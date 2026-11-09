package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;
import java.util.List;

// Punto 5: guarda el resultado del reporte comercial.
// Para otra estadística: cambiar nombres y campos solo si la salida solicitada es diferente.
public record CommercialStatistics(
        boolean hasSales,
        String topCategory,
        BigDecimal topQuantity,
        List<String> customersWithReturns) {
}
