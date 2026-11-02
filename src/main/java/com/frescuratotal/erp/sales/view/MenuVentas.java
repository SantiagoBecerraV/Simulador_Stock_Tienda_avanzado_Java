package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.sales.controller.ControladorFacturacion;
import com.frescuratotal.erp.sales.controller.ControladorVentas;
import com.frescuratotal.erp.sales.dao.FacturaDao;
import com.frescuratotal.erp.sales.dao.VentasDao;
import com.frescuratotal.erp.sales.model.LineaPedido;
import com.frescuratotal.erp.sales.model.Lote;
import com.frescuratotal.erp.sales.model.VentaRegistrada;
import java.io.IOException;
import java.math.BigDecimal;
import java.nio.file.Path;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 * Menu de consola del modulo de Ventas. Punto de entrada para el menu principal:
 * new MenuVentas(scanner, DatabaseConnection.getConnection()).ejecutar();
 */
public class MenuVentas {

    private final Scanner entrada;
    private final ControladorVentas controlador;
    private final ControladorFacturacion facturacion;

    public MenuVentas(Scanner entrada, Connection conexion) {
        this.entrada = entrada;
        this.controlador = new ControladorVentas(new VentasDao(conexion), new CustomerDao(conexion));
        this.facturacion = new ControladorFacturacion(new FacturaDao(conexion));
    }

    public void ejecutar() {
        while (true) {
            System.out.println("\n--- Ventas ---");
            System.out.println("1. Nueva venta  2. Ver lotes disponibles  3. Pasar venta a preparacion  0. Volver");
            String opcion = preguntar("Opcion");
            if (opcion.equals("0")) {
                return;
            }
            try {
                switch (opcion) {
                    case "1" -> nuevaVenta();
                    case "2" -> mostrarLotes(controlador.listarLotes());
                    case "3" -> pasarAPreparacion();
                    default -> System.out.println("Opcion no valida.");
                }
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            } catch (SQLException e) {
                System.out.println("Error de base de datos: " + e.getMessage());
            }
        }
    }

    private void nuevaVenta() throws SQLException {
        Customer cliente = controlador.buscarCliente(convertirEntero(preguntar("Id del cliente")));
        System.out.println("Cliente: " + cliente.name() + " (documento " + cliente.document() + ")");

        List<LineaPedido> pedido = new ArrayList<>();
        while (true) {
            // Se vuelve a consultar en cada vuelta para mostrar las existencias mas recientes.
            List<Lote> lotes = controlador.listarLotes();
            mostrarLotes(lotes);
            String texto = preguntar("Id del lote a agregar (Enter para terminar)");
            if (texto.isEmpty()) {
                break;
            }
            // Un dato invalido no debe perder el pedido ya armado.
            try {
                int idLote = convertirEntero(texto);
                Lote lote = lotes.stream().filter(l -> l.idLote() == idLote).findFirst()
                        .orElseThrow(() -> new IllegalArgumentException("Ese lote no esta disponible para la venta."));
                BigDecimal cantidad = convertirDecimal(preguntar("Cantidad"));
                controlador.agregarLinea(pedido, lote, cantidad);
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            }
        }

        if (pedido.isEmpty()) {
            System.out.println("Venta cancelada: el pedido esta vacio.");
            return;
        }
        mostrarResumen(pedido);
        if (preguntar("Confirmar la venta? (s/n)").equalsIgnoreCase("s")) {
            int idVenta = controlador.confirmarVenta(cliente.customerId(), pedido);
            System.out.println("Venta registrada con id " + idVenta + ".");
            generarFactura(idVenta);
        } else {
            System.out.println("Venta cancelada.");
        }
    }

    private void pasarAPreparacion() throws SQLException {
        List<VentaRegistrada> ventas = controlador.listarVentasRegistradas();
        if (ventas.isEmpty()) {
            System.out.println("No hay ventas registradas pendientes.");
            return;
        }
        System.out.println("Ventas registradas pendientes:");
        for (VentaRegistrada v : ventas) {
            System.out.printf("  #%d | %s | %s | $%s%n", v.idVenta(), v.numeroVenta(), v.cliente(), v.montoTotal());
        }
        controlador.pasarAPreparacion(convertirEntero(preguntar("Id de la venta a pasar a preparacion")));
        System.out.println("Venta en preparacion: ya aparece en el panel de Logistica.");
    }

    // La factura se crea despues de guardar la venta: si falla, la venta no se pierde y se puede
    // reintentar desde Facturacion (no se duplica, una venta tiene una sola factura).
    private void generarFactura(int idVenta) {
        try {
            Path pdf = facturacion.generarFactura(idVenta, MenuFacturacion.CARPETA_FACTURAS);
            System.out.println("Factura de demostracion generada: " + pdf.toAbsolutePath());
        } catch (SQLException | IOException | IllegalArgumentException e) {
            System.out.println("La venta " + idVenta + " quedo registrada, pero no se pudo generar la factura: "
                    + e.getMessage());
            System.out.println("Puede generarla despues desde el menu Facturacion.");
        }
    }

    private void mostrarLotes(List<Lote> lotes) {
        if (lotes.isEmpty()) {
            System.out.println("No hay lotes disponibles.");
            return;
        }
        System.out.println("Lotes disponibles (primero los que vencen antes):");
        for (Lote l : lotes) {
            String descuento = l.tasaDescuento().signum() > 0
                    ? " | descuento " + l.tasaDescuento().multiply(BigDecimal.valueOf(100)).stripTrailingZeros().toPlainString() + "%"
                    : "";
            System.out.printf("  #%d | %s | %s | vence %s | existencias %s | $%s | %s%s%n",
                    l.idLote(), l.numeroLote(), l.producto(), l.fechaVencimiento(),
                    l.cantidad(), l.precioVenta(), l.estado(), descuento);
        }
    }

    private void mostrarResumen(List<LineaPedido> pedido) {
        BigDecimal total = BigDecimal.ZERO;
        System.out.println("\nResumen del pedido:");
        for (LineaPedido l : pedido) {
            System.out.printf("  %s x %s | subtotal $%s | descuento $%s | impuesto $%s | total $%s%n",
                    l.lote().producto(), l.cantidad(), l.subtotal(), l.montoDescuento(),
                    l.montoImpuesto(), l.totalLinea());
            total = total.add(l.totalLinea());
        }
        System.out.println("TOTAL: $" + total);
    }

    private static int convertirEntero(String texto) {
        try {
            return Integer.parseInt(texto.trim());
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es un numero valido.");
        }
    }

    private static BigDecimal convertirDecimal(String texto) {
        try {
            return new BigDecimal(texto.trim().replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es una cantidad valida.");
        }
    }

    private String preguntar(String etiqueta) {
        System.out.print(etiqueta + ": ");
        return entrada.nextLine().trim();
    }
}
