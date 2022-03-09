import numpy as np
import scipy.stats as stats 
import scipy.signal as sig
import sklearn.metrics as metr
import matplotlib.pyplot as plt
import tikzplotlib as tikz
import pandas as pd
import xgboost
import shap
import pickle
import copy
import getpass
import os.path as path
from datetime import datetime
from plotting import plotblandaltman

##############################################
#
#
#
# Pickle Endung, so dass für spyder lesbar!
#
#
#
##############################################

# BUG: https://stackoverflow.com/questions/68257249/why-are-shap-values-changing-every-time-i-call-shap-plots-beeswarm

# add description
# add todos into document
# loop over with and without ppgi
# correct paths

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

# include ppgi in evaluation (note: currently these are all separate data splits)

### setup
measureTime = True
calcShap = True
loadModel = False
calcEval = True

### use PPGI data
ppgi = ['with','without']

### define relevant dataset dir (dependent on user)
username = getpass.getuser()
if(username=='Vincent Fleischhauer'): # desktop path
    datasetBaseDir = path.abspath("X:\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\CPTFULL_PPG_BPSUBSET")
elif(username=='vince'): # laptop path
    datasetBaseDir = path.abspath("Y:\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\CPTFULL_PPG_BPSUBSET")
else: # print error message and abort function
    print('User not known, analysis stopped.')
    quit()

### define split of data
dataSplit = ['interSubject','intraSubject']

### define relevant models
models = ['GammaGaussian2generic']
#models = ['GammaGaussian2generic','Gamma3generic','Gaussian2generic','Gaussian3generic']

### define predictors to be used
#desiredPredictors = ['Sex_w','Age','P1','P2','T1','T2','b_a'] 
#desiredPredictors = ['Sex_w','Age','P1','P2','T1','T2','W1','W2','b_a','SD','kurt','skew','freq1','freq2','freq3','freq4'] 
desiredPredictors = ['P1','P2','T1','T2','W1','W2','b_a','SD','kurt','skew','freq1','freq2','freq3','freq4','PulseWidth'] 

### define predictors to be used
desiredTargetList = ['SBP']

### define list if evaluation dicts
evalList = list()



