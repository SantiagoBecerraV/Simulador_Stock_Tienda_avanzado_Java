package com.frescuratotal.erp.sales.model;

// Punto 3: define las modalidades disponibles para una entrega.
public enum DeliveryMode {
    STANDARD("Estandar"),
    URGENT("Urgente");

    private final String label;

    DeliveryMode(String label) {
        this.label = label;
    }

    // Punto 3: devuelve el texto mostrado en el menú.
    public String getLabel() {
        return label;
    }
}
