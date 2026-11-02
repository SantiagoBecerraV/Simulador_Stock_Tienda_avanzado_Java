package com.frescuratotal.erp.suppliers.model;

public class Supplier {

    private int id;
    private String name;
    private String nit;
    private String contactPerson;
    private String email;
    private String phone;
    private String address;
    private boolean active;

    public Supplier(int id, String name, String nit, String contactPerson,
                    String email, String phone, String address, boolean active) {
        this.id = id;
        this.name = name;
        this.nit = nit;
        this.contactPerson = contactPerson;
        this.email = email;
        this.phone = phone;
        this.address = address;
        this.active = active;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public String getNit() { return nit; }
    public String getContactPerson() { return contactPerson; }
    public String getEmail() { return email; }
    public String getPhone() { return phone; }
    public String getAddress() { return address; }
    public boolean isActive() { return active; }

    @Override
    public String toString() {
        return id + " | " + name + " | NIT " + nit + " | " + email
                + " | " + (active ? "Activo" : "Inactivo");
    }
}
