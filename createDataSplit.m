% split for mix and not mix?
% eig nur für mix wirklich kompliziert
% --> erstmal nur mix
% warum werden ohne mix hier keine testTable erstellt?
% wahrscheinlich sollte das da so sein, dass ein dataset direkt das
% komplette trainignsset ist und bei test das dataset angegeben wird, auf
% dem getestet wird. Das dann jetzt so machen, dass hier auch zwei sets
% geladen werden, und die einteilung hier erfolgt und das in testModels
% entfernen

% muss das über algorithmen gemacht werden? es ist hier ja eigentlich nicht
% wichtig, ob bestimtme features bei den einen algorithmen sind und bei
% anderen nicht
% --> split machen, bevor Tabellen für verschiedene algorithmen erstellt
% werden

% unterscheidung in mit und ohne ppgi auch unsinnig, die tables können ja
% quasi übergeordnet dazu sein; aber dann wäre es besser, wenn erst in
% intra/inter getrennt wird und dadrin dann in mit/ohne ppgi

% features und algorithmen hier raus? ich will eigentlich schon Tabellen
% erstellen

% reicht es, einfach den subject split zu erstellen erstmal und
% abzuspeichern?
% brauche aber schon noch ne matlab funktion, um die Tabellen algorithmen
% spezifisch zu erstellen; das kann dann nochmal ne andere Funktion sein

% ich speichere doch den status des random states...funktioniert das nicht?
% + reicht das nicht aus, um die Funktion wie bisher sinnvoll zu nutzen?
% + umstellung der Speicherstruktur + trennen von training und tabellen
% --> das funktioniert; aber ich rufe die Funktion mehrmals von außen auf;
% das ist das Problem
% einfach den random state ausgeben und neu einladen?
% macht das mehrfache aufrufen von rng sinn?


function [] = createDataSplit(baseDatasetDir,fromDir,toDir,mixDatasets,intraSubjectMix,mixHu,includePPGI,PPGIdir,portionTraining,dataset)
%% Paths
% add path to functions that are required (derivation, adding noise,...)
addpath('..\NeededFunctions');
% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
% load file containing algorithms here
load('algorithmsBPestimationTEST.mat','algorithms');
%load('algorithmsBPestimation3Kernels.mat','algorithms');


%% was passiert hier?
% algorithmen werden hier nicht gebraucht
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% specify results folder if datasets are mixed
if(mixDatasets)
    datasetString(end) = [];
    if(intraSubjectMix)
        tableDir = [baseDatasetDir datasetString '\intraSubject\'];
        if(includePPGI)
            resultsFolderBase=[tableDir 'withPPGI\'];
        else
            resultsFolderBase=[tableDir 'withoutPPGI\'];
        end
    else
        tableDir = [baseDatasetDir datasetString '\interSubject\'];
        if(includePPGI)
            resultsFolderBase=[tableDir 'withPPGI\'];
        else
            resultsFolderBase=[tableDir 'withoutPPGI\'];
        end
    end
end

%% check algorithms and features --> das will ich ja eigentlich nicht
% subject kram muss ja erstmal nicht in diese funktion; ein teil davon muss
% dann eben in der Tabellen erstellungsfunktion gemacht werden
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
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % --> bis hier habe ich doch für mixed schon die subjects, die
            % train und test sind
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % --> usable vars eher in ne andere Funktion packen
            
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
%         % find correct table via comparison
%         currentTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
%         % get usableVars here as all table variables and add their type
%         usableVars{actualAlgorithm,1} = currentTable.Properties.VariableNames;
%         for currentVariable = 1:numel(usableVars{actualAlgorithm,1})
%             varType = class(currentTable.(usableVars{actualAlgorithm,1}{currentVariable}));
%             usableVars{actualAlgorithm,2}(1,end+1) = {varType};
%         end
%         clear currentTable
    end
end

%% do actual training --> no training
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
%         trainTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
    end
    
    % exclude measurements
    if(mixDatasets)
        mixedTable(any(ismissing(mixedTable),2),:) = [];
    else
%         trainTable(any(ismissing(trainTable),2),:) = [];
    end
    
    % get categrorical vars
    categoricalVars = usableVars{actualAlgorithm,1}(strcmp(usableVars{actualAlgorithm,2},{'categorical'}));
    
    % turn categorical vars nominal
    for currentCategory = 1:numel(categoricalVars)
        if(mixDatasets)
            mixedTable.(categoricalVars{currentCategory}) = nominal(mixedTable.(categoricalVars{currentCategory}));
        else
%             trainTable.(categoricalVars{currentCategory}) = nominal(trainTable.(categoricalVars{currentCategory}));
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
    
    
    
    % save tables --> % also simply save subject split?
    if(mixDatasets)
        save([tableDir 'dataTables.mat'],'trainTable','testTable');
    else
        save([resultsFolder 'modelResults.mat'],'trainTable','categoricalVars'); % TODO: welche ariablen, wo speichern? Erstmal streichen, dass datasets getrennt betrachtet werden?
    end
end
end