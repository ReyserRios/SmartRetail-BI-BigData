/* =====================================================================
   SmartRetail BI & Big Data
   11 - Seguridad: roles y permisos (RBAC)                  (Paso 30)
   ---------------------------------------------------------------------
   - analyst_user : solo lectura del esquema dw; sin acceso a stg.
   - etl_service  : lectura, escritura y ejecución en stg y dw
                    (ALTER en stg para el TRUNCATE de la validación).
   - Usuarios de prueba WITHOUT LOGIN para comprobar los permisos con
     EXECUTE AS ... REVERT (RNF-06 del informe).
   ===================================================================== */

USE SmartRetail;
GO

-- 1. Rol para los analistas: solo lectura del almacén
CREATE ROLE analyst_user;
GRANT SELECT ON SCHEMA::dw  TO analyst_user;
DENY  SELECT ON SCHEMA::stg TO analyst_user;

-- 2. Rol para el proceso ETL: lee, escribe y ejecuta los procedimientos
CREATE ROLE etl_service;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::stg TO etl_service;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::dw  TO etl_service;
GRANT ALTER ON SCHEMA::stg TO etl_service;

-- 3. Usuarios de prueba, uno en cada rol
CREATE USER usuario_analista WITHOUT LOGIN;
ALTER ROLE analyst_user ADD MEMBER usuario_analista;

CREATE USER usuario_etl WITHOUT LOGIN;
ALTER ROLE etl_service ADD MEMBER usuario_etl;
GO


/* =====================================================================
   PRUEBAS DE PERMISOS
   Ejecutar CADA bloque por separado (seleccionarlo y pulsar F5).
   Cada bloque termina con REVERT para volver al usuario dbo.
   ===================================================================== */

-- Prueba 1: leer dw -> DEBE FUNCIONAR (devuelve 5 filas)
EXECUTE AS USER = 'usuario_analista';
SELECT TOP 5 * FROM dw.Fact_Ventas_Envios;
REVERT;
GO

-- Prueba 2: leer stg -> DEBE FALLAR (Mens. 229, permiso SELECT denegado)
EXECUTE AS USER = 'usuario_analista';
SELECT TOP 5 * FROM stg.pedidos_raw;
REVERT;
GO

-- Prueba 3: borrar en dw -> DEBE FALLAR (Mens. 229, permiso DELETE denegado)
EXECUTE AS USER = 'usuario_analista';
DELETE FROM dw.Dim_Estado WHERE sk_estado = -1;
REVERT;
GO

-- Comprobación final: debe responder dbo
SELECT USER_NAME() AS soy;
GO


/* =====================================================================
   REVISIÓN DE LA CONFIGURACIÓN (solo lectura)
   ===================================================================== */

-- Permisos del rol y del usuario de prueba
SELECT dp.name AS principal, pe.permission_name, pe.state_desc,
       SCHEMA_NAME(pe.major_id) AS esquema
FROM sys.database_permissions pe
JOIN sys.database_principals dp ON pe.grantee_principal_id = dp.principal_id
WHERE dp.name IN ('analyst_user', 'usuario_analista', 'etl_service', 'usuario_etl');

-- Miembros de cada rol
SELECT r.name AS rol, m.name AS miembro
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE r.name IN ('analyst_user', 'etl_service');
GO
