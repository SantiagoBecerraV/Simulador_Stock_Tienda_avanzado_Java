package com.frescuratotal.erp;

    /*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 */

import com.frescuratotal.erp.common.DatabaseConnection;
import java.sql.Connection;
import java.sql.SQLException;

/**
 *
 * @author admin
 */


public class Main {

    public static void main(String[] args) {
        try {
            Connection conn = DatabaseConnection.getConnection();
            System.out.println("Conexión exitosa");
        } catch (SQLException e) {
            System.out.println("Error: " + e.getMessage());
        }
    }
}
