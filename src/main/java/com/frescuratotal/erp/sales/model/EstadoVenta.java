package com.frescuratotal.erp.sales.model;

// Estados de venta que usa Logística. Los nombres siguen el documento del reparto;
// valorBd() es el texto exacto guardado en estados_venta.nombre.
public enum EstadoVenta {
    IN_PREPARATION("En Preparacion"),
    IN_TRANSIT("En Transito"),
    DELIVERED("Entregada");

    private final String valorBd;

    EstadoVenta(String valorBd) {
        this.valorBd = valorBd;
    }

    public String valorBd() {
        return valorBd;
    }
}
