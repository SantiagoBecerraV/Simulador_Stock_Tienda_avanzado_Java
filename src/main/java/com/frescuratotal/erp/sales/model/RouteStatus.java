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
        for (RouteStatus status : values()) {
            if (status.databaseValue.equals(value)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Estado de ruta desconocido: " + value);
    }
}
