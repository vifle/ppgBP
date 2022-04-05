function[] = convertTable2CSV(datasetString)

% get path to datasets
if(strcmp(getenv('username'),'vince'))
    networkDrive = 'Y:';
elseif(strcmp(getenv('username'),'Vincent Fleischhauer'))
    networkDrive = 'X:';
else
    errordlg('username not known')
end
baseDatasetDir = [networkDrive,'\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\'];

% choose directory
mixMode = {'interSubject';'intraSubject'};
ppgi = {'withPPGI';'withoutPPGI'};
% loop over all tables
dataset = [];
for currentDataset = 1:size(datasetString,1)
    dataset = [dataset datasetString{currentDataset,1} datasetString{currentDataset,2} '_'];
end
dataset(end) = [];
for currentMode = 1:size(mixMode,1)
    for currentPPGI = 1:size(ppgi,1)
        matlabDir = [baseDatasetDir dataset '\' mixMode{currentMode} '\' ppgi{currentPPGI} '\'];
        if(exist(matlabDir,'dir')==7)
            load([matlabDir 'dataTables.mat'],'trainTable','testTable');
        else
            continue
        end
        writetable(trainTable,[matlabDir 'trainTable.csv']);
        writetable(testTable,[matlabDir 'testTable.csv']);
    end
end
end