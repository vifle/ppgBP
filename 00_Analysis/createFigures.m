%% Description
% this should be one script for creating multiple figures with several
% options
% first figure should be "methods" figure for publication, but other
% publication ready figures should be possible
% which figures and how many of each type (which subjects etc) should be
% possible to specify in the settings
close all
clear all
clc

%% Includes
addpath('..\NeededFunctions');
addpath('..\NeededFunctions\CPT');
addpath('..\Algorithms');

%% Settings
%%% type selection
doMethodExplanation = false;
doBlandAltman = false;

%%% general settings
scalingFactor=1;
myFontType='Times';
myFontSize=9/scalingFactor;

%%% method explanation figure settings
if(doMethodExplanation)
    % general
    myFigureSize=[18 8];
    % beat selection
    fullDataset = true; % need to specify segment for subset branch!!
    noExclusion = true;
    datasets = {'CPT'};
    subjects = {'104_S2_unisens'};
    beatNumbers = {21}; % do this as a matrix (one row for each subject)
    % das muss dann aber mit NaN automatisch aufgefüllt werden auf die Größe
    % der längsten Reihe!
    algorithms = {'GammaGauss2Mode'};
    percPrev = 0.8; % percentage of previous beat shown
    percNext = 0.4; % percentage of next beat shown
    % choose elements to incorporate
    showIntervals = true;
    showDetectionPoint = true;
    showMinima = true;
    showPoints = false; % display minima and detection point as points instead of lines
    showKernels = true;
    showRecomposition = false; % show sum of kernels
end

