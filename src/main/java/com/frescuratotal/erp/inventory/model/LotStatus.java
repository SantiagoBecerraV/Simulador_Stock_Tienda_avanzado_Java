package com.frescuratotal.erp.inventory.model;

// Los ids deben coincidir con los id_estado que docs/database.sql inserta en estados_lote
// (1 = Disponible ... 5 = Rechazado, en ese orden). Si cambia el orden del INSERT, cambie tambien aqui.
public enum LotStatus {
    AVAILABLE(1, "Disponible"),
    NEAR_EXPIRY(2, "Proximo a vencer"),
    EXPIRED(3, "Vencido"),
    IN_QUARANTINE(4, "En cuarentena"),
    REJECTED(5, "Rechazado");

    private final int id;
    private final String label;

    LotStatus(int id, String label) {
        this.id = id;
        this.label = label;
    }

    // Texto en espanol que ve la persona usuaria.
    @Override
    public String toString() {
        return label;
    }

    public int getId() {
        return id;
    }
    
    // Convierte el numero almacenado en la base de datos en el valor del enum.
    public static LotStatus fromId(int id) {
        for (LotStatus status : values()) {
            if (status.id == id) {
                return status;
            }
        }
        throw new IllegalArgumentException("Estado de lote desconocido: " + id);
    }
}