for _,currentDataSplit in enumerate(dataSplit):
    print(currentDataSplit)
    dataset = path.join(datasetBaseDir,currentDataSplit)
    for _,currentModel in enumerate(models):
        print(currentModel)
        for _,currentPPGIhandling in enumerate(ppgi): 
            print(currentPPGIhandling+'PPGI')
            if (currentPPGIhandling=='with'):
                filePath = path.join(dataset,"withPPGI",currentModel)
                # import matlab data (csv files)
                train = pd.read_csv(path.join(dataset,"withPPGI","trainTable.csv"), sep = ',')
                test = pd.read_csv(path.join(dataset,"withPPGI","testTable.csv"), sep = ',')
            elif(currentPPGIhandling=='without'):
                filePath = path.join(dataset,"withoutPPGI",currentModel)
                # import matlab data (csv files)
                train = pd.read_csv(path.join(dataset,"withoutPPGI","trainTable.csv"), sep = ',')
                test = pd.read_csv(path.join(dataset,"withoutPPGI","testTable.csv"), sep = ',')
            if measureTime:
                now = datetime.now()
                currentTime = now.strftime("%H:%M:%S")
                print('Time of start = ',currentTime)
            
            
            # convert some columns to certain types
            train.Sex = train.Sex.astype('category')
            train = pd.concat([train,pd.get_dummies(train['Sex'], prefix='Sex',drop_first=True)],axis=1)
            train.drop(['Sex'],axis=1, inplace=True)
            test.Sex = test.Sex.astype('category')
            test = pd.concat([test,pd.get_dummies(test['Sex'], prefix='Sex',drop_first=True)],axis=1)
            test.drop(['Sex'],axis=1, inplace=True)
            
            # extract relevant features as input array
            trainPredictors = train[train.columns.intersection(desiredPredictors)]
            testPredictors = test[test.columns.intersection(desiredPredictors)] # TODO: hier stand mal [train]
            
            # extract result vector (BP)
            trainTarget = np.ravel(train[train.columns.intersection(desiredTargetList)].to_numpy())
            testTarget = np.ravel(test[test.columns.intersection(desiredTargetList)].to_numpy())  # TODO: hier stand mal [train]
            
            modelFilePath = path.join(filePath,"regrModel.pkl")
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
            plotblandaltman(testTarget,prediction,path.join(filePath,"blandAltman.pdf"))
            plt.figure()
            plt.plot(testTarget)
            plt.plot(prediction)
            plt.savefig(path.join(filePath,"groundTruth_prediction.pdf"))
            plt.close()
            
            

            # predict on smoothed BP & smoothed features (Hu method)
            # create new dataframes (deepcopys of existing train and test)
            train_smB = train.copy()
            trainIDArray = train_smB["ID"].unique()
            trainPredictors_smB = train_smB[train_smB.columns.intersection(desiredPredictors)]
            trainTarget_smB = np.ravel(train_smB[train_smB.columns.intersection(desiredTargetList)].to_numpy())
            for _,currentID in enumerate(trainIDArray):
                indicesID = train_smB.index[train_smB["ID"]==currentID]
                if('unisens' in currentID):
                    ks = 5
                else:
                    ks = 1
                trainTarget_smB[indicesID] = sig.medfilt(trainTarget_smB[indicesID],kernel_size=ks)
                trainPredictors_smB.loc[indicesID,:] = sig.medfilt2d(trainPredictors_smB.to_numpy()[indicesID,:],kernel_size=[ks,1])
            test_smB = test.copy()
            testIDArray = test_smB["ID"].unique()
            testPredictors_smB = test_smB[test_smB.columns.intersection(desiredPredictors)]
            testTarget_smB = np.ravel(test_smB[test_smB.columns.intersection(desiredTargetList)].to_numpy())
            for _,currentID in enumerate(testIDArray):
                indicesID = test_smB.index[test_smB["ID"]==currentID]
                if('unisens' in currentID):
                    ks = 5
                else:
                    ks = 1
                testTarget_smB[indicesID] = sig.medfilt(testTarget_smB[indicesID],kernel_size=ks)
                testPredictors_smB.loc[indicesID,:] = sig.medfilt2d(testPredictors_smB.to_numpy()[indicesID,:],kernel_size=[ks,1])
            # need to train new model
            regrModel_smB = xgboost.XGBRegressor().fit(trainPredictors_smB,trainTarget_smB)
            prediction_smB = regrModel_smB.predict(testPredictors_smB)
            
            
            
            # smoothing afterwards
            testIDArray = test["ID"].unique()
            prediction_smA = np.zeros((np.size(prediction)))
            testTarget_smA = np.zeros((np.size(testTarget)))
            for _,currentID in enumerate(testIDArray):
                indicesID = test.index[test["ID"]==currentID]
                if('unisens' in currentID):
                    ks = 5
                else:
                    ks = 1
                prediction_smA[indicesID] = sig.medfilt(prediction[indicesID],kernel_size=ks)
                testTarget_smA[indicesID] = sig.medfilt(testTarget[indicesID],kernel_size=ks)
            plotblandaltman(testTarget_smA,prediction_smA,path.join(filePath,"blandAltmanSmooth.pdf"))
            plt.figure()
            plt.plot(testTarget_smA)
            plt.plot(prediction_smA)
            plt.savefig(path.join(filePath,"groundTruth_predictionSmooth.pdf"))
            plt.close()
            
            
            # TODO: change names of all those smooth stuff
            
            
            if calcEval:
                # evaluate prediction
                mae = metr.mean_absolute_error(testTarget,prediction) # MAE
                me = np.mean(testTarget - prediction) # ME
                rmse = metr.mean_squared_error(testTarget,prediction,squared=False) # RMSE
                sd = np.std(testTarget - prediction) # SD
                rPearson = np.corrcoef(np.ravel(testTarget),prediction)[0,1] # correlation coefficient (Pearson)
                rSpearman,_ = stats.spearmanr(np.ravel(testTarget),prediction) # correlation coefficient (Spearman)
                # evaluate Hu method
                mae_smB = metr.mean_absolute_error(testTarget_smB,prediction_smB) # MAE
                me_smB = np.mean(testTarget_smB - prediction_smB) # ME
                rmse_smB = metr.mean_squared_error(testTarget_smB,prediction_smB,squared=False) # RMSE
                sd_smB = np.std(testTarget_smB - prediction_smB) # SD
                rPearson_smB = np.corrcoef(np.ravel(testTarget_smB),prediction_smB)[0,1] # correlation coefficient (Pearson)
                rSpearman_smB,_ = stats.spearmanr(np.ravel(testTarget_smB),prediction_smB) # correlation coefficient (Spearman)
                # evaluate smoothing afterwards
                mae_smA = metr.mean_absolute_error(testTarget_smA,prediction_smA) # MAE
                me_smA = np.mean(testTarget_smA - prediction_smA) # ME
                rmse_smA = metr.mean_squared_error(testTarget_smA,prediction_smA,squared=False) # RMSE
                sd_smA = np.std(testTarget_smA - prediction_smA) # SD
                rPearson_smA = np.corrcoef(np.ravel(testTarget_smA),prediction_smA)[0,1] # correlation coefficient (Pearson)
                rSpearman_smA,_ = stats.spearmanr(np.ravel(testTarget_smA),prediction_smA) # correlation coefficient (Spearman)
                # create dict from metrics
                evalResults = {
                    'dataSplit':currentDataSplit,
                    'ppgi':currentPPGIhandling,
                    'model':currentModel,
                    'predictors':desiredPredictors,
                    'targets':desiredTargetList,
                    'MAE':mae,
                    'MAE_smA':mae_smA,
                    'MAE_smB':mae_smB,
                    'ME':me,
                    'ME_smA':me_smA,
                    'ME_smB':me_smB,
                    'RMSE':rmse,
                    'RMSE_smA':rmse_smA,
                    'RMSE_smB':rmse_smB,
                    'SD':sd,
                    'SD_smA':sd_smA,
                    'SD_smB':sd_smB,
                    'CorrPearson':rPearson,
                    'CorrPearson_smA':rPearson_smA,
                    'CorrPearson_smB':rPearson_smB,
                    'CorrSpearman':rSpearman,
                    'CorrSpearman_smA':rSpearman_smA,
                    'CorrSpearman_smB':rSpearman_smB,
                    'FeatureImportance':dict(zip(regrModel.get_booster().feature_names,regrModel.feature_importances_))
                    }
                # save prediction and metrics in pickle files
                pickle.dump(evalResults, open(path.join(filePath,"evalResults.pkl"), 'wb'))
            
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
                pickle.dump(shap_values, open(path.join(filePath,"shapValues.pkl"), 'wb'))
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
                plt.savefig(path.join(filePath,"shapValuesFirst.pdf"), bbox_inches = 'tight', pad_inches = 0)
                #tikz.save(filepath+'shapValuesFirst.tex')
                plt.close()
                
                # summarize the effects of all the features
                #fig = shap.plots.beeswarm(shap_values) # changes shap values first column only for Gamma3generic?? 6th column for gg2g for with ppgi
                fig = shap.plots.beeswarm(copy.deepcopy(shap_values))
                plt.savefig(path.join(filePath,"shapValues.pdf"), bbox_inches = 'tight', pad_inches = 0)
                #tikz.save(filepath+'shapValues.tex')
                plt.close()
                
                # summarize the effects of all the features (mean absolutes)
                #fig = shap.plots.bar(shap_values)
                fig = shap.plots.bar(copy.deepcopy(shap_values))
                plt.savefig(path.join(filePath,"shapValuesMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
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
pickle.dump(evalList, open(path.join(datasetBaseDir,"evalList.pkl"), 'wb'))
pickle.dump(evaluation, open(path.join(datasetBaseDir,"evaluation.pkl"), 'wb'))
evaluation.to_csv(path.join(datasetBaseDir,"evaluation.csv"),sep=';')
