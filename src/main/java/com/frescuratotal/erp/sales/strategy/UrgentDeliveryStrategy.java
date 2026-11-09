package com.frescuratotal.erp.sales.strategy;

import java.math.BigDecimal;
import java.math.RoundingMode;

// Punto 3: aplica el recargo de la entrega urgente.
public class UrgentDeliveryStrategy implements DeliveryRateStrategy {

    // Punto 3: multiplicador del 12 por ciento.
    private static final BigDecimal URGENT_MULTIPLIER = new BigDecimal("1.12");

    // Punto 3: suma el 12 por ciento y conserva dos decimales.
    @Override
    public BigDecimal calculateFinalAmount(BigDecimal originalAmount) {
        return originalAmount.multiply(URGENT_MULTIPLIER).setScale(2, RoundingMode.HALF_UP);
    }
}
