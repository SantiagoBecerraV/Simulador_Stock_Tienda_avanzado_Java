package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

// Venta lista para despacho. routeId es null si todavia no esta asignada a ninguna ruta.
public record SaleInPreparation(
        int saleId,
        String saleNumber,
        String customer,
        String address,
        BigDecimal totalAmount,
        Integer routeId) {
}
