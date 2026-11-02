package com.frescuratotal.erp.sales.model;

import java.sql.Timestamp;

// placa y conductor vienen de asignaciones_entrega; son null si la ruta aún no tiene asignación.
public record Ruta(
        int idRuta,
        String nombreRuta,
        Timestamp salidaEstimada,
        Timestamp llegadaEstimada,
        Timestamp salidaReal,
        Timestamp llegadaReal,
        EstadoRuta estado,
        String placa,
        String conductor) {
}
