package com.frescuratotal.erp.suppliers.view;

import com.frescuratotal.erp.common.ConsoleTable;
import com.frescuratotal.erp.suppliers.model.CommercialStatistics;
import com.frescuratotal.erp.suppliers.controller.SupplierController;
//punto 2
import com.frescuratotal.erp.suppliers.model.DailyPurchaseReport;
import com.frescuratotal.erp.suppliers.model.Supplier;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

public class SupplierView {

    private final Scanner scanner;
    private final SupplierController controller;

    public SupplierView(Scanner scanner, SupplierController controller) {
        this.scanner = scanner;
        this.controller = controller;
    }

    public void show() {
        Map<String, MenuAction> actions = Map.of(
                "1", this::listSuppliers,
                "2", this::addSupplier,
                "3", this::updateSupplier,
                "4", this::deactivateSupplier,
                "5", this::showCatalog,
                "6", this::addToCatalog,
                "7", this::removeFromCatalog,
                "8", this::showCommercialStatistics,
                // Punto 2. Para ventas: mover esta opción al menú SalesMenu.
                "9", this::generateDailyPurchaseReport);
        boolean back = false;

        while (!back) {
            System.out.println("\n--- PROVEEDORES ---");
            System.out.println("1. Listar proveedores");
            System.out.println("2. Registrar proveedor");
            System.out.println("3. Modificar proveedor");
            System.out.println("4. Desactivar proveedor");
            System.out.println("5. Ver catalogo del proveedor");
            System.out.println("6. Agregar producto al catalogo");
            System.out.println("7. Quitar producto del catalogo");            
            // Punto 5: muestra la opción. Para "menos vendidos" cambiar solo el texto.
            System.out.println("8. Generar Estadisticas Comerciales");
            System.out.println("9. Generar Reporte Diario de Compras");
            System.out.println("0. Volver");
            System.out.print("Seleccione una opcion: ");

            String option = scanner.nextLine().trim();

            try {
                if (option.equals("0")) {
                    back = true;
                } else {
                    actions.getOrDefault(option, () -> System.out.println("Opcion invalida !!")).run();
                }                   //punto 2
            } catch (SQLException | IOException | IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }
    

    private void showCommercialStatistics() throws SQLException {
        CommercialStatistics statistics = controller.generateCommercialStatistics();
        if (!statistics.hasSales()) {
            System.out.println("No existen datos suficientes para generar estadísticas comerciales.");
            return;
        }

        System.out.println("\n===== Reporte de Rendimiento de Proveedores  =====");
        if (statistics.topCategory() == null) {
            System.out.println("No hay proveedores confirmadas para calcular la categoria principal.");
        } else {
            String quantity = statistics.topQuantity().stripTrailingZeros().toPlainString();
            // Para "menos vendidos": cambiar "mayor" por "menor"; la cantidad se imprime igual.
            System.out.println("Proveedor con mayor volumen de suministro: " + statistics.topCategory()
                    + " - " + quantity + " unidades");
        }
        // Para otro reporte: reemplazar este apartado por la segunda estadística solicitada.
        System.out.println("Proveedores con Lotes Vencidos Registrados:");
        if (statistics.customersWithReturns().isEmpty()) {
            System.out.println("No hay proveedores con lotes vencidos registrados.");
        } else {
            statistics.customersWithReturns().stream()
                    .map(customer -> "- " + customer)
                    .forEach(System.out::println);
        }
    }        
    

    private void listSuppliers() throws SQLException {
        List<Supplier> suppliers = controller.listSuppliers();
        if (suppliers.isEmpty()) {
            System.out.println("No hay proveedores registrados aun");
            return;
        }

        List<String[]> rows = suppliers.stream()
                .map(supplier -> new String[]{String.valueOf(supplier.getId()), supplier.getName(), supplier.getNit(),
                    supplier.getEmail(), supplier.isActive() ? "Activo" : "Inactivo"})
                .toList();
        ConsoleTable.printTable(new String[]{"Id", "Nombre", "NIT", "Correo", "Estado"}, rows);
    }

    private void addSupplier() throws SQLException {
        String name = ask("Nombre: ");
        String nit = ask("NIT: ");
        String contact = ask("Persona del contacto: ");
        String email = ask("Email: ");
        String phone = ask("Numero de telefonico: ");
        String address = ask("Direccion : ");

        controller.addSupplier(new Supplier(0, name, nit, contact, email, phone, address, true));
        System.out.println("Proveedor anadido!! ");
    }

    private void updateSupplier() throws SQLException {
        int id = askInt("ID del proveedor a actualizar: ");
        String name = ask("Nuevo nombre: ");
        String nit = ask("Nuevi Nit : ");
        String contact = ask("Nueva persona del contacto: ");
        String email = ask("Nuevo email: ");
        String phone = ask("Nuevo numero telefonico: ");
        String address = ask("Nueva direccion: ");

        boolean updated = controller.updateSupplier(
                new Supplier(id, name, nit, contact, email, phone, address, true));
        System.out.println(updated ? "Proveedor actualizado" : "Proveedor no actualizado");
    }

    private void deactivateSupplier() throws SQLException {
        int id = askInt("Id del proveedor a desactivar: ");
        boolean done = controller.deactivateSupplier(id);
        System.out.println(done ? "Proveedor desactivado!!" : "proveedor no encontrado");
    }
    
    private void showCatalog() throws SQLException {
        int supplierId = askInt("Id del proveedor ");
        List<String> lines = controller.listCatalog(supplierId);
        if (lines.isEmpty()) {
            System.out.println("Este proveedor no tiene productos en el catalogo aun...");
        }
        lines.forEach(System.out::println);
    }

    private void addToCatalog() throws SQLException {
        int supplierId = askInt("Id del proveedor: ");
        System.out.println("Productos:");
        controller.listProductOptions().forEach(option -> System.out.println("  " + option));
        int productId = askInt("Id del producto a anadir: ");
        controller.addToCatalog(supplierId, productId);
        System.out.println("Producto anadido al catalogo!!");
    }

    private void removeFromCatalog() throws SQLException {
        int supplierId = askInt("Id del proveedor: ");
        int productId = askInt("Id del producto a quitar: ");
        boolean removed = controller.removeFromCatalog(supplierId, productId);
        System.out.println(removed ? "El producto ha sido retirado exitosamente del catalogo!!!" : "Ese producto no se ha encontrado en este catalogo...");
    }   
    
    // Punto 2: genera el reporte de hoy sin solicitar datos.
    // Para ventas: llamar generateDailySalesReport e indicar "ventas" al usuario.
    private void generateDailyPurchaseReport() throws SQLException, IOException {
        DailyPurchaseReport report = controller.generateDailyPurchaseReport();
        System.out.println("Reporte creado: " + report.file().toAbsolutePath());
        if (report.purchaseCount() == 0) {
            System.out.println("No hay compras realizadas hoy para reportar.");
        } else {
            System.out.println("Compras incluidas: " + report.purchaseCount());
        }
    }

    private String ask(String prompt) {
        System.out.print(prompt);
        return scanner.nextLine().trim();
    }

    private int askInt(String prompt) {
        String text = ask(prompt);
        try {
            return Integer.parseInt(text);
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("El id debe ser un numero valido...");
        }
    }

    @FunctionalInterface
    private interface MenuAction {
        void run() throws SQLException, IOException;
    }
}
