/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.view;

import com.frescuratotal.erp.inventory.controller.LotController;
import com.frescuratotal.erp.inventory.model.Lot;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.Scanner;
/**
 *
 * @author admin
 */
public class LotView {

    private final Scanner scanner;
    private final LotController controller;

    public LotView(Scanner scanner, LotController controller) {
        this.scanner = scanner;
        this.controller = controller;
    }

    public void show() {
        boolean back = false;

        while (!back) {
            System.out.println("\n--- INVENTORY (LOTS) ---");
            System.out.println("1. Receive lot");
            System.out.println("2. List lots");
            System.out.println("3. Run expiration check");            
            System.out.println("0. Back");
            System.out.print("Choose an option: ");

            String option = scanner.nextLine().trim();

            try {
                switch (option) {
                    case "1" -> receiveLot();
                    case "2" -> listLots();
                    case "3" -> runExpirationCheck();                    
                    case "0" -> back = true;
                    default -> System.out.println("Invalid option");
                }
            } catch (SQLException | IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private void receiveLot() throws SQLException {
        int supplierId = askInt("Supplier ID: ");
        int productId = askInt("Product ID: ");
        LocalDate expiration = askDate("Expiration date (yyyy-MM-dd): ");
        BigDecimal quantity = askDecimal("Quantity received: ");
        BigDecimal purchasePrice = askDecimal("Purchase price per unit: ");
        BigDecimal salePrice = askDecimal("Sale price per unit: ");
        String aisle = askOptional("Aisle (optional, Enter to skip): ");
        String shelf = askOptional("Shelf (optional, Enter to skip): ");

        String lotNumber = controller.receiveLot(supplierId, productId, expiration,
                quantity, purchasePrice, salePrice, aisle, shelf);
        System.out.println("Lot received. Lot number: " + lotNumber);
    }

    private void listLots() throws SQLException {
        List<Lot> lots = controller.listLots();
        if (lots.isEmpty()) {
            System.out.println("There are no lots yet");
        }
        for (Lot lot : lots) {
            System.out.println(lot);
        }
    }

    private void runExpirationCheck() throws SQLException {
        System.out.println(controller.runExpirationCheck());
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
            throw new IllegalArgumentException("Enter a whole number");
        }
    }

    private BigDecimal askDecimal(String prompt) {
        try {
            return new BigDecimal(ask(prompt));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Enter a number, for example 12 or 12.5");
        }
    }

    private LocalDate askDate(String prompt) {
        try {
            return LocalDate.parse(ask(prompt));
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Date must look like 2026-12-31");
        }
    }
}
