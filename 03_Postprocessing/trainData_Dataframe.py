import numpy as np
import scipy.stats as stats 
import scipy.signal as sig
import sklearn.metrics as metr
import matplotlib.pyplot as plt
import tikzplotlib as tikz
import pandas as pd
import xgboost
import lightgbm as lgb
import catboost as cb
import shap
import pickle
import copy
import getpass
import os.path as path
import os
from datetime import datetime
from plotting import plotComparison
from plotting import plotComparisonSub
from pyCompare import blandAltman
#from plotting import plotblandaltman
import matplotlib as mpl

useLATEX = True
if useLATEX:
    mpl.rcParams['text.usetex'] = True
    mpl.rcParams['font.family'] = 'serif'
    mpl.rcParams['font.serif'] = ['Computer Modern Roman']
textcolor = 'black'
mpl.rcParams['text.color'] = textcolor
mpl.rcParams['axes.labelcolor'] = textcolor
mpl.rcParams['xtick.color'] = textcolor
mpl.rcParams['ytick.color'] = textcolor
mpl.rcParams['axes.facecolor'] = 'FFFFFF'
plt.rcParams['grid.color'] = '#C0C0C0'
mpl.rc('axes',edgecolor='black')
ps1 = 3
ps2 = 4


# text needs to be black
# b_a workaround (problem with underscore outside of math environment)
# --> zur Not bei conversion zu csv aus underscore slash machen, hier dann damit arbeiten


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
doWeights = True
doErrorAnalysis = True
doBPAnalysis = True
doComparison = True

doSubjectwiseMAE = True
doDatasetMAE = True

doDatabankAnalysis = True
doCameraAnalysis = False
camStartInd = 13830
camEndInd = 13879
doDependencePlots = True
doDependenceInteractions = False
dependencePlotFeatures= ['skew','SD','b/a','T2','T1','PulseWidth']

mixSet = 'CPTFULL_QueenslandFULL_PPG_BPSUBSET'

### setup weights
wMultiplyer = 0.375#4#0.51 for NEWEST#4
thresholdMultiplyer = 0.5#0.75#0.35 for NEWEST#0.75

### use PPGI data
#ppgi = ['with','without']
ppgi = ['without']

### define relevant dataset dir (dependent on user)
username = getpass.getuser()
if(username=='Vincent Fleischhauer'): # desktop path
    datasetBaseDir = path.abspath("X:\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets")
elif(username=='vince'): # laptop path
    datasetBaseDir = path.abspath("Y:\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets")
elif(username=='vifle001'): # new desktop path
    datasetBaseDir = path.abspath("Z:\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets")
else: # print error message and abort function
    print('User not known, analysis stopped.')
    quit()
datasetBaseDir = path.join(datasetBaseDir,mixSet)

### define split of data
#dataSplit = ['interSubject','intraSubject']
dataSplit = ['interSubject']

### define relevant models
models = ['GammaGaussian2generic']
#models = ['GammaGaussian2generic','Gamma3generic','Gaussian2generic','Gaussian3generic']

### define predictors to be used
desiredPredictors = ['P1','P2','T1','T2','W1','W2','b/a','SD','kurt','skew','freq1','freq2','freq3','freq4','PulseWidth'] 
#desiredPredictors = ['P1','P2','T1','T2','W1','W2','SD','kurt','skew','freq1','freq2','freq3','freq4','PulseWidth'] 

### define predictors to be used
desiredTargetList = ['SBP']

