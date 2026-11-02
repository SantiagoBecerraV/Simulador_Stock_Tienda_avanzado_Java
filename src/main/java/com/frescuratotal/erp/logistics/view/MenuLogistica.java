package com.frescuratotal.erp.logistics.view;

import com.frescuratotal.erp.logistics.controller.ControladorLogistica;
import com.frescuratotal.erp.logistics.dao.LogisticaDao;
import com.frescuratotal.erp.logistics.model.EstadoVehiculo;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.Scanner;

/**
 * Menú de consola del módulo de Logística. Punto de entrada para el menú principal:
 * new MenuLogistica(scanner, DatabaseConnection.getConnection()).ejecutar();
 */
public class MenuLogistica {

    private final Scanner entrada;
    private final ControladorLogistica controlador;

    public MenuLogistica(Scanner entrada, Connection conexion) {
        this.entrada = entrada;
        this.controlador = new ControladorLogistica(new LogisticaDao(conexion));
    }

    public void ejecutar() {
        while (true) {
            System.out.println("\n--- Logística ---");
            System.out.println("1. Ventas en preparación");
            System.out.println("2. Vehículos: 21 Listar  22 Crear  23 Cambiar estado");
            System.out.println("3. Conductores: 31 Listar  32 Crear  33 Activar/desactivar");
            System.out.println("4. Rutas: 41 Listar  42 Crear  43 Ver ventas de una ruta");
            System.out.println("5. Asignar: 51 Vehículo y conductor a ruta  52 Venta a ruta");
            System.out.println("6. Despacho: 61 Iniciar despacho  62 Confirmar entrega");
            System.out.println("0. Volver");
            String opcion = preguntar("Opción");
            if (opcion.equals("0")) {
                return;
            }
            try {
                ejecutarOpcion(opcion);
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Error de base de datos: " + e.getMessage());
            }
        }
    }

