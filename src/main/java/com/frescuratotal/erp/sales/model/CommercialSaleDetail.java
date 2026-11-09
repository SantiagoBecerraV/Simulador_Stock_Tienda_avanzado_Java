package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

// Punto 5: representa una fila usada para las estadísticas comerciales.
public record CommercialSaleDetail(
        int saleId,
        BigDecimal quantity,
        String categoryName,
        String customerName,
        String saleStatus) {
}
