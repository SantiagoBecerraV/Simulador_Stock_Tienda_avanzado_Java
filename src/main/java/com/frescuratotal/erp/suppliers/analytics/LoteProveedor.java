package com.frescuratotal.erp.suppliers.analytics;

public class LoteProveedor {

    private int idLote;
    private double cantidadInicial;
    private String estadoLote;
    private int idProveedor;
    private String nombreProveedor;

    public LoteProveedor(int idLote, double cantidadInicial, String estadoLote, int idProveedor, String nombreProveedor) {
        this.idLote = idLote;
        this.cantidadInicial = cantidadInicial;
        this.estadoLote = estadoLote;
        this.idProveedor = idProveedor;
        this.nombreProveedor = nombreProveedor;
    }

    public int getIdLote() {
        return idLote;
    }

    public void setIdLote(int idLote) {
        this.idLote = idLote;
    }

    public double getCantidadInicial() {
        return cantidadInicial;
    }

    public void setCantidadInicial(double cantidadInicial) {
        this.cantidadInicial = cantidadInicial;
    }

    public String getEstadoLote() {
        return estadoLote;
    }

    public void setEstadoLote(String estadoLote) {
        this.estadoLote = estadoLote;
    }

    public int getIdProveedor() {
        return idProveedor;
    }

    public void setIdProveedor(int idProveedor) {
        this.idProveedor = idProveedor;
    }

    public String getNombreProveedor() {
        return nombreProveedor;
    }

    public void setNombreProveedor(String nombreProveedor) {
        this.nombreProveedor = nombreProveedor;
    }
}
