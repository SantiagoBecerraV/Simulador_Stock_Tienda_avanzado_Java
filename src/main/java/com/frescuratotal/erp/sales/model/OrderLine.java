package com.frescuratotal.erp.sales.model;

import java.math.BigDecimal;
import java.math.RoundingMode;

// Linea del pedido. Calculo: subtotal - descuento + impuesto = total de la linea.
public record OrderLine(SalesLot lot, BigDecimal quantity, BigDecimal taxRate) {

    public BigDecimal subtotal() {
        return roundAmount(lot.salePrice().multiply(quantity));
    }

    public BigDecimal discountAmount() {
        return roundAmount(subtotal().multiply(lot.discountRate()));
    }

    // El impuesto se calcula sobre el valor ya descontado.
    public BigDecimal taxAmount() {
        return roundAmount(subtotal().subtract(discountAmount()).multiply(taxRate));
    }

    public BigDecimal lineTotal() {
        return subtotal().subtract(discountAmount()).add(taxAmount());
    }

    private static BigDecimal roundAmount(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.HALF_UP);
    }
}
