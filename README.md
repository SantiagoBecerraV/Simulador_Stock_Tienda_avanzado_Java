# ERP para la Bodega de Alimentos "Frescura Total"

## Descripcion

Sistema ERP de consola, hecho en Java y MySQL, para la bodega de alimentos "Frescura Total". Reemplaza las hojas de calculo y los registros en papel con un flujo conectado: recepcion de lotes con fecha de vencimiento, proveedores, clientes, ventas que descuentan el inventario, facturas en PDF y despacho de pedidos con rutas, vehiculos y conductores. Asi se reducen las perdidas por vencimiento, se puede rastrear cada lote hasta su proveedor, no se venden productos agotados y la facturacion deja de ser manual.

## Autores

Becerra y Solano (completar con los nombres completos de los estudiantes antes de la entrega).

## Requerimientos previos

- Java 17 (JDK 17 o superior; el proyecto compila con `release 17`).
- Apache Maven 3.x (NetBeans incluye uno).
- Apache NetBeans 12 o superior (opcional si se usa solo la terminal).
- MySQL 8.0.

Las librerias (driver MySQL, OpenPDF y ZXing para el PDF y el QR) las descarga Maven desde `pom.xml`.

## Configuracion de la base de datos

1. Inicie el servidor MySQL 8.0 local.
2. Ejecute el script maestro **`docs/database.sql`**. Es la unica fuente para crear la base y cargar los datos de prueba:
   - Desde MySQL Workbench: abra el archivo y ejecutelo completo.
   - Desde la terminal: `mysql -u root -p < docs/database.sql`
3. El script tiene tres secciones: DDL (estructura), DML (datos de prueba, repetibles sin duplicar) y consultas de verificacion de solo lectura al final.

> **Advertencia:** el script empieza con `DROP DATABASE IF EXISTS erp_frescura_total`. Al ejecutarlo completo se borra esa base y se crea de nuevo. No lo ejecute sobre datos que quiera conservar. Para cargar solo los datos sobre una base ya creada, ejecute desde la linea `SECCION 2: DML` en adelante.

**Orden de ejecucion:** usa `docs/database.sql` como el unico script de base de datos del proyecto.

### Credenciales de conexion

La conexion esta en `src/main/java/com/frescuratotal/erp/common/DatabaseConnection.java`, en las constantes `URL`, `USER` y `PASSWORD`. Ejemplo:

```java
private static final String URL = "jdbc:mysql://localhost:3306/erp_frescura_total";
private static final String USER = "root";
private static final String PASSWORD = "su_contrasena";
```

Ajuste el puerto y la contrasena a su instalacion de MySQL. No suba al repositorio una contrasena real. Todos los modulos usan esta misma conexion.

## Instalacion y ejecucion

1. Clone el repositorio: `git clone https://github.com/SantiagoBecerraV/Frescura_total_java_Becerra_Solano.git`
2. Abra la carpeta del proyecto en Apache NetBeans (File > Open Project).
3. Compile: Run > Clean and Build Project.
4. Ejecute: Run > Run Project (tecla F6).

Desde la terminal, en la carpeta del proyecto:

```
mvn clean compile
mvn compile exec:java
```

(La clase principal `com.frescuratotal.erp.Main` esta definida en `pom.xml`. La primera vez, Maven necesita internet para descargar el plugin `exec`.)

El PDF de cada factura se guarda en la carpeta `facturas/`, relativa a donde se ejecuta el programa.

### Menu principal

1. Productos
2. Proveedores
3. Inventario
4. Ventas (nueva venta, ver lotes, pasar una venta a preparacion)
5. Facturacion (generar o regenerar la factura PDF de una venta)
6. Clientes
7. Logistica (vehiculos, conductores, rutas, despacho y entregas)
0. Salir

## Estructura del proyecto

La arquitectura es MVC por componentes: cada modulo tiene sus paquetes `controller`, `model` y `view`.

```
src/main/java/com/frescuratotal/erp/
+-- common/        Conexion compartida a la base de datos (DatabaseConnection)
+-- inventory/     controller, model, view  (productos, lotes, calidad, trazabilidad)
+-- suppliers/     controller, model, view  (proveedores)
+-- sales/         controller, dao, model, view
|                    clientes, ventas, facturacion y logistica
+-- Main.java      Punto de entrada y menu principal
```

El modulo `sales` agrupa cuatro funciones, cada una con sus clases:

