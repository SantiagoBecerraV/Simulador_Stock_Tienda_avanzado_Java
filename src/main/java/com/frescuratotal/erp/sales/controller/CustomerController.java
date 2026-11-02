package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import java.sql.SQLException;
import java.util.List;
import java.util.Map;

/**
 * Valida los datos y coordina el DAO. Los problemas del usuario se reportan
 * como IllegalArgumentException con un mensaje legible; lo demas es SQLException.
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
                .orElseThrow(() -> new IllegalArgumentException("No existe un cliente con id " + customerId + "."));
    }

    public Map<Integer, String> types() throws SQLException {
        return dao.findTypes();
    }

    public void create(Customer c) throws SQLException {
        validate(c);
        try {
            dao.insert(clean(c));
        } catch (SQLException e) {
            if (esDuplicado(e)) {
                throw new IllegalArgumentException("Ya existe un cliente con el documento '" + c.document() + "'.");
            }
            throw e;
        }
    }

    public void update(Customer c) throws SQLException {
        validate(c);
        try {
            if (!dao.update(clean(c))) {
                throw new IllegalArgumentException("No existe un cliente con id " + c.customerId() + ".");
            }
        } catch (SQLException e) {
            if (esDuplicado(e)) {
                throw new IllegalArgumentException("Ya existe un cliente con el documento '" + c.document() + "'.");
            }
            throw e;
        }
    }

    public void delete(int customerId) throws SQLException {
        if (dao.hasSales(customerId)) {
            throw new IllegalArgumentException("No se puede eliminar: el cliente tiene ventas.");
        }
        if (!dao.delete(customerId)) {
            throw new IllegalArgumentException("No existe un cliente con id " + customerId + ".");
        }
    }

    private void validate(Customer c) throws SQLException {
        if (isBlank(c.name())) {
            throw new IllegalArgumentException("El nombre es obligatorio.");
        }
        if (isBlank(c.document())) {
            throw new IllegalArgumentException("El documento es obligatorio.");
        }
        if (!dao.findTypes().containsKey(c.typeId())) {
            throw new IllegalArgumentException("Tipo de cliente no valido.");
        }
    }

    // Quita espacios y guarda como NULL los campos opcionales vacios.
    private Customer clean(Customer c) {
        return new Customer(c.customerId(), c.name().trim(), c.document().trim(),
                blankToNull(c.email()), blankToNull(c.phone()), blankToNull(c.address()),
                c.typeId(), null, null);
    }

    // true si MySQL rechazo el dato por repetir un valor unico (el documento).
    private static boolean esDuplicado(SQLException e) {
        return e.getErrorCode() == MYSQL_DUPLICATE_ENTRY;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static String blankToNull(String s) {
        return isBlank(s) ? null : s.trim();
    }
}
