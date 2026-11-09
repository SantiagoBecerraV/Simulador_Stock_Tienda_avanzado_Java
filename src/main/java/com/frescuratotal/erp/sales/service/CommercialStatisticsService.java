package com.frescuratotal.erp.sales.service;

import com.frescuratotal.erp.sales.model.CommercialSaleDetail;
import com.frescuratotal.erp.sales.model.CommercialStatistics;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

// Punto 5: calcula las estadísticas usando Stream API.
public class CommercialStatisticsService {

    // Punto 5: Entregada es el equivalente a Confirmada en este ERP.
    private static final String CONFIRMED_STATUS = "CONFIRMADA";
    private static final String DELIVERED_STATUS = "ENTREGADA";
    private static final String RETURNED_STATUS = "DEVUELTA";

    // Punto 5: agrupa las unidades y busca clientes con devoluciones.
    // Para "menos vendidos": conservar groupingBy y cambiar max(...) por min(...).
    // Para mermas: agrupar igual, pero sumar cantidadPerdida y no filtrar estados de venta.
    public CommercialStatistics generate(List<CommercialSaleDetail> details) {
        Map<String, BigDecimal> unitsByCategory = details.stream()
                .filter(detail -> CONFIRMED_STATUS.equalsIgnoreCase(detail.saleStatus())
                || DELIVERED_STATUS.equalsIgnoreCase(detail.saleStatus()))
                .collect(Collectors.groupingBy(
                        CommercialSaleDetail::categoryName,
                        Collectors.reducing(BigDecimal.ZERO,
                                CommercialSaleDetail::quantity, BigDecimal::add)));

        // Para "menos vendidos": reemplazar max por min; todo lo demás se mantiene.
        Optional<Map.Entry<String, BigDecimal>> topCategory = unitsByCategory.entrySet().stream()
                .max(Map.Entry.comparingByValue());

        // Para otro reporte: reemplazar este Stream solo si piden una segunda estadística distinta.
        List<String> customersWithReturns = details.stream()
                .filter(detail -> RETURNED_STATUS.equalsIgnoreCase(detail.saleStatus()))
                .map(CommercialSaleDetail::customerName)
                .distinct()
                .sorted()
                .toList();

        // Para mermas: ajustar el record si ya no se necesitan clientes con devoluciones.
        return new CommercialStatistics(
                !details.isEmpty(),
                topCategory.map(Map.Entry::getKey).orElse(null),
                topCategory.map(Map.Entry::getValue).orElse(BigDecimal.ZERO),
                customersWithReturns);
    }
}
