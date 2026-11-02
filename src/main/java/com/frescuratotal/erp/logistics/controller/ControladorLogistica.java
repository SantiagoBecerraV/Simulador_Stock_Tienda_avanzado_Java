package com.frescuratotal.erp.logistics.controller;

import com.frescuratotal.erp.logistics.dao.LogisticaDao;
import com.frescuratotal.erp.logistics.model.Conductor;
import com.frescuratotal.erp.logistics.model.EntregaRuta;
import com.frescuratotal.erp.logistics.model.EstadoRuta;
import com.frescuratotal.erp.logistics.model.EstadoVehiculo;
import com.frescuratotal.erp.logistics.model.Ruta;
import com.frescuratotal.erp.logistics.model.Vehiculo;
import com.frescuratotal.erp.logistics.model.VentaEnPreparacion;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;

/**
 * Módulo de Logística: valida las reglas y coordina el DAO. Los problemas del usuario se
 * reportan con IllegalArgumentException y un mensaje legible; lo demás es SQLException.
 * Flujo: crear ruta -> asignar vehículo y conductor -> asignar ventas -> despachar -> confirmar entregas.
 */
public class ControladorLogistica {

    private static final int MYSQL_ENTRADA_DUPLICADA = 1062;

    private final LogisticaDao dao;

    public ControladorLogistica(LogisticaDao dao) {
        this.dao = dao;
    }

    // ---------- Consultas ----------

    public List<VentaEnPreparacion> listarVentasEnPreparacion() throws SQLException {
        return dao.listarVentasEnPreparacion();
    }

    public List<Vehiculo> listarVehiculos() throws SQLException {
        return dao.listarVehiculos();
    }

    public List<Conductor> listarConductores() throws SQLException {
        return dao.listarConductores();
    }

    public List<Ruta> listarRutas() throws SQLException {
        return dao.listarRutas();
    }

    public List<EntregaRuta> listarEntregas(int idRuta) throws SQLException {
        buscarRuta(idRuta);
        return dao.listarEntregas(idRuta);
    }

    // ---------- Vehículos y conductores ----------

    public void crearVehiculo(String placa, String modelo, BigDecimal capacidad) throws SQLException {
        if (placa.isBlank()) {
            throw new IllegalArgumentException("La placa es obligatoria.");
        }
        if (capacidad != null && capacidad.signum() <= 0) {
            throw new IllegalArgumentException("La capacidad debe ser mayor que cero.");
        }
        try {
            dao.insertarVehiculo(placa, vacioANulo(modelo), capacidad);
        } catch (SQLException e) {
            throw traducirDuplicado(e, "Ya existe un vehículo con la placa '" + placa + "'.");
        }
    }

    public void cambiarEstadoVehiculo(int idVehiculo, EstadoVehiculo estado) throws SQLException {
        if (!dao.cambiarEstadoVehiculo(idVehiculo, estado)) {
            throw new IllegalArgumentException("No existe un vehículo con id " + idVehiculo + ".");
        }
    }

    public void crearConductor(String nombre, String licencia, String telefono, String email) throws SQLException {
        if (nombre.isBlank() || licencia.isBlank()) {
            throw new IllegalArgumentException("El nombre y la licencia son obligatorios.");
        }
        try {
            dao.insertarConductor(nombre, licencia, vacioANulo(telefono), vacioANulo(email));
        } catch (SQLException e) {
            throw traducirDuplicado(e, "Ya existe un conductor con la licencia '" + licencia + "'.");
        }
    }

    public void cambiarActivoConductor(int idConductor, boolean activo) throws SQLException {
        if (!dao.cambiarActivoConductor(idConductor, activo)) {
            throw new IllegalArgumentException("No existe un conductor con id " + idConductor + ".");
        }
    }

    // ---------- Rutas ----------

    public void crearRuta(String nombreRuta, Timestamp salidaEstimada, Timestamp llegadaEstimada) throws SQLException {
        if (nombreRuta.isBlank()) {
            throw new IllegalArgumentException("El nombre de la ruta es obligatorio.");
        }
        if (salidaEstimada != null && llegadaEstimada != null && llegadaEstimada.before(salidaEstimada)) {
            throw new IllegalArgumentException("La llegada estimada no puede ser anterior a la salida estimada.");
        }
        dao.insertarRuta(nombreRuta, salidaEstimada, llegadaEstimada);
    }

