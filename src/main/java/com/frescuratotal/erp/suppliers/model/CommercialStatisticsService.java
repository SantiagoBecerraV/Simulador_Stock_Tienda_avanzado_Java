package com.frescuratotal.erp.suppliers.model;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

public class CommercialStatisticsService {

    private static final String CONFIRMED_STATUS = "Disponible";
    private static final String VENCIDO_STATUS = "Vencido";
    private static final String PRONTO_STATUS = "Proximo a vencer";
    private static final String CUARENTENA_STATUS = "En cuarentea";


    public CommercialStatistics generate(List<CommercialSaleDetail> details) {
        Map<String, BigDecimal> unitsByCategory = details.stream()
                .filter(detail -> CONFIRMED_STATUS.equalsIgnoreCase(detail.statusLot())
                || VENCIDO_STATUS.equalsIgnoreCase(detail.statusLot()))
                .collect(Collectors.groupingBy(
                        CommercialSaleDetail::supplierName,
                        Collectors.reducing(BigDecimal.ZERO,
                                CommercialSaleDetail::quantity, BigDecimal::add)));

        Optional<Map.Entry<String, BigDecimal>> topCategory = unitsByCategory.entrySet().stream()
                .max(Map.Entry.comparingByValue());

        List<String> customersWithReturns = details.stream()
                .filter(detail -> PRONTO_STATUS.equalsIgnoreCase(detail.statusLot()))
                .map(CommercialSaleDetail::supplierName)
                .distinct()
                .sorted()
                .toList();

        return new CommercialStatistics(
                !details.isEmpty(),
                topCategory.map(Map.Entry::getKey).orElse(null),
                topCategory.map(Map.Entry::getValue).orElse(BigDecimal.ZERO),
                customersWithReturns);
    }
}
