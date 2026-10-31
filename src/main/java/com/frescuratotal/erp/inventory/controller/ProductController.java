/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.controller;

import com.frescuratotal.erp.inventory.model.Product;
import com.frescuratotal.erp.inventory.model.ProductDao;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
/**
 *
 * @author admin
 */
public class ProductController {

    private final ProductDao dao = new ProductDao();
    private static final List<String> VALID_UNITS = List.of("kg", "litro", "unidad");

    public List<Product> listProducts() throws SQLException {
        return dao.findAll();
    }

    public List<String> listCategories() throws SQLException {
        return dao.findCategories();
    }

    public void addProduct(Product product) throws SQLException {
        validate(product);
        dao.insert(product);
    }

    public boolean updateProduct(Product product) throws SQLException {
        validate(product);
        return dao.update(product);
    }

    public boolean deleteProduct(int id) throws SQLException {
        return dao.delete(id);
    }

    private void validate(Product product) {
        if (isBlank(product.getName()) || isBlank(product.getUnit())) {
            throw new IllegalArgumentException("Name and unit are required");
        }
        if (!VALID_UNITS.contains(product.getUnit().toLowerCase())) {
            throw new IllegalArgumentException("Unit must be kg, litro or unidad");
        }
        if (product.getCategoryId() <= 0) {
            throw new IllegalArgumentException("Category must be a positive number");
        }
        if (product.getBasePrice() == null || product.getBasePrice().compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Price must be zero or more");
        }
    }

    private boolean isBlank(String text) {
        return text == null || text.isBlank();
    }
}