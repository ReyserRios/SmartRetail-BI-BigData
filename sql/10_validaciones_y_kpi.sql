/* =====================================================================
   SmartRetail BI & Big Data
   10 - Consultas de comprobación y KPI
   ---------------------------------------------------------------------
   Solo consultas de lectura (SELECT): se pueden ejecutar en cualquier
   momento y las veces que se quiera, sin modificar datos.
   ===================================================================== */

USE SmartRetail;
GO

/* ---------- Estructura: tablas de cada esquema ---------- */
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('dw', 'stg')
ORDER BY TABLE_SCHEMA, TABLE_NAME;

/* ---------- Claves foráneas de la tabla de hechos (esperado: 8) ---------- */
SELECT name AS clave_foranea
FROM sys.foreign_keys
WHERE parent_object_id = OBJECT_ID('dw.Fact_Ventas_Envios');

/* ---------- Dim_Tiempo (esperado: 730 días + fila -1) ---------- */
SELECT COUNT(*) AS total_dias FROM dw.Dim_Tiempo WHERE sk_fecha <> -1;
SELECT TOP 5 * FROM dw.Dim_Tiempo WHERE sk_fecha <> -1 ORDER BY sk_fecha;

/* ---------- Fila "Desconocido" en cada dimensión (esperado: 1 en cada una) ---------- */
SELECT 'Dim_Tiempo' AS tabla, COUNT(*) AS filas FROM dw.Dim_Tiempo WHERE sk_fecha = -1
UNION ALL SELECT 'Dim_Producto', COUNT(*) FROM dw.Dim_Producto WHERE sk_producto = -1
UNION ALL SELECT 'Dim_Cliente', COUNT(*) FROM dw.Dim_Cliente WHERE sk_cliente = -1
UNION ALL SELECT 'Dim_Ubicacion', COUNT(*) FROM dw.Dim_Ubicacion WHERE sk_ubicacion = -1
UNION ALL SELECT 'Dim_Transportista', COUNT(*) FROM dw.Dim_Transportista WHERE sk_transportista = -1
UNION ALL SELECT 'Dim_Almacen', COUNT(*) FROM dw.Dim_Almacen WHERE sk_almacen = -1
UNION ALL SELECT 'Dim_Estado', COUNT(*) FROM dw.Dim_Estado WHERE sk_estado = -1;

/* ---------- Catálogos (esperado: 7, 5, 4 y 12, incluida la fila -1) ---------- */
SELECT 'Dim_Estado' AS tabla, COUNT(*) AS filas FROM dw.Dim_Estado
UNION ALL SELECT 'Dim_Transportista', COUNT(*) FROM dw.Dim_Transportista
UNION ALL SELECT 'Dim_Almacen', COUNT(*) FROM dw.Dim_Almacen
UNION ALL SELECT 'Dim_Ubicacion', COUNT(*) FROM dw.Dim_Ubicacion;

/* ---------- Productos y clientes ---------- */
SELECT categoria, COUNT(*) AS productos
FROM dw.Dim_Producto
WHERE sk_producto <> -1
GROUP BY categoria;

SELECT segmento, COUNT(*) AS clientes
FROM dw.Dim_Cliente
WHERE sk_cliente <> -1
GROUP BY segmento;

/* ---------- Revisión: claves sk = 0 (esperado: 0 filas en todas) ----------
   Las consultas de generación filtran con "sk > 0". Si alguna dimensión
   tuviera una fila con clave 0, esa fila habría quedado fuera. */
