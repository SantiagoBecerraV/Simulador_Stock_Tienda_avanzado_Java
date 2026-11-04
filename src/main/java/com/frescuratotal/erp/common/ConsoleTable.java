package com.frescuratotal.erp.common;

import java.util.List;
import java.util.stream.IntStream;

public final class ConsoleTable {

    private ConsoleTable() {
    }

    public static void printTable(String[] headers, List<String[]> rows) {
        if (rows.isEmpty()) {
            return;
        }

        int[] widths = new int[headers.length];
        IntStream.range(0, headers.length).forEach(i -> widths[i] = headers[i].length());

        rows.forEach(row -> IntStream.range(0, headers.length).forEach(column -> {
            widths[column] = Math.max(widths[column], normalizeValue(row[column]).length());
        }));

        printSeparator(widths);
        printRow(headers, widths);
        printSeparator(widths);
        rows.forEach(row -> printRow(row, widths));
        printSeparator(widths);
    }

    private static void printRow(String[] values, int[] widths) {
        System.out.print("| ");
        IntStream.range(0, values.length)
                .forEach(i -> System.out.printf("%-" + widths[i] + "s | ", normalizeValue(values[i])));
        System.out.println();
    }

    private static void printSeparator(int[] widths) {
        System.out.print("+");
        java.util.Arrays.stream(widths).forEach(width -> System.out.print("-".repeat(width + 2) + "+"));
        System.out.println();
    }

    private static String normalizeValue(String text) {
        return text == null || text.isBlank() ? "-" : text;
    }
}
