package com.frescuratotal.erp.suppliers.model;

import java.nio.file.Path;

//punto 2
// Guarda el archivo creado y la cantidad de compras incluidas.
public record DailyPurchaseReport(Path file, int purchaseCount) {
}
