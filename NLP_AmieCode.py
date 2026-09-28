# Identify reportable and non-reportable electronic pathology reports in HL7 format using NLP
# Input data are text of OBX-5 in every HL7 message, separated by "--------------------------".

import os 
import re

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


# Load reprtable data 
file_r = open("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\txt_reportable.txt", "r")
content_r = file_r.read().split("-=-=-=-=-=-=-=-=-=-=-=-=-=-")
text_r = []

for t in content_r:
    if len(t.strip()) != 0:
        t = t.replace("\n", " ").replace("\t", " ").strip()
        text_r.append(t)

print("Number of reportable reports:", len(text_r))
reportable = pd.DataFrame(text_r, columns=["Text"])



# Load non-reprtable data 
file_n = open("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\txt_non-reportable.txt", "r")
content_n = file_n.read().split("-=-=-=-=-=-=-=-=-=-=-=-=-=-")
text_n = []

for t in content_n:
    if len(t.strip()) != 0:
        t = t.replace("\n", " ").replace("\t", " ").strip()
        text_n.append(t)

print("Number of non-reportable reports:", len(text_n))
nonReportable = pd.DataFrame(text_n, columns=["Text"])



# Combine both reportable and non-reportable text
combined = pd.concat([reportable, nonReportable])

indicator_r = [1] * len(text_r)
indicator_n = [0] * len(text_n)

combined["Indicator"] = indicator_r + indicator_n



# Facility breakdown:

# In combined reportable file: 
#       1 -  443 are from Plab (443)
#     444 - 2519 are from PMS (2076)
#    2520 - 3176 are from Poplar (657)
#    3177 - 3188 are from Quest (12)

# In combined non-reportable file:
#       1 -  279 are from Plab (279)
#     280 -  325 are from PMS (46)
#     326 - 1103 are from Poplar (778)
#    1104 - 1107 are from Quest (4)

re_fac = ["plab"] * 443 + ["pms"] * 2076 + ["poplar"] * 657 + ["quest"] * 12
no_fac = ["plab"] * 279 + ["pms"] * 46   + ["poplar"] * 778 + ["quest"] * 4
combined["Facility"] = re_fac + no_fac

combined

# Check ICD-10 codes

# Load reportable ICD-10 codes
file_k = open("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\keywords.txt", "r")
content_k = file_k.readlines()
key = []
des = []

for i in content_k:
    key.append(i.split("|")[0])
    des.append(i.split("|")[1].replace("\n", ""))
    
icd10 = pd.DataFrame()
icd10["ICD-10"] = key
icd10["Name"] = des


# Check how many reports, reportable and non-reportable reports, have ICD-10 codes, and how many codes in one report
icd10_lst = []
reg = re.compile(r"[A-Z]{1}\d{2}\.[0-9A-Z]{1,3}")

for txt in combined["Text"].tolist():
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
        
print("Number of reports that contain one reportable ICD-10 code: ", len(oneIcd_re))
print("Number of reports that contain one non-reportable ICD-10 code: ", len(oneIcd_no))


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
        
print("Number of reports that contain different ICD-10 codes, all reportable: ", len(allRe))
print("Number of reports that contain different ICD-10 codes, all non-reportable: ", len(allNo))
print("Number of reports that contain both reportable and non-reportable ICD-10 codes: ", len(mixIcd))



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
plt.text(len(x)*0.55, len(oneIcd)-250, "Non-reportable codes", fontsize=12, bbox=dict(color="NavajoWhite"))
plt.text(len(x)*0.55, len(oneIcd)-400, "Reportable codes", fontsize=12, bbox=dict(color="RosyBrown"))
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

# Check reportable ICD-10 codes for all facilities 

print("\n***********************************\nCheck ICD-10 codes for all facilities:\n")

codeStatus = []
for lst in combined["ICD-10 Codes in Text"]:
    if len(lst) == 0:
        codeStatus.append(-1)
    elif any([icd for icd in icd10["ICD-10"] if icd in lst]):
        codeStatus.append(1)
    else:
        codeStatus.append(0)

combined["ICD-10 Code Indicator"] = codeStatus
combined.to_csv("\\\\fs1.hhss.local\\edv\\SYS NLP\\Data\\combined.csv")

combined_with_codes = combined[combined["ICD-10 Code Indicator"] != -1]

