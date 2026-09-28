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
combined.to_parquet("combined.parquet", index=False)



# Cluster analyzing 
# Presence Absence Vector
PAV = PresenceAbsenceVector(combined["Lemmatized"])
kmeans_PAV = KMeans(n_clusters=2, random_state=0, n_init='auto').fit(PAV)
combined["Presence Absence Vector"] = kmeans_PAV.labels_
score_PAV = silhouette_score(PAV, kmeans_PAV.labels_, metric='euclidean')



# Count Vector
CV = CountVector(combined["Lemmatized"])
kmeans_CV = KMeans(n_clusters=2, random_state=0, n_init='auto').fit(CV)
score_CV = silhouette_score(CV, kmeans_CV.labels_, metric='euclidean')



# TF-IDF Vector
str_lst = [" ".join(x) for x in combined["Lemmatized"]]
TFIDF_dic, TFIDF = TFIDFVector(str_lst)
kmeans_TFIDF = KMeans(n_clusters=2, random_state=0, n_init='auto').fit(TFIDF)
score_TFIDF = silhouette_score(TFIDF, kmeans_TFIDF.labels_, metric='euclidean')



# Plotting 
fig, (ax1, ax2, ax3) = plt.subplots(1, 3, figsize=(20, 10))
fig.suptitle("k-means Clustering with 3 Vectorization Methods", fontsize=16)
fte_colors = {0: "#008fd5", 1: "#f08080"} 

ax1.set_title(f"Presence Absence Vector\nSilhouette: {round(score_PAV,3)}", fontdict={"fontsize": 12})
ax2.set_title(f"Count Vector\nSilhouette: {round(score_CV,3)}", fontdict={"fontsize": 12})
ax3.set_title(f"TF-IDF Vector\nSilhouette: {round(score_TFIDF,3)}", fontdict={"fontsize": 12})

pca_PAV = PCA(n_components=2).fit(PAV)
pca_CV = PCA(n_components=2).fit(CV)
pca_TFIDF = PCA(n_components=2).fit(TFIDF)

data2D_PAV = pca_PAV.transform(PAV)
data2D_CV = pca_CV.transform(CV)
data2D_TFIDF = pca_TFIDF.transform(TFIDF)

# use fte_colors for coloring based on cluster labels
ax1.scatter(data2D_PAV[:, 0], data2D_PAV[:, 1], marker=".", c=[fte_colors[label] for label in kmeans_PAV.labels_])
ax2.scatter(data2D_CV[:, 0], data2D_CV[:, 1], marker=".", c=[fte_colors[label] for label in kmeans_CV.labels_])
ax3.scatter(data2D_TFIDF[:, 0], data2D_TFIDF[:, 1], marker=".", c=[fte_colors[label] for label in kmeans_TFIDF.labels_])

center_PAV = pca_PAV.transform(kmeans_PAV.cluster_centers_)
center_CV = pca_CV.transform(kmeans_CV.cluster_centers_)
center_TFIDF = pca_TFIDF.transform(kmeans_TFIDF.cluster_centers_)

ax1.scatter(center_PAV[:, 0], center_PAV[:, 1], marker="x", s=200, linewidths=3, c="k")
ax2.scatter(center_CV[:, 0], center_CV[:, 1], marker="x", s=200, linewidths=3, c="k")
ax3.scatter(center_TFIDF[:, 0], center_TFIDF[:, 1], marker="x", s=200, linewidths=3, c="k")

plt.show()