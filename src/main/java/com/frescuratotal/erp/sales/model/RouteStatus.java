package com.frescuratotal.erp.sales.model;

// Estados de rutas_entrega.estado. databaseValue() devuelve el valor exacto del ENUM de MySQL.
public enum RouteStatus {
    PLANNED("Planificada"),
    IN_TRANSIT("En Transito"),
    COMPLETED("Completada"),
    CANCELED("Cancelada");

    private final String databaseValue;

    RouteStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static RouteStatus fromDatabaseValue(String value) {
        return java.util.Arrays.stream(values())
                .filter(status -> status.databaseValue.equals(value))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Estado de ruta desconocido: " + value));
    }
}
