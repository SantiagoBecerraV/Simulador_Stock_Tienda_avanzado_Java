package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.sales.dao.LogisticsDao;
import com.frescuratotal.erp.sales.model.Driver;
import com.frescuratotal.erp.sales.model.RouteDelivery;
import com.frescuratotal.erp.sales.model.RouteStatus;
import com.frescuratotal.erp.sales.model.VehicleStatus;
import com.frescuratotal.erp.sales.model.Route;
import com.frescuratotal.erp.sales.model.Vehicle;
import com.frescuratotal.erp.sales.model.SaleInPreparation;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.List;

/**
 * Modulo de Logistica: valida las reglas y coordina el DAO. Los problemas del usuario se
 * reportan con IllegalArgumentException y un mensaje legible; lo demas es SQLException.
 * Flujo: crear ruta -> asignar vehiculo y conductor -> asignar ventas -> despachar -> confirmar entregas.
 */
public class LogisticsController {

    private static final int MYSQL_DUPLICATE_ENTRY = 1062;

    private final LogisticsDao dao;

    public LogisticsController(LogisticsDao dao) {
        this.dao = dao;
    }

    // ---------- Consultas ----------

    public List<SaleInPreparation> listSalesInPreparation() throws SQLException {
        return dao.listSalesInPreparation();
    }

    public List<Vehicle> listVehicles() throws SQLException {
        return dao.listVehicles();
    }

    public List<Driver> listDrivers() throws SQLException {
        return dao.listDrivers();
    }

    public List<Route> listRoutes() throws SQLException {
        return dao.listRoutes();
    }

    public List<RouteDelivery> listDeliveries(int routeId) throws SQLException {
        findRoute(routeId);
        return dao.listDeliveries(routeId);
    }

    // ---------- Vehiculos y conductores ----------

    public void createVehicle(String licensePlate, String model, BigDecimal capacity) throws SQLException {
        validateVehicle(licensePlate, capacity);
        try {
            dao.insertVehicle(licensePlate, emptyToNull(model), capacity);
        } catch (SQLException e) {
            if (isDuplicate(e)) {
                throw new IllegalArgumentException("Ya existe un vehiculo con la placa '" + licensePlate + "'.");
            }
            throw e;
        }
    }

    public Vehicle findVehicle(int vehicleId) throws SQLException {
        return dao.findVehicle(vehicleId)
                .orElseThrow(() -> new IllegalArgumentException("No existe un vehiculo con id " + vehicleId + "."));
    }

    public void updateVehicle(int vehicleId, String licensePlate, String model, BigDecimal capacity) throws SQLException {
        findVehicle(vehicleId);
        validateVehicle(licensePlate, capacity);
        try {
            dao.updateVehicle(vehicleId, licensePlate, emptyToNull(model), capacity);
        } catch (SQLException e) {
            if (isDuplicate(e)) {
                throw new IllegalArgumentException("Ya existe un vehiculo con la placa '" + licensePlate + "'.");
            }
            throw e;
        }
    }

    // Desactivar un vehiculo no borra su historial. No se puede si esta en una ruta pendiente.
    public void changeVehicleStatus(int vehicleId, VehicleStatus status) throws SQLException {
        findVehicle(vehicleId);
        if (status != VehicleStatus.ACTIVE && dao.isVehicleBusy(vehicleId, 0)) {
            throw new IllegalArgumentException("El vehiculo esta en una ruta pendiente; reasignelo antes de desactivarlo.");
        }
        dao.changeVehicleStatus(vehicleId, status);
    }

    // Solo se borra un vehiculo sin historial de asignaciones; si lo tiene, hay que dejarlo Inactivo.
    public void deleteVehicle(int vehicleId) throws SQLException {
        findVehicle(vehicleId);
        if (dao.vehicleHasAssignments(vehicleId)) {
            throw new IllegalArgumentException("El vehiculo tiene asignaciones en su historial: no se elimina. "
                    + "Cambie su estado a Inactivo.");
        }
        dao.deleteVehicle(vehicleId);
    }

    public void createDriver(String name, String licenseNumber, String phone, String email) throws SQLException {
        validateDriver(name, licenseNumber);
        try {
            dao.insertDriver(name, licenseNumber, emptyToNull(phone), emptyToNull(email));
        } catch (SQLException e) {
            if (isDuplicate(e)) {
                throw new IllegalArgumentException("Ya existe un conductor con la licencia '" + licenseNumber + "'.");
            }
            throw e;
        }
    }

