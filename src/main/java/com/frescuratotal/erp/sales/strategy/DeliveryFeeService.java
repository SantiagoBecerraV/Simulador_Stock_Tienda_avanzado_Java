package com.frescuratotal.erp.sales.strategy;

import com.frescuratotal.erp.sales.model.DeliveryMode;
import java.math.BigDecimal;
import java.util.Map;

// Punto 3: selecciona la estrategia sin conocer los porcentajes.
public class DeliveryFeeService {

    // Punto 3: relaciona cada modalidad con su estrategia.
    private final Map<DeliveryMode, DeliveryRateStrategy> strategies = Map.of(
            DeliveryMode.STANDARD, new StandardDeliveryStrategy(),
            DeliveryMode.URGENT, new UrgentDeliveryStrategy());

    // Punto 3: calcula el total con la estrategia elegida.
    public BigDecimal calculateFinalAmount(BigDecimal originalAmount, DeliveryMode deliveryMode) {
        if (originalAmount == null || originalAmount.signum() < 0) {
            throw new IllegalArgumentException("El valor original no puede ser negativo.");
        }
        DeliveryRateStrategy strategy = strategies.get(deliveryMode);
        if (strategy == null) {
            throw new IllegalArgumentException("La modalidad de entrega no es valida.");
        }
        return strategy.calculateFinalAmount(originalAmount);
    }
}
