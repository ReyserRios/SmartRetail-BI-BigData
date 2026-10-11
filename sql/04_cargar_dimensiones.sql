/* =====================================================================
   SmartRetail BI & Big Data
   04 - Cargar las dimensiones                   (Pasos 3, 9, 10 y 11)
   ---------------------------------------------------------------------
   - Paso 3  : Dim_Tiempo con un bucle WHILE (2025-01-01 a 2026-12-31).
   - Paso 9  : fila "Desconocido" (clave -1) en cada dimensión.
   - Paso 10 : catálogos pequeños (estado, transportista, almacén, ubicación).
   - Paso 11 : productos (a mano) y 200 clientes seudonimizados (bucle).
   ===================================================================== */

USE SmartRetail;
GO

/* ---------- Paso 3: llenar Dim_Tiempo ---------- */
SET LANGUAGE Spanish;

DECLARE @fecha DATE = '2025-01-01';
DECLARE @fin   DATE = '2026-12-31';

WHILE @fecha <= @fin
BEGIN
    INSERT INTO dw.Dim_Tiempo
        (sk_fecha, fecha, anio, trimestre, mes, nombre_mes, semana, dia, dia_semana)
    VALUES (
        CONVERT(INT, FORMAT(@fecha, 'yyyyMMdd')),
        @fecha,
        YEAR(@fecha),
        DATEPART(QUARTER, @fecha),
        MONTH(@fecha),
        DATENAME(MONTH, @fecha),
        DATEPART(ISO_WEEK, @fecha),
        DAY(@fecha),
        DATENAME(WEEKDAY, @fecha)
    );

    SET @fecha = DATEADD(DAY, 1, @fecha);
END;
GO

/* ---------- Paso 9: fila "Desconocido" (-1) ---------- */

-- Dim_Tiempo no usa IDENTITY, se inserta directo
INSERT INTO dw.Dim_Tiempo
    (sk_fecha, fecha, anio, trimestre, mes, nombre_mes, semana, dia, dia_semana)
VALUES (-1, '1900-01-01', 1900, 0, 0, 'Desconocido', 0, 0, 'Desconocido');

SET IDENTITY_INSERT dw.Dim_Producto ON;
INSERT INTO dw.Dim_Producto
    (sk_producto, id_producto, nombre_producto, categoria, precio_lista, fecha_inicio_vigencia)
VALUES (-1, 'N/A', 'Desconocido', 'Desconocido', 0, '1900-01-01');
SET IDENTITY_INSERT dw.Dim_Producto OFF;

SET IDENTITY_INSERT dw.Dim_Cliente ON;
INSERT INTO dw.Dim_Cliente
    (sk_cliente, id_cliente, segmento, fecha_inicio_vigencia)
VALUES (-1, 'N/A', 'Desconocido', '1900-01-01');
SET IDENTITY_INSERT dw.Dim_Cliente OFF;

SET IDENTITY_INSERT dw.Dim_Ubicacion ON;
INSERT INTO dw.Dim_Ubicacion
    (sk_ubicacion, ubigeo, departamento, provincia, distrito, zona)
VALUES (-1, '000000', 'Desconocido', 'Desconocido', 'Desconocido', 'Desconocido');
SET IDENTITY_INSERT dw.Dim_Ubicacion OFF;

SET IDENTITY_INSERT dw.Dim_Transportista ON;
INSERT INTO dw.Dim_Transportista
    (sk_transportista, id_transportista, nombre_transportista)
VALUES (-1, 'N/A', 'Desconocido');
SET IDENTITY_INSERT dw.Dim_Transportista OFF;

SET IDENTITY_INSERT dw.Dim_Almacen ON;
INSERT INTO dw.Dim_Almacen
    (sk_almacen, id_almacen, nombre_almacen, ubigeo)
VALUES (-1, 'N/A', 'Desconocido', '000000');
SET IDENTITY_INSERT dw.Dim_Almacen OFF;

SET IDENTITY_INSERT dw.Dim_Estado ON;
INSERT INTO dw.Dim_Estado
    (sk_estado, estado_pedido, estado_envio)
VALUES (-1, 'Desconocido', 'Desconocido');
SET IDENTITY_INSERT dw.Dim_Estado OFF;
GO

/* ---------- Paso 10: catálogos pequeños ---------- */
INSERT INTO dw.Dim_Estado (estado_pedido, estado_envio) VALUES
('REGISTRADO', 'PENDIENTE'),
('PAGADO',     'RECOGIDO'),
('PAGADO',     'EN TRANSITO'),
('PAGADO',     'EN CENTRO DE DISTRIBUCION'),
('PAGADO',     'ENTREGADO'),
('CANCELADO',  'NO ENVIADO');

INSERT INTO dw.Dim_Transportista (id_transportista, nombre_transportista) VALUES
('TR-001', 'RAPIDEX'),
('TR-002', 'ANDES CARGO'),
('TR-003', 'COSTA EXPRESS'),
('TR-004', 'ENVIOS DEL SUR');

