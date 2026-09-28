# Identify work-related and non-work related ER visits in SyS data using NLP
# Input data are discharge Dx codes, CC, Triage notes, clinical impressions, admit reasons, separated by "--------------------------".

import os 
import re

import pyarrow as pa
import pandas as pd
import numpy as np


import matplotlib.pyplot as plt
import matplotlib.patches as patches
import matplotlib.cm as cm

import sklearn
from sklearn.cluster import KMeans
from sklearn.decomposition import PCA
from sklearn.naive_bayes import MultinomialNB, GaussianNB
from sklearn.preprocessing import MultiLabelBinarizer
from sklearn import metrics
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import classification_report
from sklearn.metrics import silhouette_score
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import SGDClassifier
from sklearn.linear_model import LogisticRegression

import nltk 
from nltk.tokenize import word_tokenize
from nltk.tokenize import RegexpTokenizer
from nltk.corpus import stopwords
from nltk.stem import wordnet
from nltk.stem import WordNetLemmatizer 
nltk.download('stopwords')
nltk.download('wordnet')
nltk.download('averaged_perceptron_tagger')
nltk.download('omw-1.4')

################################################
# Functions
################################################

# “PresenceAbsenceVector” model: Converts text to vector using Presence and Absence of Words, and then classify

def PresenceAbsenceVector(token_lst):
    word_set = set()
    vec = []
    for cell in token_lst:
        word_set = word_set.union(set(cell))
    
    for cell in token_lst:
        freq = dict.fromkeys(word_set, 0)
        for word in cell:
            freq[word] = 1
        vec.append(freq)
        
    #print(word_set)
    res = []
    for i in vec:    # convert dict values list to list
        x = []
        for j in i:
            x.append(i[j])
        res.append(x)
        
    return res



# “CountVector” model: Converts text to vector using Count of Words, and then classify
def CountVector(token_lst):
    word_set = set()
    vec = []
    for cell in token_lst:
        word_set = word_set.union(set(cell))
    
    for cell in token_lst:
        freq = dict.fromkeys(word_set, 0)
        for word in cell:
            freq[word] += 1
        vec.append(freq)
    
    #print(word_set)
    res = []
    for i in vec:    # convert dict values list to list
        x = []
        for j in i:
            x.append(i[j])
        res.append(x)
        
    return res



# “TF-IDFVector” model: Converts text to vector using TF-IDF vectorization, and then classify
def TFIDFVector(str_lst):
    tf_vect = TfidfVectorizer(min_df=1, lowercase=True, stop_words="english")
    tf_matrix = tf_vect.fit_transform(str_lst)
    tf_names = tf_vect.get_feature_names_out()
    tf_df = pd.DataFrame(tf_matrix.toarray(), columns=tf_names)
    #print("\n", tf_df)
    
    res = []
    for row in tf_df.index:
        dic = dict.fromkeys(tf_names, 0)
        for col in tf_df: 
            dic[col] = tf_df[col][row]
        res.append(dic)
        
    return res, tf_df



# Provide results based on the prediction
def ConfusionMatrix(test, pred):
    confusion_matrix = metrics.confusion_matrix(test, pred)
    print("Confusion Matrix: ", "\n", confusion_matrix, "\n")
    
    accuracy = metrics.accuracy_score(test, pred)  
    TP = confusion_matrix[0][0]
    FN = confusion_matrix[0][1]
    FP = confusion_matrix[1][0]
    TN = confusion_matrix[1][1]
    TPR = TP / (TP + FN)
    FPR = FP / (FP + TN)
    TNR = TN / (TN + FP)
    PPV = TP / (TP + FP)
    FNR = FN / (FN + TP)
    NER = min(TN + FP, FN + TP) / (TP + TN + FP + FN)
    
    print("Accuracy: (TP + TN) / (P + N) =", accuracy)  
    print("Precision: TP / (TP + FP) =", PPV)
    print("True Positive Rate (Sensitivity): TP / (TP + FN) =", TPR)
    print("True Negative Rate (Specificity): TN / (TN + FP) =", TNR)
    
    print("Misclassification Rate: 1 - Accuracy =", 1-accuracy)
    print("False Positive Rate (false alarm ratio): FP / (FP + TN) =",  FPR)
    print("False Negative Rate (miss rate): FN / (FN + TP) =", FNR)
    print("Null Error Rate: min(TN + FP, FN + TP) / sample size = ", NER)



