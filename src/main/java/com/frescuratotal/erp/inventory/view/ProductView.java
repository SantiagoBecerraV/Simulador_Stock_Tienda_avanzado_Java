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
            System.out.println("\n--- PRODUCTOS ---");
            System.out.println("1. Listar productos");
            System.out.println("2. Registrar producto");
            System.out.println("3. Modificar producto");
            System.out.println("4. Eliminar producto");
            System.out.println("0. Volver");
            System.out.print("Elija una opcion: ");

            String option = scanner.nextLine().trim();

            try {
                switch (option) {
                    case "1" -> listProducts();
                    case "2" -> addProduct();
                    case "3" -> updateProduct();
                    case "4" -> deleteProduct();
                    case "0" -> back = true;
                    default -> System.out.println("Opcion invalida!!! ");
                }
            } catch (SQLException | IllegalArgumentException e) {
                System.out.println("Error: " + e.getMessage());
            }
        }
    }

    private void listProducts() throws SQLException {
        List<Product> products = controller.listProducts();
        if (products.isEmpty()) {
            System.out.println("No hay productos registrados aun...");
        }
        for (Product product : products) {
            System.out.println(product);
        }
    }

    private void addProduct() throws SQLException {
        showCategories();
        String name = ask("Nombre: ");
        String description = ask("Descripcion: ");
        int categoryId = askInt("ID de categoria: ");
        String unit = ask("Unidad de medida (kg, litro, unidad): ");
        BigDecimal price = askPrice("Precio base: ");

        controller.addProduct(new Product(0, name, description, categoryId, unit, price));
        System.out.println("Producto anadido exitosamente!!");
    }

    private void updateProduct() throws SQLException {
        int id = askInt("ID del producto a actualizar ");
        showCategories();
        String name = ask("Nombre nuevo: ");
        String description = ask("Descripcion nueva: ");
        int categoryId = askInt("Id de la nueva categoria: ");
        String unit = ask("Nueva unidad de medida: ");
        BigDecimal price = askPrice("Nuevo precio base: ");

        boolean updated = controller.updateProduct(
                new Product(id, name, description, categoryId, unit, price));
        System.out.println(updated ? "Producto actualizado con exito!!" : "Producto no encontrado");
    }

    private void deleteProduct() throws SQLException {
        int id = askInt("Id del producto a eliminar: ");
        boolean deleted = controller.deleteProduct(id);
        System.out.println(deleted ? "Producto eliminado con exito!!" : "Producto no encontrado");
    }

    private void showCategories() throws SQLException {
        System.out.println("Categorias: ");
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
            throw new IllegalArgumentException("Debe ingresar un numero entero..");
        }
    }

    private BigDecimal askPrice(String prompt) {
        try {
            return new BigDecimal(ask(prompt));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException("El precio debe ser un numero, por ejemplo 5500 o 5500.50...");
        }
    }
}