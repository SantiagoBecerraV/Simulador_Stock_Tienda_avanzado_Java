package com.frescuratotal.erp.sales.model;

import java.sql.Timestamp;

// placa y conductor vienen de asignaciones_entrega; son null si la ruta aun no tiene asignacion.
public record Route(
        int routeId,
        String routeName,
        Timestamp estimatedDeparture,
        Timestamp estimatedArrival,
        Timestamp actualDeparture,
        Timestamp actualArrival,
        RouteStatus status,
        String licensePlate,
        String driver) {
}
