import numpy as np
import sklearn.metrics as metr
import matplotlib.pyplot as plt
import tikzplotlib as tikz
import pandas as pd
import xgboost
import shap
import pickle
import copy
from datetime import datetime
from plotting import plotblandaltman

# BUG: https://stackoverflow.com/questions/68257249/why-are-shap-values-changing-every-time-i-call-shap-plots-beeswarm

# TODO: in Matlab (trainData) --> add option to only create sets, but not train models
# TODO: iterate over more models, i.e. desired predictor combinations
# --> make desiredPredictors a list of lists
# --> make target list of lists
# compute all combinations for all algorithms
# create option to create train test split instead of loading them from matlab
# make it possible to add results later on?

# TODO: write script to show results in a nice way

# multiple combinations of features should not change shapley values dratically...

# TODO: make other plots besides force plot and comment on their benefits

# TODO: consider LIME for actual prediction model?

# TODO: test tree explainer --> with 5 features same as normal explainer

# TODO: calculate shap feature importance

# TODO: in paper show summary plot?

# TODO: option to use all features

# TODO: one hot to  dummy coding

# TODO: write one csv evalResults with all information

# TODO: include bland altman plots here (is there a python-tex package?)

# TODO: include k fold corss validation --> only ro give meand score and std or really train and test model multiple times? makes more sense...
# only relevant when doing hyper parameter optimization?

# setup
measureTime = True
calcShap = True
loadModel = True
calcEval = True
# use PPGI data
includePPGI = True
# define relevant dataset
datasetBase = 'dataTables/'
# define split of data
dataSplit = ['interSubject','intraSubject']
# define relevant models
models = ['GammaGaussian2generic','Gamma3generic','Gaussian2generic','Gaussian3generic']
# define predictors to be used
#desiredPredictors = ['Sex_w','Age','P1','P2','T1','T2','b_a'] 
#desiredPredictors = ['Sex_w','Age','P1','P2','T1','T2','W1','W2','b_a','SD','kurt','skew','freq1','freq2','freq3','freq4'] 
desiredPredictors = ['P1','P2','T1','T2','W1','W2','b_a','SD','kurt','skew','freq1','freq2','freq3','freq4','PulseWidth'] 
# define predictors to be used
desiredTargetList = ['SBP']
# define list if evaluation dicts
evalList = list()


