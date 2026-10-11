/* =====================================================================
   SmartRetail BI & Big Data
   05 - Crear las tablas de la zona de staging              (Paso 12)
   ---------------------------------------------------------------------
   - stg.pedidos_raw     : pedidos tal como llegan del origen (permisiva:
                           admite NULL y fechas como texto).
   - stg.stg_errores_etl : registro de filas rechazadas, con la regla
                           de calidad que falló y el motivo.
   ===================================================================== */

USE SmartRetail;
GO

CREATE TABLE stg.pedidos_raw (
    id_fila                 INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    id_pedido               VARCHAR(36)   NULL,
    id_envio                VARCHAR(36)   NULL,
    id_cliente              VARCHAR(36)   NULL,
    id_producto             VARCHAR(36)   NULL,
    ubigeo_destino          VARCHAR(10)   NULL,
    id_transportista        VARCHAR(36)   NULL,
    id_almacen              VARCHAR(36)   NULL,
    estado_pedido           VARCHAR(30)   NULL,
    estado_envio            VARCHAR(30)   NULL,
    fecha_pedido            VARCHAR(30)   NULL,
    fecha_despacho          VARCHAR(30)   NULL,
    fecha_entrega_estimada  VARCHAR(30)   NULL,
    fecha_entrega_real      VARCHAR(30)   NULL,
    cantidad                INT           NULL,
    precio_unitario         DECIMAL(12,2) NULL,
    fecha_modificacion      DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE stg.stg_errores_etl (
    id_error        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    id_fila         INT           NULL,
    id_pedido       VARCHAR(36)   NULL,
    regla           VARCHAR(10)   NOT NULL,
    motivo          VARCHAR(200)  NOT NULL,
    fecha_registro  DATETIME      NOT NULL DEFAULT GETDATE()
);
GO
