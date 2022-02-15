%% this script extract physiological variables (from PPG recordings)


% filter werden mit festen sampling fequenzen definiert


% compare to FULL version before using so that the structure is consistent




% make another output for complete time series (are all measurements
% equally long?)

% also analyze the usual intervals

% welche random effects: epochen sinnvoll? da unterscheiden sich die Drücke
% ja eklatant und das soll eig mein Modell abbilden ohne eine Epoche zu
% kennen...

% age, height und weight?
% geschlecht?
% --> was passiert eig wenn man kontinuierliche faktoren als random effect
% nehme?

% unisens_utility_get_customAttributes(path)
% --> metadaten for Probanden mit abspeichern
% unisens_utility_get_customAttributes('C:\Users\vince\sciebo\Forschung\Konferenzen\Paper_PPG_BP\CPTdata\unisens\unisens')

clear all %clear all variables

%% add unisens (needed to read unisens data)
javaaddpath '..\..\unisens\unisens\org\lib\org.unisens.jar'
javaaddpath '..\..\unisens\unisens\org\lib\org.unisens.ri.jar'
addpath(genpath('..\..\unisens\'))
addpath('..\..\NeededFunctions');


% specify folders
if(strcmp(getenv('username'),'vince'))
    networkDrive = 'Y:';
elseif(strcmp(getenv('username'),'Vincent Fleischhauer'))
    networkDrive = 'X:';
else
    errordlg('username not known')
end
baseFolder = [networkDrive,'\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\CPT\'];
unisensFolder=[baseFolder,'measurements\'];%unisens directory where data is stored
resultsFolder = [baseFolder,'realData\SUBSET\'];
patients=textread([unisensFolder 'allSubjects.dat'],'%s');%loads list with patient
load([unisensFolder 'epochs.mat']) %loads a variable where names of epochs are stored
pathToPPGI = [baseFolder 'ppgiData']; % path to PPGI data


% create PPG filter (this filter will be used to smooth the reference PPG)
[b,a] = butter(5, 10/(1000/2), 'low');%create bandpass to filter the pixel traces
cutOffLPF=12;%default low cutoff frequency for AC signal
cutOffLPF2=0.4;%default low cutoff frequency for DC
filterOrderLPF=5;%default filter order for the higher LP filter
filterOrderLPF2=5;%default filter order for the lower LP filter
[z1,p1,k1] = butter(filterOrderLPF,cutOffLPF/(1000/2),'low');
[sos1,g1] = zp2sos(z1,p1,k1);
%low pass filter for DC part
[z2,p2,k2] = butter(filterOrderLPF2,cutOffLPF2/(1000/2),'low');
[sos2,g2] = zp2sos(z2,p2,k2);
% define filters for downsampled PPG excerpts
cutOffLPF_tmp=12;%default low cutoff frequency for AC signal
cutOffLPF2_tmp=0.25;%default low cutoff frequency for DC
filterOrderLPF_tmp=5;%default filter order for the higher LP filter
filterOrderLPF2_tmp=5;%default filter order for the lower LP filter
[z11,p11,k11] = butter(filterOrderLPF_tmp,cutOffLPF_tmp/(100/2),'low');
[sos11,g11] = zp2sos(z11,p11,k11);
[z21,p21,k21] = butter(filterOrderLPF2_tmp,cutOffLPF2_tmp/(100/2),'low');
[sos21,g21] = zp2sos(z21,p21,k21);
myFilters=[{sos11} {g11}; {sos21} {g21}; {sos2} {g2}];
        

% create table
physiologicalMeasuresTable = table;%create a table where all results are stored
physiologicalMeasuresTable.SubjectID={};%create the column for the actual patient ID

camNum='1';%defines the camera number to be used

%% get data and do processing
for actualPatientNumber=1:size(patients,1)%loop over whole dataset
    %% get current file
    fileID=patients{actualPatientNumber}%current patient ID
    currentPatient= [unisensFolder fileID];%current patient + path
    physiologicalMeasuresTable.SubjectID(actualPatientNumber,1)={fileID};%write subject ID to result table
    
    
    %% meta data
    metaData = unisens_utility_get_customAttributes(currentPatient);
    physiologicalMeasuresTable.Sex_M_F_(actualPatientNumber)=metaData(2,2);
    physiologicalMeasuresTable.Age_year_(actualPatientNumber)=str2double(metaData{10,2});
    physiologicalMeasuresTable.Height_cm_(actualPatientNumber)=str2double(metaData{3,2});
    physiologicalMeasuresTable.Weight_kg_(actualPatientNumber)=str2double(metaData{6,2});
    
    %% read physiological data   
    % why the median filter?
    
    systolicBP = unisens_get_data(currentPatient,'systolicBP_BS.csv','all');%get responses
    systolicBP.samplestamp = systolicBP.samplestamp*1000/unisens_get_samplerate(currentPatient,'systolicBP_BS.csv');
    systolicBP.values=medfilt1(systolicBP.values,5,'truncate');
    
    diastolicBP = unisens_get_data(currentPatient,'diastolicBP_BS.csv','all');%get responses
    diastolicBP.samplestamp = diastolicBP.samplestamp*1000/unisens_get_samplerate(currentPatient,'diastolicBP_BS.csv');
    diastolicBP.values=medfilt1(diastolicBP.values,5,'truncate');
    
    pulsePressure.samplestamp = systolicBP.samplestamp;
    pulsePressure.values = systolicBP.values - diastolicBP.values;
    
    tpr = unisens_get_data(currentPatient,'TPR_BS.csv','all');%get responses
    tpr.samplestamp = tpr.samplestamp*1000/unisens_get_samplerate(currentPatient,'TPR_BS.csv');
    tpr.values=medfilt1(tpr.values,5,'truncate');
    
    %% define time intervals for analysis
    blockborders=unisens_get_data(currentPatient,'blockborders.csv','all');%get block times
    
    % get finger PPG
    referencePPG.values = unisens_get_data(currentPatient,'PPG.bin','all');%get finger PPG
    referencePPG.samplerate = unisens_get_samplerate(currentPatient,'PPG.bin'); % get PPG sampling rate
    referencePPG.samplestamp = [0:numel(referencePPG.values)]'/unisens_get_samplerate(currentPatient,'PPG.bin');%create time axis in seconds
    referencePPG.values(1:blockborders.samplestamp(1))=0;
    PPG_ac = filtfilt(sos1,g1,referencePPG.values); %filter signal excerpt
    PPG_dc = filtfilt(sos2,g2,referencePPG.values); %filter signal excerpt
    referencePPG.values=PPG_ac-PPG_dc;%create BP filtered signal from which the AC part is extracted
    [beatIndices] = pqe_beatDetection_lazaro( referencePPG.values', 1000, 0 );%find peaks (maximum slopes)
    rrIntervals.samplestamp  = beatIndices;
    rrIntervals.values=diff(beatIndices);
    rrIntervals.values=[rrIntervals.values(1) rrIntervals.values];
    rrIntervals.values=medfilt1(rrIntervals.values,5,'truncate');
    fingerPPG_raw.values = unisens_get_data(currentPatient,'PPG.bin','all');%get finger PPG
    fingerPPG_raw.samplestamp = [0:numel(referencePPG.values)]';%create time axis in seconds
    
    % get brachial blood pressure
    brachialBP.values = unisens_get_data(currentPatient,'BPBrachial.bin','all');%get brachial BP
    brachialBP.samplestamp = [0:numel(brachialBP.values)]'/unisens_get_samplerate(currentPatient,'BPBrachial.bin');%create time axis in seconds
    brachialBP.values(1:blockborders.samplestamp(1))=0;
    
    % get finger blood pressure
    fingerBP.values = unisens_get_data(currentPatient,'BPFinger.bin','all');%get finger BP
    fingerBP.samplestamp = [0:numel(fingerBP.values)]'/unisens_get_samplerate(currentPatient,'BPFinger.bin');%create time axis in seconds
    fingerBP.values(1:blockborders.samplestamp(1))=0;
    
    % find maximum SBP
    indices = find(systolicBP.samplestamp > blockborders.samplestamp(3) & ...
        systolicBP.samplestamp < blockborders.samplestamp(4));%
    [~,maxIndex]=max(systolicBP.values(indices));
    maxIndex=maxIndex+indices(1)-1;
    maximumSBPInterval=[systolicBP.samplestamp(maxIndex)-5000 systolicBP.samplestamp(maxIndex)+5000];
    
    % find maximum TPR
    indices = find(tpr.samplestamp > blockborders.samplestamp(3) & ...
        tpr.samplestamp < blockborders.samplestamp(4));
    [~,maxIndex]=max(tpr.values(indices));
    maxIndex=maxIndex+indices(1)-1;
    maximumTPRInterval=[tpr.samplestamp(maxIndex)-5000 tpr.samplestamp(maxIndex)+5000];
    
    % find maximum PP
    indices = find(pulsePressure.samplestamp > blockborders.samplestamp(3) & ...
        pulsePressure.samplestamp < blockborders.samplestamp(4));
    [~,maxIndex]=max(pulsePressure.values(indices));
    maxIndex=maxIndex+indices(1)-1;
    maximumPulsePressureInterval=[pulsePressure.samplestamp(maxIndex)-5000 pulsePressure.samplestamp(maxIndex)+5000];
    
    % store interval times
    intervalTimes= [...
        blockborders.samplestamp(1)+60000 blockborders.samplestamp(1)+70000;...
        blockborders.samplestamp(1)+120000 blockborders.samplestamp(1)+130000;...
        blockborders.samplestamp(1)+180000 blockborders.samplestamp(1)+190000; ...
        blockborders.samplestamp(3)+10000 blockborders.samplestamp(3)+20000; ...
        maximumSBPInterval;
        maximumTPRInterval;
        maximumPulsePressureInterval
        ]%after CPT
    %define time intervals for analysis
    
    %% iterate over all videos (each subject has a couple of videos)
    for currentInterval=1:numel(epochs)
        
        setToNan=0;
        
        %do checks for too short epochs
        if(currentInterval==4)%epoch afterCPT
            if(intervalTimes(currentInterval,2) > blockborders.samplestamp(4)-5000)%CPT shorter than 25s
                setToNan=1;%set physiologicalMeasuresTable for CPT to NaN
            end
        end
        
        
        if(currentInterval>=5)%data driven epochs (highest SBP, DBP,...)
            if(intervalTimes(currentInterval,1) < blockborders.samplestamp(3)+10000)%if epoch too early shift to 10s after CPT begin
                intervalTimes(currentInterval,:)=[blockborders.samplestamp(3)+10000 blockborders.samplestamp(3)+20000];
            end
            if(intervalTimes(currentInterval,2) > blockborders.samplestamp(4)-5000)%if epoch too late shift to 15s before end of CPT
                intervalTimes(currentInterval,:)=[blockborders.samplestamp(4)-15000 blockborders.samplestamp(4)-5000];
            end
            if(intervalTimes(currentInterval,2) > blockborders.samplestamp(4)-5000 | ...
                    intervalTimes(currentInterval,1) < blockborders.samplestamp(3)+10000)%epoch too short
                setToNan=1;%set physiologicalMeasuresTable for CPT to NaN
            end
        end
        
        if(setToNan==1)
%             physiologicalMeasuresTable.([epochs{currentInterval} '_time'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_SBP'])(actualPatientNumber)={NaN};
%             physiologicalMeasuresTable.([epochs{currentInterval} '_DBP'])(actualPatientNumber)={NaN};
%             physiologicalMeasuresTable.([epochs{currentInterval} '_PP'])(actualPatientNumber)={NaN};
%             physiologicalMeasuresTable.([epochs{currentInterval} '_tpr'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_rr'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_PPIntervals'])(actualPatientNumber)={NaN};
%             physiologicalMeasuresTable.([epochs{currentInterval} '_ensembleAC'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_ensembleArea'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_meanSeg'])(actualPatientNumber)={NaN};
%             physiologicalMeasuresTable.([epochs{currentInterval} '_beatStartIndex'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_beatMaximumIndex'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_beatStopIndex'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_dc'])(actualPatientNumber)=NaN;
%             physiologicalMeasuresTable.([epochs{currentInterval} '_ensemblePI'])(actualPatientNumber)=NaN;
            continue
        end
        
        %physiologicalMeasuresTable.([epochs{currentInterval} '_time'])(actualPatientNumber)=intervalTimes(currentInterval,1);
        
        %get systolic BP
        indices = find(systolicBP.samplestamp > intervalTimes(currentInterval,1) & ...
            systolicBP.samplestamp < intervalTimes(currentInterval,2));
        currentSBP.values = systolicBP.values(indices);
        currentSBP.samplestamp = systolicBP.samplestamp(indices);
        clear indices;
        
        %get diastolic BP
        indices = find(diastolicBP.samplestamp > intervalTimes(currentInterval,1) & ...
            diastolicBP.samplestamp < intervalTimes(currentInterval,2));
        currentDBP.values = diastolicBP.values(indices);
        currentDBP.samplestamp = diastolicBP.samplestamp(indices);
        clear indices;
        
        %get pulse pressure
        indices = find(pulsePressure.samplestamp > intervalTimes(currentInterval,1) & ...
            pulsePressure.samplestamp < intervalTimes(currentInterval,2));
        currentPP.values = pulsePressure.values(indices);
        currentPP.samplestamp = pulsePressure.samplestamp(indices);
        clear indices;
        
        % get tpr
        indices = find(tpr.samplestamp > intervalTimes(currentInterval,1) & ...
            tpr.samplestamp < intervalTimes(currentInterval,2));
        currentTPR.values = tpr.values(indices);
        currentTPR.samplestamp = tpr.samplestamp(indices);
        clear indices;
        
        % get rr (from ECG or from pulse signal) % TODO: needs to adapted
        indices = find(rrIntervals.samplestamp > intervalTimes(currentInterval,1) & ...
            rrIntervals.samplestamp < intervalTimes(currentInterval,2));
        currentRR = median(rrIntervals.values(indices));
        clear indices;
        
        % get pulse indices
        indices = find(rrIntervals.samplestamp > intervalTimes(currentInterval,1) & ...
            rrIntervals.samplestamp < intervalTimes(currentInterval,2));
        currentPPIntervals = rrIntervals.samplestamp(indices)-intervalTimes(currentInterval,1);
        clear indices;
        
        % get signal segments for current epoch
        indices = find(1000*referencePPG.samplestamp > intervalTimes(currentInterval,1) & ...
            1000*referencePPG.samplestamp < intervalTimes(currentInterval,2));
        fingerPPG.values = referencePPG.values(indices);
        fingerPPG.samplerate = referencePPG.samplerate;
        fingerPPG.samplestamp = referencePPG.samplestamp(indices);
        clear indices;
        indices = find(1000*fingerBP.samplestamp > intervalTimes(currentInterval,1) & ...
            1000*fingerBP.samplestamp < intervalTimes(currentInterval,2));
        referenceBP_finger = fingerBP.values(indices);
        clear indices;
        indices = find(1000*brachialBP.samplestamp > intervalTimes(currentInterval,1) & ...
            1000*brachialBP.samplestamp < intervalTimes(currentInterval,2));
        referenceBP_brachial = brachialBP.values(indices);
        clear indices;

        % add PPGI from PulseDecompositionAnalysis directory
        load([pathToPPGI,'\',fileID,'\',epochs{currentInterval}],'ppgBlue','ppgGreen','ppgRed','meanSeg','beatStartIndex','beatStopIndex');
        ppgi.values = [ppgBlue,ppgGreen,ppgRed];
        ppgi.samplerate = 100;% add samplerate (100 Hz)
        ppgi.samplestamp = [0:(numel(ppgi.values(:,2))-1)]'/ppgi.samplerate;% add samplestamps
        if(~isnan(meanSeg))
            ensembleBeat = meanSeg(beatStartIndex:beatStopIndex);
        else
            ensembleBeat = NaN;
        end
        
        % calculate PI from finger PPG
        indices = find(fingerPPG_raw.samplestamp > intervalTimes(currentInterval,1) & ...
            fingerPPG_raw.samplestamp <= intervalTimes(currentInterval,2));
        currentPPG = downsample(fingerPPG_raw.values(indices),10);

        % align PPG beats and BP features
        [beatIndices] = pqe_beatDetection_lazaro( fingerPPG.values', fingerPPG.samplerate, 0 );%find peaks (maximum slopes)
        beatIndices(1) = []; % omit first and last beat to leave enough space
        beatIndices(end) = []; % omit first and last beat to leave enough room
        featureIndices = (currentSBP.samplestamp - intervalTimes(currentInterval,1))';
        numFeatures = numel(featureIndices);
        numBeats = numel(beatIndices);
        % euclidean distance
        if(numFeatures >= numBeats)
            distmat = abs(bsxfun(@minus, featureIndices, beatIndices.'));
            [~, alignmentIndices] = min(distmat,[],2);
            currentSBP.values = currentSBP.values(alignmentIndices);
            currentSBP.samplestamp  = currentSBP.samplestamp(alignmentIndices);
            currentDBP.values = currentDBP.values(alignmentIndices);
            currentDBP.samplestamp  = currentDBP.samplestamp(alignmentIndices);
            currentPP.values = currentPP.values(alignmentIndices);
            currentPP.samplestamp  = currentPP.samplestamp(alignmentIndices);
            currentTPR.values = currentTPR.values(alignmentIndices);
            currentTPR.samplestamp = currentTPR.samplestamp(alignmentIndices);
        else
            distmat = abs(bsxfun(@minus, beatIndices, featureIndices.'));
            [~, alignmentIndices] = min(distmat,[],2);
            beatIndices = beatIndices(alignmentIndices);
        end
        
        % add epochs to physiological measures table
        currentSBP.epochs=repmat(epochs(currentInterval),numel(currentSBP.values),1);
        currentDBP.epochs=repmat(epochs(currentInterval),numel(currentDBP.values),1);
        currentPP.epochs=repmat(epochs(currentInterval),numel(currentPP.values),1);
        currentTPR.epochs=repmat(epochs(currentInterval),numel(currentTPR.values),1);

        % create correct physiological measures table
        if(currentInterval==1)
            physiologicalMeasuresTable.SBP(actualPatientNumber)=currentSBP;
            physiologicalMeasuresTable.DBP(actualPatientNumber)=currentDBP;
            physiologicalMeasuresTable.PP(actualPatientNumber)=currentPP;
            physiologicalMeasuresTable.tpr(actualPatientNumber)=currentTPR;
        else
            physiologicalMeasuresTable.SBP(actualPatientNumber).values=[physiologicalMeasuresTable.SBP(actualPatientNumber).values;currentSBP.values];
            physiologicalMeasuresTable.SBP(actualPatientNumber).samplestamp=[physiologicalMeasuresTable.SBP(actualPatientNumber).samplestamp;currentSBP.samplestamp];
            physiologicalMeasuresTable.SBP(actualPatientNumber).epochs=[physiologicalMeasuresTable.SBP(actualPatientNumber).epochs;currentSBP.epochs];
            physiologicalMeasuresTable.DBP(actualPatientNumber).values=[physiologicalMeasuresTable.DBP(actualPatientNumber).values;currentDBP.values];
            physiologicalMeasuresTable.DBP(actualPatientNumber).samplestamp=[physiologicalMeasuresTable.DBP(actualPatientNumber).samplestamp;currentDBP.samplestamp];
            physiologicalMeasuresTable.DBP(actualPatientNumber).epochs=[physiologicalMeasuresTable.DBP(actualPatientNumber).epochs;currentDBP.epochs];
            physiologicalMeasuresTable.PP(actualPatientNumber).values=[physiologicalMeasuresTable.PP(actualPatientNumber).values;currentPP.values];
            physiologicalMeasuresTable.PP(actualPatientNumber).samplestamp=[physiologicalMeasuresTable.PP(actualPatientNumber).samplestamp;currentPP.samplestamp];
            physiologicalMeasuresTable.PP(actualPatientNumber).epochs=[physiologicalMeasuresTable.PP(actualPatientNumber).epochs;currentPP.epochs];
            physiologicalMeasuresTable.tpr(actualPatientNumber).values=[physiologicalMeasuresTable.tpr(actualPatientNumber).values;currentTPR.values];
            physiologicalMeasuresTable.tpr(actualPatientNumber).samplestamp=[physiologicalMeasuresTable.tpr(actualPatientNumber).samplestamp;currentTPR.samplestamp];
            physiologicalMeasuresTable.tpr(actualPatientNumber).epochs=[physiologicalMeasuresTable.tpr(actualPatientNumber).epochs;currentTPR.epochs];
        end
        
        [errorCode,~,~,...
            meanSeg,beatStartIndex,beatMaximumIndex,beatStopIndex,...
            ensembleAC, ensemblePI, dc, ensembleArea, ~, beatSegments] = ...
            perfusionIndexEnsemble_addedOutput(currentPPG, 100,...
            'LowPassFilter', myFilters,...
            'BeatTimes',ceil(currentPPIntervals'/10),...
            'maximumPPGValue',0.2);

        % TODO: jeweils nur anhängen
%         physiologicalMeasuresTable.([epochs{currentInterval} '_ensembleAC'])(actualPatientNumber)=ensembleAC;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_ensembleArea'])(actualPatientNumber)=ensembleArea;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_meanSeg'])(actualPatientNumber)={meanSeg};
%         physiologicalMeasuresTable.([epochs{currentInterval} '_beatStartIndex'])(actualPatientNumber)=beatStartIndex;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_beatMaximumIndex'])(actualPatientNumber)=beatMaximumIndex;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_beatStopIndex'])(actualPatientNumber)=beatStopIndex;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_dc'])(actualPatientNumber)=dc;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_ensemblePI'])(actualPatientNumber)=ensemblePI;
%         physiologicalMeasuresTable.([epochs{currentInterval} '_beatSegments'])(actualPatientNumber)={beatSegments};


        % cut whole signals into segments and save these in a seperate file
        % like with the other data
        if(exist([resultsFolder fileID '\'],'dir')~=7)
            mkdir([resultsFolder fileID '\']);
        end
        save([resultsFolder fileID '\' epochs{currentInterval} '.mat'],...
            'referenceBP_finger','referenceBP_brachial','fingerPPG', ...
            'beatIndices','featureIndices','alignmentIndices','ppgi','ensembleBeat');
        clear('referenceBP_finger','referenceBP_brachial','fingerPPG', ...
        'beatIndices','featureIndices','alignmentIndices','ppgi','ensembleBeat');
    end 
    clear('intervalTimes');
end
save([resultsFolder 'physiologicalMeasuresTable.mat'],'physiologicalMeasuresTable')
