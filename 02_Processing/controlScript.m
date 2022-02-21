clear all
close all
clc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% in den Funktionen noch die Pfade an die Übergebenen Pfade anpassen
% --> dafür aber erst Zusammenführung sinnvoll machen

% einbauen, dass auf alte Ergebnisse zugegriffen wird, wenn bestimmte TEile
% nicht ausgeführt werden

% what about "load algorithms" Befehle?

% finales Abspeichern der Daten anders machen --> sodass nicht einfach
% überschrieben wird --> check durchführen, ob da was existiert und wenn
% nicht "überschreiben" angewählt ist, Order

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% choose steps to be executed
doDecomposition = false;
doFeatureExtraction = false;
doTraining = false;
doTesting = true;

%% get path to datasets
if(strcmp(getenv('username'),'vince'))
    networkDrive = 'Y:';
elseif(strcmp(getenv('username'),'Vincent Fleischhauer'))
    networkDrive = 'X:';
else
    errordlg('username not known')
end
baseDatasetDir = [networkDrive,'\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\'];

%% initialize settings
settings = struct;

%% decomposeRealData
if(doDecomposition)
    settings.Decomposition = struct;
    
    % settings
    settings.Decomposition.doExclusion = false;
    settings.Decomposition.extractFullDataset = true;
    settings.Decomposition.nrmseThreshold = 0.4;
    settings.Decomposition.dataset ='CPT';
    settings.Decomposition.algorithmsFile = 'algorithmsBPestimationTEST';
    % settings only for subset
    settings.Decomposition.extractPPGIsingles = false;
    settings.Decomposition.extractPPGIensemble = true;

    % dirs
    settings.Decomposition.toDir = '2022_02_20'; % ending of dir to which data will be saved

    % execute function that stores settings
    storeSettings(baseDatasetDir,settings);

    % execute function
    decomposeRealData(baseDatasetDir,settings.Decomposition.toDir,settings.Decomposition.doExclusion, ...
        settings.Decomposition.algorithmsFile,settings.Decomposition.extractFullDataset,...
        settings.Decomposition.nrmseThreshold,settings.Decomposition.dataset, ...
        settings.Decomposition.extractPPGIsingles,settings.Decomposition.extractPPGIensemble)

    % remove current settings
    settings = rmfield(settings,'Decomposition');
    
end

%% decomposeRealData
if(doDecomposition)
    settings.Decomposition = struct;
    
    % settings
    settings.Decomposition.doExclusion = false;
    settings.Decomposition.extractFullDataset = false;
    settings.Decomposition.nrmseThreshold = 0.4;
    settings.Decomposition.dataset ='CPT';
    settings.Decomposition.algorithmsFile = 'algorithmsBPestimationTEST';
    % settings only for subset
    settings.Decomposition.extractPPGIsingles = false;
    settings.Decomposition.extractPPGIensemble = true;

    % dirs
    settings.Decomposition.toDir = '2022_02_20'; % ending of dir to which data will be saved

    % execute function that stores settings
    storeSettings(baseDatasetDir,settings);

    % execute function
    decomposeRealData(baseDatasetDir,settings.Decomposition.toDir,settings.Decomposition.doExclusion, ...
        settings.Decomposition.algorithmsFile,settings.Decomposition.extractFullDataset,...
        settings.Decomposition.nrmseThreshold,settings.Decomposition.dataset, ...
        settings.Decomposition.extractPPGIsingles,settings.Decomposition.extractPPGIensemble)

    % remove current settings
    settings = rmfield(settings,'Decomposition');
    
end

%% decomposeRealData
if(doDecomposition)
    settings.Decomposition = struct;
    
    % settings
    settings.Decomposition.doExclusion = false;
    settings.Decomposition.extractFullDataset = false;
    settings.Decomposition.nrmseThreshold = 0.4;
    settings.Decomposition.dataset ='PPG_BP';
    settings.Decomposition.algorithmsFile = 'algorithmsBPestimationTEST';
    % settings only for subset
    settings.Decomposition.extractPPGIsingles = false;
    settings.Decomposition.extractPPGIensemble = false;

    % dirs
    settings.Decomposition.toDir = '2022_02_20'; % ending of dir to which data will be saved

    % execute function that stores settings
    storeSettings(baseDatasetDir,settings);

    % execute function
    decomposeRealData(baseDatasetDir,settings.Decomposition.toDir,settings.Decomposition.doExclusion, ...
        settings.Decomposition.algorithmsFile,settings.Decomposition.extractFullDataset,...
        settings.Decomposition.nrmseThreshold,settings.Decomposition.dataset, ...
        settings.Decomposition.extractPPGIsingles,settings.Decomposition.extractPPGIensemble)

    % remove current settings
    settings = rmfield(settings,'Decomposition');
    
end

%% extractFeatures
% for subset this function can only handle one data class at a time (i.e.
% you need 2 calls of this function to 
if(doFeatureExtraction)
    % settings
    settings.Features.extractFullDataset = false;
    settings.Features.usePreviousResults = false;
    settings.Features.dataset ='CPT';
    % settings.Features.metaDataFeatures = {'ID';'Beat';'Sex';'Age';'Height';'Weight';'SBP';'DBP';'PP';'TPR'}; % add RR
    settings.Features.metaDataFeatures = {'ID';'Beat';'Sex';'Age';'Height';'Weight';'SBP';'DBP';'PP'}; % add RR % add epoch?
    % settings only for subset
    settings.Features.dataClass ='ppgiEnsemble'; % ppg, ppgiSingles, ppgiEnsemble

    % dirs
    settings.Features.fromDir = '2022_02_20'; % ending of dir from which data should be used as input
    settings.Features.toDir = '2022_02_20'; % ending of dir to which data will be saved

    % execute function that stores settings
    storeSettings(baseDatasetDir,settings);

    % execute function
    extractFeatures(baseDatasetDir,settings.Features.fromDir,settings.Features.toDir, ...
        settings.Features.extractFullDataset,settings.Features.usePreviousResults, ...
        settings.Features.dataset,settings.Features.dataClass, ...
        settings.Features.metaDataFeatures)

    % remove current settings
    settings = rmfield(settings,'Features');
end

%% trainModels
if(doTraining)
    % settings
    mixDatasets = true;
    intraSubjectMix = true; % Bedeutung: Zufälliges Ziehen aus allen Schlägen
    mixHu = true; % Bedeutung: Zufääligen Ziehen aus allen Schlägen eines Probanden
    includePPGI = true;
    PPGIdir = 'Features\SUBSET\2022_02_20\';
    % modelTypes = {'LinearMixedModel','LinearMixedModel'; ...
    %     'LinearModel','LinearModel';...
    %     'RandomForest','classreg.learning.regr.RegressionEnsemble'};
    modelTypes = {'RandomForest','classreg.learning.regr.RegressionEnsemble'};
    portionTraining = 0.8;
    if(mixDatasets)
        dataset = {'CPT','FULL';'PPG_BP','SUBSET'};
    else
        dataset = {'CPT','FULL'};
        %dataset = {'PPG_BP','SUBSET'};
    end

    % dirs
    fromDir = '2022_02_20'; % ending of dir from which data should be used as input
    toDir = '2022_02_20'; % ending of dir to which data will be saved

    % execute function
    trainModels(baseDatasetDir,fromDir,toDir,mixDatasets,intraSubjectMix,mixHu,...
        includePPGI,PPGIdir,modelTypes,portionTraining,dataset)
end

%% testModels
if(doTesting)
    % settings
    doDummyError = {false,'SBP'}; % discards trained model for a comparison of test data with mean of trainings data, test data and all data --> each comparison is treated as a 'model'
    doVisualization = {true,'','all',true,{true,'all'}}; % (1) true = plots are created; (2) 'singles' = figures for each subject separately; (3) 'all' = only combined figure; (4) true = background color divides subjects, (5) 'all' or cell containing chars that define features to be plottet with BP
    modelTypes = {'RandomForest'};
    %modelTypes = {'LinearMixedModel';'LinearModel';'RandomForest'};
    mixDatasets = true;
    intraSubjectMix = true;
    includePPGI = true;
    if(mixDatasets)
        set = 'CPTFULL_PPG_BPSUBSET';
    else
        set = {{'CPT';'FULL'},{'PPG_BP';'SUBSET'}};
        %     testSet = {'CPT';'FULL'};
        %     trainingSet = {'PPG_BP';'SUBSET'};
    end

    % dirs
    fromDir = '2022_02_20'; % ending of dir from which data should be used as input
    toDir = '2022_02_20'; % ending of dir to which data will be saved

    % execute function
    testModels(baseDatasetDir,fromDir,toDir,doDummyError,doVisualization,...
        modelTypes,mixDatasets,intraSubjectMix,includePPGI,set)
end