package com.frescuratotal.erp.sales.dao;

import com.frescuratotal.erp.sales.model.SaleStatus;
import com.frescuratotal.erp.sales.model.OrderLine;
import com.frescuratotal.erp.sales.model.SalesLot;
import com.frescuratotal.erp.sales.model.RegisteredSale;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

public class SalesDao {

    // FEFO: los lotes que vencen primero salen primero. Solo se ofrecen lotes con existencias,
    // estado vendible y sin vencer. El descuento es el mayor de las promociones activas y vigentes
    // del estado del lote; si no hay promocion, es 0. La condicion e.nombre = 'Proximo a Vencer'
    // no sobra: limita los descuentos a lotes proximos a vencer aunque exista una promocion
    // configurada para otro estado.
    private static final String LOTES_VENDIBLES =
            "SELECT l.id_lote, l.numero_lote, p.nombre AS producto, l.fecha_vencimiento, l.cantidad, "
            + "l.precio_venta, e.nombre AS estado, "
            + "COALESCE((SELECT MAX(pr.tasa_descuento) FROM promociones pr "
            + "           WHERE pr.activa = TRUE AND e.nombre = 'Proximo a Vencer' "
            + "           AND pr.aplica_estado_lote = l.id_estado "
            + "           AND (pr.aplica_categoria_producto IS NULL OR pr.aplica_categoria_producto = p.id_categoria) "
            + "           AND (pr.fecha_inicio IS NULL OR pr.fecha_inicio <= CURDATE()) "
            + "           AND (pr.fecha_fin IS NULL OR pr.fecha_fin >= CURDATE())), 0) AS tasa_descuento "
            + "FROM lotes_inventario l "
            + "JOIN productos p ON p.id_producto = l.id_producto "
            + "JOIN estados_lote e ON e.id_estado = l.id_estado "
            + "WHERE e.nombre IN ('Disponible', 'Proximo a Vencer') "
            + "AND l.cantidad > 0 AND l.fecha_vencimiento >= CURDATE() "
            + "ORDER BY l.fecha_vencimiento ASC, l.id_lote ASC";

    // La conexion viene del paquete comun compartido; este DAO no abre la suya.
    private final Connection connection;

    public SalesDao(Connection connection) {
        this.connection = connection;
    }

    public List<SalesLot> listSellableLots() throws SQLException {
        List<SalesLot> lots = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(LOTES_VENDIBLES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lots.add(new SalesLot(
                        rs.getInt("id_lote"),
                        rs.getString("numero_lote"),
                        rs.getString("producto"),
                        rs.getDate("fecha_vencimiento"),
                        rs.getBigDecimal("cantidad"),
                        rs.getBigDecimal("precio_venta"),
                        rs.getString("estado"),
                        rs.getBigDecimal("tasa_descuento")));
            }
        }
        return lots;
    }

    public List<RegisteredSale> listRegisteredSales() throws SQLException {
        String sql = "SELECT v.id_venta, v.numero_venta, c.nombre, v.monto_total FROM ventas v "
                + "JOIN clientes c ON c.id_cliente = v.id_cliente "
                + "JOIN estados_venta e ON e.id_estado = v.id_estado "
                + "WHERE e.nombre = 'Registrada' ORDER BY v.fecha_venta, v.id_venta";
        List<RegisteredSale> sales = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                sales.add(new RegisteredSale(rs.getInt(1), rs.getString(2), rs.getString(3), rs.getBigDecimal(4)));
            }
        }
        return sales;
    }

    // Registrada -> En Preparacion. Solo cambia si la venta sigue Registrada (no pisa otros estados).
    public boolean moveSaleToPreparation(int saleId) throws SQLException {
        String sql = "UPDATE ventas SET id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                + "WHERE id_venta = ? AND id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada')";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, SaleStatus.IN_PREPARATION.databaseValue());
            ps.setInt(2, saleId);
            return ps.executeUpdate() == 1;
        }
    }

    // Venta + detalles + descuento de stock en UNA transaccion: si algo falla, rollback de todo.
    // Devuelve el id de la venta creada.
    public int registerSale(int customerId, List<OrderLine> lines) throws SQLException {
        boolean autoCommitOriginal = connection.getAutoCommit();
        connection.setAutoCommit(false);
        try {
            int saleId = insertSale(customerId, lines);
            for (OrderLine line : lines) {
                subtractStock(line);
                insertSaleDetail(saleId, line);
            }
            connection.commit();
            return saleId;
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(autoCommitOriginal);
        }
    }

    private int insertSale(int customerId, List<OrderLine> lines) throws SQLException {
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal descuento = BigDecimal.ZERO;
        BigDecimal impuesto = BigDecimal.ZERO;
        BigDecimal total = BigDecimal.ZERO;
        for (OrderLine l : lines) {
            subtotal = subtotal.add(l.subtotal());
            descuento = descuento.add(l.discountAmount());
            impuesto = impuesto.add(l.taxAmount());
            total = total.add(l.lineTotal());
        }
        String saleNumber = "V-" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmssSSS"));
        String sql = "INSERT INTO ventas (numero_venta, id_cliente, subtotal, total_descuento, total_impuesto, "
                + "monto_total, id_estado) VALUES (?, ?, ?, ?, ?, ?, "
                + "(SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada'))";
        try (PreparedStatement ps = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, saleNumber);
            ps.setInt(2, customerId);
            ps.setBigDecimal(3, subtotal);
            ps.setBigDecimal(4, descuento);
            ps.setBigDecimal(5, impuesto);
            ps.setBigDecimal(6, total);
            ps.executeUpdate();
            try (ResultSet claves = ps.getGeneratedKeys()) {
                claves.next();
                return claves.getInt(1);
            }
        }
    }

    // Verificacion y descuento en un solo UPDATE: la fila queda bloqueada hasta el commit y
    // solo se actualiza si todavia hay existencias y el lote sigue siendo vendible.
    private void subtractStock(OrderLine line) throws SQLException {
        String sql = "UPDATE lotes_inventario SET cantidad = cantidad - ? "
                + "WHERE id_lote = ? AND cantidad >= ? AND fecha_vencimiento >= CURDATE() "
                + "AND id_estado IN (SELECT id_estado FROM estados_lote WHERE nombre IN ('Disponible', 'Proximo a Vencer'))";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setBigDecimal(1, line.quantity());
            ps.setInt(2, line.lot().lotId());
            ps.setBigDecimal(3, line.quantity());
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Ya no hay existencias suficientes del lote "
                        + line.lot().lotNumber() + ". La venta no se registro.");
            }
        }
    }

    private void insertSaleDetail(int saleId, OrderLine line) throws SQLException {
        String sql = "INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, "
                + "descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, saleId);
            ps.setInt(2, line.lot().lotId());
            ps.setBigDecimal(3, line.quantity());
            ps.setBigDecimal(4, line.lot().salePrice());
            ps.setBigDecimal(5, line.lot().discountRate());
            ps.setBigDecimal(6, line.discountAmount());
            ps.setBigDecimal(7, line.taxRate());
            ps.setBigDecimal(8, line.taxAmount());
            ps.setBigDecimal(9, line.subtotal());
            ps.setBigDecimal(10, line.lineTotal());
            ps.executeUpdate();
        }
    }
}
