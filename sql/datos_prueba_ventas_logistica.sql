-- Datos de prueba: clientes, ventas, detalles de venta, vehiculos, conductores, rutas y asignaciones.
-- Datos ficticios. NO crea ni borra la base: ejecutar sobre erp_frescura_total ya creada con el script del proyecto.
--
-- ORDEN DE CARGA (dependencias entre modulos):
--   1. Script del proyecto (esquema y catalogos).
--   2. SQL de productos y lotes del modulo de Inventario (de su companero). Este script NO crea productos,
--      proveedores ni lotes: los detalles de venta usan los lotes que ya existan en lotes_inventario.
--   3. Este script. Si no hay lotes, se detiene al inicio con un error y no inserta nada.
--
-- Proveedor ID 33: para estos datos de prueba se espera que el proveedor 33 tenga el NIT ficticio 985731642-9
-- (dato inventado solo para pruebas; no es un NIT registrado ni asignado por la DIAN). Este script no crea ni
-- modifica proveedores: lo carga el modulo de Proveedores/Inventario. Al final se muestra si coincide.
--
-- Se puede ejecutar mas de una vez sin duplicar datos. Cada registro se identifica por una clave propia, nunca
-- por un id autogenerado: documento, numero_venta, placa, numero_licencia y, en las rutas, el codigo
-- 'RT-TEST-nn' en nombre_ruta junto con usuario_creacion = 'datos_prueba'.
-- Requiere el cliente mysql o Workbench (usa DELIMITER para el procedimiento temporal de la comprobacion).
USE erp_frescura_total;

-- 0. COMPROBACION: sin lotes no se crean ventas incompletas.
DROP PROCEDURE IF EXISTS sp_verificar_lotes_prueba;
DELIMITER $$
CREATE PROCEDURE sp_verificar_lotes_prueba()
BEGIN
  IF (SELECT COUNT(*) FROM lotes_inventario) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
      'Faltan lotes: cargue primero el SQL de productos y lotes de Inventario y ejecute de nuevo este script.';
  END IF;
END$$
DELIMITER ;
CALL sp_verificar_lotes_prueba();
DROP PROCEDURE sp_verificar_lotes_prueba;

