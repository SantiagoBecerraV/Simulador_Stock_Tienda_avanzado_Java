/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package com.frescuratotal.erp.inventory.model;

import java.math.BigDecimal;
/**
 *
 * @author admin
 */
public class Product {

    private int id;
    private String name;
    private String description;
    private int categoryId;
    private String unit;
    private BigDecimal basePrice;

    public Product(int id, String name, String description, int categoryId,
                   String unit, BigDecimal basePrice) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.categoryId = categoryId;
        this.unit = unit;
        this.basePrice = basePrice;
    }

    public int getId() { return id; }
    public String getName() { return name; }
    public String getDescription() { return description; }
    public int getCategoryId() { return categoryId; }
    public String getUnit() { return unit; }
    public BigDecimal getBasePrice() { return basePrice; }

    @Override
    public String toString() {
        return id + " | " + name + " | " + unit + " | $" + basePrice
                + " | categoria " + categoryId;
    }
}
