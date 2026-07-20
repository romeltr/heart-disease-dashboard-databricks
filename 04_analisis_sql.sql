-- Databricks notebook source
-- MAGIC %md
-- MAGIC # 04 - Análisis SQL
-- MAGIC ## Proyecto Final - Analítica de Datos en Databricks
-- MAGIC **Dataset:** Heart Disease (Cleveland, UCI Machine Learning Repository)
-- MAGIC
-- MAGIC Este notebook contiene el análisis exploratorio realizado mediante consultas SQL sobre la tabla `heart_disease`, generada a partir del dataset limpio (`heart_disease_clean.csv`) producido en el notebook `02_limpieza_datos`.
-- MAGIC
-- MAGIC **Diccionario rápido de columnas:**
-- MAGIC - `age`: edad del paciente
-- MAGIC - `sex`: 1 = hombre, 0 = mujer
-- MAGIC - `cp`: tipo de dolor de pecho (1-4)
-- MAGIC - `trestbps`: presión arterial en reposo
-- MAGIC - `chol`: colesterol sérico
-- MAGIC - `fbs`: azúcar en ayunas > 120 mg/dl (1 = sí, 0 = no)
-- MAGIC - `thalach`: frecuencia cardíaca máxima alcanzada
-- MAGIC - `exang`: angina inducida por ejercicio (1 = sí, 0 = no)
-- MAGIC - `num`: diagnóstico (0 = sin enfermedad, 1-4 = presencia y severidad)

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 0. Verificación de la tabla
-- MAGIC La tabla `heart_disease` debe existir ya desde el notebook `01_ingesta_datos`. Primero se confirma que exista, en vez de asumir una ruta de Volumen que podría no existir en otro workspace.

-- COMMAND ----------

SHOW TABLES LIKE 'heart_disease';

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Solo si la tabla no aparece arriba**, ejecutar esta celda de respaldo (ajustando la ruta al Volumen real del workspace donde se subió el CSV):

-- COMMAND ----------

-- MAGIC %python
-- MAGIC # Ejecutar SOLO si la tabla heart_disease no existe todavía
-- MAGIC # df = spark.read.csv("/Volumes/workspace/default/heart_disease/heart_disease_clean.csv", header=True, inferSchema=True)
-- MAGIC # df.write.mode("overwrite").saveAsTable("heart_disease")

-- COMMAND ----------

SELECT * FROM heart_disease LIMIT 10;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 1. Distribución general de la enfermedad
-- MAGIC Cuenta cuántos pacientes hay en cada nivel de severidad (0 = sin enfermedad, 1-4 = presencia creciente).

-- COMMAND ----------

SELECT num AS nivel_enfermedad, COUNT(*) AS pacientes
FROM heart_disease
GROUP BY num
ORDER BY num;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(completar después de ejecutar: ¿cuántos pacientes sanos vs. cuántos con algún grado de enfermedad?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 2. Promedios clave por presencia/ausencia de enfermedad
-- MAGIC Compara edad, colesterol, presión arterial y frecuencia cardíaca máxima entre pacientes sanos y enfermos.

-- COMMAND ----------

SELECT 
  CASE WHEN num = 0 THEN 'Sin enfermedad' ELSE 'Con enfermedad' END AS diagnostico,
  COUNT(*) AS pacientes,
  ROUND(AVG(age), 1) AS edad_promedio,
  ROUND(AVG(chol), 1) AS colesterol_promedio,
  ROUND(AVG(trestbps), 1) AS presion_promedio,
  ROUND(AVG(thalach), 1) AS frecuencia_max_promedio
FROM heart_disease
GROUP BY CASE WHEN num = 0 THEN 'Sin enfermedad' ELSE 'Con enfermedad' END;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿los pacientes con enfermedad tienden a tener mayor edad/colesterol/presión y menor frecuencia cardíaca máxima?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 3. Riesgo por sexo
-- MAGIC Porcentaje de pacientes con enfermedad cardíaca según sexo.

-- COMMAND ----------

SELECT 
  CASE WHEN sex = 1 THEN 'Hombre' ELSE 'Mujer' END AS sexo,
  COUNT(*) AS total,
  SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) AS con_enfermedad,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_enfermedad
FROM heart_disease
GROUP BY sex;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿qué sexo presenta mayor proporción de enfermedad en este dataset?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 4. Tipo de dolor de pecho vs. severidad de enfermedad
-- MAGIC Relaciona el tipo de dolor de pecho reportado con la severidad promedio del diagnóstico.

-- COMMAND ----------

SELECT cp AS tipo_dolor_pecho,
       COUNT(*) AS pacientes,
       ROUND(AVG(num), 2) AS severidad_promedio,
       ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_enfermedad
FROM heart_disease
GROUP BY cp
ORDER BY severidad_promedio DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿qué tipo de dolor de pecho se asocia a mayor severidad promedio?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 5. Segmentación por rango de edad
-- MAGIC Agrupa pacientes en tres rangos de edad y compara colesterol promedio y presencia de enfermedad.

