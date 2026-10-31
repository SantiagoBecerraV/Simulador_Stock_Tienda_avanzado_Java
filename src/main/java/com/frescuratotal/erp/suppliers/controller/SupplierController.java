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
    
    //METODOS PROVEEDOR - PRODUCTO
    public List<String> listCatalog(int supplierId) throws SQLException {
        return dao.findCatalog(supplierId);
    }

    public List<String> listProductOptions() throws SQLException {
        return dao.findProductOptions();
    }

    public void addToCatalog(int supplierId, int productId) throws SQLException {
        if (supplierId <= 0 || productId <= 0) {
            throw new IllegalArgumentException("IDs must be positive numbers");
        }
        dao.addProductToCatalog(supplierId, productId);
    }

    public boolean removeFromCatalog(int supplierId, int productId) throws SQLException {
        return dao.removeProductFromCatalog(supplierId, productId);
    }
    //TERMINA PROOVEEDOR PRODUCTO
    
    // El nombre, NIT y correo electrónico son obligatorios en la base de datos
    private void validate(Supplier supplier) {
        if (isBlank(supplier.getName()) || isBlank(supplier.getNit()) || isBlank(supplier.getEmail())) {
            throw new IllegalArgumentException("Name, NIT and email are required");
        }
    }

    private boolean isBlank(String text) {
        return text == null || text.isBlank();
    }
}
