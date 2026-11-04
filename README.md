# ERP para la Bodega de Alimentos "Frescura Total"

## Descripción

El ERP para la Bodega de Alimentos "Frescura Total" es un sistema de consola desarrollado en Java 17 y MySQL, diseñado para organizar y optimizar el día a día de una bodega de alimentos perecederos. El proyecto soluciona los problemas habituales del manejo manual con papel y hojas de cálculo: falta de control del inventario, pérdidas económicas por productos que se vencen en los estantes y desorden en el despacho de pedidos. Para resolverlo, el sistema conecta todo el flujo comercial en una sola herramienta: gestiona proveedores y productos, controla lotes priorizando la salida de los más próximos a vencer mediante la regla FEFO (*First Expired, First Out*), aplica promociones automáticas para rotar inventario, emite facturas en PDF con código QR y coordina la logística de entrega asignando pedidos a rutas, vehículos y conductores.

---

## Autores

* **Santiago Becerra**
* **Cristian Solano**

---

## Requerimientos Previos

Para configurar y ejecutar el proyecto en su equipo local necesita:

* **Java Development Kit (JDK):** Versión 17 o superior.
* **Apache NetBeans IDE:** Versión 12 o superior (compatible con proyectos Maven).
* **MySQL Server:** Versión 8.0 o superior en ejecución local.
* **Apache Maven:** Versión 3.6 o superior (NetBeans ya incluye Maven por defecto).

Las librerías externas necesarias se descargan de forma automática a través del archivo `pom.xml`:
* **MySQL Connector/J:** Conector JDBC para la comunicación con la base de datos.
* **OpenPDF:** Generación y maquetación de facturas en formato PDF.
* **ZXing Core:** Generación de códigos QR incluidos en las facturas.

---

## Configuración de la Base de Datos

### 1. Creación y carga de datos

El proyecto utiliza un único script maestro ubicado en **`docs/database.sql`**, el cual se encarga de crear todas las tablas (DDL) y cargar los catálogos y datos iniciales de prueba (DML).

Para configurarla en su MySQL local, siga estos pasos:

1. Asegúrese de que el servicio local de MySQL esté en ejecución.
2. Abra su herramienta preferida (MySQL Workbench, DBeaver o la consola de MySQL).
3. Ejecute el script **`docs/database.sql`**:
   * **Desde la terminal:**
     ```bash
     mysql -u root -p < docs/database.sql
     ```
   * **Desde MySQL Workbench:**
     * Vaya a `File` > `Open SQL Script...` y abra `docs/database.sql`.
     * Ejecute todo el script haciendo clic en el ícono del rayo (*Execute*).

> **Importante:** El script comienza con `DROP DATABASE IF EXISTS erp_frescura_total;`, por lo que creará una base de datos limpia con todas sus tablas y datos de prueba listos para usar.

### 2. Configuración de credenciales en el código

La conexión se administra de forma centralizada en la clase:
[`DatabaseConnection.java`](src/main/java/com/frescuratotal/erp/common/DatabaseConnection.java)

Abra el archivo y ajuste las constantes `URL`, `USER` y `PASSWORD` con los datos de su entorno local (por ejemplo, si su puerto es 3306, 3307 o 3308):

```java
package com.frescuratotal.erp.common;

public class DatabaseConnection {

    // Ajuste el puerto y el nombre de la base de datos según su instalación
    private static final String URL = "jdbc:mysql://localhost:3306/erp_frescura_total";
    
    // Usuario de MySQL
    private static final String USER = "root";
    
    // Contraseña de su usuario de MySQL
    private static final String PASSWORD = "su_contrasena";

    // ...
}
```

### 3. Documentación y recursos de apoyo

En el directorio **`docs/`** se encuentran los documentos y recursos complementarios del proyecto:
* **`docs/database.sql`:** Script SQL con la definición del esquema DDL y la población inicial de datos DML.
* **`docs/erp_frescura_total.png`:** Diagrama del modelo entidad-relación (DER) de la base de datos.
* **`docs/guia_exposicion_proyecto.pdf`:** Guía detallada para la sustentación y exposición del proyecto.

---

## Instalación y Ejecución

### Opción 1: Desde Apache NetBeans IDE

1. **Clonar el repositorio:**  
   Abra la terminal o su cliente Git y clone el proyecto:
   ```bash
   git clone https://github.com/SantiagoBecerraV/Frescura_total_java_Becerra_Solano.git
   ```
2. **Abrir el proyecto en NetBeans:**  
   * Abra NetBeans y vaya a `File` > `Open Project...`.
   * Seleccione la carpeta `FrescuraTotal` (el IDE la reconocerá automáticamente como un proyecto Maven).
3. **Compilar el proyecto:**  
   * En el menú superior, haga clic en `Run` > `Clean and Build Project` (o use el atajo `Shift + F11`). NetBeans descargará las dependencias y compilará el código.
