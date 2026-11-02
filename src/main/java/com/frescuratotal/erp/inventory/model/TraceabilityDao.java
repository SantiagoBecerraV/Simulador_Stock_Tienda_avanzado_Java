    /*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.model;

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
public class TraceabilityDao {
    //Clase de Consultas de trazabilidad
    // Todos los lotes entregados por un proveedor, incluidos los rechazados (el historial nunca se elimina)
    public List<String> findLotsBySupplier(int supplierId) throws SQLException {
        String sql = "SELECT l.numero_lote, p.nombre, l.cantidad, l.fecha_vencimiento, l.id_estado "
                   + "FROM lotes_inventario l JOIN productos p ON p.id_producto = l.id_producto "
                   + "WHERE l.id_proveedor = ? ORDER BY l.fecha_vencimiento";
        List<String> lines = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, supplierId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    lines.add(rs.getString("numero_lote") + " | " + rs.getString("nombre")
                            + " | cantidad " + rs.getBigDecimal("cantidad")
                            + " | expira " + rs.getDate("fecha_vencimiento")
                            + " | " + LotStatus.fromId(rs.getInt("id_estado")));
                }
            }
        }
        return lines;
    }

    // Stock disponible para la venta inmediata: solo lotes Disponibles o Próximos a Vencer con existencias
    public List<String> findSellableStockByProduct() throws SQLException {
        String sql = "SELECT p.nombre, SUM(l.cantidad) AS total "
                   + "FROM lotes_inventario l JOIN productos p ON p.id_producto = l.id_producto "
                   + "WHERE l.id_estado IN (?, ?) AND l.cantidad > 0 "
                   + "GROUP BY p.id_producto, p.nombre ORDER BY p.nombre";
        List<String> lines = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, LotStatus.AVAILABLE.getId());
            statement.setInt(2, LotStatus.NEAR_EXPIRY.getId());
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    lines.add(rs.getString("nombre") + " | total " + rs.getBigDecimal("total"));
                }
            }
        }
        return lines;
    }

    // Todo lo ocurrido con un lote, en orden cronológico: cuarentena, inspecciones y merma
    public List<String> findLotHistory(int lotId) throws SQLException {
        String sql = "SELECT CONCAT('Quarantine: ', motivo, ' por ', usuario, ' rl ', fecha_registro) AS event, "
                   + "fecha_registro AS moment FROM registro_cuarentena WHERE id_lote = ? "
                   + "UNION ALL "
                   + "SELECT CONCAT('Inspection: ', resultado, ' por ', nombre_inspector, ' el ', fecha_inspeccion), "
                   + "fecha_inspeccion FROM inspecciones_calidad WHERE id_lote = ? "
                   + "UNION ALL "
                   + "SELECT CONCAT('Waste: ', cantidad_perdida, ' units, ', motivo, ' por ', usuario_registro, "
                   + "' el ', fecha_registro), fecha_registro FROM registro_mermas WHERE id_lote = ? "
                   + "ORDER BY moment";
        List<String> lines = new ArrayList<>();

        Connection connection = DatabaseConnection.getConnection();
        try (PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setInt(1, lotId);
            statement.setInt(2, lotId);
            statement.setInt(3, lotId);
            try (ResultSet rs = statement.executeQuery()) {
                while (rs.next()) {
                    lines.add(rs.getString("event"));
                }
            }
        }
        return lines;
    }
}
