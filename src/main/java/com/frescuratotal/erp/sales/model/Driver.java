package com.frescuratotal.erp.sales.model;

public record Driver(int driverId, String name, String licenseNumber, String phone, String email,
        boolean active) {
}
