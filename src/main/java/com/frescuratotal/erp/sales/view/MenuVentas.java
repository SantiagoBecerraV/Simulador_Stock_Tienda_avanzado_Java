package com.frescuratotal.erp.sales.view;

import com.frescuratotal.erp.sales.dao.CustomerDao;
import com.frescuratotal.erp.sales.model.Customer;
import com.frescuratotal.erp.sales.controller.ControladorVentas;
import com.frescuratotal.erp.sales.dao.VentasDao;
import com.frescuratotal.erp.sales.model.LineaPedido;
import com.frescuratotal.erp.sales.model.Lote;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 * Menú de consola del módulo de Ventas. Punto de entrada para el menú principal:
 * new MenuVentas(scanner, DatabaseConnection.getConnection()).ejecutar();
 */
public class MenuVentas {

    private final Scanner entrada;
    private final ControladorVentas controlador;

    public MenuVentas(Scanner entrada, Connection conexion) {
        this.entrada = entrada;
        this.controlador = new ControladorVentas(new VentasDao(conexion), new CustomerDao(conexion));
    }

    public void ejecutar() {
        while (true) {
            System.out.println("\n--- Ventas ---");
            System.out.println("1. Nueva venta  2. Ver lotes disponibles  0. Volver");
            String opcion = preguntar("Opción");
            if (opcion.equals("0")) {
                return;
            }
            try {
                switch (opcion) {
                    case "1" -> nuevaVenta();
                    case "2" -> mostrarLotes(controlador.listarLotes());
                    default -> System.out.println("Opción no válida.");
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
            // Se vuelve a consultar en cada vuelta para mostrar las existencias más recientes.
            List<Lote> lotes = controlador.listarLotes();
            mostrarLotes(lotes);
            String texto = preguntar("Id del lote a agregar (Enter para terminar)");
            if (texto.isEmpty()) {
                break;
            }
            // Un dato inválido no debe perder el pedido ya armado.
            try {
                int idLote = convertirEntero(texto);
                Lote lote = lotes.stream().filter(l -> l.idLote() == idLote).findFirst()
                        .orElseThrow(() -> new IllegalArgumentException("Ese lote no está disponible para la venta."));
                BigDecimal cantidad = convertirDecimal(preguntar("Cantidad"));
                controlador.agregarLinea(pedido, lote, cantidad);
            } catch (IllegalArgumentException e) {
                System.out.println(e.getMessage());
            }
        }

        if (pedido.isEmpty()) {
            System.out.println("Venta cancelada: el pedido está vacío.");
            return;
        }
        mostrarResumen(pedido);
        if (preguntar("¿Confirmar la venta? (s/n)").equalsIgnoreCase("s")) {
            int idVenta = controlador.confirmarVenta(cliente.customerId(), pedido);
            System.out.println("Venta registrada con id " + idVenta + ". Use Facturación para generar la factura.");
        } else {
            System.out.println("Venta cancelada.");
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
            throw new IllegalArgumentException("'" + texto + "' no es un número válido.");
        }
    }

    private static BigDecimal convertirDecimal(String texto) {
        try {
            return new BigDecimal(texto.trim().replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("'" + texto + "' no es una cantidad válida.");
        }
    }

    private String preguntar(String etiqueta) {
        System.out.print(etiqueta + ": ");
        return entrada.nextLine().trim();
    }
}
