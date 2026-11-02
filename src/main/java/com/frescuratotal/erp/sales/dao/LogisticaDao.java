package com.frescuratotal.erp.sales.dao;

import com.frescuratotal.erp.sales.model.Conductor;
import com.frescuratotal.erp.sales.model.EntregaRuta;
import com.frescuratotal.erp.sales.model.EstadoRuta;
import com.frescuratotal.erp.sales.model.EstadoVehiculo;
import com.frescuratotal.erp.sales.model.EstadoVenta;
import com.frescuratotal.erp.sales.model.Ruta;
import com.frescuratotal.erp.sales.model.Vehiculo;
import com.frescuratotal.erp.sales.model.VentaEnPreparacion;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class LogisticaDao {

    private static final String SELECT_RUTA =
            "SELECT r.id_ruta, r.nombre_ruta, r.hora_salida_estimada, r.hora_llegada_estimada, "
            + "r.hora_salida_real, r.hora_llegada_real, r.estado, ve.placa, co.nombre AS conductor "
            + "FROM rutas_entrega r "
            + "LEFT JOIN asignaciones_entrega a ON a.id_ruta = r.id_ruta "
            + "LEFT JOIN vehiculos ve ON ve.id_vehiculo = a.id_vehiculo "
            + "LEFT JOIN conductores co ON co.id_conductor = a.id_conductor ";

    // La conexion viene del paquete comun compartido; este DAO no abre la suya.
    private final Connection conexion;

    public LogisticaDao(Connection conexion) {
        this.conexion = conexion;
    }

    // ---------- Ventas ----------

    // La columna idRuta sirve para ver que ventas ya estan asignadas a una ruta.
    public List<VentaEnPreparacion> listarVentasEnPreparacion() throws SQLException {
        String sql = "SELECT v.id_venta, v.numero_venta, c.nombre, c.direccion, v.monto_total, vr.id_ruta "
                + "FROM ventas v "
                + "JOIN estados_venta e ON e.id_estado = v.id_estado "
                + "JOIN clientes c ON c.id_cliente = v.id_cliente "
                + "LEFT JOIN ventas_ruta vr ON vr.id_venta = v.id_venta "
                + "WHERE e.nombre = ? ORDER BY v.fecha_venta, v.id_venta";
        List<VentaEnPreparacion> ventas = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setString(1, EstadoVenta.IN_PREPARATION.valorBd());
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    ventas.add(new VentaEnPreparacion(rs.getInt("id_venta"), rs.getString("numero_venta"),
                            rs.getString("nombre"), rs.getString("direccion"), rs.getBigDecimal("monto_total"),
                            (Integer) rs.getObject("id_ruta")));
                }
            }
        }
        return ventas;
    }

    // ---------- Vehiculos ----------

    public List<Vehiculo> listarVehiculos() throws SQLException {
        List<Vehiculo> vehiculos = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_vehiculo, placa, modelo, capacidad, estado FROM vehiculos ORDER BY id_vehiculo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                vehiculos.add(mapearVehiculo(rs));
            }
        }
        return vehiculos;
    }

    public Optional<Vehiculo> buscarVehiculo(int idVehiculo) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_vehiculo, placa, modelo, capacidad, estado FROM vehiculos WHERE id_vehiculo = ?")) {
            ps.setInt(1, idVehiculo);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapearVehiculo(rs)) : Optional.empty();
            }
        }
    }

    public void insertarVehiculo(String placa, String modelo, BigDecimal capacidad) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "INSERT INTO vehiculos (placa, modelo, capacidad) VALUES (?, ?, ?)")) {
            ps.setString(1, placa);
            ps.setString(2, modelo);
            ps.setBigDecimal(3, capacidad);
            ps.executeUpdate();
        }
    }

    public boolean actualizarVehiculo(int idVehiculo, String placa, String modelo, BigDecimal capacidad)
            throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "UPDATE vehiculos SET placa = ?, modelo = ?, capacidad = ? WHERE id_vehiculo = ?")) {
            ps.setString(1, placa);
            ps.setString(2, modelo);
            ps.setBigDecimal(3, capacidad);
            ps.setInt(4, idVehiculo);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean vehiculoTieneAsignaciones(int idVehiculo) throws SQLException {
        return existe("SELECT 1 FROM asignaciones_entrega WHERE id_vehiculo = ?", idVehiculo);
    }

    public boolean eliminarVehiculo(int idVehiculo) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM vehiculos WHERE id_vehiculo = ?")) {
            ps.setInt(1, idVehiculo);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean cambiarEstadoVehiculo(int idVehiculo, EstadoVehiculo estado) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement("UPDATE vehiculos SET estado = ? WHERE id_vehiculo = ?")) {
            ps.setString(1, estado.valorBd());
            ps.setInt(2, idVehiculo);
            return ps.executeUpdate() > 0;
        }
    }

    // ---------- Conductores ----------

    public List<Conductor> listarConductores() throws SQLException {
        List<Conductor> conductores = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_conductor, nombre, numero_licencia, telefono, email, activo "
                + "FROM conductores ORDER BY id_conductor");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                conductores.add(mapearConductor(rs));
            }
        }
        return conductores;
    }

    public Optional<Conductor> buscarConductor(int idConductor) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT id_conductor, nombre, numero_licencia, telefono, email, activo "
                + "FROM conductores WHERE id_conductor = ?")) {
            ps.setInt(1, idConductor);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapearConductor(rs)) : Optional.empty();
            }
        }
    }

    public void insertarConductor(String nombre, String licencia, String telefono, String email) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "INSERT INTO conductores (nombre, numero_licencia, telefono, email) VALUES (?, ?, ?, ?)")) {
            ps.setString(1, nombre);
            ps.setString(2, licencia);
            ps.setString(3, telefono);
            ps.setString(4, email);
            ps.executeUpdate();
        }
    }

    public boolean actualizarConductor(int idConductor, String nombre, String licencia, String telefono, String email)
            throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "UPDATE conductores SET nombre = ?, numero_licencia = ?, telefono = ?, email = ? WHERE id_conductor = ?")) {
            ps.setString(1, nombre);
            ps.setString(2, licencia);
            ps.setString(3, telefono);
            ps.setString(4, email);
            ps.setInt(5, idConductor);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean conductorTieneAsignaciones(int idConductor) throws SQLException {
        return existe("SELECT 1 FROM asignaciones_entrega WHERE id_conductor = ?", idConductor);
    }

    public boolean eliminarConductor(int idConductor) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM conductores WHERE id_conductor = ?")) {
            ps.setInt(1, idConductor);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean cambiarActivoConductor(int idConductor, boolean activo) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement("UPDATE conductores SET activo = ? WHERE id_conductor = ?")) {
            ps.setBoolean(1, activo);
            ps.setInt(2, idConductor);
            return ps.executeUpdate() > 0;
        }
    }

    // ---------- Rutas y asignaciones ----------

    public List<Ruta> listarRutas() throws SQLException {
        List<Ruta> rutas = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(SELECT_RUTA + "ORDER BY r.id_ruta");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                rutas.add(mapearRuta(rs));
            }
        }
        return rutas;
    }

    public Optional<Ruta> buscarRuta(int idRuta) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(SELECT_RUTA + "WHERE r.id_ruta = ?")) {
            ps.setInt(1, idRuta);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapearRuta(rs)) : Optional.empty();
            }
        }
    }

    public void insertarRuta(String nombreRuta, Timestamp salidaEstimada, Timestamp llegadaEstimada) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "INSERT INTO rutas_entrega (nombre_ruta, hora_salida_estimada, hora_llegada_estimada) VALUES (?, ?, ?)")) {
            ps.setString(1, nombreRuta);
            ps.setTimestamp(2, salidaEstimada);
            ps.setTimestamp(3, llegadaEstimada);
            ps.executeUpdate();
        }
    }

    public boolean actualizarRuta(int idRuta, String nombreRuta, Timestamp salidaEstimada, Timestamp llegadaEstimada)
            throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "UPDATE rutas_entrega SET nombre_ruta = ?, hora_salida_estimada = ?, hora_llegada_estimada = ? "
                + "WHERE id_ruta = ?")) {
            ps.setString(1, nombreRuta);
            ps.setTimestamp(2, salidaEstimada);
            ps.setTimestamp(3, llegadaEstimada);
            ps.setInt(4, idRuta);
            return ps.executeUpdate() > 0;
        }
    }

    // Una ruta no se borra: se cancela y conserva su historial. Sus ventas quedan libres para otra ruta.
    public void cancelarRuta(int idRuta) throws SQLException {
        ejecutarEnTransaccion(() -> {
            cambiarEstadoRuta("UPDATE rutas_entrega SET estado = ? WHERE id_ruta = ? AND estado = ?",
                    EstadoRuta.CANCELADA, idRuta, EstadoRuta.PLANIFICADA);
            try (PreparedStatement ps = conexion.prepareStatement("DELETE FROM ventas_ruta WHERE id_ruta = ?")) {
                ps.setInt(1, idRuta);
                ps.executeUpdate();
            }
        });
    }

    public boolean rutaTieneAsignacion(int idRuta) throws SQLException {
        return existe("SELECT 1 FROM asignaciones_entrega WHERE id_ruta = ?", idRuta);
    }

    // Un vehiculo (o conductor) esta ocupado si esta en otra ruta que aun no termina.
    // idRutaExcluida es la ruta que se esta editando (use 0 para no excluir ninguna).
    public boolean vehiculoOcupado(int idVehiculo, int idRutaExcluida) throws SQLException {
        return existe("SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta "
                + "WHERE a.id_vehiculo = ? AND a.id_ruta <> ? AND r.estado IN ('Planificada', 'En Transito')",
                idVehiculo, idRutaExcluida);
    }

    public boolean conductorOcupado(int idConductor, int idRutaExcluida) throws SQLException {
        return existe("SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta "
                + "WHERE a.id_conductor = ? AND a.id_ruta <> ? AND r.estado IN ('Planificada', 'En Transito')",
                idConductor, idRutaExcluida);
    }

    // Si la ruta ya tenia vehiculo y conductor, se cambian; si no, se crea la asignacion.
    public void guardarAsignacion(int idRuta, int idVehiculo, int idConductor) throws SQLException {
        String sql = rutaTieneAsignacion(idRuta)
                ? "UPDATE asignaciones_entrega SET id_vehiculo = ?, id_conductor = ? WHERE id_ruta = ?"
                : "INSERT INTO asignaciones_entrega (id_vehiculo, id_conductor, id_ruta) VALUES (?, ?, ?)";
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setInt(1, idVehiculo);
            ps.setInt(2, idConductor);
            ps.setInt(3, idRuta);
            ps.executeUpdate();
        }
    }

    // ---------- Ventas dentro de una ruta ----------

    public boolean ventaEstaEnPreparacion(int idVenta) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT 1 FROM ventas v JOIN estados_venta e ON e.id_estado = v.id_estado "
                + "WHERE v.id_venta = ? AND e.nombre = ?")) {
            ps.setInt(1, idVenta);
            ps.setString(2, EstadoVenta.IN_PREPARATION.valorBd());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // Una venta solo puede estar en una ruta.
    public boolean ventaYaAsignada(int idVenta) throws SQLException {
        return existe("SELECT 1 FROM ventas_ruta WHERE id_venta = ?", idVenta);
    }

    public Optional<String> direccionDelCliente(int idVenta) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT c.direccion FROM ventas v JOIN clientes c ON c.id_cliente = v.id_cliente WHERE v.id_venta = ?")) {
            ps.setInt(1, idVenta);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.ofNullable(rs.getString("direccion")) : Optional.empty();
            }
        }
    }

    public int siguienteOrdenEntrega(int idRuta) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "SELECT COALESCE(MAX(orden_entrega), 0) + 1 FROM ventas_ruta WHERE id_ruta = ?")) {
            ps.setInt(1, idRuta);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // El NOT EXISTS evita que una venta quede en dos rutas aunque dos personas asignen a la vez.
    public void insertarVentaEnRuta(int idRuta, int idVenta, int orden, String direccionDestino) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino) "
                + "SELECT ?, ?, ?, ? FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM ventas_ruta WHERE id_venta = ?)")) {
            ps.setInt(1, idRuta);
            ps.setInt(2, idVenta);
            ps.setInt(3, orden);
            ps.setString(4, direccionDestino);
            ps.setInt(5, idVenta);
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("La venta " + idVenta + " ya esta asignada a una ruta.");
            }
        }
    }

    // Solo se quitan ventas que aun no fueron entregadas.
    public boolean quitarVentaDeRuta(int idRuta, int idVenta) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(
                "DELETE FROM ventas_ruta WHERE id_ruta = ? AND id_venta = ? AND fecha_entrega IS NULL")) {
            ps.setInt(1, idRuta);
            ps.setInt(2, idVenta);
            return ps.executeUpdate() > 0;
        }
    }

    public List<EntregaRuta> listarEntregas(int idRuta) throws SQLException {
        String sql = "SELECT vr.id_venta, v.numero_venta, vr.orden_entrega, vr.direccion_destino, "
                + "vr.fecha_entrega, vr.recibido_por, vr.observaciones "
                + "FROM ventas_ruta vr JOIN ventas v ON v.id_venta = vr.id_venta "
                + "WHERE vr.id_ruta = ? ORDER BY vr.orden_entrega, vr.id";
        List<EntregaRuta> entregas = new ArrayList<>();
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setInt(1, idRuta);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    entregas.add(new EntregaRuta(rs.getInt("id_venta"), rs.getString("numero_venta"),
                            (Integer) rs.getObject("orden_entrega"), rs.getString("direccion_destino"),
                            rs.getTimestamp("fecha_entrega"), rs.getString("recibido_por"),
                            rs.getString("observaciones")));
                }
            }
        }
        return entregas;
    }

    // ---------- Operaciones con transaccion ----------

    // Despacho: la ruta pasa a "En Transito" y todas sus ventas de "En Preparacion" a "En Transito".
    // Si alguna venta ya no esta en preparacion, se revierte todo.
    public void iniciarDespacho(int idRuta) throws SQLException {
        ejecutarEnTransaccion(() -> {
            cambiarEstadoRuta("UPDATE rutas_entrega SET estado = ?, hora_salida_real = NOW() "
                    + "WHERE id_ruta = ? AND estado = ?", EstadoRuta.EN_TRANSITO, idRuta, EstadoRuta.PLANIFICADA);

            String sql = "UPDATE ventas SET id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                    + "WHERE id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                    + "AND id_venta IN (SELECT id_venta FROM ventas_ruta WHERE id_ruta = ?)";
            int actualizadas;
            try (PreparedStatement ps = conexion.prepareStatement(sql)) {
                ps.setString(1, EstadoVenta.IN_TRANSIT.valorBd());
                ps.setString(2, EstadoVenta.IN_PREPARATION.valorBd());
                ps.setInt(3, idRuta);
                actualizadas = ps.executeUpdate();
            }
            if (actualizadas != contarVentasRuta(idRuta)) {
                throw new IllegalArgumentException(
                        "Alguna venta de la ruta ya no esta en preparacion. El despacho no se realizo.");
            }
        });
    }

    // Entrega: guarda fecha, receptor y observaciones, pasa la venta a "Entregada" y,
    // si era la ultima pendiente, cierra la ruta como "Completada". Devuelve true si la ruta se completo.
    public boolean confirmarEntrega(int idRuta, int idVenta, String recibidoPor, String observaciones) throws SQLException {
        boolean[] rutaCompletada = {false};
        ejecutarEnTransaccion(() -> {
            String sqlEntrega = "UPDATE ventas_ruta SET fecha_entrega = NOW(), recibido_por = ?, observaciones = ? "
                    + "WHERE id_ruta = ? AND id_venta = ? AND fecha_entrega IS NULL "
                    + "AND EXISTS (SELECT 1 FROM rutas_entrega WHERE id_ruta = ? AND estado = ?)";
            try (PreparedStatement ps = conexion.prepareStatement(sqlEntrega)) {
                ps.setString(1, recibidoPor);
                ps.setString(2, observaciones);
                ps.setInt(3, idRuta);
                ps.setInt(4, idVenta);
                ps.setInt(5, idRuta);
                ps.setString(6, EstadoRuta.EN_TRANSITO.valorBd());
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("No se puede confirmar: la ruta no esta en transito, "
                            + "la venta no pertenece a la ruta o ya fue entregada.");
                }
            }

            String sqlVenta = "UPDATE ventas SET id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?) "
                    + "WHERE id_venta = ? AND id_estado = (SELECT id_estado FROM estados_venta WHERE nombre = ?)";
            try (PreparedStatement ps = conexion.prepareStatement(sqlVenta)) {
                ps.setString(1, EstadoVenta.DELIVERED.valorBd());
                ps.setInt(2, idVenta);
                ps.setString(3, EstadoVenta.IN_TRANSIT.valorBd());
                if (ps.executeUpdate() == 0) {
                    throw new IllegalArgumentException("La venta no esta en transito; no se puede marcar como entregada.");
                }
            }

            if (existe("SELECT 1 FROM ventas_ruta WHERE id_ruta = ? AND fecha_entrega IS NULL", idRuta)) {
                return;
            }
            cambiarEstadoRuta("UPDATE rutas_entrega SET estado = ?, hora_llegada_real = NOW() "
                    + "WHERE id_ruta = ? AND estado = ?", EstadoRuta.COMPLETADA, idRuta, EstadoRuta.EN_TRANSITO);
            rutaCompletada[0] = true;
        });
        return rutaCompletada[0];
    }

    // ---------- Auxiliares ----------

    // Operacion de base de datos que puede lanzar SQLException.
    private interface Operacion {
        void ejecutar() throws SQLException;
    }

    // Todo o nada: commit si la operacion termina bien, rollback si falla.
    private void ejecutarEnTransaccion(Operacion operacion) throws SQLException {
        boolean autoCommitOriginal = conexion.getAutoCommit();
        conexion.setAutoCommit(false);
        try {
            operacion.ejecutar();
            conexion.commit();
        } catch (SQLException | RuntimeException e) {
            conexion.rollback();
            throw e;
        } finally {
            conexion.setAutoCommit(autoCommitOriginal);
        }
    }

    // Cambia el estado de una ruta solo si esta en el estado esperado (asi detecta cambios simultaneos).
    private void cambiarEstadoRuta(String sql, EstadoRuta nuevo, int idRuta, EstadoRuta esperado) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            ps.setString(1, nuevo.valorBd());
            ps.setInt(2, idRuta);
            ps.setString(3, esperado.valorBd());
            if (ps.executeUpdate() == 0) {
                throw new IllegalArgumentException("La ruta ya no esta en estado " + esperado.valorBd() + ".");
            }
        }
    }

    private int contarVentasRuta(int idRuta) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement("SELECT COUNT(*) FROM ventas_ruta WHERE id_ruta = ?")) {
            ps.setInt(1, idRuta);
            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // Consulta con parametros enteros: true si devuelve al menos una fila.
    private boolean existe(String sql, int... parametros) throws SQLException {
        try (PreparedStatement ps = conexion.prepareStatement(sql)) {
            for (int i = 0; i < parametros.length; i++) {
                ps.setInt(i + 1, parametros[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private Vehiculo mapearVehiculo(ResultSet rs) throws SQLException {
        return new Vehiculo(rs.getInt("id_vehiculo"), rs.getString("placa"), rs.getString("modelo"),
                rs.getBigDecimal("capacidad"), EstadoVehiculo.desdeBd(rs.getString("estado")));
    }

    private Conductor mapearConductor(ResultSet rs) throws SQLException {
        return new Conductor(rs.getInt("id_conductor"), rs.getString("nombre"), rs.getString("numero_licencia"),
                rs.getString("telefono"), rs.getString("email"), rs.getBoolean("activo"));
    }

    private Ruta mapearRuta(ResultSet rs) throws SQLException {
        return new Ruta(rs.getInt("id_ruta"), rs.getString("nombre_ruta"), rs.getTimestamp("hora_salida_estimada"),
                rs.getTimestamp("hora_llegada_estimada"), rs.getTimestamp("hora_salida_real"),
                rs.getTimestamp("hora_llegada_real"), EstadoRuta.desdeBd(rs.getString("estado")),
                rs.getString("placa"), rs.getString("conductor"));
    }
}
