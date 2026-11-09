package com.frescuratotal.erp.suppliers.model;

import java.math.BigDecimal;
import java.util.List;


public record CommercialStatistics(
        boolean hasSales,
        String topCategory,
        BigDecimal topQuantity,
        List<String> customersWithReturns) {
}
