package com.frescuratotal.erp.sales.strategy;

import java.math.BigDecimal;

// Punto 3: aplica la tarifa estándar sin recargo.
public class StandardDeliveryStrategy implements DeliveryRateStrategy {

    // Punto 3: devuelve el mismo valor porque no existe recargo.
    @Override
    public BigDecimal calculateFinalAmount(BigDecimal originalAmount) {
        return originalAmount;
    }
}
