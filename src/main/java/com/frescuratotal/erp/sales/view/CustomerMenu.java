package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.controller.CustomerController;
import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.common.ConsoleTable;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;

/**
 * Menu de consola del modulo de clientes. Punto de entrada para el menu principal:
 * new CustomerMenu(scanner, DatabaseConnection.getConnection()).run();
 */
public class CustomerMenu {

    private final Scanner input;
    private final CustomerController controller;

    public CustomerMenu(Scanner input, Connection connection) {
        this.input = input;
        this.controller = new CustomerController(new CustomerDao(connection));
    }

    public void run() {
        while (true) {
            System.out.println("\n--- Clientes ---");
            System.out.println("1. Listar");
            System.out.println("2. Buscar por id");
            System.out.println("3. Crear");
            System.out.println("4. Actualizar");
            System.out.println("5. Eliminar");
            System.out.println("0. Volver");
            String option = ask("Opcion");
            if (option.equals("0")) {
                return;
            }
            try {
                switch (option) {
                    case "1" -> printCustomers(controller.list());
                    case "2" -> print(controller.get(askId()));
                    case "3" -> create();
                    case "4" -> update();
                    case "5" -> delete();
                    default -> System.out.println("Opcion no valida.");
                }
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Error de base de datos: " + e.getMessage());
            }
        }
    }

    private void create() throws SQLException {
        String name = ask("Nombre");
        String document = ask("Documento");
        String email = ask("Correo (opcional)");
        String phone = ask("Telefono (opcional)");
        String address = ask("Direccion (opcional)");
        int typeId = askType();
        controller.create(new Customer(0, name, document, email, phone, address, typeId, null, null));
        System.out.println("Cliente creado.");
    }

    // Enter en cualquier campo conserva su valor actual.
    private void update() throws SQLException {
        Customer old = controller.get(askId());
        String name = askKeep("Nombre", old.name());
        String document = askKeep("Documento", old.document());
        String email = askKeep("Correo", old.email());
        String phone = askKeep("Telefono", old.phone());
        String address = askKeep("Direccion", old.address());
        int typeId = askType(old.typeId());
        controller.update(new Customer(old.customerId(), name, document, email, phone, address, typeId, null, null));
        System.out.println("Cliente actualizado.");
    }

    private void delete() throws SQLException {
        controller.delete(askId());
        System.out.println("Cliente eliminado.");
    }

    private int askType() throws SQLException {
        return askType(-1);
    }

    private int askType(int current) throws SQLException {
        Map<Integer, String> types = controller.types();
        types.forEach((id, name) -> System.out.println("  " + id + " = " + name));
        String text = ask("Id del tipo" + (current > 0 ? " (Enter conserva " + current + ")" : ""));
        if (text.isEmpty() && current > 0) {
            return current;
        }
        return parseInt(text);
    }

    private int askId() {
        return parseInt(ask("Id del cliente"));
    }

    private static int parseInt(String text) {
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

    private String askKeep(String label, String current) {
        String text = ask(label + " [" + (current == null ? "" : current) + "]");
        return text.isEmpty() ? current : text;
    }

    private static void print(Customer c) {
        System.out.printf("#%d | %s | documento: %s | %s | correo: %s | telefono: %s | direccion: %s | registro: %s%n",
                c.customerId(), c.name(), c.document(), c.typeName(),
                c.email(), c.phone(), c.address(), c.registrationDate());
    }

    private static void printCustomers(List<Customer> customers) {
        if (customers.isEmpty()) {
            System.out.println("No hay clientes registrados.");
            return;
        }

        List<String[]> rows = new ArrayList<>();
        DateTimeFormatter formatDate = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        for (Customer customer : customers) {
            String registro = customer.registrationDate() == null
                    ? "-"
                    : customer.registrationDate().toLocalDateTime().format(formatDate);
            rows.add(new String[]{customer.name(), customer.document(), customer.typeName(), customer.phone(), registro});
        }
        ConsoleTable.printTable(
                new String[]{"Nombre", "Documento", "Tipo", "Telefono", "Registro"}, rows);
    }
}
