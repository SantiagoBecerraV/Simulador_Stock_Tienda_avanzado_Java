package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;

// Venta lista para despacho. idRuta es null si todavía no está asignada a ninguna ruta.
public record VentaEnPreparacion(
        int idVenta,
        String numeroVenta,
        String cliente,
        String direccion,
        BigDecimal montoTotal,
        Integer idRuta) {
}
