/* =====================================================================
   SmartRetail BI & Big Data
   03 - Crear las tablas de hechos                     (Pasos 7 y 8)
   ---------------------------------------------------------------------
   - Fact_Ventas_Envios : una fila por producto dentro de un pedido.
   - Fact_Inventario    : foto diaria del stock por producto y almacén.
   Las claves foráneas (REFERENCES) aplican la regla RC-02 y los CHECK
   la regla RC-03.
   ===================================================================== */

USE SmartRetail;
GO

/* ---------- Paso 7: Fact_Ventas_Envios ---------- */
CREATE TABLE dw.Fact_Ventas_Envios (
    sk_venta             BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    -- Claves foráneas hacia las dimensiones
    sk_fecha_pedido      INT NOT NULL REFERENCES dw.Dim_Tiempo(sk_fecha),
    sk_fecha_entrega     INT NOT NULL REFERENCES dw.Dim_Tiempo(sk_fecha),
    sk_cliente           INT NOT NULL REFERENCES dw.Dim_Cliente(sk_cliente),
    sk_producto          INT NOT NULL REFERENCES dw.Dim_Producto(sk_producto),
    sk_ubicacion         INT NOT NULL REFERENCES dw.Dim_Ubicacion(sk_ubicacion),
    sk_transportista     INT NOT NULL REFERENCES dw.Dim_Transportista(sk_transportista),
    sk_almacen           INT NOT NULL REFERENCES dw.Dim_Almacen(sk_almacen),
    sk_estado            INT NOT NULL REFERENCES dw.Dim_Estado(sk_estado),

    -- Identificadores del pedido y del envío (dimensiones degeneradas)
    id_pedido            VARCHAR(36) NOT NULL,
    id_envio             VARCHAR(36) NOT NULL,

    -- Medidas
    cantidad             INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario      DECIMAL(12,2) NOT NULL CHECK (precio_unitario > 0),
    monto_total          DECIMAL(14,2) NOT NULL CHECK (monto_total > 0),
    tiempo_entrega_dias  DECIMAL(6,2)  NULL,
    tiempo_envio_dias    DECIMAL(6,2)  NULL,
    es_entrega_a_tiempo  BIT           NULL,
    es_cancelado         BIT           NOT NULL DEFAULT 0,

    -- Auditoría
    fecha_carga          DATETIME      NOT NULL DEFAULT GETDATE()
);
GO

/* ---------- Paso 8: Fact_Inventario ---------- */
CREATE TABLE dw.Fact_Inventario (
    sk_inventario   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,

    sk_fecha        INT NOT NULL REFERENCES dw.Dim_Tiempo(sk_fecha),
    sk_producto     INT NOT NULL REFERENCES dw.Dim_Producto(sk_producto),
    sk_almacen      INT NOT NULL REFERENCES dw.Dim_Almacen(sk_almacen),

    cantidad_stock  INT NOT NULL CHECK (cantidad_stock >= 0),
    stock_minimo    INT NOT NULL CHECK (stock_minimo >= 0),

    fecha_carga     DATETIME NOT NULL DEFAULT GETDATE()
);
GO
