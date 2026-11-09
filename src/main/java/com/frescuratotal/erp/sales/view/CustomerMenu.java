package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.controller.CustomerController;
import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.common.ConsoleTable;
import java.io.IOException;
import java.nio.file.Path;
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
        Map<String, MenuAction> actions = Map.of(
                "1", () -> printCustomers(controller.list()),
                "2", () -> print(controller.get(askId())),
                "3", this::create,
                "4", this::update,
                "5", this::delete,
                // Punto 4: opción de importación masiva.
                // Para otra entidad: moverla al menú de Productos o Proveedores.
                "6", this::importCustomers);
        while (true) {
            System.out.println("\n--- Clientes ---");
            System.out.println("1. Listar");
            System.out.println("2. Buscar por id");
            System.out.println("3. Crear");
            System.out.println("4. Actualizar");
            System.out.println("5. Eliminar");
            // Punto 4: muestra la opción de importación masiva.
            // Para otra entidad: cambiar el texto por "Importar Productos desde Archivo".
            System.out.println("6. Importar Clientes desde Archivo");
            System.out.println("0. Volver");
            String option = ask("Opcion");
            if (option.equals("0")) {
                return;
            }
            try {
                actions.getOrDefault(option, () -> System.out.println("Opcion no valida.")).run();
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Error de base de datos: " + e.getMessage());
            } catch (IOException e) {
                System.out.println("Error: " + e.getMessage());
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

    // Punto 4: importa el archivo ubicado en la raíz del proyecto.
    // Para productos: usar productos_importar.txt y llamar al controlador de productos.
    private void importCustomers() throws SQLException, IOException {
        int total = controller.importCustomersFromFile(Path.of("clientes_importar.txt"));
        System.out.println("Importación completada. Total de clientes registrados: " + total);
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

        DateTimeFormatter formatDate = DateTimeFormatter.ofPattern("dd/MM/yyyy");
        List<String[]> rows = customers.stream()
                .map(customer -> {
                    String registrationDate = customer.registrationDate() == null
                    ? "-"
                    : customer.registrationDate().toLocalDateTime().format(formatDate);
                    return new String[]{customer.name(), customer.document(), customer.typeName(),
                        customer.phone(), registrationDate};
                })
                .toList();
        ConsoleTable.printTable(
                new String[]{"Nombre", "Documento", "Tipo", "Telefono", "Registro"}, rows);
    }

    @FunctionalInterface
    // Punto 4: permite informar errores al leer el archivo.
    private interface MenuAction {
        void run() throws SQLException, IOException;
    }
}
