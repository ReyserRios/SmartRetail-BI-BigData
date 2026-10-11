/* =====================================================================
   SmartRetail BI & Big Data
   06 - Generar los pedidos crudos (datos sintéticos)       (Paso 13)
   ---------------------------------------------------------------------
   Simula unos 2 000 pedidos (enero 2025 - septiembre 2026) en
   stg.pedidos_raw y siembra errores a propósito para el ETL:
     RC-01 duplicados (~2 %), RC-02 producto nulo (~1 %),
     RC-03 precio en cero (~1 %), RC-04 fecha dd/mm/aaaa (~3 %).
   Al ser aleatorio, cada ejecución produce cifras distintas.
   ===================================================================== */

USE SmartRetail;
GO

SET NOCOUNT ON;

DECLARE @p INT = 1, @total_pedidos INT = 2000;
DECLARE @id_pedido VARCHAR(36), @id_envio VARCHAR(36), @id_cliente VARCHAR(36);
DECLARE @ubigeo VARCHAR(10), @id_transportista VARCHAR(36), @id_almacen VARCHAR(36);
DECLARE @estado_pedido VARCHAR(30), @estado_envio VARCHAR(30);
DECLARE @f_pedido DATE, @f_despacho DATE, @f_estimada DATE, @f_real DATE;
DECLARE @txt_fecha_pedido VARCHAR(30);
DECLARE @azar INT, @lineas INT, @l INT;
DECLARE @id_producto VARCHAR(36), @precio DECIMAL(12,2), @cantidad INT;

WHILE @p <= @total_pedidos
BEGIN
    -- 1. Datos del pedido
    SET @id_pedido = 'PED-' + RIGHT('00000' + CAST(@p AS VARCHAR(5)), 5);
    SET @id_envio  = 'ENV-' + RIGHT('00000' + CAST(@p AS VARCHAR(5)), 5);

    SELECT TOP 1 @id_cliente = id_cliente FROM dw.Dim_Cliente
    WHERE sk_cliente > 0 ORDER BY NEWID();

    SELECT TOP 1 @ubigeo = ubigeo FROM dw.Dim_Ubicacion
    WHERE sk_ubicacion > 0 ORDER BY NEWID();

    SET @id_transportista = 'TR-00' + CAST(1 + ABS(CHECKSUM(NEWID())) % 4 AS VARCHAR(1));
    SET @id_almacen       = 'ALM-0' + CAST(1 + ABS(CHECKSUM(NEWID())) % 3 AS VARCHAR(1));

    -- 2. Fechas
    SET @f_pedido   = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 638, '2025-01-01');
    SET @f_despacho = DATEADD(DAY, 1 + ABS(CHECKSUM(NEWID())) % 2, @f_pedido);
    SET @f_estimada = DATEADD(DAY, 5, @f_pedido);
    SET @f_real     = DATEADD(DAY, 2 + ABS(CHECKSUM(NEWID())) % 8, @f_pedido);

    -- 3. Estado
    SET @azar = ABS(CHECKSUM(NEWID())) % 100;

    IF @azar < 8
    BEGIN
        SET @estado_pedido = 'CANCELADO';  SET @estado_envio = 'NO ENVIADO';
        SET @f_despacho = NULL;            SET @f_real = NULL;
    END
    ELSE IF @azar < 12
    BEGIN
        SET @estado_pedido = 'REGISTRADO'; SET @estado_envio = 'PENDIENTE';
        SET @f_despacho = NULL;            SET @f_real = NULL;
    END
    ELSE IF @azar < 20
    BEGIN
        SET @estado_pedido = 'PAGADO';
        SET @estado_envio = CASE @azar % 3
                                WHEN 0 THEN 'RECOGIDO'
                                WHEN 1 THEN 'EN TRANSITO'
                                ELSE 'EN CENTRO DE DISTRIBUCION'
                            END;
        SET @f_real = NULL;
    END
    ELSE
    BEGIN
        SET @estado_pedido = 'PAGADO';     SET @estado_envio = 'ENTREGADO';
    END

    -- 4. Error RC-04: el 3 % de las fechas llega como dd/mm/aaaa
    IF ABS(CHECKSUM(NEWID())) % 100 < 3
        SET @txt_fecha_pedido = CONVERT(VARCHAR(10), @f_pedido, 103);
    ELSE
        SET @txt_fecha_pedido = CONVERT(VARCHAR(10), @f_pedido, 23);

    -- 5. Productos del pedido (de 1 a 3)
    SET @lineas = 1 + ABS(CHECKSUM(NEWID())) % 3;
    SET @l = 1;

    WHILE @l <= @lineas
    BEGIN
        SELECT TOP 1 @id_producto = id_producto, @precio = precio_lista
        FROM dw.Dim_Producto
        WHERE sk_producto > 0
          AND id_producto NOT IN (SELECT id_producto FROM stg.pedidos_raw
                                  WHERE id_pedido = @id_pedido AND id_producto IS NOT NULL)
        ORDER BY NEWID();

        SET @cantidad = 1 + ABS(CHECKSUM(NEWID())) % 3;

        -- Errores RC-02 y RC-03: cerca del 1 % cada uno
        SET @azar = ABS(CHECKSUM(NEWID())) % 100;
        IF @azar = 0 SET @id_producto = NULL;
        IF @azar = 1 SET @precio = 0;

        INSERT INTO stg.pedidos_raw
            (id_pedido, id_envio, id_cliente, id_producto, ubigeo_destino,
             id_transportista, id_almacen, estado_pedido, estado_envio,
             fecha_pedido, fecha_despacho, fecha_entrega_estimada, fecha_entrega_real,
             cantidad, precio_unitario)
        VALUES
            (@id_pedido, @id_envio, @id_cliente, @id_producto, @ubigeo,
             @id_transportista, @id_almacen, @estado_pedido, @estado_envio,
             @txt_fecha_pedido,
             CONVERT(VARCHAR(10), @f_despacho, 23),
             CONVERT(VARCHAR(10), @f_estimada, 23),
             CONVERT(VARCHAR(10), @f_real, 23),
             @cantidad, @precio);

        SET @l = @l + 1;
    END

    SET @p = @p + 1;
END;

-- 6. Error RC-01: se duplica cerca del 2 % de las filas
INSERT INTO stg.pedidos_raw
    (id_pedido, id_envio, id_cliente, id_producto, ubigeo_destino,
     id_transportista, id_almacen, estado_pedido, estado_envio,
     fecha_pedido, fecha_despacho, fecha_entrega_estimada, fecha_entrega_real,
     cantidad, precio_unitario)
SELECT TOP 2 PERCENT
     id_pedido, id_envio, id_cliente, id_producto, ubigeo_destino,
     id_transportista, id_almacen, estado_pedido, estado_envio,
     fecha_pedido, fecha_despacho, fecha_entrega_estimada, fecha_entrega_real,
     cantidad, precio_unitario
FROM stg.pedidos_raw
ORDER BY NEWID();
GO