for _,currentDataSplit in enumerate(dataSplit):
    print(currentDataSplit)
    for _,currentModel in enumerate(models):
        print(currentModel)
        if measureTime:
            now = datetime.now()
            currentTime = now.strftime("%H:%M:%S")
            print('Time of start = ',currentTime)
        # import matlab data (csv files)
        if includePPGI:
            dataset = datasetBase+'CPTFULL_PPG_BPSUBSET_withPPGI/modelsMIX/'
        else:
            dataset = datasetBase+'CPTFULL_PPG_BPSUBSET_withoutPPGI/modelsMIX/'
        filepath = dataset+currentDataSplit+'/'+currentModel+'/'
        train = pd.read_csv(filepath+'trainTable.csv', sep = ',')
        test = pd.read_csv(filepath+'testTable.csv', sep = ',')
        
        # convert some columns to certain types
        train.Sex = train.Sex.astype('category')
        train = pd.concat([train,pd.get_dummies(train['Sex'], prefix='Sex',drop_first=True)],axis=1)
        train.drop(['Sex'],axis=1, inplace=True)
        test.Sex = test.Sex.astype('category')
        test = pd.concat([test,pd.get_dummies(test['Sex'], prefix='Sex',drop_first=True)],axis=1)
        test.drop(['Sex'],axis=1, inplace=True)
        
        # extract relevant features as input array
        trainPredictors = train[train.columns.intersection(desiredPredictors)]
        testPredictors = test[train.columns.intersection(desiredPredictors)]
        
        # extract result vector (BP)
        trainTarget = np.ravel(train[train.columns.intersection(desiredTargetList)].to_numpy())
        testTarget = np.ravel(test[train.columns.intersection(desiredTargetList)].to_numpy())
        
        modelFilePath = filepath+'regrModel.sav'
        if not loadModel:
            regrModel = xgboost.XGBRegressor().fit(trainPredictors,trainTarget)
            # https://stats.stackexchange.com/questions/457483/sample-weights-in-xgbclassifier
            # use sample_weight option to emphasize specific subjects with less common BP values
            pickle.dump(regrModel, open(modelFilePath, 'wb'))
        
        # load models if desired
        if loadModel:
            regrModel = pickle.load(open(modelFilePath, 'rb'))
            
        # predict on test data
        prediction = regrModel.predict(testPredictors)
        plotblandaltman(testTarget,prediction,filepath+'blandAltman.pdf')
        
        if calcEval:
            # evaluate prediction
            mae = metr.mean_absolute_error(testTarget,prediction) # MAE
            me = np.mean(testTarget - prediction) # ME
            sd = np.std(testTarget - prediction) # SD
            r = np.corrcoef(np.ravel(testTarget),prediction)[0,1] # correlation coefficient
            # create dict from metrics
            evalResults = {
                'dataSplit':currentDataSplit,
                'model':currentModel,
                'predictors':desiredPredictors,
                'targets':desiredTargetList,
                'MAE':mae,
                'ME':me,
                'SD':sd,
                'CorrCoef':r,
                'FeatureImportance':dict(zip(regrModel.get_booster().feature_names,regrModel.feature_importances_))
                }
            # save prediction and metrics in pickle files
            pickle.dump(evalResults, open(filepath+'evalResuls.sav', 'wb'))
        
        if measureTime:
            now = datetime.now()
            currentTime = now.strftime("%H:%M:%S")
            print('Time after prediction = ',currentTime)
        
        # calculate shap values
        if calcShap:
            # explain the model's predictions using SHAP
            # (same syntax works for LightGBM, CatBoost, scikit-learn, transformers, Spark, etc.)
            explainer = shap.Explainer(regrModel)
            shap_values = explainer(trainPredictors)
            pickle.dump(shap_values, open(filepath+'shapValues.sav', 'wb'))
            shapDictAbsMean = dict(zip(shap_values.feature_names,np.mean(np.abs(shap_values.values),0))) # calculate absolute mean shapley values
            evalResults['shap'] = shapDictAbsMean # add shap values to evaluation dict
            evalList.append(evalResults)
            if measureTime:
                now = datetime.now()
                currentTime = now.strftime("%H:%M:%S")
                print('Time after shapley values = ',currentTime)
            
            # visualize the first prediction's explanation
            #fig = shap.plots.waterfall(shap_values[0])
            fig = shap.plots.waterfall(copy.deepcopy(shap_values)[0])
            plt.savefig(filepath+'shapValuesFirst.pdf', bbox_inches = 'tight', pad_inches = 0)
            #tikz.save(filepath+'shapValuesFirst.tex')
            plt.close()
            
            # summarize the effects of all the features
            #fig = shap.plots.beeswarm(shap_values) # changes shap values first column only for Gamma3generic?? 6th column for gg2g for with ppgi
            fig = shap.plots.beeswarm(copy.deepcopy(shap_values))
            plt.savefig(filepath+'shapValues.pdf', bbox_inches = 'tight', pad_inches = 0)
            #tikz.save(filepath+'shapValues.tex')
            plt.close()
            
            # summarize the effects of all the features (mean absolutes)
            #fig = shap.plots.bar(shap_values)
            fig = shap.plots.bar(copy.deepcopy(shap_values))
            plt.savefig(filepath+'shapValuesMeanAbs.pdf', bbox_inches = 'tight', pad_inches = 0)
            #tikz.save(filepath+'shapValuesMeanAbs.tex')
            plt.close()
            
            if measureTime:
                now = datetime.now()
                currentTime = now.strftime("%H:%M:%S")
                print('Time after shapley plots = ',currentTime)
                

# TODO: outsource to other function
# get all headers, built tuples (for shap und featureImportance) and tuples with none for all other entries
keyStrings = [x for x in evalList[0].keys()]
keyValues = [evalList[0][keyStrings[index]] for index,value in enumerate(keyStrings)]
keyTypes = [type(i) for i in keyValues]
keyBool = [True if type(evalList[0][keyStrings[index]]) == dict else False for index,value in enumerate(keyStrings)]

# buld header list
header = [(keyStrings[i],None) if not keyBool[i] else [(keyStrings[i],x) for x in keyValues[i].keys()] for i,_ in enumerate(keyStrings)]
headerFlat = list()
for entry in header:
    if type(entry)==list:
        for subEntry in entry:
            headerFlat.append(subEntry)
    else:
        headerFlat.append(entry)
        
# combine all pairs to one entry
headerCombine = list()
for entry in headerFlat:
    if not entry[1]==None:
        headerCombine.append(entry[0]+entry[1])
    else:
        headerCombine.append(entry[0])

# create data matrix for multiindex dataframe
evaluation = np.zeros((len(evalList),len(headerCombine)))# numpy array with rows = len evalList, cols = len headerCombine
evaluation = np.array(evaluation,dtype=object)
for row,rowElements in enumerate(evalList):
    for key in rowElements:
        if type(rowElements[key])==dict:
            for subKey in rowElements[key]:
                evaluation[row,headerFlat.index((key,subKey))] = rowElements[key][subKey]
        else:
            evaluation[row,headerCombine.index(key)] = rowElements[key]
    
evaluation = pd.DataFrame(evaluation,columns=headerCombine)
evaluation.columns = pd.MultiIndex.from_tuples([('', x[0]) if x[1] == None else x for x in headerFlat])

# save results
pickle.dump(evalList, open(dataset+'evalList.sav', 'wb'))
pickle.dump(evaluation, open(dataset+'evaluation.sav', 'wb'))
evaluation.to_csv(dataset+'evaluation.csv',sep=';')
