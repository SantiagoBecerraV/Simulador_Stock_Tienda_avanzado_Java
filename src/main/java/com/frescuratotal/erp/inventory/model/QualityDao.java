/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.model;

import com.frescuratotal.erp.common.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.Statement;
/**
 *
 * @author admin
 */
public class QualityDao {

    // Cambia el estado del lote y registra el historial en una sola transacción:
    // o se guardan ambos, o no se guarda ninguno
    public void quarantine(int lotId, String reason, String user) throws SQLException {
        Connection connection = DatabaseConnection.getConnection();
        connection.setAutoCommit(false);
        try {
            //La condición id_estado IN (?, ?) es la regla del negocio dentro del SQL: 
            //solo se pueden poner en cuarentena lotes AVAILABLE o NEAR_EXPIRY. Un lote vencido no entra a cuarentena
            String updateSql = "UPDATE lotes_inventario SET id_estado = ? "
                             + "WHERE id_lote = ? AND id_estado IN (?, ?)";
            int changedRows;
            try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                statement.setInt(1, LotStatus.IN_QUARANTINE.getId());
                statement.setInt(2, lotId);
                statement.setInt(3, LotStatus.AVAILABLE.getId());
                statement.setInt(4, LotStatus.NEAR_EXPIRY.getId());
                changedRows = statement.executeUpdate();
            }
            if (changedRows == 0) {
                throw new IllegalArgumentException("Lot not found, or its status does not allow quarantine");
            }

            String insertSql = "INSERT INTO registro_cuarentena (id_lote, motivo, usuario) VALUES (?, ?, ?)";
            try (PreparedStatement statement = connection.prepareStatement(insertSql)) {
                statement.setInt(1, lotId);
                statement.setString(2, reason);
                statement.setString(3, user);
                statement.executeUpdate();
            }

            connection.commit();
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(true);
        }
    }
    
    //metodos de inspeccion
    // Aprueba o rechaza un lote en cuarentena. Todo se guarda en una sola transacción.
    public void inspect(Lot lot, boolean approved, String inspector, String notes,
                        LotStatus nextStatus) throws SQLException {
        Connection connection = DatabaseConnection.getConnection();
        connection.setAutoCommit(false);
        try {
            // Un lote rechazado pierde toda su cantidad: se convierte en desperdicio
            BigDecimal remaining = approved ? lot.getQuantity() : BigDecimal.ZERO;

            String updateLotSql = "UPDATE lotes_inventario SET id_estado = ?, cantidad = ? "
                                + "WHERE id_lote = ? AND id_estado = ?";
            int changedRows;
            try (PreparedStatement statement = connection.prepareStatement(updateLotSql)) {
                statement.setInt(1, nextStatus.getId());
                statement.setBigDecimal(2, remaining);
                statement.setInt(3, lot.getId());
                statement.setInt(4, LotStatus.IN_QUARANTINE.getId());
                changedRows = statement.executeUpdate();
            }
            if (changedRows == 0) {
                throw new IllegalArgumentException("El lote ya no esta en cuarentena");
            }

            String insertInspectionSql = "INSERT INTO inspecciones_calidad "
                                       + "(id_lote, resultado, nombre_inspector, motivo_rechazo, notas) "
                                       + "VALUES (?, ?, ?, ?, ?)";
            int inspectionId;
            try (PreparedStatement statement = connection.prepareStatement(
                    insertInspectionSql, Statement.RETURN_GENERATED_KEYS)) {
                statement.setInt(1, lot.getId());
                statement.setString(2, approved ? "Aprobado" : "Rechazado");
                statement.setString(3, inspector);
                statement.setString(4, approved ? null : notes);
                statement.setString(5, approved ? notes : null);
                statement.executeUpdate();
                try (ResultSet keys = statement.getGeneratedKeys()) {
                    keys.next();
                    inspectionId = keys.getInt(1);
                }
            }

            String closeQuarantineSql = "UPDATE registro_cuarentena SET resuelta = TRUE, "
                                      + "fecha_resolucion = NOW(), notas_resolucion = ? "
                                      + "WHERE id_lote = ? AND resuelta = FALSE";
            try (PreparedStatement statement = connection.prepareStatement(closeQuarantineSql)) {
                statement.setString(1, (approved ? "Aprobado" : "Rechazado") + " por " + inspector);
                statement.setInt(2, lot.getId());
                statement.executeUpdate();
            }

            if (!approved) {
                String wasteSql = "INSERT INTO registro_mermas "
                                + "(id_lote, id_inspeccion, cantidad_perdida, motivo, usuario_registro) "
                                + "VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement statement = connection.prepareStatement(wasteSql)) {
                    statement.setInt(1, lot.getId());
                    statement.setInt(2, inspectionId);
                    statement.setBigDecimal(3, lot.getQuantity());
                    statement.setString(4, notes);
                    statement.setString(5, inspector);
                    statement.executeUpdate();
                }
            }

            connection.commit();
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(true);
        }
    }
    
    //Metodos de registros de perdida
    // Descuenta cantidad de un lote como merma. El stock nunca puede ser menor a cero.
    public void registerWaste(int lotId, BigDecimal quantity, String reason, String user) throws SQLException {
        Connection connection = DatabaseConnection.getConnection();
        connection.setAutoCommit(false);
        try {
            String updateSql = "UPDATE lotes_inventario SET cantidad = cantidad - ? "
                             + "WHERE id_lote = ? AND cantidad >= ? AND id_estado <> ?";
            //La condicion cantidad >= ? es la que evita el stock negativo
            //si pides mas de lo que hay, la consulta no cambia nada y el programa muestra el error.
            int changedRows;
            try (PreparedStatement statement = connection.prepareStatement(updateSql)) {
                statement.setBigDecimal(1, quantity);
                statement.setInt(2, lotId);
                statement.setBigDecimal(3, quantity);
                statement.setInt(4, LotStatus.IN_QUARANTINE.getId());
                changedRows = statement.executeUpdate();
            }
            if (changedRows == 0) {
                throw new IllegalArgumentException("Stock insuficiente, el lote no existe o se encuentra en cuarentena");
            }

            String insertSql = "INSERT INTO registro_mermas (id_lote, cantidad_perdida, motivo, usuario_registro) "
                             + "VALUES (?, ?, ?, ?)";
            try (PreparedStatement statement = connection.prepareStatement(insertSql)) {
                statement.setInt(1, lotId);
                statement.setBigDecimal(2, quantity);
                statement.setString(3, reason);
                statement.setString(4, user);
                statement.executeUpdate();
            }

            connection.commit();
        } catch (SQLException | RuntimeException e) {
            connection.rollback();
            throw e;
        } finally {
            connection.setAutoCommit(true);
        }
    }
}
