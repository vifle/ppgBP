clear all
close all
clc

%% TODO
% put all plots in one document (?)
% make version for subsets 
% check literature for transformations of features
% make normalization optional
% integrate "regArray" in a better way 

%% Settings
referenceFeatures = {'SBP';'DBP';'PP'}; % TPR
metaData = {'Age';'Weight';'Height'}; % add RR
visualizeFullDataset = false;
visualizeIndividuals = false;
dataset ='PPG_BP';

%% Paths
% add path to functions that are required (derivation, adding noise,...)
addpath('..\NeededFunctions');
addpath('..\NeededFunctions\CPT');
% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
% add path to feature functions and cell with feature names
addpath('..\Features');
addpath('..\Features\decomposition');
addpath('..\Features\secondDerivative');
addpath('..\Features\statistical');
addpath('..\Features\frequency');
% load file containing algorithms here
load('algorithmsBESTTEST.mat','algorithms');
% load file containing features here
load('features.mat','features');

% specify source, data and results folder
if(visualizeFullDataset)
    sourceFolder=['Datasets\' dataset '\beatwiseFeaturesFULL\'];
    resultsFolder=['Datasets\' dataset '\featureAnalysisFULL\'];
else
    sourceFolder=['Datasets\' dataset '\beatwiseFeaturesSUBSET\'];
    resultsFolder=['Datasets\' dataset '\featureAnalysisSUBSET\'];
end

% load data struct
load([sourceFolder 'tableCollection.mat']);

% add reference features to feature array
allFeatures = [metaData(:);referenceFeatures(:);features(:,1)];

% check that there is an entry for every algorithm and feature
for actualAlgorithm = 1:size(algorithms,1)
    if(~(any(strcmp(algorithms{actualAlgorithm},tableCollection(:,1)))))
        errordlg(['Algorithm ' algorithms{actualAlgorithm} ' not found in table collection'],'Input Error','modal');
        return
    end
    % find correct table via comparison
    currentTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
    for actualFeature = 1:size(allFeatures,1)
        if(~(any(strcmp(allFeatures{actualFeature,1},currentTable.Properties.VariableNames))))
            errordlg(['Feature ' allFeatures{actualFeature,1} ' not found in table for ' algorithms{actualAlgorithm}],'Input Error','modal');
            return
        end
    end
    clear currentTable
end

for actualAlgorithm = 1:size(algorithms,1)
    %% Create algorithm specific paths
    modelFolder=[resultsFolder algorithms{actualAlgorithm} '\models\'];
    plotFolder=[resultsFolder algorithms{actualAlgorithm} '\plots\'];
    histogramPlots = [plotFolder 'hist\'];
    qqPlots = [plotFolder 'qq\'];
    scatterPlots = [plotFolder 'scatter\'];
    
    % check if resultsFolders exist
    if(exist(histogramPlots,'dir')~=7)
        mkdir(histogramPlots)
    end
    if(exist(qqPlots,'dir')~=7)
        mkdir(qqPlots)
    end
    if(exist(scatterPlots,'dir')~=7)
        mkdir(scatterPlots)
    end
    if(exist(modelFolder,'dir')~=7)
        mkdir(modelFolder)
    end
    
    %% Initialization
    % get correct table
    currentTable = tableCollection{strcmp(algorithms{actualAlgorithm},tableCollection(:,1)),2};
    
    % extract relevant data
    currentTable(any(ismissing(currentTable),2),:) = []; 
    
    % standardize data
    currentTable(:,4:end) = varfun(@normalize, currentTable, 'InputVariables', 4:width(currentTable));
    
    % initialize plots for individuals
    if(visualizeIndividuals)
        id = unique(currentTable.ID);
        individuals = cell(numel(id),1);
        for currentID = 1:numel(id)
            currentTableSub = currentTable(strcmp(string(id(currentID)),string(currentTable.ID)),:);
            individuals{currentID,1} = currentTableSub;
        end
        numSubs = numel(id);
        
        % initialize storage for regression coefficients
        regArray = zeros(numel(id),size(referenceFeatures,1),size(allFeatures,1));
    end
    
    % get sizes of loops
    numRefs = size(referenceFeatures,1);
    numFeatures = size(allFeatures,1);
    numTableFeatures = size(features(:,1),1);
    numRefAndMetaFeatures = numFeatures-numTableFeatures;
    
    %% Do visualization
    parfor actualFeature = 1:numFeatures
        % histograms
        figure('Name',['histogram_' allFeatures{actualFeature,1}]);
        histogram(currentTable.(allFeatures{actualFeature,1}),25);
        ylabel('frequency');
        xlabel([allFeatures{actualFeature,1} '/a.u.'],'Interpreter','none');
        savefig([histogramPlots allFeatures{actualFeature,1}]);
        close
        
        % qq plots
        figure('Name',['qqplot_' allFeatures{actualFeature,1}]);
        qqplot(currentTable.(allFeatures{actualFeature,1}));
        ylabel('normal data quantiles');
        xlabel('normal theoretical quantiles');
        savefig([qqPlots allFeatures{actualFeature,1}]);
        close
        
        % skip this if feature belongs to reference features
        if(~(any(strcmp(allFeatures{actualFeature},referenceFeatures))))
            %% Visualize scatterplots
            for actualReference = 1:numRefs
                % create scatter plots of each ppg feature vs all reference features
                figure('Name',['scatterplot_' allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1}]);
                mdl = fitlm(currentTable,[referenceFeatures{actualReference,1} ' ~ ' allFeatures{actualFeature,1}]);
                plot(mdl);   
                ylabel([referenceFeatures{actualReference,1} '/a.u.'],'Interpreter','none');
                xlabel([allFeatures{actualFeature,1} '/a.u.'],'Interpreter','none');
                currentFigureFolder = [scatterPlots '\' allFeatures{actualFeature,1} '\'];
                if(exist(currentFigureFolder,'dir')~=7)
                    mkdir(currentFigureFolder)
                end
                savefig([currentFigureFolder allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1}]);
                currentModelFolder = [modelFolder allFeatures{actualFeature,1} '\'];
                if(exist(currentModelFolder,'dir')~=7)
                    mkdir(currentModelFolder)
                end
                parSave([currentModelFolder allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1}],mdl);
                close
                
                % scatter plots for individuals
                if(visualizeIndividuals)
                    if(actualFeature>numRefAndMetaFeatures) % make 7 dependent on
                        for currentID = 1:numSubs
                            figure('Name',['scatterplot_' allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1} '_' char(id(currentID))]);
                            mdl = fitlm(individuals{currentID,1},[referenceFeatures{actualReference,1} ' ~ ' allFeatures{actualFeature,1}]);
                            regArray(currentID,actualReference,actualFeature) = mdl.Coefficients{2,1};
                            plot(mdl);
                            ylabel([referenceFeatures{actualReference,1} '/a.u.'],'Interpreter','none');
                            xlabel([allFeatures{actualFeature,1} '/a.u.'],'Interpreter','none');
                            currentFigureFolder = [scatterPlots '0_individuals\' allFeatures{actualFeature,1} '\'];
                            if(exist(currentFigureFolder,'dir')~=7)
                                mkdir(currentFigureFolder)
                            end
                            savefig([currentFigureFolder allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1} '_' char(id(currentID))]);
                            close
                            figure('Name',['scatterplot_' allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1} '_' char(id(currentID)) '_residuals']);
                            scatter(individuals{currentID,1}.(allFeatures{actualFeature,1}),mdl.Residuals.Raw);
                            ylabel([referenceFeatures{actualReference,1} '_residuals/a.u.'],'Interpreter','none');
                            xlabel([allFeatures{actualFeature,1} '/a.u.'],'Interpreter','none');
                            savefig([currentFigureFolder allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1} '_' char(id(currentID)) '_residuals']);
                            close
                            currentModelFolder = [modelFolder '0_individuals\' allFeatures{actualFeature,1} '\'];
                            if(exist(currentModelFolder,'dir')~=7)
                                mkdir(currentModelFolder)
                            end
                            parSave([currentModelFolder allFeatures{actualFeature,1} '_vs_' referenceFeatures{actualReference,1} '_' char(id(currentID))],mdl);
                        end
                    end
                end  
            end
        end
    end
    if(visualizeIndividuals)
        % assign sub tables to regression table
        subTableTypes = cell(size(referenceFeatures,1),size(referenceFeatures,2));
        subTableTypes(:) = {'double'};
        subTableTemplate = table('Size',[numel(id) size(referenceFeatures,1)],'VariableTypes',subTableTypes,'VariableNames',referenceFeatures);

        % initialize regression table
        tableFeatures = features(:,1);
        tableTypes = cell(size(tableFeatures,1),size(tableFeatures,2));
        tableTypes(:) = {{subTableTemplate}};
        regTable = table(tableTypes{:},'VariableNames',tableFeatures);

        % assign array of regression coefficients to table
        for actualTableFeature = 1:size(tableFeatures,1)
            regTable.(tableFeatures{actualTableFeature,1}){:} = array2table(squeeze(regArray(:,:,actualTableFeature+numRefAndMetaFeatures)),...
                'VariableNames',referenceFeatures,'RowNames',string(id));
        end
        % save regression table
        save([modelFolder '0_individuals\regressionTable.mat'],'regTable');
    end
end
