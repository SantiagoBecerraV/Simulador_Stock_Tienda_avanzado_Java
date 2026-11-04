package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.common.TablaConsola;
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
import java.util.ArrayList;
import java.util.List;
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
            System.out.println("2. Vehiculos");
            System.out.println("3. Conductores");
            System.out.println("4. Rutas");
            System.out.println("5. Asignaciones");
            System.out.println("6. Despacho y entregas");
            System.out.println("0. Volver");
            switch (preguntar("Opcion")) {
                case "0" -> {
                    return;
                }
                case "1" -> ejecutarSeguro(this::mostrarVentasEnPreparacion, "");
                case "2" -> submenu("Vehiculos", this::opcionVehiculos,
                        "Listar", "Crear", "Cambiar estado", "Editar", "Eliminar");
                case "3" -> submenu("Conductores", this::opcionConductores,
                        "Listar", "Crear", "Activar/desactivar", "Editar", "Eliminar");
                case "4" -> submenu("Rutas", this::opcionRutas,
                        "Listar", "Crear", "Ver ventas", "Editar", "Cancelar");
                case "5" -> submenu("Asignaciones", this::opcionAsignaciones,
                        "Asignar vehiculo y conductor a ruta", "Asignar venta a ruta", "Quitar venta de ruta");
                case "6" -> submenu("Despacho y entregas", this::opcionDespacho,
                        "Iniciar despacho", "Confirmar entrega");
                default -> System.out.println("Opcion no valida.");
            }
        }
    }

    // Lo que hace un submenu con la opcion elegida (por ejemplo opcionVehiculos).
    private interface AccionDeMenu {
        void ejecutar(String opcion) throws SQLException;
    }

    // Muestra el submenu hasta que el usuario elige 0. Cada submenu decide sus opciones en su propio switch.
    private void submenu(String titulo, AccionDeMenu accion, String... nombresOpciones) {
        while (true) {
            System.out.println("\n--- " + titulo + " ---");
            for (int i = 0; i < nombresOpciones.length; i++) {
                System.out.println((i + 1) + ". " + nombresOpciones[i]);
            }
            System.out.println("0. Volver");
            String opcion = preguntar("Opcion");
            if (opcion.equals("0")) {
                return;
            }
            ejecutarSeguro(accion, opcion);
        }
    }

    // Un error de datos o de base de datos se muestra y el menu sigue funcionando.
    private void ejecutarSeguro(AccionDeMenu accion, String opcion) {
        try {
            accion.ejecutar(opcion);
        } catch (IllegalArgumentException e) {
            System.out.println(e.getMessage());
        } catch (SQLException e) {
            System.out.println("Error de base de datos: " + e.getMessage());
        }
    }

    // La opcion no se usa: esta accion no tiene submenu.
    private void mostrarVentasEnPreparacion(String opcion) throws SQLException {
        var ventas = controlador.listarVentasEnPreparacion();
        if (ventas.isEmpty()) {
            System.out.println("No hay ventas en preparacion.");
            return;
        }

        List<String[]> filas = new ArrayList<>();
        for (var venta : ventas) {
            String ruta = venta.idRuta() == null ? "Sin ruta" : "Ruta #" + venta.idRuta();
            filas.add(new String[]{String.valueOf(venta.idVenta()), venta.numeroVenta(), venta.cliente(),
                    venta.direccion(), "$" + venta.montoTotal(), ruta});
        }
        TablaConsola.imprimir(new String[]{"Id venta", "Numero", "Cliente", "Direccion", "Total", "Ruta"}, filas);
    }

    private void mostrarVehiculos() throws SQLException {
        var vehiculos = controlador.listarVehiculos();
        if (vehiculos.isEmpty()) {
            System.out.println("No hay vehiculos registrados.");
            return;
        }

        List<String[]> filas = new ArrayList<>();
        for (Vehiculo vehiculo : vehiculos) {
            String capacidad = vehiculo.capacidad() == null ? "-" : vehiculo.capacidad().toPlainString();
            filas.add(new String[]{String.valueOf(vehiculo.idVehiculo()), vehiculo.placa(), vehiculo.modelo(),
                    capacidad, vehiculo.estado().valorBd()});
        }
        TablaConsola.imprimir(new String[]{"Id", "Placa", "Modelo", "Capacidad", "Estado"}, filas);
    }

    private void mostrarConductores() throws SQLException {
        var conductores = controlador.listarConductores();
        if (conductores.isEmpty()) {
            System.out.println("No hay conductores registrados.");
            return;
        }

        List<String[]> filas = new ArrayList<>();
        for (Conductor conductor : conductores) {
            String estado = conductor.activo() ? "Activo" : "Inactivo";
            filas.add(new String[]{String.valueOf(conductor.idConductor()), conductor.nombre(),
                    conductor.numeroLicencia(), conductor.telefono(), estado});
        }
        TablaConsola.imprimir(new String[]{"Id", "Nombre", "Licencia", "Telefono", "Estado"}, filas);
    }

    private void mostrarRutas() throws SQLException {
        var rutas = controlador.listarRutas();
        if (rutas.isEmpty()) {
            System.out.println("No hay rutas registradas.");
            return;
        }

        List<String[]> filas = new ArrayList<>();
        for (Ruta ruta : rutas) {
            filas.add(new String[]{String.valueOf(ruta.idRuta()), ruta.nombreRuta(), ruta.estado().valorBd(),
                    ruta.placa(), ruta.conductor(), formatoFecha(ruta.salidaEstimada())});
        }
        TablaConsola.imprimir(new String[]{"Id", "Ruta", "Estado", "Vehiculo", "Conductor", "Salida estimada"}, filas);
    }

    private void mostrarEntregas(int idRuta) throws SQLException {
        var entregas = controlador.listarEntregas(idRuta);
        if (entregas.isEmpty()) {
            System.out.println("La ruta no tiene ventas asignadas.");
            return;
        }

        List<String[]> filas = new ArrayList<>();
        for (var entrega : entregas) {
            String fecha = entrega.fechaEntrega() == null ? "Pendiente" : entrega.fechaEntrega().toString();
            filas.add(new String[]{String.valueOf(entrega.ordenEntrega()), String.valueOf(entrega.idVenta()),
                    entrega.numeroVenta(), entrega.direccionDestino(), fecha, entrega.recibidoPor(),
                    entrega.observaciones()});
        }
        TablaConsola.imprimir(new String[]{"Orden", "Id venta", "Numero", "Destino", "Entregada",
            "Recibio", "Observaciones"}, filas);
    }

    // 1 Listar, 2 Crear, 3 Cambiar estado, 4 Editar, 5 Eliminar.
    private void opcionVehiculos(String opcion) throws SQLException {
        switch (opcion) {
            case "1" -> mostrarVehiculos();
            case "2" -> {
                controlador.crearVehiculo(preguntar("Placa"), preguntar("Modelo (opcional)"),
                        leerDecimalOpcional(preguntar("Capacidad (opcional)")));
                System.out.println("Vehiculo creado.");
            }
            case "3" -> {
                int id = leerEntero(preguntar("Id del vehiculo"));
                controlador.cambiarEstadoVehiculo(id, preguntarEstadoVehiculo());
                System.out.println("Estado del vehiculo actualizado.");
            }
            case "4" -> {
                // Enter en un campo conserva su valor actual.
                Vehiculo v = controlador.obtenerVehiculo(leerEntero(preguntar("Id del vehiculo")));
                controlador.actualizarVehiculo(v.idVehiculo(), conservar("Placa", v.placa()),
                        conservar("Modelo", v.modelo()),
                        leerDecimalOpcional(conservar("Capacidad", v.capacidad() == null ? "" : v.capacidad().toPlainString())));
                System.out.println("Vehiculo actualizado.");
            }
            case "5" -> {
                controlador.eliminarVehiculo(leerEntero(preguntar("Id del vehiculo")));
                System.out.println("Vehiculo eliminado.");
            }
            default -> System.out.println("Opcion no valida.");
        }
    }

    // 1 Listar, 2 Crear, 3 Activar/desactivar, 4 Editar, 5 Eliminar.
    private void opcionConductores(String opcion) throws SQLException {
        switch (opcion) {
            case "1" -> mostrarConductores();
            case "2" -> {
                controlador.crearConductor(preguntar("Nombre"), preguntar("Numero de licencia"),
                        preguntar("Telefono (opcional)"), preguntar("Correo (opcional)"));
                System.out.println("Conductor creado.");
            }
            case "3" -> {
                int id = leerEntero(preguntar("Id del conductor"));
                boolean activo = preguntar("Activo? (s/n)").equalsIgnoreCase("s");
                controlador.cambiarActivoConductor(id, activo);
                System.out.println("Conductor actualizado.");
            }
            case "4" -> {
                Conductor c = controlador.obtenerConductor(leerEntero(preguntar("Id del conductor")));
                controlador.actualizarConductor(c.idConductor(), conservar("Nombre", c.nombre()),
                        conservar("Numero de licencia", c.numeroLicencia()), conservar("Telefono", c.telefono()),
                        conservar("Correo", c.email()));
                System.out.println("Conductor actualizado.");
            }
            case "5" -> {
                controlador.eliminarConductor(leerEntero(preguntar("Id del conductor")));
                System.out.println("Conductor eliminado.");
            }
            default -> System.out.println("Opcion no valida.");
        }
    }

    // 1 Listar, 2 Crear, 3 Ver ventas, 4 Editar, 5 Cancelar.
    private void opcionRutas(String opcion) throws SQLException {
        switch (opcion) {
            case "1" -> mostrarRutas();
            case "2" -> {
                controlador.crearRuta(preguntar("Nombre de la ruta"),
                        leerFechaOpcional(preguntar("Salida estimada aaaa-MM-dd HH:mm (opcional)")),
                        leerFechaOpcional(preguntar("Llegada estimada aaaa-MM-dd HH:mm (opcional)")));
                System.out.println("Ruta creada en estado Planificada.");
            }
            case "3" -> mostrarEntregas(leerEntero(preguntar("Id de la ruta")));
            case "4" -> {
                Ruta r = controlador.obtenerRuta(leerEntero(preguntar("Id de la ruta")));
                controlador.actualizarRuta(r.idRuta(), conservar("Nombre de la ruta", r.nombreRuta()),
                        leerFechaOpcional(conservar("Salida estimada aaaa-MM-dd HH:mm", formatoFecha(r.salidaEstimada()))),
                        leerFechaOpcional(conservar("Llegada estimada aaaa-MM-dd HH:mm", formatoFecha(r.llegadaEstimada()))));
                System.out.println("Ruta actualizada.");
            }
            case "5" -> {
                controlador.cancelarRuta(leerEntero(preguntar("Id de la ruta")));
                System.out.println("Ruta cancelada. Sus ventas quedaron libres para asignarlas a otra ruta.");
            }
            default -> System.out.println("Opcion no valida.");
        }
    }

    // 1 Vehiculo y conductor a ruta, 2 Venta a ruta, 3 Quitar venta de ruta.
    private void opcionAsignaciones(String opcion) throws SQLException {
        switch (opcion) {
            case "1" -> {
                controlador.asignarVehiculoYConductor(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id del vehiculo")), leerEntero(preguntar("Id del conductor")));
                System.out.println("Vehiculo y conductor asignados.");
            }
            case "2" -> {
                int idRuta = leerEntero(preguntar("Id de la ruta"));
                int idVenta = leerEntero(preguntar("Id de la venta"));
                String orden = preguntar("Orden de entrega (Enter = siguiente)");
                String direccion = preguntar("Direccion de destino (Enter = la del cliente)");
                controlador.asignarVenta(idRuta, idVenta, orden.isEmpty() ? null : leerEntero(orden), direccion);
                System.out.println("Venta asignada a la ruta.");
            }
            case "3" -> {
                controlador.quitarVentaDeRuta(leerEntero(preguntar("Id de la ruta")),
                        leerEntero(preguntar("Id de la venta")));
                System.out.println("Venta quitada de la ruta.");
            }
            default -> System.out.println("Opcion no valida.");
        }
    }

    // 1 Iniciar despacho, 2 Confirmar entrega.
    private void opcionDespacho(String opcion) throws SQLException {
        switch (opcion) {
            case "1" -> {
                controlador.iniciarDespacho(leerEntero(preguntar("Id de la ruta")));
                System.out.println("Despacho iniciado: la ruta y sus ventas quedaron En Transito.");
            }
            case "2" -> {
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
