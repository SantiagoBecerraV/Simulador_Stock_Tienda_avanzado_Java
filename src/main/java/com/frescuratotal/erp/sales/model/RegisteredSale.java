package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

// Venta en estado Registrada, pendiente de pasar a preparacion.
public record RegisteredSale(int saleId, String saleNumber, String customer, BigDecimal totalAmount) {
}