    // Regla: el vehículo y el conductor deben estar activos y libres (no en otra ruta pendiente).
    public void asignarVehiculoYConductor(int idRuta, int idVehiculo, int idConductor) throws SQLException {
        exigirRutaPlanificada(buscarRuta(idRuta));
        if (dao.rutaTieneAsignacion(idRuta)) {
            throw new IllegalArgumentException("La ruta ya tiene vehículo y conductor asignados.");
        }
        Vehiculo vehiculo = dao.buscarVehiculo(idVehiculo)
                .orElseThrow(() -> new IllegalArgumentException("No existe un vehículo con id " + idVehiculo + "."));
        if (vehiculo.estado() != EstadoVehiculo.ACTIVO) {
            throw new IllegalArgumentException("El vehículo " + vehiculo.placa() + " no está activo.");
        }
        Conductor conductor = dao.buscarConductor(idConductor)
                .orElseThrow(() -> new IllegalArgumentException("No existe un conductor con id " + idConductor + "."));
        if (!conductor.activo()) {
            throw new IllegalArgumentException("El conductor " + conductor.nombre() + " no está activo.");
        }
        if (dao.vehiculoOcupado(idVehiculo)) {
            throw new IllegalArgumentException("El vehículo ya está asignado a otra ruta pendiente.");
        }
        if (dao.conductorOcupado(idConductor)) {
            throw new IllegalArgumentException("El conductor ya está asignado a otra ruta pendiente.");
        }
        dao.insertarAsignacion(idRuta, idVehiculo, idConductor);
    }

    // Regla: solo ventas "En Preparacion" y en una única ruta. Si no se indica dirección u orden,
    // se usa la dirección del cliente y el siguiente número de la ruta.
    public void asignarVenta(int idRuta, int idVenta, Integer orden, String direccion) throws SQLException {
        exigirRutaPlanificada(buscarRuta(idRuta));
        if (!dao.ventaEstaEnPreparacion(idVenta)) {
            throw new IllegalArgumentException("La venta " + idVenta + " no existe o no está en preparación.");
        }
        if (dao.ventaYaAsignada(idVenta)) {
            throw new IllegalArgumentException("La venta " + idVenta + " ya está asignada a una ruta.");
        }
        String destino = direccion.isBlank() ? dao.direccionDelCliente(idVenta).orElse("") : direccion;
        if (destino.isBlank()) {
            throw new IllegalArgumentException("La venta no tiene dirección: escriba una dirección de destino.");
        }
        int ordenEntrega = orden != null ? orden : dao.siguienteOrdenEntrega(idRuta);
        dao.insertarVentaEnRuta(idRuta, idVenta, ordenEntrega, destino);
    }

    // ---------- Despacho y entrega ----------

    public void iniciarDespacho(int idRuta) throws SQLException {
        exigirRutaPlanificada(buscarRuta(idRuta));
        if (!dao.rutaTieneAsignacion(idRuta)) {
            throw new IllegalArgumentException("Asigne un vehículo y un conductor antes de despachar.");
        }
        if (dao.listarEntregas(idRuta).isEmpty()) {
            throw new IllegalArgumentException("La ruta no tiene ventas asignadas.");
        }
        dao.iniciarDespacho(idRuta);
    }

    // Devuelve true si con esta entrega la ruta quedó completada.
    public boolean confirmarEntrega(int idRuta, int idVenta, String recibidoPor, String observaciones) throws SQLException {
        if (recibidoPor.isBlank()) {
            throw new IllegalArgumentException("Indique quién recibió el pedido.");
        }
        buscarRuta(idRuta);
        return dao.confirmarEntrega(idRuta, idVenta, recibidoPor, vacioANulo(observaciones));
    }

    // ---------- Auxiliares ----------

    private Ruta buscarRuta(int idRuta) throws SQLException {
        return dao.buscarRuta(idRuta)
                .orElseThrow(() -> new IllegalArgumentException("No existe una ruta con id " + idRuta + "."));
    }

    private void exigirRutaPlanificada(Ruta ruta) {
        if (ruta.estado() != EstadoRuta.PLANIFICADA) {
            throw new IllegalArgumentException("La ruta " + ruta.idRuta() + " está en estado "
                    + ruta.estado().valorBd() + "; solo se modifican rutas Planificadas.");
        }
    }

    private SQLException traducirDuplicado(SQLException e, String mensaje) {
        if (e.getErrorCode() == MYSQL_ENTRADA_DUPLICADA) {
            throw new IllegalArgumentException(mensaje);
        }
        return e;
    }

    private static String vacioANulo(String texto) {
        return texto == null || texto.isBlank() ? null : texto.trim();
    }
}
