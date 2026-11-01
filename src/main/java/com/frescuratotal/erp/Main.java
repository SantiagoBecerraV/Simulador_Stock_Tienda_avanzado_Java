package com.frescuratotal.erp;

    /*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 */

import com.frescuratotal.erp.suppliers.controller.SupplierController;
import com.frescuratotal.erp.suppliers.view.SupplierView;
import java.util.Scanner;
import com.frescuratotal.erp.inventory.controller.ProductController;
import com.frescuratotal.erp.inventory.view.ProductView;
import com.frescuratotal.erp.inventory.controller.LotController;
import com.frescuratotal.erp.inventory.view.LotView;
/**
 *
 * @author admin
 */
public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        SupplierView supplierView = new SupplierView(scanner, new SupplierController());
        ProductView productView = new ProductView(scanner, new ProductController());    
        LotView lotView = new LotView(scanner, new LotController());
        boolean running = true;

        while (running) {
            printMenu();
            int option = readOption(scanner);

            switch (option) {
                case 1 -> productView.show();
                case 2 -> supplierView.show();
                case 3 -> lotView.show();
                case 0 -> {
                    running = false;
                    System.out.println("Goodbye");
                }
                default -> System.out.println("Invalid option, try again");
            }
        }

        scanner.close();
    }

    private static void printMenu() {
        System.out.println("\n=== FRESCURA TOTAL ===");
        System.out.println("1. Products");
        System.out.println("2. Suppliers");
        System.out.println("3. Inventory");
        System.out.println("0. Exit");
        System.out.print("Choose an option: ");
    }

    private static int readOption(Scanner scanner) {
        while (true) {
            String line = scanner.nextLine().trim();
            try {
                return Integer.parseInt(line);
            } catch (NumberFormatException e) {
                System.out.print("Please enter a number: ");
            }
        }
    }
}
