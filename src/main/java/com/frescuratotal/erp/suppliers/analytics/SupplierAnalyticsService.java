package com.frescuratotal.erp.suppliers.analytics;

import java.sql.SQLException;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class SupplierAnalyticsService {

    private final SupplierAnalyticsDao dao;

    public SupplierAnalyticsService() {
        this.dao = new SupplierAnalyticsDao();
    }

    public SupplierAnalyticsService(SupplierAnalyticsDao dao) {
        this.dao = dao;
    }

    public Map.Entry<String, Double> obtenerProveedorMayorVolumen(List<LoteProveedor> lotes) {
        Map<String, Double> volumenPorProveedor = lotes.stream()
                .collect(Collectors.groupingBy(
                        LoteProveedor::getNombreProveedor,
                        Collectors.summingDouble(LoteProveedor::getCantidadInicial)
                ));

        return volumenPorProveedor.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .orElse(null);
    }

    public String obtenerNombreProveedorMayorVolumen(List<LoteProveedor> lotes) {
        Map.Entry<String, Double> mayor = obtenerProveedorMayorVolumen(lotes);
        return mayor != null ? mayor.getKey() : "No disponible";
    }

    public List<String> obtenerProveedoresConLotesVencidos(List<LoteProveedor> lotes) {
        return lotes.stream()
                .filter(lote -> lote.getEstadoLote() != null && "Vencido".equalsIgnoreCase(lote.getEstadoLote().trim()))
                .map(LoteProveedor::getNombreProveedor)
                .distinct()
                .collect(Collectors.toList());
    }

    public void generarReporte() {
        try {
            List<LoteProveedor> lotes = dao.obtenerLotesParaReporte();
            if (lotes.isEmpty()) {
                System.out.println("No hay datos de inventario suficientes para generar estadísticas.");
                return;
            }

            Map.Entry<String, Double> mayorProveedor = obtenerProveedorMayorVolumen(lotes);
            List<String> proveedoresVencidos = obtenerProveedoresConLotesVencidos(lotes);

            System.out.println();
            System.out.println("*** Reporte de Rendimiento de Proveedores ***");
            System.out.println();
            System.out.println(">> Proveedor con Mayor Volumen de Suministro:");
            if (mayorProveedor != null) {
                System.out.println(mayorProveedor.getKey() + " (Cantidad: " + mayorProveedor.getValue() + ")");
            } else {
                System.out.println("No disponible");
            }
            System.out.println();
            System.out.println(">> Proveedores con Lotes Vencidos Registrados:");
            proveedoresVencidos.forEach(nombre -> System.out.println("- " + nombre));
        } catch (SQLException e) {
            System.out.println("Error al consultar la base de datos: " + e.getMessage());
        }
    }
}