tn, fp, fn, tp = confusion_matrix(combined_with_codes["Indicator"], combined_with_codes["ICD-10 Code Indicator"]).ravel()
print(tn, fp, fn, tp, "\n")

cm_all = confusion_matrix(combined_with_codes["Indicator"], combined_with_codes["ICD-10 Code Indicator"])
print(cm_all, "\n")

sensitivity = tp / (tp + fn)
specificity = tn / (tn + fp)
print("Sensitivity:", sensitivity)
print("Specificity:", specificity)

report_names = ["Reportable", "Non-reportable"]
print("\n--------------------------\nClassification Report:\n--------------------------")
print(classification_report(combined_with_codes["Indicator"], combined_with_codes["ICD-10 Code Indicator"], target_names=report_names))

# Check reportable ICD-10 codes for Plab

print("\n***********************************\nCheck ICD-10 codes for Plab:")
combined_plab = combined[combined["Facility"] == "plab"]
print(len(combined_plab), "reports in total.")

combined_with_codes_plab = combined_plab[combined_plab["ICD-10 Code Indicator"] != -1]
print(len(combined_with_codes_plab), "reports have ICD-10 codes.")

tn, fp, fn, tp = confusion_matrix(combined_with_codes_plab["Indicator"], combined_with_codes_plab["ICD-10 Code Indicator"]).ravel()
cm_plab = confusion_matrix(combined_with_codes_plab["Indicator"], combined_with_codes_plab["ICD-10 Code Indicator"])
print("\nConfusion Matrix:\n", cm_plab, "\n")

sensitivity = tp / (tp + fn)
specificity = tn / (tn + fp)
print("Sensitivity:", sensitivity)
print("Specificity:", specificity)

report_names = ["Reportable", "Non-reportable"]
print("\n--------------------------\nClassification Report:\n--------------------------")
print(classification_report(combined_with_codes_plab["Indicator"], combined_with_codes_plab["ICD-10 Code Indicator"], target_names=report_names))


x = combined_plab[combined_plab["ICD-10 Code Indicator"] == 1]
y = x[x["Indicator"] == 0]
y.to_csv("plab_error.csv")


# Check reportable ICD-10 codes for PMS

print("\n***********************************\nCheck ICD-10 codes for PMS:")
combined_pms = combined[combined["Facility"] == "pms"]
print(len(combined_pms), "reports in total.")

combined_with_codes_pms = combined_pms[combined_pms["ICD-10 Code Indicator"] != -1]
print(len(combined_with_codes_pms), "reports have ICD-10 codes.")

tn, fp, fn, tp = confusion_matrix(combined_with_codes_pms["Indicator"], combined_with_codes_pms["ICD-10 Code Indicator"]).ravel()
cm_pms = confusion_matrix(combined_with_codes_pms["Indicator"], combined_with_codes_pms["ICD-10 Code Indicator"])
print("\nConfusion Matrix:\n", cm_pms, "\n")

sensitivity = tp / (tp + fn)
specificity = tn / (tn + fp)
print("Sensitivity:", sensitivity)
print("Specificity:", specificity)

report_names = ["Reportable", "Non-reportable"]
print("\n--------------------------\nClassification Report:\n--------------------------")
print(classification_report(combined_with_codes_pms["Indicator"], combined_with_codes_pms["ICD-10 Code Indicator"], target_names=report_names))

x = combined_pms[combined_pms["ICD-10 Code Indicator"] == 1]
y = x[x["Indicator"] == 0]
y.to_csv("pms_error.csv")

# Check reportable ICD-10 codes for Poplar

print("\n***********************************\nCheck ICD-10 codes for Poplar:")
combined_poplar = combined[combined["Facility"] == "poplar"]
print(len(combined_poplar), "reports in total.")

combined_with_codes_poplar = combined_poplar[combined_poplar["ICD-10 Code Indicator"] != -1]
print(len(combined_with_codes_poplar), "reports have ICD-10 codes.")

tn, fp, fn, tp = confusion_matrix(combined_with_codes_poplar["Indicator"], combined_with_codes_poplar["ICD-10 Code Indicator"]).ravel()
cm_poplar = confusion_matrix(combined_with_codes_poplar["Indicator"], combined_with_codes_poplar["ICD-10 Code Indicator"])
print("\nConfusion Matrix:\n", cm_poplar, "\n")

sensitivity = tp / (tp + fn)
specificity = tn / (tn + fp)
print("Sensitivity:", sensitivity)
print("Specificity:", specificity)