-- 1. CLIENTES (50)
INSERT IGNORE INTO clientes (nombre, documento, email, telefono, direccion, id_tipo) VALUES
('Camila Rojas', '1000000001', 'cliente01@correo-prueba.com', '3000000001', 'Calle 11 # 2-21, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Andres Rojas', '1000000002', 'cliente02@correo-prueba.com', '3000000002', 'Calle 12 # 3-22, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Valentina Rojas', '1000000003', 'cliente03@correo-prueba.com', '3000000003', 'Calle 13 # 4-23, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Santiago Rojas', '1000000004', 'cliente04@correo-prueba.com', '3000000004', 'Calle 14 # 5-24, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Tienda Mejia 5', '1000000005', 'cliente05@correo-prueba.com', '3000000005', 'Calle 15 # 6-25, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Mateo Rojas', '1000000006', 'cliente06@correo-prueba.com', '3000000006', 'Calle 16 # 7-26, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Daniela Rojas', '1000000007', 'cliente07@correo-prueba.com', '3000000007', 'Calle 17 # 8-27, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Juan Rojas', '1000000008', 'cliente08@correo-prueba.com', '3000000008', 'Calle 18 # 9-28, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Sofia Rojas', '1000000009', 'cliente09@correo-prueba.com', '3000000009', 'Calle 19 # 1-29, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Tienda Mejia 10', '1000000010', 'cliente10@correo-prueba.com', '3000000010', 'Calle 20 # 2-30, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Camila Gomez', '1000000011', 'cliente11@correo-prueba.com', '3000000011', 'Calle 21 # 3-31, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Andres Gomez', '1000000012', 'cliente12@correo-prueba.com', '3000000012', 'Calle 22 # 4-32, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Valentina Gomez', '1000000013', 'cliente13@correo-prueba.com', '3000000013', 'Calle 23 # 5-33, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Santiago Gomez', '1000000014', 'cliente14@correo-prueba.com', '3000000014', 'Calle 24 # 6-34, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Minimercado Mejia 15', '1000000015', 'cliente15@correo-prueba.com', '3000000015', 'Calle 25 # 7-35, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Mateo Gomez', '1000000016', 'cliente16@correo-prueba.com', '3000000016', 'Calle 26 # 8-36, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Daniela Gomez', '1000000017', 'cliente17@correo-prueba.com', '3000000017', 'Calle 27 # 9-37, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Juan Gomez', '1000000018', 'cliente18@correo-prueba.com', '3000000018', 'Calle 28 # 1-38, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Sofia Gomez', '1000000019', 'cliente19@correo-prueba.com', '3000000019', 'Calle 29 # 2-39, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Minimercado Mejia 20', '1000000020', 'cliente20@correo-prueba.com', '3000000020', 'Calle 30 # 3-40, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Camila Pardo', '1000000021', 'cliente21@correo-prueba.com', '3000000021', 'Calle 31 # 4-41, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Andres Pardo', '1000000022', 'cliente22@correo-prueba.com', '3000000022', 'Calle 32 # 5-42, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Valentina Pardo', '1000000023', 'cliente23@correo-prueba.com', '3000000023', 'Calle 33 # 6-43, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Santiago Pardo', '1000000024', 'cliente24@correo-prueba.com', '3000000024', 'Calle 34 # 7-44, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Restaurante Mejia 25', '1000000025', 'cliente25@correo-prueba.com', '3000000025', 'Calle 35 # 8-45, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Mateo Pardo', '1000000026', 'cliente26@correo-prueba.com', '3000000026', 'Calle 36 # 9-46, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Daniela Pardo', '1000000027', 'cliente27@correo-prueba.com', '3000000027', 'Calle 37 # 1-47, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Juan Pardo', '1000000028', 'cliente28@correo-prueba.com', '3000000028', 'Calle 38 # 2-48, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Sofia Pardo', '1000000029', 'cliente29@correo-prueba.com', '3000000029', 'Calle 39 # 3-49, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Restaurante Mejia 30', '1000000030', 'cliente30@correo-prueba.com', '3000000030', 'Calle 40 # 4-50, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Camila Cardenas', '1000000031', 'cliente31@correo-prueba.com', '3000000031', 'Calle 41 # 5-51, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Andres Cardenas', '1000000032', 'cliente32@correo-prueba.com', '3000000032', 'Calle 42 # 6-52, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Valentina Cardenas', '1000000033', 'cliente33@correo-prueba.com', '3000000033', 'Calle 43 # 7-53, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Santiago Cardenas', '1000000034', 'cliente34@correo-prueba.com', '3000000034', 'Calle 44 # 8-54, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Cafeteria Mejia 35', '1000000035', 'cliente35@correo-prueba.com', '3000000035', 'Calle 45 # 9-55, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Mateo Cardenas', '1000000036', 'cliente36@correo-prueba.com', '3000000036', 'Calle 46 # 1-56, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Daniela Cardenas', '1000000037', 'cliente37@correo-prueba.com', '3000000037', 'Calle 47 # 2-57, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Juan Cardenas', '1000000038', 'cliente38@correo-prueba.com', '3000000038', 'Calle 48 # 3-58, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Sofia Cardenas', '1000000039', 'cliente39@correo-prueba.com', '3000000039', 'Calle 49 # 4-59, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Cafeteria Mejia 40', '1000000040', 'cliente40@correo-prueba.com', '3000000040', 'Calle 50 # 5-60, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Camila Mejia', '1000000041', 'cliente41@correo-prueba.com', '3000000041', 'Calle 51 # 6-61, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Andres Mejia', '1000000042', 'cliente42@correo-prueba.com', '3000000042', 'Calle 52 # 7-62, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Valentina Mejia', '1000000043', 'cliente43@correo-prueba.com', '3000000043', 'Calle 53 # 8-63, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Santiago Mejia', '1000000044', 'cliente44@correo-prueba.com', '3000000044', 'Calle 54 # 9-64, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Supermercado Mejia 45', '1000000045', 'cliente45@correo-prueba.com', '3000000045', 'Calle 55 # 1-65, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista')),
('Mateo Mejia', '1000000046', 'cliente46@correo-prueba.com', '3000000046', 'Calle 56 # 2-66, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Daniela Mejia', '1000000047', 'cliente47@correo-prueba.com', '3000000047', 'Calle 57 # 3-67, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Juan Mejia', '1000000048', 'cliente48@correo-prueba.com', '3000000048', 'Calle 58 # 4-68, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Sofia Mejia', '1000000049', 'cliente49@correo-prueba.com', '3000000049', 'Calle 59 # 5-69, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Minorista')),
('Supermercado Mejia 50', '1000000050', 'cliente50@correo-prueba.com', '3000000050', 'Calle 60 # 6-70, Bogota', (SELECT id_tipo FROM tipos_cliente WHERE nombre = 'Mayorista'));

