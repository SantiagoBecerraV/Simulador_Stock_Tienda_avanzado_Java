package com.frescuratotal.erp.sales.dao;

import com.frescuratotal.erp.sales.model.Invoice;
import com.frescuratotal.erp.sales.model.Invoice.CompanyInfo;
import com.frescuratotal.erp.sales.model.Invoice.InvoiceLine;
import com.frescuratotal.erp.sales.dao.CustomerDao;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class InvoiceDao {

    // La conexion viene del paquete comun compartido; este DAO no abre la suya.
    private final Connection connection;
    private final CustomerDao customers;

    public InvoiceDao(Connection connection) {
        this.connection = connection;
        this.customers = new CustomerDao(connection);
    }

    // Se factura toda venta que exista y no este cancelada.
    public boolean saleIsBillable(int saleId) throws SQLException {
        String sql = "SELECT 1 FROM ventas v JOIN estados_venta e ON e.id_estado = v.id_estado "
                + "WHERE v.id_venta = ? AND e.nombre <> 'Cancelada'";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, saleId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // Los totales se copian de la venta, asi la factura siempre coincide con ella.
    public void insert(int saleId, String invoiceNumber, String cufe, String qrLink) throws SQLException {
        String sql = "INSERT INTO facturas (id_venta, numero_factura, cufe, enlace_qr, subtotal, "
                + "total_descuento, monto_impuesto, monto_total) "
                + "SELECT id_venta, ?, ?, ?, subtotal, total_descuento, total_impuesto, monto_total "
                + "FROM ventas WHERE id_venta = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, invoiceNumber);
            ps.setString(2, cufe);
            ps.setString(3, qrLink);
            ps.setInt(4, saleId);
            ps.executeUpdate();
        }
    }

    public Optional<Invoice> findBySale(int saleId) throws SQLException {
        String sql = "SELECT f.id_factura, f.numero_factura, f.cufe, f.enlace_qr, f.fecha_emision, f.subtotal, "
                + "f.total_descuento, f.monto_impuesto, f.monto_total, v.numero_venta, v.id_cliente "
                + "FROM facturas f JOIN ventas v ON v.id_venta = f.id_venta "
                + "WHERE f.id_venta = ? ORDER BY f.id_factura LIMIT 1";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, saleId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                int customerId = rs.getInt("id_cliente");
                return Optional.of(new Invoice(
                        rs.getInt("id_factura"),
                        rs.getString("numero_factura"),
                        rs.getString("numero_venta"),
                        rs.getString("cufe"),
                        rs.getString("enlace_qr"),
                        rs.getTimestamp("fecha_emision"),
                        rs.getBigDecimal("subtotal"),
                        rs.getBigDecimal("total_descuento"),
                        rs.getBigDecimal("monto_impuesto"),
                        rs.getBigDecimal("monto_total"),
                        findCompany(),
                        customers.findById(customerId).orElseThrow(
                                () -> new IllegalStateException("Cliente no encontrado: " + customerId)),
                        findInvoiceLines(saleId)));
            }
        }
    }

    private CompanyInfo findCompany() throws SQLException {
        String sql = "SELECT nombre_empresa, nit, direccion, ciudad, telefono, email "
                + "FROM informacion_empresa ORDER BY id_empresa LIMIT 1";
        try (PreparedStatement ps = connection.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) {
                throw new IllegalArgumentException("No hay datos de la empresa en informacion_empresa.");
            }
            return new CompanyInfo(rs.getString("nombre_empresa"), rs.getString("nit"), rs.getString("direccion"),
                    rs.getString("ciudad"), rs.getString("telefono"), rs.getString("email"));
        }
    }

    private List<InvoiceLine> findInvoiceLines(int saleId) throws SQLException {
        String sql = "SELECT p.nombre, l.numero_lote, d.cantidad_vendida, d.precio_unitario, "
                + "d.descuento_aplicado, d.monto_descuento, d.tasa_impuesto, d.monto_impuesto, d.total_linea "
                + "FROM detalles_venta d "
                + "JOIN lotes_inventario l ON l.id_lote = d.id_lote "
                + "JOIN productos p ON p.id_producto = l.id_producto "
                + "WHERE d.id_venta = ? ORDER BY d.id_detalle";
        List<InvoiceLine> lines = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, saleId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    lines.add(new InvoiceLine(
                            rs.getString("nombre"),
                            rs.getString("numero_lote"),
                            rs.getBigDecimal("cantidad_vendida"),
                            rs.getBigDecimal("precio_unitario"),
                            rs.getBigDecimal("descuento_aplicado"),
                            rs.getBigDecimal("monto_descuento"),
                            rs.getBigDecimal("tasa_impuesto"),
                            rs.getBigDecimal("monto_impuesto"),
                            rs.getBigDecimal("total_linea")));
                }
            }
        }
        return lines;
    }
}
