%% this script extracts physiological variables (from PPG recordings)

% unisens_utility_get_customAttributes(path)
% --> metadaten for Probanden mit abspeichern
% unisens_utility_get_customAttributes('C:\Users\vince\sciebo\Forschung\Konferenzen\Paper_PPG_BP\CPTdata\unisens\unisens')

% was passiert eig, wenn ich epochen wie highest sbp verwende und dadurch
% schläge in mehreren Epochen vorkommen? Dann habe ich ja keine
% unabhängigkeit mehr...
% sinnvoll, highest sbp kurz zu lassen und nur die baselines auf zwei min
% zu erhöhen?
% vllt nur after cpt und highest sbp einbauen, nicht die anderen epochen?
% so habe ich immer noch 5 levels
% vllt eine Art Start- und end-Zeit festlegen, sodass ich von allen
% gleichlange signale habe und vllt probleme am anfang und ende des signals
% vermeide?

% TODO: sebastian warum ist maximumPPGValue = 0.2?

% BP aus schlägen selbst extrahieren oder die von finapres nehmen
% schläge aussortieren, während kalibriert wird
%[beatIndicesBP] = pqe_beatDetection_lazaro( fingerBP.values', fingerBP.samplerate, 0 );%find peaks in BP form

% TODO: Sebastian fragen, warum die medianfilter drin sind + sinn bei
% ECG oder eher doch nicht? Vllt nur einsetzen, wenn rr viel größer
% oder kleiner alas der median des gesamten Verlaufs ist?

% TODO: PI calculation and downsampling: make it dependent on sample rate

clear all
close all

%% setup
% settings
alignBP = false;
biasBeats = 0;
checkBPalignment = false;
useECG = true;

% add unisens (needed to read unisens data)
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
resultsFolder = [baseFolder,'realDataFULL\'];
patients=textread([unisensFolder 'allSubjects.dat'],'%s');%loads list with patient
load([unisensFolder 'epochs.mat']) %loads a variable where names of epochs are stored

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
    % get SBP
    systolicBP = unisens_get_data(currentPatient,'systolicBP_BS.csv','all');%get responses
    systolicBP.samplestamp = systolicBP.samplestamp*1000/unisens_get_samplerate(currentPatient,'systolicBP_BS.csv');
    
    % get DBP
    diastolicBP = unisens_get_data(currentPatient,'diastolicBP_BS.csv','all');%get responses
    diastolicBP.samplestamp = diastolicBP.samplestamp*1000/unisens_get_samplerate(currentPatient,'diastolicBP_BS.csv');
    
    % get PP
    pulsePressure.samplestamp = systolicBP.samplestamp;
    pulsePressure.values = systolicBP.values - diastolicBP.values;
    
    % get TPR
    tpr = unisens_get_data(currentPatient,'TPR_BS.csv','all');%get responses
    tpr.samplestamp = tpr.samplestamp*1000/unisens_get_samplerate(currentPatient,'TPR_BS.csv');
    
    % get ECG
    ecg.samplerate = unisens_get_samplerate(currentPatient,'ECG.bin'); % get PPG sampling rate
    ecg.values = unisens_get_data(currentPatient,'ECG.bin','all');%get finger PPG
    ecg.samplestamp = [0:numel(ecg.values)-1]'*1000/ecg.samplerate;%create time axis in milli seconds
    
    % get finger PPG    
    fingerPPG.samplerate = unisens_get_samplerate(currentPatient,'PPG.bin'); % get PPG sampling rate
    fingerPPG.values = unisens_get_data(currentPatient,'PPG.bin','all');%get finger PPG
    fingerPPG.samplestamp = [0:numel(fingerPPG.values)-1]'*1000/fingerPPG.samplerate;%create time axis in milli seconds
    
    % get brachial blood pressure
    brachialBP = unisens_get_data(currentPatient,'BPBrachial_BS.bin','all');%get brachial BP
    brachialBP.samplerate = unisens_get_samplerate(currentPatient,'BPBrachial_BS.bin'); % get braichial BP samplerate
    brachialBP.samplestamp = brachialBP.samplestamp*1000/brachialBP.samplerate;%create time axis in milli seconds
    
    % get finger blood pressure
    fingerBP.samplerate = unisens_get_samplerate(currentPatient,'BPFinger.bin'); % get finger BP samplerate
    fingerBP.values = unisens_get_data(currentPatient,'BPFinger.bin','all');%get finger BP
    fingerBP.samplestamp = [0:numel(fingerBP.values)-1]'*1000/fingerBP.samplerate;%create time axis in milli seconds
    
    %% align BP waveforms and features
    % cut waveform until third index of BP features
    if(alignBP)
        systolicBP.samplestamp = systolicBP.samplestamp(biasBeats+1:end);
        systolicBP.values = systolicBP.values(1:end-biasBeats);
        diastolicBP.samplestamp = diastolicBP.samplestamp(biasBeats+1:end);
        diastolicBP.values = diastolicBP.values(1:end-biasBeats);
        pulsePressure.samplestamp = pulsePressure.samplestamp(biasBeats+1:end);
        pulsePressure.values = pulsePressure.values(1:end-biasBeats);
        tpr.samplestamp = tpr.samplestamp(biasBeats+1:end);
        tpr.values = tpr.values(1:end-biasBeats);
    end
    
    %% cut data to analysis interval
    % define interval
    blockborders=unisens_get_data(currentPatient,'blockborders.csv','all');%get block times
    intervalStart = blockborders.samplestamp(1)+60000;
    intervalEnd = blockborders.samplestamp(6);
    
    % cut SBP
    indices = find(systolicBP.samplestamp > intervalStart & ...
        systolicBP.samplestamp < intervalEnd);
    systolicBP.values = systolicBP.values(indices);
    systolicBP.samplestamp = systolicBP.samplestamp(indices);
    clear indices;
    
    % cut DBP
    indices = find(diastolicBP.samplestamp > intervalStart & ...
        diastolicBP.samplestamp < intervalEnd);
    diastolicBP.values = diastolicBP.values(indices);
    diastolicBP.samplestamp = diastolicBP.samplestamp(indices);
    clear indices;
    
    % cut PP
    indices = find(pulsePressure.samplestamp > intervalStart & ...
        pulsePressure.samplestamp < intervalEnd);
    pulsePressure.values = pulsePressure.values(indices);
    pulsePressure.samplestamp = pulsePressure.samplestamp(indices);
    clear indices;
    
    % cut TPR
    indices = find(tpr.samplestamp > intervalStart & ...
        tpr.samplestamp < intervalEnd);
    tpr.values = tpr.values(indices);
    tpr.samplestamp = tpr.samplestamp(indices);
    clear indices;
    
    % cut ECG
    indices = find(ecg.samplestamp > intervalStart & ...
        ecg.samplestamp < intervalEnd);
    ecg.values = ecg.values(indices);
    ecg.samplestamp = ecg.samplestamp(indices);
    clear indices;
    
    % cut finger PPG
    indices = find(fingerPPG.samplestamp > intervalStart & ...
        fingerPPG.samplestamp < intervalEnd);
    fingerPPG.values = fingerPPG.values(indices);
    fingerPPG.samplestamp = fingerPPG.samplestamp(indices);
    clear indices;
    
    % cut finger BP
    indices = find(fingerBP.samplestamp > intervalStart & ...
        fingerBP.samplestamp < intervalEnd);
    fingerBP.values = fingerBP.values(indices);
    fingerBP.samplestamp = fingerBP.samplestamp(indices);
    clear indices;
    
    % cut brachial BP
    indices = find(brachialBP.samplestamp > intervalStart & ...
        brachialBP.samplestamp < intervalEnd);
    brachialBP.values = brachialBP.values(indices);
    brachialBP.samplestamp = brachialBP.samplestamp(indices);
    clear indices;
    
    %% process data
    % optional alignment check
    % welche Schläge sollte ich nun nehmen?
    % naja: ich kann nur beats aufnehmen, zu denen ich ein PPG finde, denn
    % die features will ich. Davon kann ich dann alle abziehen, bei denen
    % gerade ABP kalibriert wird. kann ich aber optional machen, weil ich
    % den SBP Verlauf usw auch während der kalibrierung habe
    if(checkBPalignment)
        plot(diastolicBP.samplestamp,diastolicBP.values)
        hold on
        plot(systolicBP.samplestamp,systolicBP.values)
        plot(brachialBP.samplestamp,brachialBP.values)
        plot(fingerPPG.samplestamp,fingerPPG.values*1000)
    end
    
    % align PPG beats and BP features
    % here a constraint should be made: only take beatindices between
    % interval start and end
    % BUT: what happens if the number of beats detected in the PPG is not
    % consistent with those of PP for example?
    PPG_ac = filtfilt(sos1,g1,fingerPPG.values); %filter signal excerpt
    PPG_dc = filtfilt(sos2,g2,fingerPPG.values); %filter signal excerpt
    fingerPPG.values=PPG_ac-PPG_dc;%create BP filtered signal from which the AC part is extracted
    [beatIndices] = pqe_beatDetection_lazaro( fingerPPG.values', fingerPPG.samplerate, 0 );%find peaks (maximum slopes)
    beatIndices(1) = []; % omit first and last beat to leave enough space
    beatIndices(end) = []; % omit first and last beat to leave enough room
    featureIndices = (systolicBP.samplestamp - intervalStart)';
    numFeatures = numel(featureIndices);
    numBeats = numel(beatIndices);
    % euclidean distance
    % https://www.mathworks.com/matlabcentral/answers/225053-how-to-find-2-closest-numbers-in-a-stream-of-arrays-of-the-same-size
    if(numFeatures >= numBeats)
        distmat = abs(bsxfun(@minus, featureIndices, beatIndices.'));
        [~, alignmentIndices] = min(distmat,[],2);
        systolicBP.values = systolicBP.values(alignmentIndices);
        systolicBP.samplestamp = systolicBP.samplestamp(alignmentIndices);
        diastolicBP.values = diastolicBP.values(alignmentIndices);
        diastolicBP.samplestamp = diastolicBP.samplestamp(alignmentIndices);
        pulsePressure.values = pulsePressure.values(alignmentIndices);
        pulsePressure.samplestamp = pulsePressure.samplestamp(alignmentIndices);
        tpr.values = tpr.values(alignmentIndices);
        tpr.samplestamp = tpr.samplestamp(alignmentIndices);        
    else
        distmat = abs(bsxfun(@minus, beatIndices, featureIndices.'));
        [~, alignmentIndices] = min(distmat,[],2);
        beatIndices = beatIndices(alignmentIndices);
    end
    physiologicalMeasuresTable.SBP(actualPatientNumber)=systolicBP;
    physiologicalMeasuresTable.DBP(actualPatientNumber)=diastolicBP;
    physiologicalMeasuresTable.PP(actualPatientNumber)=pulsePressure;
    physiologicalMeasuresTable.tpr(actualPatientNumber)=tpr;

    % calculate pulse and rr intervals
    ppIntervals.samplestamp = beatIndices;
    ppIntervals.values=diff(beatIndices);
    ppIntervals.values=[ppIntervals.values(1) ppIntervals.values];
    ppIntervals.values=medfilt1(ppIntervals.values,5,'truncate');
    physiologicalMeasuresTable.ppIntervals(actualPatientNumber)=ppIntervals;
    % makes sense because it can happen that PPG beats are not detected, thus creating unnaturrally long RR intervals
    % BUT: in every case it rather distorts the results
    if(useECG)
        % TODO: need to align values here again to beat indices
        [~,rrIntervals.samplestamp,~] = pan_tompkin(ecg.values,ecg.samplerate,0);
        rrIntervals.values=diff(rrIntervals.samplestamp);
        rrIntervals.values=[rrIntervals.values(1) rrIntervals.values];
        rrIntervals.values=medfilt1(rrIntervals.values,5,'truncate'); 
        physiologicalMeasuresTable.rrIntervals(actualPatientNumber)=rrIntervals;
        % makes sense because it can happen that PPG beats are not detected, thus creating unnaturrally long RR intervals
        % BUT: in every case it rather distorts the results
    else
        rrIntervals = ppIntervals;
        physiologicalMeasuresTable.rrIntervals(actualPatientNumber)=rrIntervals;
    end    
    
    %% calculate PI and put values in table
    % create proper input for PI calculation
    fingerPPG_raw.values = unisens_get_data(currentPatient,'PPG.bin','all');%get raw finger PPG
    fingerPPG_raw.samplestamp = [0:numel(fingerPPG.values)-1]'/fingerPPG.samplerate;%create time axis in seconds
    indices = find(fingerPPG.samplerate*fingerPPG_raw.samplestamp > intervalStart & ...
        fingerPPG.samplerate*fingerPPG_raw.samplestamp <= intervalEnd);
    currentPPG = downsample(fingerPPG_raw.values(indices),10);
    currentIndices = ceil(beatIndices'/10);
    clear indices
    
    [errorCode,~,~,...
        meanSeg,beatStartIndex,beatMaximumIndex,beatStopIndex,...
        ensembleAC, ensemblePI, dc, ensembleArea, ~, beatSegments] = ...
        perfusionIndexEnsemble_addedOutput(currentPPG, 100,...
        'LowPassFilter', myFilters,...
        'BeatTimes', currentIndices,...
        'maximumPPGValue', 0.2);
    physiologicalMeasuresTable.ensembleAC(actualPatientNumber)=ensembleAC;
    physiologicalMeasuresTable.ensembleArea(actualPatientNumber)=ensembleArea;
    physiologicalMeasuresTable.meanSeg(actualPatientNumber)={meanSeg};
    physiologicalMeasuresTable.beatStartIndex(actualPatientNumber)=beatStartIndex;
    physiologicalMeasuresTable.beatMaximumIndex(actualPatientNumber)=beatMaximumIndex;
    physiologicalMeasuresTable.beatStopIndex(actualPatientNumber)=beatStopIndex;
    physiologicalMeasuresTable.dc(actualPatientNumber)=dc;
    physiologicalMeasuresTable.ensemblePI(actualPatientNumber)=ensemblePI;
    physiologicalMeasuresTable.beatSegments(actualPatientNumber)={beatSegments};
    
    %% do savings
    if(exist(resultsFolder,'dir')~=7)
        mkdir(resultsFolder);
    end
    save([resultsFolder fileID '.mat'],...
        'ecg','fingerPPG','fingerBP','brachialBP', ...
        'beatIndices','featureIndices','alignmentIndices');
    clear('ecg','fingerPPG','fingerBP','brachialBP', ...
        'beatIndices','featureIndices','alignmentIndices');
end
save([resultsFolder 'physiologicalMeasuresTable.mat'],'physiologicalMeasuresTable')