-- 2. VENTAS (50). Los totales reales se calculan en el paso 4 a partir de los detalles.
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-001', c.id_cliente, '2026-09-01 09:01:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000001' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-002', c.id_cliente, '2026-09-02 10:02:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000002' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-003', c.id_cliente, '2026-09-03 11:03:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000003' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-004', c.id_cliente, '2026-09-04 12:04:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000004' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-005', c.id_cliente, '2026-09-05 13:05:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000005' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-006', c.id_cliente, '2026-09-06 14:06:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000006' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-007', c.id_cliente, '2026-09-07 15:07:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000007' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-008', c.id_cliente, '2026-09-08 16:08:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000008' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-009', c.id_cliente, '2026-09-09 17:09:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000009' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-010', c.id_cliente, '2026-09-10 08:10:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000010' AND e.nombre = 'Entregada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-011', c.id_cliente, '2026-09-11 09:11:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000011' AND e.nombre = 'En Transito';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-012', c.id_cliente, '2026-09-12 10:12:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000012' AND e.nombre = 'En Transito';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-013', c.id_cliente, '2026-09-13 11:13:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000013' AND e.nombre = 'En Transito';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-014', c.id_cliente, '2026-09-14 12:14:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000014' AND e.nombre = 'En Transito';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-015', c.id_cliente, '2026-09-15 13:15:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000015' AND e.nombre = 'En Transito';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-016', c.id_cliente, '2026-09-16 14:16:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000016' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-017', c.id_cliente, '2026-09-17 15:17:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000017' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-018', c.id_cliente, '2026-09-18 16:18:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000018' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-019', c.id_cliente, '2026-09-19 17:19:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000019' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-020', c.id_cliente, '2026-09-20 08:20:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000020' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-021', c.id_cliente, '2026-09-21 09:21:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000021' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-022', c.id_cliente, '2026-09-22 10:22:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000022' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-023', c.id_cliente, '2026-09-23 11:23:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000023' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-024', c.id_cliente, '2026-09-24 12:24:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000024' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-025', c.id_cliente, '2026-09-25 13:25:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000025' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-026', c.id_cliente, '2026-09-26 14:26:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000026' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-027', c.id_cliente, '2026-09-27 15:27:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000027' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-028', c.id_cliente, '2026-09-28 16:28:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000028' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-029', c.id_cliente, '2026-09-01 17:29:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000029' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-030', c.id_cliente, '2026-09-02 08:30:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000030' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-031', c.id_cliente, '2026-09-03 09:31:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000031' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-032', c.id_cliente, '2026-09-04 10:32:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000032' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-033', c.id_cliente, '2026-09-05 11:33:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000033' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-034', c.id_cliente, '2026-09-06 12:34:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000034' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-035', c.id_cliente, '2026-09-07 13:35:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000035' AND e.nombre = 'En Preparacion';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-036', c.id_cliente, '2026-09-08 14:36:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000036' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-037', c.id_cliente, '2026-09-09 15:37:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000037' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-038', c.id_cliente, '2026-09-10 16:38:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000038' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-039', c.id_cliente, '2026-09-11 17:39:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000039' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-040', c.id_cliente, '2026-09-12 08:40:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000040' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-041', c.id_cliente, '2026-09-13 09:41:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000041' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-042', c.id_cliente, '2026-09-14 10:42:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000042' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-043', c.id_cliente, '2026-09-15 11:43:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000043' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-044', c.id_cliente, '2026-09-16 12:44:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000044' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-045', c.id_cliente, '2026-09-17 13:45:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000045' AND e.nombre = 'Registrada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-046', c.id_cliente, '2026-09-18 14:46:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000046' AND e.nombre = 'Cancelada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-047', c.id_cliente, '2026-09-19 15:47:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000047' AND e.nombre = 'Cancelada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-048', c.id_cliente, '2026-09-20 16:48:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000048' AND e.nombre = 'Cancelada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-049', c.id_cliente, '2026-09-21 17:49:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000049' AND e.nombre = 'Cancelada';
INSERT IGNORE INTO ventas (numero_venta, id_cliente, fecha_venta, subtotal, total_descuento, total_impuesto, monto_total, id_estado, usuario_registro)
SELECT 'V-TEST-050', c.id_cliente, '2026-09-22 08:50:00', 0, 0, 0, 0, e.id_estado, 'datos_prueba'
FROM clientes c, estados_venta e WHERE c.documento = '1000000050' AND e.nombre = 'Cancelada';

-- 3. DETALLES DE VENTA: cada venta de prueba toma un lote existente (se reparten en circulo entre
-- los lotes de lotes_inventario) y su precio_venta. Sin descuento ni impuesto.
-- Linea 1: las 50 ventas.
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT v.id_venta, l.id_lote, (CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) % 5) + 1, l.precio_venta, 0, 0, 0, 0, ROUND((CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) % 5) + 1 * l.precio_venta, 2), ROUND((CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) % 5) + 1 * l.precio_venta, 2)
FROM ventas v JOIN (SELECT id_lote, precio_venta, ROW_NUMBER() OVER (ORDER BY id_lote) AS n, COUNT(*) OVER () AS total FROM lotes_inventario) l ON l.n = ((CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) - 1 + 0) % l.total) + 1
WHERE v.numero_venta LIKE 'V-TEST-%' AND 1 = 1
AND NOT EXISTS (SELECT 1 FROM detalles_venta d WHERE d.id_venta = v.id_venta AND d.id_lote = l.id_lote);
-- Linea 2: las ventas 1 a 25 llevan un segundo producto.
INSERT INTO detalles_venta (id_venta, id_lote, cantidad_vendida, precio_unitario, descuento_aplicado, monto_descuento, tasa_impuesto, monto_impuesto, subtotal, total_linea)
SELECT v.id_venta, l.id_lote, (CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) % 3) + 1, l.precio_venta, 0, 0, 0, 0, ROUND((CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) % 3) + 1 * l.precio_venta, 2), ROUND((CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) % 3) + 1 * l.precio_venta, 2)
FROM ventas v JOIN (SELECT id_lote, precio_venta, ROW_NUMBER() OVER (ORDER BY id_lote) AS n, COUNT(*) OVER () AS total FROM lotes_inventario) l ON l.n = ((CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) - 1 + 7) % l.total) + 1
WHERE v.numero_venta LIKE 'V-TEST-%' AND CAST(SUBSTRING(v.numero_venta, 8) AS UNSIGNED) <= 25
AND NOT EXISTS (SELECT 1 FROM detalles_venta d WHERE d.id_venta = v.id_venta AND d.id_lote = l.id_lote);

