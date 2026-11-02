package com.frescuratotal.erp.sales.model;

public record Conductor(int idConductor, String nombre, String numeroLicencia, String telefono, String email,
        boolean activo) {
}