report_names = ["Reportable", "Non-reportable"]
print("\n--------------------------\nClassification Report:\n--------------------------")
print(classification_report(combined_with_codes_poplar["Indicator"], combined_with_codes_poplar["ICD-10 Code Indicator"], target_names=report_names))

x = combined_poplar[combined_poplar["ICD-10 Code Indicator"] == 1]
y = x[x["Indicator"] == 0]
y.to_csv("poplar_error.csv")

# Check reportable ICD-10 codes for Quest

print("\n***********************************\nCheck ICD-10 codes for Quest:")
combined_quest = combined[combined["Facility"] == "quest"]
print(len(combined_quest), "reports in total.")

combined_with_codes_quest = combined_quest[combined_quest["ICD-10 Code Indicator"] != -1]
print(len(combined_with_codes_quest), "reports have ICD-10 codes.")


# Preprocess for NLP

txt = combined["Text"]


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
df_train_cv.to_csv("train_cv.csv")   
df_test_cv.to_csv("test_cv.csv")

nb_cv = MultinomialNB()
nb_cv.fit(X_train_cv, y_train_cv)
y_pred_cv = nb_cv.predict(X_test_cv)

report_names = ["Reportable", "Non-reportable"]
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

#df_train_tf = combined.loc[combined.index[y_train_tf.index.values]]
#df_test_tf = combined.loc[combined.index[y_test_tf.index.values]]
#df_train_tf.to_csv("train_tf.csv")   
#df_test_tf.to_csv("test_tf.csv")

nb_tf = MultinomialNB()
nb_tf.fit(X_train_tf, y_train_tf)
y_pred_tf = nb_tf.predict(X_test_tf)


report_names = ["Reportable", "Non-reportable"]
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

ConfusionMatrix(y_test_tf, y_pred_tf)

report_names = ["Reportable", "Non-reportable"]
print("Accuracy:", accuracy_score(y_pred, y_test))
print("\n----------------------------------------------------")
print(  "Linear Support Vector Machine Classification Report:")
print(  "----------------------------------------------------")
print(classification_report(y_test, y_pred, target_names=report_names))

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

ConfusionMatrix(y_test_tf, y_pred_tf)

report_names = ["Reportable", "Non-reportable"]
print("Accuracy:", accuracy_score(y_pred, y_test))
print("\n------------------------------------------")
print(  "Logistic Regression Classification Report:")
print(  "------------------------------------------")
print(classification_report(y_test, y_pred, target_names=report_names))
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
fte_colors = {0: "#008fd5", 1: "#fc4f30",}

ax1.set_title(f"Presence Absence Vector\nSilhouette: {round(score_PAV,3)}", fontdict={"fontsize": 12})
ax2.set_title(f"Count Vector\nSilhouette: {round(score_CV,3)}", fontdict={"fontsize": 12})
ax3.set_title(f"TF-IDF Vector\nSilhouette: {round(score_TFIDF,3)}", fontdict={"fontsize": 12})

pca_PAV = PCA(n_components=2).fit(PAV)
pca_CV = PCA(n_components=2).fit(CV)
pca_TFIDF = PCA(n_components=2).fit(TFIDF)

data2D_PAV = pca_PAV.transform(PAV)
data2D_CV = pca_CV.transform(CV)
data2D_TFIDF = pca_TFIDF.transform(TFIDF)

ax1.scatter(data2D_PAV[:, 0], data2D_PAV[:, 1], marker=".", c="k")
ax2.scatter(data2D_CV[:, 0], data2D_CV[:, 1], marker=".", c="k")
ax3.scatter(data2D_TFIDF[:, 0], data2D_TFIDF[:, 1], marker=".", c="k")

center_PAV = pca_PAV.transform(kmeans_PAV.cluster_centers_)
center_CV = pca_CV.transform(kmeans_CV.cluster_centers_)
center_TFIDF = pca_TFIDF.transform(kmeans_TFIDF.cluster_centers_)

ax1.scatter(center_PAV[:, 0], center_PAV[:, 1], marker="x", s=200, linewidths=3, c="r")
ax2.scatter(center_CV[:, 0], center_CV[:, 1], marker="x", s=200, linewidths=3, c="r")
ax3.scatter(center_TFIDF[:, 0], center_TFIDF[:, 1], marker="x", s=200, linewidths=3, c="r")

plt.show()

