package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.common.ConsoleTable;
import com.frescuratotal.erp.sales.controller.LogisticsController;
import com.frescuratotal.erp.sales.dao.LogisticsDao;
import com.frescuratotal.erp.sales.model.Driver;
import com.frescuratotal.erp.sales.model.VehicleStatus;
import com.frescuratotal.erp.sales.model.Route;
import com.frescuratotal.erp.sales.model.Vehicle;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.stream.IntStream;

/**
 * Menu de consola del modulo de Logistica. Punto de entrada para el menu principal:
 * new LogisticsMenu(scanner, DatabaseConnection.getConnection()).run();
 */
public class LogisticsMenu {

    private final Scanner input;
    private final LogisticsController controller;

    public LogisticsMenu(Scanner input, Connection connection) {
        this.input = input;
        this.controller = new LogisticsController(new LogisticsDao(connection));
    }

    public void run() {
        Map<String, Runnable> actions = Map.of(
                "1", () -> runSafely(this::showSalesInPreparation, ""),
                "2", () -> showSubmenu("Vehiculos", this::handleVehicleOption,
                        "Listar", "Crear", "Cambiar estado", "Editar", "Eliminar"),
                "3", () -> showSubmenu("Conductores", this::handleDriverOption,
                        "Listar", "Crear", "Activar/desactivar", "Editar", "Eliminar"),
                "4", () -> showSubmenu("Rutas", this::handleRouteOption,
                        "Listar", "Crear", "Ver ventas", "Editar", "Cancelar"),
                "5", () -> showSubmenu("Asignaciones", this::handleAssignmentOption,
                        "Asignar vehiculo y conductor a ruta", "Asignar venta a ruta", "Quitar venta de ruta"),
                "6", () -> showSubmenu("Despacho y entregas", this::handleDispatchOption,
                        "Iniciar despacho", "Confirmar entrega"));
        while (true) {
            System.out.println("\n--- Logistica ---");
            System.out.println("1. Ventas en preparacion");
            System.out.println("2. Vehiculos");
            System.out.println("3. Conductores");
            System.out.println("4. Rutas");
            System.out.println("5. Asignaciones");
            System.out.println("6. Despacho y entregas");
            System.out.println("0. Volver");
            String option = ask("Opcion");
            if (option.equals("0")) {
                return;
            }
            actions.getOrDefault(option, () -> System.out.println("Opcion no valida.")).run();
        }
    }

    // Lo que hace un submenu con la opcion elegida (por ejemplo opcionVehiculos).
    private interface MenuAction {
        void run(String option) throws SQLException;
    }

    // Muestra el submenu hasta que el usuario elige 0. Cada submenu decide sus opciones en su propio switch.
    private void showSubmenu(String title, MenuAction action, String... optionNames) {
        while (true) {
            System.out.println("\n--- " + title + " ---");
            IntStream.range(0, optionNames.length)
                    .forEach(i -> System.out.println((i + 1) + ". " + optionNames[i]));
            System.out.println("0. Volver");
            String option = ask("Opcion");
            if (option.equals("0")) {
                return;
            }
            runSafely(action, option);
        }
    }

    // Un error de datos o de base de datos se muestra y el menu sigue funcionando.
    private void runSafely(MenuAction action, String option) {
        try {
            action.run(option);
        } catch (IllegalArgumentException e) {
            System.out.println(e.getMessage());
        } catch (SQLException e) {
            System.out.println("Error de base de datos: " + e.getMessage());
        }
    }

    // La opcion no se usa: esta accion no tiene submenu.
    private void showSalesInPreparation(String option) throws SQLException {
        var sales = controller.listSalesInPreparation();
        if (sales.isEmpty()) {
            System.out.println("No hay ventas en preparacion.");
            return;
        }

        List<String[]> rows = sales.stream()
                .map(sale -> new String[]{String.valueOf(sale.saleId()), sale.saleNumber(), sale.customer(),
                    sale.address(), "$" + sale.totalAmount(),
                    sale.routeId() == null ? "Sin ruta" : "Ruta #" + sale.routeId()})
                .toList();
        ConsoleTable.printTable(new String[]{"Id venta", "Numero", "Cliente", "Direccion", "Total", "Ruta"}, rows);
    }

    private void showVehicles() throws SQLException {
        var vehicles = controller.listVehicles();
        if (vehicles.isEmpty()) {
            System.out.println("No hay vehiculos registrados.");
            return;
        }

        List<String[]> rows = vehicles.stream()
                .map(vehicle -> new String[]{String.valueOf(vehicle.vehicleId()), vehicle.licensePlate(),
                    vehicle.model(), vehicle.capacity() == null ? "-" : vehicle.capacity().toPlainString(),
                    vehicle.status().databaseValue()})
                .toList();
        ConsoleTable.printTable(new String[]{"Id", "Placa", "Modelo", "Capacidad", "Estado"}, rows);
    }

