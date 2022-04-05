clear all
clc


% ecg for detection?
% TODO: ecg is not used in any way (neither in cpt)
% TODO: werden Zeilen wegen NaN in demographischen Feldern gelöscht?


%% setup
% paths
addpath('..\..\NeededFunctions');

if(strcmp(getenv('username'),'vince'))
    networkDrive = 'Y:';
elseif(strcmp(getenv('username'),'Vincent Fleischhauer'))
    networkDrive = 'X:';
else
    errordlg('username not known')
end
baseFolder = [networkDrive,'\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\Queensland\'];
sourceFolder=[baseFolder,'measurements\'];
resultsFolder = [baseFolder,'realData\FULL\'];

%% Parameters
% specify signal parameters
samplingFrequency = 100; % 100 Hz sampling frequency
varsOfInterest = {'RelativeTimeMilliseconds','NBP_Sys_','NBP_Dia_','NBP_Mean_','ECG','Pleth'};

% get patients list
dinfo = dir(sourceFolder);
dinfo(ismember( {dinfo.name}, {'.', '..'})) = [];  %remove . and ..;
patients = {dinfo.name}';

% create table
physiologicalMeasuresTable = table;%create a table where all results are stored
physiologicalMeasuresTable.SubjectID=patients;%create the column for the actual patient ID
physiologicalMeasuresTable.Sex_M_F_=NaN(numel(patients),1);
physiologicalMeasuresTable.Age_year_=NaN(numel(patients),1);
physiologicalMeasuresTable.Height_cm_=NaN(numel(patients),1);
physiologicalMeasuresTable.Weight_kg_=NaN(numel(patients),1);

% create PPG filter (this filter will be used to smooth the reference PPG)
[b,a] = butter(5, 10/(samplingFrequency/2), 'low');%create bandpass to filter the pixel traces
cutOffLPF=12;%default low cutoff frequency for AC signal
cutOffLPF2=0.4;%default low cutoff frequency for DC
filterOrderLPF=5;%default filter order for the higher LP filter
filterOrderLPF2=5;%default filter order for the lower LP filter
[z1,p1,k1] = butter(filterOrderLPF,cutOffLPF/(samplingFrequency/2),'low');
[sos1,g1] = zp2sos(z1,p1,k1);

%low pass filter for DC part
[z2,p2,k2] = butter(filterOrderLPF2,cutOffLPF2/(samplingFrequency/2),'low');
[sos2,g2] = zp2sos(z2,p2,k2);

%% Conversion of data
SBPcell = cell(numel(patients),1);
DBPcell = cell(numel(patients),1);
PPcell = cell(numel(patients),1);
for actualPatientNumber=1:size(patients,1) % loop over whole dataset --> TODO: use parfor for parallelizing
    disp(['patient number: ',num2str(actualPatientNumber)]) % show current patient number in console
    currentPatient = patients{actualPatientNumber};

    % get number of epochs here
    epochDir = [sourceFolder patients{actualPatientNumber} '\fulldata\'];
    epochs = dir(epochDir);
    epochs(ismember( {epochs.name}, {'.', '..'})) = [];  %remove . and ..;
    epochs = {epochs.name}';

    for currentEpoch=1:numel(epochs) %loop over all epochs
        % load csv
        dataTable = readtable([epochDir epochs{currentEpoch}],'NumHeaderLines',0,'Delimiter',',');
        % extract time (relative in milliseconds), gender - NaN, ppg, ecg, sbp, dbp 
        availableVars = dataTable.Properties.VariableNames;
        removableVars = setdiff(availableVars,varsOfInterest);
        dataTable = removevars(dataTable,removableVars);
        % demographic features available? --> generally no
        % put together the ecerpts from all epochs
        if(currentEpoch>1)
            dataTableNew = [dataTableNew;dataTable];
        else
            dataTableNew = dataTable;
        end
        
    end
    clear dataTable
    
    % get ecg, ppg and beat indices
    ecg.values = dataTableNew.ECG;
    if(isnan(ecg.values(1)))
        ecg.values(1) = 0; % avoid problem with nan beginnings
    end
    nanIdx = find(~isfinite(ecg.values));
    for numNaNIdx = 1:numel(nanIdx)
        ecg.values(nanIdx(numNaNIdx)) = ecg.values(find(~isnan(ecg.values(1:nanIdx(1))),1,'last')); % correct ecg
    end
    ecg.samplerate = samplingFrequency;
    fingerPPG.values = dataTableNew.Pleth;
    if(isnan(fingerPPG.values(1)))
        fingerPPG.values(1) = 0; % avoid problem with nan beginnings
    end
    nanIdx = find(~isfinite(fingerPPG.values));
    for numNaNIdx = 1:numel(nanIdx)
        fingerPPG.values(nanIdx(numNaNIdx)) = fingerPPG.values(find(~isnan(fingerPPG.values(1:nanIdx(1))),1,'last')); % correct ppg
    end
    fingerPPG.samplerate = samplingFrequency;
    PPG_ac = filtfilt(sos1,g1,fingerPPG.values); %filter signal excerpt
    PPG_dc = filtfilt(sos2,g2,fingerPPG.values); %filter signal excerpt
    fingerPPG.values=PPG_ac-PPG_dc;%create BP filtered signal from which the AC part is extracted
    [beatIndices] = pqe_beatDetection_lazaro(fingerPPG.values',fingerPPG.samplerate,0);%find peaks (maximum slopes)
    segmentLength = diff(beatIndices); % calculate beat to beat differences
    segmentLength = ceil(median(segmentLength)); % get median segment length
    while((beatIndices(end)+segmentLength)>numel(fingerPPG.values))
        beatIndices(end) = []; % exclude incomplete beats
    end
    if(size(beatIndices,2)>size(beatIndices,1))
        beatIndices = beatIndices'; % turn beat indices into nx1 array
    end
    numBeats = numel(beatIndices);

    % create BP vectors
    SBP = struct;
    SBP.values = zeros(numBeats,1);
    SBP.values(:) = dataTableNew.NBP_Sys_(beatIndices);
    SBPcell{actualPatientNumber} = SBP; 
    DBP = struct;
    DBP.values = zeros(numBeats,1);
    DBP.values(:) = dataTableNew.NBP_Dia_(beatIndices);
    DBPcell{actualPatientNumber} = DBP;
    PP = struct;
    PP.values = SBP.values - DBP.values;
    PPcell{actualPatientNumber} = PP;

    %% save & clear data of this patient
    save([resultsFolder currentPatient '.mat'],...
        'beatIndices' , 'fingerPPG', 'ecg');
    clear('beatIndices' , 'fingerPPG', 'ecg', 'dataTableNew');
end
SBPtab = cell2table(SBPcell,'VariableNames',{'SBP'});
physiologicalMeasuresTable = [physiologicalMeasuresTable,SBPtab];
DBPtab = cell2table(DBPcell,'VariableNames',{'DBP'});
physiologicalMeasuresTable = [physiologicalMeasuresTable,DBPtab];
PPtab = cell2table(PPcell,'VariableNames',{'PP'});
physiologicalMeasuresTable = [physiologicalMeasuresTable,PPtab];

% save physiological measures table
save([resultsFolder 'physiologicalMeasuresTable.mat'],'physiologicalMeasuresTable');