-- 4. TOTALES de cada venta de prueba = suma de sus detalles (asi ventas y detalles son coherentes).
UPDATE ventas v
SET v.subtotal = (SELECT COALESCE(SUM(d.subtotal), 0) FROM detalles_venta d WHERE d.id_venta = v.id_venta),
    v.monto_total = (SELECT COALESCE(SUM(d.total_linea), 0) FROM detalles_venta d WHERE d.id_venta = v.id_venta)
WHERE v.numero_venta LIKE 'V-TEST-%';

-- 5. VEHICULOS (50). 41 a 45 en Mantenimiento y 46 a 50 Inactivos, para probar la validacion de vehiculos no activos.
INSERT IGNORE INTO vehiculos (placa, modelo, capacidad, estado) VALUES
('TST001', 'Hino 300 2019', 1250.00, 'Activo'),
('TST002', 'Isuzu NKR 2020', 1500.00, 'Activo'),
('TST003', 'Foton Aumark 2021', 1750.00, 'Activo'),
('TST004', 'JAC X250 2022', 2000.00, 'Activo'),
('TST005', 'Chevrolet NHR 2023', 2250.00, 'Activo'),
('TST006', 'Hino 300 2024', 2500.00, 'Activo'),
('TST007', 'Isuzu NKR 2025', 2750.00, 'Activo'),
('TST008', 'Foton Aumark 2018', 3000.00, 'Activo'),
('TST009', 'JAC X250 2019', 3250.00, 'Activo'),
('TST010', 'Chevrolet NHR 2020', 1000.00, 'Activo'),
('TST011', 'Hino 300 2021', 1250.00, 'Activo'),
('TST012', 'Isuzu NKR 2022', 1500.00, 'Activo'),
('TST013', 'Foton Aumark 2023', 1750.00, 'Activo'),
('TST014', 'JAC X250 2024', 2000.00, 'Activo'),
('TST015', 'Chevrolet NHR 2025', 2250.00, 'Activo'),
('TST016', 'Hino 300 2018', 2500.00, 'Activo'),
('TST017', 'Isuzu NKR 2019', 2750.00, 'Activo'),
('TST018', 'Foton Aumark 2020', 3000.00, 'Activo'),
('TST019', 'JAC X250 2021', 3250.00, 'Activo'),
('TST020', 'Chevrolet NHR 2022', 1000.00, 'Activo'),
('TST021', 'Hino 300 2023', 1250.00, 'Activo'),
('TST022', 'Isuzu NKR 2024', 1500.00, 'Activo'),
('TST023', 'Foton Aumark 2025', 1750.00, 'Activo'),
('TST024', 'JAC X250 2018', 2000.00, 'Activo'),
('TST025', 'Chevrolet NHR 2019', 2250.00, 'Activo'),
('TST026', 'Hino 300 2020', 2500.00, 'Activo'),
('TST027', 'Isuzu NKR 2021', 2750.00, 'Activo'),
('TST028', 'Foton Aumark 2022', 3000.00, 'Activo'),
('TST029', 'JAC X250 2023', 3250.00, 'Activo'),
('TST030', 'Chevrolet NHR 2024', 1000.00, 'Activo'),
('TST031', 'Hino 300 2025', 1250.00, 'Activo'),
('TST032', 'Isuzu NKR 2018', 1500.00, 'Activo'),
('TST033', 'Foton Aumark 2019', 1750.00, 'Activo'),
('TST034', 'JAC X250 2020', 2000.00, 'Activo'),
('TST035', 'Chevrolet NHR 2021', 2250.00, 'Activo'),
('TST036', 'Hino 300 2022', 2500.00, 'Activo'),
('TST037', 'Isuzu NKR 2023', 2750.00, 'Activo'),
('TST038', 'Foton Aumark 2024', 3000.00, 'Activo'),
('TST039', 'JAC X250 2025', 3250.00, 'Activo'),
('TST040', 'Chevrolet NHR 2018', 1000.00, 'Activo'),
('TST041', 'Hino 300 2019', 1250.00, 'Mantenimiento'),
('TST042', 'Isuzu NKR 2020', 1500.00, 'Mantenimiento'),
('TST043', 'Foton Aumark 2021', 1750.00, 'Mantenimiento'),
('TST044', 'JAC X250 2022', 2000.00, 'Mantenimiento'),
('TST045', 'Chevrolet NHR 2023', 2250.00, 'Mantenimiento'),
('TST046', 'Hino 300 2024', 2500.00, 'Inactivo'),
('TST047', 'Isuzu NKR 2025', 2750.00, 'Inactivo'),
('TST048', 'Foton Aumark 2018', 3000.00, 'Inactivo'),
('TST049', 'JAC X250 2019', 3250.00, 'Inactivo'),
('TST050', 'Chevrolet NHR 2020', 1000.00, 'Inactivo');