    private void showDrivers() throws SQLException {
        var drivers = controller.listDrivers();
        if (drivers.isEmpty()) {
            System.out.println("No hay conductores registrados.");
            return;
        }

        List<String[]> rows = drivers.stream()
                .map(driver -> new String[]{String.valueOf(driver.driverId()), driver.name(),
                    driver.licenseNumber(), driver.phone(), driver.active() ? "Activo" : "Inactivo"})
                .toList();
        ConsoleTable.printTable(new String[]{"Id", "Nombre", "Licencia", "Telefono", "Estado"}, rows);
    }

    private void showRoutes() throws SQLException {
        var routes = controller.listRoutes();
        if (routes.isEmpty()) {
            System.out.println("No hay rutas registradas.");
            return;
        }

        List<String[]> rows = routes.stream()
                .map(route -> new String[]{String.valueOf(route.routeId()), route.routeName(),
                    route.status().databaseValue(), route.licensePlate(), route.driver(),
                    formatDate(route.estimatedDeparture())})
                .toList();
        ConsoleTable.printTable(new String[]{"Id", "Ruta", "Estado", "Vehiculo", "Conductor", "Salida estimada"}, rows);
    }

    private void showDeliveries(int routeId) throws SQLException {
        var deliveries = controller.listDeliveries(routeId);
        if (deliveries.isEmpty()) {
            System.out.println("La ruta no tiene ventas asignadas.");
            return;
        }

        List<String[]> rows = deliveries.stream()
                .map(delivery -> new String[]{String.valueOf(delivery.deliveryOrder()),
                    String.valueOf(delivery.saleId()), delivery.saleNumber(), delivery.deliveryAddress(),
                    delivery.deliveryDate() == null ? "Pendiente" : delivery.deliveryDate().toString(),
                    delivery.receivedBy(), delivery.observations()})
                .toList();
        ConsoleTable.printTable(new String[]{"Orden", "Id venta", "Numero", "Destino", "Entregada",
            "Recibio", "Observaciones"}, rows);
    }

    // 1 Listar, 2 Crear, 3 Cambiar estado, 4 Editar, 5 Eliminar.
    private void handleVehicleOption(String option) throws SQLException {
        Map<String, MenuAction> actions = Map.of(
            "1", ignored -> showVehicles(),
            "2", ignored -> {
                controller.createVehicle(ask("Placa"), ask("Modelo (opcional)"),
                        readOptionalDecimal(ask("Capacidad (opcional)")));
                System.out.println("Vehiculo creado.");
            },
            "3", ignored -> {
                int id = readInteger(ask("Id del vehiculo"));
                controller.changeVehicleStatus(id, askVehicleStatus());
                System.out.println("Estado del vehiculo actualizado.");
            },
            "4", ignored -> {
                // Enter en un campo conserva su valor actual.
                Vehicle v = controller.findVehicle(readInteger(ask("Id del vehiculo")));
                controller.updateVehicle(v.vehicleId(), keepCurrentValue("Placa", v.licensePlate()),
                        keepCurrentValue("Modelo", v.model()),
                        readOptionalDecimal(keepCurrentValue("Capacidad", v.capacity() == null ? "" : v.capacity().toPlainString())));
                System.out.println("Vehiculo actualizado.");
            },
            "5", ignored -> {
                controller.deleteVehicle(readInteger(ask("Id del vehiculo")));
                System.out.println("Vehiculo eliminado.");
            });
        executeOption(option, actions);
    }

    // 1 Listar, 2 Crear, 3 Activar/desactivar, 4 Editar, 5 Eliminar.
    private void handleDriverOption(String option) throws SQLException {
        Map<String, MenuAction> actions = Map.of(
            "1", ignored -> showDrivers(),
            "2", ignored -> {
                controller.createDriver(ask("Nombre"), ask("Numero de licencia"),
                        ask("Telefono (opcional)"), ask("Correo (opcional)"));
                System.out.println("Conductor creado.");
            },
            "3", ignored -> {
                int id = readInteger(ask("Id del conductor"));
                boolean active = ask("Activo? (s/n)").equalsIgnoreCase("s");
                controller.changeDriverActiveStatus(id, active);
                System.out.println("Conductor actualizado.");
            },
            "4", ignored -> {
                Driver c = controller.findDriver(readInteger(ask("Id del conductor")));
                controller.updateDriver(c.driverId(), keepCurrentValue("Nombre", c.name()),
                        keepCurrentValue("Numero de licencia", c.licenseNumber()), keepCurrentValue("Telefono", c.phone()),
                        keepCurrentValue("Correo", c.email()));
                System.out.println("Conductor actualizado.");
            },
            "5", ignored -> {
                controller.deleteDriver(readInteger(ask("Id del conductor")));
                System.out.println("Conductor eliminado.");
            });
        executeOption(option, actions);
    }

