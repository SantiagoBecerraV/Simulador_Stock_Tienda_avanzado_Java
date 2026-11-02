package com.frescuratotal.erp.sales.model;

import com.frescuratotal.erp.sales.model.Customer;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;

// Factura con todo lo que necesita el PDF. El cufe y enlaceQr son datos simulados de demostracion.
public record Factura(
        int idFactura,
        String numeroFactura,
        String numeroVenta,
        String cufe,
        String enlaceQr,
        Timestamp fechaEmision,
        BigDecimal subtotal,
        BigDecimal totalDescuento,
        BigDecimal montoImpuesto,
        BigDecimal montoTotal,
        Empresa empresa,
        Customer cliente,
        List<LineaFactura> lineas) {

    public record Empresa(String nombre, String nit, String direccion, String ciudad, String telefono, String email) {
    }

    public record LineaFactura(
            String producto,
            String numeroLote,
            BigDecimal cantidad,
            BigDecimal precioUnitario,
            BigDecimal tasaDescuento,
            BigDecimal montoDescuento,
            BigDecimal tasaImpuesto,
            BigDecimal montoImpuesto,
            BigDecimal totalLinea) {
    }
}
