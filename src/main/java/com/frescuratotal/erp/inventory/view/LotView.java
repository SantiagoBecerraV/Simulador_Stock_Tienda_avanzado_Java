package com.frescuratotal.erp.inventory.view;

import com.frescuratotal.erp.common.ConsoleTable;
import com.frescuratotal.erp.inventory.controller.LotController;
import com.frescuratotal.erp.inventory.model.Lot;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
public class LotView {

    private final Scanner scanner;
    private final LotController controller;

    public LotView(Scanner scanner, LotController controller) {
        this.scanner = scanner;
        this.controller = controller;
    }

    public void show() {
        Map<String, MenuAction> actions = Map.ofEntries(
                Map.entry("1", this::receiveLot), Map.entry("2", this::listLots),
                Map.entry("3", this::runExpirationCheck), Map.entry("4", this::quarantineLot),
                Map.entry("5", this::inspectLot), Map.entry("6", this::registerWaste),
                Map.entry("7", this::lotsBySupplier), Map.entry("8", this::sellableStock),
                Map.entry("9", this::lotHistory));
        boolean back = false;

        while (!back) {
            System.out.println("\n--- INVENTARIO (LOTES) ---");
            System.out.println("1. Ingresar lote");
            System.out.println("2. Listar lotes");
            System.out.println("3. Verificar vencimientos");
            System.out.println("4. Poner lote en cuarentena");
            System.out.println("5. Inspeccionar lote en cuarentena");    
            System.out.println("6. Registrar Perdidas (merma)");
            System.out.println("7. Lotes por proveedor");
            System.out.println("8. Stock disponible para la venta por producto");
            System.out.println("9. Historial de un lote");
            System.out.println("0. Volver");
            System.out.print("Elija una opcion: ");

            String option = scanner.nextLine().trim();

            try {
                if (option.equals("0")) {
                    back = true;
                } else {
                    actions.getOrDefault(option, () -> System.out.println("Opcion invalida!!")).run();
                }
            } catch (SQLException | IllegalArgumentException e) {
                System.out.println("Error!! : " + e.getMessage());
            }
        }
    }

    private void receiveLot() throws SQLException {
        int supplierId = askInt("ID Proveedor: ");
        int productId = askInt("ID Producto: ");
        LocalDate expiration = askDate("Fecha de vencimiento (yyyy-MM-dd): ");
        BigDecimal quantity = askDecimal("Cantidad recibida: ");
        BigDecimal purchasePrice = askDecimal("Precio de compra por unidad: ");
        BigDecimal salePrice = askDecimal("Precio de venta por unidad: ");
        String aisle = askOptional("Pasillo (opcional, Enter para omitir): ");
        String shelf = askOptional("Estante (opcional, Enter para omitir): ");

        String lotNumber = controller.receiveLot(supplierId, productId, expiration,
                quantity, purchasePrice, salePrice, aisle, shelf);
        System.out.println("Lote ingresado exitosamente. Numero de lote: " + lotNumber);
    }

    private void listLots() throws SQLException {
        List<Lot> lots = controller.listLots();
        if (lots.isEmpty()) {
            System.out.println("No hay lotes todavía.....");
            return;
        }

        List<String[]> rows = lots.stream()
                .map(lot -> new String[]{String.valueOf(lot.getId()), lot.getLotNumber(),
                    String.valueOf(lot.getProductId()), String.valueOf(lot.getSupplierId()),
                    String.valueOf(lot.getQuantity()), String.valueOf(lot.getExpirationDate()),
                    lot.getStatus().toString()})
                .toList();
        ConsoleTable.printTable(new String[]{"Id", "Numero de lote", "Id producto", "Id proveedor",
            "Existencias", "Vencimiento", "Estado"}, rows);
    }

    private void runExpirationCheck() throws SQLException {
        System.out.println(controller.runExpirationCheck());
    }
    
    private void quarantineLot() throws SQLException {
        int lotId = askInt("ID del lote a poner en cuarentena: ");
        String reason = ask("Motivo (empaque en mal estado, mal olor, etc.): ");
        String user = ask("Tu nombre: ");

        controller.quarantineLot(lotId, reason, user);
        System.out.println("Lote puesto en cuarentena");
    }
    
    private void inspectLot() throws SQLException {
        int lotId = askInt("Id del lote a inspeccionar: ");
        String result = ask("Resultado (A = aceptado, R = rechazado): ");

        boolean approved;
        if (result.equalsIgnoreCase("A")) {
            approved = true;
        } else if (result.equalsIgnoreCase("R")) {
            approved = false;
        } else {
            throw new IllegalArgumentException("El resultado debe ser A o R !!!");
        }

        String inspector = ask("Nombre del inspector: ");
        String notes = ask(approved ? "Notas (Opcionales): " : "Razon para el rechazo deel proceso: ");

        controller.inspectLot(lotId, approved, inspector, notes);
        System.out.println(approved ? "Lote aprobado !!" : "Lote rechazado y enviado a merma....");
    }
    
    private void registerWaste() throws SQLException {
        int lotId = askInt("Id del Lote: ");
        BigDecimal quantity = askDecimal("Cantidad perdida: ");
        String reason = ask("Razon (vencido, danado, etc.): ");
        String user = ask("Tu nombre: ");

        controller.registerWaste(lotId, quantity, reason, user);
        System.out.println("Perdida registrada y stock actualizado !!!");
    }
    
    private void lotsBySupplier() throws SQLException {
        int supplierId = askInt("ID del proveedor: ");
        printLines(controller.lotsBySupplier(supplierId), "Este proveedor aun no tiene lotes");
    }

    private void sellableStock() throws SQLException {
        printLines(controller.sellableStock(), "No hay stock disponible para la venta");
    }

    private void lotHistory() throws SQLException {
        int lotId = askInt("Id del lote: ");
        printLines(controller.lotHistory(lotId), "Este lote aún no tiene historial");
    }

    private void printLines(List<String> lines, String emptyMessage) {
        if (lines.isEmpty()) {
            System.out.println(emptyMessage);
        }
        lines.forEach(System.out::println);
    }
    
    private String ask(String prompt) {
        System.out.print(prompt);
        return scanner.nextLine().trim();
    }

    private String askOptional(String prompt) {
        String text = ask(prompt);
        return text.isEmpty() ? null : text;
    }

    private int askInt(String prompt) {
        try {
            return Integer.parseInt(ask(prompt));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Ingrese un numero entero");
        }
    }

    private BigDecimal askDecimal(String prompt) {
        try {
            // Igual que en Ventas: se acepta coma o punto decimal (12,5 o 12.5).
            return new BigDecimal(ask(prompt).replace(',', '.'));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Ingrese un numero, por ejemplo 12, 12.5 o 12,5");
        }
    }

    private LocalDate askDate(String prompt) {
        try {
            return LocalDate.parse(ask(prompt));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("La fecha debe tener el formato EJ: 2026-12-31");
        }
    }

    @FunctionalInterface
    private interface MenuAction {
        void run() throws SQLException;
    }
}