# Load data and briefly sumarize
os.chdir("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data")

# Load combined data from parquet file
combined = pd.read_parquet("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\sys_er_combined.parquet")

# Preprocess for NLP

# Note:replace NaN values with an empty string to avoid TypeError in Tokenization
txt = combined["text"].fillna("")


# Tokenize
tokenizer = RegexpTokenizer(r'(?u)\W+|\$[\d\.]+|\S+')
tokened = []
for cell in txt:
    tokens = tokenizer.tokenize(cell)
    tokened.append(tokens)

combined["Tokened"] = tokened


# Remove stop words
stop_words = set(stopwords.words("english"))
stop_removed = []
for cell in tokened:
    stop_removed.append([w for w in cell if not w.lower() in stop_words])

combined["Stop Words Removed"] = stop_removed


# Remove punctuations (keep "-")
punc_removed = []
for cell in stop_removed:
    punc_removed.append([w for w in cell if w not in "!\"#$%&'()*+,./:;<=>?@[\\]^_`{|}~" and not w.isspace()])

combined["Punctuations Removed"] = punc_removed


# Assign POS tags
pos = []
for cell in combined["Punctuations Removed"]:
    pos.append(nltk.pos_tag(cell))
    
combined["POS Tags"] = pos


# Lemmatization 
lemmatizer = WordNetLemmatizer()
lemmatized = []
for cell in pos:
    lemm_lst = []
    for tup in cell:
        s = ""
        if tup[1].startswith("N"):
            s = lemmatizer.lemmatize(tup[0], pos="n")
        elif tup[1].startswith("V"):
            s = lemmatizer.lemmatize(tup[0], pos="v")
        elif tup[1].startswith("R"):
            s = lemmatizer.lemmatize(tup[0], pos="r")
        elif tup[1].startswith("J"):
            s = lemmatizer.lemmatize(tup[0], pos="a")
        else:
            s = tup[0]
        lemm_lst.append(s)
    lemmatized.append(lemm_lst)

combined["Lemmatized"] = lemmatized

print(combined)

combined.to_csv("combined.csv")

combined.head()



# Naive Bayes Model 
sent_list = [" ".join(x) for x in combined["Lemmatized"]]


# Count Vector
count_vect = CountVectorizer(lowercase=True, stop_words="english", min_df=2)
X_count_vect = count_vect.fit_transform(sent_list)
X_names = count_vect.get_feature_names_out()
X_count_vect = pd.DataFrame(X_count_vect.toarray(), columns=X_names)

X_train_cv, X_test_cv, y_train_cv, y_test_cv = train_test_split(X_count_vect, combined["Indicator"], test_size=0.2, random_state=5)

df_train_cv = combined.loc[combined.index[y_train_cv.index.values]]
df_test_cv = combined.loc[combined.index[y_test_cv.index.values]]
df_train_cv.to_parquet("train_cv.parquet", index=False)
df_test_cv.to_parquet("test_cv.parquet", index=False)

nb_cv = MultinomialNB()
nb_cv.fit(X_train_cv, y_train_cv)
y_pred_cv = nb_cv.predict(X_test_cv)

report_names = ["Work-related", "Non-work related"]
print("\n-----------------------------------")
print(  "Count Vector Classification Report:")
print(  "-----------------------------------")
print("Accuracy:", accuracy_score(y_pred_cv, y_test_cv), "\n")
print(classification_report(y_test_cv, y_pred_cv, target_names=report_names))

ConfusionMatrix(y_test_cv, y_pred_cv)



