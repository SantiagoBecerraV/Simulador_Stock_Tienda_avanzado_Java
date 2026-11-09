package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.common.CustomerCache;
import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.sales.model.CommercialSaleDetail;
import com.frescuratotal.erp.sales.model.CommercialStatistics;
import com.frescuratotal.erp.sales.model.DeliveryMode;
import com.frescuratotal.erp.sales.dao.SalesDao;
import com.frescuratotal.erp.sales.model.OrderLine;
import com.frescuratotal.erp.sales.model.SalesLot;
import com.frescuratotal.erp.sales.model.RegisteredSale;
import com.frescuratotal.erp.sales.strategy.DeliveryFeeService;
import com.frescuratotal.erp.sales.service.CommercialStatisticsService;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * Modulo de Ventas: valida el pedido y coordina el DAO. Los problemas del usuario se
 * reportan con IllegalArgumentException y un mensaje legible; lo demas es SQLException.
 */
public class SalesController {

    // Ni el esquema ni el enunciado definen una tarifa de IVA, asi que NO es un dato oficial.
    // Valor de demostracion: 0 por defecto; para probar otro, ejecutar con -Derp.tasaImpuesto=0.10
    // (fraccion entre 0 y 1). La tarifa real debe confirmarse con el negocio antes de usarla.
    public static final BigDecimal TAX_RATE = readTaxRate();

    private static BigDecimal readTaxRate() {
        String text = System.getProperty("erp.tasaImpuesto", "0");
        try {
            BigDecimal rate = new BigDecimal(text);
            if (rate.signum() >= 0 && rate.compareTo(BigDecimal.ONE) <= 0) {
                return rate;
            }
        } catch (NumberFormatException e) {
            // Se informa abajo y se usa 0.
        }
        System.out.println("Tasa de impuesto invalida (" + text + "): se usa 0. Debe estar entre 0 y 1, por ejemplo 0.10.");
        return BigDecimal.ZERO;
    }

    private final SalesDao dao;
    private final CustomerDao customers;
    private final CustomerCache customerCache;
    // Punto 3: calcula el total según la modalidad de entrega.
    private final DeliveryFeeService deliveryFeeService;
    // Punto 5: genera el resumen comercial con Stream API.
    private final CommercialStatisticsService commercialStatisticsService;

    public SalesController(SalesDao dao, CustomerDao customers) {
        this.dao = dao;
        this.customers = customers;
        this.customerCache = CustomerCache.getInstance();
        // Punto 3: prepara el cálculo de la tarifa de entrega.
        this.deliveryFeeService = new DeliveryFeeService();
        // Punto 5: prepara las estadísticas comerciales.
        this.commercialStatisticsService = new CommercialStatisticsService();
    }
    //tiene cambios del punto 1
    // Usa la misma caché del módulo de clientes.
    public Customer findCustomer(int customerId) throws SQLException {
        Customer cachedCustomer = customerCache.get(customerId);
        if (cachedCustomer != null) {
            return cachedCustomer;
        }

        Customer customer = customers.findById(customerId)
                .orElseThrow(() -> new IllegalArgumentException("No existe un cliente con id " + customerId + "."));
        customerCache.put(customer);
        return customer;
    }

    // Ya vienen ordenados por vencimiento (FEFO).
    public List<SalesLot> listLots() throws SQLException {
        return dao.listSellableLots();
    }

    // Revisa la cantidad contra las existencias mostradas, descontando lo ya agregado al pedido.
    public void addOrderLine(List<OrderLine> orderLines, SalesLot lot, BigDecimal quantity) {
        if (quantity.signum() <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor que cero.");
        }
        BigDecimal quantityAlreadyInOrder = orderLines.stream()
                .filter(l -> l.lot().lotId() == lot.lotId())
                .map(OrderLine::quantity)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (quantityAlreadyInOrder.add(quantity).compareTo(lot.quantity()) > 0) {
            throw new IllegalArgumentException("Solo hay " + lot.quantity() + " disponibles en el lote "
                    + lot.lotNumber() + ".");
        }
        orderLines.add(new OrderLine(lot, quantity, TAX_RATE));
    }

    public List<RegisteredSale> listRegisteredSales() throws SQLException {
        return dao.listRegisteredSales();
    }

    // Punto 5: obtiene los datos reales y prepara las estadísticas.
    // Para otra estadística: cambiar solo el método DAO y el servicio que procesa su lista.
    public CommercialStatistics generateCommercialStatistics() throws SQLException {
        List<CommercialSaleDetail> details = dao.listCommercialSaleDetails();
        return commercialStatisticsService.generate(details);
    }

    // Logistica solo ve ventas En Preparacion; este paso las deja listas para despacho.
    public void moveSaleToPreparation(int saleId) throws SQLException {
        if (!dao.moveSaleToPreparation(saleId)) {
            throw new IllegalArgumentException("La venta " + saleId + " no existe o no esta en estado Registrada.");
        }
    }

    // Punto 3: calcula el total final antes de registrar la venta.
    public BigDecimal calculateFinalAmount(List<OrderLine> orderLines, DeliveryMode deliveryMode) {
        BigDecimal originalAmount = orderLines.stream()
                .map(OrderLine::lineTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return deliveryFeeService.calculateFinalAmount(originalAmount, deliveryMode);
    }

    // Punto 3: guarda la venta con el total y el recargo de entrega.
    public int confirmSale(int customerId, List<OrderLine> orderLines, DeliveryMode deliveryMode) throws SQLException {
        if (orderLines.isEmpty()) {
            throw new IllegalArgumentException("El pedido no tiene productos.");
        }
        findCustomer(customerId);
        BigDecimal originalAmount = orderLines.stream()
                .map(OrderLine::lineTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal finalAmount = deliveryFeeService.calculateFinalAmount(originalAmount, deliveryMode);
        BigDecimal deliveryCost = finalAmount.subtract(originalAmount);
        // Punto 3: envía el recargo y el total final al DAO.
        int saleId = dao.registerSale(customerId, orderLines, deliveryCost, finalAmount);
        if (saleId == 0) {
            throw new IllegalArgumentException("Las existencias cambiaron durante la venta. Revisa los lotes e intenta de nuevo.");
        }
        return saleId;
    }
}
