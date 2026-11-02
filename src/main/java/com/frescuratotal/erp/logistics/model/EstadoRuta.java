package com.frescuratotal.erp.logistics.model;

// Estados de rutas_entrega.estado. valorBd() es el valor exacto del ENUM de MySQL.
public enum EstadoRuta {
    PLANIFICADA("Planificada"),
    EN_TRANSITO("En Transito"),
    COMPLETADA("Completada"),
    CANCELADA("Cancelada");

    private final String valorBd;

    EstadoRuta(String valorBd) {
        this.valorBd = valorBd;
    }

    public String valorBd() {
        return valorBd;
    }

    public static EstadoRuta desdeBd(String valor) {
        for (EstadoRuta estado : values()) {
            if (estado.valorBd.equals(valor)) {
                return estado;
            }
        }
        throw new IllegalArgumentException("Estado de ruta desconocido: " + valor);
    }
}
