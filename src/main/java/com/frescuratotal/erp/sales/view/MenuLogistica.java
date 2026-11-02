package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.controller.ControladorLogistica;
import com.frescuratotal.erp.sales.dao.LogisticaDao;
import com.frescuratotal.erp.sales.model.Conductor;
import com.frescuratotal.erp.sales.model.EstadoVehiculo;
import com.frescuratotal.erp.sales.model.Ruta;
import com.frescuratotal.erp.sales.model.Vehiculo;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.Scanner;

/**
 * Menu de consola del modulo de Logistica. Punto de entrada para el menu principal:
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
            System.out.println("\n--- Logistica ---");
            System.out.println("1. Ventas en preparacion");
            System.out.println("2. Vehiculos: 21 Listar  22 Crear  23 Cambiar estado  24 Editar  25 Eliminar");
            System.out.println("3. Conductores: 31 Listar  32 Crear  33 Activar/desactivar  34 Editar  35 Eliminar");
            System.out.println("4. Rutas: 41 Listar  42 Crear  43 Ver ventas  44 Editar  45 Cancelar");
            System.out.println("5. Asignar: 51 Vehiculo y conductor a ruta  52 Venta a ruta  53 Quitar venta de ruta");
            System.out.println("6. Despacho: 61 Iniciar despacho  62 Confirmar entrega");
            System.out.println("0. Volver");
            String opcion = preguntar("Opcion");
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
                    "#%d | %s | cliente: %s | direccion: %s | total $%s | ruta: %s%n", v.idVenta(),
                    v.numeroVenta(), v.cliente(), v.direccion(), v.montoTotal(),
                    v.idRuta() == null ? "sin asignar" : v.idRuta()));
            case "21" -> controlador.listarVehiculos().forEach(v -> System.out.printf(
                    "#%d | %s | %s | capacidad: %s | %s%n", v.idVehiculo(), v.placa(), v.modelo(),
                    v.capacidad(), v.estado().valorBd()));
            case "22" -> {
                controlador.crearVehiculo(preguntar("Placa"), preguntar("Modelo (opcional)"),
                        leerDecimalOpcional(preguntar("Capacidad (opcional)")));
                System.out.println("Vehiculo creado.");
            }
            case "23" -> {
                int id = leerEntero(preguntar("Id del vehiculo"));
                controlador.cambiarEstadoVehiculo(id, preguntarEstadoVehiculo());
                System.out.println("Estado del vehiculo actualizado.");
            }
            case "24" -> {
                // Enter en un campo conserva su valor actual.
                Vehiculo v = controlador.obtenerVehiculo(leerEntero(preguntar("Id del vehiculo")));
                controlador.actualizarVehiculo(v.idVehiculo(), conservar("Placa", v.placa()),
                        conservar("Modelo", v.modelo()),
                        leerDecimalOpcional(conservar("Capacidad", v.capacidad() == null ? "" : v.capacidad().toPlainString())));
                System.out.println("Vehiculo actualizado.");
            }
            case "25" -> {
                controlador.eliminarVehiculo(leerEntero(preguntar("Id del vehiculo")));
                System.out.println("Vehiculo eliminado.");
            }
            case "31" -> controlador.listarConductores().forEach(c -> System.out.printf(
                    "#%d | %s | licencia: %s | tel: %s | %s%n", c.idConductor(), c.nombre(), c.numeroLicencia(),
                    c.telefono(), c.activo() ? "Activo" : "Inactivo"));
            case "32" -> {
                controlador.crearConductor(preguntar("Nombre"), preguntar("Numero de licencia"),
                        preguntar("Telefono (opcional)"), preguntar("Correo (opcional)"));
                System.out.println("Conductor creado.");
            }
            case "33" -> {
                int id = leerEntero(preguntar("Id del conductor"));
                boolean activo = preguntar("Activo? (s/n)").equalsIgnoreCase("s");
                controlador.cambiarActivoConductor(id, activo);
                System.out.println("Conductor actualizado.");
            }
            case "34" -> {
                Conductor c = controlador.obtenerConductor(leerEntero(preguntar("Id del conductor")));
                controlador.actualizarConductor(c.idConductor(), conservar("Nombre", c.nombre()),
                        conservar("Numero de licencia", c.numeroLicencia()), conservar("Telefono", c.telefono()),
                        conservar("Correo", c.email()));
                System.out.println("Conductor actualizado.");
            }
            case "35" -> {
                controlador.eliminarConductor(leerEntero(preguntar("Id del conductor")));
                System.out.println("Conductor eliminado.");
            }
            case "41" -> controlador.listarRutas().forEach(r -> System.out.printf(
                    "#%d | %s | %s | vehiculo: %s | conductor: %s | salida estimada: %s%n", r.idRuta(),
                    r.nombreRuta(), r.estado().valorBd(), r.placa() == null ? "-" : r.placa(),
                    r.conductor() == null ? "-" : r.conductor(), r.salidaEstimada()));
            case "42" -> {
                controlador.crearRuta(preguntar("Nombre de la ruta"),
                        leerFechaOpcional(preguntar("Salida estimada aaaa-MM-dd HH:mm (opcional)")),
                        leerFechaOpcional(preguntar("Llegada estimada aaaa-MM-dd HH:mm (opcional)")));
                System.out.println("Ruta creada en estado Planificada.");
            }
            case "43" -> controlador.listarEntregas(leerEntero(preguntar("Id de la ruta"))).forEach(e ->
                    System.out.printf("orden %s | venta #%d (%s) | destino: %s | entregada: %s | recibio: %s | obs: %s%n",
                            e.ordenEntrega(), e.idVenta(), e.numeroVenta(), e.direccionDestino(),
                            e.fechaEntrega() == null ? "pendiente" : e.fechaEntrega(), e.recibidoPor(),
                            e.observaciones()));
            case "44" -> {
                Ruta r = controlador.obtenerRuta(leerEntero(preguntar("Id de la ruta")));
                controlador.actualizarRuta(r.idRuta(), conservar("Nombre de la ruta", r.nombreRuta()),
                        leerFechaOpcional(conservar("Salida estimada aaaa-MM-dd HH:mm", formatoFecha(r.salidaEstimada()))),
                        leerFechaOpcional(conservar("Llegada estimada aaaa-MM-dd HH:mm", formatoFecha(r.llegadaEstimada()))));
                System.out.println("Ruta actualizada.");
            }
            case "45" -> {
                controlador.cancelarRuta(leerEntero(preguntar("Id de la ruta")));
                System.out.println("Ruta cancelada. Sus ventas quedaron libres para asignarlas a otra ruta.");
            }
            case "51" -> {
                controlador.asignarVehiculoYConductor(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id del vehiculo")), leerEntero(preguntar("Id del conductor")));
                System.out.println("Vehiculo y conductor asignados.");
            }
            case "52" -> {
                int idRuta = leerEntero(preguntar("Id de la ruta"));
                int idVenta = leerEntero(preguntar("Id de la venta"));
                String orden = preguntar("Orden de entrega (Enter = siguiente)");
                String direccion = preguntar("Direccion de destino (Enter = la del cliente)");
                controlador.asignarVenta(idRuta, idVenta, orden.isEmpty() ? null : leerEntero(orden), direccion);
                System.out.println("Venta asignada a la ruta.");
            }
            case "53" -> {
                controlador.quitarVentaDeRuta(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id de la venta")));
                System.out.println("Venta quitada de la ruta.");
            }
            case "61" -> {
                controlador.iniciarDespacho(leerEntero(preguntar("Id de la ruta")));
                System.out.println("Despacho iniciado: la ruta y sus ventas quedaron En Transito.");
            }
            case "62" -> {
                boolean completada = controlador.confirmarEntrega(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id de la venta")), preguntar("Recibido por"),
                        preguntar("Observaciones (opcional)"));
                System.out.println("Entrega confirmada." + (completada ? " La ruta quedo Completada." : ""));
            }
            default -> System.out.println("Opcion no valida.");
        }
    }

    private EstadoVehiculo preguntarEstadoVehiculo() {
        EstadoVehiculo[] estados = EstadoVehiculo.values();
        for (int i = 0; i < estados.length; i++) {
            System.out.println("  " + (i + 1) + " = " + estados[i].valorBd());
        }
        int numero = leerEntero(preguntar("Estado"));
        if (numero < 1 || numero > estados.length) {
            throw new IllegalArgumentException("Estado no valido.");
        }
        return estados[numero - 1];
    }

    private static int leerEntero(String texto) {
        try {
            return Integer.parseInt(texto.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es un numero valido.");
        }
    }

    private static BigDecimal leerDecimalOpcional(String texto) {
        if (texto.isEmpty()) {
            return null;
        }
        try {
            return new BigDecimal(texto.replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es una cantidad valida.");
        }
    }

    private static Timestamp leerFechaOpcional(String texto) {
        if (texto.isEmpty()) {
            return null;
        }
        try {
            return Timestamp.valueOf(LocalDateTime.parse(texto.replace(' ', 'T')));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Fecha no valida. Use el formato aaaa-MM-dd HH:mm.");
        }
    }

    // Muestra el valor actual; si el usuario solo pulsa Enter, se conserva.
    private String conservar(String etiqueta, String actual) {
        String texto = preguntar(etiqueta + " [" + (actual == null ? "" : actual) + "]");
        return texto.isEmpty() ? (actual == null ? "" : actual) : texto;
    }

    // Formato aaaa-MM-dd HH:mm que acepta leerFechaOpcional.
    private static String formatoFecha(Timestamp fecha) {
        return fecha == null ? "" : fecha.toLocalDateTime().toString().replace('T', ' ').substring(0, 16);
    }

    private String preguntar(String etiqueta) {
        System.out.print(etiqueta + ": ");
        return entrada.nextLine().trim();
    }
}