### define list if evaluation dicts
evalList = list()
evalList_CPT = list()
evalList_Queensland = list()
evalList_PPGBP = list()



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
            
            ###################################################################
            # only do that for MBP or DBP
            # restrict target variables to SBP, DBP and MBP
            if (desiredTargetList[0] == 'DBP' or desiredTargetList[0] == 'MBP'):
                # delete all nans from DBP
                test = test[test['DBP'].notna()]
                train = train[train['DBP'].notna()]
                
                # make index continupus again
                test = test.reset_index(drop=True)
                train = train.reset_index(drop=True)
                
                # calculate MBP
                testMBP = (2*test['DBP']+test['SBP'])/3
                trainMBP = (2*train['DBP']+train['SBP'])/3
                
                # insert MBP into dataframes
                test.insert(test.columns.get_loc('PP'), 'MBP', testMBP)
                train.insert(train.columns.get_loc('PP'), 'MBP', trainMBP)
            
            ###################################################################
            
            # get number of samples
            numSamples = dict()
            numSamples["CPT_train"] = sum(1 for currentSample in train["ID"] if 'unisens' in currentSample)
            numSamples["CPT_test"] = sum(1 for currentSample in test["ID"] if 'unisens' in currentSample)
            numSamples["Queensland_train"] = sum(1 for currentSample in train["ID"] if 'case' in currentSample)
            numSamples["Queensland_test"] = sum(1 for currentSample in test["ID"] if 'case' in currentSample)
            numSamples["PPG-BP_train"] = len(train) - numSamples["CPT_train"] - numSamples["Queensland_train"]
            numSamples["PPG-BP_test"] = len(test) - numSamples["CPT_test"] - numSamples["Queensland_test"]
            
            # get BP characteristica (based on target variable)
            charBP = dict()
            charBP["CPT_test_max"] = test.loc[test["ID"].str.contains('unisens'),desiredTargetList[0]].max()
            charBP["CPT_test_min"] = test.loc[test["ID"].str.contains('unisens'),desiredTargetList[0]].min()
            charBP["CPT_test_mean"] = test.loc[test["ID"].str.contains('unisens'),desiredTargetList[0]].mean()
            charBP["CPT_test_SD"] = test.loc[test["ID"].str.contains('unisens'),desiredTargetList[0]].std()
            charBP["Queensland_test_max"] = test.loc[test["ID"].str.contains('case'),desiredTargetList[0]].max()
            charBP["Queensland_test_min"] = test.loc[test["ID"].str.contains('case'),desiredTargetList[0]].min()
            charBP["Queensland_test_mean"] = test.loc[test["ID"].str.contains('case'),desiredTargetList[0]].mean()
            charBP["Queensland_test_SD"] = test.loc[test["ID"].str.contains('case'),desiredTargetList[0]].std()
            charBP["PPG-BP_test_max"] = test.loc[~(test["ID"].str.contains('unisens') | test["ID"].str.contains('case')) ,desiredTargetList[0]].max()
            charBP["PPG-BP_test_min"] = test.loc[~(test["ID"].str.contains('unisens') | test["ID"].str.contains('case')) ,desiredTargetList[0]].min()
            charBP["PPG-BP_test_mean"] = test.loc[~(test["ID"].str.contains('unisens') | test["ID"].str.contains('case')) ,desiredTargetList[0]].mean()
            charBP["PPG-BP_test_SD"] = test.loc[~(test["ID"].str.contains('unisens') | test["ID"].str.contains('case')) ,desiredTargetList[0]].std()
            charBP["CPT_train_max"] = train.loc[train["ID"].str.contains('unisens'),desiredTargetList[0]].max()
            charBP["CPT_train_min"] = train.loc[train["ID"].str.contains('unisens'),desiredTargetList[0]].min()
            charBP["CPT_train_mean"] = train.loc[train["ID"].str.contains('unisens'),desiredTargetList[0]].mean()
            charBP["CPT_train_SD"] = train.loc[train["ID"].str.contains('unisens'),desiredTargetList[0]].std()
            charBP["Queensland_train_max"] = train.loc[train["ID"].str.contains('case'),desiredTargetList[0]].max()
            charBP["Queensland_train_min"] = train.loc[train["ID"].str.contains('case'),desiredTargetList[0]].min()
            charBP["Queensland_train_mean"] = train.loc[train["ID"].str.contains('case'),desiredTargetList[0]].mean()
            charBP["Queensland_train_SD"] = train.loc[train["ID"].str.contains('case'),desiredTargetList[0]].std()
            charBP["PPG-BP_train_max"] = train.loc[~(train["ID"].str.contains('unisens') | train["ID"].str.contains('case')) ,desiredTargetList[0]].max()
            charBP["PPG-BP_train_min"] = train.loc[~(train["ID"].str.contains('unisens') | train["ID"].str.contains('case')) ,desiredTargetList[0]].min()
            charBP["PPG-BP_train_mean"] = train.loc[~(train["ID"].str.contains('unisens') | train["ID"].str.contains('case')) ,desiredTargetList[0]].mean()
            charBP["PPG-BP_train_SD"] = train.loc[~(train["ID"].str.contains('unisens') | train["ID"].str.contains('case')) ,desiredTargetList[0]].std()
            
            # extract relevant features as input array
            trainPredictors = train[train.columns.intersection(desiredPredictors)]
            testPredictors = test[test.columns.intersection(desiredPredictors)] # TODO: hier stand mal [train]
            
            # prepare indExpl table
            indExpl = test.copy()
            
            # extract result vector (BP)
            trainTarget = np.ravel(train[train.columns.intersection(desiredTargetList)].to_numpy())
            testTarget = np.ravel(test[test.columns.intersection(desiredTargetList)].to_numpy())  # TODO: hier stand mal [train]
            
            modelFilePath = path.join(filePath,"regrModel.pkl")
            if not loadModel:
                w = np.ones((trainTarget.size))# w dependent on target vector (larger than 1 above certain level, 2 for highest 20% of data)
                if doWeights:
                    threshold = thresholdMultiplyer*max(trainTarget)
                    w[trainTarget>threshold] = wMultiplyer
                regrModel = xgboost.XGBRegressor().fit(trainPredictors,trainTarget,sample_weight=w)
                # https://stats.stackexchange.com/questions/457483/sample-weights-in-xgbclassifier
                # use sample_weight option to emphasize specific subjects with less common BP values
                pickle.dump(regrModel, open(modelFilePath, 'wb'))
            
            # load models if desired
            if loadModel:
                regrModel = pickle.load(open(modelFilePath, 'rb'))
                
            # predict on test data
            prediction = regrModel.predict(testPredictors)
            blandAltman(prediction,testTarget,savePath=path.join(filePath,"blandAltman.pdf"),figureFormat='pdf')
            plotComparison(prediction,testTarget,path.join(filePath,"groundTruth_prediction.pdf"))
            
            

            # predict on smoothed BP & smoothed features (Hu method)
            # create new dataframes (deepcopys of existing train and test)
            train_smB = train.copy()
            trainIDArray = train_smB["ID"].unique()
            trainPredictors_smB = train_smB[train_smB.columns.intersection(desiredPredictors)]
            trainTarget_smB = np.ravel(train_smB[train_smB.columns.intersection(desiredTargetList)].to_numpy())
            for _,currentID in enumerate(trainIDArray):
                indicesID = train_smB.index[train_smB["ID"]==currentID]
                if('unisens' in currentID):
                    ks = 11
                elif('case' in currentID):
                    ks = 11
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
                    ks = 11
                elif('case' in currentID):
                    ks = 11
                else:
                    ks = 1
                testTarget_smB[indicesID] = sig.medfilt(testTarget_smB[indicesID],kernel_size=ks)
                testPredictors_smB.loc[indicesID,:] = sig.medfilt2d(testPredictors_smB.to_numpy()[indicesID,:],kernel_size=[ks,1])
            # need to train new model
            w_smB = np.ones((trainTarget_smB.size))# w dependent on target vector (larger than 1 above certain level, 2 for highest 20% of data)
            if doWeights:
                threshold_smB = thresholdMultiplyer*max(trainTarget_smB)
                w_smB[trainTarget_smB>threshold] = wMultiplyer
            regrModel_smB = xgboost.XGBRegressor().fit(trainPredictors_smB,trainTarget_smB,sample_weight=w_smB)
            prediction_smB = regrModel_smB.predict(testPredictors_smB)
            
            
            
            # smoothing afterwards
            subList_prediction = list()
            subList_target = list()
            testIDArray = test["ID"].unique()
            datasetArray = list()
            prediction_smA = np.zeros((np.size(prediction)))
            testTarget_smA = np.zeros((np.size(testTarget)))
            yLim = [0,0]
            for _,currentID in enumerate(testIDArray):
                indicesID = test.index[test["ID"]==currentID]
                if('unisens' in currentID):
                    ks = 11
                    datasetString = "CPT"
                elif('case' in currentID):
                    ks = 11
                    datasetString = "Queensland"
                else:
                    ks = 1
                    datasetString = "PPGBP"  
                prediction_smA[indicesID] = sig.medfilt(prediction[indicesID],kernel_size=ks)
                testTarget_smA[indicesID] = sig.medfilt(testTarget[indicesID],kernel_size=ks)
                #datasetArray.extend(datasetString*len(indicesID))
                for i in range(len(indicesID)):
                    datasetArray.append(datasetString)
            if min(prediction_smA) < min(testTarget_smA):
                yLim[0] = min(prediction_smA) - 5
            else:
                yLim[0] = min(testTarget_smA) - 5
            if max(prediction_smA) > max(testTarget_smA):
                yLim[1] = max(prediction_smA) + 5
            else:
                yLim[1] = max(testTarget_smA) + 5
            test["dataset"] = datasetArray
            datasetStrings = ["CPT","Queensland","PPGBP"]
            for datasetString in datasetStrings:
                indicesDataset = test.index[test["dataset"]==datasetString]
                subList_prediction.append(prediction_smA[indicesDataset])
                subList_target.append(testTarget_smA[indicesDataset])
                plotComparison(prediction_smA[indicesDataset],testTarget_smA[indicesDataset],path.join(filePath,"groundTruth_predictionSmooth" + datasetString + ".pdf"),yLimits = yLim)
            blandAltman(prediction_smA,testTarget_smA,savePath=path.join(filePath,"blandAltmanSmooth.pdf"),figureFormat='pdf')
            plotComparison(prediction_smA,testTarget_smA,path.join(filePath,"groundTruth_predictionSmooth.pdf"))
            plotComparisonSub(subList_prediction,subList_target,path.join(filePath,"groundTruth_predictionSmooth_subs.pdf"),yLimits = yLim)
            
            
            # TODO: change names of all those smooth stuff
            
            # fill indExpl prediction
            indExpl = indExpl.assign(Prediction=prediction,PredictionSmoothAfter=prediction_smA,PredictionSmoothBefore=prediction_smB)
            indExpl = indExpl.assign(Error=testTarget - prediction,
                                     Error_smA=testTarget_smA - prediction_smA,
                                     Error_smB=testTarget_smB - prediction_smB)
            
            
            
            if calcEval:
                # show SBP distribution
                plt.figure()
                plt.hist(trainTarget)
                plt.axvline(x=thresholdMultiplyer*max(trainTarget),ls='--',color='black')
                # give number of samples above and below threshold ?
                plt.grid(visible=False)
                plt.savefig(path.join(filePath,"HistSBPtrain.pdf"), bbox_inches = 'tight', pad_inches = 0)
                plt.close()
                plt.figure()
                plt.hist(testTarget)
                plt.grid(visible=False)
                plt.savefig(path.join(filePath,"HistSBPtest.pdf"), bbox_inches = 'tight', pad_inches = 0)
                plt.close()
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
                
                
                ###############################################################
                # calculate subject wise MAE
                if doSubjectwiseMAE:
                    print('TO BE ADDED')
                
                
                
                ###############################################################
            
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
                shap_valuesTEST = explainer(testPredictors)
                pickle.dump(shap_valuesTEST, open(path.join(filePath,"shapValuesTEST.pkl"), 'wb'))
                shapDictAbsMean = dict(zip(shap_values.feature_names,np.mean(np.abs(shap_values.values),0))) # calculate absolute mean shapley values
                evalResults['shap'] = shapDictAbsMean # add shap values to evaluation dict
                #evalList.append(evalResults)
                if measureTime:
                    now = datetime.now()
                    currentTime = now.strftime("%H:%M:%S")
                    print('Time after shapley values = ',currentTime)
                    
                for featureName in shap_valuesTEST.feature_names:
                    del indExpl[featureName]
                indExplShap = pd.DataFrame(dict(zip(shap_valuesTEST.feature_names,shap_valuesTEST.values.transpose())))
                shapSamples = pd.concat([indExpl, indExplShap], axis=1)
                pickle.dump(indExpl, open(path.join(filePath,"shapSamples.pkl"), 'wb'))
                shapSamples.to_csv(path.join(filePath,"shapSamples.csv")) 
                
                
                ###############################################################
                if doErrorAnalysis:
                    # MAE - SHAP analyses
                    
                    # get MAE
                    baseThres = np.mean(abs(shapSamples['Error_smA']))# baseThres = MAE
                    
                    # multipliers
                    multipliersThres = [1,1.5,2,2.5,3,3.5,4]
                    
                    # create folder for results
                    shapPath = path.join(filePath,"errorSHAP")
                    if not path.exists(shapPath):
                        os.mkdir(shapPath)
                    
                    for currentMultipliersThres in multipliersThres:
                        # create subfolder
                        errorSHAPSubPath = path.join(shapPath,str(currentMultipliersThres))   
                        if not path.exists(errorSHAPSubPath):
                            os.mkdir(errorSHAPSubPath)
                        # get correct rows of dataframe
                        
                        # do this and shorten predictors with i?
                        #shap_valuesTEST = explainer(testPredictors)
                        
                        indThres = np.where(shapSamples['Error_smA'] > currentMultipliersThres*baseThres)[0]
                        if len(indThres)>1:
                            shapSamples_HighError = shapSamples.loc[indThres]
                            # save as csv
                            shapSamples_HighError.to_csv(path.join(errorSHAPSubPath,"shapSamples_HighError.csv"))
                            # extract correct shap values
                            errorSHAP = shap_valuesTEST[indThres]
                            # create plots
                            
                            fig = shap.plots.beeswarm(copy.deepcopy(errorSHAP),show=False,plot_size=[ps1,ps2])
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[0].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            plt.gcf().axes[-1].set_aspect(100)
                            plt.gcf().axes[-1].set_box_aspect(100)
                            plt.xlabel('SHAP value')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"badShaps_beeswarm.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                            
                            fig = shap.plots.bar(copy.deepcopy(errorSHAP))
                            plt.gcf().set_figheight(ps2)
                            plt.gcf().set_figwidth(ps1)
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[9].set_text("others")
                            yticklabels[-1].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            if useLATEX:
                                plt.xlabel('mean($|$SHAP value$|$)')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"badShaps.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                    
                    
                    # multipliers
                    multipliersThres = [0.25,0.5,0.75,1]
                    
                    # create folder for results
                    shapPath = path.join(filePath,"goodSHAP")
                    if not path.exists(shapPath):
                        os.mkdir(shapPath)
                    
                    for currentMultipliersThres in multipliersThres:
                        # create subfolder
                        errorSHAPSubPath = path.join(shapPath,str(currentMultipliersThres))   
                        if not path.exists(errorSHAPSubPath):
                            os.mkdir(errorSHAPSubPath)
                        # get correct rows of dataframe
                        
                        # do this and shorten predictors with i?
                        #shap_valuesTEST = explainer(testPredictors)
                        
                        indThres = np.where(shapSamples['Error_smA'] < currentMultipliersThres*baseThres)[0]
                        if len(indThres)>1:
                            shapSamples_HighError = shapSamples.loc[indThres]
                            # save as csv
                            shapSamples_HighError.to_csv(path.join(errorSHAPSubPath,"shapSamples_LowError.csv"))
                            # extract correct shap values
                            errorSHAP = shap_valuesTEST[indThres]
                            # create plots
                            
                            fig = shap.plots.beeswarm(copy.deepcopy(errorSHAP),show=False,plot_size=[ps1,ps2])
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[0].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            plt.gcf().axes[-1].set_aspect(100)
                            plt.gcf().axes[-1].set_box_aspect(100)
                            plt.xlabel('SHAP value')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"goodShaps_beeswarm.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                            
                            fig = shap.plots.bar(copy.deepcopy(errorSHAP))
                            plt.gcf().set_figheight(ps2)
                            plt.gcf().set_figwidth(ps1)
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[9].set_text("others")
                            yticklabels[-1].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            if useLATEX:
                                plt.xlabel('mean($|$SHAP value$|$)')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"goodShaps.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                
                ###############################################################
                if doBPAnalysis:
                    # BP prediction - SHAP analyses
                    
                    # get MAE
                    baseThres = np.mean(shapSamples['PredictionSmoothAfter'])# baseThres = MAE
                    
                    # multipliers
                    multipliersThres = [1,1.1,1.2,1.2,1.3,1.4,1.5]
                    
                    # create folder for results
                    shapPath = path.join(filePath,"highBPSHAP")
                    if not path.exists(shapPath):
                        os.mkdir(shapPath)
                    
                    for currentMultipliersThres in multipliersThres:
                        # create subfolder
                        errorSHAPSubPath = path.join(shapPath,str(currentMultipliersThres))   
                        if not path.exists(errorSHAPSubPath):
                            os.mkdir(errorSHAPSubPath)
                        # get correct rows of dataframe
                        
                        # do this and shorten predictors with i?
                        #shap_valuesTEST = explainer(testPredictors)
                        
                        indThres = np.where(shapSamples['PredictionSmoothAfter'] > currentMultipliersThres*baseThres)[0]
                        if len(indThres)>1:
                            shapSamples_HighError = shapSamples.loc[indThres]
                            # save as csv
                            shapSamples_HighError.to_csv(path.join(errorSHAPSubPath,"shapSamples_HighBP.csv"))
                            # extract correct shap values
                            errorSHAP = shap_valuesTEST[indThres]
                            # create plots
                            
                            fig = shap.plots.beeswarm(copy.deepcopy(errorSHAP),show=False,plot_size=[ps1,ps2])
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[0].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            plt.gcf().axes[-1].set_aspect(100)
                            plt.gcf().axes[-1].set_box_aspect(100)
                            plt.xlabel('SHAP value')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"highBPshaps_beeswarm.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                            
                            fig = shap.plots.bar(copy.deepcopy(errorSHAP))
                            plt.gcf().set_figheight(ps2)
                            plt.gcf().set_figwidth(ps1)
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[9].set_text("others")
                            yticklabels[-1].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            if useLATEX:
                                plt.xlabel('mean($|$SHAP value$|$)')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"highBPshaps.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                    
                    
                    # multipliers
                    multipliersThres = [0.75,0.8,0.85,0.9,0.95,1]
                    
                    # create folder for results
                    shapPath = path.join(filePath,"lowBPSHAP")
                    if not path.exists(shapPath):
                        os.mkdir(shapPath)
                    
                    for currentMultipliersThres in multipliersThres:
                        # create subfolder
                        errorSHAPSubPath = path.join(shapPath,str(currentMultipliersThres))   
                        if not path.exists(errorSHAPSubPath):
                            os.mkdir(errorSHAPSubPath)
                        # get correct rows of dataframe
                        
                        # do this and shorten predictors with i?
                        #shap_valuesTEST = explainer(testPredictors)
                        
                        indThres = np.where(shapSamples['PredictionSmoothAfter'] < currentMultipliersThres*baseThres)[0]
                        if len(indThres)>1:
                            shapSamples_HighError = shapSamples.loc[indThres]
                            # save as csv
                            shapSamples_HighError.to_csv(path.join(errorSHAPSubPath,"shapSamples_LowBP.csv"))
                            # extract correct shap values
                            errorSHAP = shap_valuesTEST[indThres]
                            # create plots
                            
                            fig = shap.plots.beeswarm(copy.deepcopy(errorSHAP),show=False,plot_size=[ps1,ps2])
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[0].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            plt.gcf().axes[-1].set_aspect(100)
                            plt.gcf().axes[-1].set_box_aspect(100)
                            plt.xlabel('SHAP value')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"lowBPshaps_beeswarm.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                            
                            fig = shap.plots.bar(copy.deepcopy(errorSHAP))
                            plt.gcf().set_figheight(ps2)
                            plt.gcf().set_figwidth(ps1)
                            yticklabels = plt.gcf().axes[0].get_yticklabels()
                            yticklabels[9].set_text("others")
                            yticklabels[-1].set_text("others")
                            plt.gcf().axes[0].set_yticklabels(yticklabels)
                            if useLATEX:
                                plt.xlabel('mean($|$SHAP value$|$)')
                            plt.grid(visible=False)
                            plt.savefig(path.join(errorSHAPSubPath,"lowBPshaps.pdf"), bbox_inches = 'tight', pad_inches = 0)
                            plt.close()
                    
                ###############################################################
                if doDatabankAnalysis:
                    # analysis of shapley for each database individually
                    # get indices for each database
                    # get those indices from shapSamples dataframe
                    if doCameraAnalysis:
                        shapSamplesCopy = copy.deepcopy(shapSamples)
                        # extract camera data
                        shapCamera = shap_valuesTEST[camStartInd:camEndInd,:]
                        # delete camera data from main dataframe
                        shapSamplesCopy.drop(shapSamplesCopy.index[camStartInd:camEndInd])
                        # rest of data is CPT                        
                        CPTindices = shapSamplesCopy.loc[shapSamples['ID'].str.contains('unisens')].index.values.astype(int)
                        CPTindices = np.delete(CPTindices,np.where((CPTindices >= camStartInd) & (CPTindices <= camEndInd)),axis=0)
                        shapCPT = shap_valuesTEST[CPTindices,:]
                        # do plots
                        shapPath = path.join(filePath,"camera")
                        if not path.exists(shapPath):
                            os.mkdir(shapPath)
                            
                        # Camera
                        fig = shap.plots.beeswarm(copy.deepcopy(shapCamera),show=False,plot_size=[ps1,ps2])
                        yticklabels = plt.gcf().axes[0].get_yticklabels()
                        yticklabels[0].set_text("others")
                        plt.gcf().axes[0].set_yticklabels(yticklabels)
                        plt.gcf().axes[-1].set_aspect(100)
                        plt.gcf().axes[-1].set_box_aspect(100)
                        plt.xlabel('SHAP value')
                        plt.grid(visible=False)
                        plt.savefig(path.join(shapPath,"shapValuesCamera.pdf"), bbox_inches = 'tight', pad_inches = 0)
                        #tikz.save(filepath+'shapValues.tex')
                        plt.close()
                        fig = shap.plots.bar(copy.deepcopy(shapCamera))
                        plt.gcf().set_figheight(ps2)
                        plt.gcf().set_figwidth(ps1)
                        yticklabels = plt.gcf().axes[0].get_yticklabels()
                        yticklabels[9].set_text("others")
                        yticklabels[-1].set_text("others")
                        plt.gcf().axes[0].set_yticklabels(yticklabels)
                        if useLATEX:
                            plt.xlabel('mean($|$SHAP value$|$)')
                        plt.grid(visible=False)
                        plt.savefig(path.join(shapPath,"shapValuesCameraMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
                        #tikz.save(filepath+'shapValuesMeanAbs.tex')
                        plt.close()
                        
                        # Finger CPT
                        fig = shap.plots.beeswarm(copy.deepcopy(shapCPT),show=False,plot_size=[ps1,ps2])
                        yticklabels = plt.gcf().axes[0].get_yticklabels()
                        yticklabels[0].set_text("others")
                        plt.gcf().axes[0].set_yticklabels(yticklabels)
                        plt.gcf().axes[-1].set_aspect(100)
                        plt.gcf().axes[-1].set_box_aspect(100)
                        plt.xlabel('SHAP value')
                        plt.grid(visible=False)
                        plt.savefig(path.join(shapPath,"shapValuesCPT.pdf"), bbox_inches = 'tight', pad_inches = 0)
                        #tikz.save(filepath+'shapValues.tex')
                        plt.close()
                        fig = shap.plots.bar(copy.deepcopy(shapCPT))
                        plt.gcf().set_figheight(ps2)
                        plt.gcf().set_figwidth(ps1)
                        yticklabels = plt.gcf().axes[0].get_yticklabels()
                        yticklabels[9].set_text("others")
                        yticklabels[-1].set_text("others")
                        plt.gcf().axes[0].set_yticklabels(yticklabels)
                        if useLATEX:
                            plt.xlabel('mean($|$SHAP value$|$)')
                        plt.grid(visible=False)
                        plt.savefig(path.join(shapPath,"shapValuesCPTMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
                        #tikz.save(filepath+'shapValuesMeanAbs.tex')
                        plt.close()
                    else:
                        shapCPT = shap_valuesTEST[shapSamples.loc[shapSamples['ID'].str.contains('unisens')].index.values.astype(int),:]
                    shapQueensland = shap_valuesTEST[shapSamples.loc[shapSamples['ID'].str.contains('case')].index.values.astype(int),:]
                    shapPPGBP = shap_valuesTEST[shapSamples.loc[~shapSamples['ID'].str.contains('case') & ~shapSamples['ID'].str.contains('unisens')].index.values.astype(int),:]
                    # do plots
                    shapPath = path.join(filePath,"datasets")
                    if not path.exists(shapPath):
                        os.mkdir(shapPath)
                        
                    # CPT
                    fig = shap.plots.beeswarm(copy.deepcopy(shapCPT),show=False,plot_size=[ps1,ps2])
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[0].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    plt.gcf().axes[-1].set_aspect(100)
                    plt.gcf().axes[-1].set_box_aspect(100)
                    plt.xlabel('SHAP value')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,"shapValuesCPT.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValues.tex')
                    plt.close()
                    fig = shap.plots.bar(copy.deepcopy(shapCPT))
                    plt.gcf().set_figheight(ps2)
                    plt.gcf().set_figwidth(ps1)
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[9].set_text("others")
                    yticklabels[-1].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    if useLATEX:
                        plt.xlabel('mean($|$SHAP value$|$)')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,"shapValuesCPTMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValuesMeanAbs.tex')
                    plt.close()
                    
                    indCPT = shapSamples.loc[shapSamples['ID'].str.contains('unisens')].index.values.astype(int)
                    # evaluate prediction
                    mae = metr.mean_absolute_error(testTarget[indCPT],prediction[indCPT]) # MAE
                    me = np.mean(testTarget[indCPT] - prediction[indCPT]) # ME
                    rmse = metr.mean_squared_error(testTarget[indCPT],prediction[indCPT],squared=False) # RMSE
                    sd = np.std(testTarget[indCPT] - prediction[indCPT]) # SD
                    rPearson = np.corrcoef(np.ravel(testTarget[indCPT]),prediction[indCPT])[0,1] # correlation coefficient (Pearson)
                    rSpearman,_ = stats.spearmanr(np.ravel(testTarget[indCPT]),prediction[indCPT]) # correlation coefficient (Spearman)
                    # evaluate Hu method
                    mae_smB = metr.mean_absolute_error(testTarget_smB[indCPT],prediction_smB[indCPT]) # MAE
                    me_smB = np.mean(testTarget_smB[indCPT] - prediction_smB[indCPT]) # ME
                    rmse_smB = metr.mean_squared_error(testTarget_smB[indCPT],prediction_smB[indCPT],squared=False) # RMSE
                    sd_smB = np.std(testTarget_smB[indCPT] - prediction_smB[indCPT]) # SD
                    rPearson_smB = np.corrcoef(np.ravel(testTarget_smB[indCPT]),prediction_smB[indCPT])[0,1] # correlation coefficient (Pearson)
                    rSpearman_smB,_ = stats.spearmanr(np.ravel(testTarget_smB[indCPT]),prediction_smB[indCPT]) # correlation coefficient (Spearman)
                    # evaluate smoothing afterwards
                    mae_smA = metr.mean_absolute_error(testTarget_smA[indCPT],prediction_smA[indCPT]) # MAE
                    me_smA = np.mean(testTarget_smA[indCPT] - prediction_smA[indCPT]) # ME
                    rmse_smA = metr.mean_squared_error(testTarget_smA[indCPT],prediction_smA[indCPT],squared=False) # RMSE
                    sd_smA = np.std(testTarget_smA[indCPT] - prediction_smA[indCPT]) # SD
                    rPearson_smA = np.corrcoef(np.ravel(testTarget_smA[indCPT]),prediction_smA[indCPT])[0,1] # correlation coefficient (Pearson)
                    rSpearman_smA,_ = stats.spearmanr(np.ravel(testTarget_smA[indCPT]),prediction_smA[indCPT]) # correlation coefficient (Spearman)
                    # create dict from metrics
                    evalResults_CPT = {
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
                        'CorrSpearman_smB':rSpearman_smB
                        }
                    
                    # Queensland
                    fig = shap.plots.beeswarm(copy.deepcopy(shapQueensland),show=False,plot_size=[ps1,ps2])
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[0].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    plt.gcf().axes[-1].set_aspect(100)
                    plt.gcf().axes[-1].set_box_aspect(100)
                    plt.xlabel('SHAP value')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,"shapValuesQueensland.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValues.tex')
                    plt.close()
                    fig = shap.plots.bar(copy.deepcopy(shapQueensland))
                    plt.gcf().set_figheight(ps2)
                    plt.gcf().set_figwidth(ps1)
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[9].set_text("others")
                    yticklabels[-1].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    if useLATEX:
                        plt.xlabel('mean($|$SHAP value$|$)')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,"shapValuesQueenslandMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValuesMeanAbs.tex')
                    plt.close()
                    
                    indQueensland = shapSamples.loc[shapSamples['ID'].str.contains('case')].index.values.astype(int)
                    # evaluate prediction
                    mae = metr.mean_absolute_error(testTarget[indQueensland],prediction[indQueensland]) # MAE
                    me = np.mean(testTarget[indQueensland] - prediction[indQueensland]) # ME
                    rmse = metr.mean_squared_error(testTarget[indQueensland],prediction[indQueensland],squared=False) # RMSE
                    sd = np.std(testTarget[indQueensland] - prediction[indQueensland]) # SD
                    rPearson = np.corrcoef(np.ravel(testTarget[indQueensland]),prediction[indQueensland])[0,1] # correlation coefficient (Pearson)
                    rSpearman,_ = stats.spearmanr(np.ravel(testTarget[indQueensland]),prediction[indQueensland]) # correlation coefficient (Spearman)
                    # evaluate Hu method
                    mae_smB = metr.mean_absolute_error(testTarget_smB[indQueensland],prediction_smB[indQueensland]) # MAE
                    me_smB = np.mean(testTarget_smB[indQueensland] - prediction_smB[indQueensland]) # ME
                    rmse_smB = metr.mean_squared_error(testTarget_smB[indQueensland],prediction_smB[indQueensland],squared=False) # RMSE
                    sd_smB = np.std(testTarget_smB[indQueensland] - prediction_smB[indQueensland]) # SD
                    rPearson_smB = np.corrcoef(np.ravel(testTarget_smB[indQueensland]),prediction_smB[indQueensland])[0,1] # correlation coefficient (Pearson)
                    rSpearman_smB,_ = stats.spearmanr(np.ravel(testTarget_smB[indQueensland]),prediction_smB[indQueensland]) # correlation coefficient (Spearman)
                    # evaluate smoothing afterwards
                    mae_smA = metr.mean_absolute_error(testTarget_smA[indQueensland],prediction_smA[indQueensland]) # MAE
                    me_smA = np.mean(testTarget_smA[indQueensland] - prediction_smA[indQueensland]) # ME
                    rmse_smA = metr.mean_squared_error(testTarget_smA[indQueensland],prediction_smA[indQueensland],squared=False) # RMSE
                    sd_smA = np.std(testTarget_smA[indQueensland] - prediction_smA[indQueensland]) # SD
                    rPearson_smA = np.corrcoef(np.ravel(testTarget_smA[indQueensland]),prediction_smA[indQueensland])[0,1] # correlation coefficient (Pearson)
                    rSpearman_smA,_ = stats.spearmanr(np.ravel(testTarget_smA[indQueensland]),prediction_smA[indQueensland]) # correlation coefficient (Spearman)
                    # create dict from metrics
                    evalResults_Queensland = {
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
                        'CorrSpearman_smB':rSpearman_smB
                        }
                    
                    # PPG BP
                    fig = shap.plots.beeswarm(copy.deepcopy(shapPPGBP),show=False,plot_size=[ps1,ps2])
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[0].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    plt.gcf().axes[-1].set_aspect(100)
                    plt.gcf().axes[-1].set_box_aspect(100)
                    plt.xlabel('SHAP value')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,"shapValuesPPGBP.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValues.tex')
                    plt.close()
                    fig = shap.plots.bar(copy.deepcopy(shapPPGBP))
                    plt.gcf().set_figheight(ps2)
                    plt.gcf().set_figwidth(ps1)
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[9].set_text("others")
                    yticklabels[-1].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    if useLATEX:
                        plt.xlabel('mean($|$SHAP value$|$)')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,"shapValuesPPGBPMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValuesMeanAbs.tex')
                    plt.close()
                    
                    indPPGBP = shapSamples.loc[~shapSamples['ID'].str.contains('case') & ~shapSamples['ID'].str.contains('unisens')].index.values.astype(int)
                    # evaluate prediction
                    mae = metr.mean_absolute_error(testTarget[indPPGBP],prediction[indPPGBP]) # MAE
                    me = np.mean(testTarget[indPPGBP] - prediction[indPPGBP]) # ME
                    rmse = metr.mean_squared_error(testTarget[indPPGBP],prediction[indPPGBP],squared=False) # RMSE
                    sd = np.std(testTarget[indPPGBP] - prediction[indPPGBP]) # SD
                    rPearson = np.corrcoef(np.ravel(testTarget[indPPGBP]),prediction[indPPGBP])[0,1] # correlation coefficient (Pearson)
                    rSpearman,_ = stats.spearmanr(np.ravel(testTarget[indPPGBP]),prediction[indPPGBP]) # correlation coefficient (Spearman)
                    # evaluate Hu method
                    mae_smB = metr.mean_absolute_error(testTarget_smB[indPPGBP],prediction_smB[indPPGBP]) # MAE
                    me_smB = np.mean(testTarget_smB[indPPGBP] - prediction_smB[indPPGBP]) # ME
                    rmse_smB = metr.mean_squared_error(testTarget_smB[indPPGBP],prediction_smB[indPPGBP],squared=False) # RMSE
                    sd_smB = np.std(testTarget_smB[indPPGBP] - prediction_smB[indPPGBP]) # SD
                    rPearson_smB = np.corrcoef(np.ravel(testTarget_smB[indPPGBP]),prediction_smB[indPPGBP])[0,1] # correlation coefficient (Pearson)
                    rSpearman_smB,_ = stats.spearmanr(np.ravel(testTarget_smB[indPPGBP]),prediction_smB[indPPGBP]) # correlation coefficient (Spearman)
                    # evaluate smoothing afterwards
                    mae_smA = metr.mean_absolute_error(testTarget_smA[indPPGBP],prediction_smA[indPPGBP]) # MAE
                    me_smA = np.mean(testTarget_smA[indPPGBP] - prediction_smA[indPPGBP]) # ME
                    rmse_smA = metr.mean_squared_error(testTarget_smA[indPPGBP],prediction_smA[indPPGBP],squared=False) # RMSE
                    sd_smA = np.std(testTarget_smA[indPPGBP] - prediction_smA[indPPGBP]) # SD
                    rPearson_smA = np.corrcoef(np.ravel(testTarget_smA[indPPGBP]),prediction_smA[indPPGBP])[0,1] # correlation coefficient (Pearson)
                    rSpearman_smA,_ = stats.spearmanr(np.ravel(testTarget_smA[indPPGBP]),prediction_smA[indPPGBP]) # correlation coefficient (Spearman)
                    # create dict from metrics
                    evalResults_PPGBP = {
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
                        'CorrSpearman_smB':rSpearman_smB
                        }
                ###############################################################
                
                # visualize the first prediction's explanation
                #fig = shap.plots.waterfall(shap_values[0])
                #fig = shap.plots.waterfall(copy.deepcopy(shap_values)[0])
                #plt.savefig(path.join(filePath,"shapValuesFirst.pdf"), bbox_inches = 'tight', pad_inches = 0)
                #tikz.save(filepath+'shapValuesFirst.tex')
                #plt.close()
                
# =============================================================================
# old: with train shaps
#                 # visualize dependence plot for chosen features
#                 shapPath = path.join(filePath,"dependence")
#                 if not path.exists(shapPath):
#                     os.mkdir(shapPath)
#                 for feature in dependencePlotFeatures:
#                     if feature == 'b/a':
#                         featurename = 'b_a'
#                         b_a = copy.deepcopy(shap_values)[:,feature]
#                         if doDependenceInteractions:
#                             fig = shap.plots.scatter(b_a, color=copy.deepcopy(shap_values), xmin=b_a.percentile(1), hist = False)
#                         else:
#                             fig = shap.plots.scatter(b_a, xmin=b_a.percentile(1), hist = False)
#                         #plt.xlabel('sample')
#                         plt.grid(visible=False)
#                         plt.savefig(path.join(shapPath,featurename+"OutliersRemoved.pdf"), bbox_inches = 'tight', pad_inches = 0)
#                         #tikz.save(filepath+'shapMap.tex')
#                         plt.close()
#                     else:
#                         featurename = feature
#                     if doDependenceInteractions:
#                         fig = shap.plots.scatter(copy.deepcopy(shap_values)[:,feature], color=copy.deepcopy(shap_values), hist = False)
#                     else:
#                         fig = shap.plots.scatter(copy.deepcopy(shap_values)[:,feature], hist = False)
#                     #plt.xlabel('sample')
#                     plt.grid(visible=False)
#                     plt.savefig(path.join(shapPath,featurename+".pdf"), bbox_inches = 'tight', pad_inches = 0)
#                     #tikz.save(filepath+'shapMap.tex')
#                     plt.close()
#                 
#                 # summarize the effects of all the features
#                 fig = shap.plots.beeswarm(copy.deepcopy(shap_values),show=False)
#                 plt.gcf().axes[-1].set_aspect(100)
#                 plt.gcf().axes[-1].set_box_aspect(100)
#                 plt.xlabel('SHAP value')
#                 plt.grid(visible=False)
#                 plt.savefig(path.join(filePath,"shapValues.pdf"), bbox_inches = 'tight', pad_inches = 0)
#                 #tikz.save(filepath+'shapValues.tex')
#                 plt.close()
#                 
#                 # summarize the effects of all the features (mean absolutes)
#                 #fig = shap.plots.bar(shap_values)
#                 fig = shap.plots.bar(copy.deepcopy(shap_values))
#                 if useLATEX:
#                     plt.xlabel('mean($|$SHAP value$|$)')
#                 plt.grid(visible=False)
#                 plt.savefig(path.join(filePath,"shapValuesMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
#                 #tikz.save(filepath+'shapValuesMeanAbs.tex')
#                 plt.close()
# =============================================================================
                
                # visualize dependence plot for chosen features
                shapPath = path.join(filePath,"dependence")
                if not path.exists(shapPath):
                    os.mkdir(shapPath)
                for feature in dependencePlotFeatures:
                    if feature == 'b/a':
                        featurename = 'b_a'
                        b_a = copy.deepcopy(shap_valuesTEST)[:,feature]
                        if doDependenceInteractions:
                            fig = shap.plots.scatter(b_a, color=copy.deepcopy(shap_valuesTEST), xmin=b_a.percentile(1), xmax=b_a.percentile(99), hist = False)
                        else:
                            fig = shap.plots.scatter(b_a, xmin=b_a.percentile(1), xmax=b_a.percentile(99), hist = False)
                        #plt.xlabel('sample')
                        plt.grid(visible=False)
                        plt.savefig(path.join(shapPath,featurename+"OutliersRemoved.pdf"), bbox_inches = 'tight', pad_inches = 0)
                        #tikz.save(filepath+'shapMap.tex')
                        plt.close()
                    else:
                        featurename = feature
                    if doDependenceInteractions:
                        fig = shap.plots.scatter(copy.deepcopy(shap_valuesTEST)[:,feature], color=copy.deepcopy(shap_valuesTEST), hist = False)
                    else:
                        fig = shap.plots.scatter(copy.deepcopy(shap_valuesTEST)[:,feature], xmin=shap_valuesTEST[:,feature].percentile(1), xmax=shap_valuesTEST[:,feature].percentile(99), hist = False)
                    #plt.xlabel('sample')
                    plt.grid(visible=False)
                    plt.savefig(path.join(shapPath,featurename+"OutliersRemoved.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapMap.tex')
                    plt.close()
                
                # summarize the effects of all the features
                fig = shap.plots.beeswarm(copy.deepcopy(shap_valuesTEST),show=False,plot_size=[ps1,ps2])
                yticklabels = plt.gcf().axes[0].get_yticklabels()
                yticklabels[0].set_text("others")
                plt.gcf().axes[0].set_yticklabels(yticklabels)
                plt.gcf().axes[-1].set_aspect(100)
                plt.gcf().axes[-1].set_box_aspect(100)
                plt.xlabel('SHAP value')
                plt.grid(visible=False)
                plt.savefig(path.join(filePath,"shapValues.pdf"), bbox_inches = 'tight', pad_inches = 0)
                tikz.save(path.join(filePath,"shapValues.tex"))
                plt.close()
                
                # summarize the effects of all the features (mean absolutes)
                #fig = shap.plots.bar(shap_values)
                fig = shap.plots.bar(copy.deepcopy(shap_valuesTEST))
                plt.gcf().set_figheight(ps2)
                plt.gcf().set_figwidth(ps1)
                yticklabels = plt.gcf().axes[0].get_yticklabels()
                yticklabels[9].set_text("others")
                yticklabels[-1].set_text("others")
                plt.gcf().axes[0].set_yticklabels(yticklabels)
                if useLATEX:
                    plt.xlabel('mean($|$SHAP value$|$)')
                plt.grid(visible=False)
                plt.savefig(path.join(filePath,"shapValuesMeanAbs.pdf"), bbox_inches = 'tight', pad_inches = 0)
                #tikz.save(filepath+'shapValuesMeanAbs.tex')
                plt.close()
                
                if doComparison:
                    # comparison with other classifiers
                    # CAT
                    regrModelCAT = cb.CatBoostRegressor().fit(trainPredictors,trainTarget,sample_weight=w)
                    predictionCAT = regrModelCAT.predict(testPredictors)
                    predictionCAT_smA = np.zeros((np.size(predictionCAT)))
                    for _,currentID in enumerate(testIDArray):
                        indicesID = test.index[test["ID"]==currentID]
                        if('unisens' in currentID):
                            ks = 11
                        elif('case' in currentID):
                            ks = 11
                        else:
                            ks = 1
                        predictionCAT_smA[indicesID] = sig.medfilt(predictionCAT[indicesID],kernel_size=ks)
                    maeCAT = metr.mean_absolute_error(testTarget_smA,predictionCAT_smA)
                    evalResults['maeCAT'] = maeCAT
                    explainerCAT = shap.Explainer(regrModelCAT)
                    shap_valuesCAT = explainerCAT(trainPredictors)
                    pickle.dump(shap_valuesCAT, open(path.join(filePath,"shapValuesCAT.pkl"), 'wb'))
                    fig = shap.plots.bar(copy.deepcopy(shap_valuesCAT))
                    plt.gcf().set_figheight(ps2)
                    plt.gcf().set_figwidth(ps1)
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[9].set_text("others")
                    yticklabels[-1].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    if useLATEX:
                        plt.xlabel('mean($|$SHAP value$|$)')
                    plt.grid(visible=False)
                    plt.savefig(path.join(filePath,"shapValuesMeanAbsCAT.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValuesMeanAbs.tex')
                    plt.close()
                    
                    
                    
                    # lightGBM
                    regrModelLGB = lgb.LGBMRegressor().fit(trainPredictors,trainTarget,sample_weight=w)
                    predictionLGB = regrModelLGB.predict(testPredictors)
                    predictionLGB_smA = np.zeros((np.size(predictionLGB)))
                    for _,currentID in enumerate(testIDArray):
                        indicesID = test.index[test["ID"]==currentID]
                        if('unisens' in currentID):
                            ks = 11
                        elif('case' in currentID):
                            ks = 11
                        else:
                            ks = 1
                        predictionLGB_smA[indicesID] = sig.medfilt(predictionLGB[indicesID],kernel_size=ks)
                    maeLGB = metr.mean_absolute_error(testTarget_smA,predictionLGB_smA)
                    evalResults['maeLGB'] = maeLGB
                    explainerLGB = shap.Explainer(regrModelLGB)
                    shap_valuesLGB = explainerLGB(trainPredictors)
                    pickle.dump(shap_valuesLGB, open(path.join(filePath,"shapValuesLGB.pkl"), 'wb'))
                    fig = shap.plots.bar(copy.deepcopy(shap_valuesLGB))
                    plt.gcf().set_figheight(ps2)
                    plt.gcf().set_figwidth(ps1)
                    yticklabels = plt.gcf().axes[0].get_yticklabels()
                    yticklabels[9].set_text("others")
                    yticklabels[-1].set_text("others")
                    plt.gcf().axes[0].set_yticklabels(yticklabels)
                    if useLATEX:
                        plt.xlabel('mean($|$SHAP value$|$)')
                    plt.grid(visible=False)
                    plt.savefig(path.join(filePath,"shapValuesMeanAbsLGB.pdf"), bbox_inches = 'tight', pad_inches = 0)
                    #tikz.save(filepath+'shapValuesMeanAbs.tex')
                    plt.close()
                
                
                evalList.append(evalResults)
                evalList_CPT.append(evalResults_CPT)
                evalList_Queensland.append(evalResults_Queensland)
                evalList_PPGBP.append(evalResults_PPGBP)
                
                
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