-- 6. CONDUCTORES (50). Del 46 al 50 estan inactivos, para probar la validacion de conductores no activos.
INSERT IGNORE INTO conductores (nombre, numero_licencia, telefono, email, activo) VALUES
('Santiago Pardo B.', 'LIC-TEST-001', '3100000001', 'conductor01@correo-prueba.com', TRUE),
('Daniela Mejia C.', 'LIC-TEST-002', '3100000002', 'conductor02@correo-prueba.com', TRUE),
('Felipe Gomez D.', 'LIC-TEST-003', '3100000003', 'conductor03@correo-prueba.com', TRUE),
('Valentina Cardenas E.', 'LIC-TEST-004', '3100000004', 'conductor04@correo-prueba.com', TRUE),
('Mateo Rojas F.', 'LIC-TEST-005', '3100000005', 'conductor05@correo-prueba.com', TRUE),
('Sofia Pardo G.', 'LIC-TEST-006', '3100000006', 'conductor06@correo-prueba.com', TRUE),
('Andres Mejia H.', 'LIC-TEST-007', '3100000007', 'conductor07@correo-prueba.com', TRUE),
('Laura Gomez I.', 'LIC-TEST-008', '3100000008', 'conductor08@correo-prueba.com', TRUE),
('Juan Cardenas J.', 'LIC-TEST-009', '3100000009', 'conductor09@correo-prueba.com', TRUE),
('Camila Rojas K.', 'LIC-TEST-010', '3100000010', 'conductor10@correo-prueba.com', TRUE),
('Santiago Pardo L.', 'LIC-TEST-011', '3100000011', 'conductor11@correo-prueba.com', TRUE),
('Daniela Mejia M.', 'LIC-TEST-012', '3100000012', 'conductor12@correo-prueba.com', TRUE),
('Felipe Gomez N.', 'LIC-TEST-013', '3100000013', 'conductor13@correo-prueba.com', TRUE),
('Valentina Cardenas O.', 'LIC-TEST-014', '3100000014', 'conductor14@correo-prueba.com', TRUE),
('Mateo Rojas P.', 'LIC-TEST-015', '3100000015', 'conductor15@correo-prueba.com', TRUE),
('Sofia Pardo Q.', 'LIC-TEST-016', '3100000016', 'conductor16@correo-prueba.com', TRUE),
('Andres Mejia R.', 'LIC-TEST-017', '3100000017', 'conductor17@correo-prueba.com', TRUE),
('Laura Gomez S.', 'LIC-TEST-018', '3100000018', 'conductor18@correo-prueba.com', TRUE),
('Juan Cardenas T.', 'LIC-TEST-019', '3100000019', 'conductor19@correo-prueba.com', TRUE),
('Camila Rojas U.', 'LIC-TEST-020', '3100000020', 'conductor20@correo-prueba.com', TRUE),
('Santiago Pardo V.', 'LIC-TEST-021', '3100000021', 'conductor21@correo-prueba.com', TRUE),
('Daniela Mejia W.', 'LIC-TEST-022', '3100000022', 'conductor22@correo-prueba.com', TRUE),
('Felipe Gomez X.', 'LIC-TEST-023', '3100000023', 'conductor23@correo-prueba.com', TRUE),
('Valentina Cardenas Y.', 'LIC-TEST-024', '3100000024', 'conductor24@correo-prueba.com', TRUE),
('Mateo Rojas Z.', 'LIC-TEST-025', '3100000025', 'conductor25@correo-prueba.com', TRUE),
('Sofia Pardo A.', 'LIC-TEST-026', '3100000026', 'conductor26@correo-prueba.com', TRUE),
('Andres Mejia B.', 'LIC-TEST-027', '3100000027', 'conductor27@correo-prueba.com', TRUE),
('Laura Gomez C.', 'LIC-TEST-028', '3100000028', 'conductor28@correo-prueba.com', TRUE),
('Juan Cardenas D.', 'LIC-TEST-029', '3100000029', 'conductor29@correo-prueba.com', TRUE),
('Camila Rojas E.', 'LIC-TEST-030', '3100000030', 'conductor30@correo-prueba.com', TRUE),
('Santiago Pardo F.', 'LIC-TEST-031', '3100000031', 'conductor31@correo-prueba.com', TRUE),
('Daniela Mejia G.', 'LIC-TEST-032', '3100000032', 'conductor32@correo-prueba.com', TRUE),
('Felipe Gomez H.', 'LIC-TEST-033', '3100000033', 'conductor33@correo-prueba.com', TRUE),
('Valentina Cardenas I.', 'LIC-TEST-034', '3100000034', 'conductor34@correo-prueba.com', TRUE),
('Mateo Rojas J.', 'LIC-TEST-035', '3100000035', 'conductor35@correo-prueba.com', TRUE),
('Sofia Pardo K.', 'LIC-TEST-036', '3100000036', 'conductor36@correo-prueba.com', TRUE),
('Andres Mejia L.', 'LIC-TEST-037', '3100000037', 'conductor37@correo-prueba.com', TRUE),
('Laura Gomez M.', 'LIC-TEST-038', '3100000038', 'conductor38@correo-prueba.com', TRUE),
('Juan Cardenas N.', 'LIC-TEST-039', '3100000039', 'conductor39@correo-prueba.com', TRUE),
('Camila Rojas O.', 'LIC-TEST-040', '3100000040', 'conductor40@correo-prueba.com', TRUE),
('Santiago Pardo P.', 'LIC-TEST-041', '3100000041', 'conductor41@correo-prueba.com', TRUE),
('Daniela Mejia Q.', 'LIC-TEST-042', '3100000042', 'conductor42@correo-prueba.com', TRUE),
('Felipe Gomez R.', 'LIC-TEST-043', '3100000043', 'conductor43@correo-prueba.com', TRUE),
('Valentina Cardenas S.', 'LIC-TEST-044', '3100000044', 'conductor44@correo-prueba.com', TRUE),
('Mateo Rojas T.', 'LIC-TEST-045', '3100000045', 'conductor45@correo-prueba.com', TRUE),
('Sofia Pardo U.', 'LIC-TEST-046', '3100000046', 'conductor46@correo-prueba.com', FALSE),
('Andres Mejia V.', 'LIC-TEST-047', '3100000047', 'conductor47@correo-prueba.com', FALSE),
('Laura Gomez W.', 'LIC-TEST-048', '3100000048', 'conductor48@correo-prueba.com', FALSE),
('Juan Cardenas X.', 'LIC-TEST-049', '3100000049', 'conductor49@correo-prueba.com', FALSE),
('Camila Rojas Y.', 'LIC-TEST-050', '3100000050', 'conductor50@correo-prueba.com', FALSE);