-- COMMAND ----------

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
ORDER BY 1;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿el riesgo y el colesterol aumentan con la edad, como se esperaría clínicamente?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 6. Pacientes de mayor riesgo (subconsulta + HAVING)
-- MAGIC Filtra combinaciones de sexo y tipo de dolor de pecho con enfermedad confirmada, mostrando solo grupos con más de 5 pacientes.

-- COMMAND ----------

SELECT sex, cp, COUNT(*) AS total, ROUND(AVG(chol), 1) AS chol_promedio
FROM heart_disease
WHERE num > 0
GROUP BY sex, cp
HAVING COUNT(*) > 5
ORDER BY chol_promedio DESC;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿qué combinación de sexo y tipo de dolor de pecho concentra los casos de mayor colesterol entre los enfermos?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 7. Casos extremos por función de ventana
-- MAGIC Usa `RANK()` para identificar, dentro de cada nivel de severidad, a los 3 pacientes con mayor colesterol.

-- COMMAND ----------

SELECT age, chol, trestbps, num,
  RANK() OVER (PARTITION BY num ORDER BY chol DESC) AS ranking_colesterol
FROM heart_disease
QUALIFY ranking_colesterol <= 3;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿los casos extremos de colesterol se concentran en los niveles más severos de enfermedad?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 8. Estadísticas descriptivas del dataset
-- MAGIC **¿Qué aporta esta consulta?** Da un panorama general de rango y dispersión de las variables clínicas antes de compararlas por grupo — típico del análisis exploratorio inicial.

-- COMMAND ----------

SELECT
  MIN(age) AS edad_min, MAX(age) AS edad_max, ROUND(AVG(age),1) AS edad_promedio, ROUND(STDDEV(age),1) AS edad_desviacion,
  MIN(chol) AS chol_min, MAX(chol) AS chol_max, ROUND(AVG(chol),1) AS chol_promedio, ROUND(STDDEV(chol),1) AS chol_desviacion,
  MIN(trestbps) AS presion_min, MAX(trestbps) AS presion_max, ROUND(AVG(trestbps),1) AS presion_promedio, ROUND(STDDEV(trestbps),1) AS presion_desviacion,
  MIN(thalach) AS frecuencia_min, MAX(thalach) AS frecuencia_max, ROUND(AVG(thalach),1) AS frecuencia_promedio, ROUND(STDDEV(thalach),1) AS frecuencia_desviacion
FROM heart_disease;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿qué tan dispersos están los valores? ¿hay variables con rangos muy amplios que valga la pena revisar por outliers?)*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## 9. Categorías de riesgo clínico
-- MAGIC **¿Qué aporta esta consulta?** Transforma dos variables numéricas crudas (colesterol y presión arterial) en categorías de riesgo con significado clínico real, en vez de solo describirlas con promedios. Es la transformación analítica que le da valor de negocio al análisis.

-- COMMAND ----------

-- Riesgo por nivel de colesterol (umbrales clínicos estándar)
SELECT
  CASE
    WHEN chol < 200 THEN 'Normal'
    WHEN chol < 240 THEN 'Límite'
    ELSE 'Alto'
  END AS categoria_colesterol,
  COUNT(*) AS pacientes,
  ROUND(AVG(num), 2) AS severidad_promedio,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_enfermedad
FROM heart_disease
GROUP BY 1
ORDER BY CASE categoria_colesterol WHEN 'Normal' THEN 1 WHEN 'Límite' THEN 2 ELSE 3 END;

-- COMMAND ----------

-- Riesgo por nivel de presión arterial (umbrales clínicos estándar)
SELECT
  CASE
    WHEN trestbps < 120 THEN 'Normal'
    WHEN trestbps < 140 THEN 'Elevada'
    ELSE 'Hipertensión'
  END AS categoria_presion,
  COUNT(*) AS pacientes,
  ROUND(AVG(num), 2) AS severidad_promedio,
  ROUND(100.0 * SUM(CASE WHEN num > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_con_enfermedad
FROM heart_disease
GROUP BY 1
ORDER BY CASE categoria_presion WHEN 'Normal' THEN 1 WHEN 'Elevada' THEN 2 ELSE 3 END;

-- COMMAND ----------

-- MAGIC %md
-- MAGIC **Interpretación:** *(¿el riesgo de enfermedad aumenta claramente al pasar de "Normal" a "Alto"/"Hipertensión"? esto responde directamente a la hipótesis "¿el colesterol y la presión alta se asocian con más enfermedad cardíaca?")*

-- COMMAND ----------

-- MAGIC %md
-- MAGIC ## Conclusiones del análisis SQL
-- MAGIC - *(completar con 3-4 líneas resumiendo los hallazgos principales de las 9 consultas, respondiendo directamente preguntas como: ¿los hombres presentan mayor incidencia? ¿la edad aumenta el riesgo? ¿el colesterol/presión alta se asocian con más enfermedad? Usarlas también en el documento tipo artículo)*