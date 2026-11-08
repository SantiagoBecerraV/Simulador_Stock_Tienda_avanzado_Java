package com.frescuratotal.erp.common;

import com.frescuratotal.erp.sales.model.Customer;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

//Punto 1
/**
 * Stores customers that were already read from the database during the current
 * application execution. The cache is shared by the customer and sales modules.
 */
public final class CustomerCache {

    private static final CustomerCache INSTANCE = new CustomerCache();

    private final Map<Integer, Customer> customersById = new ConcurrentHashMap<>();

    private CustomerCache() {
    }

    // Devuelve la única caché compartida.
    public static CustomerCache getInstance() {
        return INSTANCE;
    }

    // Busca un cliente guardado en memoria.
    public Customer get(int customerId) {
        return customersById.get(customerId);
    }

    // Guarda un cliente válido para próximas búsquedas.
    public void put(Customer customer) {
        if (customer != null && customer.customerId() > 0) {
            customersById.put(customer.customerId(), customer);
        }
    }

    // Elimina datos desactualizados de memoria.
    public void remove(int customerId) {
        customersById.remove(customerId);
    }
}
