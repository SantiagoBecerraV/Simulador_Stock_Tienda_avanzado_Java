package com.frescuratotal.erp.customers.model;

import java.sql.Timestamp;

// typeName y registrationDate son de solo lectura: vienen de la base de datos.
public record Customer(
        int customerId,
        String name,
        String document,
        String email,
        String phone,
        String address,
        int typeId,
        String typeName,
        Timestamp registrationDate) {
}