4. **Ejecutar la aplicación:**  
   * En el menú superior, haga clic en `Run` > `Run Project` (o presione la tecla `F6`).
   * La aplicación iniciará y mostrará el menú principal en la consola de NetBeans.

### Opción 2: Desde la terminal

También puede compilar y ejecutar el proyecto directamente por consola:

1. **Compilar y ejecutar con Maven:**
   ```bash
   mvn clean compile
   mvn compile exec:java
   ```
2. **Ejecutar mediante el archivo `.jar` empaquetado:**  
   Genere el archivo empaquetado con:
   ```bash
   mvn clean package
   ```
   Y luego ejecútelo desde la carpeta de salida generada (`target/` o `dist/`):
   ```bash
   java -jar target/FrescuraTotal-1.0-SNAPSHOT.jar
   ```

> **Nota:** Las facturas PDF generadas por el sistema se guardan automáticamente en la carpeta `facturas/`, ubicada en la raíz del proyecto.

---

## Estructura del Proyecto

El sistema está organizado bajo una arquitectura **MVC por componentes funcionales**. En lugar de tener paquetes gigantes donde se mezclan modelos o controladores de todo el sistema, cada módulo de negocio (`inventory`, `suppliers`, `sales`, `common`) agrupa sus propios modelos, vistas, controladores y clases de acceso a datos (DAO):

```text
src/main/java/com/frescuratotal/erp/
├── common/                  # Infraestructura común, tablas de consola y conexión a base de datos
│   ├── ConsoleTable.java
│   └── DatabaseConnection.java
├── inventory/               # Gestión de productos, lotes, calidad y trazabilidad
│   ├── controller/          # ProductController, LotController
│   ├── model/               # Product, Lot, LotStatus, ProductDao, LotDao, QualityDao, TraceabilityDao
│   └── view/                # ProductView, LotView
├── suppliers/               # Gestión de proveedores y catálogo de compras
│   ├── controller/          # SupplierController
│   ├── model/               # Supplier, SupplierDao
│   └── view/                # SupplierView
├── sales/                   # Clientes, ventas, facturación y logística de entrega
│   ├── controller/          # SalesController, BillingController, LogisticsController, CustomerController
│   ├── dao/                 # SalesDao, InvoiceDao, LogisticsDao, CustomerDao
│   ├── model/               # Customer, Driver, Invoice, OrderLine, RegisteredSale, Route, RouteDelivery, RouteStatus, SaleInPreparation, SalesLot, SaleStatus, Vehicle, VehicleStatus
│   └── view/                # SalesMenu, BillingMenu, InvoicePdf, LogisticsMenu, CustomerMenu
└── Main.java                # Punto de entrada de la aplicación y menú principal
```

### Resumen de módulos y responsabilidades:

| Módulo | Controladores | Acceso a Datos (DAO) | Modelos Principales | Vistas / Salidas |
| :--- | :--- | :--- | :--- | :--- |
| **Productos e Inventario** | `ProductController`, `LotController` | `ProductDao`, `LotDao`, `QualityDao`, `TraceabilityDao` | `Product`, `Lot`, `LotStatus` | `ProductView`, `LotView` |
| **Proveedores** | `SupplierController` | `SupplierDao` | `Supplier` | `SupplierView` |
| **Clientes** | `CustomerController` | `CustomerDao` | `Customer` | `CustomerMenu` |
| **Ventas** | `SalesController` | `SalesDao` | `SalesLot`, `OrderLine`, `RegisteredSale` | `SalesMenu` |
| **Facturación** | `BillingController` | `InvoiceDao` | `Invoice` | `BillingMenu`, `InvoicePdf` |
| **Logística** | `LogisticsController` | `LogisticsDao` | `Vehicle`, `Driver`, `Route`, `RouteDelivery` | `LogisticsMenu` |

### Flujo del negocio:
Los módulos no se acoplan directamente entre sí, sino que colaboran mediante los estados del pedido en la base de datos:
1. **Inventario** registra los lotes y actualiza los que están próximos a vencer mediante alertas y pre-alertas de vencimiento.
2. **Ventas** consulta lotes disponibles o próximos a vencer (ordenados por fecha bajo la regla FEFO), descuenta el inventario y crea la venta en estado `Registrada`.
3. **Facturación** genera la factura PDF con QR en la venta. Si se requiere, permite reimprimirla sin duplicar ventas.
4. **Preparación y Logística:** la venta pasa a estado `En Preparación`, permitiendo a Logística armar rutas de entrega, asignar vehículo y chofer, pasar a `En Tránsito` y finalmente marcarla como `Entregada`.

---

## Principios y Patrones de Diseño

Para mantener el código ordenado, mantenible y fácil de entender, aplicamos los siguientes principios y patrones:

