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
import com.frescuratotal.erp.inventory.model.QualityDao;
/**
 *
 * @author admin
 */
public class LotController {

    private final LotDao dao = new LotDao();
    private final QualityDao qualityDao = new QualityDao();
    
    private static final int NEAR_EXPIRY_DAYS = 7;

    public List<Lot> listLots() throws SQLException {
        return dao.findAll();
    }

   // Aplica las reglas de expiracion una vez. Devuelve un resumen corto para el usuario.
    public String runExpirationCheck() throws SQLException {
        LocalDate today = LocalDate.now();
        int expired = dao.markExpired(today);
        int nearExpiry = dao.markNearExpiry(today, today.plusDays(NEAR_EXPIRY_DAYS));
        return nearExpiry + " lotes marcados como Proximos a Vencer, " + expired + " lotes marcados como Vencidos";
    }    

    // Retorna el numero de lote generado para que el usuario pueda anotarlo
    public String receiveLot(int supplierId, int productId, LocalDate expirationDate,
                             BigDecimal quantity, BigDecimal purchasePrice, BigDecimal salePrice,
                             String aisle, String shelf) throws SQLException {
        LocalDateTime now = LocalDateTime.now();
        LocalDate today = now.toLocalDate();
        validate(supplierId, productId, expirationDate, quantity, purchasePrice, salePrice, today);

        if (!dao.isInCatalog(supplierId, productId)) {
            throw new IllegalArgumentException("Este producto no se encuentra en el catalogo del proveedor");
        }

        // Un lote que ya está proximo a vencer debe iniciar como NEAR_EXPIRY;
        // de lo contrario, podria venderse a precio completo hasta la proxima verificacion
        LotStatus status = expirationDate.isAfter(today.plusDays(NEAR_EXPIRY_DAYS))
                ? LotStatus.AVAILABLE
                : LotStatus.NEAR_EXPIRY;

        String lotNumber = generateLotNumber(productId, supplierId, now);
        Lot lot = new Lot(0, lotNumber, productId, supplierId, now, expirationDate,
                quantity, quantity, purchasePrice, salePrice, aisle, shelf, status);
        dao.insert(lot);
        return lotNumber;
    }

    // Ejemplo: LOT-3-1-20261031-170000 (producto 3, proveedor 1, fecha y hora de recepcion)
    private String generateLotNumber(int productId, int supplierId, LocalDateTime now) {
        return "LOT-" + productId + "-" + supplierId + "-"
                + now.format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
    }

    //metodo de el quality mejor dicho del registro de cuarentena
    public void quarantineLot(int lotId, String reason, String user) throws SQLException {
        if (lotId <= 0) {
                throw new IllegalArgumentException("El ID del lote debe ser un numero positivo");
        }
        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException("La razon es obligatoria !!");
        }
        if (user == null || user.isBlank()) {
            throw new IllegalArgumentException("El nombre de usuario es obligatorio !!");
        }
        qualityDao.quarantine(lotId, reason, user);
    }
    
    //metodo de inspeccion
    public void inspectLot(int lotId, boolean approved, String inspector, String notes) throws SQLException {
        if (lotId <= 0) {
            throw new IllegalArgumentException("El ID del lote debe ser un numero positivo...");
        }
        if (inspector == null || inspector.isBlank()) {
            throw new IllegalArgumentException("El nombre del inspector es obligatorio !!");
        }
        if (!approved && (notes == null || notes.isBlank())) {
            throw new IllegalArgumentException("El motivo de rechazo es obligatorio !!!");
        }

        Lot lot = dao.findById(lotId)
                .orElseThrow(() -> new IllegalArgumentException("Lote no encontrado.."));
        if (lot.getStatus() != LotStatus.IN_QUARANTINE) {
            throw new IllegalArgumentException("Solo los lotes en cuarentena pueden ser inspeccionados...");
        }

        LotStatus nextStatus = approved
                ? statusForDate(lot.getExpirationDate(), LocalDate.now())
                : LotStatus.REJECTED;
        String cleanNotes = (notes == null || notes.isBlank()) ? null : notes.trim();

        qualityDao.inspect(lot, approved, inspector.trim(), cleanNotes, nextStatus);
    }

    // Misma regla que en recepción: el estado depende de qué tan próxima esté la fecha de vencimiento
    private LotStatus statusForDate(LocalDate expirationDate, LocalDate today) {
        if (expirationDate.isBefore(today)) {
            return LotStatus.EXPIRED;
        }
        if (!expirationDate.isAfter(today.plusDays(NEAR_EXPIRY_DAYS))) {
            return LotStatus.NEAR_EXPIRY;
        }
        return LotStatus.AVAILABLE;
    }

    //metodo de registro de merma
    public void registerWaste(int lotId, BigDecimal quantity, String reason, String user) throws SQLException {
        if (lotId <= 0) {
            throw new IllegalArgumentException("El id del lote debe ser un numero positivo...");
        }
        if (quantity == null || quantity.signum() <= 0) {
            throw new IllegalArgumentException("La cantidad de merma debe ser mayor a cero...");
        }
        if (reason == null || reason.isBlank()) {
            throw new IllegalArgumentException("La razon es obligatoria...");
        }
        if (user == null || user.isBlank()) {
            throw new IllegalArgumentException("El nombre del usuario es obligatorio!!");
        }
        qualityDao.registerWaste(lotId, quantity, reason.trim(), user.trim());
    }
    
    private void validate(int supplierId, int productId, LocalDate expirationDate,
                          BigDecimal quantity, BigDecimal purchasePrice, BigDecimal salePrice,
                          LocalDate today) {
        if (supplierId <= 0 || productId <= 0) {
            throw new IllegalArgumentException("Los IDs deben ser numeros positivos");
        }
        if (expirationDate == null) {
            throw new IllegalArgumentException("La fecha de expiracion es obligatoria");
        }
        if (expirationDate.isBefore(today)) {
            throw new IllegalArgumentException("No se pueden recibir productos vencidos");
        }
        if (quantity == null || quantity.signum() <= 0) {
            throw new IllegalArgumentException("La cantidad debe ser mayor a cero");
        }
        if (purchasePrice == null || purchasePrice.signum() < 0) {
            throw new IllegalArgumentException("El precio de compra debe ser mayor o igual a cero");
        }
        if (salePrice == null || salePrice.signum() < 0) {
            throw new IllegalArgumentException("El precio de venta no puede ser negativo");
        }
    }
}
