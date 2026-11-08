package com.frescuratotal.erp.suppliers.model;

import java.math.BigDecimal;

//punto 2
// Representa una compra recibida en un lote durante el día.
public record DailyPurchase(String purchaseNumber, String supplierName, BigDecimal totalAmount) {
}
