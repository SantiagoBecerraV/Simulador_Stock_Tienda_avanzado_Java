DROP DATABASE IF EXISTS erp_frescura_total;
CREATE DATABASE erp_frescura_total CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE erp_frescura_total;

-- TABLAS DE CATÁLOGO (LOOKUP TABLES)

CREATE TABLE estados_lote (
    id_estado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

CREATE TABLE tipos_cliente (
    id_tipo INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

CREATE TABLE estados_venta (
    id_estado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

-- INFORMACIÓN DE LA EMPRESA

CREATE TABLE informacion_empresa (
    id_empresa INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(255) NOT NULL,
    nit VARCHAR(20) NOT NULL UNIQUE,
    direccion TEXT NOT NULL,
    ciudad VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(100)
) ENGINE=InnoDB;

-- MÓDULO: PROVEEDORES

CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    nit VARCHAR(20) NOT NULL UNIQUE,
    persona_contacto VARCHAR(100),
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- MÓDULO: PRODUCTOS

CREATE TABLE categorias_producto (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT
) ENGINE=InnoDB;

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    id_categoria INT NOT NULL,
    unidad_medida VARCHAR(20) NOT NULL COMMENT 'Ej: kg, litro, unidad',
    precio_base DECIMAL(10, 2),
    FOREIGN KEY (id_categoria) REFERENCES categorias_producto(id_categoria)
) ENGINE=InnoDB;

CREATE TABLE productos_proveedor (
    id_proveedor INT NOT NULL,
    id_producto INT NOT NULL,
    PRIMARY KEY (id_proveedor, id_producto),
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor) ON DELETE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto) ON DELETE CASCADE
) ENGINE=InnoDB;

-- MÓDULO: INVENTARIO Y CALIDAD

CREATE TABLE lotes_inventario (
    id_lote INT AUTO_INCREMENT PRIMARY KEY,
    numero_lote VARCHAR(50) NOT NULL UNIQUE,
    id_producto INT NOT NULL,
    id_proveedor INT NOT NULL,
    fecha_ingreso DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_vencimiento DATE NOT NULL,
    cantidad_inicial DECIMAL(10, 2) NOT NULL,
    cantidad DECIMAL(10, 2) NOT NULL,
    precio_compra DECIMAL(10, 2) NOT NULL,
    precio_venta DECIMAL(10, 2) NOT NULL,
    pasillo VARCHAR(50),
    estante VARCHAR(50),
    id_estado INT NOT NULL,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor),
    FOREIGN KEY (id_estado) REFERENCES estados_lote(id_estado),
    INDEX idx_fecha_vencimiento (fecha_vencimiento),
    INDEX idx_estado (id_estado),
    INDEX idx_producto (id_producto)
) ENGINE=InnoDB;

CREATE TABLE registro_cuarentena (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT NOT NULL,
    motivo TEXT NOT NULL,
    usuario VARCHAR(100) NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resuelta BOOLEAN DEFAULT FALSE,
    fecha_resolucion DATETIME NULL,
    notas_resolucion TEXT,
    FOREIGN KEY (id_lote) REFERENCES lotes_inventario(id_lote),
    INDEX idx_resuelta (resuelta)
) ENGINE=InnoDB;

CREATE TABLE inspecciones_calidad (
    id_inspeccion INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT NOT NULL,
    fecha_inspeccion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resultado ENUM('Aprobado', 'Rechazado') NOT NULL,
    nombre_inspector VARCHAR(100) NOT NULL,
    motivo_rechazo TEXT COMMENT 'Motivo detallado si el resultado es Rechazado',
    notas TEXT,
    FOREIGN KEY (id_lote) REFERENCES lotes_inventario(id_lote),
    INDEX idx_resultado (resultado)
) ENGINE=InnoDB;

CREATE TABLE registro_mermas (
    id_registro INT AUTO_INCREMENT PRIMARY KEY,
    id_lote INT NOT NULL,
    id_inspeccion INT COMMENT 'Inspección que generó esta merma (si aplica)',
    cantidad_perdida DECIMAL(10, 2) NOT NULL,
    motivo TEXT NOT NULL,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usuario_registro VARCHAR(100),
    FOREIGN KEY (id_lote) REFERENCES lotes_inventario(id_lote),
    FOREIGN KEY (id_inspeccion) REFERENCES inspecciones_calidad(id_inspeccion) ON DELETE SET NULL,
    INDEX idx_fecha (fecha_registro)
) ENGINE=InnoDB;

-- MÓDULO: PROMOCIONES

CREATE TABLE promociones (
    id_promocion INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    descripcion TEXT,
    tasa_descuento DECIMAL(5, 2) NOT NULL COMMENT 'Ej: 0.50 para 50%',
    aplica_estado_lote INT,
    aplica_categoria_producto INT,
    activa BOOLEAN DEFAULT TRUE,
    fecha_inicio DATE,
    fecha_fin DATE,
    FOREIGN KEY (aplica_estado_lote) REFERENCES estados_lote(id_estado),
    FOREIGN KEY (aplica_categoria_producto) REFERENCES categorias_producto(id_categoria),
    INDEX idx_activa (activa)
) ENGINE=InnoDB;

-- MÓDULO: CLIENTES Y VENTAS

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    documento VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100),
    telefono VARCHAR(20),
    direccion TEXT,
    id_tipo INT NOT NULL,
    fecha_registro DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_tipo) REFERENCES tipos_cliente(id_tipo)
) ENGINE=InnoDB;

CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    numero_venta VARCHAR(50) NOT NULL UNIQUE,
    id_cliente INT NOT NULL,
    fecha_venta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) NOT NULL,
    total_descuento DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    total_impuesto DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    monto_total DECIMAL(12, 2) NOT NULL,
    id_estado INT NOT NULL,
    usuario_registro VARCHAR(100) COMMENT 'Usuario que registró la venta',
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_estado) REFERENCES estados_venta(id_estado),
    INDEX idx_estado (id_estado),
    INDEX idx_fecha (fecha_venta)
) ENGINE=InnoDB;

CREATE TABLE detalles_venta (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_lote INT NOT NULL,
    cantidad_vendida DECIMAL(10, 2) NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    descuento_aplicado DECIMAL(5, 2) DEFAULT 0.00,
    monto_descuento DECIMAL(10, 2) DEFAULT 0.00,
    tasa_impuesto DECIMAL(5, 2) DEFAULT 0.00,
    monto_impuesto DECIMAL(10, 2) DEFAULT 0.00,
    subtotal DECIMAL(10, 2) NOT NULL,
    total_linea DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta) ON DELETE CASCADE,
    FOREIGN KEY (id_lote) REFERENCES lotes_inventario(id_lote)
) ENGINE=InnoDB;

CREATE TABLE facturas (
    id_factura INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    numero_factura VARCHAR(50) NOT NULL UNIQUE,
    cufe VARCHAR(255) NOT NULL UNIQUE COMMENT 'Código simulado para factura electrónica',
    enlace_qr VARCHAR(255) COMMENT 'URL o datos para generar código QR',
    fecha_emision DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) NOT NULL,
    total_descuento DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    monto_impuesto DECIMAL(12, 2) NOT NULL,
    monto_total DECIMAL(12, 2) NOT NULL,
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    INDEX idx_numero (numero_factura)
) ENGINE=InnoDB;

-- MÓDULO: LOGÍSTICA Y ENTREGAS

CREATE TABLE conductores (
    id_conductor INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    numero_licencia VARCHAR(50) NOT NULL UNIQUE,
    telefono VARCHAR(20),
    email VARCHAR(100),
    activo BOOLEAN DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE vehiculos (
    id_vehiculo INT AUTO_INCREMENT PRIMARY KEY,
    placa VARCHAR(20) NOT NULL UNIQUE,
    modelo VARCHAR(100),
    capacidad DECIMAL(10, 2) COMMENT 'Capacidad en kg o unidades',
    estado ENUM('Activo', 'Inactivo', 'Mantenimiento') DEFAULT 'Activo'
) ENGINE=InnoDB;

CREATE TABLE rutas_entrega (
    id_ruta INT AUTO_INCREMENT PRIMARY KEY,
    nombre_ruta VARCHAR(255) NOT NULL,
    fecha_creacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_creacion VARCHAR(100) COMMENT 'Usuario logístico que creó la ruta',
    hora_salida_estimada DATETIME,
    hora_llegada_estimada DATETIME,
    hora_salida_real DATETIME,
    hora_llegada_real DATETIME,
    estado ENUM('Planificada', 'En Transito', 'Completada', 'Cancelada') DEFAULT 'Planificada',
    INDEX idx_estado (estado),
    INDEX idx_fecha_creacion (fecha_creacion)
) ENGINE=InnoDB;

CREATE TABLE asignaciones_entrega (
    id_asignacion INT AUTO_INCREMENT PRIMARY KEY,
    id_ruta INT NOT NULL,
    id_vehiculo INT NOT NULL,
    id_conductor INT NOT NULL,
    fecha_asignacion DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_asignacion VARCHAR(100) COMMENT 'Usuario que realizó la asignación',
    notas TEXT,
    FOREIGN KEY (id_ruta) REFERENCES rutas_entrega(id_ruta),
    FOREIGN KEY (id_vehiculo) REFERENCES vehiculos(id_vehiculo),
    FOREIGN KEY (id_conductor) REFERENCES conductores(id_conductor),
    INDEX idx_ruta (id_ruta)
) ENGINE=InnoDB;

CREATE TABLE ventas_ruta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_ruta INT NOT NULL,
    id_venta INT NOT NULL,
    orden_entrega INT COMMENT 'Orden de entrega en la ruta',
    direccion_destino TEXT NOT NULL,
    fecha_entrega DATETIME,
    recibido_por VARCHAR(255),
    observaciones TEXT,
    FOREIGN KEY (id_ruta) REFERENCES rutas_entrega(id_ruta),
    FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
    UNIQUE KEY (id_ruta, id_venta),
    INDEX idx_ruta (id_ruta),
    INDEX idx_venta (id_venta)
) ENGINE=InnoDB;


-- SECCION 2: Datos de prueba
USE erp_frescura_total;

-- 2.1 Catalogos y datos de la empresa (vienen del script original del proyecto)
-- El orden de estados_lote importa: el enum LotStatus del codigo Java usa los ids 1 a 5.
-- 'Rechazado' (id 5) NO estaba en el script original. Se agrega porque LotController
-- pasa el lote a LotStatus.REJECTED (id 5) cuando el inspector lo rechaza; sin esta fila
-- la llave foranea de lotes_inventario.id_estado falla.
INSERT INTO estados_lote (nombre, descripcion) VALUES
('Disponible', 'Lote disponible para venta'),
('Proximo a Vencer', 'Lote próximo a vencer (7 días o menos)'),
('Vencido', 'Lote vencido, no apto para venta'),
('En Cuarentena', 'Lote en cuarentena pendiente de inspección'),
('Rechazado', 'Lote rechazado por el inspector de calidad, dado de baja como merma')
ON DUPLICATE KEY UPDATE nombre = nombre;

INSERT INTO tipos_cliente (nombre, descripcion) VALUES
('Mayorista', 'Cliente que compra en grandes cantidades'),
('Minorista', 'Cliente que compra en pequeñas cantidades')
ON DUPLICATE KEY UPDATE nombre = nombre;

INSERT INTO estados_venta (nombre, descripcion) VALUES
('Registrada', 'Venta registrada, pendiente de preparación'),
('En Preparacion', 'Pedido en preparación para despacho'),
('En Transito', 'Pedido en tránsito hacia el cliente'),
('Entregada', 'Pedido entregado al cliente'),
('Cancelada', 'Venta cancelada')
ON DUPLICATE KEY UPDATE nombre = nombre;

INSERT INTO informacion_empresa (nombre_empresa, nit, direccion, ciudad, telefono, email) VALUES
('Frescura Total S.A.S.', '900123456-7', 'Calle 123 #45-67', 'Bogotá', '(601) 234-5678', 'contacto@frescuratotal.com')
ON DUPLICATE KEY UPDATE nit = nit;

INSERT INTO categorias_producto (nombre, descripcion) VALUES
('Frutas', 'Frutas frescas'),
('Verduras', 'Verduras y hortalizas'),
('Lacteos', 'Productos lácteos'),
('Carnes', 'Carnes y derivados'),
('Granos', 'Granos y cereales'),
('Bebidas', 'Bebidas y líquidos'),
('Enlatados', 'Productos enlatados'),
('Panaderia', 'Productos de panadería')
ON DUPLICATE KEY UPDATE nombre = nombre;

-- 2.2 Proveedores (50)
-- Datos de prueba creados con ayuda de IA; las empresas y sus contactos son ficticios.
-- NIT del proveedor 33 indicado para el proyecto: 800084744-5.
-- Los proveedores 8 y 45 estan inactivos.
INSERT INTO proveedores (id_proveedor, nombre, nit, persona_contacto, email, telefono, direccion, activo, fecha_registro) VALUES
(1, 'Agricola La Esperanza S.A.S.', '900079560-8', 'Martha Lucia Pineda', 'ventas@agricolaesperanza.example.com', '316 845 3611', 'Vereda El Salitre km 4, Fusagasuga', TRUE, '2026-07-08 15:04:00'),
(2, 'Frutales del Tolima Ltda.', '800809349-0', 'Hernan Dario Ospina', 'ventas@frutalestolima.example.com', '350 865 4325', 'Carrera 5 # 18-42, Ibague', TRUE, '2026-08-19 14:54:00'),
(3, 'Cooperativa Fruticola de Lebrija', '900656873-3', 'Jairo Cardenas', 'ventas@cooperativafruticolalebrija.example.com', '317 397 4050', 'Calle 9 # 6-20, Lebrija, Santander', TRUE, '2026-08-15 14:57:00'),
(4, 'Hacienda San Isidro Frutas S.A.S.', '900847669-7', 'Paola Andrea Rincon', 'ventas@haciendasanisidro.example.com', '317 806 6307', 'Vereda Granada, Silvania', TRUE, '2026-07-13 16:33:00'),
(5, 'Distribuidora Frutas del Valle', '800674142-1', 'Oscar Ivan Mejia', 'ventas@distribuidorafrutasvalle.example.com', '311 305 2207', 'Calle 13 # 22-60, Palmira', TRUE, '2026-08-03 08:03:00'),
(6, 'Aguacates de Caldas S.A.S.', '800488223-2', 'Luz Adriana Giraldo', 'ventas@aguacatescaldas.example.com', '315 780 9928', 'Carrera 8 # 14-35, Aguadas', TRUE, '2026-07-05 15:20:00'),
(7, 'Frutos de Guasca', '901766047-1', 'Diego Fernando Bermudez', 'ventas@frutosguasca.example.com', '323 814 2956', 'Vereda La Trinidad, Guasca', TRUE, '2026-08-12 11:48:00'),
(8, 'Huerta Frutal del Meta', '901536749-7', 'Sandra Milena Rojas', 'ventas@huertafrutalmeta.example.com', '323 810 2622', 'Km 12 via Puerto Lopez, Villavicencio', FALSE, '2026-07-19 16:54:00'),
(9, 'Comercializadora Tropical Andina', '900467517-5', 'Camilo Andres Rueda', 'ventas@comercializadoratropicalandina.example.com', '323 327 5692', 'Bodega 21 Corabastos, Bogota', TRUE, '2026-08-11 10:42:00'),
(10, 'Hortalizas de la Sabana S.A.S.', '901294577-7', 'Gloria Ines Torres', 'ventas@hortalizassabana.example.com', '315 322 8843', 'Vereda Chuntame, Cajica', TRUE, '2026-08-15 08:23:00'),
(11, 'Cultivos Tenjo Verde', '890180648-2', 'Ricardo Alonso Moreno', 'ventas@cultivostenjoverde.example.com', '321 932 6704', 'Vereda Chacal, Tenjo', TRUE, '2026-07-22 17:00:00'),
(12, 'Papas y Tuberculos de Boyaca', '890153904-9', 'Edgar Humberto Pulido', 'ventas@papastuberculosboyaca.example.com', '316 289 4761', 'Carrera 11 # 20-18, Tunja', TRUE, '2026-07-29 15:08:00'),
(13, 'Agroindustrial Ventaquemada', '860287836-2', 'Nelson Enrique Sierra', 'ventas@agroindustrialventaquemada.example.com', '310 474 5925', 'Vereda Puente de Boyaca, Ventaquemada', TRUE, '2026-07-06 10:46:00'),
(14, 'Huertas Organicas de Subachoque', '860760410-7', 'Natalia Becerra', 'ventas@huertasorganicassubachoque.example.com', '350 351 5203', 'Vereda La Pradera, Subachoque', TRUE, '2026-07-30 16:29:00'),
(15, 'Cebollas de Aquitania S.A.S.', '900940316-1', 'Wilson Fernando Avella', 'ventas@cebollasaquitania.example.com', '317 264 2505', 'Calle 6 # 4-11, Aquitania', TRUE, '2026-07-07 10:22:00'),
(16, 'Verduras Frescas Mosquera', '830201040-9', 'Yolanda Patricia Leon', 'ventas@verdurasfrescasmosquera.example.com', '312 542 4042', 'Carrera 3 # 7-55, Mosquera', TRUE, '2026-07-11 15:32:00'),
(17, 'Hidroponicos de Chia', '890058443-9', 'Julian Esteban Cortes', 'ventas@hidroponicoschia.example.com', '315 540 3136', 'Vereda Fagua, Chia', TRUE, '2026-07-19 15:04:00'),
(18, 'Campo Vivo Distribuciones', '900309046-1', 'Angela Maria Suarez', 'ventas@campovivodistribuciones.example.com', '317 827 8101', 'Bodega 34 Corabastos, Bogota', TRUE, '2026-07-23 15:23:00'),
(19, 'Lacteos El Rosal S.A.S.', '900518014-2', 'Fabio Nelson Gutierrez', 'ventas@lacteosrosal.example.com', '317 670 1608', 'Km 3 via Subachoque, El Rosal', TRUE, '2026-08-16 16:37:00'),
(20, 'Lecheria Ubate Ltda.', '800285076-4', 'Maria Teresa Castiblanco', 'ventas@lecheriaubate.example.com', '316 264 2258', 'Carrera 7 # 9-30, Ubate', TRUE, '2026-08-06 08:16:00'),
(21, 'Quesos del Valle de Tenza', '890772722-0', 'Gustavo Adolfo Barrera', 'ventas@quesosvalletenza.example.com', '313 516 6518', 'Calle 4 # 3-12, Guateque', TRUE, '2026-08-07 14:31:00'),
(22, 'Productos Lacteos San Miguel', '800410460-6', 'Claudia Patricia Nino', 'ventas@productoslacteossan.example.com', '321 587 4699', 'Vereda San Miguel, Sopo', TRUE, '2026-07-02 09:24:00'),
(23, 'Cooperativa Lechera de Simijaca', '830827404-3', 'Luis Alberto Forero', 'ventas@cooperativalecherasimijaca.example.com', '322 206 6233', 'Carrera 4 # 6-25, Simijaca', TRUE, '2026-08-09 13:57:00'),
(24, 'Derivados Lacteos La Pradera', '900749366-0', 'Adriana Marcela Leon', 'ventas@derivadoslacteospradera.example.com', '321 658 6815', 'Vereda La Pradera, Tocancipa', TRUE, '2026-07-18 14:33:00'),
(25, 'Granja Lechera Zipaquira', '900227949-4', 'Fernando Augusto Ramirez', 'ventas@granjalecherazipaquira.example.com', '322 857 6548', 'Km 2 via Pacho, Zipaquira', TRUE, '2026-08-01 09:40:00'),
(26, 'Avicola Santa Rita S.A.S.', '901461481-5', 'Jorge Eliecer Vargas', 'ventas@avicolasantarita.example.com', '318 993 6096', 'Km 5 via Girardot, Fusagasuga', TRUE, '2026-08-14 11:32:00'),
(27, 'Carnes Finas del Meta', '830985153-6', 'Rosa Elvira Hernandez', 'ventas@carnesfinasmeta.example.com', '320 905 7619', 'Calle 37 # 30-15, Villavicencio', TRUE, '2026-08-03 12:42:00'),
(28, 'Frigorifico Guadalupe Proveedores', '860733163-8', 'Alvaro Jose Salazar', 'ventas@frigorificoguadalupeproveedores.example.com', '321 518 5947', 'Calle 40 Sur # 68-40, Bogota', TRUE, '2026-08-18 09:51:00'),
(29, 'Porcicola La Cabana', '860876509-6', 'Monica Alejandra Diaz', 'ventas@porcicolacabana.example.com', '312 851 6413', 'Vereda La Cabana, Facatativa', TRUE, '2026-07-15 11:24:00'),
(30, 'Embutidos Santa Rosa de Cabal', '800499772-1', 'Carlos Mario Arango', 'ventas@embutidossantarosa.example.com', '312 259 8175', 'Carrera 14 # 12-60, Santa Rosa de Cabal', TRUE, '2026-08-17 13:54:00'),
(31, 'Pollos El Dorado Ltda.', '800392786-3', 'Liliana Carvajal', 'ventas@pollosdorado.example.com', '317 549 6290', 'Km 8 via Melgar, Girardot', TRUE, '2026-08-01 15:23:00'),
(32, 'Molino Arrocero del Tolima', '800084721-4', 'Ruben Dario Lozano', 'ventas@molinoarrocerotolima.example.com', '350 206 5629', 'Carrera 2 # 10-30, Espinal', TRUE, '2026-08-18 10:50:00'),
(33, 'Granos y Cereales La Cosecha', '800084744-5', 'Beatriz Elena Quintero', 'ventas@granoscerealescosecha.example.com', '350 348 9708', 'Bodega 12 Corabastos, Bogota', TRUE, '2026-08-09 13:33:00'),
(34, 'Legumbres del Huila S.A.S.', '860806132-4', 'Mauricio Andres Polania', 'ventas@legumbreshuila.example.com', '322 660 3368', 'Calle 8 # 5-44, Neiva', TRUE, '2026-07-23 12:53:00'),
(35, 'Comercializadora El Granero', '890755101-5', 'Teresa de Jesus Mora', 'ventas@comercializadoragranero.example.com', '317 782 4524', 'Carrera 19 # 9-70, Bogota', TRUE, '2026-07-26 14:49:00'),
(36, 'Arrocera Llanos Orientales', '901752859-4', 'Javier Alfonso Rey', 'ventas@arrocerallanosorientales.example.com', '321 913 7774', 'Km 6 via Acacias, Villavicencio', TRUE, '2026-07-28 09:47:00'),
(37, 'Jugos Naturales Del Campo', '901810296-7', 'Lina Marcela Ortiz', 'ventas@jugosnaturalescampo.example.com', '316 276 5677', 'Carrera 68 # 13-20, Bogota', TRUE, '2026-07-13 15:26:00'),
(38, 'Embotelladora Agua Clara', '900593488-9', 'Pedro Pablo Rodriguez', 'ventas@embotelladoraaguaclara.example.com', '322 327 9282', 'Calle 17 # 116-30, Bogota', TRUE, '2026-08-10 15:18:00'),
(39, 'Bebidas de la Sabana S.A.S.', '830197843-9', 'Viviana Andrea Pena', 'ventas@bebidassabana.example.com', '310 617 6434', 'Km 1 via Siberia, Cota', TRUE, '2026-07-09 08:02:00'),
(40, 'Refrescos Artesanales Zipa', '901390531-1', 'Andres Felipe Silva', 'ventas@refrescosartesanaleszipa.example.com', '321 852 5282', 'Calle 3 # 8-14, Zipaquira', TRUE, '2026-07-18 14:47:00'),
(41, 'Pulpas y Jugos Tropicales', '890753714-0', 'Ximena Rodriguez', 'ventas@pulpasjugostropicales.example.com', '322 393 6457', 'Carrera 10 # 23-45, Girardot', TRUE, '2026-07-20 16:40:00'),
(42, 'Distribuidora de Conservas Andina', '830693254-8', 'Hector Fabio Restrepo', 'ventas@distribuidoraconservasandina.example.com', '313 848 9287', 'Calle 13 # 65-21, Bogota', TRUE, '2026-08-15 13:45:00'),
(43, 'Enlatados del Caribe S.A.S.', '900712123-8', 'Marisol Gutierrez', 'ventas@enlatadoscaribe.example.com', '322 537 4861', 'Carrera 50 # 72-18, Barranquilla', TRUE, '2026-07-04 11:41:00'),
(44, 'Conservas La Granja', '900396410-0', 'Rafael Antonio Duarte', 'ventas@conservasgranja.example.com', '350 295 4928', 'Calle 80 # 69-40, Bogota', TRUE, '2026-07-01 15:34:00'),
(45, 'Mayorista de Abarrotes El Ahorro', '901702526-3', 'Ana Milena Castillo', 'ventas@mayoristaabarrotesahorro.example.com', '313 653 6636', 'Carrera 30 # 6-50, Bogota', FALSE, '2026-08-14 09:46:00'),
(46, 'Panificadora Santa Clara', '900142625-7', 'Esperanza Rubio', 'ventas@panificadorasantaclara.example.com', '323 262 8595', 'Calle 63 # 24-18, Bogota', TRUE, '2026-08-14 14:25:00'),
(47, 'Almojabanas de Funza', '890017624-1', 'German Alberto Tellez', 'ventas@almojabanasfunza.example.com', '312 742 3464', 'Carrera 12 # 14-09, Funza', TRUE, '2026-07-13 10:01:00'),
(48, 'Arepas La Antioquena', '800419396-3', 'Juan Camilo Restrepo', 'ventas@arepasantioquena.example.com', '321 288 7579', 'Calle 19 # 7-33, Soacha', TRUE, '2026-07-06 12:04:00'),
(49, 'Hornos de la Sabana Ltda.', '890877059-7', 'Olga Lucia Murillo', 'ventas@hornossabana.example.com', '320 667 1153', 'Km 2 via Funza, Mosquera', TRUE, '2026-08-07 10:24:00'),
(50, 'Pan del Dia Distribuciones', '800986205-6', 'Sergio Ivan Camacho', 'ventas@pandiadistribuciones.example.com', '314 517 4165', 'Carrera 50 # 4-22, Bogota', TRUE, '2026-07-14 14:05:00')
ON DUPLICATE KEY UPDATE nit = nit;

-- 2.3 Productos (50). unidad_medida usa los valores que valida ProductController:
--     kg, litro, unidad. precio_base en pesos colombianos.
-- Frutas
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Banano criollo', 'Banano de mesa en racimo', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 2800.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Banano criollo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Mango tommy', 'Mango maduro para jugo y mesa', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 5200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Mango tommy');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Fresa', 'Fresa fresca en canastilla', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 9800.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Fresa');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Mora de castilla', 'Mora para pulpa y jugos', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 7600.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Mora de castilla');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Lulo', 'Lulo de tierra fria', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 6400.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Lulo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Aguacate hass', 'Aguacate hass calibre 18', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 8900.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Aguacate hass');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Maracuya', 'Maracuya amarillo', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 5600.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Maracuya');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Naranja tangelo', 'Naranja para jugo', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'kg', 3200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Naranja tangelo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Pina oro miel', 'Pina golden mediana', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Frutas'), 'unidad', 6500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Pina oro miel');
-- Verduras
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Tomate chonto', 'Tomate chonto maduro', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 3600.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Tomate chonto');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Cebolla cabezona blanca', 'Cebolla cabezona seleccion', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 3200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Cebolla cabezona blanca');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Cebolla larga', 'Cebolla larga junca limpia', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 4100.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Cebolla larga');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Papa pastusa', 'Papa pastusa lavada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 2400.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Papa pastusa');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Papa criolla', 'Papa criolla lavada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 4300.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Papa criolla');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Zanahoria', 'Zanahoria lavada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 2200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Zanahoria');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Lechuga batavia', 'Lechuga batavia hidroponica', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'unidad', 2500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Lechuga batavia');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Pimenton rojo', 'Pimenton rojo grande', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 6200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Pimenton rojo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Brocoli', 'Brocoli fresco', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Verduras'), 'kg', 7200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Brocoli');
-- Lacteos
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Leche entera', 'Leche entera pasteurizada en bolsa de 1 litro', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'litro', 3900.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Leche entera');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Yogur natural', 'Yogur natural sin azucar', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'litro', 8500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Yogur natural');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Queso campesino', 'Queso campesino fresco', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'kg', 18500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Queso campesino');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Queso doble crema', 'Queso doble crema en bloque', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'kg', 24000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Queso doble crema');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Kumis', 'Kumis tradicional', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'litro', 7200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Kumis');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Crema de leche', 'Crema de leche para cocina', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'litro', 14000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Crema de leche');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Cuajada', 'Cuajada fresca', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), 'kg', 16000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Cuajada');
-- Carnes
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Pechuga de pollo', 'Pechuga de pollo refrigerada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Carnes'), 'kg', 16500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Pechuga de pollo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Muslo contramuslo', 'Pierna pernil de pollo refrigerada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Carnes'), 'kg', 11800.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Muslo contramuslo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Carne molida de res', 'Carne molida refrigerada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Carnes'), 'kg', 22000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Carne molida de res');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Lomo de cerdo', 'Lomo de cerdo refrigerado', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Carnes'), 'kg', 21000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Lomo de cerdo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Costilla de res', 'Costilla de res en porciones', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Carnes'), 'kg', 18000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Costilla de res');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Chorizo santarrosano', 'Chorizo artesanal empacado al vacio', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Carnes'), 'kg', 19000.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Chorizo santarrosano');
-- Granos
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Arroz blanco', 'Arroz blanco de primera', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Granos'), 'kg', 4200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Arroz blanco');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Frijol cargamanto', 'Frijol cargamanto rojo', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Granos'), 'kg', 9800.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Frijol cargamanto');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Lenteja', 'Lenteja seleccionada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Granos'), 'kg', 6200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Lenteja');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Garbanzo', 'Garbanzo seleccionado', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Granos'), 'kg', 7400.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Garbanzo');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Maiz pira', 'Maiz pira para crispetas', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Granos'), 'kg', 4600.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Maiz pira');
-- Bebidas
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Jugo de naranja natural', 'Jugo de naranja exprimido sin conservantes', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Bebidas'), 'litro', 7800.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Jugo de naranja natural');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Agua en botella 600 ml', 'Agua potable sin gas', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Bebidas'), 'unidad', 1500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Agua en botella 600 ml');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Bebida de avena', 'Avena liquida refrigerada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Bebidas'), 'litro', 6200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Bebida de avena');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Limonada de panela', 'Limonada de panela refrigerada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Bebidas'), 'litro', 5400.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Limonada de panela');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Jugo de mango', 'Jugo de mango refrigerado', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Bebidas'), 'litro', 7600.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Jugo de mango');
-- Enlatados
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Atun en aceite 170 g', 'Lata de atun lomitos en aceite', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Enlatados'), 'unidad', 5900.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Atun en aceite 170 g');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Maiz tierno en lata', 'Lata de maiz tierno 300 g', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Enlatados'), 'unidad', 4300.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Maiz tierno en lata');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Frijol en lata', 'Lata de frijol antioqueno 300 g', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Enlatados'), 'unidad', 5200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Frijol en lata');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Duraznos en almibar', 'Lata de duraznos en almibar 820 g', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Enlatados'), 'unidad', 8900.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Duraznos en almibar');
-- Panaderia
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Pan tajado blanco', 'Pan tajado de 500 g', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Panaderia'), 'unidad', 6200.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Pan tajado blanco');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Almojabana', 'Almojabana horneada del dia, empacada', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Panaderia'), 'unidad', 1500.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Almojabana');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Pandebono', 'Pandebono empacado', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Panaderia'), 'unidad', 1400.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Pandebono');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Arepa de maiz x 5', 'Paquete de 5 arepas de maiz blanco', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Panaderia'), 'unidad', 4800.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Arepa de maiz x 5');
INSERT INTO productos (nombre, descripcion, id_categoria, unidad_medida, precio_base)
SELECT 'Pan blandito x 10', 'Paquete de 10 panes blanditos', (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Panaderia'), 'unidad', 5600.00
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'Pan blandito x 10');

