package com.frescuratotal.erp.common;

import com.frescuratotal.erp.sales.model.Customer;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

//Punto 1
/**
 * Almacena los clientes que ya fueron leídos de la base de datos durante la
 * ejecución actual de la aplicación. La caché se comparte entre los módulos de clientes y ventas.
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