    public Driver findDriver(int driverId) throws SQLException {
        return dao.findDriver(driverId)
                .orElseThrow(() -> new IllegalArgumentException("No existe un conductor con id " + driverId + "."));
    }

    public void updateDriver(int driverId, String name, String licenseNumber, String phone, String email)
            throws SQLException {
        findDriver(driverId);
        validateDriver(name, licenseNumber);
        try {
            dao.updateDriver(driverId, name, licenseNumber, emptyToNull(phone), emptyToNull(email));
        } catch (SQLException e) {
            if (isDuplicate(e)) {
                throw new IllegalArgumentException("Ya existe un conductor con la licencia '" + licenseNumber + "'.");
            }
            throw e;
        }
    }

    // Desactivar un conductor no borra su historial. No se puede si esta en una ruta pendiente.
    public void changeDriverActiveStatus(int driverId, boolean active) throws SQLException {
        findDriver(driverId);
        if (!active && dao.isDriverBusy(driverId, 0)) {
            throw new IllegalArgumentException("El conductor esta en una ruta pendiente; reasignelo antes de desactivarlo.");
        }
        dao.changeDriverActiveStatus(driverId, active);
    }

    // Solo se borra un conductor sin historial de asignaciones; si lo tiene, hay que desactivarlo.
    public void deleteDriver(int driverId) throws SQLException {
        findDriver(driverId);
        if (dao.driverHasAssignments(driverId)) {
            throw new IllegalArgumentException("El conductor tiene asignaciones en su historial: no se elimina. "
                    + "Desactivelo.");
        }
        dao.deleteDriver(driverId);
    }

    // ---------- Rutas ----------

    public void createRoute(String routeName, Timestamp estimatedDeparture, Timestamp estimatedArrival) throws SQLException {
        validateRoute(routeName, estimatedDeparture, estimatedArrival);
        dao.insertRoute(routeName, estimatedDeparture, estimatedArrival);
    }

    public Route findRoute(int routeId) throws SQLException {
        return dao.findRoute(routeId)
                .orElseThrow(() -> new IllegalArgumentException("No existe una ruta con id " + routeId + "."));
    }

    public void updateRoute(int routeId, String routeName, Timestamp estimatedDeparture, Timestamp estimatedArrival)
            throws SQLException {
        requirePlannedRoute(findRoute(routeId));
        validateRoute(routeName, estimatedDeparture, estimatedArrival);
        dao.updateRoute(routeId, routeName, estimatedDeparture, estimatedArrival);
    }

    // Cancelar conserva la ruta en la base de datos; solo se cancelan rutas Planificadas.
    public void cancelRoute(int routeId) throws SQLException {
        requirePlannedRoute(findRoute(routeId));
        dao.cancelRoute(routeId);
    }

    // Regla: el vehiculo y el conductor deben estar activos y libres (no en otra ruta pendiente).
    // Si la ruta ya tenia asignacion, esta la reemplaza.
    public void assignVehicleAndDriver(int routeId, int vehicleId, int driverId) throws SQLException {
        requirePlannedRoute(findRoute(routeId));
        Vehicle vehicle = dao.findVehicle(vehicleId)
                .orElseThrow(() -> new IllegalArgumentException("No existe un vehiculo con id " + vehicleId + "."));
        if (vehicle.status() != VehicleStatus.ACTIVE) {
            throw new IllegalArgumentException("El vehiculo " + vehicle.licensePlate() + " no esta activo.");
        }
        Driver driver = dao.findDriver(driverId)
                .orElseThrow(() -> new IllegalArgumentException("No existe un conductor con id " + driverId + "."));
        if (!driver.active()) {
            throw new IllegalArgumentException("El conductor " + driver.name() + " no esta activo.");
        }
        if (dao.isVehicleBusy(vehicleId, routeId)) {
            throw new IllegalArgumentException("El vehiculo ya esta asignado a otra ruta pendiente.");
        }
        if (dao.isDriverBusy(driverId, routeId)) {
            throw new IllegalArgumentException("El conductor ya esta asignado a otra ruta pendiente.");
        }
        dao.saveAssignment(routeId, vehicleId, driverId);
    }

