package com.frescuratotal.erp.sales.dao;

import com.frescuratotal.erp.sales.model.Customer;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class CustomerDao {

    private static final String SELECT =
            "SELECT c.id_cliente, c.nombre, c.documento, c.email, c.telefono, c.direccion, "
            + "c.id_tipo, t.nombre AS tipo, c.fecha_registro "
            + "FROM clientes c JOIN tipos_cliente t ON t.id_tipo = c.id_tipo ";

    // La conexion viene del paquete comun compartido; este DAO no abre la suya.
    private final Connection connection;

    public CustomerDao(Connection connection) {
        this.connection = connection;
    }

    public List<Customer> findAll() throws SQLException {
        List<Customer> customers = new ArrayList<>();
        try (PreparedStatement ps = connection.prepareStatement(SELECT + "ORDER BY c.id_cliente");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                customers.add(map(rs));
            }
        }
        return customers;
    }

    public Optional<Customer> findById(int customerId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement(SELECT + "WHERE c.id_cliente = ?")) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(map(rs)) : Optional.empty();
            }
        }
    }

    public void insert(Customer c) throws SQLException {
        String sql = "INSERT INTO clientes (nombre, documento, email, telefono, direccion, id_tipo) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, c.name());
            ps.setString(2, c.document());
            ps.setString(3, c.email());
            ps.setString(4, c.phone());
            ps.setString(5, c.address());
            ps.setInt(6, c.typeId());
            ps.executeUpdate();
        }
    }

    // Punto 4: indica si el documento ya está registrado.
    public boolean documentExists(String document) throws SQLException {
        String sql = "SELECT 1 FROM clientes WHERE documento = ? LIMIT 1";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, document);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // Punto 4: inserta todos los clientes o revierte el lote completo.
    public void insertAll(List<Customer> customers) throws SQLException {
        String sql = "INSERT INTO clientes (nombre, documento, email, telefono, direccion, id_tipo) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        boolean originalAutoCommit = connection.getAutoCommit();
        connection.setAutoCommit(false);
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            for (Customer customer : customers) {
                ps.setString(1, customer.name());
                ps.setString(2, customer.document());
                ps.setString(3, customer.email());
                ps.setString(4, customer.phone());
                ps.setString(5, customer.address());
                ps.setInt(6, customer.typeId());
                ps.addBatch();
            }
            ps.executeBatch();
            connection.commit();
        } catch (SQLException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(originalAutoCommit);
        }
    }

    // fecha_registro no se incluye en el UPDATE a proposito.
    public boolean update(Customer c) throws SQLException {
        String sql = "UPDATE clientes SET nombre = ?, documento = ?, email = ?, telefono = ?, "
                + "direccion = ?, id_tipo = ? WHERE id_cliente = ?";
        try (PreparedStatement ps = connection.prepareStatement(sql)) {
            ps.setString(1, c.name());
            ps.setString(2, c.document());
            ps.setString(3, c.email());
            ps.setString(4, c.phone());
            ps.setString(5, c.address());
            ps.setInt(6, c.typeId());
            ps.setInt(7, c.customerId());
            return ps.executeUpdate() > 0;
        }
    }

    public boolean delete(int customerId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("DELETE FROM clientes WHERE id_cliente = ?")) {
            ps.setInt(1, customerId);
            return ps.executeUpdate() > 0;
        }
    }

    public boolean hasSales(int customerId) throws SQLException {
        try (PreparedStatement ps = connection.prepareStatement("SELECT 1 FROM ventas WHERE id_cliente = ? LIMIT 1")) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // id_tipo -> nombre, leido del catalogo para no escribir ids fijos en el codigo.
    public Map<Integer, String> findTypes() throws SQLException {
        Map<Integer, String> types = new LinkedHashMap<>();
        try (PreparedStatement ps = connection.prepareStatement("SELECT id_tipo, nombre FROM tipos_cliente ORDER BY id_tipo");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                types.put(rs.getInt("id_tipo"), rs.getString("nombre"));
            }
        }
        return types;
    }

    private Customer map(ResultSet rs) throws SQLException {
        return new Customer(
                rs.getInt("id_cliente"),
                rs.getString("nombre"),
                rs.getString("documento"),
                rs.getString("email"),
                rs.getString("telefono"),
                rs.getString("direccion"),
                rs.getInt("id_tipo"),
                rs.getString("tipo"),
                rs.getTimestamp("fecha_registro"));
    }
}
