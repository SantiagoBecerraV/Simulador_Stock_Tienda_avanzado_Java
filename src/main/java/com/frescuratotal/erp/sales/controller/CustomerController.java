package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Valida los datos y coordina el DAO. Los problemas del usuario se reportan
 * como IllegalArgumentException con un mensaje legible; lo demás es SQLException.
 */
public class CustomerController {

    private static final int MYSQL_DUPLICATE_ENTRY = 1062;

    private final CustomerDao dao;

    public CustomerController(CustomerDao dao) {
        this.dao = dao;
    }

    public List<Customer> list() throws SQLException {
        return dao.findAll();
    }

    public Customer get(int customerId) throws SQLException {
        return dao.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("No customer with id " + customerId + "."));
    }

    public Map<Integer, String> types() throws SQLException {
        return dao.findTypes();
    }

    public void create(Customer c) throws SQLException {
        validate(c);
        try {
            dao.insert(clean(c));
        } catch (SQLException e) {
            throw translate(e, c.document());
        }
    }

    public void update(Customer c) throws SQLException {
        validate(c);
        try {
            if (!dao.update(clean(c))) {
                throw new IllegalArgumentException("No customer with id " + c.customerId() + ".");
            }
        } catch (SQLException e) {
            throw translate(e, c.document());
        }
    }

    public void delete(int customerId) throws SQLException {
        if (dao.hasSales(customerId)) {
            throw new IllegalArgumentException("Cannot delete: this customer has related sales.");
        }
        if (!dao.delete(customerId)) {
            throw new IllegalArgumentException("No customer with id " + customerId + ".");
        }
    }

    private void validate(Customer c) throws SQLException {
        if (isBlank(c.name())) {
            throw new IllegalArgumentException("Name is required.");
        }
        if (isBlank(c.document())) {
            throw new IllegalArgumentException("Document is required.");
        }
        if (!dao.findTypes().containsKey(c.typeId())) {
            throw new IllegalArgumentException("Invalid customer type.");
        }
    }

    // Quita espacios y guarda como NULL los campos opcionales vacíos.
    private Customer clean(Customer c) {
        return new Customer(c.customerId(), c.name().trim(), c.document().trim(),
                blankToNull(c.email()), blankToNull(c.phone()), blankToNull(c.address()),
                c.typeId(), null, null);
    }

    private SQLException translate(SQLException e, String document) {
        if (e.getErrorCode() == MYSQL_DUPLICATE_ENTRY) {
            throw new IllegalArgumentException("A customer with document '" + document + "' already exists.");
        }
        return e;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static String blankToNull(String s) {
        return isBlank(s) ? null : s.trim();
    }
}
