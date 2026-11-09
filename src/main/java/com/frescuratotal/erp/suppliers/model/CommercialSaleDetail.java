package com.frescuratotal.erp.suppliers.model;

import java.math.BigDecimal;


public record CommercialSaleDetail(
        int idLot,
        BigDecimal quantity,
        String statusLot,
        int idSupplier,
        String supplierName) {
}
