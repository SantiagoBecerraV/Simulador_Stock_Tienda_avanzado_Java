package com.frescuratotal.erp.sales.model;

// Estados de venta que usa Logistica. Los nombres siguen el documento del reparto;
// databaseValue() devuelve el texto exacto guardado en estados_venta.nombre.
public enum SaleStatus {
    IN_PREPARATION("En Preparacion"),
    IN_TRANSIT("En Transito"),
    DELIVERED("Entregada");

    private final String databaseValue;

    SaleStatus(String databaseValue) {
        this.databaseValue = databaseValue;
    }

    public String databaseValue() {
        return databaseValue;
    }
}