INSERT INTO dw.Dim_Almacen (id_almacen, nombre_almacen, ubigeo) VALUES
('ALM-01', 'ALMACEN CENTRAL CALLAO', '070101'),
('ALM-02', 'ALMACEN SUR AREQUIPA',   '040101'),
('ALM-03', 'ALMACEN NORTE TRUJILLO', '130101');

INSERT INTO dw.Dim_Ubicacion (ubigeo, departamento, provincia, distrito, zona) VALUES
('150122', 'LIMA',        'LIMA',     'MIRAFLORES',             'LIMA METROPOLITANA'),
('150131', 'LIMA',        'LIMA',     'SAN ISIDRO',             'LIMA METROPOLITANA'),
('150140', 'LIMA',        'LIMA',     'SANTIAGO DE SURCO',      'LIMA METROPOLITANA'),
('150132', 'LIMA',        'LIMA',     'SAN JUAN DE LURIGANCHO', 'LIMA METROPOLITANA'),
('150117', 'LIMA',        'LIMA',     'LOS OLIVOS',             'LIMA METROPOLITANA'),
('070101', 'CALLAO',      'CALLAO',   'CALLAO',                 'LIMA METROPOLITANA'),
('040101', 'AREQUIPA',    'AREQUIPA', 'AREQUIPA',               'SUR'),
('080101', 'CUSCO',       'CUSCO',    'CUSCO',                  'SUR'),
('130101', 'LA LIBERTAD', 'TRUJILLO', 'TRUJILLO',               'NORTE'),
('140101', 'LAMBAYEQUE',  'CHICLAYO', 'CHICLAYO',               'NORTE'),
('200101', 'PIURA',       'PIURA',    'PIURA',                  'NORTE');
GO

/* ---------- Paso 11: productos ---------- */
INSERT INTO dw.Dim_Producto
    (id_producto, nombre_producto, categoria, precio_lista, fecha_inicio_vigencia)
VALUES
('PRD-001', 'LAPTOP 14 PULGADAS',       'TECNOLOGIA', 2499.00, '2025-01-01'),
('PRD-002', 'AUDIFONOS INALAMBRICOS',   'TECNOLOGIA',  189.90, '2025-01-01'),
('PRD-003', 'SMARTPHONE 128GB',         'TECNOLOGIA', 1299.00, '2025-01-01'),
('PRD-004', 'TABLET 10 PULGADAS',       'TECNOLOGIA',  899.00, '2025-01-01'),
('PRD-005', 'LICUADORA 600W',           'HOGAR',       159.90, '2025-01-01'),
('PRD-006', 'JUEGO DE SABANAS QUEEN',   'HOGAR',       129.00, '2025-01-01'),
('PRD-007', 'OLLA ARROCERA 1.8L',       'HOGAR',       149.90, '2025-01-01'),
('PRD-008', 'LAMPARA DE ESCRITORIO',    'HOGAR',        69.90, '2025-01-01'),
('PRD-009', 'ZAPATILLAS URBANAS',       'MODA',        219.00, '2025-01-01'),
('PRD-010', 'CASACA IMPERMEABLE',       'MODA',        179.90, '2025-01-01'),
('PRD-011', 'MOCHILA 25L',              'MODA',         99.90, '2025-01-01'),
('PRD-012', 'POLO DE ALGODON',          'MODA',         39.90, '2025-01-01'),
('PRD-013', 'BICICLETA MONTANERA',      'DEPORTES',    1199.00, '2025-01-01'),
('PRD-014', 'MANCUERNAS 10KG',          'DEPORTES',     139.00, '2025-01-01'),
('PRD-015', 'COLCHONETA DE YOGA',       'DEPORTES',      59.90, '2025-01-01'),
('PRD-016', 'PELOTA DE FUTBOL',         'DEPORTES',      79.90, '2025-01-01'),
('PRD-017', 'CREMA HIDRATANTE',         'BELLEZA',       49.90, '2025-01-01'),
('PRD-018', 'PERFUME 100ML',            'BELLEZA',      249.00, '2025-01-01'),
('PRD-019', 'SECADORA DE CABELLO',      'BELLEZA',      119.90, '2025-01-01'),
('PRD-020', 'SET DE MAQUILLAJE',        'BELLEZA',       89.90, '2025-01-01');
GO

/* ---------- Paso 11: 200 clientes seudonimizados ---------- */
DECLARE @i INT = 1;

WHILE @i <= 200
BEGIN
    INSERT INTO dw.Dim_Cliente (id_cliente, segmento, fecha_inicio_vigencia)
    VALUES (
        CONVERT(VARCHAR(36), NEWID()),
        CASE
            WHEN @i % 10 = 0 THEN 'CORPORATIVO'
            WHEN @i % 3  = 0 THEN 'FRECUENTE'
            ELSE 'NUEVO'
        END,
        '2025-01-01'
    );

    SET @i = @i + 1;
END;
GO
