package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

// Venta en estado Registrada, pendiente de pasar a preparacion.
public record VentaRegistrada(int idVenta, String numeroVenta, String cliente, BigDecimal montoTotal) {
}
