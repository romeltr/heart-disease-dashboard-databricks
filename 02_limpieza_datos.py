# Databricks notebook source
# MAGIC %md
# MAGIC # 02 - Limpieza y Normalización de Datos
# MAGIC ## Proyecto Final - Analítica de Datos en Databricks
# MAGIC **Dataset:** Heart Disease (Cleveland, UCI)
# MAGIC
# MAGIC Reutilizado del notebook `Normalizacion_y_LimpiezadeDatos_v2` de la Tarea #3, adaptado para correr en
# MAGIC Databricks (rutas de archivo vía Volumen en vez de disco local).

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Carga de datos
# MAGIC Subir `heart+disease.zip` (dataset original de UCI) al mismo Volumen usado en el notebook 01.

# COMMAND ----------

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from zipfile import ZipFile
from sklearn.preprocessing import StandardScaler, MinMaxScaler

RUTA_ZIP = "/Volumes/workspace/default/heart_disease/heart+disease.zip"

cols = ['age','sex','cp','trestbps','chol','fbs','restecg','thalach','exang','oldpeak','slope','ca','thal','num']
with ZipFile(RUTA_ZIP) as z:
    df = pd.read_csv(z.open('processed.cleveland.data'), header=None, names=cols, na_values='?')
df.head()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Valores faltantes

# COMMAND ----------

print(df.isnull().sum())
missing = df.isnull().sum()
missing[missing > 0].plot(kind='bar')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Imputación por mediana
# MAGIC Se eligió la mediana (en vez de la media) porque es más robusta ante valores atípicos en variables
# MAGIC clínicas como colesterol o presión arterial.

# COMMAND ----------

df_imputed = df.fillna(df.median(numeric_only=True))
print(df_imputed.isnull().sum())
df_imputed.head()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Forward y Backward Fill
# MAGIC Se prueban también como alternativa de imputación, aunque el dataset final usa la imputación por mediana.

# COMMAND ----------

df_ffill = df.ffill()
df_bfill = df.bfill()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Normalización

# COMMAND ----------

df_std = pd.DataFrame(StandardScaler().fit_transform(df_imputed), columns=df_imputed.columns)
df_minmax = pd.DataFrame(MinMaxScaler().fit_transform(df_imputed), columns=df_imputed.columns)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Comparación de escalado

# COMMAND ----------

plt.plot(df_imputed['chol'], label='Limpio')
plt.plot(df_std['chol'], label='Standard')
plt.plot(df_minmax['chol'], label='MinMax')
plt.legend(); plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 7. Exportación de datasets
# MAGIC Se guarda en el mismo Volumen para que el notebook 01 (ingesta a tabla Spark) y el 03 (análisis exploratorio)
# MAGIC lo consuman directamente.

# COMMAND ----------

RUTA_SALIDA = "/Volumes/workspace/default/heart_disease/"

df.to_csv(RUTA_SALIDA + "heart_disease_original.csv", index=False)
df_imputed.to_csv(RUTA_SALIDA + "heart_disease_clean.csv", index=False)
df_std.to_csv(RUTA_SALIDA + "heart_disease_normalized.csv", index=False)
print("CSV generados correctamente")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 8. Verificación

# COMMAND ----------

verificacion = pd.read_csv(RUTA_SALIDA + "heart_disease_clean.csv")
print(verificacion.isnull().sum())
verificacion.head()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Conclusión
# MAGIC El dataset queda sin valores nulos (imputados por mediana) y listo en `heart_disease_clean.csv`
# MAGIC para que el notebook `01_ingesta_datos` lo cargue como tabla Spark.