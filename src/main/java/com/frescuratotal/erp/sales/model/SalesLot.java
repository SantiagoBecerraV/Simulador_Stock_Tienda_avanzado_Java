package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;
import java.sql.Date;

// Lote vendible. discountRate viene de la promocion vigente (0.50 = 50%); es 0 si no hay ninguna.
public record SalesLot(
        int lotId,
        String lotNumber,
        String product,
        Date expirationDate,
        BigDecimal quantity,
        BigDecimal salePrice,
        String status,
        BigDecimal discountRate) {
}
