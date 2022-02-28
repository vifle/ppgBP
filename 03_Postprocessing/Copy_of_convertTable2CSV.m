clear all
close all
clc

% get path to datasets
if(strcmp(getenv('username'),'vince'))
    networkDrive = 'Y:';
elseif(strcmp(getenv('username'),'Vincent Fleischhauer'))
    networkDrive = 'X:';
else
    errordlg('username not known')
end
baseDatasetDir = [networkDrive,'\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\'];

% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
algorithmsFile = 'algorithmsBPestimationTEST';
% load file containing algorithms here
if(exist([algorithmsFile '.mat'],'file') == 2)
    load([algorithmsFile '.mat'],'algorithms');
else
    errordlg('Specified algorithmsFile does not exist.')
    return
end

% choose directory
mixMode = {'interSubject';'intraSubject'};
ppgi = {'withPPGI';'withoutPPGI'};
% loop over all tables
for currentPPGI = 1:size(ppgi,1)
    dataset = ['CPTFULL_PPG_BPSUBSET\' ppgi{currentPPGI}];
    for currentMode = 1:size(mixMode,1)
        for currentAlgorithm = 1:size(algorithms,1)
            matlabDir = [baseDatasetDir dataset '\' mixMode{currentMode} '\' algorithms{currentAlgorithm} '\'];
            if(exist(matlabDir,'dir')==7)
                load([matlabDir 'modelResults.mat'],'trainTable','testTable');
            else
                continue
            end
            writetable(trainTable,[matlabDir 'trainTable.csv']);
            writetable(testTable,[matlabDir 'testTable.csv']);
        end
    end
end