package com.frescuratotal.erp.sales.controller;

import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.sales.dao.VentasDao;
import com.frescuratotal.erp.sales.model.LineaPedido;
import com.frescuratotal.erp.sales.model.Lote;
import com.frescuratotal.erp.sales.model.VentaRegistrada;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

/**
 * Modulo de Ventas: valida el pedido y coordina el DAO. Los problemas del usuario se
 * reportan con IllegalArgumentException y un mensaje legible; lo demas es SQLException.
 */
public class ControladorVentas {

    // El esquema no define una tarifa de IVA. Se deja en 0 hasta que el negocio indique la oficial.
    public static final BigDecimal TASA_IMPUESTO = BigDecimal.ZERO;

    private final VentasDao dao;
    private final CustomerDao clientes;

    public ControladorVentas(VentasDao dao, CustomerDao clientes) {
        this.dao = dao;
        this.clientes = clientes;
    }

    public Customer buscarCliente(int idCliente) throws SQLException {
        return clientes.findById(idCliente)
                .orElseThrow(() -> new IllegalArgumentException("No existe un cliente con id " + idCliente + "."));
    }

    // Ya vienen ordenados por vencimiento (FIFO).
    public List<Lote> listarLotes() throws SQLException {
        return dao.listarLotesVendibles();
    }

    // Revisa la cantidad contra las existencias mostradas, descontando lo ya agregado al pedido.
    public void agregarLinea(List<LineaPedido> pedido, Lote lote, BigDecimal cantidad) {
        if (cantidad.signum() <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor que cero.");
        }
        BigDecimal yaPedido = pedido.stream()
                .filter(l -> l.lote().idLote() == lote.idLote())
                .map(LineaPedido::cantidad)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (yaPedido.add(cantidad).compareTo(lote.cantidad()) > 0) {
            throw new IllegalArgumentException("Solo hay " + lote.cantidad() + " disponibles en el lote "
                    + lote.numeroLote() + ".");
        }
        pedido.add(new LineaPedido(lote, cantidad, TASA_IMPUESTO));
    }

    public List<VentaRegistrada> listarVentasRegistradas() throws SQLException {
        return dao.listarVentasRegistradas();
    }

    // Logistica solo ve ventas En Preparacion; este paso las deja listas para despacho.
    public void pasarAPreparacion(int idVenta) throws SQLException {
        if (!dao.pasarAPreparacion(idVenta)) {
            throw new IllegalArgumentException("La venta " + idVenta + " no existe o no esta en estado Registrada.");
        }
    }

    // Devuelve el id de la venta registrada. El DAO vuelve a verificar las existencias.
    public int confirmarVenta(int idCliente, List<LineaPedido> pedido) throws SQLException {
        if (pedido.isEmpty()) {
            throw new IllegalArgumentException("El pedido no tiene productos.");
        }
        buscarCliente(idCliente);
        return dao.registrarVenta(idCliente, pedido);
    }
}
