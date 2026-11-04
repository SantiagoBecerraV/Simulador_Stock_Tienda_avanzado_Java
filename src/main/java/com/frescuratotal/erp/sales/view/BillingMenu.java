package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.controller.BillingController;
import com.frescuratotal.erp.sales.dao.InvoiceDao;
import java.io.IOException;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Scanner;

/**
 * Menu de consola del modulo de Facturacion. Punto de entrada para el menu principal:
 * new BillingMenu(scanner, DatabaseConnection.getConnection()).run();
 */
public class BillingMenu {

    // Carpeta (relativa a donde se ejecuta el programa) donde se guardan los PDF.
    static final Path INVOICE_DIRECTORY = Path.of("facturas");

    private final Scanner input;
    private final BillingController controller;

    public BillingMenu(Scanner input, Connection connection) {
        this.input = input;
        this.controller = new BillingController(new InvoiceDao(connection));
    }

    public void run() {
        while (true) {
            System.out.println("\n--- Facturacion ---");
            System.out.println("1. Generar factura PDF de una venta");
            System.out.println("0. Volver");
            String option = ask("Opcion");
            if (option.equals("0")) {
                return;
            }
            try {
                if (option.equals("1")) {
                    int saleId = parseInteger(ask("Id de la venta"));
                    Path pdf = controller.generateInvoice(saleId, INVOICE_DIRECTORY);
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

    private static int parseInteger(String text) {
        try {
            return Integer.parseInt(text.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + text + "' no es un numero valido.");
        }
    }

    private String ask(String label) {
        System.out.print(label + ": ");
        return input.nextLine().trim();
    }
}
