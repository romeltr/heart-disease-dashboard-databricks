-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 06 - Preparación del Dashboard
-- MAGIC ## Proyecto Final - Analítica de Datos en Databricks
-- MAGIC **Dataset:** Heart Disease (Cleveland, UCI)
-- MAGIC
-- MAGIC Este notebook crea las vistas (VIEWS) que alimentan el dashboard. Cada vista está agregada ya al nivel correcto para su gráfico (una fila por categoría), en vez de dejar filas sueltas por paciente.
-- MAGIC
-- MAGIC **Nota sobre los filtros:** las vistas de este notebook NO incluyen `sex`/`age` sueltos para "enlazar filtros", porque una vista de catálogo (`CREATE VIEW`) no admite parámetros de filtro (`:sex_filter`) — esos solo funcionan dentro del editor de datasets del propio dashboard Lakeview. La forma correcta de filtrar se explica al final de este notebook.

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Indicadores resumen (KPIs)

-- COMMAND ----------

-- Vista única con los 4 KPIs del dashboard
CREATE OR REPLACE VIEW vw_indicadores AS
SELECT 
  COUNT(*) AS total_pacientes,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_enfermedad,
  ROUND(AVG(age), 1) AS edad_promedio,
  ROUND(AVG(chol), 1) AS colesterol_promedio
FROM heart_disease;

-- COMMAND ----------

SELECT * FROM vw_indicadores;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 1: Distribución por nivel de enfermedad
-- MAGIC Corregido: se agrupa solo por `num`, una fila por nivel (0-4).

-- COMMAND ----------

-- Vista para gráfico de distribución por nivel de enfermedad
CREATE OR REPLACE VIEW vw_distribucion_diagnostico AS
SELECT num AS nivel_enfermedad, COUNT(*) AS pacientes
FROM heart_disease
GROUP BY num;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 2: Promedios clínicos por diagnóstico
-- MAGIC Corregido: ahora sí devuelve promedios ya calculados, una fila por diagnóstico.

-- COMMAND ----------

-- Vista para gráfico de promedios clínicos por diagnóstico
CREATE OR REPLACE VIEW vw_promedios_por_diagnostico AS
SELECT 
  CASE WHEN num = 0 THEN 'Sin enfermedad' ELSE 'Con enfermedad' END AS diagnostico,
  ROUND(AVG(age), 1) AS edad_promedio,
  ROUND(AVG(chol), 1) AS colesterol_promedio,
  ROUND(AVG(trestbps), 1) AS presion_promedio,
  ROUND(AVG(thalach), 1) AS frecuencia_max_promedio
FROM heart_disease
GROUP BY CASE WHEN num = 0 THEN 'Sin enfermedad' ELSE 'Con enfermedad' END;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 3: Riesgo por sexo
-- MAGIC Corregido: `GROUP BY sex` únicamente (antes incluía `age`, lo cual rompía el cálculo del porcentaje).

-- COMMAND ----------

-- Vista para gráfico de riesgo por sexo
CREATE OR REPLACE VIEW vw_riesgo_por_sexo AS
SELECT 
  CASE WHEN sex = 1 THEN 'Hombre' ELSE 'Mujer' END AS sexo,
  COUNT(*) AS total,
  SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) AS con_enfermedad,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_enfermedad
FROM heart_disease
GROUP BY sex;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 4: Tipo de dolor de pecho vs. severidad
-- MAGIC Se traduce el código `cp` (1-4) a texto descriptivo, para que un usuario no técnico entienda el gráfico sin necesitar el diccionario de columnas.

-- COMMAND ----------

-- Vista para gráfico de tipo de dolor de pecho vs severidad de diagnóstico
CREATE OR REPLACE VIEW vw_dolor_pecho_severidad AS
SELECT 
  CASE cp
    WHEN 1 THEN 'Angina típica'
    WHEN 2 THEN 'Angina atípica'
    WHEN 3 THEN 'Dolor no anginoso'
    ELSE 'Asintomático'
  END AS tipo_dolor_pecho,
  COUNT(*) AS pacientes,
  ROUND(AVG(num), 2) AS severidad_promedio
FROM heart_disease
GROUP BY cp;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 5: Colesterol y enfermedad por grupo de edad

-- COMMAND ----------

-- Vista para gráfico de colesterol/enfermedad por grupo de edad
CREATE OR REPLACE VIEW vw_edad_grupo AS
SELECT 
  CASE 
    WHEN age < 45 THEN '<45'
    WHEN age BETWEEN 45 AND 59 THEN '45-59'
    ELSE '60+'
  END AS grupo_edad,
  COUNT(*) AS pacientes,
  ROUND(AVG(chol), 1) AS colesterol_promedio,
  SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) AS con_enfermedad
FROM heart_disease
GROUP BY 1
ORDER BY CASE grupo_edad WHEN '<45' THEN 1 WHEN '45-59' THEN 2 ELSE 3 END;

-- COMMAND ----------

SELECT * FROM vw_edad_grupo;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 6: Riesgo por nivel de colesterol
-- MAGIC **Nueva vista** (transforma la variable cruda `chol` en una categoría de riesgo clínico, en vez de solo mostrar el promedio).

-- COMMAND ----------

-- Vista para gráfico de riesgo por categoría de colesterol
CREATE OR REPLACE VIEW vw_riesgo_colesterol AS
SELECT
  CASE
    WHEN chol < 200 THEN 'Normal'
    WHEN chol < 240 THEN 'Límite'
    ELSE 'Alto'
  END AS categoria_colesterol,
  COUNT(*) AS pacientes,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_enfermedad
FROM heart_disease
GROUP BY 1
ORDER BY CASE categoria_colesterol WHEN 'Normal' THEN 1 WHEN 'Límite' THEN 2 ELSE 3 END;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Gráfico 7: Riesgo por nivel de presión arterial
-- MAGIC **Nueva vista** (misma lógica, aplicada a `trestbps`).

-- COMMAND ----------

-- Vista para gráfico de riesgo por categoría de presión arterial
CREATE OR REPLACE VIEW vw_riesgo_presion AS
SELECT
  CASE
    WHEN trestbps < 120 THEN 'Normal'
    WHEN trestbps < 140 THEN 'Elevada'
    ELSE 'Hipertensión'
  END AS categoria_presion,
  COUNT(*) AS pacientes,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_enfermedad
FROM heart_disease
GROUP BY 1
ORDER BY CASE categoria_presion WHEN 'Normal' THEN 1 WHEN 'Elevada' THEN 2 ELSE 3 END;