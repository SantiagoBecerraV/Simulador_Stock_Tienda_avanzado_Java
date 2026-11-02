/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.model;

/**
 *
 * @author admin
 */
public enum LotStatus {
    AVAILABLE(1, "Disponible"),
    NEAR_EXPIRY(2, "Proximo a vencer"),
    EXPIRED(3, "Vencido"),
    IN_QUARANTINE(4, "En cuarentena"),
    REJECTED(5, "Rechazado");

    private final int id;
    private final String etiqueta;

    LotStatus(int id, String etiqueta) {
        this.id = id;
        this.etiqueta = etiqueta;
    }

    // Texto en espanol que ve la persona usuaria.
    @Override
    public String toString() {
        return etiqueta;
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
