package com.frescuratotal.erp.suppliers.model;

import java.nio.file.Path;

// Punto 2: guarda el archivo creado y la cantidad de compras incluidas.
// Para ventas puede reutilizarse cambiando el nombre purchaseCount por saleCount.
public record DailyPurchaseReport(Path file, int purchaseCount) {
}
