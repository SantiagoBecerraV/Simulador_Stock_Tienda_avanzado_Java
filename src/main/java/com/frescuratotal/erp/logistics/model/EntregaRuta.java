package com.frescuratotal.erp.logistics.model;

import java.sql.Timestamp;

// Fila de ventas_ruta. fechaEntrega es null mientras la venta no se haya entregado.
public record EntregaRuta(
        int idVenta,
        String numeroVenta,
        Integer ordenEntrega,
        String direccionDestino,
        Timestamp fechaEntrega,
        String recibidoPor,
        String observaciones) {
}
