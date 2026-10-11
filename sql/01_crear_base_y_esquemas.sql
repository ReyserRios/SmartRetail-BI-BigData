/* =====================================================================
   SmartRetail BI & Big Data
   01 - Crear la base de datos y los esquemas            (Paso 1)
   ---------------------------------------------------------------------
   - SmartRetail : base de datos del Data Warehouse.
   - stg         : zona de staging (datos crudos y limpieza del ETL).
   - dw          : zona limpia (dimensiones y hechos que consume Power BI).
   Orden de ejecución: 01 -> 10
   ===================================================================== */

CREATE DATABASE SmartRetail;
GO

USE SmartRetail;
GO

CREATE SCHEMA stg;
GO

CREATE SCHEMA dw;
GO
