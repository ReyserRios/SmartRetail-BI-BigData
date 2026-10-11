# SmartRetail BI & Big Data

Proyecto final del curso **Base de Datos Avanzadas y Big Data** (Ingeniería de Sistemas Computacionales, 2026-2).
Plataforma de e-commerce y logística de envíos masivos con dos soluciones complementarias:

- **Solución BI:** Data Warehouse en SQL Server (modelo en estrella), ETL en T-SQL con reglas de calidad, modelo OLAP y dashboard en Power BI.
- **Solución Big Data:** pipeline en Apache Spark (PySpark) sobre Google Colab, almacenamiento en Parquet particionado y experimento de escalabilidad.

## Equipo

| Integrante | Rol |
|---|---|
| Rios Vela, Reyser | Arquitecto de datos / Modelador BI |
| Ortega Valverde, Yulissa Stephany | Ingeniera de datos / Especialista ETL |
| Mechato Sotomayor, Noemi | Analista BI / Desarrolladora de dashboards |
| Chávez Ugarte, Juan Felix | Ingeniero Big Data |

Docente: Hugo Alejandro Mamanchura Lima.

## Estructura del repositorio

```
SmartRetail-BI-BigData/
├── sql/                     Scripts T-SQL 01 a 11 (ejecutar en orden)
├── powerbi/                 SmartRetail.pbix (modelo OLAP y dashboard)
├── bigdata/                 SmartRetail_BigData.ipynb (cuaderno de Colab)
├── docs/                    Diagrama de arquitectura y modelo dimensional
├── evidencias/
│   ├── bi/                  Capturas E-01, E-02 y dashboard; registros de rendimiento (RNF-03)
│   └── bigdata/             Capturas y resultados del experimento (E-08, E-10, E-14)
└── informe/                 Informe final (.docx / .pdf)
```

## Requisitos

| Componente | Versión usada |
|---|---|
| Microsoft SQL Server | 2025 (RTM) 17.0.1000.7, Standard Developer Edition (64 bits) |
| SQL Server Management Studio | Cualquier versión compatible con SQL Server 2025 |
| Power BI Desktop | 64 bits, modo Importación |
| Google Colab | 2 vCPU, ~13.6 GB de RAM |
| Java (OpenJDK) | 17 |
| Apache Spark (PySpark) | 3.5.3, `local[*]`, `spark.driver.memory = 6g` |
| Python | psutil, pandas, matplotlib (incluidos en Colab) |

## Cómo reproducir la solución BI

1. Abrir SSMS y ejecutar los scripts de `sql/` **en orden**:

   | Script | Qué hace |
   |---|---|
   | `01_crear_base_y_esquemas.sql` | Crea la base `SmartRetail` y los esquemas `stg` (staging) y `dw` (almacén) |
   | `02_crear_dimensiones.sql` | Crea las 7 dimensiones (SCD tipo 2 en producto y cliente) |
   | `03_crear_hechos.sql` | Crea `Fact_Ventas_Envios` y `Fact_Inventario` |
   | `04_cargar_dimensiones.sql` | Carga las dimensiones y la fila "Desconocido" (-1) |
   | `05_crear_staging.sql` | Crea `stg.pedidos_raw` y `stg.stg_errores_etl` |
   | `06_generar_pedidos_crudos.sql` | Genera 2 000 pedidos sintéticos (4 090 filas) con errores sembrados |
   | `07_funciones_etl.sql` | Funciones `fn_convertir_fecha` y `fn_es_entrega_a_tiempo` |
   | `08_procedimientos_etl.sql` | Procedimientos de validación y carga; **ejecuta el ETL** |
   | `09_cargar_inventario.sql` | Foto diaria de inventario (38 280 filas) |
   | `10_validaciones_y_kpi.sql` | Consultas de calidad, reconciliación y KPI de referencia (solo lectura) |
   | `11_seguridad.sql` | Roles `analyst_user` y `etl_service` y pruebas de permisos |

2. Verificar con el script 10: reconciliación **4 090 = 168 rechazadas + 3 922 cargadas**.
3. Abrir `powerbi/SmartRetail.pbix`, cambiar el origen al servidor local si es necesario (*Transformar datos → Configuración de origen de datos*) y pulsar **Actualizar**.

## Cómo reproducir la solución Big Data

1. Abrir `bigdata/SmartRetail_BigData.ipynb` en Google Colab.
2. Ejecutar las celdas **B1 a B11 en orden** (B1 instala Java 17 y PySpark 3.5.3; B2 monta Google Drive).
3. Los datos se generan con **semilla 42**, por lo que cada ejecución produce los mismos eventos.
4. Los registros quedan en Drive: `SmartRetail_BigData/logs/ejecuciones.csv` y `SmartRetail_BigData/resultados/`.

> Los CSV y Parquet generados (hasta ~500 MB) **no se suben al repositorio**: se regeneran con el cuaderno.

## Resultados principales

| Prueba | Resultado |
|---|---|
| Calidad del ETL | 168 filas rechazadas (81 duplicadas, 44 sin producto, 44 con precio cero), 111 fechas corregidas, reconciliación con diferencia 0 |
| KPI Power BI vs SQL | 6 de 6 idénticos |
| Tiempo de respuesta del dashboard (RNF-03) | Peor caso 0.76 s (meta ≤ 5 s) |
| Escalabilidad Spark | ×50 datos → ×17 tiempo; throughput máximo 97 339 filas/s |
| Partición Parquet | Consulta mensual de 0.52 s a 0.09 s |
| Rastreo de un pedido (RNF-04) | De 1.16 s a 0.14 s tras ordenar por pedido |

## Uso de inteligencia artificial

El equipo utilizó un asistente de IA (Claude, de Anthropic) como apoyo para explicaciones, borradores de código y redacción. Todo el código se ejecutó y validó en SQL Server, Power BI y Colab, y las cifras provienen de las ejecuciones propias del equipo. El detalle está en el apartado 5.7 del informe.

## Licencia

Código bajo licencia MIT (ver `LICENSE`). Los datos son sintéticos y no contienen información personal real.