| Funcion | Controller | DAO | Model | View |
|---|---|---|---|---|
| Clientes | `CustomerController` | `CustomerDao` | `Customer` | `CustomerMenu` |
| Ventas | `ControladorVentas` | `VentasDao` | `Lote`, `LineaPedido`, `VentaRegistrada` | `MenuVentas` |
| Facturacion | `ControladorFacturacion` | `FacturaDao` | `Factura` | `MenuFacturacion`, `FacturaPdf` |
| Logistica | `ControladorLogistica` | `LogisticaDao` | `Vehiculo`, `Conductor`, `Ruta`, `EntregaRuta`, `VentaEnPreparacion` y los estados | `MenuLogistica` |

Los diagramas estan en `docs/`: `diagrama_er.png` (entidad-relacion, fuente `diagrama_er.puml`) y `diagrama_clases.png` (fuente `diagrama_clases.puml`).

## Como se relacionan los modulos

Los modulos no se llaman entre si: se conectan por la base de datos y por el estado de la venta.

1. **Proveedores e Inventario** registran proveedores, productos y lotes (con fecha de vencimiento y cantidad). Un proceso diario de Inventario marca como `Proximo a Vencer` los lotes con 7 dias o menos.
2. **Ventas** lista los lotes vendibles y arma el pedido de un cliente. Al confirmar, guarda la venta (estado `Registrada`) y descuenta la cantidad del lote, todo en una sola transaccion.
3. **Facturacion**: apenas se confirma la venta se genera la factura PDF. Si la factura fallara, la venta ya quedo guardada y se puede generar despues desde el menu Facturacion sin duplicarla (una factura por venta).
4. **Pasar a preparacion**: en Ventas, opcion 3, la venta pasa de `Registrada` a `En Preparacion`.
5. **Logistica** solo ve las ventas `En Preparacion`. Con ellas crea una ruta, le asigna vehiculo y conductor, inicia el despacho (`En Transito`) y confirma cada entrega (`Entregada`).

## Reglas de negocio importantes

- **Lotes vendibles:** solo se ofrecen lotes `Disponible` o `Proximo a Vencer`, con existencias y sin vencer. Nunca se venden lotes `Vencido`, `En Cuarentena` o `Rechazado`. El enunciado pide mostrar solo lotes `Available` y, a la vez, aplicar descuento a los `Near Expiry`; se resolvio vendiendo ambos estados, porque un lote proximo a vencer sigue siendo apto para la venta y es justo el que la promocion busca rotar.
- **FEFO:** los lotes se muestran ordenados por fecha de vencimiento, primero los que vencen antes.
- **Descuento:** se toma de la promocion activa y vigente (`promociones.tasa_descuento`) y solo se aplica a lotes `Proximo a Vencer`.
- **Impuesto (IVA):** ni el esquema ni el enunciado definen una tarifa. La tasa es un valor de **demostracion**, 0 por defecto, definido en `ControladorVentas.TASA_IMPUESTO`. Se puede probar otra al ejecutar con `-Derp.tasaImpuesto=0.10` (fraccion entre 0 y 1). **Debe confirmarse la tarifa real con el negocio antes de usarla.**
- **Factura:** es una factura de **demostracion**. El CUFE y el QR son simulados y el documento no tiene validez fiscal ante la DIAN. El NIT de la empresa sale de la tabla `informacion_empresa`.
- **Proveedor 33:** en los datos de prueba generados con ayuda de IA, el proveedor con `id_proveedor = 33` lleva el NIT marcador `SYN-FT-900427-AG`, como lo exige el enunciado. Es un dato sintetico, no un NIT real.

## Principios y patrones de diseno

**MVC por componentes y DAO.** Cada modulo separa la vista de consola (`view`), la logica y las validaciones (`controller`) y las entidades (`model`). Las consultas SQL viven solo en las clases DAO (por ejemplo `VentasDao`, `FacturaDao`, `LogisticaDao`), de modo que el resto del codigo no depende de SQL. Asi un cambio en una consulta toca una sola clase.

**Inyeccion de la conexion y Singleton.** `DatabaseConnection` (paquete `common`) entrega una unica conexion y los menus se la pasan por constructor a los DAO. Los DAO no abren conexiones propias, lo que evita duplicarlas y permite manejar transacciones: registrar una venta, iniciar un despacho o confirmar una entrega se hacen con `commit` y, si algo falla, `rollback`.

**Responsabilidad unica y entidades inmutables.** Las entidades sencillas son `record` de Java (`Customer`, `Lote`, `Factura`...), y cada clase hace una sola cosa: `FacturaPdf` solo dibuja el PDF y `ControladorFacturacion` coordina su creacion.
