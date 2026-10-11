/* =====================================================================
   SmartRetail BI & Big Data
   02 - Crear las tablas de dimensiones           (Pasos 2, 4, 5 y 6)
   ---------------------------------------------------------------------
   - Dim_Tiempo        : una fila por día; clave AAAAMMDD.
   - Dim_Producto      : SCD tipo 2 (historial de precio y categoría).
   - Dim_Cliente       : SCD tipo 2; cliente seudonimizado (Ley 29733).
   - Dim_Ubicacion, Dim_Transportista, Dim_Almacen, Dim_Estado : SCD tipo 1.
   ===================================================================== */

USE SmartRetail;
GO

/* ---------- Paso 2: Dim_Tiempo ---------- */
CREATE TABLE dw.Dim_Tiempo (
    sk_fecha    INT          NOT NULL PRIMARY KEY,
    fecha       DATE         NOT NULL,
    anio        SMALLINT     NOT NULL,
    trimestre   SMALLINT     NOT NULL,
    mes         SMALLINT     NOT NULL,
    nombre_mes  VARCHAR(15)  NOT NULL,
    semana      SMALLINT     NOT NULL,
    dia         SMALLINT     NOT NULL,
    dia_semana  VARCHAR(15)  NOT NULL
);
GO

/* ---------- Paso 4: Dim_Producto (SCD tipo 2) ---------- */
CREATE TABLE dw.Dim_Producto (
    sk_producto            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    id_producto            VARCHAR(36)   NOT NULL,
    nombre_producto        VARCHAR(120)  NOT NULL,
    categoria              VARCHAR(60)   NOT NULL,
    precio_lista           DECIMAL(12,2) NOT NULL,
    fecha_inicio_vigencia  DATE          NOT NULL,
    fecha_fin_vigencia     DATE          NULL,
    es_actual              BIT           NOT NULL DEFAULT 1
);
GO

/* ---------- Paso 5: Dim_Cliente (SCD tipo 2) ---------- */
CREATE TABLE dw.Dim_Cliente (
    sk_cliente             INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    id_cliente             VARCHAR(36)  NOT NULL,
    segmento               VARCHAR(30)  NOT NULL,
    fecha_inicio_vigencia  DATE         NOT NULL,
    fecha_fin_vigencia     DATE         NULL,
    es_actual              BIT          NOT NULL DEFAULT 1
);
GO

/* ---------- Paso 6: dimensiones SCD tipo 1 ---------- */
CREATE TABLE dw.Dim_Ubicacion (
    sk_ubicacion  INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    ubigeo        CHAR(6)      NOT NULL,
    departamento  VARCHAR(60)  NOT NULL,
    provincia     VARCHAR(60)  NOT NULL,
    distrito      VARCHAR(60)  NOT NULL,
    zona          VARCHAR(30)  NOT NULL
);

CREATE TABLE dw.Dim_Transportista (
    sk_transportista      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    id_transportista      VARCHAR(36)  NOT NULL,
    nombre_transportista  VARCHAR(80)  NOT NULL
);

CREATE TABLE dw.Dim_Almacen (
    sk_almacen      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    id_almacen      VARCHAR(36)  NOT NULL,
    nombre_almacen  VARCHAR(80)  NOT NULL,
    ubigeo          CHAR(6)      NOT NULL
);

CREATE TABLE dw.Dim_Estado (
    sk_estado      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    estado_pedido  VARCHAR(30)  NOT NULL,
    estado_envio   VARCHAR(30)  NOT NULL
);
GO
