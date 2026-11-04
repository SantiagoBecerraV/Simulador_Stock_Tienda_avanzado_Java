package com.frescuratotal.erp.sales.dao;

import com.frescuratotal.erp.sales.model.Driver;
import com.frescuratotal.erp.sales.model.RouteDelivery;
import com.frescuratotal.erp.sales.model.RouteStatus;
import com.frescuratotal.erp.sales.model.VehicleStatus;
import com.frescuratotal.erp.sales.model.SaleStatus;
import com.frescuratotal.erp.sales.model.Route;
import com.frescuratotal.erp.sales.model.Vehicle;
import com.frescuratotal.erp.sales.model.SaleInPreparation;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class LogisticsDao {

    private static final String SELECT_ROUTE =
            "SELECT r.id_ruta, r.nombre_ruta, r.hora_salida_estimada, r.hora_llegada_estimada, "
            + "r.hora_salida_real, r.hora_llegada_real, r.estado, ve.placa, co.nombre AS conductor "
            + "FROM rutas_entrega r "
            + "LEFT JOIN asignaciones_entrega a ON a.id_ruta = r.id_ruta "
            + "LEFT JOIN vehiculos ve ON ve.id_vehiculo = a.id_vehiculo "
            + "LEFT JOIN conductores co ON co.id_conductor = a.id_conductor ";

    // Ruta que aun no termina. Se arma con valores fijos del enum (no con datos del usuario).
    private static final String PENDING_ROUTE_CONDITION = "r.estado IN ('" + RouteStatus.PLANNED.databaseValue() + "', '"
            + RouteStatus.IN_TRANSIT.databaseValue() + "')";

    // La conexion viene del paquete comun compartido; este DAO no abre la suya.
    private final Connection connection;

    public LogisticsDao(Connection connection) {
        this.connection = connection;
    }

    // ---------- Ventas ----------

    // La columna idRuta sirve para ver que ventas ya estan asignadas a una ruta.
    public List<SaleInPreparation> listSalesInPreparation() throws SQLException {
        String sql = "SELECT v.id_venta, v.numero_venta, c.nombre, c.direccion, v.monto_total, vr.id_ruta "
                + "FROM ventas v "
                + "JOIN estados_venta e ON e.id_estado = v.id_estado "
                + "JOIN clientes c ON c.id_cliente = v.id_cliente "
                + "LEFT JOIN ventas_ruta vr ON vr.id_venta = v.id_venta "
                + "WHERE e.nombre = ? ORDER BY v.fecha_venta, v.id_venta";
        List<SaleInPreparation> sales = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, SaleStatus.IN_PREPARATION.databaseValue());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    sales.add(new SaleInPreparation(rs.getInt("id_venta"), rs.getString("numero_venta"),
                            rs.getString("nombre"), rs.getString("direccion"), rs.getBigDecimal("monto_total"),
                            (Integer) rs.getObject("id_ruta")));
                }
            }
        }
        return sales;
    }

    // ---------- Vehiculos ----------

    public List<Vehicle> listVehicles() throws SQLException {
        List<Vehicle> vehicles = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT id_vehiculo, placa, modelo, capacidad, estado FROM vehiculos ORDER BY id_vehiculo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                vehicles.add(mapVehicle(rs));
            }
        }
        return vehicles;
    }

    public Optional<Vehicle> findVehicle(int vehicleId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT id_vehiculo, placa, modelo, capacidad, estado FROM vehiculos WHERE id_vehiculo = ?")) {
            ps.setInt(1, vehicleId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapVehicle(rs)) : Optional.empty();
            }
        }
    }

    public void insertVehicle(String licensePlate, String model, BigDecimal capacity) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO vehiculos (placa, modelo, capacidad) VALUES (?, ?, ?)")) {
            ps.setString(1, licensePlate);
            ps.setString(2, model);
            ps.setBigDecimal(3, capacity);
            ps.executeUpdate();
        }
    }

    public boolean updateVehicle(int vehicleId, String licensePlate, String model, BigDecimal capacity)
            throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "UPDATE vehiculos SET placa = ?, modelo = ?, capacidad = ? WHERE id_vehiculo = ?")) {
            ps.setString(1, licensePlate);
            ps.setString(2, model);
            ps.setBigDecimal(3, capacity);
            ps.setInt(4, vehicleId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean vehicleHasAssignments(int vehicleId) throws SQLException {
        return exists("SELECT 1 FROM asignaciones_entrega WHERE id_vehiculo = ?", vehicleId);
    }

    public boolean deleteVehicle(int vehicleId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("DELETE FROM vehiculos WHERE id_vehiculo = ?")) {
            ps.setInt(1, vehicleId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean changeVehicleStatus(int vehicleId, VehicleStatus status) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("UPDATE vehiculos SET estado = ? WHERE id_vehiculo = ?")) {
            ps.setString(1, status.databaseValue());
            ps.setInt(2, vehicleId);
            return ps.executeUpdate() > 0;
        }
    }

    // ---------- Conductores ----------

    public List<Driver> listDrivers() throws SQLException {
        List<Driver> drivers = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT id_conductor, nombre, numero_licencia, telefono, email, activo "
                + "FROM conductores ORDER BY id_conductor");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                drivers.add(mapDriver(rs));
            }
        }
        return drivers;
    }

    public Optional<Driver> findDriver(int driverId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT id_conductor, nombre, numero_licencia, telefono, email, activo "
                + "FROM conductores WHERE id_conductor = ?")) {
            ps.setInt(1, driverId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapDriver(rs)) : Optional.empty();
            }
        }
    }

    public void insertDriver(String name, String licenseNumber, String phone, String email) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO conductores (nombre, numero_licencia, telefono, email) VALUES (?, ?, ?, ?)")) {
            ps.setString(1, name);
            ps.setString(2, licenseNumber);
            ps.setString(3, phone);
            ps.setString(4, email);
            ps.executeUpdate();
        }
    }

    public boolean updateDriver(int driverId, String name, String licenseNumber, String phone, String email)
            throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "UPDATE conductores SET nombre = ?, numero_licencia = ?, telefono = ?, email = ? WHERE id_conductor = ?")) {
            ps.setString(1, name);
            ps.setString(2, licenseNumber);
            ps.setString(3, phone);
            ps.setString(4, email);
            ps.setInt(5, driverId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean driverHasAssignments(int driverId) throws SQLException {
        return exists("SELECT 1 FROM asignaciones_entrega WHERE id_conductor = ?", driverId);
    }

    public boolean deleteDriver(int driverId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("DELETE FROM conductores WHERE id_conductor = ?")) {
            ps.setInt(1, driverId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean changeDriverActiveStatus(int driverId, boolean active) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("UPDATE conductores SET activo = ? WHERE id_conductor = ?")) {
            ps.setBoolean(1, active);
            ps.setInt(2, driverId);
            return ps.executeUpdate() > 0;
        }
    }

    // ---------- Rutas y asignaciones ----------

    public List<Route> listRoutes() throws SQLException {
        List<Route> routes = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(SELECT_ROUTE + "ORDER BY r.id_ruta");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                routes.add(mapRoute(rs));
            }
        }
        return routes;
    }

    public Optional<Route> findRoute(int routeId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(SELECT_ROUTE + "WHERE r.id_ruta = ?")) {
            ps.setInt(1, routeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapRoute(rs)) : Optional.empty();
            }
        }
    }

    public void insertRoute(String routeName, Timestamp estimatedDeparture, Timestamp estimatedArrival) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO rutas_entrega (nombre_ruta, hora_salida_estimada, hora_llegada_estimada) VALUES (?, ?, ?)")) {
            ps.setString(1, routeName);
            ps.setTimestamp(2, estimatedDeparture);
            ps.setTimestamp(3, estimatedArrival);
            ps.executeUpdate();
        }
    }

    public boolean updateRoute(int routeId, String routeName, Timestamp estimatedDeparture, Timestamp estimatedArrival)
            throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "UPDATE rutas_entrega SET nombre_ruta = ?, hora_salida_estimada = ?, hora_llegada_estimada = ? "
                + "WHERE id_ruta = ?")) {
            ps.setString(1, routeName);
            ps.setTimestamp(2, estimatedDeparture);
            ps.setTimestamp(3, estimatedArrival);
            ps.setInt(4, routeId);
            return ps.executeUpdate() > 0;
        }
    }

    // Una ruta no se borra: se cancela y conserva su historial. Sus ventas quedan libres para otra ruta.
    public void cancelRoute(int routeId) throws SQLException {
        executeInTransaction(() -> {
            changeRouteStatus("UPDATE rutas_entrega SET estado = ? WHERE id_ruta = ? AND estado = ?",
                    RouteStatus.CANCELED, routeId, RouteStatus.PLANNED);
            try (PreparedStatement ps = connection.prepareStatement("DELETE FROM ventas_ruta WHERE id_ruta = ?")) {
                ps.setInt(1, routeId);
                ps.executeUpdate();
            }
        });
    }

    public boolean routeHasAssignment(int routeId) throws SQLException {
        return exists("SELECT 1 FROM asignaciones_entrega WHERE id_ruta = ?", routeId);
    }

    // Un vehiculo (o conductor) esta ocupado si esta en otra ruta que aun no termina.
    // idRutaExcluida es la ruta que se esta editando (use 0 para no excluir ninguna).
    public boolean isVehicleBusy(int vehicleId, int excludedRouteId) throws SQLException {
        return exists("SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta "
                + "WHERE a.id_vehiculo = ? AND a.id_ruta <> ? AND " + PENDING_ROUTE_CONDITION,
                vehicleId, excludedRouteId);
    }

    public boolean isDriverBusy(int driverId, int excludedRouteId) throws SQLException {
        return exists("SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta "
                + "WHERE a.id_conductor = ? AND a.id_ruta <> ? AND " + PENDING_ROUTE_CONDITION,
                driverId, excludedRouteId);
    }

    // Si la ruta ya tenia vehiculo y conductor, se cambian; si no, se crea la asignacion.
    public void saveAssignment(int routeId, int vehicleId, int driverId) throws SQLException {
        String sql = routeHasAssignment(routeId)
                ? "UPDATE asignaciones_entrega SET id_vehiculo = ?, id_conductor = ? WHERE id_ruta = ?"
                : "INSERT INTO asignaciones_entrega (id_vehiculo, id_conductor, id_ruta) VALUES (?, ?, ?)";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, vehicleId);
            ps.setInt(2, driverId);
            ps.setInt(3, routeId);
            ps.executeUpdate();
        }
    }

    // ---------- Ventas dentro de una ruta ----------

    public boolean saleIsInPreparation(int saleId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT 1 FROM ventas v JOIN estados_venta e ON e.id_estado = v.id_estado "
                + "WHERE v.id_venta = ? AND e.nombre = ?")) {
            ps.setInt(1, saleId);
            ps.setString(2, SaleStatus.IN_PREPARATION.databaseValue());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // Una venta solo puede estar en una ruta.
    public boolean saleIsAlreadyAssigned(int saleId) throws SQLException {
        return exists("SELECT 1 FROM ventas_ruta WHERE id_venta = ?", saleId);
    }

    public Optional<String> customerAddress(int saleId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT c.direccion FROM ventas v JOIN clientes c ON c.id_cliente = v.id_cliente WHERE v.id_venta = ?")) {
            ps.setInt(1, saleId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.ofNullable(rs.getString("direccion")) : Optional.empty();
            }
        }
    }

    public int nextDeliveryOrder(int routeId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "SELECT COALESCE(MAX(orden_entrega), 0) + 1 FROM ventas_ruta WHERE id_ruta = ?")) {
            ps.setInt(1, routeId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // El NOT EXISTS evita que una venta quede en dos rutas aunque dos personas asignen a la vez.
    public void insertSaleIntoRoute(int routeId, int saleId, int order, String deliveryAddress) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino) "
                + "SELECT ?, ?, ?, ? FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM ventas_ruta WHERE id_venta = ?)")) {
            ps.setInt(1, routeId);
            ps.setInt(2, saleId);
            ps.setInt(3, order);
            ps.setString(4, deliveryAddress);
            ps.setInt(5, saleId);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("La venta " + saleId + " ya esta asignada a una ruta.");
            }
        }
    }

    // Solo se quitan ventas que aun no fueron entregadas.
    public boolean removeSaleFromRoute(int routeId, int saleId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(
                "DELETE FROM ventas_ruta WHERE id_ruta = ? AND id_venta = ? AND fecha_entrega IS NULL")) {
            ps.setInt(1, routeId);
            ps.setInt(2, saleId);
            return ps.executeUpdate() > 0;
        }
    }

    public List<RouteDelivery> listDeliveries(int routeId) throws SQLException {
        String sql = "SELECT vr.id_venta, v.numero_venta, vr.orden_entrega, vr.direccion_destino, "
                + "vr.fecha_entrega, vr.recibido_por, vr.observaciones "
                + "FROM ventas_ruta vr JOIN ventas v ON v.id_venta = vr.id_venta "
                + "WHERE vr.id_ruta = ? ORDER BY vr.orden_entrega, vr.id";
        List<RouteDelivery> deliveries = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setInt(1, routeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    deliveries.add(new RouteDelivery(rs.getInt("id_venta"), rs.getString("numero_venta"),
                            (Integer) rs.getObject("orden_entrega"), rs.getString("direccion_destino"),
                            rs.getTimestamp("fecha_entrega"), rs.getString("recibido_por"),
                            rs.getString("observaciones")));
                }
            }
        }
        return deliveries;
    }

    // ---------- Operaciones con transaccion ----------

    // Despacho: la ruta pasa a "En Transito" y todas sus ventas de "En Preparacion" a "En Transito".
    // Si alguna venta ya no esta en preparacion, se revierte todo.
    public void startDispatch(int routeId) throws SQLException {
        executeInTransaction(() -> {
            changeRouteStatus("UPDATE rutas_entrega SET estado = ?, hora_salida_real = NOW() "
                    + "WHERE id_ruta = ? AND estado = ?", RouteStatus.IN_TRANSIT, routeId, RouteStatus.PLANNED);

            String sql = "UPDATE ventas SET id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                    + "WHERE id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                    + "AND id_venta IN (SELECT id_venta FROM ventas_ruta WHERE id_ruta = ?)";
            int actualizadas;
            try (PreparedStatement ps = connection.prepareStatement(sql)) {
                ps.setString(1, SaleStatus.IN_TRANSIT.databaseValue());
                ps.setString(2, SaleStatus.IN_PREPARATION.databaseValue());
                ps.setInt(3, routeId);
                actualizadas = ps.executeUpdate();
            }
            if (actualizadas != countRouteSales(routeId)) {
                throw new IllegalArgumentException(
                        "Alguna venta de la ruta ya no esta en preparacion. El despacho no se realizo.");
            }
        });
    }

    // Entrega: guarda fecha, receptor y observaciones, pasa la venta a "Entregada" y,
    // si era la ultima pendiente, cierra la ruta como "Completada". Devuelve true si la ruta se completo.
    // La transaccion se escribe aqui (no con ejecutarEnTransaccion) porque el metodo devuelve un valor.
    public boolean confirmDelivery(int routeId, int saleId, String receivedBy, String observations) throws SQLException {
        boolean autoCommitOriginal = connection.getAutoCommit();
        connection.setAutoCommit(false);
        try {
            String sqlEntrega = "UPDATE ventas_ruta SET fecha_entrega = NOW(), recibido_por = ?, observaciones = ? "
                    + "WHERE id_ruta = ? AND id_venta = ? AND fecha_entrega IS NULL "
                    + "AND EXISTS (SELECT 1 FROM rutas_entrega WHERE id_ruta = ? AND estado = ?)";
            try (PreparedStatement ps = connection.prepareStatement(sqlEntrega)) {
                ps.setString(1, receivedBy);
                ps.setString(2, observations);
                ps.setInt(3, routeId);
                ps.setInt(4, saleId);
                ps.setInt(5, routeId);
                ps.setString(6, RouteStatus.IN_TRANSIT.databaseValue());
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("No se puede confirmar: la ruta no esta en transito, "
                            + "la venta no pertenece a la ruta o ya fue entregada.");
                }
            }

            String sqlVenta = "UPDATE ventas SET id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                    + "WHERE id_venta = ? AND id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?)";
            try (PreparedStatement ps = connection.prepareStatement(sqlVenta)) {
                ps.setString(1, SaleStatus.DELIVERED.databaseValue());
                ps.setInt(2, saleId);
                ps.setString(3, SaleStatus.IN_TRANSIT.databaseValue());
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("La venta no esta en transito; no se puede marcar como entregada.");
                }
            }

            boolean rutaCompletada = !exists("SELECT 1 FROM ventas_ruta WHERE id_ruta = ? AND fecha_entrega IS NULL", routeId);
            if (rutaCompletada) {
                changeRouteStatus("UPDATE rutas_entrega SET estado = ?, hora_llegada_real = NOW() "
                        + "WHERE id_ruta = ? AND estado = ?", RouteStatus.COMPLETED, routeId, RouteStatus.IN_TRANSIT);
            }
            connection.commit();
            return rutaCompletada;
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(autoCommitOriginal);
        }
    }

    // ---------- Auxiliares ----------

    // Operacion de base de datos que puede lanzar SQLException.
    private interface TransactionOperation {
        void run() throws SQLException;
    }

    // Todo o nada: commit si la operacion termina bien, rollback si falla.
    private void executeInTransaction(TransactionOperation operation) throws SQLException {
        boolean autoCommitOriginal = connection.getAutoCommit();
        connection.setAutoCommit(false);
        try {
            operation.run();
            connection.commit();
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(autoCommitOriginal);
        }
    }

    // Cambia el estado de una ruta solo si esta en el estado esperado (asi detecta cambios simultaneos).
    private void changeRouteStatus(String sql, RouteStatus newStatus, int routeId, RouteStatus expectedStatus) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, newStatus.databaseValue());
            ps.setInt(2, routeId);
            ps.setString(3, expectedStatus.databaseValue());
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("La ruta ya no esta en estado " + expectedStatus.databaseValue() + ".");
            }
        }
    }

    private int countRouteSales(int routeId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("SELECT COUNT(*) FROM ventas_ruta WHERE id_ruta = ?")) {
            ps.setInt(1, routeId);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // Consulta con parametros enteros: true si devuelve al menos una fila.
    private boolean exists(String sql, int... parameters) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (int i = 0; i < parameters.length; i++) {
                ps.setInt(i + 1, parameters[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private Vehicle mapVehicle(ResultSet rs) throws SQLException {
        return new Vehicle(rs.getInt("id_vehiculo"), rs.getString("placa"), rs.getString("modelo"),
                rs.getBigDecimal("capacidad"), VehicleStatus.fromDatabaseValue(rs.getString("estado")));
    }

    private Driver mapDriver(ResultSet rs) throws SQLException {
        return new Driver(rs.getInt("id_conductor"), rs.getString("nombre"), rs.getString("numero_licencia"),
                rs.getString("telefono"), rs.getString("email"), rs.getBoolean("activo"));
    }

    private Route mapRoute(ResultSet rs) throws SQLException {
        return new Route(rs.getInt("id_ruta"), rs.getString("nombre_ruta"), rs.getTimestamp("hora_salida_estimada"),
                rs.getTimestamp("hora_llegada_estimada"), rs.getTimestamp("hora_salida_real"),
                rs.getTimestamp("hora_llegada_real"), RouteStatus.fromDatabaseValue(rs.getString("estado")),
                rs.getString("placa"), rs.getString("conductor"));
    }
}
