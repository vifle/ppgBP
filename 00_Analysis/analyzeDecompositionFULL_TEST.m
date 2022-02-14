clear all
close all
clc

%% TODO
% there are no intervals to loop over
% make interval looping optional?

% display 6 beats with decompositions and second derivatives on one
% page

% make one pdf per subject
    
% every plot from page two onward is smaller than the ones on page one  


% What about parfor?

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make it possible to also plt subset decompositions!!!!
% make it optional to visualize decomposition
% add analysis of nrmse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
dataset='PPG_BP';
sourceFolder=['Data\' dataset '\realDataFULL\'];
dataFolder=['Data\' dataset '\results_beatwiseFULL\'];
plotFolder=['Data\' dataset '\plotsDecompositionFULL\'];
load([sourceFolder 'physiologicalMeasuresTable.mat']);
load([sourceFolder 'epochs.mat']);
load('algorithmsBESTTEST.mat');
patients=physiologicalMeasuresTable.SubjectID;
if(exist([plotFolder],'dir')~=7)
    mkdir([plotFolder])
end



for actualPatientNumber=2:size(patients,1)
    fileID = patients{actualPatientNumber};
    %% loop over epochs & beats & algorithms
    for actualAlgorithm = 1:size(algorithms,1)
        
        algorithmName = algorithms{actualAlgorithm};
        currentFile = [dataFolder fileID '\' algorithmName];
        try%try loading
            load(currentFile)
        catch%if not loadable
            decompositionResults.singleBeats = NaN;
            decompositionResults.meanSeg = NaN;
            decompositionResults.y=cell(3,1);
            decompositionResults.signal_mod=NaN;
            beatIndicesEnsembleBeat = NaN;
        end
        
        % optional:
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% init figure and subplots for output
        f1=figure('PaperUnits', 'normalized',...
            'PaperPosition',[0 0 1 1],...
            'NumberTitle', 'off',...
            'Name',[fileID '_' algorithms{actualAlgorithm,1}]);

        %% show signal
        currentBeat = 0;
        numPages = ceil(length(beatIndicesEnsembleBeat)/12);
        for currentPage = 1:numPages
            for currentPlot = 1:12
                %% show decomposition
                currentBeat = (currentPage-1)*12+currentPlot;
                myaxSignal(currentPlot)=subplot(4,3,currentPlot);
                
                % bedingung für currentBeat größer als gesamtanzahl beats
                
                if(currentBeat <= length(beatIndicesEnsembleBeat))
                    if(~isnan(decompositionResults(currentBeat).singleBeats))
                        plot(decompositionResults(currentBeat).singleBeats,'LineWidth',3); hold on
                        plot(decompositionResults(currentBeat).signal_mod,'Color','r')
                        for i = 1:size(decompositionResults(currentBeat).y,1)
                            plot(decompositionResults(currentBeat).y{i},'k')
                        end
                        hold off
                    else
                        plot(1:numel(decompositionResults(currentBeat).singleBeats),0) % show dummy plot
                    end
                else
                    plot(1:numel(decompositionResults(length(beatIndicesEnsembleBeat)).singleBeats),0) % show dummy plot
                end
                title({['beat: ', num2str(currentBeat), '/', num2str(numel(beatIndicesEnsembleBeat))]},'Interpreter','none')
                
                % end the loop when a multiple of pageIndex reaches length(beatIndicesEnsembleBeat)
            end
            %% format subplots
            set(myaxSignal(1:12),'XLim', [0 max(max(cell2mat({myaxSignal(1:12).XLim}')))])
            set(myaxSignal(1:12),'YLim',[min(min(cell2mat({myaxSignal(1:12).YLim}'))) max(max(cell2mat({myaxSignal(1:12).YLim}'))) ])
            %set(myaxSignal(1:length(beatIndicesEnsembleBeat)),'YLim',[min(min(cell2mat({myaxSignal(1:length(beatIndicesEnsembleBeat)).YLim}'))) max(max(cell2mat({myaxSignal(1:length(beatIndicesEnsembleBeat)).YLim}'))) ])
            
            %% store plot
            print([plotFolder 'decompositionPlot_subject' num2str(actualPatientNumber) '_' algorithmName],'-dpsc','-append')
            
            %close plot
            close all
            clear myaxSignal myaxModel f1
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        % clear this subject
        clear decompositionResults
  
    end
end
