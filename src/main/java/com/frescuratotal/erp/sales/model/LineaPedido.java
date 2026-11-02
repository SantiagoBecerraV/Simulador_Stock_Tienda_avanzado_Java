package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;
import java.math.RoundingMode;

// Linea del pedido. Calculo: subtotal - descuento + impuesto = total de la linea.
public record LineaPedido(Lote lote, BigDecimal cantidad, BigDecimal tasaImpuesto) {

    public BigDecimal subtotal() {
        return redondear(lote.precioVenta().multiply(cantidad));
    }

    public BigDecimal montoDescuento() {
        return redondear(subtotal().multiply(lote.tasaDescuento()));
    }

    // El impuesto se calcula sobre el valor ya descontado.
    public BigDecimal montoImpuesto() {
        return redondear(subtotal().subtract(montoDescuento()).multiply(tasaImpuesto));
    }

    public BigDecimal totalLinea() {
        return subtotal().subtract(montoDescuento()).add(montoImpuesto());
    }

    private static BigDecimal redondear(BigDecimal valor) {
        return valor.setScale(2, RoundingMode.HALF_UP);
    }
}
