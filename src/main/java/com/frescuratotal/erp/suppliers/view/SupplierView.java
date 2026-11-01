/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.suppliers.view;

import com.frescuratotal.erp.suppliers.controller.SupplierController;
import com.frescuratotal.erp.suppliers.model.Supplier;
import java.sql.SQLException;
import java.util.List;
import java.util.Scanner;

/**
 *
 * @author admin
 */
public class SupplierView {

    private final Scanner scanner;
    private final SupplierController controller;

    public SupplierView(Scanner scanner, SupplierController controller) {
        this.scanner = scanner;
        this.controller = controller;
    }

    public void show() {
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
            System.out.println("0. Volver");
            System.out.print("Seleccione una opcion: ");

            String option = scanner.nextLine().trim();

            try {
                switch (option) {
                    case "1" -> listSuppliers();
                    case "2" -> addSupplier();
                    case "3" -> updateSupplier();
                    case "4" -> deactivateSupplier();
                    case "5" -> showCatalog();
                    case "6" -> addToCatalog();
                    case "7" -> removeFromCatalog();                    
                    case "0" -> back = true;
                    default -> System.out.println("Opcion invalida !!");
                }
            } catch (SQLException | IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private void listSuppliers() throws SQLException {
        List<Supplier> suppliers = controller.listSuppliers();
        if (suppliers.isEmpty()) {
            System.out.println("No hay proveedores registrados aun");
        }
        for (Supplier supplier : suppliers) {
            System.out.println(supplier);
        }
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
    
    //RELACION PROVEEDOR-PRODUCTO METODOS
    private void showCatalog() throws SQLException {
        int supplierId = askInt("Id del proveedor ");
        List<String> lines = controller.listCatalog(supplierId);
        if (lines.isEmpty()) {
            System.out.println("Este proveedor no tiene productos en el catalogo aun...");
        }
        for (String line : lines) {
            System.out.println(line);
        }
    }

    private void addToCatalog() throws SQLException {
        int supplierId = askInt("Id del proveedor: ");
        System.out.println("Productos:");
        for (String option : controller.listProductOptions()) {
            System.out.println("  " + option);
        }
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
    // FIN PROVEEDOR PRODUCTO 

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
}
