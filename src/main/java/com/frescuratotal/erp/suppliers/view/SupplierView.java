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
            System.out.println("\n--- SUPPLIERS ---");
            System.out.println("1. List suppliers");
            System.out.println("2. Add supplier");
            System.out.println("3. Update supplier");
            System.out.println("4. Deactivate supplier");
            System.out.println("0. Back");
            System.out.print("Choose an option: ");

            String option = scanner.nextLine().trim();

            try {
                switch (option) {
                    case "1" -> listSuppliers();
                    case "2" -> addSupplier();
                    case "3" -> updateSupplier();
                    case "4" -> deactivateSupplier();
                    case "0" -> back = true;
                    default -> System.out.println("Invalid option");
                }
            } catch (SQLException | IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private void listSuppliers() throws SQLException {
        List<Supplier> suppliers = controller.listSuppliers();
        if (suppliers.isEmpty()) {
            System.out.println("There are no suppliers yet");
        }
        for (Supplier supplier : suppliers) {
            System.out.println(supplier);
        }
    }

    private void addSupplier() throws SQLException {
        String name = ask("Name: ");
        String nit = ask("NIT: ");
        String contact = ask("Contact person: ");
        String email = ask("Email: ");
        String phone = ask("Phone: ");
        String address = ask("Address: ");

        controller.addSupplier(new Supplier(0, name, nit, contact, email, phone, address, true));
        System.out.println("Supplier added");
    }

    private void updateSupplier() throws SQLException {
        int id = askInt("Supplier ID to update: ");
        String name = ask("New name: ");
        String nit = ask("New NIT: ");
        String contact = ask("New contact person: ");
        String email = ask("New email: ");
        String phone = ask("New phone: ");
        String address = ask("New address: ");

        boolean updated = controller.updateSupplier(
                new Supplier(id, name, nit, contact, email, phone, address, true));
        System.out.println(updated ? "Supplier updated" : "Supplier not found");
    }

    private void deactivateSupplier() throws SQLException {
        int id = askInt("Supplier ID to deactivate: ");
        boolean done = controller.deactivateSupplier(id);
        System.out.println(done ? "Supplier deactivated" : "Supplier not found");
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
            throw new IllegalArgumentException("ID must be a number");
        }
    }
}
