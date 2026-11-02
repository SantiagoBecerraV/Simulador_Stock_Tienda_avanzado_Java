/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.model;

import com.frescuratotal.erp.common.DatabaseConnection;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.time.LocalDate;
import java.util.Optional;
import java.math.BigDecimal;
/**
 *
 * @author admin
 */
public class LotDao {

    public List<Lot> findAll() throws SQLException {
        String sql = "SELECT id_lote, numero_lote, id_producto, id_proveedor, fecha_ingreso, "
                   + "fecha_vencimiento, cantidad_inicial, cantidad, precio_compra, precio_venta, "
                   + "pasillo, estante, id_estado FROM lotes_inventario ORDER BY fecha_vencimiento";
        List<Lot> lots = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                lots.add(mapRow(rs));
            }
        }
        return lots;
    }

   // Retorna true si el proveedor vende este producto (el registro existe en productos_proveedor)
    public boolean isInCatalog(int supplierId, int productId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM productos_proveedor WHERE id_proveedor = ? AND id_producto = ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, supplierId);
            statement.setInt(2, productId);
            try (ResultSet rs = statement.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    public void insert(Lot lot) throws SQLException {
        String sql = "INSERT INTO lotes_inventario (numero_lote, id_producto, id_proveedor, fecha_ingreso, "
                   + "fecha_vencimiento, cantidad_inicial, cantidad, precio_compra, precio_venta, "
                   + "pasillo, estante, id_estado) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, lot.getLotNumber());
            statement.setInt(2, lot.getProductId());
            statement.setInt(3, lot.getSupplierId());
            statement.setTimestamp(4, Timestamp.valueOf(lot.getReceivedAt()));
            statement.setDate(5, Date.valueOf(lot.getExpirationDate()));
            statement.setBigDecimal(6, lot.getInitialQuantity());
            statement.setBigDecimal(7, lot.getQuantity());
            statement.setBigDecimal(8, lot.getPurchasePrice());
            statement.setBigDecimal(9, lot.getSalePrice());
            statement.setString(10, lot.getAisle());
            statement.setString(11, lot.getShelf());
            statement.setInt(12, lot.getStatus().getId());
            statement.executeUpdate();
        }
    }

    // Marca los lotes DISPONIBLES que expiran dentro de los proximos 7 días (incluyendo hoy)
    public int markNearExpiry(LocalDate today, LocalDate limit) throws SQLException {
        String sql = "UPDATE lotes_inventario SET id_estado = ? "
                   + "WHERE id_estado = ? AND fecha_vencimiento BETWEEN ? AND ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, LotStatus.NEAR_EXPIRY.getId());
            statement.setInt(2, LotStatus.AVAILABLE.getId());
            statement.setDate(3, Date.valueOf(today));
            statement.setDate(4, Date.valueOf(limit));
            return statement.executeUpdate();
        }
    }
    
    //Venta de productos esto  es para encintrar y solo dejar vender los productos available y near expiry
    // Lotes disponibles para la venta de un producto, ordenados por vencimiento más próximo (FEFO).
    // Los lotes vencidos, en cuarentena y rechazados nunca aparecen aquí.
    public List<Lot> findAvailableByProductFefo(int productId) throws SQLException {
        String sql = "SELECT id_lote, numero_lote, id_producto, id_proveedor, fecha_ingreso, "
                   + "fecha_vencimiento, cantidad_inicial, cantidad, precio_compra, precio_venta, "
                   + "pasillo, estante, id_estado FROM lotes_inventario "
                   + "WHERE id_producto = ? AND id_estado IN (?, ?) AND cantidad > 0 "
                   + "ORDER BY fecha_vencimiento ASC, id_lote ASC";
        List<Lot> lots = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, productId);
            statement.setInt(2, LotStatus.AVAILABLE.getId());
            statement.setInt(3, LotStatus.NEAR_EXPIRY.getId());
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    lots.add(mapRow(rs));
                }
            }
        }
        return lots;
    }

    // Utiliza la conexión de la venta. NO hace commit ni la cierra:
    // la venta guarda o cancela todo en conjunto.
    // Retorna false si el lote no tiene suficiente stock o no se puede vender.
    public boolean decreaseQuantity(int lotId, BigDecimal quantity, Connection connection) throws SQLException {
        if (quantity == null || quantity.signum() <= 0) {
            throw new IllegalArgumentException("La cantidad a descontar debe ser mayor a cero");
        }
        String sql = "UPDATE lotes_inventario SET cantidad = cantidad - ? "
                   + "WHERE id_lote = ? AND cantidad >= ? AND id_estado IN (?, ?)";

        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setBigDecimal(1, quantity);
            statement.setInt(2, lotId);
            statement.setBigDecimal(3, quantity);
            statement.setInt(4, LotStatus.AVAILABLE.getId());
            statement.setInt(5, LotStatus.NEAR_EXPIRY.getId());
            return statement.executeUpdate() > 0;
        }
    }

    // Marca los lotes como Expirados cuando su fecha ya paso.
    // Los lotes en cuarentena no cambian: un inspector decide su destino.
    public int markExpired(LocalDate today) throws SQLException {
        String sql = "UPDATE lotes_inventario SET id_estado = ? "
                   + "WHERE id_estado IN (?, ?) AND fecha_vencimiento < ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, LotStatus.EXPIRED.getId());
            statement.setInt(2, LotStatus.AVAILABLE.getId());
            statement.setInt(3, LotStatus.NEAR_EXPIRY.getId());
            statement.setDate(4, Date.valueOf(today));
            return statement.executeUpdate();
        }
    }
    
    //metodo de inspeccion dependiendo del id
    public Optional<Lot> findById(int lotId) throws SQLException {
        String sql = "SELECT id_lote, numero_lote, id_producto, id_proveedor, fecha_ingreso, "
                   + "fecha_vencimiento, cantidad_inicial, cantidad, precio_compra, precio_venta, "
                   + "pasillo, estante, id_estado FROM lotes_inventario WHERE id_lote = ?";

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, lotId);
            try (ResultSet rs = statement.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
                return Optional.empty();
            }
        }
    }

    private Lot mapRow(ResultSet rs) throws SQLException {
        return new Lot(
                rs.getInt("id_lote"),
                rs.getString("numero_lote"),
                rs.getInt("id_producto"),
                rs.getInt("id_proveedor"),
                rs.getTimestamp("fecha_ingreso").toLocalDateTime(),
                rs.getDate("fecha_vencimiento").toLocalDate(),
                rs.getBigDecimal("cantidad_inicial"),
                rs.getBigDecimal("cantidad"),
                rs.getBigDecimal("precio_compra"),
                rs.getBigDecimal("precio_venta"),
                rs.getString("pasillo"),
                rs.getString("estante"),
                LotStatus.fromId(rs.getInt("id_estado")));
    }
}
