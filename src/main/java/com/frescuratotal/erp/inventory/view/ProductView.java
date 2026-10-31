/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.view;

import com.frescuratotal.erp.inventory.controller.ProductController;
import com.frescuratotal.erp.inventory.model.Product;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;
import java.util.Scanner;
/**
 *
 * @author admin
 */
public class ProductView {

    private final Scanner scanner;
    private final ProductController controller;

    public ProductView(Scanner scanner, ProductController controller) {
        this.scanner = scanner;
        this.controller = controller;
    }

    public void show() {
        boolean back = false;

        while (!back) {
            System.out.println("\n--- PRODUCTS ---");
            System.out.println("1. List products");
            System.out.println("2. Add product");
            System.out.println("3. Update product");
            System.out.println("4. Delete product");
            System.out.println("0. Back");
            System.out.print("Choose an option: ");

            String option = scanner.nextLine().trim();

            try {
                switch (option) {
                    case "1" -> listProducts();
                    case "2" -> addProduct();
                    case "3" -> updateProduct();
                    case "4" -> deleteProduct();
                    case "0" -> back = true;
                    default -> System.out.println("Invalid option");
                }
            } catch (SQLException | IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private void listProducts() throws SQLException {
        List<Product> products = controller.listProducts();
        if (products.isEmpty()) {
            System.out.println("There are no products yet");
        }
        for (Product product : products) {
            System.out.println(product);
        }
    }

    private void addProduct() throws SQLException {
        showCategories();
        String name = ask("Name: ");
        String description = ask("Description: ");
        int categoryId = askInt("Category ID: ");
        String unit = ask("Unit (kg, litro, unidad): ");
        BigDecimal price = askPrice("Base price: ");

        controller.addProduct(new Product(0, name, description, categoryId, unit, price));
        System.out.println("Product added");
    }

    private void updateProduct() throws SQLException {
        int id = askInt("Product ID to update: ");
        showCategories();
        String name = ask("New name: ");
        String description = ask("New description: ");
        int categoryId = askInt("New category ID: ");
        String unit = ask("New unit: ");
        BigDecimal price = askPrice("New base price: ");

        boolean updated = controller.updateProduct(
                new Product(id, name, description, categoryId, unit, price));
        System.out.println(updated ? "Product updated" : "Product not found");
    }

    private void deleteProduct() throws SQLException {
        int id = askInt("Product ID to delete: ");
        boolean deleted = controller.deleteProduct(id);
        System.out.println(deleted ? "Product deleted" : "Product not found");
    }

    private void showCategories() throws SQLException {
        System.out.println("Categories:");
        for (String category : controller.listCategories()) {
            System.out.println("  " + category);
        }
    }

    private String ask(String prompt) {
        System.out.print(prompt);
        return scanner.nextLine().trim();
    }

    private int askInt(String prompt) {
        try {
            return Integer.parseInt(ask(prompt));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Enter a whole number");
        }
    }

    private BigDecimal askPrice(String prompt) {
        try {
            return new BigDecimal(ask(prompt));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("Price must be a number, for example 5500 or 5500.50");
        }
    }
}