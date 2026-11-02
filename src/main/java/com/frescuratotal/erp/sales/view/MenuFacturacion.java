package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.controller.ControladorFacturacion;
import com.frescuratotal.erp.sales.dao.FacturaDao;
import java.io.IOException;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Scanner;

/**
 * Menu de consola del modulo de Facturacion. Punto de entrada para el menu principal:
 * new MenuFacturacion(scanner, DatabaseConnection.getConnection()).ejecutar();
 */
public class MenuFacturacion {

    // Carpeta (relativa a donde se ejecuta el programa) donde se guardan los PDF.
    static final Path CARPETA_FACTURAS = Path.of("facturas");

    private final Scanner entrada;
    private final ControladorFacturacion controlador;

    public MenuFacturacion(Scanner entrada, Connection conexion) {
        this.entrada = entrada;
        this.controlador = new ControladorFacturacion(new FacturaDao(conexion));
    }

    public void ejecutar() {
        while (true) {
            System.out.println("\n--- Facturacion ---");
            System.out.println("1. Generar factura PDF de una venta");
            System.out.println("0. Volver");
            String opcion = preguntar("Opcion");
            if (opcion.equals("0")) {
                return;
            }
            try {
                if (opcion.equals("1")) {
                    int idVenta = convertirEntero(preguntar("Id de la venta"));
                    Path pdf = controlador.generarFactura(idVenta, CARPETA_FACTURAS);
                    System.out.println("Factura de demostracion generada: " + pdf.toAbsolutePath());
                } else {
                    System.out.println("Opcion no valida.");
                }
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Error de base de datos: " + e.getMessage());
            } catch (IOException e) {
                System.out.println("Error al crear el PDF: " + e.getMessage());
            }
        }
    }

    private static int convertirEntero(String texto) {
        try {
            return Integer.parseInt(texto.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es un numero valido.");
        }
    }

    private String preguntar(String etiqueta) {
        System.out.print(etiqueta + ": ");
        return entrada.nextLine().trim();
    }
}
