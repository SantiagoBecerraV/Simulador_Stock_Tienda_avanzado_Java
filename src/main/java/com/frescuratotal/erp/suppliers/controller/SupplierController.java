package com.frescuratotal.erp.suppliers.controller;

import com.frescuratotal.erp.suppliers.model.DailyPurchase;
import com.frescuratotal.erp.suppliers.model.DailyPurchaseReport;
import com.frescuratotal.erp.suppliers.model.Supplier;
import com.frescuratotal.erp.suppliers.model.SupplierDao;
//punto 2
import java.io.BufferedWriter;
import java.io.IOException;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
//
import java.sql.SQLException;
//punto 2
import java.time.LocalDate;
import java.util.List;

public class SupplierController {

    private final SupplierDao dao = new SupplierDao();

    public List<Supplier> listSuppliers() throws SQLException {
        return dao.findAll();
    }

    public void addSupplier(Supplier supplier) throws SQLException {
        validate(supplier);
        dao.insert(supplier);
    }

    public boolean updateSupplier(Supplier supplier) throws SQLException {
        validate(supplier);
        return dao.update(supplier);
    }

    public boolean deactivateSupplier(int id) throws SQLException {
        return dao.deactivate(id);
    }
    
    public List<String> listCatalog(int supplierId) throws SQLException {
        return dao.findCatalog(supplierId);
    }

    public List<String> listProductOptions() throws SQLException {
        return dao.findProductOptions();
    }

    public void addToCatalog(int supplierId, int productId) throws SQLException {
        if (supplierId <= 0 || productId <= 0) {
            throw new IllegalArgumentException("Los ID deben ser numeros positivos");
        }
        dao.addProductToCatalog(supplierId, productId);
    }

    public boolean removeFromCatalog(int supplierId, int productId) throws SQLException {
        return dao.removeProductFromCatalog(supplierId, productId);
    }
    
    //punto 2
    // Genera el CSV con las compras registradas hoy.
    public DailyPurchaseReport generateDailyPurchaseReport() throws SQLException, IOException {
        LocalDate today = LocalDate.now();
        List<DailyPurchase> purchases = dao.findPurchasesByDate(today);
        Path file = Path.of("compras_" + today + ".csv");

        try (BufferedWriter writer = Files.newBufferedWriter(file, StandardCharsets.UTF_8)) {
            writer.write("NumeroCompra;NombreProveedor;MontoTotal");
            writer.newLine();
            for (DailyPurchase purchase : purchases) {
                writer.write(formatPurchase(purchase));
                writer.newLine();
            }
        }
        return new DailyPurchaseReport(file, purchases.size());
    }

    // Ordena los tres campos requeridos por el CSV.
    private String formatPurchase(DailyPurchase purchase) {
        String amount = purchase.totalAmount().setScale(2, RoundingMode.HALF_UP)
                .toPlainString();
        return escapeCsv(purchase.purchaseNumber()) + ";"
                + escapeCsv(purchase.supplierName()) + ";" + amount;
    }

    // Protege el archivo si un nombre contiene punto y coma o comillas.
    private String escapeCsv(String value) {
        if (value == null) {
            return "";
        }
        if (value.contains(";") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }
    
    ///////
    // El nombre, NIT y correo electrónico son obligatorios en la base de datos
    private void validate(Supplier supplier) {
        if (isBlank(supplier.getName()) || isBlank(supplier.getNit()) || isBlank(supplier.getEmail())) {
            throw new IllegalArgumentException("El nombre, el NIT y el correo electronico son obligatorios !!");
        }
    }

    private boolean isBlank(String text) {
        return text == null || text.isBlank();
    }
}
