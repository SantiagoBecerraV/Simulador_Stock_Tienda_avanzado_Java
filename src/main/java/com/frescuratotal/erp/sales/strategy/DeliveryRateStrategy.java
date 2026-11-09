package com.frescuratotal.erp.sales.strategy;

import java.math.BigDecimal;

// Punto 3: define el contrato Strategy para una entrega.
public interface DeliveryRateStrategy {

    // Punto 3: recibe el valor original y devuelve el total final.
    BigDecimal calculateFinalAmount(BigDecimal originalAmount);
}
