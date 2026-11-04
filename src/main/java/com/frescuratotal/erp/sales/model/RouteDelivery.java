package com.frescuratotal.erp.sales.model;

import java.sql.Timestamp;

// Fila de ventas_ruta. fechaEntrega es null mientras la venta no se haya entregado.
public record RouteDelivery(
        int saleId,
        String saleNumber,
        Integer deliveryOrder,
        String deliveryAddress,
        Timestamp deliveryDate,
        String receivedBy,
        String observations) {
}
