package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.common.ConsoleTable;
import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.sales.controller.BillingController;
import com.frescuratotal.erp.sales.controller.SalesController;
import com.frescuratotal.erp.sales.dao.InvoiceDao;
import com.frescuratotal.erp.sales.dao.SalesDao;
import com.frescuratotal.erp.sales.model.OrderLine;
import com.frescuratotal.erp.sales.model.SalesLot;
import com.frescuratotal.erp.sales.model.RegisteredSale;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 * Menu de consola del modulo de Ventas. Punto de entrada para el menu principal:
 * new SalesMenu(scanner, DatabaseConnection.getConnection()).run();
 */
public class SalesMenu {

    private final Scanner input;
    private final SalesController controller;
    private final BillingController billingController;

    public SalesMenu(Scanner input, Connection connection) {
        this.input = input;
        this.controller = new SalesController(new SalesDao(connection), new CustomerDao(connection));
        this.billingController = new BillingController(new InvoiceDao(connection));
    }

    public void run() {
        while (true) {
            System.out.println("\n--- Ventas ---");
            System.out.println("1. Nueva venta");
            System.out.println("2. Ver lotes disponibles");
            System.out.println("3. Pasar venta a preparacion");
            System.out.println("0. Volver");
            String option = ask("Opcion");
            if (option.equals("0")) {
                return;
            }
            try {
                switch (option) {
                    case "1" -> createSale();
                    case "2" -> showLots(controller.listLots());
                    case "3" -> moveSaleToPreparation();
                    default -> System.out.println("Opcion no valida.");
                }
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Error de base de datos: " + e.getMessage());
            }
        }
    }

    private void createSale() throws SQLException {
        Customer customer = controller.findCustomer(parseInteger(ask("Id del cliente")));
        System.out.println("Cliente: " + customer.name() + " (documento " + customer.document() + ")");

        List<OrderLine> orderLines = new ArrayList<>();
        while (true) {
            // Se vuelve a consultar en cada vuelta para mostrar las existencias mas recientes.
            List<SalesLot> lots = controller.listLots();
            showLots(lots);
            String text = ask("Id del lote a agregar (Enter para terminar)");
            if (text.isEmpty()) {
                break;
            }
            // Un dato invalido no debe perder el pedido ya armado.
            try {
                int lotId = parseInteger(text);
                SalesLot lot = lots.stream().filter(l -> l.lotId() == lotId).findFirst()
                        .orElseThrow(() -> new IllegalArgumentException("Ese lote no esta disponible para la venta."));
                BigDecimal quantity = parseDecimal(ask("Cantidad"));
                controller.addOrderLine(orderLines, lot, quantity);
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            }
        }

        if (orderLines.isEmpty()) {
            System.out.println("Venta cancelada: el pedido esta vacio.");
            return;
        }
        showOrderSummary(orderLines);
        if (ask("Confirmar la venta? (s/n)").equalsIgnoreCase("s")) {
            int saleId = controller.confirmSale(customer.customerId(), orderLines);
            System.out.println("Venta registrada con id " + saleId + ".");
            generateInvoice(saleId);
        } else {
            System.out.println("Venta cancelada.");
        }
    }

    private void moveSaleToPreparation() throws SQLException {
        List<RegisteredSale> sales = controller.listRegisteredSales();
        if (sales.isEmpty()) {
            System.out.println("No hay ventas registradas pendientes.");
            return;
        }
        System.out.println("Ventas registradas pendientes:");
        List<String[]> rows = new ArrayList<>();
        for (RegisteredSale v : sales) {
            rows.add(new String[]{String.valueOf(v.saleId()), v.saleNumber(), v.customer(),
                    "$" + v.totalAmount()});
        }
        ConsoleTable.printTable(new String[]{"Id venta", "Numero", "Cliente", "Total"}, rows);
        controller.moveSaleToPreparation(parseInteger(ask("Id de la venta a pasar a preparacion")));
        System.out.println("Venta en preparacion: ya aparece en el panel de Logistica.");
    }

    // La factura se crea despues de guardar la venta: si falla, la venta no se pierde y se puede
    // reintentar desde Facturacion (no se duplica, una venta tiene una sola factura).
    private void generateInvoice(int saleId) {
        try {
            Path pdf = billingController.generateInvoice(saleId, BillingMenu.INVOICE_DIRECTORY);
            System.out.println("Factura de demostracion generada: " + pdf.toAbsolutePath());
        } catch (SQLException | IOException | IllegalArgumentException e) {
            System.out.println("La venta " + saleId + " quedo registrada, pero no se pudo generar la factura: "
                    + e.getMessage());
            System.out.println("Puede generarla despues desde el menu Facturacion.");
        }
    }

    private void showLots(List<SalesLot> lots) {
        if (lots.isEmpty()) {
            System.out.println("No hay lotes disponibles.");
            return;
        }
        System.out.println("Lotes disponibles (primero los que vencen antes):");
        List<String[]> rows = new ArrayList<>();
        for (SalesLot l : lots) {
            String descuento = l.discountRate().signum() > 0
                    ? l.discountRate().multiply(BigDecimal.valueOf(100)).stripTrailingZeros().toPlainString() + "%"
                    : "-";
            rows.add(new String[]{String.valueOf(l.lotId()), l.lotNumber(), l.product(),
                    String.valueOf(l.expirationDate()), String.valueOf(l.quantity()),
                    "$" + l.salePrice(), l.status(), descuento});
        }
        ConsoleTable.printTable(new String[]{"Id", "Numero de lote", "Producto", "Vence",
            "Existencias", "Precio", "Estado", "Descuento"}, rows);
    }

    private void showOrderSummary(List<OrderLine> orderLines) {
        BigDecimal total = BigDecimal.ZERO;
        System.out.println("\nResumen del pedido:");
        List<String[]> rows = new ArrayList<>();
        for (OrderLine l : orderLines) {
            rows.add(new String[]{l.lot().product(), String.valueOf(l.quantity()),
                    "$" + l.subtotal(), "$" + l.discountAmount(), "$" + l.taxAmount(),
                    "$" + l.lineTotal()});
            total = total.add(l.lineTotal());
        }
        ConsoleTable.printTable(new String[]{"Producto", "Cantidad", "Subtotal", "Descuento", "Impuesto", "Total"}, rows);
        System.out.println("TOTAL: $" + total);
    }

    private static int parseInteger(String text) {
        try {
            return Integer.parseInt(text.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + text + "' no es un numero valido.");
        }
    }

    private static BigDecimal parseDecimal(String text) {
        try {
            return new BigDecimal(text.trim().replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + text + "' no es una cantidad valida.");
        }
    }

    private String ask(String label) {
        System.out.print(label + ": ");
        return input.nextLine().trim();
    }
}
