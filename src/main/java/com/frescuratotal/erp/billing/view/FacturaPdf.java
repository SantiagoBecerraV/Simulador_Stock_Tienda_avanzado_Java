package com.frescuratotal.erp.billing.view;

import com.frescuratotal.erp.billing.model.Factura;
import com.frescuratotal.erp.billing.model.Factura.LineaFactura;
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
 * Dibuja la factura en PDF con los datos que ya están en la base de datos.
 * Es un documento de DEMOSTRACIÓN: el CUFE y el QR son simulados y no tiene validez fiscal.
 */
public class FacturaPdf {

    private static final Font TITULO = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16);
    private static final Font NEGRITA = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
    private static final Font NORMAL = FontFactory.getFont(FontFactory.HELVETICA, 10);
    private static final Font AVISO = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.RED);

    private FacturaPdf() {
    }

    public static void generar(Factura f, Path destino) throws IOException {
        Document documento = new Document(PageSize.A4, 36, 36, 36, 36);
        try (OutputStream salida = Files.newOutputStream(destino)) {
            PdfWriter.getInstance(documento, salida);
            documento.open();

            documento.add(new Paragraph("FACTURA DE DEMOSTRACIÓN - DOCUMENTO SIMULADO, SIN VALIDEZ FISCAL", AVISO));
            documento.add(new Paragraph(f.empresa().nombre(), TITULO));
            documento.add(new Paragraph("NIT: " + f.empresa().nit() + " (NIT de demostración)", NORMAL));
            documento.add(new Paragraph(f.empresa().direccion() + ", " + f.empresa().ciudad()
                    + " | Tel: " + f.empresa().telefono() + " | " + f.empresa().email(), NORMAL));

            documento.add(new Paragraph("\nFactura No. " + f.numeroFactura() + "   |   Venta: " + f.numeroVenta()
                    + "   |   Fecha: " + f.fechaEmision(), NEGRITA));

            documento.add(new Paragraph("\nCliente", NEGRITA));
            documento.add(new Paragraph(f.cliente().name() + " | Documento: " + f.cliente().document()
                    + " | " + f.cliente().typeName(), NORMAL));
            documento.add(new Paragraph(texto(f.cliente().address()) + " | Tel: " + texto(f.cliente().phone())
                    + " | " + texto(f.cliente().email()), NORMAL));

            documento.add(new Paragraph(" "));
            documento.add(tablaLineas(f));
            documento.add(new Paragraph(" "));
            documento.add(tablaTotales(f));

            documento.add(new Paragraph("\nCUFE (simulado): " + f.cufe(), NORMAL));
            documento.add(qr(f.enlaceQr()));
            documento.add(new Paragraph("QR simulado de demostración. No corresponde a un documento "
                    + "electrónico validado por la DIAN.", AVISO));
            documento.close();
        } catch (DocumentException | WriterException e) {
            throw new IOException("No se pudo generar el PDF: " + e.getMessage(), e);
        }
    }

    private static PdfPTable tablaLineas(Factura f) throws DocumentException {
        PdfPTable tabla = new PdfPTable(7);
        tabla.setWidthPercentage(100);
        tabla.setWidths(new float[] {26, 12, 8, 14, 14, 12, 14});
        for (String titulo : new String[] {"Producto", "Lote", "Cant.", "Precio unit.", "Descuento", "Impuesto", "Total"}) {
            tabla.addCell(celda(titulo, NEGRITA, Element.ALIGN_LEFT));
        }
        for (LineaFactura l : f.lineas()) {
            tabla.addCell(celda(l.producto(), NORMAL, Element.ALIGN_LEFT));
            tabla.addCell(celda(l.numeroLote(), NORMAL, Element.ALIGN_LEFT));
            tabla.addCell(celda(l.cantidad().toPlainString(), NORMAL, Element.ALIGN_RIGHT));
            tabla.addCell(celda(l.precioUnitario().toPlainString(), NORMAL, Element.ALIGN_RIGHT));
            tabla.addCell(celda(l.montoDescuento().toPlainString() + " (" + porcentaje(l.tasaDescuento()) + ")",
                    NORMAL, Element.ALIGN_RIGHT));
            tabla.addCell(celda(l.montoImpuesto().toPlainString() + " (" + porcentaje(l.tasaImpuesto()) + ")",
                    NORMAL, Element.ALIGN_RIGHT));
            tabla.addCell(celda(l.totalLinea().toPlainString(), NORMAL, Element.ALIGN_RIGHT));
        }
        return tabla;
    }

    private static PdfPTable tablaTotales(Factura f) throws DocumentException {
        PdfPTable tabla = new PdfPTable(2);
        tabla.setWidthPercentage(40);
        tabla.setHorizontalAlignment(Element.ALIGN_RIGHT);
        fila(tabla, "Subtotal", f.subtotal(), NORMAL);
        fila(tabla, "Descuentos", f.totalDescuento(), NORMAL);
        fila(tabla, "Impuesto (IVA)", f.montoImpuesto(), NORMAL);
        fila(tabla, "TOTAL", f.montoTotal(), NEGRITA);
        return tabla;
    }

    private static void fila(PdfPTable tabla, String etiqueta, BigDecimal valor, Font fuente) {
        tabla.addCell(celda(etiqueta, fuente, Element.ALIGN_LEFT));
        tabla.addCell(celda(valor.toPlainString(), fuente, Element.ALIGN_RIGHT));
    }

    private static PdfPCell celda(String texto, Font fuente, int alineacion) {
        PdfPCell celda = new PdfPCell(new Phrase(texto, fuente));
        celda.setHorizontalAlignment(alineacion);
        celda.setPadding(4);
        return celda;
    }

    // Convierte 0.50 en "50%".
    private static String porcentaje(BigDecimal tasa) {
        return tasa.multiply(BigDecimal.valueOf(100)).setScale(0, RoundingMode.HALF_UP) + "%";
    }

    private static String texto(String valor) {
        return valor == null ? "-" : valor;
    }

    // ZXing calcula la matriz del QR; aquí se pinta pixel a pixel como imagen PNG.
    private static Image qr(String datos) throws WriterException, IOException, DocumentException {
        BitMatrix matriz = new QRCodeWriter().encode(datos, BarcodeFormat.QR_CODE, 150, 150);
        BufferedImage imagen = new BufferedImage(matriz.getWidth(), matriz.getHeight(), BufferedImage.TYPE_INT_RGB);
        for (int x = 0; x < matriz.getWidth(); x++) {
            for (int y = 0; y < matriz.getHeight(); y++) {
                imagen.setRGB(x, y, matriz.get(x, y) ? Color.BLACK.getRGB() : Color.WHITE.getRGB());
            }
        }
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        ImageIO.write(imagen, "png", bytes);
        return Image.getInstance(bytes.toByteArray());
    }
}
