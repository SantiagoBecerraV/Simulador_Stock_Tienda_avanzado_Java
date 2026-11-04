package com.frescuratotal.erp.sales.model;

import com.frescuratotal.erp.sales.model.Customer;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;

// Factura con todo lo que necesita el PDF. El cufe y enlaceQr son datos simulados de demostracion.
public record Invoice(
        int invoiceId,
        String invoiceNumber,
        String saleNumber,
        String cufe,
        String qrLink,
        Timestamp issuedAt,
        BigDecimal subtotal,
        BigDecimal totalDiscount,
        BigDecimal taxAmount,
        BigDecimal totalAmount,
        CompanyInfo company,
        Customer customer,
        List<InvoiceLine> lines) {

    public record CompanyInfo(String name, String nit, String address, String city, String phone, String email) {
    }

    public record InvoiceLine(
            String product,
            String lotNumber,
            BigDecimal quantity,
            BigDecimal unitPrice,
            BigDecimal discountRate,
            BigDecimal discountAmount,
            BigDecimal taxRate,
            BigDecimal taxAmount,
            BigDecimal lineTotal) {
    }
}
