import os 
import re


import pandas as pd
import numpy as np


import sklearn
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score



modelResults= pd.read_csv("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\model_result_reviewed.csv")


# For Naive Bayes - Count Vector model
y_true = modelResults["Indicator"]
y_pred = modelResults["Naive Bayes - Count Vector"]

accuracy = accuracy_score(y_true, y_pred)
precision = precision_score(y_true, y_pred)
recall = recall_score(y_true, y_pred)
f1 = f1_score(y_true, y_pred)

print(f"Naive Bayes - Count Vector Model:")
print(f"Accuracy: {accuracy}")
print(f"Precision: {precision}")
print(f"Recall: {recall}")
print(f"F1 Score: {f1}")


# For Naive Bayes - TF-IDF model
y_true = modelResults["Indicator"]
y_pred = modelResults["Naive Bayes - TF-IDF"]

accuracy = accuracy_score(y_true, y_pred)
precision = precision_score(y_true, y_pred)
recall = recall_score(y_true, y_pred)
f1 = f1_score(y_true, y_pred)

print(f"Naive Bayes - TF-IDF Model:")
print(f"Accuracy: {accuracy}")
print(f"Precision: {precision}")
print(f"Recall: {recall}")
print(f"F1 Score: {f1}")

# Linear Support Vector Machine - TF-IDF model
y_true = modelResults["Indicator"]
y_pred = modelResults["Linear Support Vector Machine - TF-IDF"]

accuracy = accuracy_score(y_true, y_pred)
precision = precision_score(y_true, y_pred)
recall = recall_score(y_true, y_pred)
f1 = f1_score(y_true, y_pred)

print(f"Linear Support Vector Machine - TF-IDF Model:")
print(f"Accuracy: {accuracy}")
print(f"Precision: {precision}")
print(f"Recall: {recall}")
print(f"F1 Score: {f1}")

# Logistic Regression - TF-IDF model
y_true = modelResults["Indicator"]
y_pred = modelResults["Logistic Regression - TF-IDF"]

accuracy = accuracy_score(y_true, y_pred)
precision = precision_score(y_true, y_pred)
recall = recall_score(y_true, y_pred)
f1 = f1_score(y_true, y_pred)

print(f"Logistic Regression - TF-IDF:")
print(f"Accuracy: {accuracy}")
print(f"Precision: {precision}")
print(f"Recall: {recall}")
print(f"F1 Score: {f1}")