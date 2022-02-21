function [] = trainModels(baseDatasetDir,fromDir,toDir,mixDatasets,intraSubjectMix,mixHu,includePPGI,PPGIdir,modelTypes,portionTraining,dataset)
%% TODO
% Namen der Tabelle überarbeiten und an andere Daten anpassen
% wie gut ist varianz erklärt? R^2 ansehen
% evtl. mal group mean centering probieren
% estimate entspricht quasi dem Korrelationsfaktor?

% der Proband sollte ein confounding factor sein. Der offset ist sicher
% unterschiedlich für verschiedene Probanden

% append exisiting modelResults?

% add restrictions to inputs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% implement dependence on algorithm used (for which model to use)

% intraSubjectMix needs to be different folder
% add dependence on dataExcluded or not

% save outputs of multiple models?
% ensure that for every algorithm the same entries are chosen for training
% and testing?

% do not save models under datasets but maybe its own "models" folder?


% wenn iPPG included sein soll, muss ich zu den entsprechenden Probanden
% einfach PPGI suchen und anfügen --> erstmal Ordner explizit angeben; nur
% für CPT; nur in mix dataset
% mit neuem identifier anfügen (125_L1_ensemble oder so) --> bei strikter
% Trennung kommen die in das richtige System
% Variable anfügen: CAM oder PPG? Könnte dem random Forest ja helfen...

%% Paths
% add path to functions that are required (derivation, adding noise,...)
addpath('..\NeededFunctions');
addpath('C:\Users\vince\sciebo\Programme\MATLAB_Tools\altmany-export_fig-4703a84')
% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
% add path to feature functions and cell with feature names
addpath('..\Features');
addpath('..\Features\decomposition');
addpath('..\Features\secondDerivative');
addpath('..\Features\statistical');
addpath('..\Features\frequency');
% load file containing algorithms here
load('algorithmsBPestimationTEST.mat','algorithms');
%load('algorithmsBPestimation3Kernels.mat','algorithms');

if(mixDatasets)
    datasetString = [];
    dataTables = cell(size(dataset,1),1);
