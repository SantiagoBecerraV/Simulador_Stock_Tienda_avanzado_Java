package com.frescuratotal.erp.sales.model;

// Estados de vehiculos.estado. valorBd() es el valor exacto del ENUM de MySQL.
public enum EstadoVehiculo {
    ACTIVO("Activo"),
    INACTIVO("Inactivo"),
    MANTENIMIENTO("Mantenimiento");

    private final String valorBd;

    EstadoVehiculo(String valorBd) {
        this.valorBd = valorBd;
    }

    public String valorBd() {
        return valorBd;
    }

    public static EstadoVehiculo desdeBd(String valor) {
        for (EstadoVehiculo estado : values()) {
            if (estado.valorBd.equals(valor)) {
                return estado;
            }
        }
        throw new IllegalArgumentException("Estado de vehiculo desconocido: " + valor);
    }
}
