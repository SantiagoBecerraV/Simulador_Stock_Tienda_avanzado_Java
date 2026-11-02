package com.frescuratotal.erp.customers.view;

import com.frescuratotal.erp.customers.controller.CustomerController;
import com.frescuratotal.erp.customers.dao.CustomerDao;
import com.frescuratotal.erp.customers.model.Customer;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Map;
import java.util.Scanner;

/**
 * Menú de consola del módulo de clientes. Punto de entrada para el menú principal:
 * new CustomerMenu(scanner, DatabaseConnection.getConnection()).run();
 */
public class CustomerMenu {

    private final Scanner in;
    private final CustomerController controller;

    public CustomerMenu(Scanner in, Connection connection) {
        this.in = in;
        this.controller = new CustomerController(new CustomerDao(connection));
    }

    public void run() {
        while (true) {
            System.out.println("\n--- Customers ---");
            System.out.println("1. List  2. Find by ID  3. Create  4. Update  5. Delete  0. Back");
            String option = ask("Option");
            if (option.equals("0")) {
                return;
            }
            try {
                switch (option) {
                    case "1" -> controller.list().forEach(CustomerMenu::print);
                    case "2" -> print(controller.get(askId()));
                    case "3" -> create();
                    case "4" -> update();
                    case "5" -> delete();
                    default -> System.out.println("Invalid option.");
                }
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Database error: " + e.getMessage());
            }
        }
    }

    private void create() throws SQLException {
        String name = ask("Name");
        String document = ask("Document");
        String email = ask("Email (optional)");
        String phone = ask("Phone (optional)");
        String address = ask("Address (optional)");
        int typeId = askType();
        controller.create(new Customer(0, name, document, email, phone, address, typeId, null, null));
        System.out.println("Customer created.");
    }

    // Enter en cualquier campo conserva su valor actual.
    private void update() throws SQLException {
        Customer old = controller.get(askId());
        String name = askKeep("Name", old.name());
        String document = askKeep("Document", old.document());
        String email = askKeep("Email", old.email());
        String phone = askKeep("Phone", old.phone());
        String address = askKeep("Address", old.address());
        int typeId = askType(old.typeId());
        controller.update(new Customer(old.customerId(), name, document, email, phone, address, typeId, null, null));
        System.out.println("Customer updated.");
    }

    private void delete() throws SQLException {
        controller.delete(askId());
        System.out.println("Customer deleted.");
    }

    private int askType() throws SQLException {
        return askType(-1);
    }

    private int askType(int current) throws SQLException {
        Map<Integer, String> types = controller.types();
        types.forEach((id, name) -> System.out.println("  " + id + " = " + name));
        String text = ask("Type id" + (current > 0 ? " (Enter keeps " + current + ")" : ""));
        if (text.isEmpty() && current > 0) {
            return current;
        }
        return parseInt(text);
    }

    private int askId() {
        return parseInt(ask("Customer id"));
    }

    private static int parseInt(String text) {
        try {
            return Integer.parseInt(text.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + text + "' is not a valid number.");
        }
    }

    private String ask(String label) {
        System.out.print(label + ": ");
        return in.nextLine().trim();
    }

    private String askKeep(String label, String current) {
        String text = ask(label + " [" + (current == null ? "" : current) + "]");
        return text.isEmpty() ? current : text;
    }

    private static void print(Customer c) {
        System.out.printf("#%d | %s | doc: %s | %s | email: %s | phone: %s | address: %s | registered: %s%n",
                c.customerId(), c.name(), c.document(), c.typeName(),
                c.email(), c.phone(), c.address(), c.registrationDate());
    }
}
