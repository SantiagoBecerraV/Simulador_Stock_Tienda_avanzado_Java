package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

public record Vehicle(int vehicleId, String licensePlate, String model, BigDecimal capacity, VehicleStatus status) {
}
