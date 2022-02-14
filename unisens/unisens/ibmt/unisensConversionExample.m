%% Function to show how data can be converted to Unisens format
%
% basic proceeding: the function unisens_converter(pathname, datasetname, data)
% the variable contains all data to be written - separated into signal
% (data.signal), values (data.values) and annotations (data.annotations)
% see function unisens_converter.m for details concerning parameters
%
% NOTE: Unisens must be installed or included to the path temporally, e.g.
% by
% javaaddpath 'unisens\lib\org.unisens.jar'
% javaaddpath 'unisens\lib\org.unisens.ri.jar'
% addpath('unisens')
%
% Author: Sebastian Zaunseder
% Date: 12.07.2014


%% examplary read out of a data file --> here a loop can be invoked, as example a single file is loaded
patientName='Proband01_1';
load(patientName)


%% write data into a structure of the desired format (-> data.signal, data.annotation ,...)
% this block is dependent to the structure of loaded data

writeData.comment = datestr(blocktimes, 31);%time given as YYYY MM DD, HH MM SS


writeData.signals.flashsignal.content = 'Flash';
writeData.signals.flashsignal.physicalUnit = 'V';
writeData.signals.flashsignal.data = data(1, datastart(1):dataend(1));

writeData.signals.PPGupperArm.content = 'PPG upper Arm';
writeData.signals.PPGupperArm.physicalUnit = 'mV';
writeData.signals.PPGupperArm.data = data(1, datastart(2):dataend(2));

writeData.signals.PPGarmCrook.content = 'PPG crook of the arm';
writeData.signals.PPGarmCrook.physicalUnit = 'mV';
writeData.signals.PPGarmCrook.data = data(1, datastart(3):dataend(3));

writeData.signals.PPGfinger.content = 'PPG finger';
writeData.signals.PPGfinger.physicalUnit = 'mV';
writeData.signals.PPGfinger.data = data(1, datastart(4):dataend(4));

writeData.signals.bloodPressure.content = 'Blood Pressure';
writeData.signals.bloodPressure.physicalUnit = 'mmHg';
writeData.signals.bloodPressure.data = data(1,datastart(5):dataend(5));

writeData.signals.ecg.content = 'ECG';
writeData.signals.ecg.physicalUnit = 'mV';
writeData.signals.ecg.data = data(1,datastart(6):dataend(6));

% write systlic blood pressure as values (time + BP)
systPressure=data(1,datastart(7):dataend(7));
systPressure(isnan(systPressure))=0;
diffSystolicPressure=diff(systPressure);
indices=find(diffSystolicPressure~=0)+1;
indices(end)=[];
systole=systPressure(indices);
writeData.values.systolicBP.content = 'Systolic blood pressure';
writeData.values.systolicBP.physicalUnit = 'mmHg';
writeData.values.systolicBP.data=[indices' systole'];

% write detections as annotations
qrsAnnotSignal=data(1,datastart(9):dataend(9));
qrsIndices=find(qrsAnnotSignal~=0);
writeData.annotations.qrsComplex.content = 'QRS times';
writeData.annotations.qrsComplex.physicalUnit = '';
writeData.annotations.qrsComplex.data=qrsIndices;


%% write data to unisens
folderToWrite=cd; %folder to write data
unisens_converter([folderToWrite '\'] , patientName, writeData);

