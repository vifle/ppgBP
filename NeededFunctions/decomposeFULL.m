function decomposeFULL(sourceFolder,resultsFolder,patients,algorithms,doExclusion,nrmseThreshold)
% error code:
% 0 - everything is fine
% 1 - singleBeats is NaN
% 2 - singleBeats is no cell and not NaN; error unknown
% 3 - decomposition failed (first try)
% 4 - refining of decomposition failed
% 5 - excluded due to too few peaks

numExclusions = zeros(size(patients,1),size(algorithms,1));
numPatients = size(patients,1);
numAlgs = size(algorithms,1);

parfor actualPatientNumber=1:numPatients
%for actualPatientNumber=numPatients:numPatients
    if(exist([sourceFolder,patients{actualPatientNumber},'.mat'],'file') ~= 2)
        continue
    end
    %% load signal to be decomposed
    data = load([sourceFolder,patients{actualPatientNumber},'.mat'],...
        'beatIndices','fingerPPG');
    filteredPPG = data.fingerPPG.values;
    beatIndices = data.beatIndices;
    samplingFreq = data.fingerPPG.samplerate;
    if(size(beatIndices,2)>size(beatIndices,1))
        beatIndices = beatIndices';
    end
    if(~any(isnan(beatIndices)))
        try
            [singleBeats,~,~] = createSingleBeats(filteredPPG,samplingFreq,beatIndices);
        catch
            singleBeats = NaN;
        end
    else
        singleBeats = NaN;
    end
    for actualAlgorithm = 1:numAlgs
        %% decomposition, reconstruction and calculation of NRMSE
        
        % decompose algorithm name
        [kernelTypeMethod,numKernelsString] = split(algorithms{actualAlgorithm},{'2','3','4','5'});
        kernelTypes = kernelTypeMethod{1};
        numKernels = str2double(numKernelsString);
        initialValueMethod = kernelTypeMethod{2};
        
        decompositionResults = struct;
        numBeats = size(beatIndices,1);
        for beatNumber = 1:numBeats
