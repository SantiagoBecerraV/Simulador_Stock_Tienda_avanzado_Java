package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.model.Invoice;
import com.frescuratotal.erp.sales.model.Invoice.InvoiceLine;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Image;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import java.awt.Color;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.file.Files;
import java.nio.file.Path;
import javax.imageio.ImageIO;

/**
 * Dibuja la factura en PDF con los datos que ya estan en la base de datos.
 * Es un documento de DEMOSTRACION: el CUFE y el QR son simulados y no tiene validez fiscal.
 */
public class InvoicePdf {

    private static final Font TITLE_FONT = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16);
    private static final Font BOLD_FONT = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
    private static final Font NORMAL_FONT = FontFactory.getFont(FontFactory.HELVETICA, 10);
    private static final Font WARNING_FONT = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.RED);

    private InvoicePdf() {
    }

    public static void generate(Invoice f, Path destination) throws IOException {
        Document document = new Document(PageSize.A4, 36, 36, 36, 36);
        try (OutputStream output = Files.newOutputStream(destination)) {
            PdfWriter.getInstance(document, output);
            document.open();

            document.add(new Paragraph("FACTURA DE DEMOSTRACION - DOCUMENTO SIMULADO, SIN VALIDEZ FISCAL", WARNING_FONT));
            document.add(new Paragraph(f.company().name(), TITLE_FONT));
            document.add(new Paragraph("NIT: " + f.company().nit() + " (NIT de demostracion)", NORMAL_FONT));
            document.add(new Paragraph(f.company().address() + ", " + f.company().city()
                    + " | Tel: " + f.company().phone() + " | " + f.company().email(), NORMAL_FONT));

            document.add(new Paragraph("\nFactura No. " + f.invoiceNumber() + "   |   Venta: " + f.saleNumber()
                    + "   |   Fecha: " + f.issuedAt(), BOLD_FONT));

            document.add(new Paragraph("\nCliente", BOLD_FONT));
            document.add(new Paragraph(f.customer().name() + " | Documento: " + f.customer().document()
                    + " | " + f.customer().typeName(), NORMAL_FONT));
            document.add(new Paragraph(text(f.customer().address()) + " | Tel: " + text(f.customer().phone())
                    + " | " + text(f.customer().email()), NORMAL_FONT));

            document.add(new Paragraph(" "));
            document.add(renderInvoiceLines(f));
            document.add(new Paragraph(" "));
            document.add(renderInvoiceTotals(f));

            document.add(new Paragraph("\nCUFE (simulado): " + f.cufe(), NORMAL_FONT));
            document.add(generateQrCode(f.qrLink()));
            document.add(new Paragraph("QR simulado de demostracion. No corresponde a un documento "
                    + "electronico validado por la DIAN.", WARNING_FONT));
            document.close();
        } catch (DocumentException | WriterException e) {
            throw new IOException("No se pudo generar el PDF: " + e.getMessage(), e);
        }
    }

    private static PdfPTable renderInvoiceLines(Invoice f) throws DocumentException {
        PdfPTable table = new PdfPTable(7);
        table.setWidthPercentage(100);
        table.setWidths(new float[] {26, 12, 8, 14, 14, 12, 14});
        for (String title : new String[] {"Producto", "Lote", "Cant.", "Precio unit.", "Descuento", "Impuesto", "Total"}) {
            table.addCell(cell(title, BOLD_FONT, Element.ALIGN_LEFT));
        }
        for (InvoiceLine l : f.lines()) {
            table.addCell(cell(l.product(), NORMAL_FONT, Element.ALIGN_LEFT));
            table.addCell(cell(l.lotNumber(), NORMAL_FONT, Element.ALIGN_LEFT));
            table.addCell(cell(l.quantity().toPlainString(), NORMAL_FONT, Element.ALIGN_RIGHT));
            table.addCell(cell(l.unitPrice().toPlainString(), NORMAL_FONT, Element.ALIGN_RIGHT));
            table.addCell(cell(l.discountAmount().toPlainString() + " (" + formatPercentage(l.discountRate()) + ")",
                    NORMAL_FONT, Element.ALIGN_RIGHT));
            table.addCell(cell(l.taxAmount().toPlainString() + " (" + formatPercentage(l.taxRate()) + ")",
                    NORMAL_FONT, Element.ALIGN_RIGHT));
            table.addCell(cell(l.lineTotal().toPlainString(), NORMAL_FONT, Element.ALIGN_RIGHT));
        }
        return table;
    }

    private static PdfPTable renderInvoiceTotals(Invoice f) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(40);
        table.setHorizontalAlignment(Element.ALIGN_RIGHT);
        row(table, "Subtotal", f.subtotal(), NORMAL_FONT);
        row(table, "Descuentos", f.totalDiscount(), NORMAL_FONT);
        row(table, "Impuesto (IVA)", f.taxAmount(), NORMAL_FONT);
        row(table, "TOTAL", f.totalAmount(), BOLD_FONT);
        return table;
    }

    private static void row(PdfPTable table, String label, BigDecimal amount, Font font) {
        table.addCell(cell(label, font, Element.ALIGN_LEFT));
        table.addCell(cell(amount.toPlainString(), font, Element.ALIGN_RIGHT));
    }

    private static PdfPCell cell(String text, Font font, int alignment) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(alignment);
        cell.setPadding(4);
        return cell;
    }

    // Convierte 0.50 en "50%".
    private static String formatPercentage(BigDecimal rate) {
        return rate.multiply(BigDecimal.valueOf(100)).setScale(0, RoundingMode.HALF_UP) + "%";
    }

    private static String text(String value) {
        return value == null ? "-" : value;
    }

    // ZXing calcula la matriz del QR; aqui se pinta pixel a pixel como imagen PNG.
    private static Image generateQrCode(String data) throws WriterException, IOException, DocumentException {
        BitMatrix matrix = new QRCodeWriter().encode(data, BarcodeFormat.QR_CODE, 150, 150);
        BufferedImage image = new BufferedImage(matrix.getWidth(), matrix.getHeight(), BufferedImage.TYPE_INT_RGB);
        for (int x = 0; x < matrix.getWidth(); x++) {
            for (int y = 0; y < matrix.getHeight(); y++) {
                image.setRGB(x, y, matrix.get(x, y) ? Color.BLACK.getRGB() : Color.WHITE.getRGB());
            }
        }
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        ImageIO.write(image, "png", bytes);
        return Image.getInstance(bytes.toByteArray());
    }
}