end
for currentDataset = 1:size(dataset,1)
    % specify folders
    sourceFolder=[baseDatasetDir dataset{currentDataset,1} '\Features\' dataset{currentDataset,2} '\' fromDir '\'];
    if(~mixDatasets)
        resultsFolderBase=['Datasets\' dataset{currentDataset,1} '\models' dataset{currentDataset,2} '\'];
    end
    % load data struct
    load([sourceFolder 'tableCollection.mat']);
    if(mixDatasets)
        % create string of used datasets
        datasetString = [datasetString dataset{currentDataset,1} dataset{currentDataset,2} '_'];
        % store tableCollections
        dataTables{currentDataset,1} = tableCollection;
        % include PPGI if desired
        if(strcmp(dataset{currentDataset,1},'CPT') && includePPGI)
            load([baseDatasetDir dataset{currentDataset,1} '\' PPGIdir 'tableCollection_ensembleBeat.mat']);
            for entry = 1:size(tableCollection,1)
                % get all entries that are also in dataTables
                if(~any(strcmp(dataTables{currentDataset,1},tableCollection{entry,1})))
                    continue
                else
                    % for all entries in table collection: append _ensembleBeat
                    % to ID column to differentiate between PPGI and PPG?
                    % add data to dataTables
                    %idx = find(contains(dataTables{currentDataset,1}(:,1),tableCollection{entry,1}));
                    idx = find(strcmp([dataTables{currentDataset,1}(:,1)], tableCollection{entry,1}));
                    dataTables{currentDataset,1}{idx,2} = [dataTables{currentDataset,1}{idx,2}; tableCollection{entry,2}];
                end
            end
        end
    end
end
% specify results folder if datasets are mixed
if(mixDatasets)
    datasetString(end) = [];
    if(includePPGI)
        if(intraSubjectMix)
            resultsFolderBase=[baseDatasetDir datasetString '_withPPGI\modelsMIX\intraSubject\'];
        else
            resultsFolderBase=[baseDatasetDir datasetString '_withPPGI\modelsMIX\interSubject\'];
        end
    else
        if(intraSubjectMix)
            resultsFolderBase=[baseDatasetDir datasetString '_withoutPPGI\modelsMIX\intraSubject\'];
        else
            resultsFolderBase=[baseDatasetDir datasetString '_withoutPPGI\modelsMIX\interSubject\'];
        end
    end
end

%% check algorithms and features
randomState = rng; % save state of random number generator
allSubjects = cell(size(dataset,1),size(algorithms,1));
trainSubjects = cell(size(dataset,1),size(algorithms,1));
testSubjects = cell(size(dataset,1),size(algorithms,1));
availableVars = cell(size(dataset,1),size(algorithms,1));
usableVars = cell(size(algorithms,1),2);
mixedTables = cell(size(algorithms,1),1);
for actualAlgorithm = 1:size(algorithms,1)
    % check if tables for all need algorithms exist
    if(mixDatasets)
        for currentDataset = 1:size(dataset,1)
            if(~(any(strcmp(algorithms{actualAlgorithm},dataTables{currentDataset,1}(:,1)))))
                errordlg(['Algorithm ' algorithms{actualAlgorithm} ' not found in table collection of' dataset{currentDataset,1}],'Input Error','modal');
                return
            end
        end
    else
        if(~(any(strcmp(algorithms{actualAlgorithm},tableCollection(:,1)))))
            errordlg(['Algorithm ' algorithms{actualAlgorithm} ' not found in table collection'],'Input Error','modal');
            return
        end
    end
    
    % get variable names and their types
    if(mixDatasets)
        mixedTable = table;
        for currentDataset = 1:size(dataset,1)
            tableCollection = dataTables{currentDataset,1};
            currentTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
            
            
            if(~intraSubjectMix)
                rng(randomState); % restore random number generator state
                charID = char(currentTable.ID);
                allSubjects{currentDataset,actualAlgorithm} = unique(currentTable.ID); % only use first 3 as identifier (ensure strict separation for CPT)
                helperAll = unique(categorical(cellstr(charID(:,1:3))));
                helperTrain = helperAll(randperm(numel(helperAll),round(portionTraining*numel(helperAll))));
                trainSubjects{currentDataset,actualAlgorithm} = allSubjects{currentDataset,actualAlgorithm}(contains(string(allSubjects{currentDataset,actualAlgorithm}),string(helperTrain)));
                testSubjects{currentDataset,actualAlgorithm} = setdiff(allSubjects{currentDataset,actualAlgorithm},trainSubjects{currentDataset,actualAlgorithm});
                %trainSubjects{currentDataset,actualAlgorithm} = allSubjects{currentDataset,actualAlgorithm}(randperm(numel(allSubjects{currentDataset,actualAlgorithm}),round(portionTraining*numel(allSubjects{currentDataset,actualAlgorithm}))));
            else
                if(~mixHu)
                    rng(randomState); % restore random number generator state
                    beatID = nominal([repmat([num2str(currentDataset) '_'],numel(currentTable.ID),1) num2str([1:1:numel(currentTable.ID)]')]);
                    beatID = regexprep(cellstr(beatID), ' ', '0');
                    currentTable = addvars(currentTable,beatID,'After','Beat');
                    tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2} = currentTable;
                    dataTables{currentDataset,1} = tableCollection;
                    trainSubjects{currentDataset,actualAlgorithm} = beatID(randperm(numel(beatID),round(portionTraining*numel(beatID))));
                    testSubjects{currentDataset,actualAlgorithm} = setdiff(beatID,trainSubjects{currentDataset,actualAlgorithm});
                else
                    rng(randomState); % restore random number generator state
                    beatID = nominal([repmat([num2str(currentDataset) '_'],numel(currentTable.ID),1) num2str([1:1:numel(currentTable.ID)]')]);
                    beatID = regexprep(cellstr(beatID), ' ', '0');
                    currentTable = addvars(currentTable,beatID,'After','Beat');
                    tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2} = currentTable;
                    dataTables{currentDataset,1} = tableCollection;
                    trainSubjects{currentDataset,actualAlgorithm} = [];
                    subjectList = unique(currentTable.ID);
                    for actualSubject = 1:numel(subjectList)
                        currentBeatID = beatID(currentTable.ID == subjectList(actualSubject));
                        currentChosenSet = currentBeatID(randperm(numel(currentBeatID),round(portionTraining*numel(currentBeatID))));
                        % remember to save at least one beat for testing per subject
                        if(size(currentBeatID,1) == size(currentChosenSet,1))
                            currentChosenSet(end) = [];
                        end
                        trainSubjects{currentDataset,actualAlgorithm} = [trainSubjects{currentDataset,actualAlgorithm};currentChosenSet];
                    end
                    testSubjects{currentDataset,actualAlgorithm} = setdiff(beatID,trainSubjects{currentDataset,actualAlgorithm});
                end
            end
            
            
            availableVars{currentDataset,actualAlgorithm} = currentTable.Properties.VariableNames;
            if(currentDataset == 1)
                usableVars{actualAlgorithm,1} = availableVars{currentDataset,actualAlgorithm};
            else
                usableVars{actualAlgorithm,1} = intersect(availableVars{currentDataset,actualAlgorithm},usableVars{actualAlgorithm,1}, 'stable');
            end
        end
        for currentVariable = 1:numel(usableVars{actualAlgorithm,1})
            currentArray = [];
            for currentDataset = 1:size(dataset,1)
                tableCollection = dataTables{currentDataset,1};
                currentTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
                currentArray = [currentArray;currentTable.(usableVars{actualAlgorithm,1}{currentVariable})];
            end
            % type of currentArray?
            varType = class(currentArray);
            usableVars{actualAlgorithm,2}(1,end+1) = {varType};
            % fill mixedTable
            mixedTable.(usableVars{actualAlgorithm,1}{currentVariable}) = currentArray;
        end
        mixedTables{actualAlgorithm,1} = mixedTable;
        clear mixedTable
    else
        % find correct table via comparison
        currentTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
        % get usableVars here as all table variables and add their type
        usableVars{actualAlgorithm,1} = currentTable.Properties.VariableNames;
        for currentVariable = 1:numel(usableVars{actualAlgorithm,1})
            varType = class(currentTable.(usableVars{actualAlgorithm,1}{currentVariable}));
            usableVars{actualAlgorithm,2}(1,end+1) = {varType};
        end
        clear currentTable
    end
end

%% do actual training
for actualAlgorithm = 1:size(algorithms,1)
    %% Preproessing
    % create algorithm specific path
    resultsFolder=[resultsFolderBase algorithms{actualAlgorithm} '\'];
    figureFolder = [resultsFolder 'figures\'];  
    if(exist(figureFolder,'dir')~=7)
        mkdir(figureFolder)
    end
    
    % load tables
    if(mixDatasets)
        mixedTable = mixedTables{actualAlgorithm,1};
    else
        trainTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
    end
    
    % exclude measurements
    if(mixDatasets)
        mixedTable(any(ismissing(mixedTable),2),:) = [];
    else
        trainTable(any(ismissing(trainTable),2),:) = [];
    end
    
    % get categrorical vars
    categoricalVars = usableVars{actualAlgorithm,1}(strcmp(usableVars{actualAlgorithm,2},{'categorical'}));
    
    % turn categorical vars nominal
    for currentCategory = 1:numel(categoricalVars)
        if(mixDatasets)
            mixedTable.(categoricalVars{currentCategory}) = nominal(mixedTable.(categoricalVars{currentCategory}));
        else
            trainTable.(categoricalVars{currentCategory}) = nominal(trainTable.(categoricalVars{currentCategory}));
        end
    end
    
    % create training and test subset
    if(mixDatasets)
        trainSubjectArray = [];
        testSubjectArray = [];
        for currentDataset = 1:size(dataset,1)
            % combine subject lists of different datasets
            trainSubjectArray = [trainSubjectArray;trainSubjects{currentDataset,actualAlgorithm}];
            testSubjectArray = [testSubjectArray;testSubjects{currentDataset,actualAlgorithm}];
        end
        trainSubjectArray = nominal(trainSubjectArray);
        testSubjectArray = nominal(testSubjectArray);
        if(~intraSubjectMix)
            [idx,~] = ismember(mixedTable.ID,trainSubjectArray,'rows');
        else
            [idx,~] = ismember(mixedTable.beatID,trainSubjectArray,'rows');
        end
        trainTable = mixedTable(idx,:);
        testTable = mixedTable(~idx,:);
    end
    
    %% create models
    % mixed effects models
    if(any(ismember(modelTypes(:,1),'LinearMixedModel')))
        lme1 = fitlme(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + b_a + (P1|ID) + (P2|ID) + (T1|ID) + (T2|ID) + (b_a|ID)','fitMethod','REML')
        lme2 = fitlme(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + (P1|ID) + (P2|ID) + (T1|ID) + (T2|ID)','fitMethod','REML')
        lme3 = fitlme(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + (P1|ID) + (P2|ID) + (T1|ID) + (T2|ID) + (kurt|ID) + (skew|ID) + (SD|ID) + (freq1|ID) + (freq2|ID) + (freq3|ID) + (freq4|ID)','fitMethod','REML')
        lme4 = fitlme(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + b_a + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + (P1|ID) + (P2|ID) + (T1|ID) + (T2|ID) + (b_a|ID) + (kurt|ID) + (skew|ID) + (SD|ID) + (freq1|ID) + (freq2|ID) + (freq3|ID) + (freq4|ID)','fitMethod','REML')
        lme5 = fitlme(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + b_a + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2 + (P1|ID) + (P2|ID) + (T1|ID) + (T2|ID) + (b_a|ID) + (kurt|ID) + (skew|ID) + (SD|ID) + (freq1|ID) + (freq2|ID) + (freq3|ID) + (freq4|ID) + (W1|ID) + (W2|ID)','fitMethod','REML')
        lme6 = fitlme(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2 + (P1|ID) + (P2|ID) + (T1|ID) + (T2|ID) + (kurt|ID) + (skew|ID) + (SD|ID) + (freq1|ID) + (freq2|ID) + (freq3|ID) + (freq4|ID) + (W1|ID) + (W2|ID)','fitMethod','REML')
    end
    
    % multiple linear regression
    if(any(ismember(modelTypes(:,1),'LinearModel')))
        lm1 = fitlm(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + b_a')
        lm2 = fitlm(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2')
        lm3 = fitlm(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4')
        lm4 = fitlm(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + b_a + kurt + skew + SD + freq1 + freq2 + freq3 + freq4')
        lm5 = fitlm(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + b_a + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2')
        lm6 = fitlm(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2')
    end

    % regression tree models
    % random forest, adaboost,xgboost?
    if(any(ismember(modelTypes(:,1),'RandomForest')))
%         rf1 = fitrensemble(trainTable, ...
%             'SBP ~ P1 + P2 + T1 + T2 + b_a')
%         rf2 = fitrensemble(trainTable, ...
%             'SBP ~ P1 + P2 + T1 + T2')
%         rf3 = fitrensemble(trainTable, ...
%             'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4')
%         rf4 = fitrensemble(trainTable, ...
%             'SBP ~ P1 + P2 + T1 + T2 + b_a + kurt + skew + SD + freq1 + freq2 + freq3 + freq4')
%         rf5 = fitrensemble(trainTable, ...
%             'SBP ~ P1 + P2 + T1 + T2 + b_a + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2')
%         rf6 = fitrensemble(trainTable, ...
%             'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2')
        rf1 = fitrensemble(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2')
        rf2 = fitrensemble(trainTable, ...
            'SBP ~ P1 + P2 + T1 + T2 + kurt + skew + SD + freq1 + freq2 + freq3 + freq4 + W1 + W2 + PulseWidth')
    end
    
    % physical models
    %Ding2017 with PTT substituted
    %combination of esmaili and Hu
    
    
    % make a decision here for best model?
    %  https://stats.stackexchange.com/questions/250277/are-mixed-models-useful-as-predictive-models
    % comparison of results: file:///C:/Users/vince/AppData/Local/Temp/Folien_Schaetzverfahren_und_Modellvergleiche.pdf
    
    
    %% Report results
    
    % could also create struct beforehand
    
    
    % get names of all models
    s = whos;
    myModels = [];
    %matches = false(size(s,1),size(s,2))'; % does not make sense anyway
    if(any(ismember(modelTypes(:,1),'LinearMixedModel')))
        idx = find(ismember(modelTypes(:,1),'LinearMixedModel'));
        %matches = matches | strcmp({s.class}, modelTypes{idx,2});
        matches = strcmp({s.class}, modelTypes{idx,2});
        myModels = [myModels,[{s(matches).name};repmat({'LinearMixedModel'},1,numel(matches(matches==true)))]];
    end
    if(any(ismember(modelTypes(:,1),'LinearModel')))
        idx = find(ismember(modelTypes(:,1),'LinearModel'));
        %matches = matches | strcmp({s.class}, modelTypes{idx,2});
        matches = strcmp({s.class}, modelTypes{idx,2});
        myModels = [myModels,[{s(matches).name};repmat({'LinearModel'},1,numel(matches(matches==true)))]];
    end
    if(any(ismember(modelTypes(:,1),'RandomForest')))
        idx = find(ismember(modelTypes(:,1),'RandomForest'));
        %matches = matches | strcmp({s.class}, modelTypes{idx,2});
        matches = strcmp({s.class}, modelTypes{idx,2});
        myModels = [myModels,[{s(matches).name};repmat({'RandomForest'},1,numel(matches(matches==true)))]];
    end
    %myModels = {s(matches).name};
    
    % store all model information in a struct
    modelResults = struct;
    for actualModel = 1:size(myModels,2)
        modelResults.(myModels{2,actualModel}).(myModels{1,actualModel}) = eval(myModels{1,actualModel});
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % maybe choose best model? --> make this optional
    % which criterion to choose?
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % save model
    if(mixDatasets)
        save([resultsFolder 'modelResults.mat'],'modelResults','trainTable','testTable');
    else
        save([resultsFolder 'modelResults.mat'],'modelResults','trainTable','categoricalVars');
    end
end
end