function [] = extractFeatures(baseDatasetDir,dirEnding,extractFullDataset,usePreviousResults,dataset,extractPPGI,extractPPGIensemble,metaDataFeatures)
%% TODO
% important:
% depending on number of kernels extract different number of features
% this should be thought of.

% add previous values of a variable as a variable?
% not only previous, but multiple steps back with varying distances
% easiest implementation: one variable "stepback" which defines the number
% of previous values of all features to be included
% but maybe unncessesary here...rather in model creation as a function that
% is optionally called
% this should be no more than some rearranging of a given table
% probably good idea to automatize creation of model strings then...

% metaDataFeatures need to be automated like features in order to be
% really changeable

% specify specific features that are to be overwritten

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% - doExclusions not to be saved as variable, but rather as new path branch
% --> handle exclusions/not exclusion path in a better way
% --> maybe doExclusion is an additional ensurance besides the path? seems
% unneccessaty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% include ppgi optionally and treat as belonging to specific dataset as
% additional samples for that subject

% CPT special case: subjects CAN have multiple unique identifiers --> merge
% them

% add restrictions to inputs

%% Paths
% add path to functions that are required (derivation, adding noise,...)
addpath('..\NeededFunctions');
% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
% add path to feature functions and cell with feature names
addpath('..\Features');
addpath('..\Features\decomposition');
addpath('..\Features\secondDerivative');
addpath('..\Features\statistical');
addpath('..\Features\frequency');
% load file containing algorithms here
load('algorithmsBPestimation.mat','algorithms');
% load file containing features here
load('featuresExpanded.mat','features');
% specify source, data and results folder
if(extractFullDataset)
    sourceFolder=['Datasets\' dataset '\realDataFULL\'];
    resultsFolder=['Datasets\' dataset '\beatwiseFeaturesFULL_NOEX_2022_01_20\'];
    dataFolder=['Datasets\' dataset '\decompositionBeatwiseFULL_NOEX_2021_08_04\'];
else
    sourceFolder=['Datasets\' dataset '\realDataSUBSET\'];
    resultsFolder=['Datasets\' dataset '\beatwiseFeaturesSUBSET_NOEX_2022_01_20\'];
    dataFolder=['Datasets\' dataset '\decompositionBeatwiseSUBSET_NOEX_2022_01_05\'];
    epochFile = load(['Datasets\' dataset '\epochs.mat']);
end
% load data information
load([sourceFolder 'physiologicalMeasuresTable.mat']);
load([dataFolder 'exclusions.mat']);
patients=physiologicalMeasuresTable.SubjectID; % loads list with patients

%% Extraction
% initialize table with right size and types
if(exist([resultsFolder 'tableCollection.mat'],'file')==2)
    if(usePreviousResults)
        tableCollection = cell(size(algorithms,1),2);
        prevResults = load([resultsFolder 'tableCollection.mat'],'tableCollection');
        prevResultsRearranged = cell(size(algorithms,1),2);
        for actualAlgorithm = 1:size(algorithms,1)
            if(any(strcmp(prevResults.tableCollection(:,1),algorithms{actualAlgorithm})))
                prevResultsRearranged{actualAlgorithm,2} = prevResults.tableCollection{strcmp(algorithms{actualAlgorithm},prevResults.tableCollection(:,1)),2};
            end
        end
        exclusionsExtraction = zeros(size(patients,1),size(algorithms,1)); % assign table heads later
        beatsRemaining = array2table(zeros(size(patients,1),size(algorithms,1)),'VariableNames',algorithms);
    else
        tableCollection = cell(size(algorithms,1),2);
        prevResultsRearranged = cell(size(algorithms,1),2);
        exclusionsExtraction = zeros(size(patients,1),size(algorithms,1)); % assign table heads later
        beatsRemaining = array2table(zeros(size(patients,1),size(algorithms,1)),'VariableNames',algorithms);
    end
else
    usePreviousResults = false;
    tableCollection = cell(size(algorithms,1),2);
    prevResultsRearranged = cell(size(algorithms,1),2); % otherwise I get error:
    % Error: Invalid syntax for calling function 'prevResultsRearranged' on the path. 
    %Use a valid syntax or explicitly initialize 'prevResultsRearranged' to make it a variable.
    exclusionsExtraction = zeros(size(patients,1),size(algorithms,1)); % assign table heads later
    beatsRemaining = array2table(zeros(size(patients,1),size(algorithms,1)),'VariableNames',algorithms);
end

% initialize table template
featureNames = [metaDataFeatures(:);features(:,1)];
featureTypes = cell(size(featureNames,1),size(featureNames,2));
featureTypes(:) = {'double'};
numCols = numel(metaDataFeatures) + size(features,1); % metaData features + features for prediction
numRows = 0;
for actualSubject = 1:size(patients,1)
    if(extractPPGIensemble && ~extractPPGI)
        numBeats = 1;
    else
        numBeats = size(physiologicalMeasuresTable.SBP(actualSubject).values,1);
    end
    numRows = numRows + numBeats;
    beatsRemaining(actualSubject,:) = {numBeats};
end
featureTableLongTemplate = table('Size',[numRows numCols],'VariableNames',featureNames,'VariableTypes',featureTypes);

% make data categorical
featureTableLongTemplate.ID = categorical(featureTableLongTemplate.ID);
featureTableLongTemplate.Beat = categorical(featureTableLongTemplate.Beat);
featureTableLongTemplate.Sex = categorical(featureTableLongTemplate.Sex);

% calculate results
numAlg = size(algorithms,1);
numSubjects = size(patients,1);
%for actualAlgorithm = 1:numAlg % only for convenience (debugging)
parfor actualAlgorithm = 1:numAlg
    if(~usePreviousResults)
        % adapt template
        featureTableLong = featureTableLongTemplate;
    else
        % get correct table from cell array
        if(isempty(prevResultsRearranged{actualAlgorithm,2}))
            featureTableLong = featureTableLongTemplate;
        else
            featureTableLong = prevResultsRearranged{actualAlgorithm,2};
            existingParams = featureTableLong.Properties.VariableNames;
            nonExistingParams = [];
            for actualFeature = 1:size(features,1)
                if(~any(strcmp(existingParams,features{actualFeature,1})))
                    featureTableLong.(features{actualFeature})(:) = NaN;
                    nonExistingParams = [nonExistingParams;features(actualFeature,1)];
                end
            end
        end
    end
    
    i = 1;
    % fill table, also do loading
    for actualSubject = 1:numSubjects
        if(extractFullDataset)
            currentFilePath = [dataFolder patients{actualSubject} '\' algorithms{actualAlgorithm} '.mat'];
            currentFile = load(currentFilePath,'decompositionResults','samplingFreq');
            for actualBeat = 1:size(currentFile.decompositionResults,2)
                % skip if using previous results and meta data is already
                % in table
                if(~(usePreviousResults && ~isempty(featureTableLong.ID(i,1))))
                    % get correct label for every beat
                    featureTableLong.ID(i,1) = physiologicalMeasuresTable.SubjectID(actualSubject);
                    featureTableLong.Beat(i,1) = categorical(actualBeat);
                    % get meta data
                    featureTableLong.Sex(i,1) = physiologicalMeasuresTable.Sex_M_F_(actualSubject);
                    featureTableLong.Age(i,1) = physiologicalMeasuresTable.Age_year_(actualSubject);
                    featureTableLong.Height(i,1) = physiologicalMeasuresTable.Height_cm_(actualSubject);
                    featureTableLong.Weight(i,1) = physiologicalMeasuresTable.Weight_kg_(actualSubject);
                    % get features from reference
                    featureTableLong.SBP(i,1) = physiologicalMeasuresTable.SBP(actualSubject).values(actualBeat);
                    featureTableLong.DBP(i,1) = physiologicalMeasuresTable.DBP(actualSubject).values(actualBeat);
                    featureTableLong.PP(i,1) = physiologicalMeasuresTable.PP(actualSubject).values(actualBeat);
                end
                % get features from PPG
                for actualFeature = 1:size(features,1)
                    % skip if using previous results and feature is
                    % already calculated
                    if(~(usePreviousResults && ~any(strcmp(nonExistingParams,features{actualFeature,1}))))
                        try
                            featureTableLong.(features{actualFeature})(i,1) = feval(['calculate_' features{actualFeature,1}], ...
                                currentFile.decompositionResults(actualBeat).signal_mod, ...
                                currentFile.decompositionResults(actualBeat).singleBeats, ...
                                currentFile.decompositionResults(actualBeat).y, ...
                                currentFile.decompositionResults(actualBeat).opt_params, ...
                                algorithms{actualAlgorithm}, ...
                                currentFile.samplingFreq);
                        catch
                            featureTableLong.(features{actualFeature,1})(i,1) = NaN;
                        end
                    end
                end
                if(any(ismissing(featureTableLong(i,:))))
                    exclusionsExtraction(actualSubject,actualAlgorithm) = exclusionsExtraction(actualSubject,actualAlgorithm) + 1;
                end
                % get to next table row
                i=i+1;
            end
        else
            beatNumber = 0;
            for currentInterval = 1:size(epochFile.epochs,1)
                if(extractPPGI && ~extractPPGIensemble)
                    currentFilePath = [dataFolder patients{actualSubject} '\' epochFile.epochs{currentInterval} '\' algorithms{actualAlgorithm} '_ppgi.mat'];
                elseif(extractPPGIensemble && ~extractPPGI)
                    currentFilePath = [dataFolder patients{actualSubject} '\' epochFile.epochs{currentInterval} '\' algorithms{actualAlgorithm} '_ensembleBeat.mat'];
                elseif((~extractPPGI && ~extractPPGIensemble) || (extractPPGI && extractPPGIensemble))
                    currentFilePath = [dataFolder patients{actualSubject} '\' epochFile.epochs{currentInterval} '\' algorithms{actualAlgorithm} '.mat'];
                end
                
                % check if filepath exists, otherwise skip
                if(~(exist(currentFilePath,'file')==2))
                    continue
                end
                
                currentFile = load(currentFilePath,'decompositionResults','samplingFreq');
                for actualBeat = 1:size(currentFile.decompositionResults,2)
                    % skip if using previous results and meta data is already
                    % in table
                    if(~(usePreviousResults && ~isempty(featureTableLong.ID(i,1))))
                        % get correct label for every beat
                        featureTableLong.ID(i,1) = physiologicalMeasuresTable.SubjectID(actualSubject);
                        beatNumber = beatNumber + 1;
                        featureTableLong.Beat(i,1) = categorical(beatNumber);
                        % get meta data
                        featureTableLong.Sex(i,1) = physiologicalMeasuresTable.Sex_M_F_(actualSubject);
                        featureTableLong.Age(i,1) = physiologicalMeasuresTable.Age_year_(actualSubject);
                        featureTableLong.Height(i,1) = physiologicalMeasuresTable.Height_cm_(actualSubject);
                        featureTableLong.Weight(i,1) = physiologicalMeasuresTable.Weight_kg_(actualSubject);
                        % get features from reference
                        if(extractPPGIensemble && ~extractPPGI)
                            idx = find(strcmp(physiologicalMeasuresTable.SBP(actualSubject).epochs, epochFile.epochs{currentInterval}));
                            featureTableLong.SBP(i,1) = median(physiologicalMeasuresTable.SBP(actualSubject).values(idx));
                            featureTableLong.DBP(i,1) = median(physiologicalMeasuresTable.DBP(actualSubject).values(idx));
                            featureTableLong.PP(i,1) = median(physiologicalMeasuresTable.PP(actualSubject).values(idx));
                        else
                            featureTableLong.SBP(i,1) = physiologicalMeasuresTable.SBP(actualSubject).values(actualBeat);
                            featureTableLong.DBP(i,1) = physiologicalMeasuresTable.DBP(actualSubject).values(actualBeat);
                            featureTableLong.PP(i,1) = physiologicalMeasuresTable.PP(actualSubject).values(actualBeat);
                        end
                    end
                    % get features from PPG
                    for actualFeature = 1:size(features,1)
                        % skip if using previous results and feature is
                        % already calculated
                        if(~(usePreviousResults && ~any(strcmp(nonExistingParams,features{actualFeature,1}))))
                            try
                                featureTableLong.(features{actualFeature})(i,1) = feval(['calculate_' features{actualFeature,1}], ...
                                    currentFile.decompositionResults(actualBeat).signal_mod, ...
                                    currentFile.decompositionResults(actualBeat).singleBeats, ...
                                    currentFile.decompositionResults(actualBeat).y, ...
                                    currentFile.decompositionResults(actualBeat).opt_params, ...
                                    algorithms{actualAlgorithm}, ...
                                    currentFile.samplingFreq);
                            catch
                                featureTableLong.(features{actualFeature,1})(i,1) = NaN;
                            end
                        end
                    end
                    if(any(ismissing(featureTableLong(i,:))))
                        exclusionsExtraction(actualSubject,actualAlgorithm) = exclusionsExtraction(actualSubject,actualAlgorithm) + 1;
                    end
                    % get to next table row
                    i=i+1;
                end
            end
        end
    end
    % save table in cell
    tableCollection(actualAlgorithm,:) = [{algorithms{actualAlgorithm}}, {featureTableLong}];
end

% order numExclusions in the same way as beatsRemaining just in case
if(~extractFullDataset)
    numExclusionsSum = zeros(size(patients,1),size(algorithms,1));
    for currentInterval = 1:size(epochFile.epochs,1)
        % get table of interval
        currentTable = numExclusions{currentInterval,2};
        % sort table
        oldOrder = currentTable.Properties.VariableNames;
        newOrder = algorithms;
        [~,LOCB] = ismember(newOrder,oldOrder);
        currentTable = currentTable(:,LOCB);
        % add table turned to matrix to sum matrix
        numExclusionsSum = numExclusionsSum + table2array(currentTable);
    end
    % turn matrix to table
    numExclusions = array2table(numExclusionsSum,'VariableNames',algorithms);
else
    oldOrder = numExclusions.Properties.VariableNames;
    newOrder = algorithms;
    [~,LOCB] = ismember(newOrder,oldOrder);
    numExclusions = numExclusions(:,LOCB);
end

% calculate beatsRemaining
beatsRemaining = array2table(table2array(beatsRemaining) - exclusionsExtraction,'VariableNames',algorithms);

% create table of exclusionsExtraction
exclusionsExtraction = exclusionsExtraction - table2array(numExclusions);
exclusionsExtraction = array2table(exclusionsExtraction,'VariableNames',algorithms);

% save results
if(exist(resultsFolder,'dir')~=7)
    mkdir(resultsFolder)
end
if(extractPPGI && ~extractPPGIensemble)
    save([resultsFolder 'tableCollection_ppgi.mat'],'tableCollection','numExclusions','exclusionsExtraction','beatsRemaining','-v7.3');
elseif(extractPPGIensemble && ~extractPPGI)
    save([resultsFolder 'tableCollection_ensembleBeat.mat'],'tableCollection','numExclusions','exclusionsExtraction','beatsRemaining','-v7.3');
elseif((~extractPPGI && ~extractPPGIensemble) || (extractPPGI && extractPPGIensemble))
    save([resultsFolder 'tableCollection.mat'],'tableCollection','numExclusions','exclusionsExtraction','beatsRemaining','-v7.3');
end
end