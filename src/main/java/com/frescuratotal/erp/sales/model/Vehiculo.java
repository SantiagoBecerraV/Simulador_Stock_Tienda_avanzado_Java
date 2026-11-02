package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

public record Vehiculo(int idVehiculo, String placa, String modelo, BigDecimal capacidad, EstadoVehiculo estado) {
}
