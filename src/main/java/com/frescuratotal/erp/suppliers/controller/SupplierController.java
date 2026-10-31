/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.suppliers.controller;

import com.frescuratotal.erp.suppliers.model.Supplier;
import com.frescuratotal.erp.suppliers.model.SupplierDao;
import java.sql.SQLException;
import java.util.List;

/**
 *
 * @author admin
 */
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

    // Name, NIT and email are required in the database
    private void validate(Supplier supplier) {
        if (isBlank(supplier.getName()) || isBlank(supplier.getNit()) || isBlank(supplier.getEmail())) {
            throw new IllegalArgumentException("Name, NIT and email are required");
        }
    }

    private boolean isBlank(String text) {
        return text == null || text.isBlank();
    }
}
