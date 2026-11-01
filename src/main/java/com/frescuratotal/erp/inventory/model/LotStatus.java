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
    AVAILABLE(1),
    NEAR_EXPIRY(2),
    EXPIRED(3),
    IN_QUARANTINE(4),
    REJECTED(5);

    private final int id;

    LotStatus(int id) {
        this.id = id;
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
        throw new IllegalArgumentException("Id del lot status desconocido!!: " + id);
    }
}
