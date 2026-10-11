/* =====================================================================
   SmartRetail BI & Big Data
   09 - Cargar Fact_Inventario                              (Paso 17)
   ---------------------------------------------------------------------
   Foto diaria de stock por producto y almacén (2025-01-01 a 2026-09-30),
   generada por conjuntos con CROSS JOIN: 638 días x 20 productos x
   3 almacenes = 38 280 filas. El 5 % de las fotos son productos agotados.
   ===================================================================== */

USE SmartRetail;
GO

INSERT INTO dw.Fact_Inventario (sk_fecha, sk_producto, sk_almacen, cantidad_stock, stock_minimo)
SELECT
    t.sk_fecha,
    p.sk_producto,
    a.sk_almacen,
    CASE
        WHEN ABS(CHECKSUM(NEWID())) % 100 < 5 THEN 0
        ELSE 5 + ABS(CHECKSUM(NEWID())) % 116
    END,
    15
FROM dw.Dim_Tiempo t
CROSS JOIN dw.Dim_Producto p
CROSS JOIN dw.Dim_Almacen a
WHERE t.sk_fecha BETWEEN 20250101 AND 20260930
  AND p.sk_producto > 0
  AND a.sk_almacen > 0
  AND NOT EXISTS (SELECT 1 FROM dw.Fact_Inventario i
                  WHERE i.sk_fecha = t.sk_fecha
                    AND i.sk_producto = p.sk_producto
                    AND i.sk_almacen = a.sk_almacen);
GO