%%% bland-altman-plot
if(doBlandAltman)
    % specify path to data source
    mixDatasets = true;
    intraSubjectMix = true;
    algorithm = 'GammaGauss2Mode';
    if(mixDatasets)
        mixedSet = 'CPTFULL_PPG_BPSUBSET';
        if(intraSubjectMix)
            dataPath = ['Datasets\' mixedSet '\modelsMIX\intraSubject\' algorithm '\modelResults.mat'];
        else
            dataPath = ['Datasets\' mixedSet '\modelsMIX\interSubject\' algorithm '\modelResults.mat'];
        end
    end
    % specify model results to be displayed
    modelType = 'RandomForest';
    model = 'rf1';
    responseVar = 'SBP';
    % specify figure content
    label = {'Prediction','Ground truth','mmHg'}; % Names of data sets
    %corrinfo = {'n','SSE','r2','eq'}; % stats to display of correlation scatter plot
    corrinfo = {}; % stats to display of correlation scatter plot
    BAinfo = {}; % stats to display on Bland-Altman plot
    limits = 'auto'; % how to set the axes limits
    colors = 'br'; % character codes
end

%% method explanation figure
if(doMethodExplanation)
    % fill beat numbers
    
    % check if chosen beat number has previous and subsequent beat detected
    % problematic could be that sometimes the end point is the last sample
    % of segment, because this here only works if the stopindex of previous
    % beat is the startindex of next beat 43-45 scheint nicht gut zu
    % funktionieren...
    % zumindest bei 43 scheinen die indices einfach mist zu sein
    % das könnte sich auch auf die eigentlich zrlegung ausgewirkt haben,
    % dem muss ich nachgehen...
    % ich gehe davon aus, dass bei diesen Beats die dicrotic notch als
    % endsegment gefunden wird. das sollte man beheben können, indem
    % geprüft wird, ob das eine realistische herzrate ist. und statt das
    % letzte sample zu nehmen, wenn kein ende gefunden wird, könnte man
    % einfach den beat verlängern, dann das erste minimum nehmen und
    % schauen, ob das eine realistische länge ist, könnte für das single
    % beat machen auch etwas mehr als 1 segmentLength nehmen
    
    % there are some beats that simply are not pretty... but you choose the
    % beat you want to display. I could include an auto function that does
    % figures for the 5 beats with the best NRMSE
    
    % begin looping here, no parfor needed
    for currentDataset = 1:numel(datasets)
        for actualSubject = 1:numel(subjects)
            for actualAlgorithm = 1:numel(algorithms)
                for actualBeat = 1:size(beatNumbers,2)
                    
                    % everything can be loaded from decompositionFolder
                    
                    % load data
                    % --> load
                    if(fullDataset)
                        if(noExclusion)
                            sourceFolder=['Datasets\' datasets{currentDataset} '\decompositionBeatwiseFULL_NOEX\'];
                        else
                            %not implemented yet
                            %sourceFolder=['Datasets\' datasets{currentDataset} '\decompositionBeatwiseFULL_EX\'];
                        end
                    else
                        load(['Datasets\' datasets{currentDataset} '\epochs.mat']);
                        if(noExclusion)
                            sourceFolder=['Datasets\' datasets{currentDataset} '\decompositionBeatwiseSUBSET_NOEX\'];
                        else
                            %not implemented yet
                            %sourceFolder=['Datasets\' datasets{currentDataset} '\decompositionBeatwiseSUBSET_EX\'];
                        end
                    end
                    
                    % error messages for non-available beats/algorithms etc?
                    if(exist([sourceFolder subjects{actualSubject} '.mat'],'file') ~= 2)
                        % give error message
                    end
                    % check if specified beat exists
                    
                    resultsFolder=['PublicationFigures\MethodsFigure\' datasets{currentDataset} '\'];
                    if(exist([resultsFolder],'dir')~=7)
                        mkdir([resultsFolder]);
                    end
                    
                    %% load signal to be decomposed
                    load([sourceFolder subjects{actualSubject} '\' algorithms{actualAlgorithm} '.mat']);
                    
                    [singleBeats_processed,singleBeats,indices,detectionPoint,borders,trends] = ...
                        createSingleBeats(filteredPPG,samplingFreq,beatIndices,beatIndices);
                    
                    
                    ppg_signal = singleBeats{beatNumbers{actualBeat}};
                    cutOutPrev = ppg_signal(1:indices{beatNumbers{actualBeat},1}-1);
                    ppg_signal = ppg_signal(indices{beatNumbers{actualBeat},1}:indices{beatNumbers{actualBeat},2});
                    
                    ppg_signalPrev = singleBeats{beatNumbers{actualBeat}-1};
                    spanPrev = numel(indices{beatNumbers{actualBeat}-1,1}:indices{beatNumbers{actualBeat}-1,2}-1);
                    ppg_signalPrev = ppg_signalPrev((indices{beatNumbers{actualBeat}-1,2}-1 - ceil(spanPrev*percPrev)):indices{beatNumbers{actualBeat}-1,2}-1);
                    
                    ppg_signalNext = singleBeats{beatNumbers{actualBeat}+1};
                    spanNext = numel(indices{beatNumbers{actualBeat}+1,1}+1:indices{beatNumbers{actualBeat}+1,2});
                    ppg_signalNext = ppg_signalNext(indices{beatNumbers{actualBeat}+1,1}+1:(indices{beatNumbers{actualBeat}+1,1}+1 + ceil(spanNext*percNext)));
                    
                    ppg_signal = [ppg_signalPrev,ppg_signal,ppg_signalNext];
                    addedSamples = numel(ppg_signalPrev) - numel(cutOutPrev);
                    startIndex = indices{beatNumbers{actualBeat},1} + addedSamples;
                    stopIndex = indices{beatNumbers{actualBeat},2} + addedSamples;
                    detectionPoint = detectionPoint + addedSamples;
                    
                    %ppg_signal = (ppg_signal - min(ppg_signal))/(max(ppg_signal) - min(ppg_signal)); % original beat needs to be normalized like in decomposition algorithm
                    t_ppg= 0:1/samplingFreq:(length(ppg_signal)-1)/samplingFreq;
                    figure;
                    plot(t_ppg,ppg_signal);
                    hold on
                    plot(t_ppg(startIndex),ppg_signal(startIndex),'rx');
                    plot(t_ppg(stopIndex),ppg_signal(stopIndex),'rx');
                    plot(t_ppg(detectionPoint),ppg_signal(detectionPoint),'go')
                    line([t_ppg(detectionPoint-borders(1)) t_ppg(detectionPoint-borders(1))],[1.5*min(ppg_signal) 1.5*max(ppg_signal)],'LineStyle','--','Color','black')
                    line([t_ppg(detectionPoint+borders(2)) t_ppg(detectionPoint+borders(2))],[1.5*min(ppg_signal) 1.5*max(ppg_signal)],'LineStyle','--','Color','black')
                    
                    % decomposition
                    [nrmse,signal_mod,y,opt_params] = calculateNRMSE(singleBeats_processed{beatNumbers{actualBeat}},singleBeats_processed{beatNumbers{actualBeat}},samplingFreq,algorithms{actualAlgorithm},'NormalizeInput',false);
                    plot(t_ppg(startIndex:stopIndex),y{1}+trends{beatNumbers{actualBeat}},'color',rgb('LightGray'))
                    plot(t_ppg(startIndex:stopIndex),y{2}+trends{beatNumbers{actualBeat}},'color',rgb('LightGray'))
                    plot(t_ppg(startIndex:stopIndex),signal_mod+trends{beatNumbers{actualBeat}},'black')
                    
                    % format figure
                    ylim([1.5*min(ppg_signal) 1.5*max(ppg_signal)])
                    xlabel('time / s')
                    ylabel('amplitude / a.u.')
                    box off
                    set(gcf, 'Units', 'centimeters');
                    set(gcf, 'PaperUnits', 'centimeters');
                    currentPos=get(gcf,'Position');
                    set(gcf, 'Position', [currentPos(1) currentPos(2) myFigureSize]);
                    set(findobj(gcf,'type','axes'),...
                        'FontSize', myFontSize,...
                        'FontName', myFontType,...
                        'FontWeight','normal',...
                        'TitleFontWeight','normal');
                    a=gcf;
                    a.PaperPosition=[0 0 a.Position(3:4)];
                    a.PaperSize=a.Position(3:4);
                    
                    % save figure
                    saveas(gcf,[resultsFolder 'methodExplanation'],'epsc')
                    print([resultsFolder 'methodExplanation'],'-dpdf')
                    matlab2tikz([resultsFolder 'methodExplanation.tex']);
                    savefig([resultsFolder 'methodExplanation']);
                    % add reference to dataset, subject, algorithm and beat
                    % to filename
                    
                end
            end
        end
    end
end

%% bland-altman-plot
if(doBlandAltman)
    % specify storage path
    resultsFolder=['PublicationFigures\BlandAltman\'];
    if(exist([resultsFolder],'dir')~=7)
        mkdir([resultsFolder]);
    end
    % load data and display plot
    load(dataPath);
    prediction = predict(modelResults.(modelType).(model),testTable);
    groundTruth = testTable.(responseVar);
    [cr, fig, statsStruct] = BlandAltman(prediction,groundTruth,label,'','','baInfo',BAinfo,'corrInfo',corrinfo,'axesLimits',limits,'colors',colors, 'showFitCI','off','legend','off');
    
    % format figure (font size etc)
    set(findobj(gcf,'type','axes'),...
        'FontSize', myFontSize,...
        'FontName', myFontType,...
        'FontWeight','normal',...
        'TitleFontWeight','normal');
    set(findobj(gcf,'Type','text'),...
        'FontName', myFontType);
    
    % save figure
    %cleanfigure('targetResolution',50);
    print([resultsFolder 'blandAltman'],'-dpdf')
    saveas(gcf,[resultsFolder 'blandAltman'],'epsc')
    matlab2tikz([resultsFolder 'blandAltman.tex']);
    savefig([resultsFolder 'blandAltman']);
end