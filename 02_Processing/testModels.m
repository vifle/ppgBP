function[] = testModels(baseDatasetDir,dirEnding,doDummyError,doVisualization,modelTypes,mixDatasets,intraSubjectMix,includePPGI,set)
%% TODO
% do visualisation
% put this into trainModels and put all of it into an optional part that is
% accessed via doTesting?
% check if specified model types are existing in source

% create a comparison table that summarizes the results for all algorithms;
% there should be separate tables for different types of models (Random
% forest, mixed model)

% add restrictions to 

% add path to decomposition functions and cell with algorithm names
addpath('..\Algorithms');
load('algorithmsBPestimation.mat','algorithms');

if(mixDatasets)
    mixedSet = set;
else
    trainingSet = set{1};
    testSet = set{2};
    %     testSet = {'CPT';'FULL'};
    %     trainingSet = {'PPG_BP';'SUBSET'};
end

%% Checkings
% do checkings:
% - are datasets for training and test for each algorithm available
% - are modelTypes available?

%% Predict & evaluate
for actualAlgorithm = 1:size(algorithms,1)
    evaluationResults = struct;
    if(mixDatasets)
        % load model and data
        if(includePPGI)
            if(intraSubjectMix)
                load(['Datasets\' mixedSet '_withPPGI\modelsMIX\intraSubject\' algorithms{actualAlgorithm,1} '\modelResults.mat']);
            else
                load(['Datasets\' mixedSet '_withPPGI\modelsMIX\interSubject\' algorithms{actualAlgorithm,1} '\modelResults.mat']);
            end
        else
            if(intraSubjectMix)
                load(['Datasets\' mixedSet '_withoutPPGI\modelsMIX\intraSubject\' algorithms{actualAlgorithm,1} '\modelResults.mat']);
            else
                load(['Datasets\' mixedSet '_withoutPPGI\modelsMIX\interSubject\' algorithms{actualAlgorithm,1} '\modelResults.mat']);
            end
        end
        % save data used
        evaluationResults.trainTable = trainTable;
        evaluationResults.testTable = testTable;
        % use only model types you are interested in
        if(doDummyError{1})
            modelTypes = {'train';'test';'all'};
        else
            modelTypes = intersect(fieldnames(modelResults),modelTypes);
        end
        % loop over model types and then the number of models for each type
        for actualModelType = 1:numel(modelTypes)
            evaluationResults.(modelTypes{actualModelType}) = struct;
            if(doDummyError{1})
                % model specifications
                responseVariable = doDummyError{2};
                evaluationResults.(modelTypes{actualModelType}).responseVar = ...
                    responseVariable;
                % predictions and ground truth
                if(strcmp(modelTypes{actualModelType},'train'))
                    evaluationResults.(modelTypes{actualModelType}).prediction = ...
                        ones(size(testTable.(responseVariable)))*mean(trainTable.(responseVariable),'omitnan'); % needs to be repeated
                elseif(strcmp(modelTypes{actualModelType},'test'))
                    evaluationResults.(modelTypes{actualModelType}).prediction = ...
                        ones(size(testTable.(responseVariable)))*mean(testTable.(responseVariable),'omitnan');
                else
                    evaluationResults.(modelTypes{actualModelType}).prediction = ...
                        ones(size(testTable.(responseVariable)))*mean([testTable.(responseVariable);trainTable.(responseVariable)],'omitnan');
                end
                evaluationResults.(modelTypes{actualModelType}).groundTruth = ...
                    testTable.(responseVariable);
                % evaluation measures
                evaluationResults.(modelTypes{actualModelType}).MAE = ...
                    mean(abs(evaluationResults.(modelTypes{actualModelType}).prediction-evaluationResults.(modelTypes{actualModelType}).groundTruth),'omitnan'); % mean absolute error
                evaluationResults.(modelTypes{actualModelType}).ME = ...
                    mean(evaluationResults.(modelTypes{actualModelType}).prediction-evaluationResults.(modelTypes{actualModelType}).groundTruth,'omitnan'); % mean error
                evaluationResults.(modelTypes{actualModelType}).SD = ...
                    std(evaluationResults.(modelTypes{actualModelType}).prediction-evaluationResults.(modelTypes{actualModelType}).groundTruth,'omitnan'); % standard deviation of error
                evaluationResults.(modelTypes{actualModelType}).r = ...
                    corr(evaluationResults.(modelTypes{actualModelType}).prediction,evaluationResults.(modelTypes{actualModelType}).groundTruth,'Rows','complete'); % correlation coefficient
            else
                models = fieldnames(modelResults.(modelTypes{actualModelType}));
                for actualModel = 1:numel(models)
                    % model specifications
                    evaluationResults.(modelTypes{actualModelType})(actualModel).model = ...
                        modelResults.(modelTypes{actualModelType}).(models{actualModel});
                    evaluationResults.(modelTypes{actualModelType})(actualModel).responseVar = ...
                        modelResults.(modelTypes{actualModelType}).(models{actualModel}).ResponseName;
                    % predictions and ground truth
                    evaluationResults.(modelTypes{actualModelType})(actualModel).prediction = ...
                        predict(modelResults.(modelTypes{actualModelType}).(models{actualModel}),testTable);
                    evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth = ...
                        testTable.(evaluationResults.(modelTypes{actualModelType})(actualModel).responseVar);
                    % evaluation measures
                    evaluationResults.(modelTypes{actualModelType})(actualModel).MAE = ...
                        mean(abs(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction-evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth),'omitnan'); % mean absolute error
                    evaluationResults.(modelTypes{actualModelType})(actualModel).ME = ...
                        mean(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction-evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth,'omitnan'); % mean error
                    evaluationResults.(modelTypes{actualModelType})(actualModel).SD = ...
                        std(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction-evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth,'omitnan'); % standard deviation of error
                    evaluationResults.(modelTypes{actualModelType})(actualModel).r = ...
                        corr(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction,evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth,'Rows','complete'); % correlation coefficient
                    if(strcmp(modelTypes{actualModelType},'RandomForest'))
                        evaluationResults.(modelTypes{actualModelType})(actualModel).imp = predictorImportance(modelResults.(modelTypes{actualModelType}).(models{actualModel})); % feature importance
                    end
                end
            end
        end
        % save evaluation results
        if(includePPGI)
            ppgiChar = '_withPPGI';
        else
            ppgiChar = '_withoutPPGI';
        end
        if(intraSubjectMix)
            mixChar = 'intraSubject';
        else
            mixChar = 'interSubject';
        end
        if(doDummyError{1})
            save(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\evaluationResultsDummy.mat'],'evaluationResults');
        else
            % visualize results
            if(doVisualization{1})
                testSubs = unique(testTable.ID);
                for actualModelType = 1:numel(modelTypes)
                    for actualModel = 1:numel(models)
                        if(strcmp(doVisualization{2},'singles'))
                            for currentSubject = 1:numel(testSubs)
                                idx = find(evaluationResults.testTable.ID==testSubs(currentSubject));
                                currentPrediction = evaluationResults.(modelTypes{actualModelType})(actualModel).prediction(idx);
                                currentGroundTruth = evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth(idx);
                                figure;
                                plot(currentPrediction)
                                hold on
                                plot(currentGroundTruth)
                                xlabel('sample')
                                ylabel('blood pressure / mmHg')
                                legend('prediction','groundTruth');
                                if(exist(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' ],'dir')~=7)
                                    mkdir(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' ])
                                end
                                savefig(gcf,['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\'  char(testSubs(currentSubject)) '.fig']);
                                close;
                                if(doVisualization{5}{1})
                                     % visualize features
                                     % if: all, single features or simply
                                     % skip if argument not valid with
                                     % message
                                     if(strcmp(doVisualization{5}{2},'all'))

                                     elseif(iscell(doVisualization{5}{2}))

                                     else
                                         continue
                                     end
                                end
                            end
                        end
                        if(strcmp(doVisualization{3},'all'))
                            figure;
                            hold on
                            if(doVisualization{4})
                                patchStart = 1;
                                minY = min([min(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction),min(evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth)]);
                                maxY = max([max(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction),max(evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth)]);
                                ylim([minY,maxY])
                                for currentSubject = 1:numel(testSubs)
                                    % determine color for patch based on modulo
                                    if(mod(currentSubject,2)==0)
                                        colorPatch = rgb('lightgrey');
                                    else
                                        colorPatch = 'w';
                                    end
                                    idx = find(evaluationResults.testTable.ID==testSubs(currentSubject));
                                    patchEnd = patchStart + length(idx)-1;
                                    patch([patchStart patchEnd patchEnd patchStart], [maxY maxY minY minY], colorPatch)
                                    patchStart = patchEnd+1;
                                end
                            end
                            hPred = plot(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction);
                            hGT = plot(evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth);
                            xlabel('sample')
                            ylabel('blood pressure / mmHg')
                            legend([hPred, hGT], 'prediction','groundTruth');
                            if(exist(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' ],'dir')~=7)
                                mkdir(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' ])
                            end
                            savefig(gcf,['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' 'all.fig']);
                            close;
                            if(doVisualization{5}{1})
                                % visualize features
                                % if: all, single features or simply
                                % skip if argument not valid with
                                % message
                                if(strcmp(doVisualization{5}{2},'all'))
                                    % take all features that are in
                                    % specified model
                                    
                                    % get features from model
                                    featureTable = evaluationResults.(modelTypes{actualModelType})(actualModel).model.X;
                                    featureNames = featureTable.Properties.VariableNames;
                                    for actualFeature = 1:size(featureNames,2)
                                        figure;
                                        hold on
                                        if(doVisualization{4})
                                            patchStart = 1;
                                            minY = min([min(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction),min(evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth)]);
                                            maxY = max([max(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction),max(evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth)]);
                                            ylim([minY,maxY])
                                            for currentSubject = 1:numel(testSubs)
                                                % determine color for patch based on modulo
                                                if(mod(currentSubject,2)==0)
                                                    colorPatch = rgb('lightgrey');
                                                else
                                                    colorPatch = 'w';
                                                end
                                                idx = find(evaluationResults.testTable.ID==testSubs(currentSubject));
                                                patchEnd = patchStart + length(idx)-1;
                                                patch([patchStart patchEnd patchEnd patchStart], [maxY maxY minY minY], colorPatch)
                                                patchStart = patchEnd+1;
                                            end
                                        end
                                        yyaxis right
                                        hFeature = plot(testTable.(featureNames{actualFeature}));
                                        ylabel([featureNames{actualFeature} ' / a.u.'])
                                        yyaxis left
                                        hBP = plot(evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth);
                                        ylabel('blood pressure / mmHg')
                                        xlabel('sample')
                                        if(exist(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' featureNames{actualFeature} '\'],'dir')~=7)
                                            mkdir(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' featureNames{actualFeature} '\'])
                                        end
                                        savefig(gcf,['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\figures\' modelTypes{actualModelType} '\' models{actualModel} '\' featureNames{actualFeature} '\' 'all.fig']);
                                        close;
                                    end
                                elseif(iscell(doVisualization{5}{2}))
                                    % read out strings in cell, compare
                                    % with patameter table and plot these
                                    % features; give warning for non
                                    % existing features, but simply
                                    % continue

                                    % the same as in 'if' only with other
                                    % subset of features

                                else
                                    continue
                                end
                            end
                        end
                    end
                end
            end
            % save results
            save(['Datasets\' mixedSet ppgiChar '\modelsMIX\' mixChar '\' algorithms{actualAlgorithm,1} '\evaluationResults.mat'],'evaluationResults');
        end
    else
        % load model and data
        load(['Datasets\' trainingSet{1,1} '\models' trainingSet{2,1} '\' algorithms{actualAlgorithm,1} '\modelResults.mat']);
        load(['Datasets\' testSet{1,1} '\beatwiseFeatures' testSet{2,1} '\tableCollection.mat']); % load feature tables
        entry = find(ismember(algorithms{actualAlgorithm,1},tableCollection(:,1))); % get the table for the chosen algorithm
        testTable = tableCollection{entry,2};
        for currentCategory = 1:numel(categoricalVars)
            testTable.(categoricalVars{currentCategory}) = nominal(testTable.(categoricalVars{currentCategory}));
        end
        % save data used
        evaluationResults.trainTable = trainTable;
        evaluationResults.trainingSet = trainingSet;
        evaluationResults.testTable = testTable;
        evaluationResults.testSet = testSet;
        % use only model types you are interested in
        modelTypes = intersect(fieldnames(modelResults),modelTypes);
        % loop over model types and then the number of models for each type
        for actualModelType = 1:numel(modelTypes)
            evaluationResults.(modelTypes{actualModelType}) = struct;
            models = fieldnames(modelResults.(modelTypes{actualModelType}));
            for actualModel = 1:numel(models)
                % model specifications
                evaluationResults.(modelTypes{actualModelType})(actualModel).model = ...
                    modelResults.(modelTypes{actualModelType}).(models{actualModel});
                evaluationResults.(modelTypes{actualModelType})(actualModel).responseVar = ...
                    modelResults.(modelTypes{actualModelType}).(models{actualModel}).ResponseName;
                % predictions and ground truth
                evaluationResults.(modelTypes{actualModelType})(actualModel).prediction = ...
                    predict(modelResults.(modelTypes{actualModelType}).(models{actualModel}),testTable);
                evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth = ...
                    testTable.(evaluationResults.(modelTypes{actualModelType})(actualModel).responseVar);
                % evaluation measures
                evaluationResults.(modelTypes{actualModelType})(actualModel).MAE = ...
                    mean(abs(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction-evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth),'omitnan'); % mean absolute error
                evaluationResults.(modelTypes{actualModelType})(actualModel).ME = ...
                    mean(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction-evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth,'omitnan'); % mean error
                evaluationResults.(modelTypes{actualModelType})(actualModel).SD = ...
                    std(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction-evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth,'omitnan'); % standard deviation of error
                evaluationResults.(modelTypes{actualModelType})(actualModel).r = ...
                    corr(evaluationResults.(modelTypes{actualModelType})(actualModel).prediction,evaluationResults.(modelTypes{actualModelType})(actualModel).groundTruth,'Rows','complete'); % correlation coefficient
            end
        end
        % save evaluation results
        save(['Datasets\' trainingSet{1,1} '\models' trainingSet{2,1} '\' algorithms{actualAlgorithm,1} '\evaluationResults.mat'],'evaluationResults');
    end
end
end