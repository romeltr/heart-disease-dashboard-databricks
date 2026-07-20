# Databricks notebook source
# MAGIC %md
# MAGIC # 03 - Análisis Exploratorio
# MAGIC ## Proyecto Final - Analítica de Datos en Databricks
# MAGIC **Dataset:** Heart Disease (Cleveland, UCI)
# MAGIC
# MAGIC Reutilizado del notebook `Analisis_Completo_HeartDisease_Clean` de la Tarea #3.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Carga de librerías y dataset

# COMMAND ----------

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.ensemble import RandomForestClassifier

RUTA_CSV = "/Volumes/workspace/default/heart_disease/heart_disease_clean.csv"
df = pd.read_csv(RUTA_CSV)
print('Dimensiones:', df.shape)
df.head()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Información general del dataset

# COMMAND ----------

print(df.info())
print('\nResumen estadístico')
display(df.describe())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Verificación de valores faltantes
# MAGIC Confirmación de que el dataset está completamente limpio.

# COMMAND ----------

print(df.isnull().sum())

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Distribución de la variable objetivo

# COMMAND ----------

plt.figure(figsize=(6,4))
df['num'].value_counts().sort_index().plot(kind='bar')
plt.title('Distribución de enfermedad cardíaca')
plt.xlabel('Nivel de enfermedad')
plt.ylabel('Cantidad')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Edad vs Frecuencia Cardíaca Máxima

# COMMAND ----------

plt.figure(figsize=(8,5))
plt.scatter(df['age'], df['thalach'], c=df['num'])
plt.xlabel('Edad')
plt.ylabel('Frecuencia Cardíaca Máxima')
plt.title('Edad vs Thalach')
plt.colorbar(label='Nivel Enfermedad')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Colesterol vs Presión Arterial

# COMMAND ----------

plt.figure(figsize=(8,5))
plt.scatter(df['chol'], df['trestbps'], s=df['age']*2, c=df['num'])
plt.xlabel('Colesterol')
plt.ylabel('Presión Arterial')
plt.title('Colesterol vs Presión Arterial')
plt.colorbar(label='Enfermedad')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 7. Edad, Colesterol y Enfermedad

# COMMAND ----------

plt.figure(figsize=(8,5))
plt.scatter(df['age'], df['chol'], c=df['num'])
plt.xlabel('Edad')
plt.ylabel('Colesterol')
plt.title('Edad vs Colesterol')
plt.colorbar(label='Enfermedad')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 8. Matriz de correlaciones

# COMMAND ----------

corr = df.corr(numeric_only=True)
plt.figure(figsize=(10,8))
plt.imshow(corr)
plt.colorbar()
plt.xticks(range(len(corr.columns)), corr.columns, rotation=90)
plt.yticks(range(len(corr.columns)), corr.columns)
plt.title('Matriz de Correlación')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 9. PCA Multivariable

# COMMAND ----------

X = df.drop(columns=['num'])
X_scaled = StandardScaler().fit_transform(X)

pca = PCA(n_components=2)
comp = pca.fit_transform(X_scaled)

plt.figure(figsize=(8,5))
plt.scatter(comp[:,0], comp[:,1], c=df['num'])
plt.xlabel('PCA 1')
plt.ylabel('PCA 2')
plt.title('Proyección PCA')
plt.colorbar(label='Enfermedad')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 10. Importancia de variables

# COMMAND ----------

X = df.drop(columns=['num'])
y = df['num']

rf = RandomForestClassifier(random_state=42)
rf.fit(X, y)

importance = pd.Series(rf.feature_importances_, index=X.columns).sort_values()

plt.figure(figsize=(8,5))
importance.plot(kind='barh')
plt.title('Importancia de Variables')
plt.show()

display(importance)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 11. Frecuencia cardíaca por tipo de dolor de pecho

# COMMAND ----------

agrupado = df.groupby('cp')['thalach'].mean()

plt.figure(figsize=(7,4))
agrupado.plot(kind='bar')
plt.title('Frecuencia Cardíaca Promedio por Tipo de Dolor')
plt.ylabel('Thalach Promedio')
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## Conclusiones
# MAGIC - Dataset libre de valores nulos.
# MAGIC - Relaciones relevantes entre edad, colesterol y enfermedad.
# MAGIC - PCA permite observar agrupaciones según nivel de enfermedad.
# MAGIC - Random Forest identifica `thalach`, `cp`, `oldpeak` y `ca` como variables más influyentes (ver notebook 05 para el modelo evaluado formalmente).