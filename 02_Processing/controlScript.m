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
% überschrieben wird

% train und test models abspeichern lassen, welche läufe von decompose und
% extract features genutzt wurden (csv datei oder mat file)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% choose steps to be executed
doDecomposition = true;
doFeatureExtraction = true;
doTraining = true;
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

%% decomposeRealData
if(doDecomposition)
    % settings
    doExclusion = false;
    extractFullDataset = false;
    nrmseThreshold = 0.4;
    dataset ='CPT';

    % dirs
    toDir = '2022_02_02'; % ending of dir to which data will be saved
    % function that reads input dir for a file that contains information on
    % which data is used for calculation and takes this information and adds
    % new information from this section here

    % hier im Speziellen diese doExclusionNummer rausnehmen aus dem
    % Speicherpfad (also NoEx) --> Einstellungen sollen ja über datei
    % nachverfolgbar sein

    % execute function
    decomposeRealData(baseDatasetDir,dirEnding,doExclusion,extractFullDataset,...
        nrmseThreshold,dataset)
end

%% extractFeatures
if(doFeatureExtraction)
    % settings
    extractFullDataset = false;
    usePreviousResults = false;
    dataset ='CPT';
    extractPPGI = false;
    extractPPGIensemble = true;
    % metaDataFeatures = {'ID';'Beat';'Sex';'Age';'Height';'Weight';'SBP';'DBP';'PP';'TPR'}; % add RR
    metaDataFeatures = {'ID';'Beat';'Sex';'Age';'Height';'Weight';'SBP';'DBP';'PP'}; % add RR % add epoch?

    % dirs
    fromDir = ''; % ending of dir from which data should be used as input
    toDir = ''; % ending of dir to which data will be saved
    % function that reads input dir for a file that contains information on
    % which data is used for calculation and takes this information and adds
    % new information from this section here

    % execute function
    extractFeatures(baseDatasetDir,dirEnding,extractFullDataset,...
        usePreviousResults,dataset,extractPPGI,extractPPGIensemble,...
        metaDataFeatures)
end

%% trainModels
if(doTraining)
    % settings
    mixDatasets = true;
    intraSubjectMix = true; % Bedeutung: Zufälliges Ziehen aus allen Schlägen
    mixHu = true; % Bedeutung: Zufääligen Ziehen aus allen Schlägen eines Probanden
    includePPGI = true;
    PPGIdir = 'beatwiseFeaturesSUBSET_NOEX_2022_01_20\';
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
    fromDir = '2022_02_02'; % ending of dir from which data should be used as input
    toDir = '2022_02_02'; % ending of dir to which data will be saved
    % function that reads input dir for a file that contains information on
    % which data is used for calculation and takes this information and adds
    % new information from this section here

    % execute function
    trainModels(baseDatasetDir,dirEnding,mixDatasets,intraSubjectMix,mixHu,...
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
    intraSubjectMix = false;
    includePPGI = false;
    if(mixDatasets)
        set = 'CPTFULL_PPG_BPSUBSET';
    else
        set = {{'CPT';'FULL'},{'PPG_BP';'SUBSET'}};
        %     testSet = {'CPT';'FULL'};
        %     trainingSet = {'PPG_BP';'SUBSET'};
    end

    % dirs
    fromDir = '2022_02_02'; % ending of dir from which data should be used as input
    toDir = '2022_02_02'; % ending of dir to which data will be saved
    % function that reads input dir for a file that contains information on
    % which data is used for calculation and takes this information and adds
    % new information from this section here

    % execute function
    testModels(baseDatasetDir,dirEnding,doDummyError,doVisualization,...
        modelTypes,mixDatasets,intraSubjectMix,includePPGI,set)
end