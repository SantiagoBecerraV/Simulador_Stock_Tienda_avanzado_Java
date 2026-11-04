package com.frescuratotal.erp.inventory.model;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
public class Lot {

    private int id;
    private String lotNumber;
    private int productId;
    private int supplierId;
    private LocalDateTime receivedAt;
    private LocalDate expirationDate;
    private BigDecimal initialQuantity;
    private BigDecimal quantity;
    private BigDecimal purchasePrice;
    private BigDecimal salePrice;
    private String aisle;
    private String shelf;
    private LotStatus status;

    public Lot(int id, String lotNumber, int productId, int supplierId,
               LocalDateTime receivedAt, LocalDate expirationDate,
               BigDecimal initialQuantity, BigDecimal quantity,
               BigDecimal purchasePrice, BigDecimal salePrice,
               String aisle, String shelf, LotStatus status) {
        this.id = id;
        this.lotNumber = lotNumber;
        this.productId = productId;
        this.supplierId = supplierId;
        this.receivedAt = receivedAt;
        this.expirationDate = expirationDate;
        this.initialQuantity = initialQuantity;
        this.quantity = quantity;
        this.purchasePrice = purchasePrice;
        this.salePrice = salePrice;
        this.aisle = aisle;
        this.shelf = shelf;
        this.status = status;
    }

    public int getId() { return id; }
    public String getLotNumber() { return lotNumber; }
    public int getProductId() { return productId; }
    public int getSupplierId() { return supplierId; }
    public LocalDateTime getReceivedAt() { return receivedAt; }
    public LocalDate getExpirationDate() { return expirationDate; }
    public BigDecimal getInitialQuantity() { return initialQuantity; }
    public BigDecimal getQuantity() { return quantity; }
    public BigDecimal getPurchasePrice() { return purchasePrice; }
    public BigDecimal getSalePrice() { return salePrice; }
    public String getAisle() { return aisle; }
    public String getShelf() { return shelf; }
    public LotStatus getStatus() { return status; }

    @Override
    public String toString() {
        return id + " | " + lotNumber + " | producto " + productId
                + " | proveedor " + supplierId + " | cantidad " + quantity
                + " | vence " + expirationDate + " | " + status;
    }
}
