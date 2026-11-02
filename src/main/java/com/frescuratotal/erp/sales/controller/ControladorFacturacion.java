package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.sales.dao.FacturaDao;
import com.frescuratotal.erp.sales.model.Factura;
import com.frescuratotal.erp.sales.view.FacturaPdf;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.UUID;

/**
 * Módulo de Facturación: a partir de una venta ya registrada crea (una sola vez) su factura
 * en la tabla facturas y genera el PDF. Si la venta ya tiene factura, solo se regenera el PDF.
 * El CUFE y el QR son simulados: la factura NO es un documento fiscal válido.
 */
public class ControladorFacturacion {

    private final FacturaDao dao;

    public ControladorFacturacion(FacturaDao dao) {
        this.dao = dao;
    }

    // Devuelve la ruta del PDF generado.
    public Path generarFactura(int idVenta, Path carpeta) throws SQLException, IOException {
        if (!dao.ventaFacturable(idVenta)) {
            throw new IllegalArgumentException("No existe una venta activa con id " + idVenta + ".");
        }
        if (dao.buscarPorVenta(idVenta).isEmpty()) {
            String numeroFactura = String.format("FAC-DEMO-%06d", idVenta);
            String cufe = "SIMULADO-" + UUID.randomUUID();
            String datosQr = "SIMULADO|" + numeroFactura + "|" + cufe;
            dao.insertar(idVenta, numeroFactura, cufe, datosQr);
        }
        Factura factura = dao.buscarPorVenta(idVenta).orElseThrow();
        Files.createDirectories(carpeta);
        Path destino = carpeta.resolve(factura.numeroFactura() + ".pdf");
        FacturaPdf.generar(factura, destino);
        return destino;
    }
}
