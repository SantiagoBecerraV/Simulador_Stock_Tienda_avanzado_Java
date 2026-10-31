/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.suppliers.model;

import com.frescuratotal.erp.common.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

/**
 *
 * @author admin
 */
public class SupplierDao {

    public List<Supplier> findAll() throws SQLException {
        String sql = "SELECT id_proveedor, nombre, nit, persona_contacto, email, telefono, direccion, activo "
                   + "FROM proveedores ORDER BY nombre";
        List<Supplier> suppliers = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                suppliers.add(mapRow(rs));
            }
        }
        return suppliers;
    }

    public void insert(Supplier supplier) throws SQLException {
        String sql = "INSERT INTO proveedores (nombre, nit, persona_contacto, email, telefono, direccion) "
                   + "VALUES (?, ?, ?, ?, ?, ?)";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, supplier.getName());
            statement.setString(2, supplier.getNit());
            statement.setString(3, supplier.getContactPerson());
            statement.setString(4, supplier.getEmail());
            statement.setString(5, supplier.getPhone());
            statement.setString(6, supplier.getAddress());
            statement.executeUpdate();
        }
    }

    // Retorna true si se modificó una fila.
    public boolean update(Supplier supplier) throws SQLException {
        String sql = "UPDATE proveedores SET nombre = ?, nit = ?, persona_contacto = ?, "
                   + "email = ?, telefono = ?, direccion = ? WHERE id_proveedor = ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, supplier.getName());
            statement.setString(2, supplier.getNit());
            statement.setString(3, supplier.getContactPerson());
            statement.setString(4, supplier.getEmail());
            statement.setString(5, supplier.getPhone());
            statement.setString(6, supplier.getAddress());
            statement.setInt(7, supplier.getId());
            return statement.executeUpdate() > 0;
        }
    }

    // No eliminamos proveedores: los lotes apuntan a ellos, así que solo los marcamos como inactivos.
    public boolean deactivate(int id) throws SQLException {
        String sql = "UPDATE proveedores SET activo = FALSE WHERE id_proveedor = ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            return statement.executeUpdate() > 0;
        }
    }

    // Convierte una fila de la tabla en un objeto Supplier.
    private Supplier mapRow(ResultSet rs) throws SQLException {
        return new Supplier(
                rs.getInt("id_proveedor"),
                rs.getString("nombre"),
                rs.getString("nit"),
                rs.getString("persona_contacto"),
                rs.getString("email"),
                rs.getString("telefono"),
                rs.getString("direccion"),
                rs.getBoolean("activo"));
    }
}



