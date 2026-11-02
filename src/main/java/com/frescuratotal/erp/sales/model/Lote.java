package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;
import java.sql.Date;

// Lote vendible. tasaDescuento viene de la promoción vigente (0.50 = 50%); es 0 si no hay ninguna.
public record Lote(
        int idLote,
        String numeroLote,
        String producto,
        Date fechaVencimiento,
        BigDecimal cantidad,
        BigDecimal precioVenta,
        String estado,
        BigDecimal tasaDescuento) {
}