-- 7. RUTAS (50). Rutas 1-5 Completada, 6-7 En Transito, 8-9 Planificada con vehiculo, conductor y ventas,
-- 10-48 Planificada vacias (sirven para practicar las asignaciones), 49-50 Cancelada.
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-01 Sur', 'datos_prueba', '2026-09-01 07:00:00', '2026-09-01 15:00:00', '2026-09-01 07:00:00', '2026-09-01 14:30:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-01 Sur' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-02 Occidente', 'datos_prueba', '2026-09-02 07:00:00', '2026-09-02 15:00:00', '2026-09-02 07:00:00', '2026-09-02 14:30:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-02 Occidente' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-03 Centro', 'datos_prueba', '2026-09-03 07:00:00', '2026-09-03 15:00:00', '2026-09-03 07:00:00', '2026-09-03 14:30:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-03 Centro' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-04 Chapinero', 'datos_prueba', '2026-09-04 07:00:00', '2026-09-04 15:00:00', '2026-09-04 07:00:00', '2026-09-04 14:30:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-04 Chapinero' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-05 Kennedy', 'datos_prueba', '2026-09-05 07:00:00', '2026-09-05 15:00:00', '2026-09-05 07:00:00', '2026-09-05 14:30:00', 'Completada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-05 Kennedy' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-06 Suba', 'datos_prueba', '2026-09-06 07:00:00', '2026-09-06 15:00:00', '2026-09-06 07:00:00', NULL, 'En Transito'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-06 Suba' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-07 Fontibon', 'datos_prueba', '2026-09-07 07:00:00', '2026-09-07 15:00:00', '2026-09-07 07:00:00', NULL, 'En Transito'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-07 Fontibon' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-08 Engativa', 'datos_prueba', '2026-09-08 07:00:00', '2026-09-08 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-08 Engativa' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-09 Usaquen', 'datos_prueba', '2026-09-09 07:00:00', '2026-09-09 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-09 Usaquen' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-10 Norte', 'datos_prueba', '2026-09-10 07:00:00', '2026-09-10 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-10 Norte' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-11 Sur', 'datos_prueba', '2026-09-11 07:00:00', '2026-09-11 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-11 Sur' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-12 Occidente', 'datos_prueba', '2026-09-12 07:00:00', '2026-09-12 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-12 Occidente' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-13 Centro', 'datos_prueba', '2026-09-13 07:00:00', '2026-09-13 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-13 Centro' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-14 Chapinero', 'datos_prueba', '2026-09-14 07:00:00', '2026-09-14 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-14 Chapinero' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-15 Kennedy', 'datos_prueba', '2026-09-15 07:00:00', '2026-09-15 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-15 Kennedy' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-16 Suba', 'datos_prueba', '2026-09-16 07:00:00', '2026-09-16 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-16 Suba' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-17 Fontibon', 'datos_prueba', '2026-09-17 07:00:00', '2026-09-17 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-17 Fontibon' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-18 Engativa', 'datos_prueba', '2026-09-18 07:00:00', '2026-09-18 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-18 Engativa' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-19 Usaquen', 'datos_prueba', '2026-09-19 07:00:00', '2026-09-19 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-19 Usaquen' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-20 Norte', 'datos_prueba', '2026-09-20 07:00:00', '2026-09-20 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-20 Norte' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-21 Sur', 'datos_prueba', '2026-09-21 07:00:00', '2026-09-21 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-21 Sur' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-22 Occidente', 'datos_prueba', '2026-09-22 07:00:00', '2026-09-22 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-22 Occidente' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-23 Centro', 'datos_prueba', '2026-09-23 07:00:00', '2026-09-23 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-23 Centro' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-24 Chapinero', 'datos_prueba', '2026-09-24 07:00:00', '2026-09-24 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-24 Chapinero' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-25 Kennedy', 'datos_prueba', '2026-09-25 07:00:00', '2026-09-25 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-25 Kennedy' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-26 Suba', 'datos_prueba', '2026-09-26 07:00:00', '2026-09-26 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-26 Suba' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-27 Fontibon', 'datos_prueba', '2026-09-27 07:00:00', '2026-09-27 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-27 Fontibon' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-28 Engativa', 'datos_prueba', '2026-09-28 07:00:00', '2026-09-28 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-28 Engativa' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-29 Usaquen', 'datos_prueba', '2026-09-01 07:00:00', '2026-09-01 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-29 Usaquen' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-30 Norte', 'datos_prueba', '2026-09-02 07:00:00', '2026-09-02 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-30 Norte' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-31 Sur', 'datos_prueba', '2026-09-03 07:00:00', '2026-09-03 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-31 Sur' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-32 Occidente', 'datos_prueba', '2026-09-04 07:00:00', '2026-09-04 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-32 Occidente' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-33 Centro', 'datos_prueba', '2026-09-05 07:00:00', '2026-09-05 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-33 Centro' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-34 Chapinero', 'datos_prueba', '2026-09-06 07:00:00', '2026-09-06 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-34 Chapinero' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-35 Kennedy', 'datos_prueba', '2026-09-07 07:00:00', '2026-09-07 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-35 Kennedy' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-36 Suba', 'datos_prueba', '2026-09-08 07:00:00', '2026-09-08 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-36 Suba' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-37 Fontibon', 'datos_prueba', '2026-09-09 07:00:00', '2026-09-09 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-37 Fontibon' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-38 Engativa', 'datos_prueba', '2026-09-10 07:00:00', '2026-09-10 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-38 Engativa' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-39 Usaquen', 'datos_prueba', '2026-09-11 07:00:00', '2026-09-11 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-39 Usaquen' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-40 Norte', 'datos_prueba', '2026-09-12 07:00:00', '2026-09-12 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-40 Norte' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-41 Sur', 'datos_prueba', '2026-09-13 07:00:00', '2026-09-13 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-41 Sur' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-42 Occidente', 'datos_prueba', '2026-09-14 07:00:00', '2026-09-14 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-42 Occidente' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-43 Centro', 'datos_prueba', '2026-09-15 07:00:00', '2026-09-15 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-43 Centro' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-44 Chapinero', 'datos_prueba', '2026-09-16 07:00:00', '2026-09-16 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-44 Chapinero' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-45 Kennedy', 'datos_prueba', '2026-09-17 07:00:00', '2026-09-17 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-45 Kennedy' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-46 Suba', 'datos_prueba', '2026-09-18 07:00:00', '2026-09-18 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-46 Suba' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-47 Fontibon', 'datos_prueba', '2026-09-19 07:00:00', '2026-09-19 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-47 Fontibon' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-48 Engativa', 'datos_prueba', '2026-09-20 07:00:00', '2026-09-20 15:00:00', NULL, NULL, 'Planificada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-48 Engativa' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-49 Usaquen', 'datos_prueba', '2026-09-21 07:00:00', '2026-09-21 15:00:00', NULL, NULL, 'Cancelada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-49 Usaquen' AND usuario_creacion = 'datos_prueba');
INSERT INTO rutas_entrega (nombre_ruta, usuario_creacion, hora_salida_estimada, hora_llegada_estimada, hora_salida_real, hora_llegada_real, estado)
SELECT 'RT-TEST-50 Norte', 'datos_prueba', '2026-09-22 07:00:00', '2026-09-22 15:00:00', NULL, NULL, 'Cancelada'
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM rutas_entrega WHERE nombre_ruta = 'RT-TEST-50 Norte' AND usuario_creacion = 'datos_prueba');

