package com.frescuratotal.erp;

    /*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 */

import java.util.Scanner;

/**
 *
 * @author admin
 */
public class Main {

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        boolean running = true;

        while (running) {
            printMenu();
            int option = readOption(scanner);

            switch (option) {
                case 1 -> System.out.println("Products: coming soon");
                case 2 -> System.out.println("Suppliers: coming soon");
                case 3 -> System.out.println("Inventory: coming soon");
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

    // Sigue preguntando hasta que el usuario ingrese un número entero.
    private static int readOption(Scanner scanner) {
        while (!scanner.hasNextInt()) {
            scanner.next();
            System.out.print("Please enter a number: ");
        }
        return scanner.nextInt();
    }
}
