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
        obtenerRuta(idRuta);
        return dao.listarEntregas(idRuta);
    }

    // ---------- Vehículos y conductores ----------

    public void crearVehiculo(String placa, String modelo, BigDecimal capacidad) throws SQLException {
        validarVehiculo(placa, capacidad);
        try {
            dao.insertarVehiculo(placa, vacioANulo(modelo), capacidad);
        } catch (SQLException e) {
            throw traducirDuplicado(e, "Ya existe un vehículo con la placa '" + placa + "'.");
        }
    }

    public Vehiculo obtenerVehiculo(int idVehiculo) throws SQLException {
        return dao.buscarVehiculo(idVehiculo)
                .orElseThrow(() -> new IllegalArgumentException("No existe un vehículo con id " + idVehiculo + "."));
    }

    public void actualizarVehiculo(int idVehiculo, String placa, String modelo, BigDecimal capacidad) throws SQLException {
        obtenerVehiculo(idVehiculo);
        validarVehiculo(placa, capacidad);
        try {
            dao.actualizarVehiculo(idVehiculo, placa, vacioANulo(modelo), capacidad);
        } catch (SQLException e) {
            throw traducirDuplicado(e, "Ya existe un vehículo con la placa '" + placa + "'.");
        }
    }

    // Desactivar un vehículo no borra su historial. No se puede si está en una ruta pendiente.
    public void cambiarEstadoVehiculo(int idVehiculo, EstadoVehiculo estado) throws SQLException {
        obtenerVehiculo(idVehiculo);
        if (estado != EstadoVehiculo.ACTIVO && dao.vehiculoOcupado(idVehiculo, 0)) {
            throw new IllegalArgumentException("El vehículo está en una ruta pendiente; reasígnelo antes de desactivarlo.");
        }
        dao.cambiarEstadoVehiculo(idVehiculo, estado);
    }

    // Solo se borra un vehículo sin historial de asignaciones; si lo tiene, hay que dejarlo Inactivo.
    public void eliminarVehiculo(int idVehiculo) throws SQLException {
        obtenerVehiculo(idVehiculo);
        if (dao.vehiculoTieneAsignaciones(idVehiculo)) {
            throw new IllegalArgumentException("El vehículo tiene asignaciones en su historial: no se elimina. "
                    + "Cambie su estado a Inactivo.");
        }
        dao.eliminarVehiculo(idVehiculo);
    }

    public void crearConductor(String nombre, String licencia, String telefono, String email) throws SQLException {
        validarConductor(nombre, licencia);
        try {
            dao.insertarConductor(nombre, licencia, vacioANulo(telefono), vacioANulo(email));
        } catch (SQLException e) {
            throw traducirDuplicado(e, "Ya existe un conductor con la licencia '" + licencia + "'.");
        }
    }

    public Conductor obtenerConductor(int idConductor) throws SQLException {
        return dao.buscarConductor(idConductor)
                .orElseThrow(() -> new IllegalArgumentException("No existe un conductor con id " + idConductor + "."));
    }

    public void actualizarConductor(int idConductor, String nombre, String licencia, String telefono, String email)
            throws SQLException {
        obtenerConductor(idConductor);
        validarConductor(nombre, licencia);
        try {
            dao.actualizarConductor(idConductor, nombre, licencia, vacioANulo(telefono), vacioANulo(email));
        } catch (SQLException e) {
            throw traducirDuplicado(e, "Ya existe un conductor con la licencia '" + licencia + "'.");
        }
    }

    // Desactivar un conductor no borra su historial. No se puede si está en una ruta pendiente.
    public void cambiarActivoConductor(int idConductor, boolean activo) throws SQLException {
        obtenerConductor(idConductor);
        if (!activo && dao.conductorOcupado(idConductor, 0)) {
            throw new IllegalArgumentException("El conductor está en una ruta pendiente; reasígnelo antes de desactivarlo.");
        }
        dao.cambiarActivoConductor(idConductor, activo);
    }

    // Solo se borra un conductor sin historial de asignaciones; si lo tiene, hay que desactivarlo.
    public void eliminarConductor(int idConductor) throws SQLException {
        obtenerConductor(idConductor);
        if (dao.conductorTieneAsignaciones(idConductor)) {
            throw new IllegalArgumentException("El conductor tiene asignaciones en su historial: no se elimina. "
                    + "Desactívelo.");
        }
        dao.eliminarConductor(idConductor);
    }

    // ---------- Rutas ----------

    public void crearRuta(String nombreRuta, Timestamp salidaEstimada, Timestamp llegadaEstimada) throws SQLException {
        validarRuta(nombreRuta, salidaEstimada, llegadaEstimada);
        dao.insertarRuta(nombreRuta, salidaEstimada, llegadaEstimada);
    }

    public Ruta obtenerRuta(int idRuta) throws SQLException {
        return dao.buscarRuta(idRuta)
                .orElseThrow(() -> new IllegalArgumentException("No existe una ruta con id " + idRuta + "."));
    }

    public void actualizarRuta(int idRuta, String nombreRuta, Timestamp salidaEstimada, Timestamp llegadaEstimada)
            throws SQLException {
        exigirRutaPlanificada(obtenerRuta(idRuta));
        validarRuta(nombreRuta, salidaEstimada, llegadaEstimada);
        dao.actualizarRuta(idRuta, nombreRuta, salidaEstimada, llegadaEstimada);
    }

    // Cancelar conserva la ruta en la base de datos; solo se cancelan rutas Planificadas.
    public void cancelarRuta(int idRuta) throws SQLException {
        exigirRutaPlanificada(obtenerRuta(idRuta));
        dao.cancelarRuta(idRuta);
    }

    // Regla: el vehículo y el conductor deben estar activos y libres (no en otra ruta pendiente).
    // Si la ruta ya tenía asignación, esta la reemplaza.
    public void asignarVehiculoYConductor(int idRuta, int idVehiculo, int idConductor) throws SQLException {
        exigirRutaPlanificada(obtenerRuta(idRuta));
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
        if (dao.vehiculoOcupado(idVehiculo, idRuta)) {
            throw new IllegalArgumentException("El vehículo ya está asignado a otra ruta pendiente.");
        }
        if (dao.conductorOcupado(idConductor, idRuta)) {
            throw new IllegalArgumentException("El conductor ya está asignado a otra ruta pendiente.");
        }
        dao.guardarAsignacion(idRuta, idVehiculo, idConductor);
    }

    // Regla: solo ventas "En Preparacion" y en una única ruta. Si no se indica dirección u orden,
    // se usa la dirección del cliente y el siguiente número de la ruta.
    public void asignarVenta(int idRuta, int idVenta, Integer orden, String direccion) throws SQLException {
        exigirRutaPlanificada(obtenerRuta(idRuta));
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

    // La venta vuelve a quedar libre en "En Preparacion". Solo en rutas Planificadas.
    public void quitarVentaDeRuta(int idRuta, int idVenta) throws SQLException {
        exigirRutaPlanificada(obtenerRuta(idRuta));
        if (!dao.quitarVentaDeRuta(idRuta, idVenta)) {
            throw new IllegalArgumentException("La venta " + idVenta + " no está en la ruta " + idRuta + ".");
        }
    }

    // ---------- Despacho y entrega ----------

    public void iniciarDespacho(int idRuta) throws SQLException {
        exigirRutaPlanificada(obtenerRuta(idRuta));
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
        obtenerRuta(idRuta);
        return dao.confirmarEntrega(idRuta, idVenta, recibidoPor, vacioANulo(observaciones));
    }

    // ---------- Auxiliares ----------

    // Validaciones compartidas por crear y actualizar.
    private void validarVehiculo(String placa, BigDecimal capacidad) {
        if (placa.isBlank()) {
            throw new IllegalArgumentException("La placa es obligatoria.");
        }
        if (capacidad != null && capacidad.signum() <= 0) {
            throw new IllegalArgumentException("La capacidad debe ser mayor que cero.");
        }
    }

    private void validarConductor(String nombre, String licencia) {
        if (nombre.isBlank() || licencia.isBlank()) {
            throw new IllegalArgumentException("El nombre y la licencia son obligatorios.");
        }
    }

    private void validarRuta(String nombreRuta, Timestamp salidaEstimada, Timestamp llegadaEstimada) {
        if (nombreRuta.isBlank()) {
            throw new IllegalArgumentException("El nombre de la ruta es obligatorio.");
        }
        if (salidaEstimada != null && llegadaEstimada != null && llegadaEstimada.before(salidaEstimada)) {
            throw new IllegalArgumentException("La llegada estimada no puede ser anterior a la salida estimada.");
        }
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