-- 2.4 Catalogo proveedor - producto (que productos puede suministrar cada proveedor)
INSERT INTO productos_proveedor (id_proveedor, id_producto) VALUES
((SELECT id_proveedor FROM proveedores WHERE nit = '900079560-8'), (SELECT id_producto FROM productos WHERE nombre = 'Banano criollo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900656873-3'), (SELECT id_producto FROM productos WHERE nombre = 'Banano criollo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800809349-0'), (SELECT id_producto FROM productos WHERE nombre = 'Mango tommy')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900847669-7'), (SELECT id_producto FROM productos WHERE nombre = 'Mango tommy')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), (SELECT id_producto FROM productos WHERE nombre = 'Mango tommy')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900656873-3'), (SELECT id_producto FROM productos WHERE nombre = 'Fresa')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800674142-1'), (SELECT id_producto FROM productos WHERE nombre = 'Fresa')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901766047-1'), (SELECT id_producto FROM productos WHERE nombre = 'Fresa')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900847669-7'), (SELECT id_producto FROM productos WHERE nombre = 'Mora de castilla')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), (SELECT id_producto FROM productos WHERE nombre = 'Mora de castilla')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800674142-1'), (SELECT id_producto FROM productos WHERE nombre = 'Lulo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901766047-1'), (SELECT id_producto FROM productos WHERE nombre = 'Lulo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), (SELECT id_producto FROM productos WHERE nombre = 'Aguacate hass')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901536749-7'), (SELECT id_producto FROM productos WHERE nombre = 'Aguacate hass')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901766047-1'), (SELECT id_producto FROM productos WHERE nombre = 'Maracuya')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900467517-5'), (SELECT id_producto FROM productos WHERE nombre = 'Maracuya')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900079560-8'), (SELECT id_producto FROM productos WHERE nombre = 'Naranja tangelo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901536749-7'), (SELECT id_producto FROM productos WHERE nombre = 'Naranja tangelo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800809349-0'), (SELECT id_producto FROM productos WHERE nombre = 'Pina oro miel')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900847669-7'), (SELECT id_producto FROM productos WHERE nombre = 'Pina oro miel')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900467517-5'), (SELECT id_producto FROM productos WHERE nombre = 'Pina oro miel')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901294577-7'), (SELECT id_producto FROM productos WHERE nombre = 'Tomate chonto')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890153904-9'), (SELECT id_producto FROM productos WHERE nombre = 'Tomate chonto')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), (SELECT id_producto FROM productos WHERE nombre = 'Cebolla cabezona blanca')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860287836-2'), (SELECT id_producto FROM productos WHERE nombre = 'Cebolla cabezona blanca')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), (SELECT id_producto FROM productos WHERE nombre = 'Cebolla cabezona blanca')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890153904-9'), (SELECT id_producto FROM productos WHERE nombre = 'Cebolla larga')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860760410-7'), (SELECT id_producto FROM productos WHERE nombre = 'Cebolla larga')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830201040-9'), (SELECT id_producto FROM productos WHERE nombre = 'Cebolla larga')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860287836-2'), (SELECT id_producto FROM productos WHERE nombre = 'Papa pastusa')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), (SELECT id_producto FROM productos WHERE nombre = 'Papa pastusa')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860760410-7'), (SELECT id_producto FROM productos WHERE nombre = 'Papa criolla')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830201040-9'), (SELECT id_producto FROM productos WHERE nombre = 'Papa criolla')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900309046-1'), (SELECT id_producto FROM productos WHERE nombre = 'Papa criolla')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901294577-7'), (SELECT id_producto FROM productos WHERE nombre = 'Zanahoria')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), (SELECT id_producto FROM productos WHERE nombre = 'Zanahoria')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890058443-9'), (SELECT id_producto FROM productos WHERE nombre = 'Zanahoria')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830201040-9'), (SELECT id_producto FROM productos WHERE nombre = 'Lechuga batavia')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900309046-1'), (SELECT id_producto FROM productos WHERE nombre = 'Lechuga batavia')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901294577-7'), (SELECT id_producto FROM productos WHERE nombre = 'Pimenton rojo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890058443-9'), (SELECT id_producto FROM productos WHERE nombre = 'Pimenton rojo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), (SELECT id_producto FROM productos WHERE nombre = 'Brocoli')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860287836-2'), (SELECT id_producto FROM productos WHERE nombre = 'Brocoli')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900309046-1'), (SELECT id_producto FROM productos WHERE nombre = 'Brocoli')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900518014-2'), (SELECT id_producto FROM productos WHERE nombre = 'Leche entera')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890772722-0'), (SELECT id_producto FROM productos WHERE nombre = 'Leche entera')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), (SELECT id_producto FROM productos WHERE nombre = 'Leche entera')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800285076-4'), (SELECT id_producto FROM productos WHERE nombre = 'Yogur natural')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800410460-6'), (SELECT id_producto FROM productos WHERE nombre = 'Yogur natural')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900749366-0'), (SELECT id_producto FROM productos WHERE nombre = 'Yogur natural')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890772722-0'), (SELECT id_producto FROM productos WHERE nombre = 'Queso campesino')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), (SELECT id_producto FROM productos WHERE nombre = 'Queso campesino')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900227949-4'), (SELECT id_producto FROM productos WHERE nombre = 'Queso campesino')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900518014-2'), (SELECT id_producto FROM productos WHERE nombre = 'Queso doble crema')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800410460-6'), (SELECT id_producto FROM productos WHERE nombre = 'Queso doble crema')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900749366-0'), (SELECT id_producto FROM productos WHERE nombre = 'Queso doble crema')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800285076-4'), (SELECT id_producto FROM productos WHERE nombre = 'Kumis')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), (SELECT id_producto FROM productos WHERE nombre = 'Kumis')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900227949-4'), (SELECT id_producto FROM productos WHERE nombre = 'Kumis')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900518014-2'), (SELECT id_producto FROM productos WHERE nombre = 'Crema de leche')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890772722-0'), (SELECT id_producto FROM productos WHERE nombre = 'Crema de leche')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900749366-0'), (SELECT id_producto FROM productos WHERE nombre = 'Crema de leche')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800285076-4'), (SELECT id_producto FROM productos WHERE nombre = 'Cuajada')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900227949-4'), (SELECT id_producto FROM productos WHERE nombre = 'Cuajada')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901461481-5'), (SELECT id_producto FROM productos WHERE nombre = 'Pechuga de pollo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860733163-8'), (SELECT id_producto FROM productos WHERE nombre = 'Pechuga de pollo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800499772-1'), (SELECT id_producto FROM productos WHERE nombre = 'Pechuga de pollo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830985153-6'), (SELECT id_producto FROM productos WHERE nombre = 'Muslo contramuslo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860876509-6'), (SELECT id_producto FROM productos WHERE nombre = 'Muslo contramuslo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860733163-8'), (SELECT id_producto FROM productos WHERE nombre = 'Carne molida de res')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800499772-1'), (SELECT id_producto FROM productos WHERE nombre = 'Carne molida de res')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860876509-6'), (SELECT id_producto FROM productos WHERE nombre = 'Lomo de cerdo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800392786-3'), (SELECT id_producto FROM productos WHERE nombre = 'Lomo de cerdo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901461481-5'), (SELECT id_producto FROM productos WHERE nombre = 'Costilla de res')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860733163-8'), (SELECT id_producto FROM productos WHERE nombre = 'Costilla de res')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800499772-1'), (SELECT id_producto FROM productos WHERE nombre = 'Costilla de res')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830985153-6'), (SELECT id_producto FROM productos WHERE nombre = 'Chorizo santarrosano')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800392786-3'), (SELECT id_producto FROM productos WHERE nombre = 'Chorizo santarrosano')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800084721-4'), (SELECT id_producto FROM productos WHERE nombre = 'Arroz blanco')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860806132-4'), (SELECT id_producto FROM productos WHERE nombre = 'Arroz blanco')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800084744-5'), (SELECT id_producto FROM productos WHERE nombre = 'Frijol cargamanto')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890755101-5'), (SELECT id_producto FROM productos WHERE nombre = 'Frijol cargamanto')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800084744-5'), (SELECT id_producto FROM productos WHERE nombre = 'Lenteja')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860806132-4'), (SELECT id_producto FROM productos WHERE nombre = 'Lenteja')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901752859-4'), (SELECT id_producto FROM productos WHERE nombre = 'Lenteja')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800084721-4'), (SELECT id_producto FROM productos WHERE nombre = 'Garbanzo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '860806132-4'), (SELECT id_producto FROM productos WHERE nombre = 'Garbanzo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890755101-5'), (SELECT id_producto FROM productos WHERE nombre = 'Garbanzo')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800084744-5'), (SELECT id_producto FROM productos WHERE nombre = 'Maiz pira')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890755101-5'), (SELECT id_producto FROM productos WHERE nombre = 'Maiz pira')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901752859-4'), (SELECT id_producto FROM productos WHERE nombre = 'Maiz pira')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), (SELECT id_producto FROM productos WHERE nombre = 'Jugo de naranja natural')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830197843-9'), (SELECT id_producto FROM productos WHERE nombre = 'Jugo de naranja natural')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), (SELECT id_producto FROM productos WHERE nombre = 'Agua en botella 600 ml')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900593488-9'), (SELECT id_producto FROM productos WHERE nombre = 'Agua en botella 600 ml')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901390531-1'), (SELECT id_producto FROM productos WHERE nombre = 'Agua en botella 600 ml')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830197843-9'), (SELECT id_producto FROM productos WHERE nombre = 'Bebida de avena')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890753714-0'), (SELECT id_producto FROM productos WHERE nombre = 'Bebida de avena')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), (SELECT id_producto FROM productos WHERE nombre = 'Limonada de panela')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901390531-1'), (SELECT id_producto FROM productos WHERE nombre = 'Limonada de panela')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900593488-9'), (SELECT id_producto FROM productos WHERE nombre = 'Jugo de mango')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901390531-1'), (SELECT id_producto FROM productos WHERE nombre = 'Jugo de mango')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890753714-0'), (SELECT id_producto FROM productos WHERE nombre = 'Jugo de mango')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830693254-8'), (SELECT id_producto FROM productos WHERE nombre = 'Atun en aceite 170 g')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900396410-0'), (SELECT id_producto FROM productos WHERE nombre = 'Atun en aceite 170 g')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900712123-8'), (SELECT id_producto FROM productos WHERE nombre = 'Maiz tierno en lata')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901702526-3'), (SELECT id_producto FROM productos WHERE nombre = 'Maiz tierno en lata')),
((SELECT id_proveedor FROM proveedores WHERE nit = '830693254-8'), (SELECT id_producto FROM productos WHERE nombre = 'Frijol en lata')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900396410-0'), (SELECT id_producto FROM productos WHERE nombre = 'Frijol en lata')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900712123-8'), (SELECT id_producto FROM productos WHERE nombre = 'Duraznos en almibar')),
((SELECT id_proveedor FROM proveedores WHERE nit = '901702526-3'), (SELECT id_producto FROM productos WHERE nombre = 'Duraznos en almibar')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900142625-7'), (SELECT id_producto FROM productos WHERE nombre = 'Pan tajado blanco')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800419396-3'), (SELECT id_producto FROM productos WHERE nombre = 'Pan tajado blanco')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800986205-6'), (SELECT id_producto FROM productos WHERE nombre = 'Pan tajado blanco')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900142625-7'), (SELECT id_producto FROM productos WHERE nombre = 'Almojabana')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890017624-1'), (SELECT id_producto FROM productos WHERE nombre = 'Almojabana')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), (SELECT id_producto FROM productos WHERE nombre = 'Almojabana')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890017624-1'), (SELECT id_producto FROM productos WHERE nombre = 'Pandebono')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800419396-3'), (SELECT id_producto FROM productos WHERE nombre = 'Pandebono')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800986205-6'), (SELECT id_producto FROM productos WHERE nombre = 'Pandebono')),
((SELECT id_proveedor FROM proveedores WHERE nit = '900142625-7'), (SELECT id_producto FROM productos WHERE nombre = 'Arepa de maiz x 5')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), (SELECT id_producto FROM productos WHERE nombre = 'Arepa de maiz x 5')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890017624-1'), (SELECT id_producto FROM productos WHERE nombre = 'Pan blandito x 10')),
((SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), (SELECT id_producto FROM productos WHERE nombre = 'Pan blandito x 10')),
((SELECT id_proveedor FROM proveedores WHERE nit = '800986205-6'), (SELECT id_producto FROM productos WHERE nombre = 'Pan blandito x 10'))
ON DUPLICATE KEY UPDATE id_producto = id_producto;

-- 2.5 Lotes de inventario
-- numero_lote sigue el formato de LotController: LOT-<id producto>-<id proveedor>-<fecha y hora
-- de recepcion>. Cada lote usa un proveedor que tiene ese producto en productos_proveedor.
-- cantidad = cantidad_inicial - lo vendido (ventas no canceladas) - las mermas registradas.
-- Estados calculados al 2026-11-02:
--   Vencido: fecha_vencimiento anterior al 2026-11-02 (muchos ya se vendieron completos).
--   Proximo a Vencer: vence entre el 2026-11-02 y el 2026-11-09.
--   En Cuarentena / Rechazado: ver la seccion 2.6.
INSERT INTO lotes_inventario (numero_lote, id_producto, id_proveedor, fecha_ingreso, fecha_vencimiento, cantidad_inicial, cantidad, precio_compra, precio_venta, pasillo, estante, id_estado) VALUES
-- Recepciones de agosto de 2026
('LOT-32-34-20260826-054000', (SELECT id_producto FROM productos WHERE nombre = 'Arroz blanco'), (SELECT id_proveedor FROM proveedores WHERE nit = '860806132-4'), '2026-08-26 05:40:00', '2027-08-03', 1110.00, 968.00, 2600.00, 4200.00, 'Pasillo E', 'E-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-28-30-20260827-055000', (SELECT id_producto FROM productos WHERE nombre = 'Carne molida de res'), (SELECT id_proveedor FROM proveedores WHERE nit = '800499772-1'), '2026-08-27 05:50:00', '2026-09-05', 18.00, 0.00, 14300.00, 22000.00, 'Pasillo D', 'D-02', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-22-19-20260827-070000', (SELECT id_producto FROM productos WHERE nombre = 'Queso doble crema'), (SELECT id_proveedor FROM proveedores WHERE nit = '900518014-2'), '2026-08-27 07:00:00', '2026-09-24', 17.00, 0.00, 16800.00, 25200.00, 'Pasillo C', 'C-02', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-24-24-20260827-071500', (SELECT id_producto FROM productos WHERE nombre = 'Crema de leche'), (SELECT id_proveedor FROM proveedores WHERE nit = '900749366-0'), '2026-08-27 07:15:00', '2026-09-18', 20.00, 0.00, 10080.00, 15400.00, 'Pasillo C', 'C-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-18-11-20260827-074000', (SELECT id_producto FROM productos WHERE nombre = 'Brocoli'), (SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), '2026-08-27 07:40:00', '2026-09-05', 24.00, 0.00, 4900.00, 7800.00, 'Pasillo B', 'B-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-43-43-20260827-075000', (SELECT id_producto FROM productos WHERE nombre = 'Maiz tierno en lata'), (SELECT id_proveedor FROM proveedores WHERE nit = '900712123-8'), '2026-08-27 07:50:00', '2028-07-25', 384.00, 48.00, 3100.00, 4500.00, 'Pasillo G', 'G-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-16-18-20260828-054500', (SELECT id_producto FROM productos WHERE nombre = 'Lechuga batavia'), (SELECT id_proveedor FROM proveedores WHERE nit = '900309046-1'), '2026-08-28 05:45:00', '2026-09-07', 30.00, 0.00, 1550.00, 2500.00, 'Pasillo B', 'B-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-3-3-20260828-061500', (SELECT id_producto FROM productos WHERE nombre = 'Fresa'), (SELECT id_proveedor FROM proveedores WHERE nit = '900656873-3'), '2026-08-28 06:15:00', '2026-09-08', 26.00, 0.00, 6370.00, 10300.00, 'Pasillo A', 'A-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-12-12-20260828-061500', (SELECT id_producto FROM productos WHERE nombre = 'Cebolla larga'), (SELECT id_proveedor FROM proveedores WHERE nit = '890153904-9'), '2026-08-28 06:15:00', '2026-09-09', 17.00, 0.00, 2540.00, 4450.00, 'Pasillo B', 'B-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-42-44-20260828-072000', (SELECT id_producto FROM productos WHERE nombre = 'Atun en aceite 170 g'), (SELECT id_proveedor FROM proveedores WHERE nit = '900396410-0'), '2026-08-28 07:20:00', '2028-06-06', 585.00, 282.00, 4250.00, 6200.00, 'Pasillo G', 'G-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-8-1-20260828-074500', (SELECT id_producto FROM productos WHERE nombre = 'Naranja tangelo'), (SELECT id_proveedor FROM proveedores WHERE nit = '900079560-8'), '2026-08-28 07:45:00', '2026-09-22', 75.00, 0.00, 2300.00, 3500.00, 'Pasillo A', 'A-04', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-21-23-20260829-061000', (SELECT id_producto FROM productos WHERE nombre = 'Queso campesino'), (SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), '2026-08-29 06:10:00', '2026-09-13', 14.00, 0.00, 11470.00, 19400.00, 'Pasillo C', 'C-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-9-2-20260829-064000', (SELECT id_producto FROM productos WHERE nombre = 'Pina oro miel'), (SELECT id_proveedor FROM proveedores WHERE nit = '800809349-0'), '2026-08-29 06:40:00', '2026-09-13', 26.00, 0.00, 4420.00, 7150.00, 'Pasillo A', 'A-04', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-38-38-20260829-070000', (SELECT id_producto FROM productos WHERE nombre = 'Agua en botella 600 ml'), (SELECT id_proveedor FROM proveedores WHERE nit = '900593488-9'), '2026-08-29 07:00:00', '2027-08-11', 998.00, 597.00, 980.00, 1600.00, 'Pasillo F', 'F-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-2-6-20260830-051000', (SELECT id_producto FROM productos WHERE nombre = 'Mango tommy'), (SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), '2026-08-30 05:10:00', '2026-09-13', 35.00, 0.00, 3220.00, 5200.00, 'Pasillo A', 'A-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-48-48-20260830-054000', (SELECT id_producto FROM productos WHERE nombre = 'Pandebono'), (SELECT id_proveedor FROM proveedores WHERE nit = '800419396-3'), '2026-08-30 05:40:00', '2026-09-09', 69.00, 0.00, 980.00, 1450.00, 'Pasillo H', 'H-10', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-15-15-20260830-055000', (SELECT id_producto FROM productos WHERE nombre = 'Zanahoria'), (SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), '2026-08-30 05:50:00', '2026-09-22', 65.00, 0.00, 1430.00, 2200.00, 'Pasillo B', 'B-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-14-14-20260830-060000', (SELECT id_producto FROM productos WHERE nombre = 'Papa criolla'), (SELECT id_proveedor FROM proveedores WHERE nit = '860760410-7'), '2026-08-30 06:00:00', '2026-09-17', 35.00, 0.00, 3010.00, 4650.00, 'Pasillo B', 'B-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-37-37-20260831-052000', (SELECT id_producto FROM productos WHERE nombre = 'Jugo de naranja natural'), (SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), '2026-08-31 05:20:00', '2026-09-12', 35.00, 0.00, 5460.00, 7800.00, 'Pasillo F', 'F-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-46-46-20260831-061000', (SELECT id_producto FROM productos WHERE nombre = 'Pan tajado blanco'), (SELECT id_proveedor FROM proveedores WHERE nit = '900142625-7'), '2026-08-31 06:10:00', '2026-09-12', 51.00, 0.00, 4030.00, 6500.00, 'Pasillo H', 'H-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-34-36-20260831-064500', (SELECT id_producto FROM productos WHERE nombre = 'Lenteja'), (SELECT id_proveedor FROM proveedores WHERE nit = '901752859-4'), '2026-08-31 06:45:00', '2027-08-13', 425.00, 202.00, 4340.00, 6500.00, 'Pasillo E', 'E-05', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
-- Recepciones de septiembre de 2026
('LOT-36-36-20260902-054500', (SELECT id_producto FROM productos WHERE nombre = 'Maiz pira'), (SELECT id_proveedor FROM proveedores WHERE nit = '901752859-4'), '2026-09-02 05:45:00', '2027-08-04', 470.00, 281.00, 3310.00, 4950.00, 'Pasillo E', 'E-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-7-9-20260902-062000', (SELECT id_producto FROM productos WHERE nombre = 'Maracuya'), (SELECT id_proveedor FROM proveedores WHERE nit = '900467517-5'), '2026-09-02 06:20:00', '2026-09-16', 36.00, 0.00, 4030.00, 5600.00, 'Pasillo A', 'A-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-45-43-20260902-070000', (SELECT id_producto FROM productos WHERE nombre = 'Duraznos en almibar'), (SELECT id_proveedor FROM proveedores WHERE nit = '900712123-8'), '2026-09-02 07:00:00', '2028-05-13', 182.00, 0.00, 6050.00, 8900.00, 'Pasillo G', 'G-02', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-30-26-20260902-074500', (SELECT id_producto FROM productos WHERE nombre = 'Costilla de res'), (SELECT id_proveedor FROM proveedores WHERE nit = '901461481-5'), '2026-09-02 07:45:00', '2026-09-13', 14.00, 0.00, 12600.00, 19450.00, 'Pasillo D', 'D-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-5-5-20260903-051500', (SELECT id_producto FROM productos WHERE nombre = 'Lulo'), (SELECT id_proveedor FROM proveedores WHERE nit = '800674142-1'), '2026-09-03 05:15:00', '2026-09-18', 28.00, 0.00, 4160.00, 7050.00, 'Pasillo A', 'A-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-40-37-20260903-054500', (SELECT id_producto FROM productos WHERE nombre = 'Limonada de panela'), (SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), '2026-09-03 05:45:00', '2026-09-17', 19.00, 0.00, 3510.00, 5400.00, 'Pasillo F', 'F-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-6-6-20260903-055000', (SELECT id_producto FROM productos WHERE nombre = 'Aguacate hass'), (SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), '2026-09-03 05:50:00', '2026-09-17', 32.00, 0.00, 6410.00, 9600.00, 'Pasillo A', 'A-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-19-21-20260903-055000', (SELECT id_producto FROM productos WHERE nombre = 'Leche entera'), (SELECT id_proveedor FROM proveedores WHERE nit = '890772722-0'), '2026-09-03 05:50:00', '2026-09-15', 78.00, 0.00, 2730.00, 4300.00, 'Pasillo C', 'C-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-25-20-20260903-060000', (SELECT id_producto FROM productos WHERE nombre = 'Cuajada'), (SELECT id_proveedor FROM proveedores WHERE nit = '800285076-4'), '2026-09-03 06:00:00', '2026-09-13', 12.00, 0.00, 10400.00, 17600.00, 'Pasillo C', 'C-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-10-10-20260903-062000', (SELECT id_producto FROM productos WHERE nombre = 'Tomate chonto'), (SELECT id_proveedor FROM proveedores WHERE nit = '901294577-7'), '2026-09-03 06:20:00', '2026-09-16', 70.00, 0.00, 2590.00, 3900.00, 'Pasillo B', 'B-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-39-39-20260903-064500', (SELECT id_producto FROM productos WHERE nombre = 'Bebida de avena'), (SELECT id_proveedor FROM proveedores WHERE nit = '830197843-9'), '2026-09-03 06:45:00', '2026-09-22', 39.00, 0.00, 4220.00, 6500.00, 'Pasillo F', 'F-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-23-25-20260903-074000', (SELECT id_producto FROM productos WHERE nombre = 'Kumis'), (SELECT id_proveedor FROM proveedores WHERE nit = '900227949-4'), '2026-09-03 07:40:00', '2026-09-19', 27.00, 0.00, 4680.00, 7900.00, 'Pasillo C', 'C-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-50-49-20260904-051500', (SELECT id_producto FROM productos WHERE nombre = 'Pan blandito x 10'), (SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), '2026-09-04 05:15:00', '2026-09-15', 36.00, 0.00, 3640.00, 5600.00, 'Pasillo H', 'H-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-35-35-20260904-055000', (SELECT id_producto FROM productos WHERE nombre = 'Garbanzo'), (SELECT id_proveedor FROM proveedores WHERE nit = '890755101-5'), '2026-09-04 05:50:00', '2027-08-22', 255.00, 83.00, 5180.00, 8150.00, 'Pasillo E', 'E-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-20-20-20260905-054500', (SELECT id_producto FROM productos WHERE nombre = 'Yogur natural'), (SELECT id_proveedor FROM proveedores WHERE nit = '800285076-4'), '2026-09-05 05:45:00', '2026-09-26', 26.00, 0.00, 6120.00, 8900.00, 'Pasillo C', 'C-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-11-11-20260905-055000', (SELECT id_producto FROM productos WHERE nombre = 'Cebolla cabezona blanca'), (SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), '2026-09-05 05:50:00', '2026-09-30', 80.00, 0.00, 2180.00, 3350.00, 'Pasillo B', 'B-05', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-26-28-20260905-061000', (SELECT id_producto FROM productos WHERE nombre = 'Pechuga de pollo'), (SELECT id_proveedor FROM proveedores WHERE nit = '860733163-8'), '2026-09-05 06:10:00', '2026-09-14', 41.00, 0.00, 10230.00, 17300.00, 'Pasillo D', 'D-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-4-6-20260905-075000', (SELECT id_producto FROM productos WHERE nombre = 'Mora de castilla'), (SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), '2026-09-05 07:50:00', '2026-09-14', 18.00, 0.00, 4710.00, 8000.00, 'Pasillo A', 'A-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-29-29-20260906-060000', (SELECT id_producto FROM productos WHERE nombre = 'Lomo de cerdo'), (SELECT id_proveedor FROM proveedores WHERE nit = '860876509-6'), '2026-09-06 06:00:00', '2026-09-17', 15.00, 0.00, 15120.00, 21000.00, 'Pasillo D', 'D-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-1-3-20260906-063000', (SELECT id_producto FROM productos WHERE nombre = 'Banano criollo'), (SELECT id_proveedor FROM proveedores WHERE nit = '900656873-3'), '2026-09-06 06:30:00', '2026-09-19', 60.00, 0.00, 1900.00, 3100.00, 'Pasillo A', 'A-04', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-27-29-20260906-075000', (SELECT id_producto FROM productos WHERE nombre = 'Muslo contramuslo'), (SELECT id_proveedor FROM proveedores WHERE nit = '860876509-6'), '2026-09-06 07:50:00', '2026-09-15', 33.00, 0.00, 8020.00, 12400.00, 'Pasillo D', 'D-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-33-35-20260907-054000', (SELECT id_producto FROM productos WHERE nombre = 'Frijol cargamanto'), (SELECT id_proveedor FROM proveedores WHERE nit = '890755101-5'), '2026-09-07 05:40:00', '2027-06-13', 345.00, 253.00, 6370.00, 9800.00, 'Pasillo E', 'E-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-13-15-20260907-064500', (SELECT id_producto FROM productos WHERE nombre = 'Papa pastusa'), (SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), '2026-09-07 06:45:00', '2026-10-17', 150.00, 0.00, 1490.00, 2600.00, 'Pasillo B', 'B-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-41-41-20260908-051000', (SELECT id_producto FROM productos WHERE nombre = 'Jugo de mango'), (SELECT id_proveedor FROM proveedores WHERE nit = '890753714-0'), '2026-09-08 05:10:00', '2026-09-23', 19.00, 0.00, 5320.00, 7600.00, 'Pasillo F', 'F-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-47-47-20260908-054500', (SELECT id_producto FROM productos WHERE nombre = 'Almojabana'), (SELECT id_proveedor FROM proveedores WHERE nit = '890017624-1'), '2026-09-08 05:45:00', '2026-09-18', 68.00, 0.00, 930.00, 1500.00, 'Pasillo H', 'H-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-17-17-20260908-060000', (SELECT id_producto FROM productos WHERE nombre = 'Pimenton rojo'), (SELECT id_proveedor FROM proveedores WHERE nit = '890058443-9'), '2026-09-08 06:00:00', '2026-09-24', 17.00, 0.00, 4460.00, 6500.00, 'Pasillo B', 'B-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-31-27-20260908-064500', (SELECT id_producto FROM productos WHERE nombre = 'Chorizo santarrosano'), (SELECT id_proveedor FROM proveedores WHERE nit = '830985153-6'), '2026-09-08 06:45:00', '2026-10-08', 11.00, 0.00, 12920.00, 19950.00, 'Pasillo D', 'D-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-44-44-20260908-064500', (SELECT id_producto FROM productos WHERE nombre = 'Frijol en lata'), (SELECT id_proveedor FROM proveedores WHERE nit = '900396410-0'), '2026-09-08 06:45:00', '2028-06-09', 368.00, 11.00, 3220.00, 5200.00, 'Pasillo G', 'G-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-49-49-20260908-073000', (SELECT id_producto FROM productos WHERE nombre = 'Arepa de maiz x 5'), (SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), '2026-09-08 07:30:00', '2026-09-22', 51.00, 0.00, 3460.00, 5050.00, 'Pasillo H', 'H-01', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-7-9-20260918-055000', (SELECT id_producto FROM productos WHERE nombre = 'Maracuya'), (SELECT id_proveedor FROM proveedores WHERE nit = '900467517-5'), '2026-09-18 05:50:00', '2026-10-05', 34.00, 0.00, 3810.00, 6150.00, 'Pasillo A', 'A-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-37-37-20260918-064500', (SELECT id_producto FROM productos WHERE nombre = 'Jugo de naranja natural'), (SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), '2026-09-18 06:45:00', '2026-09-30', 24.00, 0.00, 4840.00, 7800.00, 'Pasillo F', 'F-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-18-11-20260919-052000', (SELECT id_producto FROM productos WHERE nombre = 'Brocoli'), (SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), '2026-09-19 05:20:00', '2026-09-30', 15.00, 0.00, 4680.00, 7200.00, 'Pasillo B', 'B-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-23-20-20260919-072000', (SELECT id_producto FROM productos WHERE nombre = 'Kumis'), (SELECT id_proveedor FROM proveedores WHERE nit = '800285076-4'), '2026-09-19 07:20:00', '2026-10-03', 24.00, 0.00, 4680.00, 7900.00, 'Pasillo C', 'C-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-15-15-20260922-074000', (SELECT id_producto FROM productos WHERE nombre = 'Zanahoria'), (SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), '2026-09-22 07:40:00', '2026-10-18', 65.00, 0.00, 1540.00, 2300.00, 'Pasillo B', 'B-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-4-6-20260925-073000', (SELECT id_producto FROM productos WHERE nombre = 'Mora de castilla'), (SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), '2026-09-25 07:30:00', '2026-10-06', 31.00, 0.00, 5170.00, 7600.00, 'Pasillo A', 'A-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-41-40-20260928-050000', (SELECT id_producto FROM productos WHERE nombre = 'Jugo de mango'), (SELECT id_proveedor FROM proveedores WHERE nit = '901390531-1'), '2026-09-28 05:00:00', '2026-10-12', 18.00, 0.00, 4940.00, 8350.00, 'Pasillo F', 'F-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-28-28-20260929-051000', (SELECT id_producto FROM productos WHERE nombre = 'Carne molida de res'), (SELECT id_proveedor FROM proveedores WHERE nit = '860733163-8'), '2026-09-29 05:10:00', '2026-10-09', 19.00, 0.00, 14300.00, 24200.00, 'Pasillo D', 'D-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-8-1-20260929-051500', (SELECT id_producto FROM productos WHERE nombre = 'Naranja tangelo'), (SELECT id_proveedor FROM proveedores WHERE nit = '900079560-8'), '2026-09-29 05:15:00', '2026-10-24', 70.00, 2.50, 2080.00, 3500.00, 'Pasillo A', 'A-05', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-46-50-20260929-063000', (SELECT id_producto FROM productos WHERE nombre = 'Pan tajado blanco'), (SELECT id_proveedor FROM proveedores WHERE nit = '800986205-6'), '2026-09-29 06:30:00', '2026-10-12', 47.00, 33.00, 4030.00, 6200.00, 'Pasillo H', 'H-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-24-19-20260930-050000', (SELECT id_producto FROM productos WHERE nombre = 'Crema de leche'), (SELECT id_proveedor FROM proveedores WHERE nit = '900518014-2'), '2026-09-30 05:00:00', '2026-10-22', 16.00, 0.00, 9520.00, 14000.00, 'Pasillo C', 'C-02', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-21-25-20260930-064000', (SELECT id_producto FROM productos WHERE nombre = 'Queso campesino'), (SELECT id_proveedor FROM proveedores WHERE nit = '900227949-4'), '2026-09-30 06:40:00', '2026-10-17', 11.00, 0.00, 12580.00, 19400.00, 'Pasillo C', 'C-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
-- Recepciones de octubre de 2026
('LOT-13-13-20261002-050000', (SELECT id_producto FROM productos WHERE nombre = 'Papa pastusa'), (SELECT id_proveedor FROM proveedores WHERE nit = '860287836-2'), '2026-10-02 05:00:00', '2026-11-03', 150.00, 0.00, 1680.00, 2600.00, 'Pasillo B', 'B-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-11-11-20261003-065000', (SELECT id_producto FROM productos WHERE nombre = 'Cebolla cabezona blanca'), (SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), '2026-10-03 06:50:00', '2026-11-07', 85.00, 0.00, 2180.00, 3450.00, 'Pasillo B', 'B-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-15-15-20261014-061000', (SELECT id_producto FROM productos WHERE nombre = 'Zanahoria'), (SELECT id_proveedor FROM proveedores WHERE nit = '900940316-1'), '2026-10-14 06:10:00', '2026-11-08', 47.00, 0.00, 1500.00, 2400.00, 'Pasillo B', 'B-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-39-39-20261016-052000', (SELECT id_producto FROM productos WHERE nombre = 'Bebida de avena'), (SELECT id_proveedor FROM proveedores WHERE nit = '830197843-9'), '2026-10-16 05:20:00', '2026-11-06', 35.00, 0.00, 4220.00, 6200.00, 'Pasillo F', 'F-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-7-9-20261018-063000', (SELECT id_producto FROM productos WHERE nombre = 'Maracuya'), (SELECT id_proveedor FROM proveedores WHERE nit = '900467517-5'), '2026-10-18 06:30:00', '2026-11-05', 24.00, 0.00, 3920.00, 6150.00, 'Pasillo A', 'A-10', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-17-10-20261020-053000', (SELECT id_producto FROM productos WHERE nombre = 'Pimenton rojo'), (SELECT id_proveedor FROM proveedores WHERE nit = '901294577-7'), '2026-10-20 05:30:00', '2026-11-05', 15.00, 0.00, 4340.00, 6500.00, 'Pasillo B', 'B-02', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-2-4-20261022-051000', (SELECT id_producto FROM productos WHERE nombre = 'Mango tommy'), (SELECT id_proveedor FROM proveedores WHERE nit = '900847669-7'), '2026-10-22 05:10:00', '2026-11-01', 32.00, 0.00, 3220.00, 5200.00, 'Pasillo A', 'A-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Vencido')),
('LOT-6-6-20261022-071000', (SELECT id_producto FROM productos WHERE nombre = 'Aguacate hass'), (SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), '2026-10-22 07:10:00', '2026-11-04', 48.00, 36.00, 6050.00, 9350.00, 'Pasillo A', 'A-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-21-23-20261023-061500', (SELECT id_producto FROM productos WHERE nombre = 'Queso campesino'), (SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), '2026-10-23 06:15:00', '2026-11-09', 12.00, 0.00, 12580.00, 19400.00, 'Pasillo C', 'C-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-5-7-20261024-064500', (SELECT id_producto FROM productos WHERE nombre = 'Lulo'), (SELECT id_proveedor FROM proveedores WHERE nit = '901766047-1'), '2026-10-24 06:45:00', '2026-11-09', 19.00, 19.00, 3970.00, 6400.00, 'Pasillo A', 'A-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'En Cuarentena')),
('LOT-18-11-20261024-074500', (SELECT id_producto FROM productos WHERE nombre = 'Brocoli'), (SELECT id_proveedor FROM proveedores WHERE nit = '890180648-2'), '2026-10-24 07:45:00', '2026-11-07', 18.00, 18.00, 4680.00, 7200.00, 'Pasillo B', 'B-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'En Cuarentena')),
('LOT-10-12-20261025-061000', (SELECT id_producto FROM productos WHERE nombre = 'Tomate chonto'), (SELECT id_proveedor FROM proveedores WHERE nit = '890153904-9'), '2026-10-25 06:10:00', '2026-11-06', 55.00, 2.00, 2450.00, 3600.00, 'Pasillo B', 'B-01', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-4-4-20261026-051500', (SELECT id_producto FROM productos WHERE nombre = 'Mora de castilla'), (SELECT id_proveedor FROM proveedores WHERE nit = '900847669-7'), '2026-10-26 05:15:00', '2026-11-06', 21.00, 0.00, 5320.00, 8200.00, 'Pasillo A', 'A-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-37-37-20261026-054500', (SELECT id_producto FROM productos WHERE nombre = 'Jugo de naranja natural'), (SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), '2026-10-26 05:45:00', '2026-11-07', 18.00, 10.00, 5460.00, 7800.00, 'Pasillo F', 'F-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-27-29-20261027-051500', (SELECT id_producto FROM productos WHERE nombre = 'Muslo contramuslo'), (SELECT id_proveedor FROM proveedores WHERE nit = '860876509-6'), '2026-10-27 05:15:00', '2026-11-05', 36.00, 31.50, 7320.00, 13000.00, 'Pasillo D', 'D-01', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-1-1-20261027-071500', (SELECT id_producto FROM productos WHERE nombre = 'Banano criollo'), (SELECT id_proveedor FROM proveedores WHERE nit = '900079560-8'), '2026-10-27 07:15:00', '2026-11-12', 70.00, 70.00, 1740.00, 2800.00, 'Pasillo A', 'A-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'En Cuarentena')),
('LOT-24-24-20261028-052000', (SELECT id_producto FROM productos WHERE nombre = 'Crema de leche'), (SELECT id_proveedor FROM proveedores WHERE nit = '900749366-0'), '2026-10-28 05:20:00', '2026-11-22', 11.00, 11.00, 9100.00, 14000.00, 'Pasillo C', 'C-11', (SELECT id_estado FROM estados_lote WHERE nombre = 'En Cuarentena')),
('LOT-25-25-20261028-053000', (SELECT id_producto FROM productos WHERE nombre = 'Cuajada'), (SELECT id_proveedor FROM proveedores WHERE nit = '900227949-4'), '2026-10-28 05:30:00', '2026-11-09', 12.00, 2.00, 11520.00, 16800.00, 'Pasillo C', 'C-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-6-6-20261028-053000', (SELECT id_producto FROM productos WHERE nombre = 'Aguacate hass'), (SELECT id_proveedor FROM proveedores WHERE nit = '800488223-2'), '2026-10-28 05:30:00', '2026-11-11', 31.00, 31.00, 5780.00, 8900.00, 'Pasillo A', 'A-10', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-50-49-20261028-054500', (SELECT id_producto FROM productos WHERE nombre = 'Pan blandito x 10'), (SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), '2026-10-28 05:45:00', '2026-11-07', 50.00, 0.00, 4030.00, 5900.00, 'Pasillo H', 'H-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-26-26-20261028-055000', (SELECT id_producto FROM productos WHERE nombre = 'Pechuga de pollo'), (SELECT id_proveedor FROM proveedores WHERE nit = '901461481-5'), '2026-10-28 05:50:00', '2026-11-08', 41.00, 41.00, 11220.00, 17300.00, 'Pasillo D', 'D-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer')),
('LOT-29-31-20261028-060000', (SELECT id_producto FROM productos WHERE nombre = 'Lomo de cerdo'), (SELECT id_proveedor FROM proveedores WHERE nit = '800392786-3'), '2026-10-28 06:00:00', '2026-11-11', 16.00, 12.00, 13650.00, 22050.00, 'Pasillo D', 'D-04', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-50-50-20261029-050000', (SELECT id_producto FROM productos WHERE nombre = 'Pan blandito x 10'), (SELECT id_proveedor FROM proveedores WHERE nit = '800986205-6'), '2026-10-29 05:00:00', '2026-11-11', 39.00, 0.00, 3810.00, 6050.00, 'Pasillo H', 'H-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-30-28-20261029-051500', (SELECT id_producto FROM productos WHERE nombre = 'Costilla de res'), (SELECT id_proveedor FROM proveedores WHERE nit = '860733163-8'), '2026-10-29 05:15:00', '2026-11-11', 24.00, 21.00, 11700.00, 19800.00, 'Pasillo D', 'D-05', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-2-4-20261029-052000', (SELECT id_producto FROM productos WHERE nombre = 'Mango tommy'), (SELECT id_proveedor FROM proveedores WHERE nit = '900847669-7'), '2026-10-29 05:20:00', '2026-11-11', 44.00, 32.00, 3540.00, 5200.00, 'Pasillo A', 'A-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-40-37-20261029-054500', (SELECT id_producto FROM productos WHERE nombre = 'Limonada de panela'), (SELECT id_proveedor FROM proveedores WHERE nit = '901810296-7'), '2026-10-29 05:45:00', '2026-11-13', 18.00, 15.00, 3670.00, 5950.00, 'Pasillo F', 'F-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-19-23-20261029-061000', (SELECT id_producto FROM productos WHERE nombre = 'Leche entera'), (SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), '2026-10-29 06:10:00', '2026-11-10', 59.00, 59.00, 2420.00, 3900.00, 'Pasillo C', 'C-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-12-16-20261029-063000', (SELECT id_producto FROM productos WHERE nombre = 'Cebolla larga'), (SELECT id_proveedor FROM proveedores WHERE nit = '830201040-9'), '2026-10-29 06:30:00', '2026-11-12', 20.00, 0.00, 2790.00, 4500.00, 'Pasillo B', 'B-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Rechazado')),
('LOT-39-39-20261029-070000', (SELECT id_producto FROM productos WHERE nombre = 'Bebida de avena'), (SELECT id_proveedor FROM proveedores WHERE nit = '830197843-9'), '2026-10-29 07:00:00', '2026-11-16', 34.00, 34.00, 3840.00, 6200.00, 'Pasillo F', 'F-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-20-22-20261030-051500', (SELECT id_producto FROM productos WHERE nombre = 'Yogur natural'), (SELECT id_proveedor FROM proveedores WHERE nit = '800410460-6'), '2026-10-30 05:15:00', '2026-11-21', 21.00, 0.00, 5780.00, 9350.00, 'Pasillo C', 'C-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-8-1-20261030-052000', (SELECT id_producto FROM productos WHERE nombre = 'Naranja tangelo'), (SELECT id_proveedor FROM proveedores WHERE nit = '900079560-8'), '2026-10-30 05:20:00', '2026-11-24', 65.00, 0.00, 2240.00, 3200.00, 'Pasillo A', 'A-02', (SELECT id_estado FROM estados_lote WHERE nombre = 'Rechazado')),
('LOT-13-13-20261030-054000', (SELECT id_producto FROM productos WHERE nombre = 'Papa pastusa'), (SELECT id_proveedor FROM proveedores WHERE nit = '860287836-2'), '2026-10-30 05:40:00', '2026-12-06', 145.00, 142.00, 1680.00, 2650.00, 'Pasillo B', 'B-08', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-19-23-20261030-062000', (SELECT id_producto FROM productos WHERE nombre = 'Leche entera'), (SELECT id_proveedor FROM proveedores WHERE nit = '830827404-3'), '2026-10-30 06:20:00', '2026-11-14', 59.00, 59.00, 2730.00, 4300.00, 'Pasillo C', 'C-06', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-46-50-20261030-063000', (SELECT id_producto FROM productos WHERE nombre = 'Pan tajado blanco'), (SELECT id_proveedor FROM proveedores WHERE nit = '800986205-6'), '2026-10-30 06:30:00', '2026-11-13', 40.00, 40.00, 3840.00, 6200.00, 'Pasillo H', 'H-12', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-49-49-20261030-063000', (SELECT id_producto FROM productos WHERE nombre = 'Arepa de maiz x 5'), (SELECT id_proveedor FROM proveedores WHERE nit = '890877059-7'), '2026-10-30 06:30:00', '2026-11-17', 37.00, 37.00, 3260.00, 5300.00, 'Pasillo H', 'H-04', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-27-29-20261031-051000', (SELECT id_producto FROM productos WHERE nombre = 'Muslo contramuslo'), (SELECT id_proveedor FROM proveedores WHERE nit = '860876509-6'), '2026-10-31 05:10:00', '2026-11-11', 35.00, 35.00, 8500.00, 13000.00, 'Pasillo D', 'D-03', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-14-18-20261031-054000', (SELECT id_producto FROM productos WHERE nombre = 'Papa criolla'), (SELECT id_proveedor FROM proveedores WHERE nit = '900309046-1'), '2026-10-31 05:40:00', '2026-11-16', 33.00, 33.00, 2800.00, 4650.00, 'Pasillo B', 'B-10', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
-- Recepciones de noviembre de 2026
('LOT-47-46-20261101-054000', (SELECT id_producto FROM productos WHERE nombre = 'Almojabana'), (SELECT id_proveedor FROM proveedores WHERE nit = '900142625-7'), '2026-11-01 05:40:00', '2026-11-11', 47.00, 47.00, 1080.00, 1500.00, 'Pasillo H', 'H-09', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-26-26-20261101-054500', (SELECT id_producto FROM productos WHERE nombre = 'Pechuga de pollo'), (SELECT id_proveedor FROM proveedores WHERE nit = '901461481-5'), '2026-11-01 05:45:00', '2026-11-11', 38.00, 38.00, 11550.00, 17800.00, 'Pasillo D', 'D-07', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible')),
('LOT-41-38-20261101-063000', (SELECT id_producto FROM productos WHERE nombre = 'Jugo de mango'), (SELECT id_proveedor FROM proveedores WHERE nit = '900593488-9'), '2026-11-01 06:30:00', '2026-11-14', 27.00, 27.00, 4940.00, 7600.00, 'Pasillo F', 'F-01', (SELECT id_estado FROM estados_lote WHERE nombre = 'Disponible'))
ON DUPLICATE KEY UPDATE numero_lote = numero_lote;

-- 2.6 Calidad: cuarentenas, inspecciones y mermas
-- 4 lotes siguen En Cuarentena (resuelta = FALSE) para probar la inspeccion desde el menu.
-- 2 lotes fueron Rechazados: su cantidad paso a 0 y quedo registrada como merma.
-- 2 lotes fueron Aprobados y volvieron a su estado normal.

-- Registro de cuarentena
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-5-7-20261024-064500'), 'Empaque roto y olor acido en varias canastillas', 'jefe.bodega', '2026-10-24 10:45:00', FALSE, NULL, NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-5-7-20261024-064500' AND c.fecha_registro = '2026-10-24 10:45:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-18-11-20261024-074500'), 'Temperatura de llegada por encima de 6 grados', 'jefe.bodega', '2026-10-25 07:45:00', FALSE, NULL, NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-18-11-20261024-074500' AND c.fecha_registro = '2026-10-25 07:45:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-1-1-20261027-071500'), 'Presencia de moho en algunas unidades', 'operario.bodega1', '2026-10-27 20:15:00', FALSE, NULL, NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-1-1-20261027-071500' AND c.fecha_registro = '2026-10-27 20:15:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-24-24-20261028-052000'), 'Golpes y magulladuras en la parte superior del lote', 'jefe.bodega', '2026-10-29 10:20:00', FALSE, NULL, NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-24-24-20261028-052000' AND c.fecha_registro = '2026-10-29 10:20:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-12-16-20261029-063000'), 'Sello de seguridad violado en dos cajas', 'jefe.bodega', '2026-10-29 11:30:00', TRUE, '2026-10-29 19:30:00', 'Rechazado por Mauricio Leal'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-12-16-20261029-063000' AND c.fecha_registro = '2026-10-29 11:30:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20261030-052000'), 'Color irregular y textura blanda', 'jefe.bodega', '2026-10-30 18:20:00', TRUE, '2026-10-31 05:20:00', 'Rechazado por Mauricio Leal'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-8-1-20261030-052000' AND c.fecha_registro = '2026-10-30 18:20:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-46-50-20261030-063000'), 'Cadena de frio interrumpida segun el registro del camion', 'operario.bodega2', '2026-10-30 10:30:00', TRUE, '2026-10-31 07:30:00', 'Aprobado por Mauricio Leal'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-46-50-20261030-063000' AND c.fecha_registro = '2026-10-30 10:30:00');
INSERT INTO registro_cuarentena (id_lote, motivo, usuario, fecha_registro, resuelta, fecha_resolucion, notas_resolucion)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-49-49-20261030-063000'), 'Etiquetas con fecha de vencimiento ilegible', 'operario.bodega2', '2026-10-30 14:30:00', TRUE, '2026-10-31 15:30:00', 'Aprobado por Diana Castro'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_cuarentena c JOIN lotes_inventario l ON l.id_lote = c.id_lote WHERE l.numero_lote = 'LOT-49-49-20261030-063000' AND c.fecha_registro = '2026-10-30 14:30:00');