# TD-IDF Vector
tf_vect = TfidfVectorizer(min_df=1, lowercase=True, stop_words="english")
tf_matrix = tf_vect.fit_transform(sent_list)
tf_names = tf_vect.get_feature_names_out()
tf_df_vect = pd.DataFrame(tf_matrix.toarray(), columns=tf_names)

X_train_tf, X_test_tf, y_train_tf, y_test_tf = train_test_split(tf_df_vect, combined["Indicator"], test_size=0.2, random_state=5)


nb_tf = MultinomialNB()
nb_tf.fit(X_train_tf, y_train_tf)
y_pred_tf = nb_tf.predict(X_test_tf)


report_names = ["Work-related", "Non-work related"]
print("\n------------------------------------")
print(  "TF_IDF Vector Classification Report:")
print(  "------------------------------------")
print("Accuracy:", accuracy_score(y_pred_tf, y_test_tf), "\n")
print(classification_report(y_test_tf, y_pred_tf, target_names=report_names))

ConfusionMatrix(y_test_tf, y_pred_tf)


#plotting
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 6))
fig.suptitle("Receiver Operating Characteristic", fontsize=16)

fpr_cv, tpr_cv, _ = metrics.roc_curve(y_test_cv, y_pred_cv)
roc_auc_cv = metrics.auc(fpr_cv, tpr_cv)

fpr_tf, tpr_tf, _ = metrics.roc_curve(y_test_tf, y_pred_tf)
roc_auc_tf = metrics.auc(fpr_tf, tpr_tf)

ax1.plot(fpr_cv, tpr_cv, "b", label="AUC="+str(roc_auc_cv))
ax1.plot([0, 1], [0, 1],'r--')
ax1.set_ylabel('True Positive Rate')
ax1.set_xlabel('False Positive Rate')
ax1.legend(loc="best")
ax1.set_title("Count Vector", fontdict={"fontsize": 12})

ax2.plot(fpr_tf, tpr_tf, "b", label="AUC="+str(roc_auc_tf))
ax2.plot([0, 1], [0, 1],'r--')
ax2.set_ylabel('True Positive Rate')
ax2.set_xlabel('False Positive Rate')
ax2.legend(loc="best")
ax2.set_title("TF-IDF Vector", fontdict={"fontsize": 12})

plt.show()

# Linear Support Vector Machine, using a pipline:
# Count Vector => TF_IDF Vector => Classifier

X = [" ".join(x) for x in combined["Lemmatized"]]
y = combined["Indicator"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=5)

sgd = Pipeline([('vect', CountVectorizer()),
                ('tfidf', TfidfTransformer()),
                ('clf', SGDClassifier(loss='hinge', penalty='l2',alpha=1e-3, random_state=42, max_iter=5, tol=None)),
               ])

sgd.fit(X_train, y_train)
y_pred = sgd.predict(X_test)


report_names = ["Work-related", "Non-work related"]

print("\n----------------------------------------------------")
print(  "Linear Support Vector Machine Classification Report:")
print(  "----------------------------------------------------")
print("Accuracy:", accuracy_score(y_pred, y_test))
print(classification_report(y_test, y_pred, target_names=report_names))

ConfusionMatrix(y_test, y_pred)


# Logistic Regression, using a pipline:
# Count Vector => TF_IDF Vector => Classifier

X = [" ".join(x) for x in combined["Lemmatized"]]
y = combined["Indicator"]

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=5)

logreg = Pipeline([('vect', CountVectorizer()),
                ('tfidf', TfidfTransformer()),
                ('clf', LogisticRegression(n_jobs=1, C=1e5, max_iter=10000)),
               ])

logreg.fit(X_train, y_train)
y_pred = logreg.predict(X_test)

report_names = ["Work-related", "Non-work related"]

print("\n------------------------------------------")
print(  "Logistic Regression Classification Report:")
print(  "------------------------------------------")
print("Accuracy:", accuracy_score(y_pred, y_test))
print(classification_report(y_test, y_pred, target_names=report_names))

ConfusionMatrix(y_test, y_pred)
