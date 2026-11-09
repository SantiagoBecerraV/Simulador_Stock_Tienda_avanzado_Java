package com.frescuratotal.erp.suppliers.model;

import java.math.BigDecimal;

// Punto 2: representa una compra recibida en un lote durante el día.
// Para ventas: crear DailySale(numeroVenta, nombreCliente, montoTotal).
public record DailyPurchase(String purchaseNumber, String supplierName, BigDecimal totalAmount) {
}
