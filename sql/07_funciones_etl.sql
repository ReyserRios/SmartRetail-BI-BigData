/* =====================================================================
   SmartRetail BI & Big Data
   07 - Funciones del ETL                                   (Paso 14)
   ---------------------------------------------------------------------
   - stg.fn_convertir_fecha     : interpreta fechas en texto con formato
                                  aaaa-mm-dd o dd/mm/aaaa (regla RC-04).
   - stg.fn_es_entrega_a_tiempo : 1 a tiempo, 0 tarde, NULL no entregado
                                  (indicador del KPI-07).
   ===================================================================== */

USE SmartRetail;
GO

CREATE FUNCTION stg.fn_convertir_fecha (@texto VARCHAR(30))
RETURNS DATE
AS
BEGIN
    DECLARE @resultado DATE;

    IF @texto LIKE '__/__/____'
        SET @resultado = TRY_CONVERT(DATE, @texto, 103);
    ELSE
        SET @resultado = TRY_CONVERT(DATE, @texto, 23);

    RETURN @resultado;
END;
GO

CREATE FUNCTION stg.fn_es_entrega_a_tiempo (@fecha_real DATE, @fecha_estimada DATE)
RETURNS BIT
AS
BEGIN
    IF @fecha_real IS NULL
        RETURN NULL;

    RETURN CASE WHEN @fecha_real <= @fecha_estimada THEN 1 ELSE 0 END;
END;
GO
