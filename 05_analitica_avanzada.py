# Databricks notebook source
# MAGIC %md
# MAGIC # 05 - Analítica Avanzada: Clasificación
# MAGIC ## Proyecto Final - Analítica de Datos en Databricks
# MAGIC **Dataset:** Heart Disease (Cleveland, UCI)
# MAGIC
# MAGIC Basado en el modelo de Random Forest de la Tarea #3 (notebook `Analisis_Completo_HeartDisease_Clean`),
# MAGIC pero evaluado correctamente con separación entrenamiento/prueba y métricas de clasificación
# MAGIC (requisito de la guía: "análisis avanzado" de clasificación).

# COMMAND ----------

import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import matplotlib.pyplot as plt

RUTA_CSV = "/Volumes/workspace/default/heart_disease/heart_disease_clean.csv"
df = pd.read_csv(RUTA_CSV)
df.head()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Preparación: variables y separación train/test
# MAGIC Se predice `num` (nivel de enfermedad, 0-4) a partir del resto de variables clínicas. 80% entrenamiento,
# MAGIC 20% prueba, con semilla fija para que el resultado sea reproducible.

# COMMAND ----------

X = df.drop(columns=['num'])
y = df['num']

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)
print("Entrenamiento:", X_train.shape, " Prueba:", X_test.shape)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Entrenamiento del modelo

# COMMAND ----------

rf = RandomForestClassifier(random_state=42, n_estimators=200)
rf.fit(X_train, y_train)
y_pred = rf.predict(X_test)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Métricas de evaluación

# COMMAND ----------

print("Accuracy:", round(accuracy_score(y_test, y_pred), 3))
print("\nReporte de clasificación:\n")
print(classification_report(y_test, y_pred))

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Matriz de confusión

# COMMAND ----------

cm = confusion_matrix(y_test, y_pred)
plt.figure(figsize=(6,5))
plt.imshow(cm)
plt.colorbar()
plt.title("Matriz de Confusión - Nivel de Enfermedad (0-4)")
plt.xlabel("Predicción")
plt.ylabel("Real")
for i in range(cm.shape[0]):
    for j in range(cm.shape[1]):
        plt.text(j, i, cm[i, j], ha="center", va="center")
plt.show()

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Importancia de variables

# COMMAND ----------

importance = pd.Series(rf.feature_importances_, index=X.columns).sort_values()
plt.figure(figsize=(8,5))
importance.plot(kind='barh')
plt.title('Importancia de Variables')
plt.show()
display(importance)

# COMMAND ----------

# MAGIC %md
# MAGIC ## Conclusiones
# MAGIC - *(completar con el accuracy real obtenido y las 2-3 variables más importantes según el gráfico anterior)*
# MAGIC - El modelo predice el nivel de severidad (0-4), lo cual es más exigente que una clasificación binaria
# MAGIC   sano/enfermo — es normal que el accuracy no sea muy alto en las clases intermedias (1-3), ya que tienen
# MAGIC   menos ejemplos y son clínicamente más parecidas entre sí.