package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.common.CustomerCache;
import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
// Punto 4: dependencias para leer y validar clientes desde archivo.
import java.io.FileNotFoundException;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/**
 * Valida los datos y coordina el DAO. Los problemas del usuario se reportan
 * como IllegalArgumentException con un mensaje legible; lo demas es SQLException.
 */
public class CustomerController {

    private static final int MYSQL_DUPLICATE_ENTRY = 1062;
    // Punto 4: cabecera obligatoria del archivo de importación.
    private static final String IMPORT_HEADER = "nombre;documento;correo;telefono;tipo_cliente";
    // Punto 4: valida el formato básico del correo.
    private static final Pattern EMAIL_PATTERN = Pattern.compile("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$");

    private final CustomerDao dao;
    //punto1
    private final CustomerCache cache;

    public CustomerController(CustomerDao dao) {
        this.dao = dao;
        //punto1
        this.cache = CustomerCache.getInstance();
    }

    public List<Customer> list() throws SQLException {
        return dao.findAll();
    }

    //PUNTO 1 taller
    // Devuelve la caché o consulta MySQL una sola vez.
    public Customer get(int customerId) throws SQLException {
        Customer cachedCustomer = cache.get(customerId);
        if (cachedCustomer != null) {
            return cachedCustomer;
        }

        Customer customer = dao.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("No existe un cliente con id " + customerId + "."));
        cache.put(customer);
        return customer;
    }

    public Map<Integer, String> types() throws SQLException {
        return dao.findTypes();
    }

    public void create(Customer c) throws SQLException {
        validate(c);
        try {
            dao.insert(clean(c));
        } catch (SQLException e) {
            if (isDuplicate(e)) {
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
            //Punto 1
            cache.remove(c.customerId()); // La próxima búsqueda carga datos actualizados.
        } catch (SQLException e) {
            if (isDuplicate(e)) {
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
        //punto 1
        cache.remove(customerId); // Un cliente eliminado no queda en caché.
    }

    // Punto 4: valida el archivo completo antes de guardar clientes.
    public int importCustomersFromFile(Path file) throws IOException, SQLException {
        if (!Files.isRegularFile(file)) {
            throw new FileNotFoundException("No se encontró el archivo clientes_importar.txt.");
        }

        List<Customer> customers = readImportFile(file);
        for (Customer customer : customers) {
            if (dao.documentExists(customer.document())) {
                throw invalidImport();
            }
        }

        try {
            dao.insertAll(customers);
            return customers.size();
        } catch (SQLException e) {
            if (isDuplicate(e)) {
                throw invalidImport();
            }
            throw e;
        }
    }

    // Punto 4: lee las filas y crea clientes válidos en memoria.
    private List<Customer> readImportFile(Path file) throws IOException, SQLException {
        List<String> lines = Files.readAllLines(file, StandardCharsets.UTF_8);
        if (lines.isEmpty() || !IMPORT_HEADER.equals(lines.get(0))) {
            throw invalidImport();
        }

        Map<Integer, String> types = dao.findTypes();
        List<Customer> customers = new ArrayList<>();
        Set<String> documents = new HashSet<>();
        for (int index = 1; index < lines.size(); index++) {
            String line = lines.get(index).trim();
            if (line.isEmpty()) {
                continue;
            }
            Customer customer = parseImportLine(line, types);
            if (!documents.add(customer.document())) {
                throw invalidImport();
            }
            customers.add(customer);
        }
        return customers;
    }

    // Punto 4: convierte una fila de texto en un cliente.
    private Customer parseImportLine(String line, Map<Integer, String> types) {
        String[] fields = line.split(";", -1);
        if (fields.length != 5) {
            throw invalidImport();
        }

        String name = fields[0].trim();
        String document = fields[1].trim();
        String email = fields[2].trim();
        String phone = fields[3].trim();
        String typeName = fields[4].trim().toUpperCase(Locale.ROOT);
        if (isBlank(name) || isBlank(document) || isBlank(email) || isBlank(phone)
                || !EMAIL_PATTERN.matcher(email).matches()) {
            throw invalidImport();
        }

        int typeId = findTypeId(typeName, types);
        return new Customer(0, name, document, email, phone, null, typeId, null, null);
    }

    // Punto 4: busca el ID de MAYORISTA o MINORISTA.
    private int findTypeId(String typeName, Map<Integer, String> types) {
        if (!typeName.equals("MAYORISTA") && !typeName.equals("MINORISTA")) {
            throw invalidImport();
        }
        return types.entrySet().stream()
                .filter(entry -> entry.getValue().equalsIgnoreCase(typeName))
                .map(Map.Entry::getKey)
                .findFirst()
                .orElseThrow(this::invalidImport);
    }

    // Punto 4: crea el mensaje único para datos inválidos.
    private IllegalArgumentException invalidImport() {
        return new IllegalArgumentException("Se encontraron registros inválidos. Importación cancelada.");
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
    private static boolean isDuplicate(SQLException e) {
        return e.getErrorCode() == MYSQL_DUPLICATE_ENTRY;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private static String blankToNull(String s) {
        return isBlank(s) ? null : s.trim();
    }
}
