package com.frescuratotal.erp.common;

import java.util.List;

public final class TablaConsola {

    private TablaConsola() {
    }

    public static void imprimir(String[] encabezados, List<String[]> filas) {
        if (filas.isEmpty()) {
            return;
        }

        int[] anchos = new int[encabezados.length];
        for (int i = 0; i < encabezados.length; i++) {
            anchos[i] = encabezados[i].length();
        }

        for (String[] fila : filas) {
            for (int columna = 0; columna < encabezados.length; columna++) {
                anchos[columna] = Math.max(anchos[columna], valor(fila[columna]).length());
            }
        }

        imprimirSeparador(anchos);
        imprimirFila(encabezados, anchos);
        imprimirSeparador(anchos);
        for (String[] fila : filas) {
            imprimirFila(fila, anchos);
        }
        imprimirSeparador(anchos);
    }

    private static void imprimirFila(String[] valores, int[] anchos) {
        System.out.print("| ");
        for (int i = 0; i < valores.length; i++) {
            System.out.printf("%-" + anchos[i] + "s | ", valor(valores[i]));
        }
        System.out.println();
    }

    private static void imprimirSeparador(int[] anchos) {
        System.out.print("+");
        for (int ancho : anchos) {
            System.out.print("-".repeat(ancho + 2) + "+");
        }
        System.out.println();
    }

    private static String valor(String texto) {
        return texto == null || texto.isBlank() ? "-" : texto;
    }
}
