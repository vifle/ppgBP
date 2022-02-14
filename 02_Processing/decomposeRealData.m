function [] = decomposeRealData(baseDatasetDir,dirEnding,doExclusion,extractFullDataset,nrmseThreshold,dataset)

%% TODO
% consider class 3/4 beats in exclusions
% numExclusions must not be overwritten but rather appended
% give possibility to add decompositions without deleting the others
% add restrictions to input

%% Paths
% add path to functions that are required (derivation, adding noise,...)
addpath('..\NeededFunctions');
% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
% load file containing algorithms here
load('algorithmsBPestimation.mat','algorithms');

% initialize kernel characteristics
algorithmsStruct(size(algorithms,1)) = struct();
% extract algorithm arguments ---> TODO: do this in calculateNRMSE
for actualAlgorithm = 1:size(algorithms,1)
    [kernelTypeMethod,numKernelsString] = split(algorithms{actualAlgorithm},{'2','3','4','5'});
    algorithmsStruct(actualAlgorithm).kernelTypes = kernelTypeMethod(1);
    algorithmsStruct(actualAlgorithm).numKernels = str2double(numKernelsString);
    algorithmsStruct(actualAlgorithm).initialValueMethod = kernelTypeMethod(2);
end

% specify source and results folder
if(extractFullDataset)
    sourceFolder=['Datasets\' dataset '\realDataFULL\'];
    resultsFolder=['Datasets\' dataset '\decompositionBeatwiseFULL_NOEX_2021_08_04\']; % TODO: get NOEX or not automatically
else
    sourceFolder=['Datasets\' dataset '\realDataSUBSET\'];
    resultsFolder=['Datasets\' dataset '\decompositionBeatwiseSUBSET_NOEX_2022_01_05\'];
    load(['Datasets\' dataset '\epochs.mat']);
end
% load data information
load([sourceFolder 'physiologicalMeasuresTable.mat']);
patients=physiologicalMeasuresTable.SubjectID; % loads list with patients

%% Do decomposition
if(extractFullDataset)
    decomposeFULL(sourceFolder,resultsFolder,patients,algorithms,doExclusion,nrmseThreshold);
else
    decomposeSUBSET(sourceFolder,resultsFolder,epochs,patients,algorithms,doExclusion,nrmseThreshold);
end
end