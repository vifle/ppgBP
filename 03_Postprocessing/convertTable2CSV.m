clear all
close all
clc

% choose directory
includePPGI = true;
mixMode = {'interSubject';'intraSubject'};
algorithm = {'Gamma3generic';'GammaGaussian2generic';'Gaussian2generic';'Gaussian3generic'};
ppgi = {'withPPGI';'withoutPPGI'};
% loop over all tables
for currentPPGI = 1:size(ppgi,1)
    dataset = ['CPTFULL_PPG_BPSUBSET_' ppgi{currentPPGI} '\modelsMIX'];
    for currentMode = 1:size(mixMode,1)
        for currentAlgorithm = 1:size(algorithm,1)
            matlabDir = ['..\Datasets\' dataset '\' mixMode{currentMode} '\' algorithm{currentAlgorithm} '\'];
            pythonDir = ['dataTables\' dataset '\' mixMode{currentMode} '\' algorithm{currentAlgorithm} '\'];
            if(exist(matlabDir,'dir')==7)
                load([matlabDir 'modelResults.mat'],'trainTable','testTable');
            else
                continue
            end
            if(exist(pythonDir,'dir')~=7)
                mkdir(pythonDir)
            end
            writetable(trainTable,[pythonDir 'trainTable.csv']);
            writetable(testTable,[pythonDir 'testTable.csv']);
        end
    end
end