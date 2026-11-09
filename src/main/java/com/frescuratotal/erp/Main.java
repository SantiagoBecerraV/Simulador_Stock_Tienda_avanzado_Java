package com.frescuratotal.erp;

import com.frescuratotal.erp.suppliers.analytics.SupplierAnalyticsService;
import com.frescuratotal.erp.common.DatabaseConnection;
import com.frescuratotal.erp.suppliers.controller.SupplierController;
import com.frescuratotal.erp.suppliers.view.SupplierView;
import com.frescuratotal.erp.inventory.controller.ProductController;
import com.frescuratotal.erp.inventory.view.ProductView;
import com.frescuratotal.erp.inventory.controller.LotController;
import com.frescuratotal.erp.inventory.view.LotView;
import com.frescuratotal.erp.sales.view.CustomerMenu;
import com.frescuratotal.erp.sales.view.BillingMenu;
import com.frescuratotal.erp.sales.view.LogisticsMenu;
import com.frescuratotal.erp.sales.view.SalesMenu;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;
import java.util.Scanner;
import java.util.function.IntConsumer;

public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        Runtime.getRuntime().addShutdownHook(new Thread(Main::closeDatabaseConnection));
        SupplierView supplierView = new SupplierView(scanner, new SupplierController());
        ProductView productView = new ProductView(scanner, new ProductController());    
        LotView lotView = new LotView(scanner, new LotController());
        SupplierAnalyticsService analyticsService = new SupplierAnalyticsService();
        Map<Integer, IntConsumer> actions = Map.of(
                1, ignored -> productView.show(),
                2, ignored -> supplierView.show(),
                3, ignored -> lotView.show(),
                4, option -> openSalesModule(option, scanner),
                5, option -> openSalesModule(option, scanner),
                6, option -> openSalesModule(option, scanner),
                7, option -> openSalesModule(option, scanner),
                8, ignored -> analyticsService.generarReporte());

        try {
            while (true) {
                printMenu();
                int option = readOption(scanner);
                if (option == 0) {
                    System.out.println("Saliendo...\n");
                    break;
                }
                try {
                    actions.getOrDefault(option, ignored -> System.out.println("Opcion invalida.\n"))
                            .accept(option);
                } catch (Exception e) {
                    System.out.println("Ocurrio un error en el modulo. Puedes volver a intentarlo.");
                    e.printStackTrace();
                }
            }
        } finally {
            scanner.close();
            closeDatabaseConnection();
        }
    }

    private static void printMenu() {
        System.out.println("\n=== FRESCURA TOTAL ===");
        System.out.println("1. Productos");
        System.out.println("2. Proveedores");
        System.out.println("3. Inventario");
        System.out.println("4. Ventas");
        System.out.println("5. Facturacion");
        System.out.println("6. Clientes");
        System.out.println("7. Logistica");
        System.out.println("8. Generar Reporte de Rendimiento de Proveedores");
        System.out.println("0. Salir");
        System.out.print("Escoge una opcion: ");
    }

    // Los menus de ventas, facturacion, clientes y logistica comparten la misma conexion.
    private static void openSalesModule(int option, Scanner scanner) {
        try {
            Connection connection = DatabaseConnection.getConnection();
            Map<Integer, Runnable> actions = Map.of(
                    4, () -> new SalesMenu(scanner, connection).run(),
                    5, () -> new BillingMenu(scanner, connection).run(),
                    6, () -> new CustomerMenu(scanner, connection).run(),
                    7, () -> new LogisticsMenu(scanner, connection).run());
            actions.getOrDefault(option, () -> System.out.println("Opcion invalida.\n")).run();
        } catch (SQLException e) {
            System.out.println("No se pudo conectar a MySQL en localhost:3307: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static void closeDatabaseConnection() {
        try {
            DatabaseConnection.close();
        } catch (SQLException e) {
            System.out.println("No se pudo cerrar la conexion a la base de datos: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static int readOption(Scanner scanner) {
        while (true) {
            String line = scanner.nextLine().trim();
            try {
                return Integer.parseInt(line);
            } catch (NumberFormatException e) {
                System.out.print("Error: ingresa un numero valido: ");
            }
        }
    }
}
