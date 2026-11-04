package com.frescuratotal.erp.common;

import java.util.List;

public final class ConsoleTable {

    private ConsoleTable() {
    }

    public static void printTable(String[] headers, List<String[]> rows) {
        if (rows.isEmpty()) {
            return;
        }

        int[] widths = new int[headers.length];
        for (int i = 0; i < headers.length; i++) {
            widths[i] = headers[i].length();
        }

        for (String[] row : rows) {
            for (int column = 0; column < headers.length; column++) {
                widths[column] = Math.max(widths[column], normalizeValue(row[column]).length());
            }
        }

        printSeparator(widths);
        printRow(headers, widths);
        printSeparator(widths);
        for (String[] row : rows) {
            printRow(row, widths);
        }
        printSeparator(widths);
    }

    private static void printRow(String[] values, int[] widths) {
        System.out.print("| ");
        for (int i = 0; i < values.length; i++) {
            System.out.printf("%-" + widths[i] + "s | ", normalizeValue(values[i]));
        }
        System.out.println();
    }

    private static void printSeparator(int[] widths) {
        System.out.print("+");
        for (int width : widths) {
            System.out.print("-".repeat(width + 2) + "+");
        }
        System.out.println();
    }

    private static String normalizeValue(String text) {
        return text == null || text.isBlank() ? "-" : text;
    }
}