-- 8. ASIGNACIONES de vehiculo y conductor a las rutas 1 a 9 (las demas quedan libres para probar la asignacion).
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-01 Sur' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST001' AND c.numero_licencia = 'LIC-TEST-001'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-02 Occidente' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST002' AND c.numero_licencia = 'LIC-TEST-002'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-03 Centro' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST003' AND c.numero_licencia = 'LIC-TEST-003'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-04 Chapinero' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST004' AND c.numero_licencia = 'LIC-TEST-004'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-05 Kennedy' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST005' AND c.numero_licencia = 'LIC-TEST-005'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-06 Suba' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST006' AND c.numero_licencia = 'LIC-TEST-006'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-07 Fontibon' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST007' AND c.numero_licencia = 'LIC-TEST-007'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-08 Engativa' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST008' AND c.numero_licencia = 'LIC-TEST-008'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);
INSERT INTO asignaciones_entrega (id_ruta, id_vehiculo, id_conductor, usuario_asignacion, notas)
SELECT r.id_ruta, v.id_vehiculo, c.id_conductor, 'datos_prueba', 'Asignacion de prueba'
FROM rutas_entrega r, vehiculos v, conductores c
WHERE r.nombre_ruta = 'RT-TEST-09 Usaquen' AND r.usuario_creacion = 'datos_prueba' AND v.placa = 'TST009' AND c.numero_licencia = 'LIC-TEST-009'
AND NOT EXISTS (SELECT 1 FROM asignaciones_entrega a WHERE a.id_ruta = r.id_ruta);

