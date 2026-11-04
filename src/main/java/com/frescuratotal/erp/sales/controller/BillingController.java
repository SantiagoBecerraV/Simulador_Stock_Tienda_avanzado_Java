package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.sales.dao.InvoiceDao;
import com.frescuratotal.erp.sales.model.Invoice;
import com.frescuratotal.erp.sales.view.InvoicePdf;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.UUID;

/**
 * Modulo de Facturacion: a partir de una venta ya registrada crea (una sola vez) su factura
 * en la tabla facturas y genera el PDF. Si la venta ya tiene factura, solo se regenera el PDF.
 * El CUFE y el QR son simulados: la factura NO es un documento fiscal valido.
 */
public class BillingController {

    private final InvoiceDao dao;

    public BillingController(InvoiceDao dao) {
        this.dao = dao;
    }

    // Devuelve la ruta del PDF generado.
    public Path generateInvoice(int saleId, Path directory) throws SQLException, IOException {
        if (!dao.saleIsBillable(saleId)) {
            throw new IllegalArgumentException("No existe una venta activa con id " + saleId + ".");
        }
        if (dao.findBySale(saleId).isEmpty()) {
            String invoiceNumber = String.format("FAC-DEMO-%06d", saleId);
            String cufe = "SIMULADO-" + UUID.randomUUID();
            String qrData = "SIMULADO|" + invoiceNumber + "|" + cufe;
            dao.insert(saleId, invoiceNumber, cufe, qrData);
        }
        Invoice invoice = dao.findBySale(saleId).orElseThrow();
        Files.createDirectories(directory);
        Path destination = directory.resolve(invoice.invoiceNumber() + ".pdf");
        InvoicePdf.generate(invoice, destination);
        return destination;
    }
}
