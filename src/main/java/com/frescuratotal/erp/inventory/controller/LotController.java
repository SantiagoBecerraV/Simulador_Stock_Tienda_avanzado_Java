/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.controller;

import com.frescuratotal.erp.inventory.model.Lot;
import com.frescuratotal.erp.inventory.model.LotDao;
import com.frescuratotal.erp.inventory.model.LotStatus;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
/**
 *
 * @author admin
 */
public class LotController {

    private final LotDao dao = new LotDao();

    public List<Lot> listLots() throws SQLException {
        return dao.findAll();
    }

    // Applies the expiration rules once. Returns a short summary for the user.
    public String runExpirationCheck() throws SQLException {
        LocalDate today = LocalDate.now();
        int expired = dao.markExpired(today);
        int nearExpiry = dao.markNearExpiry(today, today.plusDays(7));
        return nearExpiry + " lots marked as Near Expiry, " + expired + " lots marked as Expired";
    }    

    // Returns the generated lot number so the user can write it down
    public String receiveLot(int supplierId, int productId, LocalDate expirationDate,
                             BigDecimal quantity, BigDecimal purchasePrice, BigDecimal salePrice,
                             String aisle, String shelf) throws SQLException {
        LocalDateTime now = LocalDateTime.now();
        validate(supplierId, productId, expirationDate, quantity, purchasePrice, salePrice, now.toLocalDate());

        if (!dao.isInCatalog(supplierId, productId)) {
            throw new IllegalArgumentException("This product is not in the supplier's catalog");
        }

        String lotNumber = generateLotNumber(productId, supplierId, now);
        Lot lot = new Lot(0, lotNumber, productId, supplierId, now, expirationDate,
                quantity, quantity, purchasePrice, salePrice, aisle, shelf, LotStatus.AVAILABLE);
        dao.insert(lot);
        return lotNumber;
    }

    // Example: LOT-3-1-20261031-170000 (product 3, supplier 1, date and time of reception)
    private String generateLotNumber(int productId, int supplierId, LocalDateTime now) {
        return "LOT-" + productId + "-" + supplierId + "-"
                + now.format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
    }

    private void validate(int supplierId, int productId, LocalDate expirationDate,
                          BigDecimal quantity, BigDecimal purchasePrice, BigDecimal salePrice,
                          LocalDate today) {
        if (supplierId <= 0 || productId <= 0) {
            throw new IllegalArgumentException("IDs must be positive numbers");
        }
        if (expirationDate == null) {
            throw new IllegalArgumentException("Expiration date is required");
        }
        if (expirationDate.isBefore(today)) {
            throw new IllegalArgumentException("Expired products cannot be received");
        }
        if (quantity == null || quantity.signum() <= 0) {
            throw new IllegalArgumentException("Quantity must be greater than zero");
        }
        if (purchasePrice == null || purchasePrice.signum() < 0) {
            throw new IllegalArgumentException("Purchase price cannot be negative");
        }
        if (salePrice == null || salePrice.signum() < 0) {
            throw new IllegalArgumentException("Sale price cannot be negative");
        }
    }
}
