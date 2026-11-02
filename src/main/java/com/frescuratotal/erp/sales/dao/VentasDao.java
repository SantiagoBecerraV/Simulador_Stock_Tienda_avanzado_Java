package com.frescuratotal.erp.sales.dao;

import com.frescuratotal.erp.sales.model.LineaPedido;
import com.frescuratotal.erp.sales.model.Lote;
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

public class VentasDao {

    // FIFO: los lotes que vencen primero salen primero. Solo se ofrecen lotes con existencias,
    // estado vendible y sin vencer. El descuento sale de la promoción activa y vigente
    // que aplica al estado "Proximo a Vencer"; si no hay promoción, es 0.
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

    // La conexión viene del paquete común compartido; este DAO no abre la suya.
    private final Connection conexion;

    public VentasDao(Connection conexion) {
        this.conexion = conexion;
    }

    public List<Lote> listarLotesVendibles() throws SQLException {
        List<Lote> lotes = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(LOTES_VENDIBLES);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lotes.add(new Lote(
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
        return lotes;
    }

    // Venta + detalles + descuento de stock en UNA transacción: si algo falla, rollback de todo.
    // Devuelve el id de la venta creada.
    public int registrarVenta(int idCliente, List<LineaPedido> lineas) throws SQLException {
        boolean autoCommitOriginal = conexion.getAutoCommit();
        conexion.setAutoCommit(false);
        try {
            int idVenta = insertarVenta(idCliente, lineas);
            for (LineaPedido linea : lineas) {
                descontarStock(linea);
                insertarDetalle(idVenta, linea);
            }
            conexion.commit();
            return idVenta;
        } catch (SQLException | RuntimeException e) {
            conexion.rollback();
            throw e;
        } finally {
            conexion.setAutoCommit(autoCommitOriginal);
        }
    }

    private int insertarVenta(int idCliente, List<LineaPedido> lineas) throws SQLException {
        BigDecimal subtotal = BigDecimal.ZERO;
        BigDecimal descuento = BigDecimal.ZERO;
        BigDecimal impuesto = BigDecimal.ZERO;
        BigDecimal total = BigDecimal.ZERO;
        for (LineaPedido l : lineas) {
            subtotal = subtotal.add(l.subtotal());
            descuento = descuento.add(l.montoDescuento());
            impuesto = impuesto.add(l.montoImpuesto());
            total = total.add(l.totalLinea());
        }
        String numeroVenta = "V-" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmssSSS"));
        String sql = "INSERT INTO ventas (numero_venta, id_cliente, subtotal, total_descuento, total_impuesto, "
                + "monto_total, id_estado) VALUES (?, ?, ?, ?, ?, ?, "
                + "(SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada'))";
        try (PreparedStatement ps = conexion.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, numeroVenta);
            ps.setInt(2, idCliente);
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

    // Verificación y descuento en un solo UPDATE: la fila queda bloqueada hasta el commit y
    // solo se actualiza si todavía hay existencias y el lote sigue siendo vendible.
    private void descontarStock(LineaPedido linea) throws SQLException {
        String sql = "UPDATE lotes_inventario SET cantidad = cantidad - ? "
                + "WHERE id_lote = ? AND cantidad >= ? AND fecha_vencimiento >= CURDATE() "
                + "AND id_estado IN (SELECT id_estado FROM estados_lote WHERE nombre IN ('Disponible', 'Proximo a Vencer'))";
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setBigDecimal(1, linea.cantidad());
            ps.setInt(2, linea.lote().idLote());
            ps.setBigDecimal(3, linea.cantidad());
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("Ya no hay existencias suficientes del lote "
                        + linea.lote().numeroLote() + ". La venta no se registró.");
            }
        }
    }

    private void insertarDetalle(int idVenta, LineaPedido linea) throws SQLException {
        String sql = "INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, "
                + "descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setInt(1, idVenta);
            ps.setInt(2, linea.lote().idLote());
            ps.setBigDecimal(3, linea.cantidad());
            ps.setBigDecimal(4, linea.lote().precioVenta());
            ps.setBigDecimal(5, linea.lote().tasaDescuento());
            ps.setBigDecimal(6, linea.montoDescuento());
            ps.setBigDecimal(7, linea.tasaImpuesto());
            ps.setBigDecimal(8, linea.montoImpuesto());
            ps.setBigDecimal(9, linea.subtotal());
            ps.setBigDecimal(10, linea.totalLinea());
            ps.executeUpdate();
        }
    }
}
