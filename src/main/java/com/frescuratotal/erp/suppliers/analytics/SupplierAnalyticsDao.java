package com.frescuratotal.erp.suppliers.analytics;

import com.frescuratotal.erp.common.DatabaseConnection;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class SupplierAnalyticsDao {

    public List<LoteProveedor> obtenerLotesParaReporte() throws SQLException {
        String sql = "SELECT l.id_lote, l.cantidad_inicial, e.nombre AS estado_lote, "
                   + "p.id_proveedor, p.nombre AS nombre_proveedor "
                   + "FROM lotes_inventario l "
                   + "INNER JOIN proveedores p ON l.id_proveedor = p.id_proveedor "
                   + "INNER JOIN estados_lote e ON l.id_estado = e.id_estado";

        List<LoteProveedor> lista = new ArrayList<>();
        Connection connection = DatabaseConnection.getConnection();

        try (PreparedStatement statement = connection.prepareStatement(sql);
             ResultSet rs = statement.executeQuery()) {
            while (rs.next()) {
                LoteProveedor item = new LoteProveedor(
                        rs.getInt("id_lote"),
                        rs.getDouble("cantidad_inicial"),
                        rs.getString("estado_lote"),
                        rs.getInt("id_proveedor"),
                        rs.getString("nombre_proveedor")
                );
                lista.add(item);
            }
        }
        return lista;
    }
}
