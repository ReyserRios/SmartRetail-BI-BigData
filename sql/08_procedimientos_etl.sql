/* =====================================================================
   SmartRetail BI & Big Data
   08 - Procedimientos del ETL                         (Pasos 15 y 16)
   ---------------------------------------------------------------------
   - stg.sp_validar_pedidos : aplica las reglas RC-01 a RC-04 y registra
                              las filas rechazadas en stg.stg_errores_etl.
   - dw.sp_cargar_ventas    : traduce códigos a claves subrogadas, calcula
                              las medidas y carga Fact_Ventas_Envios dentro
                              de una transacción con TRY...CATCH.
   Uso:  EXEC stg.sp_validar_pedidos;
         EXEC dw.sp_cargar_ventas;
   ===================================================================== */

USE SmartRetail;
GO

/* ---------- Paso 15: validación ---------- */
CREATE PROCEDURE stg.sp_validar_pedidos
AS
BEGIN
    SET NOCOUNT ON;

    -- Cada ejecución recalcula los errores desde cero
    TRUNCATE TABLE stg.stg_errores_etl;

    -- RC-01 Unicidad: mismo pedido y mismo producto repetidos
    INSERT INTO stg.stg_errores_etl (id_fila, id_pedido, regla, motivo)
    SELECT r.id_fila, r.id_pedido, 'RC-01', 'Fila duplicada: mismo pedido y producto'
    FROM stg.pedidos_raw r
    WHERE r.id_producto IS NOT NULL
      AND r.id_fila > (SELECT MIN(r2.id_fila)
                       FROM stg.pedidos_raw r2
                       WHERE r2.id_pedido = r.id_pedido
                         AND r2.id_producto = r.id_producto);

    -- RC-02 Completitud: producto vacío
    INSERT INTO stg.stg_errores_etl (id_fila, id_pedido, regla, motivo)
    SELECT id_fila, id_pedido, 'RC-02', 'Producto nulo'
    FROM stg.pedidos_raw
    WHERE id_producto IS NULL;

    -- RC-03 Validez: cantidad o precio en cero o negativo
    INSERT INTO stg.stg_errores_etl (id_fila, id_pedido, regla, motivo)
    SELECT id_fila, id_pedido, 'RC-03', 'Cantidad o precio menor o igual a cero'
    FROM stg.pedidos_raw
    WHERE ISNULL(precio_unitario, 0) <= 0
       OR ISNULL(cantidad, 0) <= 0;

    -- RC-04 Consistencia: fecha que no se puede interpretar
    INSERT INTO stg.stg_errores_etl (id_fila, id_pedido, regla, motivo)
    SELECT id_fila, id_pedido, 'RC-04', 'Fecha de pedido no reconocible'
    FROM stg.pedidos_raw
    WHERE stg.fn_convertir_fecha(fecha_pedido) IS NULL;

    -- Resumen de la validación
    SELECT regla, COUNT(*) AS filas_rechazadas
    FROM stg.stg_errores_etl
    GROUP BY regla
    ORDER BY regla;
END;
GO

/* ---------- Paso 16: carga ---------- */
CREATE PROCEDURE dw.sp_cargar_ventas
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @filas INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dw.Fact_Ventas_Envios
            (sk_fecha_pedido, sk_fecha_entrega, sk_cliente, sk_producto,
             sk_ubicacion, sk_transportista, sk_almacen, sk_estado,
             id_pedido, id_envio, cantidad, precio_unitario, monto_total,
             tiempo_entrega_dias, tiempo_envio_dias, es_entrega_a_tiempo, es_cancelado)
        SELECT
            ISNULL(tp.sk_fecha, -1),
            ISNULL(te.sk_fecha, -1),
            ISNULL(c.sk_cliente, -1),
            p.sk_producto,
            ISNULL(u.sk_ubicacion, -1),
            ISNULL(t.sk_transportista, -1),
            ISNULL(a.sk_almacen, -1),
            ISNULL(e.sk_estado, -1),
            r.id_pedido,
            r.id_envio,
            r.cantidad,
            r.precio_unitario,
            r.cantidad * r.precio_unitario,
            DATEDIFF(DAY, f.fecha_pedido,   f.fecha_real),
            DATEDIFF(DAY, f.fecha_despacho, f.fecha_real),
            stg.fn_es_entrega_a_tiempo(f.fecha_real, f.fecha_estimada),
            CASE WHEN r.estado_pedido = 'CANCELADO' THEN 1 ELSE 0 END
        FROM stg.pedidos_raw r
        CROSS APPLY (SELECT
                        stg.fn_convertir_fecha(r.fecha_pedido)           AS fecha_pedido,
                        stg.fn_convertir_fecha(r.fecha_despacho)         AS fecha_despacho,
                        stg.fn_convertir_fecha(r.fecha_entrega_estimada) AS fecha_estimada,
                        stg.fn_convertir_fecha(r.fecha_entrega_real)     AS fecha_real) f
        INNER JOIN dw.Dim_Producto p
                ON p.id_producto = r.id_producto
               AND f.fecha_pedido BETWEEN p.fecha_inicio_vigencia
                                      AND ISNULL(p.fecha_fin_vigencia, '9999-12-31')
        LEFT JOIN dw.Dim_Cliente c
               ON c.id_cliente = r.id_cliente
              AND f.fecha_pedido BETWEEN c.fecha_inicio_vigencia
                                     AND ISNULL(c.fecha_fin_vigencia, '9999-12-31')
        LEFT JOIN dw.Dim_Tiempo tp        ON tp.fecha = f.fecha_pedido
        LEFT JOIN dw.Dim_Tiempo te        ON te.fecha = f.fecha_real
        LEFT JOIN dw.Dim_Ubicacion u      ON u.ubigeo = r.ubigeo_destino
        LEFT JOIN dw.Dim_Transportista t  ON t.id_transportista = r.id_transportista
        LEFT JOIN dw.Dim_Almacen a        ON a.id_almacen = r.id_almacen
        LEFT JOIN dw.Dim_Estado e         ON e.estado_pedido = r.estado_pedido
                                         AND e.estado_envio  = r.estado_envio
        WHERE NOT EXISTS (SELECT 1 FROM stg.stg_errores_etl x
                          WHERE x.id_fila = r.id_fila)
          AND NOT EXISTS (SELECT 1 FROM dw.Fact_Ventas_Envios v
                          WHERE v.id_pedido = r.id_pedido
                            AND v.sk_producto = p.sk_producto);

        SET @filas = @@ROWCOUNT;

        COMMIT TRANSACTION;

        SELECT @filas AS filas_cargadas;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO stg.stg_errores_etl (id_fila, id_pedido, regla, motivo)
        VALUES (NULL, NULL, 'ETL', LEFT(ERROR_MESSAGE(), 200));

        THROW;
    END CATCH
END;
GO

/* ---------- Ejecución del ETL ---------- */
EXEC stg.sp_validar_pedidos;
EXEC dw.sp_cargar_ventas;
GO