%             disp(actualPatientNumber);
%             disp(actualAlgorithm);
%             disp(beatNumber);
            if(iscell(singleBeats))
                decompositionResults(beatNumber).singleBeats = singleBeats{beatNumber};
                % TODO: singleBeats can be smaller than number of beats
                % insert nan for exclusions in while loop?
                % how was this handled before?
            elseif(isnan(singleBeats))
                decompositionResults(beatNumber).singleBeats = NaN;
                decompositionResults(beatNumber).nrmse = NaN;
                decompositionResults(beatNumber).signal_mod = NaN;
                decompositionResults(beatNumber).y = cell(3,1);
                decompositionResults(beatNumber).opt_params = NaN;
                decompositionResults(beatNumber).numDecompositions = 0;
                decompositionResults(beatNumber).error = 1;
                continue      
            else
                decompositionResults(beatNumber).singleBeats = NaN;
                decompositionResults(beatNumber).nrmse = NaN;
                decompositionResults(beatNumber).signal_mod = NaN;
                decompositionResults(beatNumber).y = cell(3,1);
                decompositionResults(beatNumber).opt_params = NaN;
                decompositionResults(beatNumber).numDecompositions = 0;
                decompositionResults(beatNumber).error = 2;
                continue 
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TODO: is this solved?
            % check here if the beat has more than one peak?
            % but this would lead to the exclusion of class 4 beats...
            % maybe make that dependent on neighbour beats...if they have
            % more than one peak then it is likely that this is a
            % measurement error; also should observe full time series -->
            % can these 1 peak pulses be seen in the BP measurement as
            % well?
            numPeaks = numel(findpeaks(singleBeats{beatNumber}));
            if(numPeaks > 1 || ~(doExclusion))
                try
                    [nrmse,signal_mod,y,opt_params] = calculateNRMSE(singleBeats{beatNumber}, ...
                        singleBeats{beatNumber},samplingFreq,'normalizeOutput',true,...
                        'kernelTypes',kernelTypes,'numKernels',numKernels,...
                        'method',initialValueMethod);
                    decompositionResults(beatNumber).nrmse = nrmse;
                    decompositionResults(beatNumber).signal_mod = signal_mod;
                    decompositionResults(beatNumber).y = y;
                    decompositionResults(beatNumber).opt_params = opt_params;
                    decompositionResults(beatNumber).numDecompositions = 1;
                    decompositionResults(beatNumber).error = 0;
                catch
                    decompositionResults(beatNumber).nrmse = NaN;
                    decompositionResults(beatNumber).signal_mod = NaN;
                    decompositionResults(beatNumber).y = cell(3,1);
                    decompositionResults(beatNumber).opt_params = NaN;
                    decompositionResults(beatNumber).numDecompositions = 1;
                    decompositionResults(beatNumber).error = 3;
                end
                
                % second try goes here with refined starting parameters
                if(decompositionResults(beatNumber).nrmse < nrmseThreshold && doExclusion)
                    % try decomposition with refined initial values
                    try
                        [nrmse,signal_mod,y,opt_params] = ...
                            calculateNRMSE(singleBeats{beatNumber},singleBeats{beatNumber},samplingFreq, ...
                            'InitialValues',opt_params,'normalizeOutput',true, ...
                            'kernelTypes',kernelTypes,'numKernels',numKernels,...
                            'method',initialValueMethod);
                    catch
                        decompositionResults(beatNumber).nrmse = NaN;
                        decompositionResults(beatNumber).signal_mod = NaN;
                        decompositionResults(beatNumber).y = cell(3,1);
                        decompositionResults(beatNumber).opt_params = NaN;
                        decompositionResults(beatNumber).numDecompositions = 1;
                        decompositionResults(beatNumber).error = 4;
                    end
                    % check if result is better than threshold
                    if(nrmse < nrmseThreshold)
                        % exclude beat if nrmse is too low
                        decompositionResults(beatNumber).nrmse = NaN;
                        decompositionResults(beatNumber).signal_mod = NaN;
                        decompositionResults(beatNumber).y = cell(3,1);
                        decompositionResults(beatNumber).opt_params = NaN;
                        decompositionResults(beatNumber).numDecompositions = 2;
                        decompositionResults(beatNumber).error = 0;
                    else
                        decompositionResults(beatNumber).nrmse = nrmse;
                        decompositionResults(beatNumber).signal_mod = signal_mod;
                        decompositionResults(beatNumber).y = y;
                        decompositionResults(beatNumber).opt_params = opt_params;
                        decompositionResults(beatNumber).numDecompositions = 2;
                        decompositionResults(beatNumber).error = 0;
                    end
                end
            else
                decompositionResults(beatNumber).nrmse = NaN;
                decompositionResults(beatNumber).signal_mod = NaN;
                decompositionResults(beatNumber).y = cell(3,1);
                decompositionResults(beatNumber).opt_params = NaN;
                decompositionResults(beatNumber).numDecompositions = 0;
                decompositionResults(beatNumber).error = 5;
            end
        end
        
        numExclusions(actualPatientNumber,actualAlgorithm) = numel(find(isnan([decompositionResults.nrmse])));
        
        if(exist([resultsFolder,patients{actualPatientNumber},'\'],'dir')~=7)
            mkdir([resultsFolder,patients{actualPatientNumber},'\'])
        end
        parSave([resultsFolder,patients{actualPatientNumber},'\', ...
            [kernelTypes,num2str(numKernels),initialValueMethod],'.mat'],...
            decompositionResults, beatIndices, filteredPPG, samplingFreq);
    end
end

% TODO: overwrite certain entries?!
% Stand jetzt werden ja nur bei neuen Algorithmen neue Spalten angehängt
% wenn ich alte Spalten oder sogar nur einzelne Zeilen überarbeiten will,
% geht das nicht
% neue Zeilen anhängen geht auch nicht...aber das muss auch nicht möglich
% sein
% dafür muss ich wissen, welche Zeilen überarbeitet werden sollen

% make table out of exclusions for easier extraction of the information
% later on
if(exist([resultsFolder 'exclusions.mat'],'file')==2)
    numExclusionsNew = array2table(numExclusions,'VariableNames',{algorithms{:}});
    load([resultsFolder 'exclusions.mat'],'numExclusions');
    newVars = numExclusionsNew.Properties.VariableNames;
    oldVars = numExclusions.Properties.VariableNames;
    commonVars = oldVars(ismember(oldVars,newVars));
    numExclusions = removevars(numExclusions,commonVars);
    numExclusions = [numExclusions numExclusionsNew];
else
    numExclusions = array2table(numExclusions,'VariableNames',{algorithms{:}});
end

% doExclusion does not need to be saved; rather make it another branch of
% folders
save([resultsFolder 'exclusions.mat'],...
    'doExclusion','numExclusions');