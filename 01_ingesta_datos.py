# Databricks notebook source
# MAGIC %md
# MAGIC # 01 - Ingesta de Datos
# MAGIC ## Proyecto Final - Analítica de Datos en Databricks
# MAGIC **Dataset:** Heart Disease (Cleveland, UCI Machine Learning Repository)
# MAGIC
# MAGIC Este notebook carga el CSV limpio (`heart_disease_clean.csv`, generado en el notebook `02_limpieza_datos`
# MAGIC a partir del dataset original de la Tarea #3) y lo registra como tabla para que el resto de notebooks
# MAGIC (SQL, análisis exploratorio, modelo y dashboard) lo usen.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Subir el archivo
# MAGIC Antes de correr esta celda: en el panel izquierdo ir a **Catalog → Create → Volume** (o usar un Volumen ya
# MAGIC existente), y subir ahí `heart_disease_clean.csv`. Ajustar la ruta de abajo a donde quedó guardado.

# COMMAND ----------

RUTA_CSV = "/Volumes/workspace/default/heart_disease/heart_disease_clean.csv"

df = spark.read.csv(RUTA_CSV, header=True, inferSchema=True)
display(df.limit(10))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Verificar esquema y conteo

# COMMAND ----------

df.printSchema()
print("Total de registros:", df.count())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Registrar como tabla
# MAGIC Esta tabla (`heart_disease`) es la que usan los notebooks 04 (SQL), 06 (dashboard) y las vistas del dashboard.

# COMMAND ----------

df.write.mode("overwrite").saveAsTable("heart_disease")

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM heart_disease LIMIT 10;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Conclusión
# MAGIC La tabla `heart_disease` queda disponible para el resto del proyecto. Si esta celda de escritura ya se ejecutó
# MAGIC una vez, los notebooks 04 y 06 pueden simplemente hacer `SHOW TABLES` para confirmar que existe, sin
# MAGIC necesidad de repetir la carga.