    // Regla: solo ventas "En Preparacion" y en una unica ruta. Si no se indica direccion u orden,
    // se usa la direccion del cliente y el siguiente numero de la ruta.
    public void assignSale(int routeId, int saleId, Integer order, String address) throws SQLException {
        requirePlannedRoute(findRoute(routeId));
        if (!dao.saleIsInPreparation(saleId)) {
            throw new IllegalArgumentException("La venta " + saleId + " no existe o no esta en preparacion.");
        }
        if (dao.saleIsAlreadyAssigned(saleId)) {
            throw new IllegalArgumentException("La venta " + saleId + " ya esta asignada a una ruta.");
        }
        String destination = address.isBlank() ? dao.customerAddress(saleId).orElse("") : address;
        if (destination.isBlank()) {
            throw new IllegalArgumentException("La venta no tiene direccion: escriba una direccion de destino.");
        }
        int deliveryOrder = order != null ? order : dao.nextDeliveryOrder(routeId);
        dao.insertSaleIntoRoute(routeId, saleId, deliveryOrder, destination);
    }

    // La venta vuelve a quedar libre en "En Preparacion". Solo en rutas Planificadas.
    public void removeSaleFromRoute(int routeId, int saleId) throws SQLException {
        requirePlannedRoute(findRoute(routeId));
        if (!dao.removeSaleFromRoute(routeId, saleId)) {
            throw new IllegalArgumentException("La venta " + saleId + " no esta en la ruta " + routeId + ".");
        }
    }

    // ---------- Despacho y entrega ----------

    public void startDispatch(int routeId) throws SQLException {
        requirePlannedRoute(findRoute(routeId));
        if (!dao.routeHasAssignment(routeId)) {
            throw new IllegalArgumentException("Asigne un vehiculo y un conductor antes de despachar.");
        }
        if (dao.listDeliveries(routeId).isEmpty()) {
            throw new IllegalArgumentException("La ruta no tiene ventas asignadas.");
        }
        dao.startDispatch(routeId);
    }

    // Devuelve true si con esta entrega la ruta quedo completada.
    public boolean confirmDelivery(int routeId, int saleId, String receivedBy, String observations) throws SQLException {
        if (receivedBy.isBlank()) {
            throw new IllegalArgumentException("Indique quien recibio el pedido.");
        }
        findRoute(routeId);
        return dao.confirmDelivery(routeId, saleId, receivedBy, emptyToNull(observations));
    }

    // ---------- Auxiliares ----------

    // Validaciones compartidas por crear y actualizar.
    private void validateVehicle(String licensePlate, BigDecimal capacity) {
        if (licensePlate.isBlank()) {
            throw new IllegalArgumentException("La placa es obligatoria.");
        }
        if (capacity != null && capacity.signum() <= 0) {
            throw new IllegalArgumentException("La capacidad debe ser mayor que cero.");
        }
    }

    private void validateDriver(String name, String licenseNumber) {
        if (name.isBlank() || licenseNumber.isBlank()) {
            throw new IllegalArgumentException("El nombre y la licencia son obligatorios.");
        }
    }

    private void validateRoute(String routeName, Timestamp estimatedDeparture, Timestamp estimatedArrival) {
        if (routeName.isBlank()) {
            throw new IllegalArgumentException("El nombre de la ruta es obligatorio.");
        }
        if (estimatedDeparture != null && estimatedArrival != null && estimatedArrival.before(estimatedDeparture)) {
            throw new IllegalArgumentException("La llegada estimada no puede ser anterior a la salida estimada.");
        }
    }

    private void requirePlannedRoute(Route route) {
        if (route.status() != RouteStatus.PLANNED) {
            throw new IllegalArgumentException("La ruta " + route.routeId() + " esta en estado "
                    + route.status().databaseValue() + "; solo se modifican rutas Planificadas.");
        }
    }

    // true si MySQL rechazo el dato por repetir un valor unico (placa o licencia).
    private static boolean isDuplicate(SQLException e) {
        return e.getErrorCode() == MYSQL_DUPLICATE_ENTRY;
    }

    private static String emptyToNull(String text) {
        return text == null || text.isBlank() ? null : text.trim();
    }
}