    private void ejecutarOpcion(String opcion) throws SQLException {
        switch (opcion) {
            case "1" -> controlador.listarVentasEnPreparacion().forEach(v -> System.out.printf(
                    "#%d | %s | cliente: %s | dirección: %s | total $%s | ruta: %s%n", v.idVenta(),
                    v.numeroVenta(), v.cliente(), v.direccion(), v.montoTotal(),
                    v.idRuta() == null ? "sin asignar" : v.idRuta()));
            case "21" -> controlador.listarVehiculos().forEach(v -> System.out.printf(
                    "#%d | %s | %s | capacidad: %s | %s%n", v.idVehiculo(), v.placa(), v.modelo(),
                    v.capacidad(), v.estado().valorBd()));
            case "22" -> {
                controlador.crearVehiculo(preguntar("Placa"), preguntar("Modelo (opcional)"),
                        leerDecimalOpcional(preguntar("Capacidad (opcional)")));
                System.out.println("Vehículo creado.");
            }
            case "23" -> {
                int id = leerEntero(preguntar("Id del vehículo"));
                controlador.cambiarEstadoVehiculo(id, preguntarEstadoVehiculo());
                System.out.println("Estado del vehículo actualizado.");
            }
            case "31" -> controlador.listarConductores().forEach(c -> System.out.printf(
                    "#%d | %s | licencia: %s | tel: %s | %s%n", c.idConductor(), c.nombre(), c.numeroLicencia(),
                    c.telefono(), c.activo() ? "Activo" : "Inactivo"));
            case "32" -> {
                controlador.crearConductor(preguntar("Nombre"), preguntar("Número de licencia"),
                        preguntar("Teléfono (opcional)"), preguntar("Correo (opcional)"));
                System.out.println("Conductor creado.");
            }
            case "33" -> {
                int id = leerEntero(preguntar("Id del conductor"));
                boolean activo = preguntar("¿Activo? (s/n)").equalsIgnoreCase("s");
                controlador.cambiarActivoConductor(id, activo);
                System.out.println("Conductor actualizado.");
            }
            case "41" -> controlador.listarRutas().forEach(r -> System.out.printf(
                    "#%d | %s | %s | vehículo: %s | conductor: %s | salida estimada: %s%n", r.idRuta(),
                    r.nombreRuta(), r.estado().valorBd(), r.placa() == null ? "-" : r.placa(),
                    r.conductor() == null ? "-" : r.conductor(), r.salidaEstimada()));
            case "42" -> {
                controlador.crearRuta(preguntar("Nombre de la ruta"),
                        leerFechaOpcional(preguntar("Salida estimada aaaa-MM-dd HH:mm (opcional)")),
                        leerFechaOpcional(preguntar("Llegada estimada aaaa-MM-dd HH:mm (opcional)")));
                System.out.println("Ruta creada en estado Planificada.");
            }
            case "43" -> controlador.listarEntregas(leerEntero(preguntar("Id de la ruta"))).forEach(e ->
                    System.out.printf("orden %s | venta #%d (%s) | destino: %s | entregada: %s | recibió: %s | obs: %s%n",
                            e.ordenEntrega(), e.idVenta(), e.numeroVenta(), e.direccionDestino(),
                            e.fechaEntrega() == null ? "pendiente" : e.fechaEntrega(), e.recibidoPor(),
                            e.observaciones()));
            case "51" -> {
                controlador.asignarVehiculoYConductor(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id del vehículo")), leerEntero(preguntar("Id del conductor")));
                System.out.println("Vehículo y conductor asignados.");
            }
            case "52" -> {
                int idRuta = leerEntero(preguntar("Id de la ruta"));
                int idVenta = leerEntero(preguntar("Id de la venta"));
                String orden = preguntar("Orden de entrega (Enter = siguiente)");
                String direccion = preguntar("Dirección de destino (Enter = la del cliente)");
                controlador.asignarVenta(idRuta, idVenta, orden.isEmpty() ? null : leerEntero(orden), direccion);
                System.out.println("Venta asignada a la ruta.");
            }
            case "61" -> {
                controlador.iniciarDespacho(leerEntero(preguntar("Id de la ruta")));
                System.out.println("Despacho iniciado: la ruta y sus ventas quedaron En Transito.");
            }
            case "62" -> {
                boolean completada = controlador.confirmarEntrega(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id de la venta")), preguntar("Recibido por"),
                        preguntar("Observaciones (opcional)"));
                System.out.println("Entrega confirmada." + (completada ? " La ruta quedó Completada." : ""));
            }
            default -> System.out.println("Opción no válida.");
        }
    }

    private EstadoVehiculo preguntarEstadoVehiculo() {
        EstadoVehiculo[] estados = EstadoVehiculo.values();
        for (int i = 0; i < estados.length; i++) {
            System.out.println("  " + (i + 1) + " = " + estados[i].valorBd());
        }
        int numero = leerEntero(preguntar("Estado"));
        if (numero < 1 || numero > estados.length) {
            throw new IllegalArgumentException("Estado no válido.");
        }
        return estados[numero - 1];
    }

    private static int leerEntero(String texto) {
        try {
            return Integer.parseInt(texto.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es un número válido.");
        }
    }

    private static BigDecimal leerDecimalOpcional(String texto) {
        if (texto.isEmpty()) {
            return null;
        }
        try {
            return new BigDecimal(texto.replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es una cantidad válida.");
        }
    }

    private static Timestamp leerFechaOpcional(String texto) {
        if (texto.isEmpty()) {
            return null;
        }
        try {
            return Timestamp.valueOf(LocalDateTime.parse(texto.replace(' ', 'T')));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Fecha no válida. Use el formato aaaa-MM-dd HH:mm.");
        }
    }

    private String preguntar(String etiqueta) {
        System.out.print(etiqueta + ": ");
        return entrada.nextLine().trim();
    }
}