SELECT 'Dim_Producto' AS tabla, COUNT(*) AS filas_con_sk_0 FROM dw.Dim_Producto WHERE sk_producto = 0
UNION ALL SELECT 'Dim_Cliente', COUNT(*) FROM dw.Dim_Cliente WHERE sk_cliente = 0
UNION ALL SELECT 'Dim_Ubicacion', COUNT(*) FROM dw.Dim_Ubicacion WHERE sk_ubicacion = 0
UNION ALL SELECT 'Dim_Transportista', COUNT(*) FROM dw.Dim_Transportista WHERE sk_transportista = 0
UNION ALL SELECT 'Dim_Almacen', COUNT(*) FROM dw.Dim_Almacen WHERE sk_almacen = 0
UNION ALL SELECT 'Dim_Estado', COUNT(*) FROM dw.Dim_Estado WHERE sk_estado = 0;

/* ---------- Pruebas de las funciones ---------- */
SELECT
    stg.fn_convertir_fecha('15/03/2025')                    AS fecha_formato_peru,
    stg.fn_convertir_fecha('2025-03-15')                    AS fecha_formato_iso,
    stg.fn_es_entrega_a_tiempo('2025-03-18', '2025-03-20')  AS llego_antes,
    stg.fn_es_entrega_a_tiempo('2025-03-22', '2025-03-20')  AS llego_tarde,
    stg.fn_es_entrega_a_tiempo(NULL, '2025-03-20')          AS no_entregado;

/* ---------- Calidad ANTES del ETL (datos crudos) ---------- */
SELECT COUNT(*)                  AS filas_totales,
       COUNT(DISTINCT id_pedido) AS pedidos
FROM stg.pedidos_raw;

SELECT
    SUM(CASE WHEN id_producto IS NULL         THEN 1 ELSE 0 END) AS rc02_producto_nulo,
    SUM(CASE WHEN precio_unitario <= 0        THEN 1 ELSE 0 END) AS rc03_precio_invalido,
    SUM(CASE WHEN fecha_pedido LIKE '__/__/%' THEN 1 ELSE 0 END) AS rc04_fecha_mal_formato
FROM stg.pedidos_raw;

/* ---------- Filas rechazadas por regla ---------- */
SELECT regla, COUNT(*) AS filas_rechazadas
FROM stg.stg_errores_etl
GROUP BY regla
ORDER BY regla;

/* ---------- Reconciliación: rechazadas + cargadas = origen ---------- */
SELECT
    (SELECT COUNT(*) FROM stg.pedidos_raw)                     AS filas_origen,
    (SELECT COUNT(DISTINCT id_fila) FROM stg.stg_errores_etl)  AS filas_rechazadas,
    (SELECT COUNT(*) FROM dw.Fact_Ventas_Envios)               AS filas_cargadas;

/* ---------- Inventario (esperado: 38 280 filas) ---------- */
SELECT
    COUNT(*)                                                        AS filas,
    SUM(CASE WHEN cantidad_stock = 0 THEN 1 ELSE 0 END)             AS fotos_agotado,
    SUM(CASE WHEN cantidad_stock < stock_minimo THEN 1 ELSE 0 END)  AS fotos_bajo_stock
FROM dw.Fact_Inventario;

/* ---------- KPI de referencia para validar Power BI (Paso 18) ---------- */
SELECT
    SUM(CASE WHEN es_cancelado = 0 THEN monto_total ELSE 0 END)   AS ventas_totales,
    COUNT(DISTINCT id_pedido)                                      AS numero_pedidos,
    SUM(CASE WHEN es_cancelado = 0 THEN monto_total ELSE 0 END)
        / COUNT(DISTINCT CASE WHEN es_cancelado = 0 THEN id_pedido END) AS ticket_promedio,
    100.0 * COUNT(DISTINCT CASE WHEN es_cancelado = 1 THEN id_pedido END)
        / COUNT(DISTINCT id_pedido)                                AS tasa_cancelacion_pct,
    AVG(tiempo_entrega_dias)                                       AS tiempo_promedio_entrega,
    100.0 * SUM(CASE WHEN es_entrega_a_tiempo = 1 THEN 1 ELSE 0 END)
        / COUNT(es_entrega_a_tiempo)                               AS entregas_a_tiempo_pct
FROM dw.Fact_Ventas_Envios;
GO
