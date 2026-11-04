package com.frescuratotal.erp.sales.model;

// Estados de vehiculos.estado. databaseValue() devuelve el valor exacto del ENUM de MySQL.
public enum VehicleStatus {
    ACTIVE("Activo"),
    INACTIVE("Inactivo"),
    UNDER_MAINTENANCE("Mantenimiento");

    private final String databaseValue;

    VehicleStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }

    public static VehicleStatus fromDatabaseValue(String value) {
        for (VehicleStatus status : values()) {
            if (status.databaseValue.equals(value)) {
                return status;
            }
        }
        throw new IllegalArgumentException("Estado de vehiculo desconocido: " + value);
    }
}
