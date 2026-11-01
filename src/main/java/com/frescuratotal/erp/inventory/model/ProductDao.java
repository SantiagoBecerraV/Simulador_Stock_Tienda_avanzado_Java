/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.model;

import com.frescuratotal.erp.common.DatabaseConnection;
import java.math.BigDecimal;
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
public class ProductDao {

    public List<Product> findAll() throws SQLException {
        String sql = "SELECT id_producto, nombre, descripcion, id_categoria, unidad_medida, precio_base "
                   + "FROM productos ORDER BY nombre";
        List<Product> products = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                products.add(mapRow(rs));
            }
        }
        return products;
    }

    // Retorna las categorias con el formato '1 - Frutas', para que el usuario pueda elegir el numero
    public List<String> findCategories() throws SQLException {
        String sql = "SELECT id_categoria, nombre FROM categorias_producto ORDER BY id_categoria";
        List<String> categories = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                categories.add(rs.getInt("id_categoria") + " - " + rs.getString("nombre"));
            }
        }
        return categories;
    }

    public void insert(Product product) throws SQLException {
        String sql = "INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base) "
                   + "VALUES (?, ?, ?, ?, ?)";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, product.getName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setString(4, product.getUnit());
            statement.setBigDecimal(5, product.getBasePrice());
            statement.executeUpdate();
        }
    }

    public boolean update(Product product) throws SQLException {
        String sql = "UPDATE productos SET nombre = ?, descripcion = ?, id_categoria = ?, "
                   + "unidad_medida = ?, precio_base = ? WHERE id_producto = ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, product.getName());
            statement.setString(2, product.getDescription());
            statement.setInt(3, product.getCategoryId());
            statement.setString(4, product.getUnit());
            statement.setBigDecimal(5, product.getBasePrice());
            statement.setInt(6, product.getId());
            return statement.executeUpdate() > 0;
        }
    }

    // La tabla products no tiene columna "active", por lo que esta es una eliminacion real.
    // MySQL la rechaza si todavía hay lotes usando el producto, y ese es el comportamiento esperado.
    public boolean delete(int id) throws SQLException {
        String sql = "DELETE FROM productos WHERE id_producto = ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, id);
            return statement.executeUpdate() > 0;
        }
    }

    private Product mapRow(ResultSet rs) throws SQLException {
        return new Product(
                rs.getInt("id_producto"),
                rs.getString("nombre"),
                rs.getString("descripcion"),
                rs.getInt("id_categoria"),
                rs.getString("unidad_medida"),
                rs.getBigDecimal("precio_base"));
    }
}