-- 9. VENTAS EN RUTA. Rutas 1-5: ventas 1-10 ya entregadas. Rutas 6-7: ventas 11-15 En Transito (pendientes de entrega).
-- Rutas 8-9: ventas 16-20 En Preparacion listas para despachar. Las ventas 21-35 En Preparacion quedan sin ruta.
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, '2026-09-01 11:15:00', 'Recepcion venta 1', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-001' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-01 Sur' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, '2026-09-01 12:15:00', 'Recepcion venta 2', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-002' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-01 Sur' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, '2026-09-02 11:15:00', 'Recepcion venta 3', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-003' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-02 Occidente' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, '2026-09-02 12:15:00', 'Recepcion venta 4', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-004' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-02 Occidente' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, '2026-09-03 11:15:00', 'Recepcion venta 5', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-005' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-03 Centro' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, '2026-09-03 12:15:00', 'Recepcion venta 6', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-006' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-03 Centro' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, '2026-09-04 11:15:00', 'Recepcion venta 7', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-007' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-04 Chapinero' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, '2026-09-04 12:15:00', 'Recepcion venta 8', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-008' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-04 Chapinero' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, '2026-09-05 11:15:00', 'Recepcion venta 9', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-009' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-05 Kennedy' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, '2026-09-05 12:15:00', 'Recepcion venta 10', 'Entregado sin novedad'
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-010' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-05 Kennedy' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-011' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-06 Suba' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-012' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-06 Suba' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 3, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-013' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-06 Suba' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-014' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-07 Fontibon' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-015' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-07 Fontibon' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-016' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-08 Engativa' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-017' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-08 Engativa' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 3, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-018' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-08 Engativa' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 1, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-019' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-09 Usaquen' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);
INSERT INTO ventas_ruta (id_ruta, id_venta, orden_entrega, direccion_destino, fecha_entrega, recibido_por, observaciones)
SELECT r.id_ruta, v.id_venta, 2, c.direccion, NULL, NULL, NULL
FROM rutas_entrega r JOIN ventas v ON v.numero_venta = 'V-TEST-020' JOIN clientes c ON c.id_cliente = v.id_cliente
WHERE r.nombre_ruta = 'RT-TEST-09 Usaquen' AND r.usuario_creacion = 'datos_prueba'
AND NOT EXISTS (SELECT 1 FROM ventas_ruta x WHERE x.id_ruta = r.id_ruta AND x.id_venta = v.id_venta);

-- 10. VERIFICACION informativa (no modifica nada): proveedor 33 con el NIT ficticio de prueba.
SELECT CASE
         WHEN p.id_proveedor IS NULL THEN 'El proveedor 33 aun no existe: lo carga el modulo de Proveedores/Inventario.'
         WHEN p.nit = '985731642-9' THEN 'El proveedor 33 coincide con el NIT ficticio de prueba 985731642-9.'
         ELSE CONCAT('El proveedor 33 existe con otro NIT (', p.nit, '). No se modifico.')
       END AS verificacion_proveedor_33
FROM (SELECT 1) AS unico LEFT JOIN proveedores p ON p.id_proveedor = 33;