    // 1 Listar, 2 Crear, 3 Ver ventas, 4 Editar, 5 Cancelar.
    private void handleRouteOption(String option) throws SQLException {
        Map<String, MenuAction> actions = Map.of(
            "1", ignored -> showRoutes(),
            "2", ignored -> {
                controller.createRoute(ask("Nombre de la ruta"),
                        readOptionalDate(ask("Salida estimada aaaa-MM-dd HH:mm (opcional)")),
                        readOptionalDate(ask("Llegada estimada aaaa-MM-dd HH:mm (opcional)")));
                System.out.println("Ruta creada en estado Planificada.");
            },
            "3", ignored -> showDeliveries(readInteger(ask("Id de la ruta"))),
            "4", ignored -> {
                Route r = controller.findRoute(readInteger(ask("Id de la ruta")));
                controller.updateRoute(r.routeId(), keepCurrentValue("Nombre de la ruta", r.routeName()),
                        readOptionalDate(keepCurrentValue("Salida estimada aaaa-MM-dd HH:mm", formatDate(r.estimatedDeparture()))),
                        readOptionalDate(keepCurrentValue("Llegada estimada aaaa-MM-dd HH:mm", formatDate(r.estimatedArrival()))));
                System.out.println("Ruta actualizada.");
            },
            "5", ignored -> {
                controller.cancelRoute(readInteger(ask("Id de la ruta")));
                System.out.println("Ruta cancelada. Sus ventas quedaron libres para asignarlas a otra ruta.");
            });
        executeOption(option, actions);
    }

    // 1 Vehiculo y conductor a ruta, 2 Venta a ruta, 3 Quitar venta de ruta.
    private void handleAssignmentOption(String option) throws SQLException {
        Map<String, MenuAction> actions = Map.of(
            "1", ignored -> {
                controller.assignVehicleAndDriver(readInteger(ask("Id de la ruta")),
                        readInteger(ask("Id del vehiculo")), readInteger(ask("Id del conductor")));
                System.out.println("Vehiculo y conductor asignados.");
            },
            "2", ignored -> {
                int routeId = readInteger(ask("Id de la ruta"));
                int saleId = readInteger(ask("Id de la venta"));
                String order = ask("Orden de entrega (Enter = siguiente)");
                String address = ask("Direccion de destino (Enter = la del cliente)");
                controller.assignSale(routeId, saleId, order.isEmpty() ? null : readInteger(order), address);
                System.out.println("Venta asignada a la ruta.");
            },
            "3", ignored -> {
                controller.removeSaleFromRoute(readInteger(ask("Id de la ruta")),
                        readInteger(ask("Id de la venta")));
                System.out.println("Venta quitada de la ruta.");
            });
        executeOption(option, actions);
    }

    // 1 Iniciar despacho, 2 Confirmar entrega.
    private void handleDispatchOption(String option) throws SQLException {
        Map<String, MenuAction> actions = Map.of(
            "1", ignored -> {
                controller.startDispatch(readInteger(ask("Id de la ruta")));
                System.out.println("Despacho iniciado: la ruta y sus ventas quedaron En Transito.");
            },
            "2", ignored -> {
                boolean completed = controller.confirmDelivery(readInteger(ask("Id de la ruta")),
                        readInteger(ask("Id de la venta")), ask("Recibido por"),
                        ask("Observaciones (opcional)"));
                System.out.println("Entrega confirmada." + (completed ? " La ruta quedo Completada." : ""));
            });
        executeOption(option, actions);
    }

    private VehicleStatus askVehicleStatus() {
        VehicleStatus[] states = VehicleStatus.values();
        IntStream.range(0, states.length)
                .forEach(i -> System.out.println("  " + (i + 1) + " = " + states[i].databaseValue()));
        int number = readInteger(ask("Estado"));
        if (number < 1 || number > states.length) {
            throw new IllegalArgumentException("Estado no valido.");
        }
        return states[number - 1];
    }

    private void executeOption(String option, Map<String, MenuAction> actions) throws SQLException {
        actions.getOrDefault(option, ignored -> System.out.println("Opcion no valida.")).run(option);
    }

    private static int readInteger(String text) {
        try {
            return Integer.parseInt(text.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + text + "' no es un numero valido.");
        }
    }

    private static BigDecimal readOptionalDecimal(String text) {
        if (text.isEmpty()) {
            return null;
        }
        try {
            return new BigDecimal(text.replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + text + "' no es una cantidad valida.");
        }
    }

    private static Timestamp readOptionalDate(String text) {
        if (text.isEmpty()) {
            return null;
        }
        try {
            return Timestamp.valueOf(LocalDateTime.parse(text.replace(' ', 'T')));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Fecha no valida. Use el formato aaaa-MM-dd HH:mm.");
        }
    }

    // Muestra el valor actual; si el usuario solo pulsa Enter, se conserva.
    private String keepCurrentValue(String label, String current) {
        String text = ask(label + " [" + (current == null ? "" : current) + "]");
        return text.isEmpty() ? (current == null ? "" : current) : text;
    }

    // Formato aaaa-MM-dd HH:mm que acepta leerFechaOpcional.
    private static String formatDate(Timestamp date) {
        return date == null ? "" : date.toLocalDateTime().toString().replace('T', ' ').substring(0, 16);
    }

    private String ask(String label) {
        System.out.print(label + ": ");
        return input.nextLine().trim();
    }
}
