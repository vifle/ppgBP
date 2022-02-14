%% TODO

% make data equidistant? --> no timestamps available, must assume
% equidistancy
% filtering is not needed

% variables saved per subjects need to get the same names as in CPT data

% perfusionIndexEnsemble aufrufen
% --> filtert + erstellt mean seg
% Funktion umschreiben, sodass einzelne Segmente ausgegeben werden und auch
% die gefilterten Verläufe

% filtering must be adapted to new data maybe due to hardware filtering
% if filtering is done it should be the same as in CPT data set



% ensemble averaging nicht so sinnvoll, weil oft nur ein beat vorhanden
% use same naming conventions as in tables of CPT data
% which variables do i need to rename?
% -->PPG und samplingFrequency, noch was? 
% make sure there is no exclusion due to perfusion index function
% --> nicht einfach perfusion index function nutzen

clear all
clc

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
baseFolder = [networkDrive,'\FleischhauerVincent\sciebo_appendix\Forschung\Konferenzen\Paper_PPG_BP\Data\Datasets\PPG_BP\'];
sourceFolder=[baseFolder,'measurements\'];
resultsFolder = [baseFolder,'realDataSUBSET\'];

%% Parameters
% specify signal parameters
samplingFrequency = 1000; % 1000 Hz sampling frequency
resolution = 4096; %2^12

load([sourceFolder 'dataset.mat']);
load([sourceFolder 'dataTable.mat']);
physiologicalMeasuresTable = dataTable; % rather physiological measures table?
load('epochs.mat');

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
physiologicalMeasuresTable.subject_ID = regexprep(cellstr(num2str(physiologicalMeasuresTable.subject_ID)), ' ', '0');
patients = physiologicalMeasuresTable.subject_ID;
SBPcell = cell(numel(patients),1);
DBPcell = cell(numel(patients),1);
PPcell = cell(numel(patients),1);
for actualPatientNumber=1:size(patients,1) % loop over whole dataset --> TODO: use parfor for parallelizing
    disp(['patient number: ',num2str(actualPatientNumber)]) % show current patient number in console
    currentPatient = patients{actualPatientNumber};
    numBeats = 0;
    for currentEpoch=1:numel(epochs) %loop over all epochs
        fingerPPG.values = dataset{actualPatientNumber,currentEpoch};
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
        numBeats = numBeats + numel(beatIndices);
        
        %% save & clear data of this epoch
        if(exist([resultsFolder currentPatient '\'],'dir')~=7)
            mkdir([resultsFolder currentPatient '\']);
        end
        save([resultsFolder currentPatient '\' epochs{currentEpoch} '.mat'],...
            'beatIndices' , 'fingerPPG');
        clear('beatIndices' , 'fingerPPG');
    end
    % create BP vectors
    SBP = struct;
    SBP.values = zeros(numBeats,1);
    SBP.values(:) = physiologicalMeasuresTable.SystolicBloodPressure_mmHg_(actualPatientNumber);
    SBPcell{actualPatientNumber} = SBP; %--> rather a table?
    DBP = struct;
    DBP.values = zeros(numBeats,1);
    DBP.values(:) = physiologicalMeasuresTable.DiastolicBloodPressure_mmHg_(actualPatientNumber);
    DBPcell{actualPatientNumber} = DBP;
    PP = struct;
    PP.values = SBP.values - DBP.values;
    PPcell{actualPatientNumber} = PP;
end
SBPtab = cell2table(SBPcell,'VariableNames',{'SBP'});
physiologicalMeasuresTable = [physiologicalMeasuresTable,SBPtab];
physiologicalMeasuresTable = movevars(physiologicalMeasuresTable,'SBP','After','SystolicBloodPressure_mmHg_');
physiologicalMeasuresTable.SystolicBloodPressure_mmHg_ = [];
DBPtab = cell2table(DBPcell,'VariableNames',{'DBP'});
physiologicalMeasuresTable = [physiologicalMeasuresTable,DBPtab];
physiologicalMeasuresTable = movevars(physiologicalMeasuresTable,'DBP','After','DiastolicBloodPressure_mmHg_');
physiologicalMeasuresTable.DiastolicBloodPressure_mmHg_ = [];
PPtab = cell2table(PPcell,'VariableNames',{'PP'});
physiologicalMeasuresTable = [physiologicalMeasuresTable,PPtab];
physiologicalMeasuresTable = movevars(physiologicalMeasuresTable,'PP','After','DBP');

% rename fields of table to match CPT data
physiologicalMeasuresTable.Properties.VariableNames{'subject_ID'} = 'SubjectID';

% rename entries of table to match CPT data
physiologicalMeasuresTable.Sex_M_F_(strcmp(physiologicalMeasuresTable.Sex_M_F_,'Male')) = {'m'};
physiologicalMeasuresTable.Sex_M_F_(strcmp(physiologicalMeasuresTable.Sex_M_F_,'Female')) = {'w'};

% save physiological measures table
save([resultsFolder 'physiologicalMeasuresTable.mat'],'physiologicalMeasuresTable');