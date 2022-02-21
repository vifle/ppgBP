function decomposeSUBSET(sourceFolder,resultsFolder,epochs,patients,algorithms,doExclusion,nrmseThreshold,extractPPGIsingles,extractPPGIensemble)
% error code:
% 0 - everything is fine
% 1 - singleBeats is NaN
% 2 - singleBeats is no cell and not NaN; error unknown
% 3 - decomposition failed (first try)
% 4 - refining of decomposition failed
% 5 - excluded due to too few peaks

numExclusionsCurrRun = zeros(size(patients,1),size(epochs,1),size(algorithms,1));
numPatients = size(patients,1);
numAlgs = size(algorithms,1);
numIntervals = size(epochs,1);

parfor actualPatientNumber=1:numPatients
    %for actualPatientNumber=1:numPatients  % only here out of convenience (debugging)
    for currentInterval=1:numIntervals
        if(exist([sourceFolder,patients{actualPatientNumber},'\',epochs{currentInterval},'.mat'],'file') ~= 2)
            continue
        end
        %% load signal to be decomposed
        data = load([sourceFolder,patients{actualPatientNumber},'\',epochs{currentInterval},'.mat'],...
            'beatIndices','fingerPPG','ppgi','ensembleBeat');
        warning('off',warning('query','last').identifier); % shut down warnings about ippg not being included

        % check if ppgi is available
        if(isfield(data,'ppgi'))
            if(extractPPGIsingles)
                processPPGI = true; % flag for processing ppgi on
                data.ppgi.values = data.ppgi.values(:,2); % choose green channel
                data.ppgi.values = interp1(data.ppgi.samplestamp,data.ppgi.values,[0:numel(data.fingerPPG.samplestamp)]'/data.fingerPPG.samplerate); % interpolate ppgi to same length as ppg
                data.ppgi.samplerate = data.fingerPPG.samplerate;
            else
                data = rmfield(data,'ppgi');
                processPPGI = false; % flag for processing ppgi off
            end
        else
            processPPGI = false; % flag for processing ppgi off
        end

        % check if ensembleBeat is available
        if(isfield(data,'ensembleBeat'))
            if(extractPPGIensemble)
                processEnsemble = true; % flag for processing ensemble on
                ensembleTmp = data.ensembleBeat;
                data = rmfield(data,'ensembleBeat');
                data.ensembleBeat.values = ensembleTmp;
                data.ensembleBeat.samplerate = 100; % ippg samplerate should be 100 fps
            else
                data = rmfield(data,'ensembleBeat');
                processEnsemble = false; % flag for processing ensemble off
            end
        else
            processEnsemble = false; % flag for processing ensemble off
        end

        % check what types of ppg there are
        dataClasses = fieldnames(data);
        dataClasses(ismember(dataClasses,'beatIndices')) = [];

        % Loop here over ppg data
        for dataClass = 1:length(dataClasses)
            filteredPPG = data.(dataClasses{dataClass}).values;
            samplingFreq = data.(dataClasses{dataClass}).samplerate;

            % get beat indices (in loop as ensemble overwrites beat
            % indices)
            beatIndices = data.beatIndices;

            if(~strcmp(dataClasses{dataClass},'ensembleBeat'))
                if(size(beatIndices,2)>size(beatIndices,1))
                    beatIndices = beatIndices';
                end
                if(~any(isnan(beatIndices)))
                    try
                        [singleBeats,~,importantPoints] = createSingleBeats(filteredPPG,samplingFreq,beatIndices);
                    catch
                        singleBeats = NaN;
                    end
                else
                    singleBeats = NaN;
                end
            else
                singleBeats = {filteredPPG}; % for ensembleBeat the beat is already cut and detrended
                importantPoints = NaN;
                beatIndices = 1; % just give beatIndices an arbitrary value
            end
            for actualAlgorithm = 1:numAlgs
                %% decomposition, reconstruction and calculation of NRMSE

                % decompose algorithm name
                [kernelTypeMethod,numKernelsString] = split(algorithms{actualAlgorithm},{'2','3','4','5'});
                kernelTypes = kernelTypeMethod{1};
                numKernels = str2double(numKernelsString);
                initialValueMethod = kernelTypeMethod{2};

                % skip if result already exists
                if(strcmp(dataClasses{dataClass},'ppgi'))
                    ending = '_ppgi.mat';
                elseif(strcmp(dataClasses{dataClass},'ensembleBeat'))
                    ending = '_ensembleBeat.mat';
                else
                    ending = '.mat';
                end
                if(exist([resultsFolder,patients{actualPatientNumber},'\', ...
                        epochs{currentInterval},'\', ...
                        [kernelTypes,num2str(numKernels),initialValueMethod],ending],'file') == 2)
                    disp('results already exist')
                    continue
                end

                decompositionResults = struct;
                for beatNumber = 1:size(beatIndices,1)
                    if(iscell(singleBeats))
                        if(isnan(singleBeats{beatNumber}))
                            decompositionResults(beatNumber).singleBeats = NaN;
                            decompositionResults(beatNumber).importantPoints = NaN;
                            decompositionResults(beatNumber).nrmse = NaN;
                            decompositionResults(beatNumber).signal_mod = NaN;
                            decompositionResults(beatNumber).y = cell(3,1);
                            decompositionResults(beatNumber).opt_params = NaN;
                            decompositionResults(beatNumber).numDecompositions = 0;
                            decompositionResults(beatNumber).error = 0; % beat was too short and is thus set nan in createSingleBeats
                            continue
                        else
                            decompositionResults(beatNumber).singleBeats = singleBeats{beatNumber};
                            decompositionResults(beatNumber).importantPoints = importantPoints(beatNumber);
                        end
                    elseif(isnan(singleBeats))
                        decompositionResults(beatNumber).singleBeats = NaN;
                        decompositionResults(beatNumber).importantPoints = NaN;
                        decompositionResults(beatNumber).nrmse = NaN;
                        decompositionResults(beatNumber).signal_mod = NaN;
                        decompositionResults(beatNumber).y = cell(3,1);
                        decompositionResults(beatNumber).opt_params = NaN;
                        decompositionResults(beatNumber).numDecompositions = 0;
                        decompositionResults(beatNumber).error = 1;
                        continue
                    else
                        decompositionResults(beatNumber).singleBeats = NaN;
                        decompositionResults(beatNumber).importantPoints = NaN;
                        decompositionResults(beatNumber).nrmse = NaN;
                        decompositionResults(beatNumber).signal_mod = NaN;
                        decompositionResults(beatNumber).y = cell(3,1);
                        decompositionResults(beatNumber).opt_params = NaN;
                        decompositionResults(beatNumber).numDecompositions = 0;
                        decompositionResults(beatNumber).error = 2;
                        continue
                    end

                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    % TODO: is this solved?
                    % check here if the beat has more than one peak?
                    % but this would lead to the exclusion of class 4 beats...
                    % maybe make that dependent on neighbour beats...if they have
                    % more than one peak then it is likely that this is a
                    % measurement error; also should observe full time series -->
                    % can these 1 peak pulses be seen in the BP measurement as
                    % well?

                    if(~(doExclusion))
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
                    else
                        numPeaks = numel(findpeaks(singleBeats{beatNumber}));
                        if(numPeaks > 1 || ~(doExclusion))
                            try
                                [nrmse,signal_mod,y,opt_params] = calculateNRMSE(singleBeats{beatNumber}, ...
                                    singleBeats{beatNumber},samplingFreq,'normalizeOutput',true, ...
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
                                    [nrmse,signal_mod,y,opt_params] = calculateNRMSE(singleBeats{beatNumber}, ...
                                        singleBeats{beatNumber},samplingFreq,'InitialValues',opt_params, ...
                                        'normalizeOutput',true,'kernelTypes',kernelTypes,'numKernels',numKernels,...
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
                end

                numExclusionsCurrRun(actualPatientNumber,currentInterval,actualAlgorithm) = numel(find(isnan([decompositionResults.nrmse])));

                if(exist([resultsFolder,patients{actualPatientNumber},'\',epochs{currentInterval},'\'],'dir')~=7)
                    mkdir([resultsFolder,patients{actualPatientNumber},'\',epochs{currentInterval},'\'])
                end
                if(processPPGI && strcmp(dataClasses{dataClass},'ppgi'))
                    parSave([resultsFolder,patients{actualPatientNumber},'\', ...
                        epochs{currentInterval},'\',[kernelTypes, ...
                        num2str(numKernels),initialValueMethod],'_ppgi.mat'],...
                        decompositionResults,beatIndices,filteredPPG,samplingFreq);
                elseif(processEnsemble && strcmp(dataClasses{dataClass},'ensembleBeat'))
                    parSave([resultsFolder,patients{actualPatientNumber},'\', ...
                        epochs{currentInterval},'\',[kernelTypes, ...
                        num2str(numKernels),initialValueMethod],'_ensembleBeat.mat'],...
                        decompositionResults,beatIndices,filteredPPG,samplingFreq);
                else
                    parSave([resultsFolder,patients{actualPatientNumber},'\', ...
                        epochs{currentInterval},'\',[kernelTypes, ...
                        num2str(numKernels),initialValueMethod],'.mat'],...
                        decompositionResults,beatIndices,filteredPPG,samplingFreq);
                end
            end
        end
    end
end
% make table out of exclusions for easier extraction of the information
% later on
% make an exclusion table for every interval
exclusionCollection = cell(numel(epochs),2);
if(exist([resultsFolder 'exclusions.mat'],'file')==2)
    % do this if there is a file
    load([resultsFolder 'exclusions.mat'],'numExclusions');
    for i = 1:numel(epochs)
        exclusionCollection{i,1} = epochs{i};
        numExclusionsNew = array2table(squeeze(numExclusionsCurrRun(:,i,:)),'VariableNames',{algorithms{:}});
        numExclusionsOld = numExclusions{i,2};
        newVars = numExclusionsNew.Properties.VariableNames;
        oldVars = numExclusionsOld.Properties.VariableNames;
        commonVars = oldVars(ismember(oldVars,newVars));
        numExclusionsOld = removevars(numExclusionsOld,commonVars);
        numExclusionsJoin = [numExclusionsOld numExclusionsNew];
        exclusionCollection{i,2} = numExclusionsJoin;
    end
    numExclusions = exclusionCollection;
else
    % do this, if there isnt already a file
    for i = 1:numel(epochs)
        exclusionCollection{i,1} = epochs{i};
        exclusionCollection{i,2} = array2table(squeeze(numExclusionsCurrRun(:,i,:)),'VariableNames',{algorithms{:}});
    end
    numExclusions = exclusionCollection;
end

% doExclusion does not need to be saved; rather make it another branch of
% folders
save([resultsFolder 'exclusions.mat'],...
    'doExclusion','numExclusions');