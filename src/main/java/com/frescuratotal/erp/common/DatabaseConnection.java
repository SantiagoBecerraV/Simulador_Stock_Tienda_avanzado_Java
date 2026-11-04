/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.common;

/**
 *
 * @author admin
 */
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {

    private static final String URL = "jdbc:mysql://localhost:3308/erp_frescura_total";
    private static final String USER = "root";
    private static final String PASSWORD = "Campus2026";

    private static Connection connection;

    private DatabaseConnection() {
    }

    public static synchronized Connection getConnection() throws SQLException {
        if (connection == null || connection.isClosed()) {
            connection = DriverManager.getConnection(URL, USER, PASSWORD);
        }
        return connection;
    }

    public static synchronized void close() throws SQLException {
        if (connection != null) {
            try {
                connection.close();
            } finally {
                connection = null;
            }
        }
    }
}