clear all
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

datasetDir = [baseDatasetDir,'CPTFULL_QueenslandFULL_PPG_BPSUBSET_sampleSHAP'];

% choose directory
mixMode = {'interSubject';'intraSubject'};
ppgi = {'withPPGI';'withoutPPGI'};
for currentMode = 1:size(mixMode,1)
    if(currentMode==2)
        begin = 25;
    else
        begin = 24;
    end
    for currentPPGI = 1:size(ppgi,1)
        matlabDir = [datasetDir '\' mixMode{currentMode} '\' ppgi{currentPPGI} '\GammaGaussian2generic\'];
        if(exist(matlabDir,'dir')==7)
            shapSamples = readtable([matlabDir 'shapSamples.csv']);
            % give for bad predictions (abs(Error) >= MAE) mean abs of
            % shapley values?
            % could also make a beeswarm plot of bad predictions only
            absError_smA = abs(shapSamples.Error_smA);
            shapSamples_bad = shapSamples(absError_smA>=mean(absError_smA),begin:end);
            shapMeanAbs = array2table(mean(abs(shapSamples_bad{:,:})),'VariableNames',shapSamples_bad.Properties.VariableNames);
            [sorted,ind] = sort(mean(abs(shapSamples_bad{:,:})));
            bar(sorted)
            set(gca,'XTickLabel',shapSamples_bad.Properties.VariableNames(ind));
            saveas(gcf,[matlabDir,'badShaps.pdf']);
            close;
        else
            continue
        end

    end
end