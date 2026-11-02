package com.frescuratotal.erp.logistics.model;

public record Conductor(int idConductor, String nombre, String numeroLicencia, String telefono, String email,
        boolean activo) {
}