### 1. Patrón DAO (Data Access Object)
Reunimos todas las consultas SQL y el manejo de JDBC en clases especializadas como `SalesDao`, `InvoiceDao`, `CustomerDao`, `LogisticsDao`, `ProductDao`, `LotDao`, `QualityDao`, `TraceabilityDao` y `SupplierDao`. De esta manera, los controladores y las vistas nunca escriben ni conocen sentencias SQL, sino que únicamente reciben y manipulan objetos del dominio. Si el día de mañana se cambia la estructura de una tabla o se optimiza un índice, solo debemos modificar el archivo DAO correspondiente sin alterar la lógica de negocio ni la interfaz de usuario.

### 2. Patrón Singleton y Gestión de Recursos
Al inicio pensamos en abrir una conexión por operación, pero nos dimos cuenta de que no solo saturaba el servidor MySQL innecesariamente en una aplicación monousuario, sino que además nos impedía coordinar transacciones seguras con confirmaciones y cancelaciones. Por esa razón decidimos implementar el patrón Singleton en la clase `DatabaseConnection` (`com.frescuratotal.erp.common`), protegiendo su constructor como privado y ofreciendo un único punto de acceso global mediante el método estático sincronizado `getConnection()`. Adicionalmente, se incluye el método `close()` y un `ShutdownHook` en `Main` para asegurar el cierre ordenado de la conexión al terminar la aplicación.

### 3. Principio de Responsabilidad Única (SRP)
Al momento de diseñar el módulo de facturación, decidimos no recargar una sola clase con todo el proceso. Preferimos repartir el trabajo en componentes con una única tarea bien definida: `InvoicePdf` se encarga exclusivamente de maquetar el documento visual y generar la imagen del código QR con OpenPDF y ZXing; `InvoiceDao` se limita a consultar y registrar los datos de la factura en MySQL; y `BillingController` orquesta el flujo de negocio sin meterse en detalles de diseño visual ni en código SQL. Con esta separación, si queremos cambiar los estilos, colores o fuentes del PDF, lo hacemos directamente en `InvoicePdf` con la total tranquilidad de que no afectaremos el cálculo de totales ni la persistencia de las ventas.

### 4. Inversión de Dependencias y Manejo Transaccional
En lugar de que cada DAO o controlador cree su propia conexión de forma rígida, diseñamos las clases para que reciban la conexión activa mediante sus constructores (por ejemplo, `new SalesDao(connection)` o `new LogisticsDao(connection)`). Esta decisión desacopló las clases del origen de datos y nos permitió manejar transacciones atómicas en operaciones compuestas: al registrar una venta, insertamos el encabezado, registramos el detalle y descontamos las existencias del lote bajo una misma unidad de trabajo con `commit`, garantizando que ante cualquier error inesperado se ejecute un `rollback` automático y la base de datos nunca quede en un estado inconsistente.

### 5. Programación Funcional y Streams (Java 17)
Se aprovechan las características modernas de Java para escribir código más conciso, declarativo y legible:
* **Stream API:** Búsqueda funcional en enums (`Arrays.stream(values()).filter(...).findFirst()`) en `LotStatus`, `RouteStatus` y `VehicleStatus`; cálculo de acumulados de venta (subtotales, impuestos y totales) mediante `.map(...).reduce(...)` en `SalesDao`; y formateo dinámico de tablas en `ConsoleTable` usando `IntStream`.
* **Lambdas y Referencias a Métodos:** Navegación por menú desacoplada mediante mapas de acciones funcionales (`Map<String, MenuAction>` y `Map<Integer, Runnable>`) en `Main` y en las vistas, además del uso de interfaces funcionales para operaciones transaccionales (`SqlLineAction` en `SalesDao` con `allMatch`).

---

## Nota del equipo

* **Credenciales de base de datos:** Las credenciales que figuran en el código de ejemplo (`Campus2026` o `su_contrasena` en los puertos `3306`, `3307` o `3308`) son referencias utilizadas durante las pruebas locales del equipo. Cada usuario debe verificar y ajustar su usuario, contraseña y puerto según su propia instalación local de MySQL.
* **Facturación electrónica simulada:** Los valores de CUFE y el código QR generados en los archivos PDF son simulaciones creadas con fines estrictamente académicos y demostrativos; no representan documentos fiscales oficiales ante la DIAN.
* **Generación automática de carpetas:** No es necesario crear la carpeta `facturas/` manualmente antes de iniciar el programa; la aplicación detecta si el directorio existe y lo crea de forma automática en la raíz del proyecto cuando se genera la primera factura.
* **Tasa de impuesto (IVA):** Para facilitar las pruebas de demostración, el sistema utiliza una tasa inicial de 0 en `SalesController.TAX_RATE`. Si se desea probar con un porcentaje específico de IVA, puede pasarse como propiedad de ejecución (por ejemplo `-Derp.tasaImpuesto=0.10`).
