# Identify work-related and non-work related ER visits in SyS data using NLP
# Input data are text of OBX-5 in every HL7 message, separated by "--------------------------".

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


# Check ICD-10 codes

# Load work-related ICD-10 codes
file_k = open("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\keywords_oh.txt", "r")
content_k = file_k.readlines()
key = []
des = []

for i in content_k:
    key.append(i.split("|")[0])
    des.append(i.split("|")[1].replace("\n", ""))
    
icd10 = pd.DataFrame()
icd10["ICD-10"] = key
icd10["Name"] = des


# Check how many reports, work-related and non-work related reports, have ICD-10 codes, and how many codes in one report
icd10_lst = []
reg = re.compile(r"[A-Z]\d{2}\.?[0-9A-Z]{0,3}[ADSX]")

for txt in combined["text"].tolist():
    if re.search(reg, txt) != None:
        icd10_lst.append(re.findall(reg, txt))
    else:
        icd10_lst.append([])

combined["ICD-10 Codes in Text"] = icd10_lst
        
oneIcd = [];
mulIcd = [];
noIcd = [];
for codes in icd10_lst:
    if len(codes) == 0:
        noIcd.append(codes)
    elif len(codes) == 1 or len(set(codes)) == 1: 
        oneIcd.append(codes)
    else:
        mulIcd.append(codes)

print("For all reports:")
print("Number of reports that contain one ICD-10 code (including same code being present multiple times): ", len(oneIcd))
print("Number of reports that contain multiple ICD-10 codes: ", len(mulIcd))
print("Number of reports that contain no ICD-10 code: ", len(noIcd))


print("\nFor reports that have one ICD-10 code:")
oneIcd_re = []
oneIcd_no = []
for codes in oneIcd:
    if codes[0] in icd10["ICD-10"].tolist():
        oneIcd_re.append(codes)
    else:
        oneIcd_no.append(codes)
        
print("Number of reports that contain one work-related ICD-10 code: ", len(oneIcd_re))
print("Number of reports that contain one non-work related ICD-10 code: ", len(oneIcd_no))


print("\nFor reports that have multiple ICD-10 codes:")
allRe = []
allNo = []
mixIcd = []

for codes in mulIcd:
    tmp = []
    for code in codes:
        if code in icd10["ICD-10"].tolist():
            tmp.append(code)
              
    if len(tmp) == len(codes):
        allRe.append(codes)
    elif len(tmp) == 0:
        allNo.append(codes)
    else:
        mixIcd.append(codes)
        
    tmp = []
        
print("Number of reports that contain different ICD-10 codes, all work-related: ", len(allRe))
print("Number of reports that contain different ICD-10 codes, all non-work related: ", len(allNo))
print("Number of reports that contain both work-related and non-work related ICD-10 codes: ", len(mixIcd))


# Plot 

x = ["One code", "Multiple codes", "No code"]
y1 = [len(oneIcd_re), len(allRe), 0]
y2 = [len(oneIcd_no), len(allNo), 0]
y3 = [0, len(mixIcd), 0]
y4 = [0, 0, len(noIcd)]

bottom3 = np.add(y1, y2).tolist()

plt.figure(figsize=(10, 8))
plt.bar(x, y1, color="RosyBrown")
plt.bar(x, y2, color="NavajoWhite", bottom=y1)
plt.bar(x, y3, color="LightCoral", bottom=bottom3)
plt.bar(x, y4, color="lightgrey")

plt.xticks(x, rotation=0, fontsize=12)
plt.yticks(fontsize=12)
plt.xlabel(" ", fontsize=12)
plt.ylabel("Number of reports", fontsize=12)

ax = plt.gca()
ax.set_ylim([0, len(oneIcd)+100])

plt.text(len(x)*0.55, len(oneIcd)-100, "Mixed codes", fontsize=12, bbox=dict(color="LightCoral"))
plt.text(len(x)*0.55, len(oneIcd)-250, "Non-work related codes", fontsize=12, bbox=dict(color="NavajoWhite"))
plt.text(len(x)*0.55, len(oneIcd)-400, "Work-related codes", fontsize=12, bbox=dict(color="RosyBrown"))
plt.text(len(x)*0.55, len(oneIcd)-550, "No code", fontsize=12, bbox=dict(color="lightgrey"))

plt.text(len(x)*0.07, len(oneIcd_re)-70, str(len(oneIcd_re)), fontsize=12)
plt.text(len(x)*0.07, len(oneIcd)-70, str(len(oneIcd_no)), fontsize=12)
plt.text(len(x)*0.42, len(allRe)-50, str(len(allRe)), fontsize=12)
plt.text(len(x)*0.41, len(allRe)+len(allNo)-70, str(len(allNo)), fontsize=12)
plt.text(len(x)*0.41, len(allRe)+len(allNo)+len(mixIcd)-70, str(len(mixIcd)), fontsize=12)

plt.text(-len(x)*0.133, len(oneIcd)+20, str(len(oneIcd)), fontsize=12, weight="bold")
plt.text(len(x)*0.2, len(mulIcd)+20, str(len(mulIcd)), fontsize=12, weight="bold")
plt.text(len(x)*0.53, len(noIcd)+20, str(len(noIcd)), fontsize=12, weight="bold")

plt.show()