-- Inspecciones de calidad (resultado del inspector)
INSERT INTO inspecciones_calidad (id_lote, fecha_inspeccion, resultado, nombre_inspector, motivo_rechazo, notas)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-12-16-20261029-063000'), '2026-10-29 19:30:00', 'Rechazado', 'Mauricio Leal', 'Se confirma descomposicion, no apto para la venta', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inspecciones_calidad x JOIN lotes_inventario l ON l.id_lote = x.id_lote WHERE l.numero_lote = 'LOT-12-16-20261029-063000' AND x.fecha_inspeccion = '2026-10-29 19:30:00');
INSERT INTO inspecciones_calidad (id_lote, fecha_inspeccion, resultado, nombre_inspector, motivo_rechazo, notas)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20261030-052000'), '2026-10-31 05:20:00', 'Rechazado', 'Mauricio Leal', 'Ruptura de cadena de frio confirmada, riesgo sanitario', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inspecciones_calidad x JOIN lotes_inventario l ON l.id_lote = x.id_lote WHERE l.numero_lote = 'LOT-8-1-20261030-052000' AND x.fecha_inspeccion = '2026-10-31 05:20:00');
INSERT INTO inspecciones_calidad (id_lote, fecha_inspeccion, resultado, nombre_inspector, motivo_rechazo, notas)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-46-50-20261030-063000'), '2026-10-31 07:30:00', 'Aprobado', 'Mauricio Leal', NULL, 'Revision completa, el producto esta en buen estado'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inspecciones_calidad x JOIN lotes_inventario l ON l.id_lote = x.id_lote WHERE l.numero_lote = 'LOT-46-50-20261030-063000' AND x.fecha_inspeccion = '2026-10-31 07:30:00');
INSERT INTO inspecciones_calidad (id_lote, fecha_inspeccion, resultado, nombre_inspector, motivo_rechazo, notas)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-49-49-20261030-063000'), '2026-10-31 15:30:00', 'Aprobado', 'Diana Castro', NULL, 'Solo un empaque afectado, se retiro y el resto esta bien'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM inspecciones_calidad x JOIN lotes_inventario l ON l.id_lote = x.id_lote WHERE l.numero_lote = 'LOT-49-49-20261030-063000' AND x.fecha_inspeccion = '2026-10-31 15:30:00');

-- Mermas: rechazos de calidad, lotes vencidos que se dieron de baja y producto danado.
-- Quedan 2 lotes vencidos con existencias sin dar de baja (LOT-46-50-20260929-063000 y LOT-8-1-20260929-051500)
-- para probar el registro de mermas desde el menu.
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-28-30-20260827-055000'), NULL, 18.00, 'Producto vencido, se da de baja', '2026-09-06 07:00:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-28-30-20260827-055000' AND r.fecha_registro = '2026-09-06 07:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-18-11-20260827-074000'), NULL, 9.00, 'Vencido en bodega, se descarta', '2026-09-06 07:30:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-18-11-20260827-074000' AND r.fecha_registro = '2026-09-06 07:30:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-16-18-20260828-054500'), NULL, 24.00, 'Vencido en bodega, se descarta', '2026-09-08 08:00:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-16-18-20260828-054500' AND r.fecha_registro = '2026-09-08 08:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-48-48-20260830-054000'), NULL, 29.00, 'Producto vencido, se da de baja', '2026-09-10 07:15:00', 'jefe.bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-48-48-20260830-054000' AND r.fecha_registro = '2026-09-10 07:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-12-12-20260828-061500'), NULL, 17.00, 'Producto vencido, se da de baja', '2026-09-10 08:45:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-12-12-20260828-061500' AND r.fecha_registro = '2026-09-10 08:45:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-21-23-20260829-061000'), NULL, 8.00, 'Lote vencido sin vender', '2026-09-14 08:15:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-21-23-20260829-061000' AND r.fecha_registro = '2026-09-14 08:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-9-2-20260829-064000'), NULL, 22.00, 'Producto vencido, se da de baja', '2026-09-14 09:15:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-9-2-20260829-064000' AND r.fecha_registro = '2026-09-14 09:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-25-20-20260903-060000'), NULL, 2.00, 'Lote vencido sin vender', '2026-09-14 09:30:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-25-20-20260903-060000' AND r.fecha_registro = '2026-09-14 09:30:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-26-28-20260905-061000'), NULL, 12.30, 'Lote vencido sin vender', '2026-09-15 07:00:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-26-28-20260905-061000' AND r.fecha_registro = '2026-09-15 07:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-4-6-20260905-075000'), NULL, 18.00, 'Lote vencido sin vender', '2026-09-15 09:00:00', 'jefe.bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-4-6-20260905-075000' AND r.fecha_registro = '2026-09-15 09:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-19-21-20260903-055000'), NULL, 38.00, 'Producto vencido, se da de baja', '2026-09-16 07:00:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-19-21-20260903-055000' AND r.fecha_registro = '2026-09-16 07:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-50-49-20260904-051500'), NULL, 20.00, 'Vencido en bodega, se descarta', '2026-09-16 08:15:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-50-49-20260904-051500' AND r.fecha_registro = '2026-09-16 08:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-27-29-20260906-075000'), NULL, 8.00, 'Lote vencido sin vender', '2026-09-16 08:30:00', 'jefe.bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-27-29-20260906-075000' AND r.fecha_registro = '2026-09-16 08:30:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260902-062000'), NULL, 13.00, 'Vencido en bodega, se descarta', '2026-09-17 07:00:00', 'jefe.bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-7-9-20260902-062000' AND r.fecha_registro = '2026-09-17 07:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-10-10-20260903-062000'), NULL, 61.00, 'Producto vencido, se da de baja', '2026-09-17 07:30:00', 'jefe.bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-10-10-20260903-062000' AND r.fecha_registro = '2026-09-17 07:30:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-14-14-20260830-060000'), NULL, 35.00, 'Vencido en bodega, se descarta', '2026-09-18 08:15:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-14-14-20260830-060000' AND r.fecha_registro = '2026-09-18 08:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-29-29-20260906-060000'), NULL, 5.50, 'Lote vencido sin vender', '2026-09-18 08:15:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-29-29-20260906-060000' AND r.fecha_registro = '2026-09-18 08:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-5-5-20260903-051500'), NULL, 3.00, 'Producto vencido, se da de baja', '2026-09-19 07:00:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-5-5-20260903-051500' AND r.fecha_registro = '2026-09-19 07:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-1-3-20260906-063000'), NULL, 21.00, 'Producto vencido, se da de baja', '2026-09-20 08:30:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-1-3-20260906-063000' AND r.fecha_registro = '2026-09-20 08:30:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260828-074500'), NULL, 2.00, 'Producto vencido, se da de baja', '2026-09-23 07:00:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-8-1-20260828-074500' AND r.fecha_registro = '2026-09-23 07:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-39-39-20260903-064500'), NULL, 35.00, 'Lote vencido sin vender', '2026-09-23 08:15:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-39-39-20260903-064500' AND r.fecha_registro = '2026-09-23 08:15:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260830-055000'), NULL, 20.50, 'Vencido en bodega, se descarta', '2026-09-23 08:45:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-15-15-20260830-055000' AND r.fecha_registro = '2026-09-23 08:45:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), NULL, 5.00, 'Producto aplastado por mala estiba', '2026-10-24 03:00:00', 'operario.bodega1'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-43-43-20260827-075000' AND r.fecha_registro = '2026-10-24 03:00:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-12-16-20261029-063000'), (SELECT x.id_inspeccion FROM inspecciones_calidad x JOIN lotes_inventario l ON l.id_lote = x.id_lote WHERE l.numero_lote = 'LOT-12-16-20261029-063000' AND x.fecha_inspeccion = '2026-10-29 19:30:00'), 20.00, 'Se confirma descomposicion, no apto para la venta', '2026-10-29 19:30:00', 'Mauricio Leal'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-12-16-20261029-063000' AND r.fecha_registro = '2026-10-29 19:30:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261030-054000'), NULL, 3.00, 'Golpes en el descargue del camion', '2026-10-30 08:40:00', 'operario.bodega2'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-13-13-20261030-054000' AND r.fecha_registro = '2026-10-30 08:40:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20261030-052000'), (SELECT x.id_inspeccion FROM inspecciones_calidad x JOIN lotes_inventario l ON l.id_lote = x.id_lote WHERE l.numero_lote = 'LOT-8-1-20261030-052000' AND x.fecha_inspeccion = '2026-10-31 05:20:00'), 65.00, 'Ruptura de cadena de frio confirmada, riesgo sanitario', '2026-10-31 05:20:00', 'Mauricio Leal'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-8-1-20261030-052000' AND r.fecha_registro = '2026-10-31 05:20:00');
INSERT INTO registro_mermas (id_lote, id_inspeccion, cantidad_perdida, motivo, fecha_registro, usuario_registro)
SELECT (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-30-28-20261029-051500'), NULL, 3.00, 'Canastilla caida en el pasillo', '2026-11-01 10:30:00', 'jefe.bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM registro_mermas r JOIN lotes_inventario l ON l.id_lote = r.id_lote WHERE l.numero_lote = 'LOT-30-28-20261029-051500' AND r.fecha_registro = '2026-11-01 10:30:00');

-- 2.7 Promociones para lotes 'Proximo a Vencer'
-- VentasDao toma la tasa_descuento MAS ALTA entre las promociones activas y vigentes que
-- aplican al estado 'Proximo a Vencer' y a la categoria del producto (o a todas si
-- aplica_categoria_producto es NULL). Con estos datos:
--   Lacteos 50% (solo del 2026-10-01 al 2026-11-30), Panaderia 40%, resto de productos 30%.
--   La promocion de agosto esta desactivada (activa = FALSE) y no debe aplicarse.
-- Las lineas de venta con lotes a 7 dias o menos de vencer ya traen este descuento.
INSERT INTO promociones (nombre, descripcion, tasa_descuento, aplica_estado_lote, aplica_categoria_producto, activa, fecha_inicio, fecha_fin)
SELECT 'Liquidacion proximos a vencer', 'Descuento general para lotes con 7 dias o menos de vida util', 0.30, (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer'), NULL, TRUE, '2026-09-01', '2026-12-31'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE nombre = 'Liquidacion proximos a vencer');
INSERT INTO promociones (nombre, descripcion, tasa_descuento, aplica_estado_lote, aplica_categoria_producto, activa, fecha_inicio, fecha_fin)
SELECT 'Lacteos proximos a vencer', 'Descuento especial para lacteos en estado Proximo a Vencer', 0.50, (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer'), (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Lacteos'), TRUE, '2026-10-01', '2026-11-30'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE nombre = 'Lacteos proximos a vencer');
INSERT INTO promociones (nombre, descripcion, tasa_descuento, aplica_estado_lote, aplica_categoria_producto, activa, fecha_inicio, fecha_fin)
SELECT 'Panaderia proxima a vencer', 'Descuento para panaderia en estado Proximo a Vencer', 0.40, (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer'), (SELECT id_categoria FROM categorias_producto WHERE nombre = 'Panaderia'), TRUE, '2026-09-01', '2026-12-31'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE nombre = 'Panaderia proxima a vencer');
INSERT INTO promociones (nombre, descripcion, tasa_descuento, aplica_estado_lote, aplica_categoria_producto, activa, fecha_inicio, fecha_fin)
SELECT 'Promocion de prueba agosto', 'Promocion antigua desactivada, no debe aplicarse', 0.15, (SELECT id_estado FROM estados_lote WHERE nombre = 'Proximo a Vencer'), NULL, FALSE, '2026-08-01', '2026-08-31'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM promociones WHERE nombre = 'Promocion de prueba agosto');

