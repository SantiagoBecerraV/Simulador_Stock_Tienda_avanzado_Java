package com.frescuratotal.erp;

import com.frescuratotal.erp.common.DatabaseConnection;
import com.frescuratotal.erp.suppliers.controller.SupplierController;
import com.frescuratotal.erp.suppliers.view.SupplierView;
import com.frescuratotal.erp.inventory.controller.ProductController;
import com.frescuratotal.erp.inventory.view.ProductView;
import com.frescuratotal.erp.inventory.controller.LotController;
import com.frescuratotal.erp.inventory.view.LotView;
import com.frescuratotal.erp.sales.view.CustomerMenu;
import com.frescuratotal.erp.sales.view.MenuFacturacion;
import com.frescuratotal.erp.sales.view.MenuLogistica;
import com.frescuratotal.erp.sales.view.MenuVentas;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Scanner;

public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        SupplierView supplierView = new SupplierView(scanner, new SupplierController());
        ProductView productView = new ProductView(scanner, new ProductController());    
        LotView lotView = new LotView(scanner, new LotController());
        boolean running = true;

        while (running) {
            printMenu();
            int option = readOption(scanner);

            switch (option) {
                case 1 -> productView.show();
                case 2 -> supplierView.show();
                case 3 -> lotView.show();
                case 4, 5, 6, 7 -> abrirModuloDeVentas(option, scanner);
                case 0 -> {
                    running = false;
                    System.out.println("Saliendo...\n");
                }
                default -> System.out.println("Opcion invalida.\n");
            }
        }

        scanner.close();
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
        System.out.println("0. Salir");
        System.out.print("Escoge una opcion: ");
    }

    // Los menus de ventas, facturacion, clientes y logistica comparten la misma conexion.
    private static void abrirModuloDeVentas(int option, Scanner scanner) {
        try {
            Connection conexion = DatabaseConnection.getConnection();
            switch (option) {
                case 4 -> new MenuVentas(scanner, conexion).ejecutar();
                case 5 -> new MenuFacturacion(scanner, conexion).ejecutar();
                case 6 -> new CustomerMenu(scanner, conexion).run();
                case 7 -> new MenuLogistica(scanner, conexion).ejecutar();
            }
        } catch (SQLException e) {
            System.out.println("No se pudo conectar a la base de datos: " + e.getMessage());
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
