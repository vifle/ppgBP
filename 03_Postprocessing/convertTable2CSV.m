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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % change all underscores to something else
        % b_a --> b/a
        % all else with math mode?
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % get table var names (are the same for both tables)
        varNames = testTable.Properties.VariableNames;
        % change specific entries if they are available, change all other
        specialCases = {{'b_a','b/a'}}; % structure: {{'nameOfVarToBeChanged','changedName'},...}
        for currentCase = 1:numel(specialCases)
            idx = find(strcmp(varNames,specialCases{currentCase}{1}));
            if(~isempty(idx))
                varNames{idx} = specialCases{currentCase}{2};
            end
        end
        % problematic chars to something else by default
        problematicChars = {{'_','\_'}};
        for currentChar = 1:numel(problematicChars)
            indices = find(contains(varNames,problematicChars{currentChar}{1}));
            if(~isempty(indices))
                for idx = 1:numel(indices)
                    varNames{indices(idx)} = strrep(varNames{indices(idx)},problematicChars{currentChar}{1},problematicChars{currentChar}{2});
                end
            end
        end
        % feed var names into tables (same for both tables)
        trainTable.Properties.VariableNames = varNames;
        testTable.Properties.VariableNames = varNames;
        % continue conversion 
        writetable(trainTable,[matlabDir 'trainTable.csv']);
        writetable(testTable,[matlabDir 'testTable.csv']);
    end
end
end