-- 2.8 Clientes (50): 20 mayoristas y 30 minoristas. Datos ficticios.
INSERT INTO clientes (nombre, documento, email, telefono, direccion, id_tipo, fecha_registro) VALUES
('Restaurante La Cazuela Sabanera S.A.S.', '900804298-3', 'pedidos@restaurantecazuelasabanera.example.com', '318 943 1319', 'Calle 46 # 11-22, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-18 15:54:00'),
('Supermercado El Vecino Ltda.', '830490236-3', 'administracion@supermercadovecino.example.com', '307 663 1401', 'Calle 154 # 82-95, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-20 10:59:00'),
('Hotel Andino Plaza S.A.S.', '830317404-5', 'compras@hotelandinoplaza.example.com', '351 246 3453', 'Calle 60 # 15-85, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-12 16:45:00'),
('Casino Empresarial Buen Sabor', '900759812-7', 'contacto@casinoempresarialbuen.example.com', '601 230 1420', 'Calle 10 # 36-55, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-17 11:04:00'),
('Colegio Campestre Los Alpes', '901763724-6', 'contacto@colegiocampestrealpes.example.com', '317 545 6221', 'Calle 18 # 8-16, Chia', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-28 11:03:00'),
('Fruver La Cosecha de Usaquen', '860951566-7', 'compras@fruvercosechausaquen.example.com', '601 687 7941', 'Carrera 8 # 146-68, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-13 16:20:00'),
('Restaurante Fogon Paisa', '901670233-1', 'pedidos@restaurantefogonpaisa.example.com', '601 497 8235', 'Carrera 18 # 35-51, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-13 14:24:00'),
('Minimercado Don Pacho', '830403989-1', 'administracion@minimercadodonpacho.example.com', '328 350 6362', 'Carrera 75 # 46-12 Sur, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-13 14:12:00'),
('Cafeteria y Panaderia La Espiga', '860173712-8', 'contacto@cafeteriapanaderiaespiga.example.com', '601 697 1582', 'Calle 80 # 82-42, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-28 12:42:00'),
('Asadero El Llanerito', '830816147-8', 'compras@asaderollanerito.example.com', '601 382 6064', 'Calle 17 # 98-24, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-18 16:23:00'),
('Hotel Boutique Calle 70', '830851925-1', 'contacto@hotelboutiquecalle.example.com', '601 510 2199', 'Calle 57 # 6-33, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-22 15:07:00'),
('Supermercado Mercafacil Soacha', '830423958-7', 'compras@supermercadomercafacilsoacha.example.com', '310 969 8078', 'Carrera 18 # 10-94, Soacha', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-28 15:06:00'),
('Comedor Comunitario San Mateo', '860252314-9', 'administracion@comedorcomunitariosan.example.com', '354 223 7656', 'Calle 27 # 16-59, Soacha', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-10 11:55:00'),
('Restaurante Sabor del Pacifico', '900574716-2', 'administracion@restaurantesaborpacifico.example.com', '352 542 3032', 'Carrera 30 # 36-65, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-31 12:09:00'),
('Clinica Santa Ana - Servicio de Alimentacion', '901834485-6', 'pedidos@clinicasantaana.example.com', '601 625 7159', 'Carrera 9 # 142-5, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-11 12:04:00'),
('Fruteria Tropical Funza', '900679844-9', 'contacto@fruteriatropicalfunza.example.com', '601 472 7533', 'Carrera 12 # 18-47, Funza', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-15 13:36:00'),
('Catering Eventos Gourmet S.A.S.', '901266465-1', 'administracion@cateringeventosgourmet.example.com', '318 520 8331', 'Calle 138 # 112-32, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-07 14:26:00'),
('Restaurante Wok y Arroz', '830378414-1', 'administracion@restaurantewokarroz.example.com', '315 320 6667', 'Carrera 9 # 118-37, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-08 10:40:00'),
('Supermercado Cajica Express', '900107517-1', 'compras@supermercadocajicaexpress.example.com', '601 715 8677', 'Calle 5 # 5-38, Cajica', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-26 16:20:00'),
('Hogar Geriatrico Los Robles', '900782265-4', 'pedidos@hogargeriatricorobles.example.com', '314 931 4650', 'Calle 75 # 83-11, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'), '2026-08-30 13:11:00'),
('Tienda Dona Rosa', '395448473', 'pedidos@tiendadonarosa.example.com', '326 599 9460', 'Carrera 80 # 30-38 Sur, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-27 11:04:00'),
('Tienda El Paisa', '830611618-4', 'administracion@tiendapaisa.example.com', '356 265 3913', 'Carrera 95 # 78-47, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-22 15:24:00'),
('Fruver Las Margaritas', '830891865-7', 'contacto@fruvermargaritas.example.com', '322 857 3398', 'Calle 28 Sur # 68-45, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-28 11:04:00'),
('Camila Andrea Rojas Quintero', '1020816213', 'camila.rojas@example.com', '319 445 2113', 'Carrera 91 # 135-89, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-18 13:50:00'),
('Luis Eduardo Pardo Salinas', '5220512050', 'luis.pardo@example.com', '310 234 8441', 'Carrera 107 # 18-18, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-02 09:28:00'),
('Tienda La Esquina de Juan', '860737809-5', 'compras@tiendaesquinajuan.example.com', '303 570 6189', 'Calle 131 # 100-33, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-25 14:02:00'),
('Panaderia Pan Caliente', '196129980', 'administracion@panaderiapancaliente.example.com', '601 420 2262', 'Calle 20 # 105-34, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-11 12:51:00'),
('Valentina Gomez Arias', '1015188440', 'valentina.gomez@example.com', '317 231 2846', 'Calle 49 # 24-69, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-05 09:31:00'),
('Cigarreria y Tienda La 45', '901495800-8', 'contacto@cigarreriatienda45.example.com', '312 385 2638', 'Calle 34 # 25-74, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-23 16:25:00'),
('Andres Felipe Cardenas Mora', '1012539771', 'andres.cardenas@example.com', '356 350 9297', 'Carrera 11 # 66-50, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-20 13:42:00'),
('Tienda Mi Barrio', '419859414', 'administracion@tiendamibarrio.example.com', '304 514 5440', 'Carrera 53 # 15-8, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-30 11:38:00'),
('Frutas y Verduras Dona Ines', '830536890-0', 'pedidos@frutasverdurasdona.example.com', '323 351 9636', 'Carrera 73 # 64-35, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-07 15:12:00'),
('Carolina Mejia Restrepo', '1020115879', 'carolina.mejia@example.com', '325 482 3137', 'Calle 141 # 9-32, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-04 11:14:00'),
('Tienda Naturista Vida Sana', '830199613-0', 'compras@tiendanaturistavida.example.com', '601 530 8586', 'Carrera 7 # 64-7, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-10 11:08:00'),
('Santiago Herrera Duque', '5219221410', 'santiago.herrera@example.com', '316 377 2679', 'Carrera 8 # 8-76, Chia', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-04 09:25:00'),
('Cafe Bar El Rincon', '900880426-3', 'pedidos@cafebarrincon.example.com', '351 843 1032', 'Calle 46 # 25-52, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-05 12:02:00'),
('Tienda Los Hermanos', '901709683-3', 'compras@tiendahermanos.example.com', '355 392 5738', 'Calle 28 Sur # 75-29, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-31 10:20:00'),
('Daniela Ospina Vargas', '1010180295', 'daniela.ospina@example.com', '314 726 6391', 'Carrera 108 # 142-24, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-05 10:03:00'),
('Lonchera Escolar Don Jorge', '900818033-1', 'pedidos@loncheraescolardon.example.com', '355 280 1933', 'Calle 67 # 108-9, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-09 12:23:00'),
('Tienda La Bendicion', '830626033-1', 'contacto@tiendabendicion.example.com', '601 521 1956', 'Calle 20 # 17-95, Soacha', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-21 12:10:00'),
('Jorge Ivan Castano Lopez', '1010771312', 'jorge.castano@example.com', '316 819 4287', 'Calle 22 # 96-65, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-01 15:03:00'),
('Heladeria y Fruteria Coco Loco', '830520546-1', 'contacto@heladeriafruteriacoco.example.com', '601 713 1338', 'Carrera 7 # 6-91, Cajica', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-10 10:19:00'),
('Tienda El Trebol', '197894450', 'contacto@tiendatrebol.example.com', '302 744 1966', 'Calle 18 # 37-44, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-30 16:50:00'),
('Paula Andrea Martinez Gil', '7990476709', 'paula.martinez@example.com', '314 397 6697', 'Calle 54 # 15-39, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-15 15:08:00'),
('Tienda Surtifruver 80', '394810202', 'contacto@tiendasurtifruver80.example.com', '601 436 8662', 'Calle 68 # 104-31, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-04 09:39:00'),
('Miguel Angel Torres Ruiz', '1020429903', 'miguel.torres@example.com', '311 795 4980', 'Carrera 81 # 45-82 Sur, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-19 14:23:00'),
('Tienda Dona Cecilia', '830427273-9', 'pedidos@tiendadonacecilia.example.com', '304 567 4269', 'Calle 158 # 84-39, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-17 15:48:00'),
('Comidas Rapidas El Gordo', '830984101-9', 'pedidos@comidasrapidasgordo.example.com', '601 282 6499', 'Carrera 110 # 16-57, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-03 11:18:00'),
('Laura Sofia Beltran Pinzon', '1015441921', 'laura.beltran@example.com', '359 912 1711', 'Carrera 18 # 142-27, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-11 13:19:00'),
('Tienda San Jose', '860393046-4', 'compras@tiendasanjose.example.com', '601 510 8054', 'Carrera 16 # 15-55, Funza', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista'), '2026-08-11 10:32:00')
ON DUPLICATE KEY UPDATE documento = documento;

-- 2.9 Ventas (110)
-- numero_venta usa el formato de VentasDao: V-yyyyMMddHHmmssSSS con la fecha de la venta.
-- Totales = suma de sus detalles (seccion 2.10):
--   subtotal = suma de subtotales, total_descuento = suma de monto_descuento,
--   total_impuesto = suma de monto_impuesto, monto_total = suma de total_linea.
-- IVA: ControladorVentas.TASA_IMPUESTO es 0, por eso tasa_impuesto y monto_impuesto son 0.
-- Estados: Entregada 87, En Transito 6, En Preparacion 10, Registrada 4, Cancelada 3.
-- Las ventas canceladas conservan su detalle pero no descuentan inventario.
INSERT INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro) VALUES
('V-20260902114427000', (SELECT id_cliente FROM clientes WHERE documento = '901266465-1'), '2026-09-02 11:44:27', 245000.00, 0.00, 0.00, 245000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260902155354000', (SELECT id_cliente FROM clientes WHERE documento = '901834485-6'), '2026-09-02 15:53:54', 420900.00, 30900.00, 0.00, 390000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260902155404000', (SELECT id_cliente FROM clientes WHERE documento = '830520546-1'), '2026-09-02 15:54:04', 69850.00, 0.00, 0.00, 69850.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260903122427000', (SELECT id_cliente FROM clientes WHERE documento = '900574716-2'), '2026-09-03 12:24:27', 340600.00, 72640.00, 0.00, 267960.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260903140018000', (SELECT id_cliente FROM clientes WHERE documento = '830403989-1'), '2026-09-03 14:00:18', 768250.00, 0.00, 0.00, 768250.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260904123420000', (SELECT id_cliente FROM clientes WHERE documento = '395448473'), '2026-09-04 12:34:20', 45600.00, 0.00, 0.00, 45600.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260904143325000', (SELECT id_cliente FROM clientes WHERE documento = '860252314-9'), '2026-09-04 14:33:25', 653500.00, 35100.00, 0.00, 618400.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260904165625000', (SELECT id_cliente FROM clientes WHERE documento = '1015441921'), '2026-09-04 16:56:25', 52050.00, 0.00, 0.00, 52050.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260905082432000', (SELECT id_cliente FROM clientes WHERE documento = '830611618-4'), '2026-09-05 08:24:32', 16300.00, 0.00, 0.00, 16300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260905085105000', (SELECT id_cliente FROM clientes WHERE documento = '900880426-3'), '2026-09-05 08:51:05', 38400.00, 4500.00, 0.00, 33900.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260905100418000', (SELECT id_cliente FROM clientes WHERE documento = '830611618-4'), '2026-09-05 10:04:18', 11700.00, 0.00, 0.00, 11700.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260905113710000', (SELECT id_cliente FROM clientes WHERE documento = '830984101-9'), '2026-09-05 11:37:10', 153150.00, 0.00, 0.00, 153150.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260905122437000', (SELECT id_cliente FROM clientes WHERE documento = '1010180295'), '2026-09-05 12:24:37', 33760.00, 0.00, 0.00, 33760.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260907142837000', (SELECT id_cliente FROM clientes WHERE documento = '901763724-6'), '2026-09-07 14:28:37', 415750.00, 0.00, 0.00, 415750.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260908095617000', (SELECT id_cliente FROM clientes WHERE documento = '860393046-4'), '2026-09-08 09:56:17', 57600.00, 0.00, 0.00, 57600.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260908151829000', (SELECT id_cliente FROM clientes WHERE documento = '900574716-2'), '2026-09-08 15:18:29', 497050.00, 16820.00, 0.00, 480230.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Cancelada'), 'jpineda'),
('V-20260909083008000', (SELECT id_cliente FROM clientes WHERE documento = '830490236-3'), '2026-09-09 08:30:08', 426100.00, 39000.00, 0.00, 387100.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260909105928000', (SELECT id_cliente FROM clientes WHERE documento = '830891865-7'), '2026-09-09 10:59:28', 19550.00, 0.00, 0.00, 19550.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260909122044000', (SELECT id_cliente FROM clientes WHERE documento = '1015441921'), '2026-09-09 12:20:44', 46825.00, 0.00, 0.00, 46825.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260909131414000', (SELECT id_cliente FROM clientes WHERE documento = '419859414'), '2026-09-09 13:14:14', 6600.00, 0.00, 0.00, 6600.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260909164616000', (SELECT id_cliente FROM clientes WHERE documento = '830626033-1'), '2026-09-09 16:46:16', 29400.00, 0.00, 0.00, 29400.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260910145439000', (SELECT id_cliente FROM clientes WHERE documento = '830378414-1'), '2026-09-10 14:54:39', 621950.00, 0.00, 0.00, 621950.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Cancelada'), 'lmartinez'),
('V-20260911110911000', (SELECT id_cliente FROM clientes WHERE documento = '900107517-1'), '2026-09-11 11:09:11', 548900.00, 0.00, 0.00, 548900.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260911134623000', (SELECT id_cliente FROM clientes WHERE documento = '830199613-0'), '2026-09-11 13:46:23', 87200.00, 6480.00, 0.00, 80720.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260912121643000', (SELECT id_cliente FROM clientes WHERE documento = '860737809-5'), '2026-09-12 12:16:43', 25500.00, 10200.00, 0.00, 15300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260912141537000', (SELECT id_cliente FROM clientes WHERE documento = '830891865-7'), '2026-09-12 14:15:37', 28600.00, 8580.00, 0.00, 20020.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260914105916000', (SELECT id_cliente FROM clientes WHERE documento = '860951566-7'), '2026-09-14 10:59:16', 553800.00, 38925.00, 0.00, 514875.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260914124855000', (SELECT id_cliente FROM clientes WHERE documento = '830851925-1'), '2026-09-14 12:48:55', 160500.00, 48450.00, 0.00, 112050.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260914151600000', (SELECT id_cliente FROM clientes WHERE documento = '900818033-1'), '2026-09-14 15:16:00', 107100.00, 35840.00, 0.00, 71260.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260914164433000', (SELECT id_cliente FROM clientes WHERE documento = '830423958-7'), '2026-09-14 16:44:33', 583400.00, 103800.00, 0.00, 479600.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260915151810000', (SELECT id_cliente FROM clientes WHERE documento = '1020816213'), '2026-09-15 15:18:10', 42000.00, 12600.00, 0.00, 29400.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260916094235000', (SELECT id_cliente FROM clientes WHERE documento = '394810202'), '2026-09-16 09:42:35', 25200.00, 0.00, 0.00, 25200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260916102049000', (SELECT id_cliente FROM clientes WHERE documento = '901709683-3'), '2026-09-16 10:20:49', 3300.00, 990.00, 0.00, 2310.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260916144447000', (SELECT id_cliente FROM clientes WHERE documento = '900107517-1'), '2026-09-16 14:44:47', 471900.00, 72000.00, 0.00, 399900.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260917095234000', (SELECT id_cliente FROM clientes WHERE documento = '900782265-4'), '2026-09-17 09:52:34', 142100.00, 2880.00, 0.00, 139220.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260917160714000', (SELECT id_cliente FROM clientes WHERE documento = '901495800-8'), '2026-09-17 16:07:14', 92200.00, 3720.00, 0.00, 88480.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260918133913000', (SELECT id_cliente FROM clientes WHERE documento = '1015188440'), '2026-09-18 13:39:13', 207100.00, 0.00, 0.00, 207100.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260918143232000', (SELECT id_cliente FROM clientes WHERE documento = '830490236-3'), '2026-09-18 14:32:32', 631800.00, 92400.00, 0.00, 539400.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260918162638000', (SELECT id_cliente FROM clientes WHERE documento = '900679844-9'), '2026-09-18 16:26:38', 487100.00, 58500.00, 0.00, 428600.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Cancelada'), 'jpineda'),
('V-20260919101335000', (SELECT id_cliente FROM clientes WHERE documento = '830891865-7'), '2026-09-19 10:13:35', 13350.00, 4005.00, 0.00, 9345.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260919102443000', (SELECT id_cliente FROM clientes WHERE documento = '830317404-5'), '2026-09-19 10:24:43', 379050.00, 13350.00, 0.00, 365700.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260919132958000', (SELECT id_cliente FROM clientes WHERE documento = '830378414-1'), '2026-09-19 13:29:58', 593600.00, 27240.00, 0.00, 566360.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260921091208000', (SELECT id_cliente FROM clientes WHERE documento = '197894450'), '2026-09-21 09:12:08', 88300.00, 0.00, 0.00, 88300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260921102039000', (SELECT id_cliente FROM clientes WHERE documento = '900818033-1'), '2026-09-21 10:20:39', 35900.00, 7800.00, 0.00, 28100.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260922095644000', (SELECT id_cliente FROM clientes WHERE documento = '860737809-5'), '2026-09-22 09:56:44', 39200.00, 0.00, 0.00, 39200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260922105343000', (SELECT id_cliente FROM clientes WHERE documento = '901834485-6'), '2026-09-22 10:53:43', 258300.00, 6600.00, 0.00, 251700.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260922122639000', (SELECT id_cliente FROM clientes WHERE documento = '1020429903'), '2026-09-22 12:26:39', 14400.00, 0.00, 0.00, 14400.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260922130636000', (SELECT id_cliente FROM clientes WHERE documento = '900679844-9'), '2026-09-22 13:06:36', 139450.00, 0.00, 0.00, 139450.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260923081418000', (SELECT id_cliente FROM clientes WHERE documento = '860951566-7'), '2026-09-23 08:14:18', 377500.00, 0.00, 0.00, 377500.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260923151536000', (SELECT id_cliente FROM clientes WHERE documento = '901763724-6'), '2026-09-23 15:15:36', 1001950.00, 0.00, 0.00, 1001950.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20260924140203000', (SELECT id_cliente FROM clientes WHERE documento = '196129980'), '2026-09-24 14:02:03', 53650.00, 0.00, 0.00, 53650.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260926085210000', (SELECT id_cliente FROM clientes WHERE documento = '830423958-7'), '2026-09-26 08:52:10', 502600.00, 32400.00, 0.00, 470200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260926110012000', (SELECT id_cliente FROM clientes WHERE documento = '830816147-8'), '2026-09-26 11:00:12', 502650.00, 0.00, 0.00, 502650.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260926133856000', (SELECT id_cliente FROM clientes WHERE documento = '830891865-7'), '2026-09-26 13:38:56', 120000.00, 0.00, 0.00, 120000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260926154016000', (SELECT id_cliente FROM clientes WHERE documento = '901834485-6'), '2026-09-26 15:40:16', 252300.00, 40200.00, 0.00, 212100.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260926155802000', (SELECT id_cliente FROM clientes WHERE documento = '900880426-3'), '2026-09-26 15:58:02', 44425.00, 0.00, 0.00, 44425.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260926164131000', (SELECT id_cliente FROM clientes WHERE documento = '830816147-8'), '2026-09-26 16:41:31', 218300.00, 14070.00, 0.00, 204230.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260928115841000', (SELECT id_cliente FROM clientes WHERE documento = '830851925-1'), '2026-09-28 11:58:41', 373150.00, 0.00, 0.00, 373150.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260928122243000', (SELECT id_cliente FROM clientes WHERE documento = '901834485-6'), '2026-09-28 12:22:43', 413150.00, 0.00, 0.00, 413150.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20260930091515000', (SELECT id_cliente FROM clientes WHERE documento = '900679844-9'), '2026-09-30 09:15:15', 592800.00, 0.00, 0.00, 592800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20260930112904000', (SELECT id_cliente FROM clientes WHERE documento = '830851925-1'), '2026-09-30 11:29:04', 295500.00, 0.00, 0.00, 295500.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261001124951000', (SELECT id_cliente FROM clientes WHERE documento = '7990476709'), '2026-10-01 12:49:51', 120040.00, 0.00, 0.00, 120040.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261001145245000', (SELECT id_cliente FROM clientes WHERE documento = '900782265-4'), '2026-10-01 14:52:45', 304200.00, 0.00, 0.00, 304200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261001161647000', (SELECT id_cliente FROM clientes WHERE documento = '901763724-6'), '2026-10-01 16:16:47', 237800.00, 0.00, 0.00, 237800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261003145725000', (SELECT id_cliente FROM clientes WHERE documento = '830536890-0'), '2026-10-03 14:57:25', 34350.00, 0.00, 0.00, 34350.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261005090611000', (SELECT id_cliente FROM clientes WHERE documento = '860173712-8'), '2026-10-05 09:06:11', 133000.00, 0.00, 0.00, 133000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261005125509000', (SELECT id_cliente FROM clientes WHERE documento = '1020115879'), '2026-10-05 12:55:09', 99200.00, 0.00, 0.00, 99200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261006132250000', (SELECT id_cliente FROM clientes WHERE documento = '830490236-3'), '2026-10-06 13:22:50', 337660.00, 71148.00, 0.00, 266512.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261007091839000', (SELECT id_cliente FROM clientes WHERE documento = '830403989-1'), '2026-10-07 09:18:39', 643100.00, 0.00, 0.00, 643100.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261008083520000', (SELECT id_cliente FROM clientes WHERE documento = '900107517-1'), '2026-10-08 08:35:20', 343350.00, 0.00, 0.00, 343350.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261008084053000', (SELECT id_cliente FROM clientes WHERE documento = '1020816213'), '2026-10-08 08:40:53', 86750.00, 24800.00, 0.00, 61950.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261008091631000', (SELECT id_cliente FROM clientes WHERE documento = '900759812-7'), '2026-10-08 09:16:31', 228000.00, 0.00, 0.00, 228000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261008130039000', (SELECT id_cliente FROM clientes WHERE documento = '860393046-4'), '2026-10-08 13:00:39', 18600.00, 0.00, 0.00, 18600.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261009092500000', (SELECT id_cliente FROM clientes WHERE documento = '830984101-9'), '2026-10-09 09:25:00', 16250.00, 0.00, 0.00, 16250.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261009122601000', (SELECT id_cliente FROM clientes WHERE documento = '860173712-8'), '2026-10-09 12:26:01', 374600.00, 15030.00, 0.00, 359570.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261009134113000', (SELECT id_cliente FROM clientes WHERE documento = '197894450'), '2026-10-09 13:41:13', 10350.00, 0.00, 0.00, 10350.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261009150958000', (SELECT id_cliente FROM clientes WHERE documento = '1015441921'), '2026-10-09 15:09:58', 74400.00, 0.00, 0.00, 74400.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261010082538000', (SELECT id_cliente FROM clientes WHERE documento = '830984101-9'), '2026-10-10 08:25:38', 34500.00, 0.00, 0.00, 34500.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261010110304000', (SELECT id_cliente FROM clientes WHERE documento = '900880426-3'), '2026-10-10 11:03:04', 33200.00, 9920.00, 0.00, 23280.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261010125643000', (SELECT id_cliente FROM clientes WHERE documento = '830816147-8'), '2026-10-10 12:56:43', 845200.00, 0.00, 0.00, 845200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261010164748000', (SELECT id_cliente FROM clientes WHERE documento = '830199613-0'), '2026-10-10 16:47:48', 81000.00, 0.00, 0.00, 81000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261013101837000', (SELECT id_cliente FROM clientes WHERE documento = '900574716-2'), '2026-10-13 10:18:37', 69200.00, 0.00, 0.00, 69200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261013125226000', (SELECT id_cliente FROM clientes WHERE documento = '901670233-1'), '2026-10-13 12:52:26', 318250.00, 0.00, 0.00, 318250.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261013163958000', (SELECT id_cliente FROM clientes WHERE documento = '1015441921'), '2026-10-13 16:39:58', 95225.00, 0.00, 0.00, 95225.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261014112401000', (SELECT id_cliente FROM clientes WHERE documento = '860951566-7'), '2026-10-14 11:24:01', 303500.00, 0.00, 0.00, 303500.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261014150111000', (SELECT id_cliente FROM clientes WHERE documento = '860173712-8'), '2026-10-14 15:01:11', 312150.00, 0.00, 0.00, 312150.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261016112536000', (SELECT id_cliente FROM clientes WHERE documento = '830626033-1'), '2026-10-16 11:25:36', 20200.00, 0.00, 0.00, 20200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261016132250000', (SELECT id_cliente FROM clientes WHERE documento = '900804298-3'), '2026-10-16 13:22:50', 249800.00, 0.00, 0.00, 249800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'jpineda'),
('V-20261017092510000', (SELECT id_cliente FROM clientes WHERE documento = '830816147-8'), '2026-10-17 09:25:10', 384900.00, 0.00, 0.00, 384900.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'lmartinez'),
('V-20261017132202000', (SELECT id_cliente FROM clientes WHERE documento = '860173712-8'), '2026-10-17 13:22:02', 390300.00, 0.00, 0.00, 390300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Entregada'), 'dvargas'),
('V-20261019112437000', (SELECT id_cliente FROM clientes WHERE documento = '1010771312'), '2026-10-19 11:24:37', 116700.00, 0.00, 0.00, 116700.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Transito'), 'jpineda'),
('V-20261020082334000', (SELECT id_cliente FROM clientes WHERE documento = '196129980'), '2026-10-20 08:23:34', 80800.00, 0.00, 0.00, 80800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Transito'), 'dvargas'),
('V-20261021164505000', (SELECT id_cliente FROM clientes WHERE documento = '901266465-1'), '2026-10-21 16:45:05', 337800.00, 0.00, 0.00, 337800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Transito'), 'lmartinez'),
('V-20261022105400000', (SELECT id_cliente FROM clientes WHERE documento = '1012539771'), '2026-10-22 10:54:00', 5250.00, 1575.00, 0.00, 3675.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Transito'), 'lmartinez'),
('V-20261022111512000', (SELECT id_cliente FROM clientes WHERE documento = '1012539771'), '2026-10-22 11:15:12', 50225.00, 0.00, 0.00, 50225.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Transito'), 'jpineda'),
('V-20261023105852000', (SELECT id_cliente FROM clientes WHERE documento = '901266465-1'), '2026-10-23 10:58:52', 554300.00, 0.00, 0.00, 554300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Transito'), 'lmartinez'),
('V-20261024124600000', (SELECT id_cliente FROM clientes WHERE documento = '5219221410'), '2026-10-24 12:46:00', 51400.00, 4200.00, 0.00, 47200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'dvargas'),
('V-20261026121127000', (SELECT id_cliente FROM clientes WHERE documento = '1020816213'), '2026-10-26 12:11:27', 72100.00, 0.00, 0.00, 72100.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'jpineda'),
('V-20261027083325000', (SELECT id_cliente FROM clientes WHERE documento = '860252314-9'), '2026-10-27 08:33:25', 464200.00, 0.00, 0.00, 464200.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'jpineda'),
('V-20261027111232000', (SELECT id_cliente FROM clientes WHERE documento = '830891865-7'), '2026-10-27 11:12:32', 111900.00, 0.00, 0.00, 111900.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'dvargas'),
('V-20261027112414000', (SELECT id_cliente FROM clientes WHERE documento = '900679844-9'), '2026-10-27 11:24:14', 428800.00, 0.00, 0.00, 428800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'dvargas'),
('V-20261027134135000', (SELECT id_cliente FROM clientes WHERE documento = '5220512050'), '2026-10-27 13:41:35', 14850.00, 0.00, 0.00, 14850.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'lmartinez'),
('V-20261027152159000', (SELECT id_cliente FROM clientes WHERE documento = '830427273-9'), '2026-10-27 15:21:59', 31700.00, 3900.00, 0.00, 27800.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'jpineda'),
('V-20261028131728000', (SELECT id_cliente FROM clientes WHERE documento = '830611618-4'), '2026-10-28 13:17:28', 46800.00, 2340.00, 0.00, 44460.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'dvargas'),
('V-20261028132120000', (SELECT id_cliente FROM clientes WHERE documento = '860252314-9'), '2026-10-28 13:21:20', 447300.00, 0.00, 0.00, 447300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'dvargas'),
('V-20261028142718000', (SELECT id_cliente FROM clientes WHERE documento = '900679844-9'), '2026-10-28 14:27:18', 748000.00, 0.00, 0.00, 748000.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'En Preparacion'), 'dvargas'),
('V-20261029132920000', (SELECT id_cliente FROM clientes WHERE documento = '901670233-1'), '2026-10-29 13:29:20', 687750.00, 43680.00, 0.00, 644070.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada'), 'jpineda'),
('V-20261030100607000', (SELECT id_cliente FROM clientes WHERE documento = '901266465-1'), '2026-10-30 10:06:07', 566350.00, 0.00, 0.00, 566350.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada'), 'lmartinez'),
('V-20261030101853000', (SELECT id_cliente FROM clientes WHERE documento = '830626033-1'), '2026-10-30 10:18:53', 64350.00, 5850.00, 0.00, 58500.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada'), 'jpineda'),
('V-20261031125424000', (SELECT id_cliente FROM clientes WHERE documento = '830816147-8'), '2026-10-31 12:54:24', 615300.00, 0.00, 0.00, 615300.00, (SELECT id_estado FROM estados_venta WHERE nombre = 'Registrada'), 'jpineda')
ON DUPLICATE KEY UPDATE numero_venta = numero_venta;

-- 2.10 Detalles de venta
-- Calculo por linea (igual que LineaPedido):
--   subtotal = cantidad_vendida * precio_unitario
--   monto_descuento = subtotal * descuento_aplicado
--   monto_impuesto = (subtotal - monto_descuento) * tasa_impuesto   (tasa 0)
--   total_linea = subtotal - monto_descuento + monto_impuesto
-- Los lotes se tomaron por FEFO (el que vence primero sale primero); si un lote no alcanzaba,
-- la cantidad se completo con el siguiente lote del mismo producto.
-- Cada bloque inserta las lineas de una venta solo si esa venta todavia no tiene detalles.

-- V-20260902114427000 | Catering Eventos Gourmet S.A.S. | Entregada | total 245000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902114427000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-46-46-20260831-061000') AS id_lote, 20.00 AS cantidad, 6500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 130000.00 AS subtotal, 130000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260828-074500'), 18.00, 3500.00, 0.00, 0.00, 0.00, 0.00, 63000.00, 63000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-2-6-20260830-051000'), 10.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 52000.00, 52000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260902155354000 | Clinica Santa Ana - Servicio de Alimentacion | Entregada | total 390000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902155354000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-21-23-20260829-061000') AS id_lote, 6.00 AS cantidad, 19400.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 116400.00 AS subtotal, 116400.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-3-3-20260828-061500'), 10.00, 10300.00, 0.30, 30900.00, 0.00, 0.00, 103000.00, 72100.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-46-46-20260831-061000'), 31.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 201500.00, 201500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260902155404000 | Heladeria y Fruteria Coco Loco | Entregada | total 69850.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902155404000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-30-26-20260902-074500') AS id_lote, 1.00 AS cantidad, 19450.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 19450.00 AS subtotal, 19450.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-22-19-20260827-070000'), 2.00, 25200.00, 0.00, 0.00, 0.00, 0.00, 50400.00, 50400.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260903122427000 | Restaurante Sabor del Pacifico | Entregada | total 267960.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260903122427000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-40-37-20260903-054500') AS id_lote, 15.00 AS cantidad, 5400.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 81000.00 AS subtotal, 81000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-48-48-20260830-054000'), 40.00, 1450.00, 0.40, 23200.00, 0.00, 0.00, 58000.00, 34800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-3-3-20260828-061500'), 16.00, 10300.00, 0.30, 49440.00, 0.00, 0.00, 164800.00, 115360.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 23.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 36800.00, 36800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260903140018000 | Minimercado Don Pacho | Entregada | total 768250.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260903140018000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260902-062000') AS id_lote, 15.00 AS cantidad, 5600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 84000.00 AS subtotal, 84000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-30-26-20260902-074500'), 13.00, 19450.00, 0.00, 0.00, 0.00, 0.00, 252850.00, 252850.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-25-20-20260903-060000'), 9.00, 17600.00, 0.00, 0.00, 0.00, 0.00, 158400.00, 158400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-37-37-20260831-052000'), 35.00, 7800.00, 0.00, 0.00, 0.00, 0.00, 273000.00, 273000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260904123420000 | Tienda Dona Rosa | Entregada | total 45600.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904123420000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-25-20-20260903-060000') AS id_lote, 1.00 AS cantidad, 17600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 17600.00 AS subtotal, 17600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260902-062000'), 5.00, 5600.00, 0.00, 0.00, 0.00, 0.00, 28000.00, 28000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260904143325000 | Comedor Comunitario San Mateo | Entregada | total 618400.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904143325000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-19-21-20260903-055000') AS id_lote, 40.00 AS cantidad, 4300.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 172000.00 AS subtotal, 172000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-18-11-20260827-074000'), 15.00, 7800.00, 0.30, 35100.00, 0.00, 0.00, 117000.00, 81900.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-22-19-20260827-070000'), 6.00, 25200.00, 0.00, 0.00, 0.00, 0.00, 151200.00, 151200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-23-25-20260903-074000'), 27.00, 7900.00, 0.00, 0.00, 0.00, 0.00, 213300.00, 213300.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260904165625000 | Laura Sofia Beltran Pinzon | Entregada | total 52050.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904165625000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260902-062000') AS id_lote, 3.00 AS cantidad, 5600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 16800.00 AS subtotal, 16800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-5-5-20260903-051500'), 5.00, 7050.00, 0.00, 0.00, 0.00, 0.00, 35250.00, 35250.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260905082432000 | Tienda El Paisa | Entregada | total 16300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905082432000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000') AS id_lote, 2.00 AS cantidad, 8150.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 16300.00 AS subtotal, 16300.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260905085105000 | Cafe Bar El Rincon | Entregada | total 33900.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905085105000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-16-18-20260828-054500') AS id_lote, 6.00 AS cantidad, 2500.00 AS precio, 0.30 AS descuento, 4500.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 15000.00 AS subtotal, 10500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-10-10-20260903-062000'), 6.00, 3900.00, 0.00, 0.00, 0.00, 0.00, 23400.00, 23400.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260905100418000 | Tienda El Paisa | Entregada | total 11700.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905100418000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-10-10-20260903-062000') AS id_lote, 3.00 AS cantidad, 3900.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 11700.00 AS subtotal, 11700.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260905113710000 | Comidas Rapidas El Gordo | Entregada | total 153150.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905113710000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-5-5-20260903-051500') AS id_lote, 5.00 AS cantidad, 7050.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 35250.00 AS subtotal, 35250.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000'), 9.00, 8900.00, 0.00, 0.00, 0.00, 0.00, 80100.00, 80100.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-22-19-20260827-070000'), 1.50, 25200.00, 0.00, 0.00, 0.00, 0.00, 37800.00, 37800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260905122437000 | Daniela Ospina Vargas | Entregada | total 33760.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905122437000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500') AS id_lote, 2.00 AS cantidad, 6500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 13000.00 AS subtotal, 13000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-26-28-20260905-061000'), 1.20, 17300.00, 0.00, 0.00, 0.00, 0.00, 20760.00, 20760.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260907142837000 | Colegio Campestre Los Alpes | Entregada | total 415750.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260907142837000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-5-5-20260903-051500') AS id_lote, 15.00 AS cantidad, 7050.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 105750.00 AS subtotal, 105750.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-27-29-20260906-075000'), 25.00, 12400.00, 0.00, 0.00, 0.00, 0.00, 310000.00, 310000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260908095617000 | Tienda San Jose | Entregada | total 57600.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260908095617000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-6-6-20260903-055000') AS id_lote, 6.00 AS cantidad, 9600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 57600.00 AS subtotal, 57600.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260908151829000 | Restaurante Sabor del Pacifico | Cancelada | total 480230.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260908151829000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260828-074500') AS id_lote, 40.00 AS cantidad, 3500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 140000.00 AS subtotal, 140000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-48-48-20260830-054000'), 29.00, 1450.00, 0.40, 16820.00, 0.00, 0.00, 42050.00, 25230.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-29-29-20260906-060000'), 15.00, 21000.00, 0.00, 0.00, 0.00, 0.00, 315000.00, 315000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260909083008000 | Supermercado El Vecino Ltda. | Entregada | total 387100.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909083008000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-47-47-20260908-054500') AS id_lote, 49.00 AS cantidad, 1500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 73500.00 AS subtotal, 73500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-2-6-20260830-051000'), 25.00, 5200.00, 0.30, 39000.00, 0.00, 0.00, 130000.00, 91000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-22-19-20260827-070000'), 7.50, 25200.00, 0.00, 0.00, 0.00, 0.00, 189000.00, 189000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 8.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 33600.00, 33600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260909105928000 | Fruver Las Margaritas | Entregada | total 19550.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909105928000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-20-20-20260905-054500') AS id_lote, 1.50 AS cantidad, 8900.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 13350.00 AS subtotal, 13350.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-1-3-20260906-063000'), 2.00, 3100.00, 0.00, 0.00, 0.00, 0.00, 6200.00, 6200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260909122044000 | Laura Sofia Beltran Pinzon | Entregada | total 46825.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909122044000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20260905-055000') AS id_lote, 8.00 AS cantidad, 3350.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 26800.00 AS subtotal, 26800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 1.50, 8150.00, 0.00, 0.00, 0.00, 0.00, 12225.00, 12225.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500'), 3.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 7800.00, 7800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260909131414000 | Tienda Mi Barrio | Entregada | total 6600.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909131414000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260830-055000') AS id_lote, 3.00 AS cantidad, 2200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 6600.00 AS subtotal, 6600.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260909164616000 | Tienda La Bendicion | Entregada | total 29400.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909164616000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000') AS id_lote, 3.00 AS cantidad, 9800.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 29400.00 AS subtotal, 29400.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260910145439000 | Restaurante Wok y Arroz | Cancelada | total 621950.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260910145439000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000') AS id_lote, 52.00 AS cantidad, 8900.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 462800.00 AS subtotal, 462800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 18.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 75600.00, 75600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 39.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 62400.00, 62400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-5-5-20260903-051500'), 3.00, 7050.00, 0.00, 0.00, 0.00, 0.00, 21150.00, 21150.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260911110911000 | Supermercado Cajica Express | Entregada | total 548900.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260911110911000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500') AS id_lote, 48.00 AS cantidad, 5200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 249600.00 AS subtotal, 249600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 19.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 30400.00, 30400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500'), 12.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 31200.00, 31200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-20-20-20260905-054500'), 18.00, 8900.00, 0.00, 0.00, 0.00, 0.00, 160200.00, 160200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-1-3-20260906-063000'), 25.00, 3100.00, 0.00, 0.00, 0.00, 0.00, 77500.00, 77500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260911134623000 | Tienda Naturista Vida Sana | Entregada | total 80720.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260911134623000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 8.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 39600.00 AS subtotal, 39600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-17-17-20260908-060000'), 4.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 26000.00, 26000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-40-37-20260903-054500'), 4.00, 5400.00, 0.30, 6480.00, 0.00, 0.00, 21600.00, 15120.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260912121643000 | Tienda La Esquina de Juan | Entregada | total 15300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260912121643000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-47-47-20260908-054500') AS id_lote, 17.00 AS cantidad, 1500.00 AS precio, 0.40 AS descuento, 10200.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 25500.00 AS subtotal, 15300.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260912141537000 | Fruver Las Margaritas | Entregada | total 20020.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260912141537000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-9-2-20260829-064000') AS id_lote, 4.00 AS cantidad, 7150.00 AS precio, 0.30 AS descuento, 8580.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 28600.00 AS subtotal, 20020.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260914105916000 | Fruver La Cosecha de Usaquen | Entregada | total 514875.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914105916000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-41-41-20260908-051000') AS id_lote, 15.00 AS cantidad, 7600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 114000.00 AS subtotal, 114000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260828-074500'), 15.00, 3500.00, 0.00, 0.00, 0.00, 0.00, 52500.00, 52500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-49-49-20260908-073000'), 51.00, 5050.00, 0.00, 0.00, 0.00, 0.00, 257550.00, 257550.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-26-28-20260905-061000'), 7.50, 17300.00, 0.30, 38925.00, 0.00, 0.00, 129750.00, 90825.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260914124855000 | Hotel Boutique Calle 70 | Entregada | total 112050.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914124855000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-29-29-20260906-060000') AS id_lote, 7.50 AS cantidad, 21000.00 AS precio, 0.30 AS descuento, 47250.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 157500.00 AS subtotal, 110250.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-47-47-20260908-054500'), 2.00, 1500.00, 0.40, 1200.00, 0.00, 0.00, 3000.00, 1800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260914151600000 | Lonchera Escolar Don Jorge | Entregada | total 71260.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914151600000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260828-074500') AS id_lote, 5.00 AS cantidad, 3500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 17500.00 AS subtotal, 17500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-50-49-20260904-051500'), 16.00, 5600.00, 0.40, 35840.00, 0.00, 0.00, 89600.00, 53760.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260914164433000 | Supermercado Mercafacil Soacha | Entregada | total 479600.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914164433000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-17-17-20260908-060000') AS id_lote, 13.00 AS cantidad, 6500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 84500.00 AS subtotal, 84500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-41-41-20260908-051000'), 4.00, 7600.00, 0.00, 0.00, 0.00, 0.00, 30400.00, 30400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260828-074500'), 35.00, 3500.00, 0.00, 0.00, 0.00, 0.00, 122500.00, 122500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-26-28-20260905-061000'), 20.00, 17300.00, 0.30, 103800.00, 0.00, 0.00, 346000.00, 242200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260915151810000 | Camila Andrea Rojas Quintero | Entregada | total 29400.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260915151810000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-29-29-20260906-060000') AS id_lote, 2.00 AS cantidad, 21000.00 AS precio, 0.30 AS descuento, 12600.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 42000.00 AS subtotal, 29400.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260916094235000 | Tienda Surtifruver 80 | Entregada | total 25200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916094235000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000') AS id_lote, 6.00 AS cantidad, 4200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 25200.00 AS subtotal, 25200.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260916102049000 | Tienda Los Hermanos | Entregada | total 2310.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916102049000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260830-055000') AS id_lote, 1.50 AS cantidad, 2200.00 AS precio, 0.30 AS descuento, 990.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 3300.00 AS subtotal, 2310.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260916144447000 | Supermercado Cajica Express | Entregada | total 399900.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916144447000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500') AS id_lote, 30.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 78000.00 AS subtotal, 78000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20260905-055000'), 18.00, 3350.00, 0.00, 0.00, 0.00, 0.00, 60300.00, 60300.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 18.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 93600.00, 93600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-6-6-20260903-055000'), 25.00, 9600.00, 0.30, 72000.00, 0.00, 0.00, 240000.00, 168000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260917095234000 | Hogar Geriatrico Los Robles | Entregada | total 139220.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260917095234000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500') AS id_lote, 25.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 65000.00 AS subtotal, 65000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), 15.00, 4500.00, 0.00, 0.00, 0.00, 0.00, 67500.00, 67500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-6-6-20260903-055000'), 1.00, 9600.00, 0.30, 2880.00, 0.00, 0.00, 9600.00, 6720.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260917160714000 | Cigarreria y Tienda La 45 | Entregada | total 88480.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260917160714000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-1-3-20260906-063000') AS id_lote, 4.00 AS cantidad, 3100.00 AS precio, 0.30 AS descuento, 3720.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 12400.00 AS subtotal, 8680.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-31-27-20260908-064500'), 4.00, 19950.00, 0.00, 0.00, 0.00, 0.00, 79800.00, 79800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260918133913000 | Valentina Gomez Arias | Entregada | total 207100.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918133913000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000') AS id_lote, 9.00 AS cantidad, 6200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 55800.00 AS subtotal, 55800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000'), 17.00, 8900.00, 0.00, 0.00, 0.00, 0.00, 151300.00, 151300.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260918143232000 | Supermercado El Vecino Ltda. | Entregada | total 539400.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918143232000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500') AS id_lote, 28.00 AS cantidad, 5200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 145600.00 AS subtotal, 145600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), 15.00, 4500.00, 0.00, 0.00, 0.00, 0.00, 67500.00, 67500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-24-24-20260827-071500'), 20.00, 15400.00, 0.30, 92400.00, 0.00, 0.00, 308000.00, 215600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260918-055000'), 18.00, 6150.00, 0.00, 0.00, 0.00, 0.00, 110700.00, 110700.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260918162638000 | Fruteria Tropical Funza | Cancelada | total 428600.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918162638000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 47.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 211500.00 AS subtotal, 211500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-39-39-20260903-064500'), 30.00, 6500.00, 0.30, 58500.00, 0.00, 0.00, 195000.00, 136500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 13.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 80600.00, 80600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260919101335000 | Fruver Las Margaritas | Entregada | total 9345.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919101335000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-20-20-20260905-054500') AS id_lote, 1.50 AS cantidad, 8900.00 AS precio, 0.30 AS descuento, 4005.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 13350.00 AS subtotal, 9345.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260919102443000 | Hotel Andino Plaza S.A.S. | Entregada | total 365700.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919102443000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 25.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 123750.00 AS subtotal, 123750.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-20-20-20260905-054500'), 5.00, 8900.00, 0.30, 13350.00, 0.00, 0.00, 44500.00, 31150.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 34.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 210800.00, 210800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260919132958000 | Restaurante Wok y Arroz | Entregada | total 566360.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919132958000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000') AS id_lote, 30.00 AS cantidad, 4200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 126000.00 AS subtotal, 126000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-1-3-20260906-063000'), 8.00, 3100.00, 0.30, 7440.00, 0.00, 0.00, 24800.00, 17360.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-37-37-20260918-064500'), 24.00, 7800.00, 0.00, 0.00, 0.00, 0.00, 187200.00, 187200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260830-055000'), 30.00, 2200.00, 0.30, 19800.00, 0.00, 0.00, 66000.00, 46200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-23-20-20260919-072000'), 24.00, 7900.00, 0.00, 0.00, 0.00, 0.00, 189600.00, 189600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260921091208000 | Tienda El Trebol | Entregada | total 88300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260921091208000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000') AS id_lote, 7.00 AS cantidad, 8900.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 62300.00 AS subtotal, 62300.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 4.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 26000.00, 26000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260921102039000 | Lonchera Escolar Don Jorge | Entregada | total 28100.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260921102039000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-39-39-20260903-064500') AS id_lote, 4.00 AS cantidad, 6500.00 AS precio, 0.30 AS descuento, 7800.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 26000.00 AS subtotal, 18200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 2.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 9900.00, 9900.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260922095644000 | Tienda La Esquina de Juan | Entregada | total 39200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922095644000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000') AS id_lote, 4.00 AS cantidad, 9800.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 39200.00 AS subtotal, 39200.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260922105343000 | Clinica Santa Ana - Servicio de Alimentacion | Entregada | total 251700.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922105343000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260830-055000') AS id_lote, 10.00 AS cantidad, 2200.00 AS precio, 0.30 AS descuento, 6600.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 22000.00 AS subtotal, 15400.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260918-055000'), 12.00, 6150.00, 0.00, 0.00, 0.00, 0.00, 73800.00, 73800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 25.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 162500.00, 162500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260922122639000 | Miguel Angel Torres Ruiz | Entregada | total 14400.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922122639000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000') AS id_lote, 9.00 AS cantidad, 1600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 14400.00 AS subtotal, 14400.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260922130636000 | Fruteria Tropical Funza | Entregada | total 139450.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922130636000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000') AS id_lote, 8.00 AS cantidad, 8150.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 65200.00 AS subtotal, 65200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 15.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 74250.00, 74250.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260923081418000 | Fruver La Cosecha de Usaquen | Entregada | total 377500.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260923081418000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 55.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 247500.00 AS subtotal, 247500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 25.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 130000.00, 130000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260923151536000 | Colegio Campestre Los Alpes | Entregada | total 1001950.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260923151536000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000') AS id_lote, 58.00 AS cantidad, 8900.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 516200.00 AS subtotal, 516200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 18.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 117000.00, 117000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000'), 25.00, 9800.00, 0.00, 0.00, 0.00, 0.00, 245000.00, 245000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 25.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 123750.00, 123750.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260924140203000 | Panaderia Pan Caliente | Entregada | total 53650.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260924140203000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000') AS id_lote, 16.00 AS cantidad, 1600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 25600.00 AS subtotal, 25600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20260918-055000'), 4.00, 6150.00, 0.00, 0.00, 0.00, 0.00, 24600.00, 24600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260922-074000'), 1.50, 2300.00, 0.00, 0.00, 0.00, 0.00, 3450.00, 3450.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260926085210000 | Supermercado Mercafacil Soacha | Entregada | total 470200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926085210000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000') AS id_lote, 33.00 AS cantidad, 6200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 204600.00 AS subtotal, 204600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-18-11-20260919-052000'), 15.00, 7200.00, 0.30, 32400.00, 0.00, 0.00, 108000.00, 75600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-4-6-20260925-073000'), 25.00, 7600.00, 0.00, 0.00, 0.00, 0.00, 190000.00, 190000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260926110012000 | Asadero El Llanerito | Entregada | total 502650.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926110012000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500') AS id_lote, 18.00 AS cantidad, 5200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 93600.00 AS subtotal, 93600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-31-27-20260908-064500'), 7.00, 19950.00, 0.00, 0.00, 0.00, 0.00, 139650.00, 139650.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 20.00, 8150.00, 0.00, 0.00, 0.00, 0.00, 163000.00, 163000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260922-074000'), 18.00, 2300.00, 0.00, 0.00, 0.00, 0.00, 41400.00, 41400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500'), 25.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 65000.00, 65000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260926133856000 | Fruver Las Margaritas | Entregada | total 120000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926133856000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000') AS id_lote, 8.00 AS cantidad, 9800.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 78400.00 AS subtotal, 78400.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 8.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 41600.00, 41600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260926154016000 | Clinica Santa Ana - Servicio de Alimentacion | Entregada | total 212100.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926154016000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000') AS id_lote, 13.00 AS cantidad, 1600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 20800.00 AS subtotal, 20800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20260905-055000'), 40.00, 3350.00, 0.30, 40200.00, 0.00, 0.00, 134000.00, 93800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 15.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 97500.00, 97500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260926155802000 | Cafe Bar El Rincon | Entregada | total 44425.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926155802000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 1.50 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 7425.00 AS subtotal, 7425.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500'), 5.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 13000.00, 13000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 15.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 24000.00, 24000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260926164131000 | Asadero El Llanerito | Entregada | total 204230.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926164131000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20260905-055000') AS id_lote, 14.00 AS cantidad, 3350.00 AS precio, 0.30 AS descuento, 14070.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 46900.00 AS subtotal, 32830.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 20.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 130000.00, 130000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260922-074000'), 18.00, 2300.00, 0.00, 0.00, 0.00, 0.00, 41400.00, 41400.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260928115841000 | Hotel Boutique Calle 70 | Entregada | total 373150.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260928115841000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000') AS id_lote, 25.00 AS cantidad, 8150.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 203750.00 AS subtotal, 203750.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 49.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 78400.00, 78400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500'), 35.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 91000.00, 91000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260928122243000 | Clinica Santa Ana - Servicio de Alimentacion | Entregada | total 413150.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260928122243000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20260922-074000') AS id_lote, 27.50 AS cantidad, 2300.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 63250.00 AS subtotal, 63250.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 10.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 49500.00, 49500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 49.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 254800.00, 254800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-4-6-20260925-073000'), 6.00, 7600.00, 0.00, 0.00, 0.00, 0.00, 45600.00, 45600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260930091515000 | Fruteria Tropical Funza | Entregada | total 592800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260930091515000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-41-40-20260928-050000') AS id_lote, 12.00 AS cantidad, 8350.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 100200.00 AS subtotal, 100200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 48.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 297600.00, 297600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 30.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 195000.00, 195000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20260930112904000 | Hotel Boutique Calle 70 | Entregada | total 295500.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260930112904000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-21-25-20260930-064000') AS id_lote, 7.50 AS cantidad, 19400.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 145500.00 AS subtotal, 145500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), 24.00, 4500.00, 0.00, 0.00, 0.00, 0.00, 108000.00, 108000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 10.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 42000.00, 42000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261001124951000 | Paula Andrea Martinez Gil | Entregada | total 120040.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001124951000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-28-28-20260929-051000') AS id_lote, 1.20 AS cantidad, 24200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 29040.00 AS subtotal, 29040.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-24-19-20260930-050000'), 3.00, 14000.00, 0.00, 0.00, 0.00, 0.00, 42000.00, 42000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000'), 5.00, 9800.00, 0.00, 0.00, 0.00, 0.00, 49000.00, 49000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261001145245000 | Hogar Geriatrico Los Robles | Entregada | total 304200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001145245000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-28-28-20260929-051000') AS id_lote, 4.00 AS cantidad, 24200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 96800.00 AS subtotal, 96800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-21-25-20260930-064000'), 3.50, 19400.00, 0.00, 0.00, 0.00, 0.00, 67900.00, 67900.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), 31.00, 4500.00, 0.00, 0.00, 0.00, 0.00, 139500.00, 139500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261001161647000 | Colegio Campestre Los Alpes | Entregada | total 237800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001161647000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500') AS id_lote, 12.00 AS cantidad, 6500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 78000.00 AS subtotal, 78000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-28-28-20260929-051000'), 4.00, 24200.00, 0.00, 0.00, 0.00, 0.00, 96800.00, 96800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), 14.00, 4500.00, 0.00, 0.00, 0.00, 0.00, 63000.00, 63000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261003145725000 | Frutas y Verduras Dona Ines | Entregada | total 34350.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261003145725000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 2.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 9900.00 AS subtotal, 9900.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 3.00, 8150.00, 0.00, 0.00, 0.00, 0.00, 24450.00, 24450.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261005090611000 | Cafeteria y Panaderia La Espiga | Entregada | total 133000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261005090611000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-15-20260907-064500') AS id_lote, 15.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 39000.00 AS subtotal, 39000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000'), 20.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 52000.00, 52000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260929-051500'), 12.00, 3500.00, 0.00, 0.00, 0.00, 0.00, 42000.00, 42000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261005125509000 | Carolina Mejia Restrepo | Entregada | total 99200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261005125509000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-24-19-20260930-050000') AS id_lote, 3.00 AS cantidad, 14000.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 42000.00 AS subtotal, 42000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 11.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 57200.00, 57200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261006132250000 | Supermercado El Vecino Ltda. | Entregada | total 266512.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261006132250000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000') AS id_lote, 30.00 AS cantidad, 1600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 48000.00 AS subtotal, 48000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260929-051500'), 15.00, 3500.00, 0.00, 0.00, 0.00, 0.00, 52500.00, 52500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-28-28-20260929-051000'), 9.80, 24200.00, 0.30, 71148.00, 0.00, 0.00, 237160.00, 166012.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261007091839000 | Minimercado Don Pacho | Entregada | total 643100.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261007091839000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000') AS id_lote, 31.00 AS cantidad, 8900.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 275900.00 AS subtotal, 275900.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000'), 12.00, 9800.00, 0.00, 0.00, 0.00, 0.00, 117600.00, 117600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 48.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 249600.00, 249600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261008083520000 | Supermercado Cajica Express | Entregada | total 343350.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008083520000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000') AS id_lote, 40.00 AS cantidad, 4200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 168000.00 AS subtotal, 168000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20261003-065000'), 25.00, 3450.00, 0.00, 0.00, 0.00, 0.00, 86250.00, 86250.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 18.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 89100.00, 89100.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261008084053000 | Camila Andrea Rojas Quintero | Entregada | total 61950.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008084053000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 5.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 24750.00 AS subtotal, 24750.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-46-50-20260929-063000'), 10.00, 6200.00, 0.40, 24800.00, 0.00, 0.00, 62000.00, 37200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261008091631000 | Casino Empresarial Buen Sabor | Entregada | total 228000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008091631000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20261003-065000') AS id_lote, 18.00 AS cantidad, 3450.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 62100.00 AS subtotal, 62100.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 18.00, 8150.00, 0.00, 0.00, 0.00, 0.00, 146700.00, 146700.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 12.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 19200.00, 19200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261008130039000 | Tienda San Jose | Entregada | total 18600.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008130039000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000') AS id_lote, 3.00 AS cantidad, 6200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 18600.00 AS subtotal, 18600.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261009092500000 | Comidas Rapidas El Gordo | Entregada | total 16250.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009092500000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500') AS id_lote, 2.50 AS cantidad, 6500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 16250.00 AS subtotal, 16250.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261009122601000 | Cafeteria y Panaderia La Espiga | Entregada | total 359570.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009122601000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 49.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 220500.00 AS subtotal, 220500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-41-40-20260928-050000'), 6.00, 8350.00, 0.30, 15030.00, 0.00, 0.00, 50100.00, 35070.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000'), 40.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 104000.00, 104000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261009134113000 | Tienda El Trebol | Entregada | total 10350.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009134113000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20261003-065000') AS id_lote, 3.00 AS cantidad, 3450.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 10350.00 AS subtotal, 10350.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261009150958000 | Laura Sofia Beltran Pinzon | Entregada | total 74400.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009150958000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000') AS id_lote, 12.00 AS cantidad, 6200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 74400.00 AS subtotal, 74400.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261010082538000 | Comidas Rapidas El Gordo | Entregada | total 34500.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010082538000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 5.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 24750.00 AS subtotal, 24750.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 1.50, 6500.00, 0.00, 0.00, 0.00, 0.00, 9750.00, 9750.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261010110304000 | Cafe Bar El Rincon | Entregada | total 23280.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010110304000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000') AS id_lote, 2.00 AS cantidad, 4200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 8400.00 AS subtotal, 8400.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-46-50-20260929-063000'), 4.00, 6200.00, 0.40, 9920.00, 0.00, 0.00, 24800.00, 14880.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261010125643000 | Asadero El Llanerito | Entregada | total 845200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010125643000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000') AS id_lote, 40.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 104000.00 AS subtotal, 104000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-45-43-20260902-070000'), 60.00, 8900.00, 0.00, 0.00, 0.00, 0.00, 534000.00, 534000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 8.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 33600.00, 33600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 28.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 173600.00, 173600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261010164748000 | Tienda Naturista Vida Sana | Entregada | total 81000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010164748000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 18.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 81000.00 AS subtotal, 81000.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261013101837000 | Restaurante Sabor del Pacifico | Entregada | total 69200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013101837000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000') AS id_lote, 10.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 26000.00 AS subtotal, 26000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 27.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 43200.00, 43200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261013125226000 | Restaurante Fogon Paisa | Entregada | total 318250.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013125226000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000') AS id_lote, 25.00 AS cantidad, 8150.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 203750.00 AS subtotal, 203750.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 10.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 49500.00, 49500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 10.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 65000.00, 65000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261013163958000 | Laura Sofia Beltran Pinzon | Entregada | total 95225.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013163958000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000') AS id_lote, 5.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 13000.00 AS subtotal, 13000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 1.50, 8150.00, 0.00, 0.00, 0.00, 0.00, 12225.00, 12225.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-24-19-20260930-050000'), 5.00, 14000.00, 0.00, 0.00, 0.00, 0.00, 70000.00, 70000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261014112401000 | Fruver La Cosecha de Usaquen | Entregada | total 303500.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261014112401000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260929-051500') AS id_lote, 35.00 AS cantidad, 3500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 122500.00 AS subtotal, 122500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20261003-065000'), 20.00, 3450.00, 0.00, 0.00, 0.00, 0.00, 69000.00, 69000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-24-19-20260930-050000'), 5.00, 14000.00, 0.00, 0.00, 0.00, 0.00, 70000.00, 70000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 10.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 42000.00, 42000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261014150111000 | Cafeteria y Panaderia La Espiga | Entregada | total 312150.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261014150111000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000') AS id_lote, 33.00 AS cantidad, 6200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 204600.00 AS subtotal, 204600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 10.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 42000.00, 42000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-11-11-20261003-065000'), 19.00, 3450.00, 0.00, 0.00, 0.00, 0.00, 65550.00, 65550.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261016112536000 | Tienda La Bendicion | Entregada | total 20200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261016112536000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000') AS id_lote, 3.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 7800.00 AS subtotal, 7800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-39-39-20261016-052000'), 2.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 12400.00, 12400.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261016132250000 | Restaurante La Cazuela Sabanera S.A.S. | Entregada | total 249800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261016132250000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000') AS id_lote, 15.00 AS cantidad, 2600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 39000.00 AS subtotal, 39000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 24.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 148800.00, 148800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-39-39-20261016-052000'), 10.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 62000.00, 62000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261017092510000 | Asadero El Llanerito | Entregada | total 384900.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261017092510000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20261014-061000') AS id_lote, 35.00 AS cantidad, 2400.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 84000.00 AS subtotal, 84000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 14.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 22400.00, 22400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 30.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 148500.00, 148500.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 25.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 130000.00, 130000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261017132202000 | Cafeteria y Panaderia La Espiga | Entregada | total 390300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261017132202000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500') AS id_lote, 18.00 AS cantidad, 6500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 117000.00 AS subtotal, 117000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-15-15-20261014-061000'), 12.00, 2400.00, 0.00, 0.00, 0.00, 0.00, 28800.00, 28800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 30.00, 8150.00, 0.00, 0.00, 0.00, 0.00, 244500.00, 244500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261019112437000 | Jorge Ivan Castano Lopez | En Transito | total 116700.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261019112437000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 15.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 67500.00 AS subtotal, 67500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20261018-063000'), 8.00, 6150.00, 0.00, 0.00, 0.00, 0.00, 49200.00, 49200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261020082334000 | Panaderia Pan Caliente | En Transito | total 80800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261020082334000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500') AS id_lote, 6.00 AS cantidad, 5200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 31200.00 AS subtotal, 31200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 8.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 49600.00, 49600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261021164505000 | Catering Eventos Gourmet S.A.S. | En Transito | total 337800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261021164505000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000') AS id_lote, 18.00 AS cantidad, 8150.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 146700.00 AS subtotal, 146700.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500'), 18.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 93600.00, 93600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-17-10-20261020-053000'), 15.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 97500.00, 97500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261022105400000 | Andres Felipe Cardenas Mora | En Transito | total 3675.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261022105400000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260929-051500') AS id_lote, 1.50 AS cantidad, 3500.00 AS precio, 0.30 AS descuento, 1575.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 5250.00 AS subtotal, 3675.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261022111512000 | Andres Felipe Cardenas Mora | En Transito | total 50225.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261022111512000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 1.50 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 7425.00 AS subtotal, 7425.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 6.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 25200.00, 25200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 11.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 17600.00, 17600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261023105852000 | Catering Eventos Gourmet S.A.S. | En Transito | total 554300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261023105852000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 18.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 89100.00 AS subtotal, 89100.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-39-39-20261016-052000'), 23.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 142600.00, 142600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000'), 40.00, 4500.00, 0.00, 0.00, 0.00, 0.00, 180000.00, 180000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-7-9-20261018-063000'), 16.00, 6150.00, 0.00, 0.00, 0.00, 0.00, 98400.00, 98400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-13-13-20261002-050000'), 17.00, 2600.00, 0.00, 0.00, 0.00, 0.00, 44200.00, 44200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261024124600000 | Santiago Herrera Duque | En Preparacion | total 47200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261024124600000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-6-6-20261022-071000') AS id_lote, 4.00 AS cantidad, 9350.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 37400.00 AS subtotal, 37400.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-8-1-20260929-051500'), 4.00, 3500.00, 0.30, 4200.00, 0.00, 0.00, 14000.00, 9800.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261026121127000 | Camila Andrea Rojas Quintero | En Preparacion | total 72100.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261026121127000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000') AS id_lote, 10.00 AS cantidad, 1600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 16000.00 AS subtotal, 16000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-6-6-20261022-071000'), 6.00, 9350.00, 0.00, 0.00, 0.00, 0.00, 56100.00, 56100.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261027083325000 | Comedor Comunitario San Mateo | En Preparacion | total 464200.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027083325000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-4-4-20261026-051500') AS id_lote, 21.00 AS cantidad, 8200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 172200.00 AS subtotal, 172200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-21-23-20261023-061500'), 12.00, 19400.00, 0.00, 0.00, 0.00, 0.00, 232800.00, 232800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 37.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 59200.00, 59200.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261027111232000 | Fruver Las Margaritas | En Preparacion | total 111900.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027111232000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 11.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 49500.00 AS subtotal, 49500.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-37-37-20261026-054500'), 8.00, 7800.00, 0.00, 0.00, 0.00, 0.00, 62400.00, 62400.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261027112414000 | Fruteria Tropical Funza | En Preparacion | total 428800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027112414000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000') AS id_lote, 56.00 AS cantidad, 6200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 347200.00 AS subtotal, 347200.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 51.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 81600.00, 81600.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261027134135000 | Luis Eduardo Pardo Salinas | En Preparacion | total 14850.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027134135000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500') AS id_lote, 3.00 AS cantidad, 4950.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 14850.00 AS subtotal, 14850.00 AS total_linea
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261027152159000 | Tienda Dona Cecilia | En Preparacion | total 27800.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027152159000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-6-6-20261022-071000') AS id_lote, 2.00 AS cantidad, 9350.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 18700.00 AS subtotal, 18700.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-2-4-20261022-051000'), 2.50, 5200.00, 0.30, 3900.00, 0.00, 0.00, 13000.00, 9100.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261028131728000 | Tienda El Paisa | En Preparacion | total 44460.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261028131728000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-2-4-20261022-051000') AS id_lote, 1.50 AS cantidad, 5200.00 AS precio, 0.30 AS descuento, 2340.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 7800.00 AS subtotal, 5460.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-27-29-20261027-051500'), 3.00, 13000.00, 0.00, 0.00, 0.00, 0.00, 39000.00, 39000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261028132120000 | Comedor Comunitario San Mateo | En Preparacion | total 447300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261028132120000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000') AS id_lote, 16.00 AS cantidad, 1600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 25600.00 AS subtotal, 25600.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-50-49-20261028-054500'), 43.00, 5900.00, 0.00, 0.00, 0.00, 0.00, 253700.00, 253700.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-25-25-20261028-053000'), 10.00, 16800.00, 0.00, 0.00, 0.00, 0.00, 168000.00, 168000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261028142718000 | Fruteria Tropical Funza | En Preparacion | total 748000.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261028142718000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 38.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 171000.00 AS subtotal, 171000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-35-35-20260904-055000'), 20.00, 8150.00, 0.00, 0.00, 0.00, 0.00, 163000.00, 163000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-42-44-20260828-072000'), 15.00, 6200.00, 0.00, 0.00, 0.00, 0.00, 93000.00, 93000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-10-12-20261025-061000'), 35.00, 3600.00, 0.00, 0.00, 0.00, 0.00, 126000.00, 126000.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 30.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 195000.00, 195000.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261029132920000 | Restaurante Fogon Paisa | Registrada | total 644070.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261029132920000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-10-12-20261025-061000') AS id_lote, 18.00 AS cantidad, 3600.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 64800.00 AS subtotal, 64800.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-2-4-20261022-051000'), 28.00, 5200.00, 0.30, 43680.00, 0.00, 0.00, 145600.00, 101920.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-2-4-20261029-052000'), 12.00, 5200.00, 0.00, 0.00, 0.00, 0.00, 62400.00, 62400.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-50-49-20261028-054500'), 7.00, 5900.00, 0.00, 0.00, 0.00, 0.00, 41300.00, 41300.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-50-50-20261029-050000'), 39.00, 6050.00, 0.00, 0.00, 0.00, 0.00, 235950.00, 235950.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-29-31-20261028-060000'), 4.00, 22050.00, 0.00, 0.00, 0.00, 0.00, 88200.00, 88200.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-36-36-20260902-054500'), 10.00, 4950.00, 0.00, 0.00, 0.00, 0.00, 49500.00, 49500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261030100607000 | Catering Eventos Gourmet S.A.S. | Registrada | total 566350.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261030100607000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-44-44-20260908-064500') AS id_lote, 55.00 AS cantidad, 5200.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 286000.00 AS subtotal, 286000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 21.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 33600.00, 33600.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-20-22-20261030-051500'), 21.00, 9350.00, 0.00, 0.00, 0.00, 0.00, 196350.00, 196350.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-32-34-20260826-054000'), 12.00, 4200.00, 0.00, 0.00, 0.00, 0.00, 50400.00, 50400.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261030101853000 | Tienda La Bendicion | Registrada | total 58500.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261030101853000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-43-43-20260827-075000') AS id_lote, 6.00 AS cantidad, 4500.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 27000.00 AS subtotal, 27000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-40-37-20261029-054500'), 3.00, 5950.00, 0.00, 0.00, 0.00, 0.00, 17850.00, 17850.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-27-29-20261027-051500'), 1.50, 13000.00, 0.30, 5850.00, 0.00, 0.00, 19500.00, 13650.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- V-20261031125424000 | Asadero El Llanerito | Registrada | total 615300.00
SET @id_venta = (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261031125424000');
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT * FROM (
    SELECT @id_venta AS id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-33-35-20260907-054000') AS id_lote, 35.00 AS cantidad, 9800.00 AS precio, 0.00 AS descuento, 0.00 AS monto_descuento, 0.00 AS tasa_impuesto, 0.00 AS monto_impuesto, 343000.00 AS subtotal, 343000.00 AS total_linea
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-38-38-20260829-070000'), 28.00, 1600.00, 0.00, 0.00, 0.00, 0.00, 44800.00, 44800.00
    UNION ALL SELECT @id_venta, (SELECT id_lote FROM lotes_inventario WHERE numero_lote = 'LOT-34-36-20260831-064500'), 35.00, 6500.00, 0.00, 0.00, 0.00, 0.00, 227500.00, 227500.00
) AS lineas
WHERE NOT EXISTS (SELECT 1 FROM detalles_venta WHERE id_venta = @id_venta);

-- 2.11 Facturas (107): una por cada venta no cancelada.
-- DOCUMENTOS SIMULADOS, sin validez fiscal. El CUFE es un hash SHA-384 de los datos de la
-- factura y enlace_qr usa el mismo formato que ControladorFacturacion: SIMULADO|numero|cufe.
-- Se usa el prefijo FE- para no chocar con los numeros FAC-DEMO-<id venta> que genera la app.
-- Los totales de la factura son los mismos de la venta.
INSERT INTO facturas (id_venta, numero_factura, cufe, enlace_qr, fecha_emision, subtotal, total_descuento, monto_impuesto, monto_total) VALUES
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902114427000'), 'FE-000001', 'fcaead3fbd4b30bc7deac98534926bbef330ff43ed68af25cd9a815a3832161e835f4cd60982ca06dea37e2d26927273', 'SIMULADO|FE-000001|fcaead3fbd4b30bc7deac98534926bbef330ff43ed68af25cd9a815a3832161e835f4cd60982ca06dea37e2d26927273', '2026-09-02 11:47:27', 245000.00, 0.00, 0.00, 245000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902155354000'), 'FE-000002', '71df6d150e3a478b3f49b65f6c4416af36273d881a379d496993a03e05bde486030ccb775ce2bcd5f6ba1b547e645fa3', 'SIMULADO|FE-000002|71df6d150e3a478b3f49b65f6c4416af36273d881a379d496993a03e05bde486030ccb775ce2bcd5f6ba1b547e645fa3', '2026-09-02 15:57:54', 420900.00, 30900.00, 0.00, 390000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902155404000'), 'FE-000003', '282d203fa22bbee6879d7fd6193398db4c5155f72c905a75d402a469a3fe0fd2bf63e761b90647a5ec83d1e886cbe986', 'SIMULADO|FE-000003|282d203fa22bbee6879d7fd6193398db4c5155f72c905a75d402a469a3fe0fd2bf63e761b90647a5ec83d1e886cbe986', '2026-09-02 15:56:04', 69850.00, 0.00, 0.00, 69850.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260903122427000'), 'FE-000004', 'e9bf4461f11df55d377a7d703f3a9ae3b0c1071d9c309cbe49c8c0d92dde670e2ffce8c1ebf44494f333b3feda0f2b0f', 'SIMULADO|FE-000004|e9bf4461f11df55d377a7d703f3a9ae3b0c1071d9c309cbe49c8c0d92dde670e2ffce8c1ebf44494f333b3feda0f2b0f', '2026-09-03 12:27:27', 340600.00, 72640.00, 0.00, 267960.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260903140018000'), 'FE-000005', '7cce3ea6cb637c2b3f259eed4ebce21e8eb2cd703abc5f81af43c07ff259cb461eab6d8a5b24701213be3e1745d20175', 'SIMULADO|FE-000005|7cce3ea6cb637c2b3f259eed4ebce21e8eb2cd703abc5f81af43c07ff259cb461eab6d8a5b24701213be3e1745d20175', '2026-09-03 14:03:18', 768250.00, 0.00, 0.00, 768250.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904123420000'), 'FE-000006', 'f6c36d0b154f983efdb7a4fab83d51cce84fe2fe15f6f46826c3de635868b4942f29f74bd819021ac1dcadce88112268', 'SIMULADO|FE-000006|f6c36d0b154f983efdb7a4fab83d51cce84fe2fe15f6f46826c3de635868b4942f29f74bd819021ac1dcadce88112268', '2026-09-04 12:38:20', 45600.00, 0.00, 0.00, 45600.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904143325000'), 'FE-000007', '08042fa1174858f68c086949ff90dcdd15f43893c6165a6447c393a1f4fa8c79938e04ed2f0912ecb9aa4257397e04b3', 'SIMULADO|FE-000007|08042fa1174858f68c086949ff90dcdd15f43893c6165a6447c393a1f4fa8c79938e04ed2f0912ecb9aa4257397e04b3', '2026-09-04 14:36:25', 653500.00, 35100.00, 0.00, 618400.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904165625000'), 'FE-000008', 'ae5ca196e4322eb8cc3bc324778a0b1e1aceab245d6b96c69cd1ca6775e09aa3681ceec2a9449985abd763792b1e9531', 'SIMULADO|FE-000008|ae5ca196e4322eb8cc3bc324778a0b1e1aceab245d6b96c69cd1ca6775e09aa3681ceec2a9449985abd763792b1e9531', '2026-09-04 16:58:25', 52050.00, 0.00, 0.00, 52050.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905082432000'), 'FE-000009', '53d3e565e4805025849603a154c0e008a4fa9da5ea922eb58310f1ad104a298bb29cdbb80d7426a28c93c07f13424df1', 'SIMULADO|FE-000009|53d3e565e4805025849603a154c0e008a4fa9da5ea922eb58310f1ad104a298bb29cdbb80d7426a28c93c07f13424df1', '2026-09-05 08:27:32', 16300.00, 0.00, 0.00, 16300.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905085105000'), 'FE-000010', '67961c8afbe5b1f5a0c5a018e24af724000ba670e02405f3faa4d11f19f108ec9aafdc59cdccf02406a8dde9301c1929', 'SIMULADO|FE-000010|67961c8afbe5b1f5a0c5a018e24af724000ba670e02405f3faa4d11f19f108ec9aafdc59cdccf02406a8dde9301c1929', '2026-09-05 08:57:05', 38400.00, 4500.00, 0.00, 33900.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905100418000'), 'FE-000011', 'f27f59baf190ea772c28d3424c346471402d4e7202ca138dd35f5f3eae5bd2de6f2de20d39fb65558a18ffcdc286a45a', 'SIMULADO|FE-000011|f27f59baf190ea772c28d3424c346471402d4e7202ca138dd35f5f3eae5bd2de6f2de20d39fb65558a18ffcdc286a45a', '2026-09-05 10:08:18', 11700.00, 0.00, 0.00, 11700.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905113710000'), 'FE-000012', 'd8813142cf3be85d41c15e5062f31790d7b05601984cb18b786e0bec14632a7964e7de5d66f73fbd94728c46f3195c16', 'SIMULADO|FE-000012|d8813142cf3be85d41c15e5062f31790d7b05601984cb18b786e0bec14632a7964e7de5d66f73fbd94728c46f3195c16', '2026-09-05 11:40:10', 153150.00, 0.00, 0.00, 153150.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905122437000'), 'FE-000013', 'c1734366a6c3a22064f9a794e2d97c97fdc64bf5cdadd532d6a790951e736fd17cb8a27b5a1c59e2618ba81c5044d154', 'SIMULADO|FE-000013|c1734366a6c3a22064f9a794e2d97c97fdc64bf5cdadd532d6a790951e736fd17cb8a27b5a1c59e2618ba81c5044d154', '2026-09-05 12:25:37', 33760.00, 0.00, 0.00, 33760.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260907142837000'), 'FE-000014', 'c734a514e19c8f8494485eb9913f11f68570bd31e4f2cc9fcafe5c361eb030d398de4dd5efb02fbe595545f2ee7f95c4', 'SIMULADO|FE-000014|c734a514e19c8f8494485eb9913f11f68570bd31e4f2cc9fcafe5c361eb030d398de4dd5efb02fbe595545f2ee7f95c4', '2026-09-07 14:31:37', 415750.00, 0.00, 0.00, 415750.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260908095617000'), 'FE-000015', '575e7aee2388ab208e4202ff0d57e10b313f9db20c7ae3ce8514d67751cc0c5dd99179d2b5c365ff5ce9f90ff75a2a99', 'SIMULADO|FE-000015|575e7aee2388ab208e4202ff0d57e10b313f9db20c7ae3ce8514d67751cc0c5dd99179d2b5c365ff5ce9f90ff75a2a99', '2026-09-08 09:57:17', 57600.00, 0.00, 0.00, 57600.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909083008000'), 'FE-000016', '9bc7dc0c1792f253755433e0fbae39ef62d3f2892ba738318a4c2c3ae008b61c151677423ae59d1bd6fe52e5fa17485b', 'SIMULADO|FE-000016|9bc7dc0c1792f253755433e0fbae39ef62d3f2892ba738318a4c2c3ae008b61c151677423ae59d1bd6fe52e5fa17485b', '2026-09-09 08:35:08', 426100.00, 39000.00, 0.00, 387100.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909105928000'), 'FE-000017', '33cd7cbbe53405fd7e46ecaf5fe17965fe28e42983b2fac85c71de27b74be79066e8a7804d79a14198f54009c4c405b1', 'SIMULADO|FE-000017|33cd7cbbe53405fd7e46ecaf5fe17965fe28e42983b2fac85c71de27b74be79066e8a7804d79a14198f54009c4c405b1', '2026-09-09 11:03:28', 19550.00, 0.00, 0.00, 19550.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909122044000'), 'FE-000018', '52fa372c6fb2e0c2b07af24e2822849c49b5c8b5796f18d8b00a785283b2c8ccc22e4ee6a316e8b63213bdb6631ebbd5', 'SIMULADO|FE-000018|52fa372c6fb2e0c2b07af24e2822849c49b5c8b5796f18d8b00a785283b2c8ccc22e4ee6a316e8b63213bdb6631ebbd5', '2026-09-09 12:21:44', 46825.00, 0.00, 0.00, 46825.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909131414000'), 'FE-000019', '736dcd9280019daf4565c874b980dd7e92d057556d4f837f0d9e4f931d272fc496780e205ab61b7ae8588b141520926c', 'SIMULADO|FE-000019|736dcd9280019daf4565c874b980dd7e92d057556d4f837f0d9e4f931d272fc496780e205ab61b7ae8588b141520926c', '2026-09-09 13:19:14', 6600.00, 0.00, 0.00, 6600.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909164616000'), 'FE-000020', '04b8881f1f961e8fa408b615b952515bb29bc0d86cd8a949f404cab3f634a3177dd7c465ab78e1e6a436fbff73d806c5', 'SIMULADO|FE-000020|04b8881f1f961e8fa408b615b952515bb29bc0d86cd8a949f404cab3f634a3177dd7c465ab78e1e6a436fbff73d806c5', '2026-09-09 16:52:16', 29400.00, 0.00, 0.00, 29400.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260911110911000'), 'FE-000021', 'e02fc7bb2a54b4ed205672d5aa491ed649b59f06f5034adc92208d309afb18d8f57161ff374732bc2f1bf900c2a08290', 'SIMULADO|FE-000021|e02fc7bb2a54b4ed205672d5aa491ed649b59f06f5034adc92208d309afb18d8f57161ff374732bc2f1bf900c2a08290', '2026-09-11 11:12:11', 548900.00, 0.00, 0.00, 548900.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260911134623000'), 'FE-000022', '8ece38c8b5092ddf271a1e310e127dbd43d260c318cdcd6f4d467fbaaf82070c37fb99101cda8e3514794242ab718b8b', 'SIMULADO|FE-000022|8ece38c8b5092ddf271a1e310e127dbd43d260c318cdcd6f4d467fbaaf82070c37fb99101cda8e3514794242ab718b8b', '2026-09-11 13:52:23', 87200.00, 6480.00, 0.00, 80720.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260912121643000'), 'FE-000023', '3a56abea18a85180b89b46d9e65a6cea960b1067af5c67b10f8447c716159ee17cf99fb559cfcd7a8265746857a4dabb', 'SIMULADO|FE-000023|3a56abea18a85180b89b46d9e65a6cea960b1067af5c67b10f8447c716159ee17cf99fb559cfcd7a8265746857a4dabb', '2026-09-12 12:18:43', 25500.00, 10200.00, 0.00, 15300.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260912141537000'), 'FE-000024', '43b960b86bc0badbfe32ff1eced1562bcab6b3cb8c55d6850642e02372282759d3f1ce098cf9930619312852c8175fdb', 'SIMULADO|FE-000024|43b960b86bc0badbfe32ff1eced1562bcab6b3cb8c55d6850642e02372282759d3f1ce098cf9930619312852c8175fdb', '2026-09-12 14:19:37', 28600.00, 8580.00, 0.00, 20020.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914105916000'), 'FE-000025', '38c3f542525344b984a11fe5e24393ac6f4ec0c0c3c6658500f33a12be4ad3506de5a480744b68d98447394b48793094', 'SIMULADO|FE-000025|38c3f542525344b984a11fe5e24393ac6f4ec0c0c3c6658500f33a12be4ad3506de5a480744b68d98447394b48793094', '2026-09-14 11:00:16', 553800.00, 38925.00, 0.00, 514875.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914124855000'), 'FE-000026', 'd01d279783949438fc32eca64f1e80124f512a9a78ff7c2da5ccdcba205176f054fc53036660e9fc722223004ce40665', 'SIMULADO|FE-000026|d01d279783949438fc32eca64f1e80124f512a9a78ff7c2da5ccdcba205176f054fc53036660e9fc722223004ce40665', '2026-09-14 12:53:55', 160500.00, 48450.00, 0.00, 112050.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914151600000'), 'FE-000027', '436ff7b19f51f3d3bdad6c8a013d9a57e411051f65e0ee7fd1d844b55db632b614d1d575476e756de978155f11e34e50', 'SIMULADO|FE-000027|436ff7b19f51f3d3bdad6c8a013d9a57e411051f65e0ee7fd1d844b55db632b614d1d575476e756de978155f11e34e50', '2026-09-14 15:18:00', 107100.00, 35840.00, 0.00, 71260.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914164433000'), 'FE-000028', '84f80e3f77cbb994b98dd496c8ffcecf1b2be3e88304bbac2137a1d22d55e6f22000f9af9059366556cd682f0dfe67a6', 'SIMULADO|FE-000028|84f80e3f77cbb994b98dd496c8ffcecf1b2be3e88304bbac2137a1d22d55e6f22000f9af9059366556cd682f0dfe67a6', '2026-09-14 16:46:33', 583400.00, 103800.00, 0.00, 479600.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260915151810000'), 'FE-000029', '98ef9ca08133cad7befd32b348f2b965f3094ad1521e8a8dcbb1526828fc8a563a5cbb2d8332ea8c342a047c917dce9e', 'SIMULADO|FE-000029|98ef9ca08133cad7befd32b348f2b965f3094ad1521e8a8dcbb1526828fc8a563a5cbb2d8332ea8c342a047c917dce9e', '2026-09-15 15:24:10', 42000.00, 12600.00, 0.00, 29400.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916094235000'), 'FE-000030', '2c5f2687d404ef8fb51ea78e240b6c66672f8b353e26175c8d8621508287336326efacd3da15ddb45584817ca8f3144a', 'SIMULADO|FE-000030|2c5f2687d404ef8fb51ea78e240b6c66672f8b353e26175c8d8621508287336326efacd3da15ddb45584817ca8f3144a', '2026-09-16 09:48:35', 25200.00, 0.00, 0.00, 25200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916102049000'), 'FE-000031', '064c30447fafa46977f99f658c204b1703ab3bfbfa7cef8ffba9d0e27118d9478c54f4a77155e58ababfce749338d9f3', 'SIMULADO|FE-000031|064c30447fafa46977f99f658c204b1703ab3bfbfa7cef8ffba9d0e27118d9478c54f4a77155e58ababfce749338d9f3', '2026-09-16 10:24:49', 3300.00, 990.00, 0.00, 2310.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916144447000'), 'FE-000032', '05f4376fdd878c4ef6d5068962d8e83caa0ee119742b07f43e039f552fa7c562219906cb89fe4adc3f1a040b1466de57', 'SIMULADO|FE-000032|05f4376fdd878c4ef6d5068962d8e83caa0ee119742b07f43e039f552fa7c562219906cb89fe4adc3f1a040b1466de57', '2026-09-16 14:49:47', 471900.00, 72000.00, 0.00, 399900.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260917095234000'), 'FE-000033', '18abc9583514748951af48602c74e17dc4eaa4a01e8d2fa2f241c5ed694684c7b8d568ba82f5d97e7c987029bc09f1ec', 'SIMULADO|FE-000033|18abc9583514748951af48602c74e17dc4eaa4a01e8d2fa2f241c5ed694684c7b8d568ba82f5d97e7c987029bc09f1ec', '2026-09-17 09:57:34', 142100.00, 2880.00, 0.00, 139220.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260917160714000'), 'FE-000034', '7e5588f3985117736cbed5430919ca5e7856379343fd84a7e144ff4d73a70d9ef3c3246fc9958e25241d9b1564b648e3', 'SIMULADO|FE-000034|7e5588f3985117736cbed5430919ca5e7856379343fd84a7e144ff4d73a70d9ef3c3246fc9958e25241d9b1564b648e3', '2026-09-17 16:09:14', 92200.00, 3720.00, 0.00, 88480.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918133913000'), 'FE-000035', '8d5dd7bf4e6b4805744e7c44e881549e6fb155deb166e1f5aafac27c44fa6db883d932b1445b00bfef51680e8012e986', 'SIMULADO|FE-000035|8d5dd7bf4e6b4805744e7c44e881549e6fb155deb166e1f5aafac27c44fa6db883d932b1445b00bfef51680e8012e986', '2026-09-18 13:44:13', 207100.00, 0.00, 0.00, 207100.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918143232000'), 'FE-000036', 'ff3ab16e9ae6d56b1b86735866bd633fcd0baefed9e32807696f9cd2d27a60d97143e9cb905072fb7f86136e20f53152', 'SIMULADO|FE-000036|ff3ab16e9ae6d56b1b86735866bd633fcd0baefed9e32807696f9cd2d27a60d97143e9cb905072fb7f86136e20f53152', '2026-09-18 14:36:32', 631800.00, 92400.00, 0.00, 539400.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919101335000'), 'FE-000037', '7690bc2fb56968cce94ff93754f659e58e4bcc25b4aa1c91ee740f94b80c369a69baf85d68961bbff5d5c363a910caad', 'SIMULADO|FE-000037|7690bc2fb56968cce94ff93754f659e58e4bcc25b4aa1c91ee740f94b80c369a69baf85d68961bbff5d5c363a910caad', '2026-09-19 10:19:35', 13350.00, 4005.00, 0.00, 9345.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919102443000'), 'FE-000038', 'dc2e83b367f31cf30da3c8382df3f83ed3d878e9dd43e6e6be369997685463d37a62c9499c4a96b4eaea804f51479c59', 'SIMULADO|FE-000038|dc2e83b367f31cf30da3c8382df3f83ed3d878e9dd43e6e6be369997685463d37a62c9499c4a96b4eaea804f51479c59', '2026-09-19 10:28:43', 379050.00, 13350.00, 0.00, 365700.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919132958000'), 'FE-000039', '9bb2964ff4e4c84f31e2de8c5ef144d73e9291d4590a3ca1c9846fd7ffaa39887c33c167c73fea4307471d3353ba7e0a', 'SIMULADO|FE-000039|9bb2964ff4e4c84f31e2de8c5ef144d73e9291d4590a3ca1c9846fd7ffaa39887c33c167c73fea4307471d3353ba7e0a', '2026-09-19 13:32:58', 593600.00, 27240.00, 0.00, 566360.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260921091208000'), 'FE-000040', 'e305fa1670a282a3cba235a646a138460ffe505da187a5505ccad9c99eea83e16379de27509a189c3438ee451eb257c8', 'SIMULADO|FE-000040|e305fa1670a282a3cba235a646a138460ffe505da187a5505ccad9c99eea83e16379de27509a189c3438ee451eb257c8', '2026-09-21 09:14:08', 88300.00, 0.00, 0.00, 88300.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260921102039000'), 'FE-000041', 'dc4838faac6e9ce01f4210e088a998db673e4a9ce9195f48ea8dda886eed6dc0a0ce51b37d89d7ee4217058d51c03cc9', 'SIMULADO|FE-000041|dc4838faac6e9ce01f4210e088a998db673e4a9ce9195f48ea8dda886eed6dc0a0ce51b37d89d7ee4217058d51c03cc9', '2026-09-21 10:26:39', 35900.00, 7800.00, 0.00, 28100.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922095644000'), 'FE-000042', 'b949bedb20ecbc323f336f328b7a44bff39575344ca4997a584e10ec9b889bd79092e5b00f913d931115c782f7fdc671', 'SIMULADO|FE-000042|b949bedb20ecbc323f336f328b7a44bff39575344ca4997a584e10ec9b889bd79092e5b00f913d931115c782f7fdc671', '2026-09-22 09:57:44', 39200.00, 0.00, 0.00, 39200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922105343000'), 'FE-000043', '69986008470b7f5d83eaa18f6addfdc6b244a6faa5784dcc7b289fa25fd45b1bcca4c8e3c1345d25815869518580f439', 'SIMULADO|FE-000043|69986008470b7f5d83eaa18f6addfdc6b244a6faa5784dcc7b289fa25fd45b1bcca4c8e3c1345d25815869518580f439', '2026-09-22 10:57:43', 258300.00, 6600.00, 0.00, 251700.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922122639000'), 'FE-000044', '5593ede246c09764bc98f5037c6e678f0f27c1d2acd38e432958a6ee079fff9a0c30efdcf8806de5795acd476e84415d', 'SIMULADO|FE-000044|5593ede246c09764bc98f5037c6e678f0f27c1d2acd38e432958a6ee079fff9a0c30efdcf8806de5795acd476e84415d', '2026-09-22 12:30:39', 14400.00, 0.00, 0.00, 14400.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922130636000'), 'FE-000045', '6f77495677a6263fa9b3e4572196083cfa3b728e16df1710459fac6922fc786609ab70c4a00007b272abe62418e2b514', 'SIMULADO|FE-000045|6f77495677a6263fa9b3e4572196083cfa3b728e16df1710459fac6922fc786609ab70c4a00007b272abe62418e2b514', '2026-09-22 13:09:36', 139450.00, 0.00, 0.00, 139450.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260923081418000'), 'FE-000046', '30ab959596fc7af28bdf0d448a86ef776c5f8c7cbfac64d45ce1f7f6020e0c86fd9ea301bc0a9f1c20f421ab7d44fdf8', 'SIMULADO|FE-000046|30ab959596fc7af28bdf0d448a86ef776c5f8c7cbfac64d45ce1f7f6020e0c86fd9ea301bc0a9f1c20f421ab7d44fdf8', '2026-09-23 08:15:18', 377500.00, 0.00, 0.00, 377500.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260923151536000'), 'FE-000047', 'e3a71e52e925dcbaf848aff2a6e5fcd6dc16276b1c8ca28a62e6459d395e85320fdfe79ed2374f8b9b0830c714b2dda8', 'SIMULADO|FE-000047|e3a71e52e925dcbaf848aff2a6e5fcd6dc16276b1c8ca28a62e6459d395e85320fdfe79ed2374f8b9b0830c714b2dda8', '2026-09-23 15:17:36', 1001950.00, 0.00, 0.00, 1001950.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260924140203000'), 'FE-000048', '62be1f8f055d8f77118d38ae86c3610ff6e0ca66a40a8ce031ac887a28ffd66b6e902d81d0fc0dad43d530eb2015d1ed', 'SIMULADO|FE-000048|62be1f8f055d8f77118d38ae86c3610ff6e0ca66a40a8ce031ac887a28ffd66b6e902d81d0fc0dad43d530eb2015d1ed', '2026-09-24 14:03:03', 53650.00, 0.00, 0.00, 53650.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926085210000'), 'FE-000049', '384cf6456cd036081eadc8fac8106f3ea531dea9812d58df2eaa5c2756b6b8c220961603405a7a46791070165ba1342b', 'SIMULADO|FE-000049|384cf6456cd036081eadc8fac8106f3ea531dea9812d58df2eaa5c2756b6b8c220961603405a7a46791070165ba1342b', '2026-09-26 08:53:10', 502600.00, 32400.00, 0.00, 470200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926110012000'), 'FE-000050', '216d1c558f4919c7652ccd181189eca12a6258b2aa2bf217bfeba74128703657fcdfaead3c29beae7d05a4b1234daa74', 'SIMULADO|FE-000050|216d1c558f4919c7652ccd181189eca12a6258b2aa2bf217bfeba74128703657fcdfaead3c29beae7d05a4b1234daa74', '2026-09-26 11:03:12', 502650.00, 0.00, 0.00, 502650.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926133856000'), 'FE-000051', '9f20ce95a54f5426385cf2acd679f48dbe3db9d0d8d0bce4d27a5180e09b89b9d95f24e8a6bb85930d721282df50985c', 'SIMULADO|FE-000051|9f20ce95a54f5426385cf2acd679f48dbe3db9d0d8d0bce4d27a5180e09b89b9d95f24e8a6bb85930d721282df50985c', '2026-09-26 13:39:56', 120000.00, 0.00, 0.00, 120000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926154016000'), 'FE-000052', '470cac5120c06ff09fde2c6d2308b3318f9d24e6d2d0c876eb1c3f7c8896f5fd81088b42a73726a88014631d65bdcb93', 'SIMULADO|FE-000052|470cac5120c06ff09fde2c6d2308b3318f9d24e6d2d0c876eb1c3f7c8896f5fd81088b42a73726a88014631d65bdcb93', '2026-09-26 15:44:16', 252300.00, 40200.00, 0.00, 212100.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926155802000'), 'FE-000053', 'c6d13ba56f188fc36639b3683a479c1580f8ddce9887e777bfbac6c5fba9b98dc246a6ccbc0f07fc50803707b5bca7a8', 'SIMULADO|FE-000053|c6d13ba56f188fc36639b3683a479c1580f8ddce9887e777bfbac6c5fba9b98dc246a6ccbc0f07fc50803707b5bca7a8', '2026-09-26 16:02:02', 44425.00, 0.00, 0.00, 44425.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926164131000'), 'FE-000054', 'cb16c6b65de3b3c298a338d167faca3eb8dde7543bc3bb3d84b7acf42ba0a19259aa088e30061eb9d6226db6b98c7db0', 'SIMULADO|FE-000054|cb16c6b65de3b3c298a338d167faca3eb8dde7543bc3bb3d84b7acf42ba0a19259aa088e30061eb9d6226db6b98c7db0', '2026-09-26 16:45:31', 218300.00, 14070.00, 0.00, 204230.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260928115841000'), 'FE-000055', 'a100c7946269f5dfcef139f876d562003aef1ca67c4f5cb9534e48fa7e13cd58489ce1d9284908ec1916eef5d36ed039', 'SIMULADO|FE-000055|a100c7946269f5dfcef139f876d562003aef1ca67c4f5cb9534e48fa7e13cd58489ce1d9284908ec1916eef5d36ed039', '2026-09-28 12:02:41', 373150.00, 0.00, 0.00, 373150.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260928122243000'), 'FE-000056', 'cec0770d7a2a6a1ecbc85bdfde5e8b44cc2735446f2155cf3610493a3c5c785c4bb8969bcc60f9a8c8ccb10b901c6e21', 'SIMULADO|FE-000056|cec0770d7a2a6a1ecbc85bdfde5e8b44cc2735446f2155cf3610493a3c5c785c4bb8969bcc60f9a8c8ccb10b901c6e21', '2026-09-28 12:23:43', 413150.00, 0.00, 0.00, 413150.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260930091515000'), 'FE-000057', '7931061c1548e3f8f90bfba1fa8d54d9986950ebc240759d1cc171d38e9aa8e945b57cfb9a431ad7392e72f41bc49f31', 'SIMULADO|FE-000057|7931061c1548e3f8f90bfba1fa8d54d9986950ebc240759d1cc171d38e9aa8e945b57cfb9a431ad7392e72f41bc49f31', '2026-09-30 09:17:15', 592800.00, 0.00, 0.00, 592800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260930112904000'), 'FE-000058', '542caeb3f60bffe21a40d05dcd3f175078f864235cb14d6dc6dda0f79d43ca924042ac0f55a26d7012d70c707ed3fd65', 'SIMULADO|FE-000058|542caeb3f60bffe21a40d05dcd3f175078f864235cb14d6dc6dda0f79d43ca924042ac0f55a26d7012d70c707ed3fd65', '2026-09-30 11:33:04', 295500.00, 0.00, 0.00, 295500.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001124951000'), 'FE-000059', 'a7520dae2b938b1a673000ec4b2687f5fc71c9c74038d970d971b25bc57a8bffc881840775d65d8f551c22b4bf49e6fc', 'SIMULADO|FE-000059|a7520dae2b938b1a673000ec4b2687f5fc71c9c74038d970d971b25bc57a8bffc881840775d65d8f551c22b4bf49e6fc', '2026-10-01 12:54:51', 120040.00, 0.00, 0.00, 120040.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001145245000'), 'FE-000060', 'bf502478c811d6582d42e1494d3438fe1f06e3c07c245264c878ae0e82a88646a4046ef12b6b4c895ff0ff7a4b33ac63', 'SIMULADO|FE-000060|bf502478c811d6582d42e1494d3438fe1f06e3c07c245264c878ae0e82a88646a4046ef12b6b4c895ff0ff7a4b33ac63', '2026-10-01 14:54:45', 304200.00, 0.00, 0.00, 304200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001161647000'), 'FE-000061', 'e52894e6bcbe882e7b4b85b41fe76b8466ad5320466d1b8c589ffb328082fcffde2e9e755f27fbb0304768f92bbad61b', 'SIMULADO|FE-000061|e52894e6bcbe882e7b4b85b41fe76b8466ad5320466d1b8c589ffb328082fcffde2e9e755f27fbb0304768f92bbad61b', '2026-10-01 16:20:47', 237800.00, 0.00, 0.00, 237800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261003145725000'), 'FE-000062', '7a7bfb3b3cbe98335f22061dc646df68e0369c3e72b3c2f52767f8818815cd1129ec8946e0a95aedbc8d00ae4ee79777', 'SIMULADO|FE-000062|7a7bfb3b3cbe98335f22061dc646df68e0369c3e72b3c2f52767f8818815cd1129ec8946e0a95aedbc8d00ae4ee79777', '2026-10-03 14:58:25', 34350.00, 0.00, 0.00, 34350.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261005090611000'), 'FE-000063', '8eb21a0b74d0e9f056c38619b37a5f55192c3e2c54b643df9e5449e2105b203aa7c5650c3a0f4a180428330feefb6950', 'SIMULADO|FE-000063|8eb21a0b74d0e9f056c38619b37a5f55192c3e2c54b643df9e5449e2105b203aa7c5650c3a0f4a180428330feefb6950', '2026-10-05 09:07:11', 133000.00, 0.00, 0.00, 133000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261005125509000'), 'FE-000064', '9985ee455208ebfd87d249e73f3ea0a51c960e8515965a297440f1ac711108a644d3818521c157f8ac434124737a984a', 'SIMULADO|FE-000064|9985ee455208ebfd87d249e73f3ea0a51c960e8515965a297440f1ac711108a644d3818521c157f8ac434124737a984a', '2026-10-05 13:00:09', 99200.00, 0.00, 0.00, 99200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261006132250000'), 'FE-000065', '6f411bb7cb2dab22422c8510dbf5d4937ac0e8449747791aecdda9d986e728ce797eb60efb22db9b4d473eaa1cf75381', 'SIMULADO|FE-000065|6f411bb7cb2dab22422c8510dbf5d4937ac0e8449747791aecdda9d986e728ce797eb60efb22db9b4d473eaa1cf75381', '2026-10-06 13:28:50', 337660.00, 71148.00, 0.00, 266512.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261007091839000'), 'FE-000066', '5b8dd649a38721f5e59cf1b72ca1196e9e0e2ae4f11a58a8461bbc980a6f93bb0469ccbe9ef065f1d94f7af537b30acb', 'SIMULADO|FE-000066|5b8dd649a38721f5e59cf1b72ca1196e9e0e2ae4f11a58a8461bbc980a6f93bb0469ccbe9ef065f1d94f7af537b30acb', '2026-10-07 09:24:39', 643100.00, 0.00, 0.00, 643100.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008083520000'), 'FE-000067', '744d3305d47ddfef4d89bbe85aed15f33d509ce5ebfda4578490e898a4189e309979a6b6d6526939db47871cccd5934f', 'SIMULADO|FE-000067|744d3305d47ddfef4d89bbe85aed15f33d509ce5ebfda4578490e898a4189e309979a6b6d6526939db47871cccd5934f', '2026-10-08 08:38:20', 343350.00, 0.00, 0.00, 343350.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008084053000'), 'FE-000068', 'ff1c5e69bb3a7b13110e681344b55e5bc602792375e87718c0cf7ebe510c09b9669758bca68a59141a4cf9e330b6f8c8', 'SIMULADO|FE-000068|ff1c5e69bb3a7b13110e681344b55e5bc602792375e87718c0cf7ebe510c09b9669758bca68a59141a4cf9e330b6f8c8', '2026-10-08 08:46:53', 86750.00, 24800.00, 0.00, 61950.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008091631000'), 'FE-000069', 'bb5762cec6ecad3cdd98d58dba42302cd4e5f75940e409f9b2c4e387264101c9712adc27504cf1c6566fae5086a633c4', 'SIMULADO|FE-000069|bb5762cec6ecad3cdd98d58dba42302cd4e5f75940e409f9b2c4e387264101c9712adc27504cf1c6566fae5086a633c4', '2026-10-08 09:17:31', 228000.00, 0.00, 0.00, 228000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008130039000'), 'FE-000070', 'bee4ad99d1205ff7b53efc1ed71fabb5814dc643c2d9c714381b9c704b6956c5c5d95a9e0379a696db0ae21b8cc26fa4', 'SIMULADO|FE-000070|bee4ad99d1205ff7b53efc1ed71fabb5814dc643c2d9c714381b9c704b6956c5c5d95a9e0379a696db0ae21b8cc26fa4', '2026-10-08 13:04:39', 18600.00, 0.00, 0.00, 18600.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009092500000'), 'FE-000071', '2624eef7c67eecce27c8c4205590f1032fe4e692d47e882f19c668c5c5907cf0cd33b9a07da8ac9d1d06c854c81ea3dc', 'SIMULADO|FE-000071|2624eef7c67eecce27c8c4205590f1032fe4e692d47e882f19c668c5c5907cf0cd33b9a07da8ac9d1d06c854c81ea3dc', '2026-10-09 09:31:00', 16250.00, 0.00, 0.00, 16250.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009122601000'), 'FE-000072', 'fb0f5b8c70ac20bf129ca4fe6429c8d14aef8c2e6324378af14eb1b78e541d7e379442c5762796e30b70e7da221a1428', 'SIMULADO|FE-000072|fb0f5b8c70ac20bf129ca4fe6429c8d14aef8c2e6324378af14eb1b78e541d7e379442c5762796e30b70e7da221a1428', '2026-10-09 12:27:01', 374600.00, 15030.00, 0.00, 359570.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009134113000'), 'FE-000073', '312f74fcfb5eb76e4ec57673fd43765079a4e51c54b561fe0032ecb11e51d4b39de76f8c8d545f06ca943be8d2273480', 'SIMULADO|FE-000073|312f74fcfb5eb76e4ec57673fd43765079a4e51c54b561fe0032ecb11e51d4b39de76f8c8d545f06ca943be8d2273480', '2026-10-09 13:47:13', 10350.00, 0.00, 0.00, 10350.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009150958000'), 'FE-000074', 'd8331290c8123cf4c64686ddf60ff85f2adf08641c13e010d551c809263f0cc0a7f24437135823427311ee28ba27b9c6', 'SIMULADO|FE-000074|d8331290c8123cf4c64686ddf60ff85f2adf08641c13e010d551c809263f0cc0a7f24437135823427311ee28ba27b9c6', '2026-10-09 15:13:58', 74400.00, 0.00, 0.00, 74400.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010082538000'), 'FE-000075', '5ba2f5329bae265c8fde23a1b3b2a180b1a918447dbb57c97e3d76967ce2caead241e838043560ad7e6bea0429edd961', 'SIMULADO|FE-000075|5ba2f5329bae265c8fde23a1b3b2a180b1a918447dbb57c97e3d76967ce2caead241e838043560ad7e6bea0429edd961', '2026-10-10 08:30:38', 34500.00, 0.00, 0.00, 34500.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010110304000'), 'FE-000076', '0713d4cbda684fdc1e62e89d18c4eff5c35ab854657756dc763a48b6dc6d7fb09a526c0504f70d70f8bff01889eea2e3', 'SIMULADO|FE-000076|0713d4cbda684fdc1e62e89d18c4eff5c35ab854657756dc763a48b6dc6d7fb09a526c0504f70d70f8bff01889eea2e3', '2026-10-10 11:08:04', 33200.00, 9920.00, 0.00, 23280.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010125643000'), 'FE-000077', '3acb32519994c80e874a4c0487243177cd958c712be5b00f048b0904d1eeafc7bcfd9b647dad324b904b2cdc5b317e8e', 'SIMULADO|FE-000077|3acb32519994c80e874a4c0487243177cd958c712be5b00f048b0904d1eeafc7bcfd9b647dad324b904b2cdc5b317e8e', '2026-10-10 12:59:43', 845200.00, 0.00, 0.00, 845200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010164748000'), 'FE-000078', '477145ca29d9aacf633c2a0dc93f7666407ce93b163488f3dc6e80c0a02a02864eeea19963396ac03de1f2ddd5b74043', 'SIMULADO|FE-000078|477145ca29d9aacf633c2a0dc93f7666407ce93b163488f3dc6e80c0a02a02864eeea19963396ac03de1f2ddd5b74043', '2026-10-10 16:51:48', 81000.00, 0.00, 0.00, 81000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013101837000'), 'FE-000079', '66eb56c0c9f5fefb0423317aa3ef22181200927326fef5c5f08774c27cb7e05589b5ce994164a0d7b50411429d5395b4', 'SIMULADO|FE-000079|66eb56c0c9f5fefb0423317aa3ef22181200927326fef5c5f08774c27cb7e05589b5ce994164a0d7b50411429d5395b4', '2026-10-13 10:24:37', 69200.00, 0.00, 0.00, 69200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013125226000'), 'FE-000080', 'e832ab8f899b588e4f31528322dd53e14d89e1f4b5deed1a7efd57a6c5b9ba76e95349ddb57549cd8b3046d0f8ef5a63', 'SIMULADO|FE-000080|e832ab8f899b588e4f31528322dd53e14d89e1f4b5deed1a7efd57a6c5b9ba76e95349ddb57549cd8b3046d0f8ef5a63', '2026-10-13 12:54:26', 318250.00, 0.00, 0.00, 318250.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013163958000'), 'FE-000081', 'e100cc77a8e51cbb1ce40ae533bbcc0d9a9e2e24daf92b96279147274113894c0c761b3a5e5fe4135788f8117d85ed7a', 'SIMULADO|FE-000081|e100cc77a8e51cbb1ce40ae533bbcc0d9a9e2e24daf92b96279147274113894c0c761b3a5e5fe4135788f8117d85ed7a', '2026-10-13 16:44:58', 95225.00, 0.00, 0.00, 95225.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261014112401000'), 'FE-000082', '77c1e75d5e0f6f127b9e299932eba19384229ba56866f81bd9b0a59909bec94ab5e36b1038ebec39c79866d484cefafd', 'SIMULADO|FE-000082|77c1e75d5e0f6f127b9e299932eba19384229ba56866f81bd9b0a59909bec94ab5e36b1038ebec39c79866d484cefafd', '2026-10-14 11:30:01', 303500.00, 0.00, 0.00, 303500.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261014150111000'), 'FE-000083', 'ab11080296b40a93e3ad917e25186e802b2ad4a7f7dbaa86a2a5407e912bd3fc6cfa6b7cb232054ad03d8bbaa9df53dc', 'SIMULADO|FE-000083|ab11080296b40a93e3ad917e25186e802b2ad4a7f7dbaa86a2a5407e912bd3fc6cfa6b7cb232054ad03d8bbaa9df53dc', '2026-10-14 15:02:11', 312150.00, 0.00, 0.00, 312150.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261016112536000'), 'FE-000084', '390aa215d73f7a931e4ba9944c8c9bff14fbed73d99d6ad3d3c2e0e364a875abb607ad37a2d9f12e9ac0f1ff25ec2180', 'SIMULADO|FE-000084|390aa215d73f7a931e4ba9944c8c9bff14fbed73d99d6ad3d3c2e0e364a875abb607ad37a2d9f12e9ac0f1ff25ec2180', '2026-10-16 11:26:36', 20200.00, 0.00, 0.00, 20200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261016132250000'), 'FE-000085', '936b00e391c09f8177725a65297b700ec5aecaed0ace5edebeaf64a47fbaf6260682fbb7ef948a5b435f0f47128d3342', 'SIMULADO|FE-000085|936b00e391c09f8177725a65297b700ec5aecaed0ace5edebeaf64a47fbaf6260682fbb7ef948a5b435f0f47128d3342', '2026-10-16 13:25:50', 249800.00, 0.00, 0.00, 249800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261017092510000'), 'FE-000086', '4fc7390324bc568d6d474b803204d1014a524d1c7d47f2d74d62dcf72f095c8020bf8167f01a69b40b72e96c3bb71d0b', 'SIMULADO|FE-000086|4fc7390324bc568d6d474b803204d1014a524d1c7d47f2d74d62dcf72f095c8020bf8167f01a69b40b72e96c3bb71d0b', '2026-10-17 09:30:10', 384900.00, 0.00, 0.00, 384900.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261017132202000'), 'FE-000087', 'c5f01f8968b6605120f3be15e54538cf6b777655431dcdec51c954de4f9c16d9ce92daeba385a49e0781a88c82543dfa', 'SIMULADO|FE-000087|c5f01f8968b6605120f3be15e54538cf6b777655431dcdec51c954de4f9c16d9ce92daeba385a49e0781a88c82543dfa', '2026-10-17 13:28:02', 390300.00, 0.00, 0.00, 390300.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261019112437000'), 'FE-000088', 'f3e64fdfe0b67aedc3956d681a07ae56ee466e413a61064ddaba577141ec273e6b271f73cf49780bcf9c774d93079937', 'SIMULADO|FE-000088|f3e64fdfe0b67aedc3956d681a07ae56ee466e413a61064ddaba577141ec273e6b271f73cf49780bcf9c774d93079937', '2026-10-19 11:25:37', 116700.00, 0.00, 0.00, 116700.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261020082334000'), 'FE-000089', '3cd287415f2117e668ea53655dc7dcba9e73cd2e27bc0a9ed23dcaaeea806d8adb55f8d552220d54739851327a9a9f3e', 'SIMULADO|FE-000089|3cd287415f2117e668ea53655dc7dcba9e73cd2e27bc0a9ed23dcaaeea806d8adb55f8d552220d54739851327a9a9f3e', '2026-10-20 08:29:34', 80800.00, 0.00, 0.00, 80800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261021164505000'), 'FE-000090', '460792e7eb3efdfa22553137da9676a6f872813d96c8c0319211a6ed3480b673c1a0ac18a77db799e781c667aad93164', 'SIMULADO|FE-000090|460792e7eb3efdfa22553137da9676a6f872813d96c8c0319211a6ed3480b673c1a0ac18a77db799e781c667aad93164', '2026-10-21 16:48:05', 337800.00, 0.00, 0.00, 337800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261022105400000'), 'FE-000091', 'c97423992473abb3158ad7f703233f8a886b9f1e23a933eb47ad121e1592e37833dedbbdc9346861df4209fe3199e1d9', 'SIMULADO|FE-000091|c97423992473abb3158ad7f703233f8a886b9f1e23a933eb47ad121e1592e37833dedbbdc9346861df4209fe3199e1d9', '2026-10-22 10:57:00', 5250.00, 1575.00, 0.00, 3675.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261022111512000'), 'FE-000092', '7b7fdc26f24281f564742ca20210f7bc5a7e838d1681169c198a7334c12bcbb19150b4cb54aead7027e1a754841a9425', 'SIMULADO|FE-000092|7b7fdc26f24281f564742ca20210f7bc5a7e838d1681169c198a7334c12bcbb19150b4cb54aead7027e1a754841a9425', '2026-10-22 11:18:12', 50225.00, 0.00, 0.00, 50225.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261023105852000'), 'FE-000093', 'fd83e9073620d763e60809912b32745b1faedb5c8b97e09ef5240b39c8cfe4bf7a093afbf6a3ce90eeacec83c56d00c1', 'SIMULADO|FE-000093|fd83e9073620d763e60809912b32745b1faedb5c8b97e09ef5240b39c8cfe4bf7a093afbf6a3ce90eeacec83c56d00c1', '2026-10-23 11:02:52', 554300.00, 0.00, 0.00, 554300.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261024124600000'), 'FE-000094', 'a26d99d28f0383840eaa30d2b672d9f64d3a2033df9fcf78301a07aece63fd889c0c26628c1ac6511c96922f60f1b6f6', 'SIMULADO|FE-000094|a26d99d28f0383840eaa30d2b672d9f64d3a2033df9fcf78301a07aece63fd889c0c26628c1ac6511c96922f60f1b6f6', '2026-10-24 12:49:00', 51400.00, 4200.00, 0.00, 47200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261026121127000'), 'FE-000095', '57e8e97d80218d06bfc64a225ebe6272e07917748342f59a908308b08fa4176d3a125159d44054b17f64986f9b8f010e', 'SIMULADO|FE-000095|57e8e97d80218d06bfc64a225ebe6272e07917748342f59a908308b08fa4176d3a125159d44054b17f64986f9b8f010e', '2026-10-26 12:15:27', 72100.00, 0.00, 0.00, 72100.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027083325000'), 'FE-000096', '09a555d38b04e0739b9d7b9f0f7f352bc820f9891ee71273c6fe9bb5588ad27542e30e0e04b785ac4c85823c2a1d8f1a', 'SIMULADO|FE-000096|09a555d38b04e0739b9d7b9f0f7f352bc820f9891ee71273c6fe9bb5588ad27542e30e0e04b785ac4c85823c2a1d8f1a', '2026-10-27 08:38:25', 464200.00, 0.00, 0.00, 464200.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027111232000'), 'FE-000097', '688122c48bc0998e4fcd1a49f6a247e3f312254054dc7b9f93ab35302d13cabbf50c903a57c73ff498e6a7a45d618d4d', 'SIMULADO|FE-000097|688122c48bc0998e4fcd1a49f6a247e3f312254054dc7b9f93ab35302d13cabbf50c903a57c73ff498e6a7a45d618d4d', '2026-10-27 11:17:32', 111900.00, 0.00, 0.00, 111900.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027112414000'), 'FE-000098', 'c6824cee88740d032fbf7380ef99dc520a86c319dfe649652c186d41ac3ee3ebb149b483bc0ff8e3c1dd8f5f5fcfa457', 'SIMULADO|FE-000098|c6824cee88740d032fbf7380ef99dc520a86c319dfe649652c186d41ac3ee3ebb149b483bc0ff8e3c1dd8f5f5fcfa457', '2026-10-27 11:30:14', 428800.00, 0.00, 0.00, 428800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027134135000'), 'FE-000099', '133e51d3549683fd20a5b5db39b2f405f91e609148a672894ab462c68100c36efc23184ee5d23c88c3385520f4466caf', 'SIMULADO|FE-000099|133e51d3549683fd20a5b5db39b2f405f91e609148a672894ab462c68100c36efc23184ee5d23c88c3385520f4466caf', '2026-10-27 13:47:35', 14850.00, 0.00, 0.00, 14850.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027152159000'), 'FE-000100', '8f24abb29d3adf70ef506d2650d9dbb262aff7ec9df3f6ff20d9e9ded80b24c7b6c857911f444a6d53a03ef9e1154f85', 'SIMULADO|FE-000100|8f24abb29d3adf70ef506d2650d9dbb262aff7ec9df3f6ff20d9e9ded80b24c7b6c857911f444a6d53a03ef9e1154f85', '2026-10-27 15:24:59', 31700.00, 3900.00, 0.00, 27800.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261028131728000'), 'FE-000101', '64386d47a62ef7eb1a42763c37a81a0f3574bfbb6cc964171e1ea361c0760cff599011243d8a32465c38573bacfba3a9', 'SIMULADO|FE-000101|64386d47a62ef7eb1a42763c37a81a0f3574bfbb6cc964171e1ea361c0760cff599011243d8a32465c38573bacfba3a9', '2026-10-28 13:18:28', 46800.00, 2340.00, 0.00, 44460.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261028132120000'), 'FE-000102', '89d81d21a2a6ce8fae9cb17724b2dcfe815362c5d729b7bf4c046fab7b464a600cb979267039c14b73da2163356e3358', 'SIMULADO|FE-000102|89d81d21a2a6ce8fae9cb17724b2dcfe815362c5d729b7bf4c046fab7b464a600cb979267039c14b73da2163356e3358', '2026-10-28 13:27:20', 447300.00, 0.00, 0.00, 447300.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261028142718000'), 'FE-000103', '1bd2ed6fedb8236123e5fc19ff920fc5f246fa6f5fa06ff192af14ba14e5468bc6453dc24f34151ce410803f96983a9b', 'SIMULADO|FE-000103|1bd2ed6fedb8236123e5fc19ff920fc5f246fa6f5fa06ff192af14ba14e5468bc6453dc24f34151ce410803f96983a9b', '2026-10-28 14:31:18', 748000.00, 0.00, 0.00, 748000.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261029132920000'), 'FE-000104', '7666d8ce61c2285ef94f90add17aa364b0aefe3af4f5906401477d769851b73e01bf10df4b0fd60313d0bb613434d83a', 'SIMULADO|FE-000104|7666d8ce61c2285ef94f90add17aa364b0aefe3af4f5906401477d769851b73e01bf10df4b0fd60313d0bb613434d83a', '2026-10-29 13:31:20', 687750.00, 43680.00, 0.00, 644070.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261030100607000'), 'FE-000105', '1c36b2fd1e160047ffd67771575584f314af3f8bf7687ec6baa76fec242b5822e665daa1529eb5567a5b804897c35ba7', 'SIMULADO|FE-000105|1c36b2fd1e160047ffd67771575584f314af3f8bf7687ec6baa76fec242b5822e665daa1529eb5567a5b804897c35ba7', '2026-10-30 10:12:07', 566350.00, 0.00, 0.00, 566350.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261030101853000'), 'FE-000106', 'd0df1585a0db4b70c346f2ebf435b0d768bf2d3de677375300b162305c39dcc074d90f0a0f81edee66e325585805e50f', 'SIMULADO|FE-000106|d0df1585a0db4b70c346f2ebf435b0d768bf2d3de677375300b162305c39dcc074d90f0a0f81edee66e325585805e50f', '2026-10-30 10:22:53', 64350.00, 5850.00, 0.00, 58500.00),
((SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261031125424000'), 'FE-000107', '9c9e0e0567e5aa3ffca2e3f5e95b2937103d8c6b5d2137cbc11b55efeb6ccbedf7a5c5fa1fc683caf5c900c3ccb3f788', 'SIMULADO|FE-000107|9c9e0e0567e5aa3ffca2e3f5e95b2937103d8c6b5d2137cbc11b55efeb6ccbedf7a5c5fa1fc683caf5c900c3ccb3f788', '2026-10-31 12:57:24', 615300.00, 0.00, 0.00, 615300.00)
ON DUPLICATE KEY UPDATE numero_factura = numero_factura;

-- 2.12 Vehiculos (50): 40 activos, 6 en mantenimiento y 4 inactivos.
INSERT INTO vehiculos (placa, modelo, capacidad, estado) VALUES
('SCT938', 'Chevrolet NHR 2019', 1800.00, 'Mantenimiento'),
('UZG988', 'Chevrolet NPR 2020', 4500.00, 'Activo'),
('JNT121', 'Hino Dutro 2018', 3500.00, 'Inactivo'),
('WLS785', 'JAC 1040 2021', 2500.00, 'Activo'),
('SCD846', 'Foton Aumark 2022', 3000.00, 'Activo'),
('TJT962', 'Isuzu NKR 2017', 2800.00, 'Activo'),
('HNP665', 'Kia K2700 2019', 1200.00, 'Activo'),
('UJP960', 'Hyundai HD65 2020', 3200.00, 'Activo'),
('UFG994', 'Renault Kangoo 2021', 650.00, 'Activo'),
('STZ655', 'Nissan Cabstar 2018', 2500.00, 'Activo'),
('HVB344', 'JMC Carrying 2022', 1500.00, 'Activo'),
('JZZ694', 'Chevrolet N300 2021', 700.00, 'Activo'),
('WPD808', 'Hino 300 2023', 4000.00, 'Mantenimiento'),
('UMH814', 'Foton Midi 2020', 900.00, 'Activo'),
('TPK491', 'DFSK K01 2022', 1000.00, 'Activo'),
('JVY575', 'Chevrolet NHR 2019', 1800.00, 'Activo'),
('SNJ779', 'Foton Aumark 2022', 3000.00, 'Activo'),
('HVF972', 'JMC Carrying 2022', 1500.00, 'Activo'),
('JNB414', 'Foton Aumark 2022', 3000.00, 'Activo'),
('WPS446', 'JAC 1040 2021', 2500.00, 'Activo'),
('SZD639', 'Isuzu NKR 2017', 2800.00, 'Mantenimiento'),
('SFJ136', 'JMC Carrying 2022', 1500.00, 'Activo'),
('JFH738', 'DFSK K01 2022', 1000.00, 'Activo'),
('JHM950', 'Renault Kangoo 2021', 650.00, 'Activo'),
('WBF784', 'Foton Aumark 2022', 3000.00, 'Activo'),
('UYZ410', 'Foton Aumark 2022', 3000.00, 'Activo'),
('TKM279', 'Foton Midi 2020', 900.00, 'Activo'),
('TNH371', 'Hino 300 2023', 4000.00, 'Activo'),
('WFB799', 'DFSK K01 2022', 1000.00, 'Activo'),
('JZT311', 'Kia K2700 2019', 1200.00, 'Activo'),
('UJT461', 'Hino Dutro 2018', 3500.00, 'Activo'),
('TBF607', 'JMC Carrying 2022', 1500.00, 'Mantenimiento'),
('WLF989', 'JMC Carrying 2022', 1500.00, 'Activo'),
('HRR670', 'Chevrolet NPR 2020', 4500.00, 'Activo'),
('SXD489', 'Hino 300 2023', 4000.00, 'Activo'),
('SBP656', 'Foton Aumark 2022', 3000.00, 'Activo'),
('HSM627', 'Kia K2700 2019', 1200.00, 'Activo'),
('WCV933', 'JMC Carrying 2022', 1500.00, 'Inactivo'),
('HPV488', 'Hino Dutro 2018', 3500.00, 'Activo'),
('THX899', 'JAC 1040 2021', 2500.00, 'Mantenimiento'),
('UHW181', 'Nissan Cabstar 2018', 2500.00, 'Activo'),
('HCR813', 'Renault Kangoo 2021', 650.00, 'Activo'),
('TZL867', 'Nissan Cabstar 2018', 2500.00, 'Activo'),
('TVR891', 'Kia K2700 2019', 1200.00, 'Inactivo'),
('TGN162', 'Kia K2700 2019', 1200.00, 'Mantenimiento'),
('JML358', 'Nissan Cabstar 2018', 2500.00, 'Activo'),
('SWW256', 'Nissan Cabstar 2018', 2500.00, 'Inactivo'),
('JTS639', 'DFSK K01 2022', 1000.00, 'Activo'),
('HYS702', 'Nissan Cabstar 2018', 2500.00, 'Activo'),
('TMF989', 'Hino Dutro 2018', 3500.00, 'Activo')
ON DUPLICATE KEY UPDATE placa = placa;

-- 2.13 Conductores (50): 45 activos y 5 inactivos. numero_licencia = numero de cedula.
INSERT INTO conductores (nombre, numero_licencia, telefono, email, activo) VALUES
('Jose Pineda Velandia', '1013194840', '328 532 4454', 'jose.pineda20@example.com', TRUE),
('Luis Rodriguez Pineda', '1069208425', '318 861 3498', 'luis.rodriguez62@example.com', TRUE),
('Carlos Hurtado Caicedo', '1069407148', '313 426 5738', 'carlos.hurtado70@example.com', TRUE),
('Jhon Pineda Garzon', '1069456836', '320 558 6008', 'jhon.pineda43@example.com', TRUE),
('Edwin Guerrero Duarte', '7991511789', '353 287 6830', 'edwin.guerrero64@example.com', TRUE),
('Fredy Suarez Parra', '7935556342', '355 416 2278', 'fredy.suarez14@example.com', TRUE),
('William Espitia Espitia', '1069411852', '358 818 4898', 'william.espitia85@example.com', TRUE),
('Oscar Bautista Cardenas', '7976913637', '301 837 2396', 'oscar.bautista88@example.com', TRUE),
('Nelson Velandia Cortes', '1013475970', '323 599 2236', 'nelson.velandia8@example.com', TRUE),
('Ruben Urrego Sanchez', '1069963340', '301 646 1497', 'ruben.urrego62@example.com', TRUE),
('Wilson Velandia Leon', '1073495874', '300 553 5242', 'wilson.velandia39@example.com', TRUE),
('Jairo Arias Torres', '1069982572', '315 663 8694', 'jairo.arias86@example.com', TRUE),
('Hector Leon Cardenas', '1069249759', '320 545 7631', 'hector.leon27@example.com', TRUE),
('Fabian Murcia Acosta', '1013739585', '352 370 6032', 'fabian.murcia17@example.com', TRUE),
('Alexander Rincon Torres', '1073149993', '313 976 8001', 'alexander.rincon92@example.com', TRUE),
('Diego Arias Lopez', '7961950322', '329 325 3876', 'diego.arias92@example.com', TRUE),
('Mauricio Moreno Mendoza', '8043089520', '308 259 4154', 'mauricio.moreno60@example.com', TRUE),
('Henry Torres Guerrero', '1073882407', '305 678 7119', 'henry.torres43@example.com', FALSE),
('Camilo Duarte Rincon', '1013288400', '327 518 7897', 'camilo.duarte70@example.com', TRUE),
('Jorge Martinez Beltran', '1069959988', '323 487 5801', 'jorge.martinez4@example.com', TRUE),
('Omar Cifuentes Pulido', '1069595139', '314 511 2634', 'omar.cifuentes52@example.com', FALSE),
('Ferney Caicedo Rincon', '1013866993', '324 422 4421', 'ferney.caicedo7@example.com', TRUE),
('Yesid Castro Rincon', '1013999281', '352 270 3789', 'yesid.castro41@example.com', FALSE),
('Arley Hurtado Mendoza', '1073568336', '312 767 8825', 'arley.hurtado9@example.com', FALSE),
('Hugo Acosta Pulido', '1022409969', '317 590 5494', 'hugo.acosta46@example.com', TRUE),
('Cristian Rodriguez Espitia', '1030676652', '353 717 1152', 'cristian.rodriguez1@example.com', TRUE),
('Brayan Cardenas Duarte', '8065261937', '329 484 3364', 'brayan.cardenas10@example.com', TRUE),
('Andres Sanchez Ortiz', '1022259978', '323 421 1624', 'andres.sanchez95@example.com', TRUE),
('Ivan Guerrero Gomez', '1073836961', '359 918 5434', 'ivan.guerrero95@example.com', TRUE),
('Nestor Zambrano Lopez', '1030989566', '359 768 6732', 'nestor.zambrano84@example.com', FALSE),
('Leidy Galindo Bautista', '8085774368', '354 275 4015', 'leidy.galindo9@example.com', TRUE),
('Yuli Rodriguez Torres', '7998947596', '325 333 9463', 'yuli.rodriguez12@example.com', TRUE),
('Sandra Espitia Mendoza', '8071842600', '350 285 8269', 'sandra.espitia54@example.com', TRUE),
('Marcela Vargas Suarez', '7978482677', '311 504 9098', 'marcela.vargas51@example.com', TRUE),
('Rodrigo Mendoza Zambrano', '1030392582', '307 877 7837', 'rodrigo.mendoza60@example.com', TRUE),
('Ever Vargas Hurtado', '8032638928', '310 707 3932', 'ever.vargas55@example.com', TRUE),
('Gerardo Pineda Cortes', '8025615688', '314 607 5852', 'gerardo.pineda90@example.com', TRUE),
('Libardo Rodriguez Duarte', '1073726004', '300 286 9443', 'libardo.rodriguez16@example.com', TRUE),
('Duvan Rincon Cifuentes', '1069259568', '357 409 5944', 'duvan.rincon13@example.com', TRUE),
('Sebastian Ortiz Rodriguez', '7951713957', '355 567 6132', 'sebastian.ortiz62@example.com', TRUE),
('Mario Espitia Garzon', '7972544431', '321 536 1646', 'mario.espitia59@example.com', TRUE),
('Julio Castro Murcia', '7932734189', '312 377 2018', 'julio.castro6@example.com', TRUE),
('Eduardo Gomez Cortes', '8011743954', '357 865 8336', 'eduardo.gomez27@example.com', TRUE),
('Alberto Vargas Beltran', '1069371690', '320 808 6237', 'alberto.vargas34@example.com', TRUE),
('Javier Martinez Beltran', '1069289701', '311 209 8474', 'javier.martinez77@example.com', TRUE),
('Felipe Suarez Caicedo', '1022667736', '304 756 5300', 'felipe.suarez17@example.com', TRUE),
('Jaime Mendoza Murcia', '1073442476', '321 335 1035', 'jaime.mendoza5@example.com', TRUE),
('Pedro Beltran Murcia', '1069528621', '312 259 3577', 'pedro.beltran79@example.com', TRUE),
('Oswaldo Velandia Pineda', '1073628834', '355 648 4228', 'oswaldo.velandia56@example.com', TRUE),
('Elkin Bernal Gomez', '8032144614', '328 849 2353', 'elkin.bernal35@example.com', TRUE)
ON DUPLICATE KEY UPDATE numero_licencia = numero_licencia;

-- 2.14 Rutas de entrega (50)
-- Completada 43: llevan las ventas Entregadas.
-- En Transito 2: llevan las ventas En Transito (salieron el 2026-11-02).
-- Planificada 4: tres con ventas En Preparacion y una vacia para probar la asignacion.
-- Cancelada 1: sin ventas (el vehiculo no encendio).
-- Quedan ventas En Preparacion sin ruta para que aparezcan en el panel de despachos.
-- nombre_ruta no se repite y sirve como clave natural para las demas tablas de logistica.
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Suba - Usaquen 03/09/2026', '2026-09-02 17:35:00', 'afajardo.logistica', '2026-09-03 06:30:00', '2026-09-03 10:30:00', '2026-09-03 06:26:00', '2026-09-03 10:02:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 03/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Sabana Norte - Teusaquillo 04/09/2026', '2026-09-03 17:03:00', 'cruiz.logistica', '2026-09-04 06:00:00', '2026-09-04 10:00:00', '2026-09-04 05:57:00', '2026-09-04 10:18:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Teusaquillo 04/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Kennedy 05/09/2026', '2026-09-04 17:16:00', 'afajardo.logistica', '2026-09-05 06:00:00', '2026-09-05 11:00:00', '2026-09-05 06:23:00', '2026-09-05 10:42:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy 05/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Soacha - Usaquen 05/09/2026', '2026-09-04 17:05:00', 'cruiz.logistica', '2026-09-05 06:30:00', '2026-09-05 11:30:00', '2026-09-05 06:48:00', '2026-09-05 10:57:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Usaquen 05/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Engativa - Teusaquillo 07/09/2026', '2026-09-05 17:03:00', 'afajardo.logistica', '2026-09-07 06:30:00', '2026-09-07 12:30:00', '2026-09-07 06:37:00', '2026-09-07 12:07:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Teusaquillo 07/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Engativa - Fontibon 07/09/2026', '2026-09-05 17:27:00', 'cruiz.logistica', '2026-09-07 06:30:00', '2026-09-07 10:30:00', '2026-09-07 06:41:00', '2026-09-07 11:18:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Fontibon 07/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Suba - Sabana Norte 08/09/2026', '2026-09-07 17:29:00', 'cruiz.logistica', '2026-09-08 06:00:00', '2026-09-08 12:00:00', '2026-09-08 06:11:00', '2026-09-08 11:36:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Sabana Norte 08/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026', '2026-09-09 17:20:00', 'afajardo.logistica', '2026-09-10 06:00:00', '2026-09-10 10:00:00', '2026-09-10 06:24:00', '2026-09-10 10:02:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Sabana Occidente - Suba 10/09/2026', '2026-09-09 17:27:00', 'cruiz.logistica', '2026-09-10 06:30:00', '2026-09-10 12:30:00', '2026-09-10 06:33:00', '2026-09-10 13:03:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Suba 10/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Soacha - Sabana Norte 12/09/2026', '2026-09-11 17:44:00', 'cruiz.logistica', '2026-09-12 06:30:00', '2026-09-12 12:30:00', '2026-09-12 06:39:00', '2026-09-12 12:47:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Sabana Norte 12/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Chapinero - Suba 14/09/2026', '2026-09-12 17:13:00', 'afajardo.logistica', '2026-09-14 06:30:00', '2026-09-14 12:30:00', '2026-09-14 06:46:00', '2026-09-14 13:09:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 14/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Chapinero - Engativa 15/09/2026', '2026-09-14 17:47:00', 'cruiz.logistica', '2026-09-15 06:00:00', '2026-09-15 12:00:00', '2026-09-15 05:57:00', '2026-09-15 11:55:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Engativa 15/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Kennedy - Usaquen 15/09/2026', '2026-09-14 17:43:00', 'afajardo.logistica', '2026-09-15 06:30:00', '2026-09-15 12:30:00', '2026-09-15 06:25:00', '2026-09-15 12:07:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen 15/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Soacha - Suba 16/09/2026', '2026-09-15 17:05:00', 'cruiz.logistica', '2026-09-16 06:00:00', '2026-09-16 11:00:00', '2026-09-16 05:56:00', '2026-09-16 11:13:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Suba 16/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Engativa - Kennedy 17/09/2026', '2026-09-16 17:32:00', 'cruiz.logistica', '2026-09-17 06:00:00', '2026-09-17 12:00:00', '2026-09-17 06:20:00', '2026-09-17 12:14:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Kennedy 17/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Sabana Norte - Engativa 18/09/2026', '2026-09-17 17:04:00', 'cruiz.logistica', '2026-09-18 06:30:00', '2026-09-18 11:30:00', '2026-09-18 06:37:00', '2026-09-18 11:10:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Engativa 18/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Teusaquillo 19/09/2026', '2026-09-18 17:33:00', 'cruiz.logistica', '2026-09-19 06:00:00', '2026-09-19 10:00:00', '2026-09-19 06:08:00', '2026-09-19 10:32:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo 19/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Suba - Kennedy 21/09/2026', '2026-09-19 17:23:00', 'cruiz.logistica', '2026-09-21 06:00:00', '2026-09-21 11:00:00', '2026-09-21 06:07:00', '2026-09-21 10:23:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Kennedy 21/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Chapinero - Usaquen 21/09/2026', '2026-09-19 17:16:00', 'cruiz.logistica', '2026-09-21 06:30:00', '2026-09-21 12:30:00', '2026-09-21 06:40:00', '2026-09-21 13:08:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Usaquen 21/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Puente Aranda - Engativa 22/09/2026', '2026-09-21 17:45:00', 'afajardo.logistica', '2026-09-22 06:30:00', '2026-09-22 10:30:00', '2026-09-22 06:28:00', '2026-09-22 10:26:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Puente Aranda - Engativa 22/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Kennedy - Sabana Occidente 23/09/2026', '2026-09-22 17:45:00', 'cruiz.logistica', '2026-09-23 06:00:00', '2026-09-23 12:00:00', '2026-09-23 06:05:00', '2026-09-23 11:53:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Occidente 23/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Suba - Usaquen 23/09/2026', '2026-09-22 17:30:00', 'cruiz.logistica', '2026-09-23 06:30:00', '2026-09-23 12:30:00', '2026-09-23 06:28:00', '2026-09-23 12:24:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 23/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Usaquen - Sabana Norte 24/09/2026', '2026-09-23 17:04:00', 'afajardo.logistica', '2026-09-24 06:00:00', '2026-09-24 12:00:00', '2026-09-24 06:05:00', '2026-09-24 12:35:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Norte 24/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Fontibon - Soacha 28/09/2026', '2026-09-26 17:06:00', 'cruiz.logistica', '2026-09-28 06:00:00', '2026-09-28 12:00:00', '2026-09-28 06:25:00', '2026-09-28 11:56:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Soacha 28/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Fontibon - Kennedy 28/09/2026', '2026-09-26 17:48:00', 'cruiz.logistica', '2026-09-28 06:30:00', '2026-09-28 12:30:00', '2026-09-28 06:27:00', '2026-09-28 12:47:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Kennedy 28/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Usaquen - Teusaquillo 28/09/2026', '2026-09-26 17:13:00', 'afajardo.logistica', '2026-09-28 06:30:00', '2026-09-28 11:30:00', '2026-09-28 06:48:00', '2026-09-28 11:59:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Teusaquillo 28/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Fontibon - Chapinero 29/09/2026', '2026-09-28 17:43:00', 'cruiz.logistica', '2026-09-29 06:00:00', '2026-09-29 12:00:00', '2026-09-29 06:22:00', '2026-09-29 11:37:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Chapinero 29/09/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Usaquen - Sabana Occidente 01/10/2026', '2026-09-30 17:38:00', 'cruiz.logistica', '2026-10-01 06:30:00', '2026-10-01 11:30:00', '2026-10-01 06:51:00', '2026-10-01 11:55:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Occidente 01/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Chapinero 02/10/2026', '2026-10-01 17:38:00', 'afajardo.logistica', '2026-10-02 06:00:00', '2026-10-02 11:00:00', '2026-10-02 06:23:00', '2026-10-02 11:42:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero 02/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Engativa - Sabana Norte 02/10/2026', '2026-10-01 17:26:00', 'cruiz.logistica', '2026-10-02 06:30:00', '2026-10-02 12:30:00', '2026-10-02 06:34:00', '2026-10-02 12:12:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Sabana Norte 02/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Engativa 06/10/2026', '2026-10-05 17:29:00', 'afajardo.logistica', '2026-10-06 06:00:00', '2026-10-06 12:00:00', '2026-10-06 06:01:00', '2026-10-06 11:26:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa 06/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Usaquen - Suba 07/10/2026', '2026-10-06 17:10:00', 'afajardo.logistica', '2026-10-07 06:30:00', '2026-10-07 10:30:00', '2026-10-07 06:53:00', '2026-10-07 11:06:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Suba 07/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Kennedy - Sabana Norte 09/10/2026', '2026-10-08 17:12:00', 'afajardo.logistica', '2026-10-09 06:00:00', '2026-10-09 12:00:00', '2026-10-09 06:03:00', '2026-10-09 12:02:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Norte 09/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Suba - Puente Aranda 09/10/2026', '2026-10-08 17:34:00', 'afajardo.logistica', '2026-10-09 06:00:00', '2026-10-09 10:00:00', '2026-10-09 05:55:00', '2026-10-09 09:48:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Puente Aranda 09/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Kennedy 09/10/2026', '2026-10-08 17:20:00', 'cruiz.logistica', '2026-10-09 06:30:00', '2026-10-09 11:30:00', NULL, NULL, 'Cancelada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy 09/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Sabana Occidente - Fontibon 10/10/2026', '2026-10-09 17:15:00', 'afajardo.logistica', '2026-10-10 06:00:00', '2026-10-10 11:00:00', '2026-10-10 06:12:00', '2026-10-10 11:36:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 10/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Engativa - Puente Aranda 10/10/2026', '2026-10-09 17:34:00', 'afajardo.logistica', '2026-10-10 06:00:00', '2026-10-10 10:00:00', '2026-10-10 05:55:00', '2026-10-10 10:03:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Puente Aranda 10/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Usaquen - Fontibon 12/10/2026', '2026-10-10 17:33:00', 'afajardo.logistica', '2026-10-12 06:00:00', '2026-10-12 12:00:00', '2026-10-12 06:05:00', '2026-10-12 12:35:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Fontibon 12/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Teusaquillo - Fontibon 12/10/2026', '2026-10-10 17:23:00', 'afajardo.logistica', '2026-10-12 06:00:00', '2026-10-12 12:00:00', '2026-10-12 06:03:00', '2026-10-12 11:28:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Fontibon 12/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Chapinero - Teusaquillo 14/10/2026', '2026-10-13 17:05:00', 'afajardo.logistica', '2026-10-14 06:00:00', '2026-10-14 12:00:00', '2026-10-14 06:14:00', '2026-10-14 11:25:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Teusaquillo 14/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Teusaquillo - Usaquen 14/10/2026', '2026-10-13 17:42:00', 'cruiz.logistica', '2026-10-14 06:30:00', '2026-10-14 12:30:00', '2026-10-14 06:43:00', '2026-10-14 12:32:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Usaquen 14/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Usaquen - Engativa 15/10/2026', '2026-10-14 17:39:00', 'cruiz.logistica', '2026-10-15 06:30:00', '2026-10-15 11:30:00', '2026-10-15 06:43:00', '2026-10-15 11:40:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Engativa 15/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Soacha - Chapinero 17/10/2026', '2026-10-16 17:26:00', 'afajardo.logistica', '2026-10-17 06:30:00', '2026-10-17 11:30:00', '2026-10-17 06:34:00', '2026-10-17 12:03:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Chapinero 17/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Fontibon - Engativa 19/10/2026', '2026-10-17 17:36:00', 'afajardo.logistica', '2026-10-19 06:00:00', '2026-10-19 12:00:00', '2026-10-19 06:00:00', '2026-10-19 11:20:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Engativa 19/10/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Fontibon - Suba 02/11/2026', '2026-10-21 18:45:05', 'cruiz.logistica', '2026-11-02 06:00:00', '2026-11-02 11:00:00', '2026-11-02 06:19:00', NULL, 'En Transito'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Suba 02/11/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Chapinero - Suba 02/11/2026', '2026-10-23 12:58:52', 'cruiz.logistica', '2026-11-02 06:30:00', '2026-11-02 11:30:00', '2026-11-02 06:44:00', NULL, 'En Transito'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 02/11/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Sabana Norte - Suba 03/11/2026', '2026-10-26 14:11:27', 'cruiz.logistica', '2026-11-03 06:00:00', '2026-11-03 11:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Suba 03/11/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Soacha - Kennedy 03/11/2026', '2026-10-27 13:12:32', 'afajardo.logistica', '2026-11-03 06:30:00', '2026-11-03 11:30:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Kennedy 03/11/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Sabana Occidente - Fontibon 04/11/2026', '2026-10-27 15:41:35', 'cruiz.logistica', '2026-11-04 06:00:00', '2026-11-04 11:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 04/11/2026');
INSERT INTO rutas_entrega (nombre_ruta, fecha_creacion, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'Ruta Norte 04/11/2026', '2026-11-01 18:00:00', 'afajardo.logistica', '2026-11-04 06:30:00', '2026-11-04 11:30:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'Ruta Norte 04/11/2026');

-- 2.15 Asignaciones de vehiculo y conductor (una por ruta)
-- Las rutas Planificadas y En Transito usan vehiculos activos y conductores activos
-- distintos entre si (regla de LogisticaDao: no pueden estar en dos rutas abiertas).
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 03/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'TJT962'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7991511789'), '2026-09-02 18:18:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Suba - Usaquen 03/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Teusaquillo 04/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVB344'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069411852'), '2026-09-03 18:12:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Sabana Norte - Teusaquillo 04/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy 05/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'SFJ136'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '8085774368'), '2026-09-04 18:46:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Kennedy 05/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Usaquen 05/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'SXD489'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '8043089520'), '2026-09-04 17:20:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Soacha - Usaquen 05/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Teusaquillo 07/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HYS702'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1013739585'), '2026-09-05 17:23:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Engativa - Teusaquillo 07/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Fontibon 07/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVF972'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073442476'), '2026-09-05 18:20:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Engativa - Fontibon 07/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Sabana Norte 08/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'SFJ136'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069208425'), '2026-09-07 18:19:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Suba - Sabana Norte 08/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HRR670'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069411852'), '2026-09-09 17:30:00', 'afajardo.logistica', 'Salida por la puerta 2 de la bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Suba 10/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'SBP656'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7976913637'), '2026-09-09 18:21:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Sabana Occidente - Suba 10/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Sabana Norte 12/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HCR813'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '8032144614'), '2026-09-11 18:09:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Soacha - Sabana Norte 12/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 14/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'STZ655'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073628834'), '2026-09-12 18:03:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Chapinero - Suba 14/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Engativa 15/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'SFJ136'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7951713957'), '2026-09-14 19:12:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Chapinero - Engativa 15/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen 15/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'WLF989'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1013194840'), '2026-09-14 18:14:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Kennedy - Usaquen 15/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Suba 16/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'UHW181'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073836961'), '2026-09-15 17:43:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Soacha - Suba 16/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Kennedy 17/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'WPS446'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7951713957'), '2026-09-16 19:02:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Engativa - Kennedy 17/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Engativa 18/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HSM627'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069289701'), '2026-09-17 17:50:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Sabana Norte - Engativa 18/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo 19/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVF972'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7961950322'), '2026-09-18 18:07:00', 'cruiz.logistica', 'Llevar canastillas vacias de regreso'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Teusaquillo 19/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Kennedy 21/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HSM627'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1022259978'), '2026-09-19 18:38:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Suba - Kennedy 21/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Usaquen 21/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HNP665'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '8032144614'), '2026-09-19 18:17:00', 'cruiz.logistica', 'Cargar primero los refrigerados'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Chapinero - Usaquen 21/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Puente Aranda - Engativa 22/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HNP665'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7951713957'), '2026-09-21 18:46:00', 'afajardo.logistica', 'Cargar primero los refrigerados'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Puente Aranda - Engativa 22/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Occidente 23/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'TNH371'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7961950322'), '2026-09-22 18:58:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Kennedy - Sabana Occidente 23/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 23/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVB344'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '8043089520'), '2026-09-22 18:40:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Suba - Usaquen 23/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Norte 24/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JVY575'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1013866993'), '2026-09-23 17:53:00', 'afajardo.logistica', 'Revisar termo king antes de salir'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Usaquen - Sabana Norte 24/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Soacha 28/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JZT311'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7991511789'), '2026-09-26 18:02:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Fontibon - Soacha 28/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Kennedy 28/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'TZL867'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7951713957'), '2026-09-26 18:11:00', 'cruiz.logistica', 'Revisar termo king antes de salir'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Fontibon - Kennedy 28/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Teusaquillo 28/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HRR670'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7935556342'), '2026-09-26 17:49:00', 'afajardo.logistica', 'Salida por la puerta 2 de la bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Usaquen - Teusaquillo 28/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Chapinero 29/09/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HNP665'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069371690'), '2026-09-28 18:34:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Fontibon - Chapinero 29/09/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Occidente 01/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HCR813'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069411852'), '2026-09-30 18:51:00', 'cruiz.logistica', 'Llevar canastillas vacias de regreso'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Usaquen - Sabana Occidente 01/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero 02/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JNB414'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1030676652'), '2026-10-01 18:30:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Chapinero 02/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Sabana Norte 02/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'UZG988'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069259568'), '2026-10-01 17:40:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Engativa - Sabana Norte 02/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa 06/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HNP665'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073836961'), '2026-10-05 18:14:00', 'afajardo.logistica', 'Salida por la puerta 2 de la bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Engativa 06/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Suba 07/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HSM627'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069249759'), '2026-10-06 18:26:00', 'afajardo.logistica', 'Revisar termo king antes de salir'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Usaquen - Suba 07/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Norte 09/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'SXD489'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069411852'), '2026-10-08 17:30:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Kennedy - Sabana Norte 09/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Puente Aranda 09/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JTS639'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073149993'), '2026-10-08 18:14:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Suba - Puente Aranda 09/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy 09/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JFH738'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1022259978'), '2026-10-08 18:38:00', 'cruiz.logistica', 'Ruta cancelada: el vehiculo no encendio, los pedidos pasaron a la ruta del dia siguiente'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Kennedy 09/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 10/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JFH738'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1013194840'), '2026-10-09 17:59:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Sabana Occidente - Fontibon 10/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Puente Aranda 10/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HRR670'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7972544431'), '2026-10-09 17:53:00', 'afajardo.logistica', 'Llevar canastillas vacias de regreso'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Engativa - Puente Aranda 10/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Fontibon 12/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'UFG994'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '8065261937'), '2026-10-10 18:21:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Usaquen - Fontibon 12/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Fontibon 12/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'TKM279'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069959988'), '2026-10-10 18:03:00', 'afajardo.logistica', 'Cargar primero los refrigerados'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Teusaquillo - Fontibon 12/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Teusaquillo 14/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JVY575'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069407148'), '2026-10-13 17:21:00', 'afajardo.logistica', 'Revisar termo king antes de salir'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Chapinero - Teusaquillo 14/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Usaquen 14/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'WPS446'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1013288400'), '2026-10-13 17:54:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Teusaquillo - Usaquen 14/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Engativa 15/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HYS702'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7932734189'), '2026-10-14 18:26:00', 'cruiz.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Usaquen - Engativa 15/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Chapinero 17/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVF972'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069963340'), '2026-10-16 17:48:00', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Soacha - Chapinero 17/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Engativa 19/10/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVB344'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073149993'), '2026-10-17 18:33:00', 'afajardo.logistica', 'Salida por la puerta 2 de la bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Fontibon - Engativa 19/10/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Suba 02/11/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'TMF989'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1069249759'), '2026-10-21 19:17:05', 'cruiz.logistica', 'Salida por la puerta 2 de la bodega'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Fontibon - Suba 02/11/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 02/11/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JZT311'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1073836961'), '2026-10-23 14:09:52', 'cruiz.logistica', 'Cargar primero los refrigerados'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Chapinero - Suba 02/11/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Suba 03/11/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'TJT962'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7991511789'), '2026-10-26 15:16:27', 'cruiz.logistica', 'Llevar canastillas vacias de regreso'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Sabana Norte - Suba 03/11/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Kennedy 03/11/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'JML358'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '1013194840'), '2026-10-27 14:34:32', 'afajardo.logistica', NULL
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Soacha - Kennedy 03/11/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 04/11/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'UHW181'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7961950322'), '2026-10-27 16:07:35', 'cruiz.logistica', 'Llevar canastillas vacias de regreso'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Sabana Occidente - Fontibon 04/11/2026');
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, fecha_asignacion, usuario_asignacion, notas)
SELECT (SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Norte 04/11/2026'), (SELECT id_vehiculo FROM vehiculos WHERE placa = 'HVF972'), (SELECT id_conductor FROM conductores WHERE numero_licencia = '7951713957'), '2026-11-01 18:34:00', 'afajardo.logistica', 'Cargar primero los refrigerados'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM asignaciones_entrega a JOIN rutas_entrega r ON r.id_ruta = a.id_ruta WHERE r.nombre_ruta = 'Ruta Norte 04/11/2026');

-- 2.16 Ventas por ruta (entregas). direccion_destino = direccion del cliente.
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones) VALUES
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 03/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902114427000'), 1, 'Calle 138 # 112-32, Bogota', '2026-09-03 07:38:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 03/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902155354000'), 2, 'Carrera 9 # 142-5, Bogota', '2026-09-03 08:32:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Teusaquillo 04/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260902155404000'), 1, 'Carrera 7 # 6-91, Cajica', '2026-09-04 07:10:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Teusaquillo 04/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260903122427000'), 2, 'Carrera 30 # 36-65, Bogota', '2026-09-04 08:33:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy 05/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260903140018000'), 1, 'Carrera 75 # 46-12 Sur, Bogota', '2026-09-05 07:17:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy 05/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904123420000'), 2, 'Carrera 80 # 30-38 Sur, Bogota', '2026-09-05 08:16:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Usaquen 05/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904143325000'), 1, 'Calle 27 # 16-59, Soacha', '2026-09-05 07:30:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Usaquen 05/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260904165625000'), 2, 'Carrera 18 # 142-27, Bogota', '2026-09-05 08:28:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Teusaquillo 07/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905082432000'), 1, 'Carrera 95 # 78-47, Bogota', '2026-09-07 07:38:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Teusaquillo 07/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905085105000'), 2, 'Calle 46 # 25-52, Bogota', '2026-09-07 08:13:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Fontibon 07/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905100418000'), 1, 'Carrera 95 # 78-47, Bogota', '2026-09-07 07:33:00', 'Recibe el propietario', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Fontibon 07/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905113710000'), 2, 'Carrera 110 # 16-57, Bogota', '2026-09-07 08:58:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Sabana Norte 08/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260905122437000'), 1, 'Carrera 108 # 142-24, Bogota', '2026-09-08 07:25:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Sabana Norte 08/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260907142837000'), 2, 'Calle 18 # 8-16, Chia', '2026-09-08 08:42:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909105928000'), 1, 'Calle 28 Sur # 68-45, Bogota', '2026-09-10 07:28:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909122044000'), 2, 'Carrera 18 # 142-27, Bogota', '2026-09-10 08:32:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen - Puente Aranda 10/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909131414000'), 3, 'Carrera 53 # 15-8, Bogota', '2026-09-10 09:08:00', 'Recibe cajera de turno', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Suba 10/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260908095617000'), 1, 'Carrera 16 # 15-55, Funza', '2026-09-10 07:41:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Suba 10/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909083008000'), 2, 'Calle 154 # 82-95, Bogota', '2026-09-10 09:03:00', 'Recibe el administrador', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Sabana Norte 12/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260909164616000'), 1, 'Calle 20 # 17-95, Soacha', '2026-09-12 07:43:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Sabana Norte 12/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260911110911000'), 2, 'Calle 5 # 5-38, Cajica', '2026-09-12 09:03:00', 'Recibe el propietario', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 14/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260911134623000'), 1, 'Carrera 7 # 64-7, Bogota', '2026-09-14 07:49:00', 'Recibe jefe de cocina', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 14/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260912121643000'), 2, 'Calle 131 # 100-33, Bogota', '2026-09-14 08:35:00', 'Recibe el administrador', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Engativa 15/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914124855000'), 1, 'Calle 57 # 6-33, Bogota', '2026-09-15 06:43:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Engativa 15/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914151600000'), 2, 'Calle 67 # 108-9, Bogota', '2026-09-15 08:07:00', 'Recibe el propietario', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen 15/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260912141537000'), 1, 'Calle 28 Sur # 68-45, Bogota', '2026-09-15 07:28:00', 'Recibe cajera de turno', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Usaquen 15/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914105916000'), 2, 'Carrera 8 # 146-68, Bogota', '2026-09-15 08:44:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Suba 16/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260914164433000'), 1, 'Carrera 18 # 10-94, Soacha', '2026-09-16 06:55:00', 'Recibe el propietario', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Suba 16/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260915151810000'), 2, 'Carrera 91 # 135-89, Bogota', '2026-09-16 07:46:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Kennedy 17/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916094235000'), 1, 'Calle 68 # 104-31, Bogota', '2026-09-17 07:04:00', 'Recibe cajera de turno', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Kennedy 17/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916102049000'), 2, 'Calle 28 Sur # 75-29, Bogota', '2026-09-17 07:59:00', 'Recibe el propietario', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Engativa 18/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260916144447000'), 1, 'Calle 5 # 5-38, Cajica', '2026-09-18 07:41:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Engativa 18/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260917095234000'), 2, 'Calle 75 # 83-11, Bogota', '2026-09-18 08:29:00', 'Recibe el propietario', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo 19/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260917160714000'), 1, 'Calle 34 # 25-74, Bogota', '2026-09-19 07:06:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo 19/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918133913000'), 2, 'Calle 49 # 24-69, Bogota', '2026-09-19 08:29:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Kennedy 21/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260918143232000'), 1, 'Calle 154 # 82-95, Bogota', '2026-09-21 07:20:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Kennedy 21/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919101335000'), 2, 'Calle 28 Sur # 68-45, Bogota', '2026-09-21 08:41:00', 'Recibe el administrador', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Usaquen 21/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919102443000'), 1, 'Calle 60 # 15-85, Bogota', '2026-09-21 07:46:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Usaquen 21/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260919132958000'), 2, 'Carrera 9 # 118-37, Bogota', '2026-09-21 08:59:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Puente Aranda - Engativa 22/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260921091208000'), 1, 'Calle 18 # 37-44, Bogota', '2026-09-22 07:46:00', 'Recibe jefe de cocina', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Puente Aranda - Engativa 22/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260921102039000'), 2, 'Calle 67 # 108-9, Bogota', '2026-09-22 09:13:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Occidente 23/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922122639000'), 1, 'Carrera 81 # 45-82 Sur, Bogota', '2026-09-23 07:06:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Occidente 23/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922130636000'), 2, 'Carrera 12 # 18-47, Funza', '2026-09-23 07:51:00', 'Recibe el propietario', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 23/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922095644000'), 1, 'Calle 131 # 100-33, Bogota', '2026-09-23 07:11:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Usaquen 23/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260922105343000'), 2, 'Carrera 9 # 142-5, Bogota', '2026-09-23 08:00:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Norte 24/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260923081418000'), 1, 'Carrera 8 # 146-68, Bogota', '2026-09-24 06:50:00', 'Recibe el propietario', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Norte 24/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260923151536000'), 2, 'Calle 18 # 8-16, Chia', '2026-09-24 07:55:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Soacha 28/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260924140203000'), 1, 'Calle 20 # 105-34, Bogota', '2026-09-28 07:26:00', 'Recibe el administrador', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Soacha 28/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926085210000'), 2, 'Carrera 18 # 10-94, Soacha', '2026-09-28 08:02:00', 'Recibe cajera de turno', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Kennedy 28/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926110012000'), 1, 'Calle 17 # 98-24, Bogota', '2026-09-28 07:39:00', 'Recibe cajera de turno', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Kennedy 28/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926133856000'), 2, 'Calle 28 Sur # 68-45, Bogota', '2026-09-28 09:05:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Teusaquillo 28/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926154016000'), 1, 'Carrera 9 # 142-5, Bogota', '2026-09-28 07:50:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Teusaquillo 28/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926155802000'), 2, 'Calle 46 # 25-52, Bogota', '2026-09-28 08:50:00', 'Recibe jefe de cocina', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Chapinero 29/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260926164131000'), 1, 'Calle 17 # 98-24, Bogota', '2026-09-29 07:16:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Chapinero 29/09/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260928115841000'), 2, 'Calle 57 # 6-33, Bogota', '2026-09-29 08:08:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Occidente 01/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260928122243000'), 1, 'Carrera 9 # 142-5, Bogota', '2026-10-01 08:03:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Sabana Occidente 01/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260930091515000'), 2, 'Carrera 12 # 18-47, Funza', '2026-10-01 08:51:00', 'Recibe el administrador', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero 02/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20260930112904000'), 1, 'Calle 57 # 6-33, Bogota', '2026-10-02 07:19:00', 'Recibe cajera de turno', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero 02/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001124951000'), 2, 'Calle 54 # 15-39, Bogota', '2026-10-02 08:38:00', 'Recibe el administrador', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Sabana Norte 02/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001145245000'), 1, 'Calle 75 # 83-11, Bogota', '2026-10-02 07:34:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Sabana Norte 02/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261001161647000'), 2, 'Calle 18 # 8-16, Chia', '2026-10-02 08:26:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa 06/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261003145725000'), 1, 'Carrera 73 # 64-35, Bogota', '2026-10-06 06:43:00', 'Recibe el administrador', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa 06/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261005090611000'), 2, 'Calle 80 # 82-42, Bogota', '2026-10-06 07:41:00', 'Recibe auxiliar de bodega', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Suba 07/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261005125509000'), 1, 'Calle 141 # 9-32, Bogota', '2026-10-07 08:10:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Suba 07/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261006132250000'), 2, 'Calle 154 # 82-95, Bogota', '2026-10-07 08:58:00', 'Recibe auxiliar de bodega', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Norte 09/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261007091839000'), 1, 'Carrera 75 # 46-12 Sur, Bogota', '2026-10-09 07:13:00', 'Recibe cajera de turno', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Kennedy - Sabana Norte 09/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008083520000'), 2, 'Calle 5 # 5-38, Cajica', '2026-10-09 08:04:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Puente Aranda 09/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008084053000'), 1, 'Carrera 91 # 135-89, Bogota', '2026-10-09 06:44:00', 'Recibe auxiliar de bodega', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Suba - Puente Aranda 09/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008091631000'), 2, 'Calle 10 # 36-55, Bogota', '2026-10-09 07:43:00', 'Recibe cajera de turno', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 10/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261008130039000'), 1, 'Carrera 16 # 15-55, Funza', '2026-10-10 06:59:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 10/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009092500000'), 2, 'Carrera 110 # 16-57, Bogota', '2026-10-10 07:44:00', 'Recibe jefe de cocina', 'Cliente pide llegar antes de las 10'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Puente Aranda 10/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009122601000'), 1, 'Calle 80 # 82-42, Bogota', '2026-10-10 07:09:00', 'Recibe cajera de turno', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Engativa - Puente Aranda 10/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009134113000'), 2, 'Calle 18 # 37-44, Bogota', '2026-10-10 08:16:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Fontibon 12/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261009150958000'), 1, 'Carrera 18 # 142-27, Bogota', '2026-10-12 07:04:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Fontibon 12/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010082538000'), 2, 'Carrera 110 # 16-57, Bogota', '2026-10-12 08:11:00', 'Recibe cajera de turno', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Fontibon 12/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010110304000'), 1, 'Calle 46 # 25-52, Bogota', '2026-10-12 07:21:00', 'Recibe auxiliar de bodega', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Fontibon 12/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010125643000'), 2, 'Calle 17 # 98-24, Bogota', '2026-10-12 08:21:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Teusaquillo 14/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261010164748000'), 1, 'Carrera 7 # 64-7, Bogota', '2026-10-14 07:29:00', 'Recibe jefe de cocina', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Teusaquillo 14/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013101837000'), 2, 'Carrera 30 # 36-65, Bogota', '2026-10-14 08:06:00', 'Recibe el administrador', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Usaquen 14/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013125226000'), 1, 'Carrera 18 # 35-51, Bogota', '2026-10-14 07:45:00', 'Recibe auxiliar de bodega', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Teusaquillo - Usaquen 14/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261013163958000'), 2, 'Carrera 18 # 142-27, Bogota', '2026-10-14 08:58:00', 'Recibe el administrador', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Engativa 15/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261014112401000'), 1, 'Carrera 8 # 146-68, Bogota', '2026-10-15 07:35:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Usaquen - Engativa 15/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261014150111000'), 2, 'Calle 80 # 82-42, Bogota', '2026-10-15 08:59:00', 'Recibe cajera de turno', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Chapinero 17/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261016112536000'), 1, 'Calle 20 # 17-95, Soacha', '2026-10-17 07:36:00', 'Recibe auxiliar de bodega', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Chapinero 17/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261016132250000'), 2, 'Calle 46 # 11-22, Bogota', '2026-10-17 08:48:00', 'Recibe el propietario', 'Entrega sin novedad'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Engativa 19/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261017092510000'), 1, 'Calle 17 # 98-24, Bogota', '2026-10-19 06:40:00', 'Recibe el propietario', NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Engativa 19/10/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261017132202000'), 2, 'Calle 80 # 82-42, Bogota', '2026-10-19 07:40:00', 'Recibe cajera de turno', 'Se entrego por la puerta de servicio'),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Suba 02/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261019112437000'), 1, 'Calle 22 # 96-65, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Suba 02/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261020082334000'), 2, 'Calle 20 # 105-34, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Fontibon - Suba 02/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261021164505000'), 3, 'Calle 138 # 112-32, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 02/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261022105400000'), 1, 'Carrera 11 # 66-50, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 02/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261022111512000'), 2, 'Carrera 11 # 66-50, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Chapinero - Suba 02/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261023105852000'), 3, 'Calle 138 # 112-32, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Suba 03/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261024124600000'), 1, 'Carrera 8 # 8-76, Chia', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Norte - Suba 03/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261026121127000'), 2, 'Carrera 91 # 135-89, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Kennedy 03/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027083325000'), 1, 'Calle 27 # 16-59, Soacha', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Soacha - Kennedy 03/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027111232000'), 2, 'Calle 28 Sur # 68-45, Bogota', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 04/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027112414000'), 1, 'Carrera 12 # 18-47, Funza', NULL, NULL, NULL),
((SELECT id_ruta FROM rutas_entrega WHERE nombre_ruta = 'Ruta Sabana Occidente - Fontibon 04/11/2026'), (SELECT id_venta FROM ventas WHERE numero_venta = 'V-20261027134135000'), 2, 'Carrera 107 # 18-18, Bogota', NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE orden_entrega = orden_entrega;

-- SECCION 3: Consultas para revisar los datos (solo lectura)
-- Registros por tabla
SELECT 'proveedores' AS tabla, COUNT(*) AS registros FROM proveedores
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'productos_proveedor', COUNT(*) FROM productos_proveedor
UNION ALL SELECT 'lotes_inventario', COUNT(*) FROM lotes_inventario
UNION ALL SELECT 'registro_cuarentena', COUNT(*) FROM registro_cuarentena
UNION ALL SELECT 'inspecciones_calidad', COUNT(*) FROM inspecciones_calidad
UNION ALL SELECT 'registro_mermas', COUNT(*) FROM registro_mermas
UNION ALL SELECT 'promociones', COUNT(*) FROM promociones
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'ventas', COUNT(*) FROM ventas
UNION ALL SELECT 'detalles_venta', COUNT(*) FROM detalles_venta
UNION ALL SELECT 'facturas', COUNT(*) FROM facturas
UNION ALL SELECT 'vehiculos', COUNT(*) FROM vehiculos
UNION ALL SELECT 'conductores', COUNT(*) FROM conductores
UNION ALL SELECT 'rutas_entrega', COUNT(*) FROM rutas_entrega
UNION ALL SELECT 'asignaciones_entrega', COUNT(*) FROM asignaciones_entrega
UNION ALL SELECT 'ventas_ruta', COUNT(*) FROM ventas_ruta;

-- Debe devolver 0 filas: ventas sin detalle o con totales distintos a la suma de sus detalles
SELECT v.numero_venta, v.subtotal, v.total_descuento, v.total_impuesto, v.monto_total,
       SUM(d.subtotal) AS suma_subtotal, SUM(d.monto_descuento) AS suma_descuento,
       SUM(d.monto_impuesto) AS suma_impuesto, SUM(d.total_linea) AS suma_total
FROM ventas v
LEFT JOIN detalles_venta d ON d.id_venta = v.id_venta
GROUP BY v.id_venta, v.numero_venta, v.subtotal, v.total_descuento, v.total_impuesto, v.monto_total
HAVING COUNT(d.id_detalle) = 0
    OR v.subtotal <> SUM(d.subtotal)
    OR v.total_descuento <> SUM(d.monto_descuento)
    OR v.total_impuesto <> SUM(d.monto_impuesto)
    OR v.monto_total <> SUM(d.total_linea);

-- Debe devolver 0 filas: lotes cuya cantidad no cuadra con lo vendido y las mermas
SELECT l.numero_lote, l.cantidad_inicial, l.cantidad, x.vendido, y.merma
FROM lotes_inventario l
LEFT JOIN (SELECT d.id_lote, SUM(d.cantidad_vendida) AS vendido
           FROM detalles_venta d JOIN ventas v ON v.id_venta = d.id_venta
           JOIN estados_venta e ON e.id_estado = v.id_estado
           WHERE e.nombre <> 'Cancelada' GROUP BY d.id_lote) x ON x.id_lote = l.id_lote
LEFT JOIN (SELECT id_lote, SUM(cantidad_perdida) AS merma FROM registro_mermas GROUP BY id_lote) y ON y.id_lote = l.id_lote
WHERE l.cantidad < 0
   OR l.cantidad <> l.cantidad_inicial - COALESCE(x.vendido, 0) - COALESCE(y.merma, 0);

-- Debe devolver 0 filas: facturas con totales distintos a los de su venta
SELECT f.numero_factura, v.numero_venta
FROM facturas f JOIN ventas v ON v.id_venta = f.id_venta
WHERE f.subtotal <> v.subtotal OR f.total_descuento <> v.total_descuento
   OR f.monto_impuesto <> v.total_impuesto OR f.monto_total <> v.monto_total;

-- Debe devolver 0 filas: lotes cuyo proveedor no tiene ese producto en productos_proveedor
SELECT l.numero_lote
FROM lotes_inventario l
LEFT JOIN productos_proveedor pp ON pp.id_proveedor = l.id_proveedor AND pp.id_producto = l.id_producto
WHERE pp.id_proveedor IS NULL;

-- Proveedor 33
SELECT id_proveedor, nombre, nit FROM proveedores WHERE id_proveedor = 33;
