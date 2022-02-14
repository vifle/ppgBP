%% Function to calculate Perfusion index from a PPG segment after calculating a beat template
% (note that the perfusion index DC is calculated from the non-iverted
% signal! --> add evidence later)
%
%   Input:
%       PPG - PPG signal (already inverted to resemble the "normal" PPG); not
%       necessarily filtered (size Nx1))
%       samplingFrequency - sampling frequency of the PPG signal
%
%   Varargs (name value pairs)
%     'BeatTimes' + vector - beat times in samples (samplestamps given) (size Nx1)
%     'LowPassFilter' + 3x2 matrix with [sos1 g1; sos2 g2; sos3 g3]
%     'PPG_dc' + vector of size PPG - DC part of PPG; the passed PPG is
%     then automatically interpreted as AC part (size Nx1)
%     'maximumPPGValue' + scalar - the maximum value the PPG can take (e.g. 2^12 for some camera recordings); only required if the DC component is not passed
%     'mimimumNumberOfEnsembledBeats' + scalar - the number of beats required to form an ensemble beat (default is 3; minimum is 1 which makes sense if a single beat is to be processed)
%     'requiredInterbeatCorrelation' + scalar - the correlation which is required for a beat to the other beats in order to enter the ensemble; default is 0.3; -inf will not sort out anything
%     'segmentLength' + scalar - length of considered segment in number of samples (beat-to-beat interval is assumed); if not passed it is determined from the beat detections in the window
%
%
%   Output
%       errorCode - indicates the functioning
%               = 0 - everything fine
%               = 1 - beat indices strange (too few, too much)
%               = 2 - template consist of too few beats
%               = 3 - template was created but no minima found
%               = 4 - no PI calculation possible
%               = 5 - segment length could not be determinant (not enough beats)
%       meanBeatTemplate - ensemble beat
%       beatIndices - timestamps of all found beats (if input the out is the same)
%       beatIndicesEnsembleBeat - indices of found beats which were used in the ensemble
%       beatStartIndex - starting minimum of PPG beat
%       beatMaximumIndex - maximum inex of template
%       beatStopIndex - ending minimum of PPG beat
%       acPart - AC calculated from the ensemble beat
%       perfusionIndex - PI from the ensemble beat
%       dcPart - DC value
%       ppgArea - area of the ensemble beat

% (C) Sebastian Zaunseder, Version 1.0, 20.10.2017
% 02.05.2018, modifications, Sebastian Zaunseder
% 27.06.2019, comments, Sebastian Zaunseder
% 10.07.2019, new ensemble calculation
% 07.08.2019, added third filter to implement AC indepenedent DC filtering
%
%
% Todos
% - integrate alignment to make sure that passed beat indices are on the slope
% - integrate Time delay estimation
% - integrate Warping (2DSW)
% - investigate DC inversion or not - find literature	

function [errorCode, beatIndices,beatIndicesEnsembleBeat,...
    meanBeatTemplate,beatStartIndex,beatMaximumIndex,beatStopIndex,...
    acPart, perfusionIndex, dcPart, ppgArea, PPG, beatSegments] = ...
    perfusionIndexEnsemble_addedOutput(PPG, samplingFrequency, varargin)


okargs =   {...
    'BeatTimes', ...
    'LowPassFilter', ...
    'PPG_dc',... 
    'maximumPPGValue',...
    'mimimumNumberOfEnsembledBeats',... 
    'requiredInterbeatCorrelation',...
    'segmentLength',...
    };%allowed argument specifiers

%% prepare otput variables
errorCode = 0;
beatIndices=NaN;%indices of beat occurences
beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
meanBeatTemplate=NaN;%template segment
beatStartIndex=NaN;%start index of delineated beat
beatMaximumIndex=NaN;%maximum of delineated beat
beatStopIndex=NaN;%end index of delineated beat
acPart=NaN;%AC from ensemble beat
perfusionIndex=NaN;%PI from enememble beat
dcPart=NaN;%DC from ensemble beat
ppgArea=NaN;%area of ensemble beats
beatSegments = NaN;

%% overtake input values
PPGinput=PPG; %save original PPG to store it eventually
PPG_dc=[];%PPG DC part

%% setup internal variables
minimumExpectedHR=30;%minimum expected HR (used to identify non valid number of beat indices)
maximumExpectedHR=180;%maximum expected HR (used to identify non valid number of beat indices)
mimimumNumberOfEnsembledBeats=1;%minimum number of beats which are required to establish a template --> for single beats = 1
maximumValuePPGRange=10;%maximum value the PPG can take (default value; a voltage is assumed, no ADU)
requiredInterbeatCorrelation=0.3; %correlation which is required for a beat to other beats to be used
segmentLength = [];%length of considered intervals (derive from pulse-to-pulse intervals)
sos1=[];%LP filter upper cutoff for AC part
g1=[];%LP filter upper cutoff for AC part
sos2=[];%LP filter lower cutoff for AC part
g2=[];%LP filter lower cutoff for AC part
sos3=[];%LP filter for DC part
g3=[];%LP filter for DC part
cutOff_AC_high=8;%default upper cutoff frequency for AC signal
cutOff_AC_low=0.4;%default lower cutoff frequency for AC signal
cutOff_DC=0.15;%default low cutoff frequency for DC

filterOrder_AC_high=5;%default filter order for upper cutoff frequency for AC signal
filterOrder_AC_low=5;%default filter order for lower cutoff frequency for AC signal
filterOrder_DC = 5;%default filter order for low cutoff frequency for DC signal

%% evaluate optional input arguments (name value arguments)
if(nargin<2)%leave while loop if there are no more new variable arguments
    errordlg('Too few arguments');
    return;
end
i=1;
while(1)
    
    if(mod(size(varargin,2),2)~=0) %check if number of variable arguments is even
        errordlg('Uneven number of arguments not supported');
        return;
    end
    
    if(i>size(varargin,2))%leave while loop if there are no more new variable arguments
        break;
    end
    
    if(ischar(varargin{i}))%evaluate key word of next argument
        if(ismember(varargin{i},okargs))
            actualArgument=varargin{i};
        else
            errordlg(['Specified Option ''' varargin{i} ''' is not a valid option']);
            return;
        end
        
    else
        errordlg(['Specified Option ''' varargin{i} ''' is not a valid option']);
        return;
    end
    i=i+1;
    
    if(isempty(varargin{i}))
        continue
    end
    
    switch actualArgument %set values for the actual arguments
        case 'BeatTimes'%sampling frequency

            if(~isnumeric(varargin{i}))
                errordlg('Beat times need to be numeric (in samples)');
                return;
            end
            beatIndices=varargin{i};
            
        case 'LowPassFilter'%sampling frequency
            if(size(varargin{i},1)~=3 | size(varargin{i},2)~=2)
                errordlg('Wrong size of passed filters');
                return;
            end
            sos1=varargin{i}{1,1};
            g1=varargin{i}{1,2};
            sos2=varargin{i}{2,1};
            g2=varargin{i}{2,2};
            sos3=varargin{i}{3,1};
            g3=varargin{i}{3,2};
            
        case 'PPG_dc'%
            if(~isnumeric(varargin{i}))
                errordlg('PPG_dc needs to be numeric');
                return;
            end
            PPG_dc=varargin{i}(:);
            
        case 'maximumPPGValue'%
            if(~isnumeric(varargin{i}))
                errordlg('maximumPPGValue needs to be numeric');
                return;
            end
            maximumValuePPGRange=varargin{i}(:);
            
        case 'mimimumNumberOfEnsembledBeats'
            if(~isnumeric(varargin{i}))
                errordlg('mimimumNumberOfEnsembledBeats needs to be numeric');
                return;
            end
            if(varargin{i}(:)<1)
                mimimumNumberOfEnsembledBeats=1;
            else
                mimimumNumberOfEnsembledBeats=varargin{i}(:);
            end
            
        case 'requiredInterbeatCorrelation'
            if(~isnumeric(varargin{i}))
                errordlg('requiredInterbeatCorrelation needs to be numeric');
                return;
            end
            requiredInterbeatCorrelation=varargin{i}(:);
            
        case 'segmentLength'
            if(~isnumeric(varargin{i}))
                errordlg('segmentLength needs to be numeric');
                return;
            end
            if(varargin{i}(:)<1)
                errordlg('segmentLength needs to greater than 0');
                return;
            else
                segmentLength=varargin{i}(:);
            end
    end
    i=i+1;
end


%% create AC and DC PPG if not passed alone (if required create filters to that end) --> filtering stage is used in other functions
if(isempty(PPG_dc))%if not passed create AC and DC parts
    
    if(isempty(sos1) | isempty(sos2) | isempty(sos3) | isempty(g1) | isempty(g2) | isempty(g3))
        
        %low pass filter for AC part upper cutoff
        [z1,p1,k1] = butter(filterOrder_AC_high,cutOff_AC_high/(samplingFrequency/2),'low');
        [sos1,g1] = zp2sos(z1,p1,k1);
        
        %low pass filter for AC part lower cotuoff
        [z2,p2,k2] = butter(filterOrder_AC_low,cutOff_AC_low/(samplingFrequency/2),'low');
        [sos2,g2] = zp2sos(z2,p2,k2);
        
        %low pass filter for DC part
        [z3,p3,k3] = butter(filterOrder_DC,cutOff_DC/(samplingFrequency/2),'low');
        [sos3,g3] = zp2sos(z3,p3,k3);
    end
    
    PPG_ac_upper = filtfilt(sos1,g1,PPG); %filter signal excerpt
    PPG_ac_lower = filtfilt(sos2,g2,PPG); %filter signal excerpt    
    PPG=PPG_ac_upper-PPG_ac_lower;%create BP filtered signal from which the AC part is extracted
    
    PPG_dc = filtfilt(sos3,g3,PPGinput); %filter signal excerpt
    PPG_dc = maximumValuePPGRange - PPG_dc;%do "re-inversion" of signal to get DC part
end

%% detect beats if not passed (here the signal used for the AC part is employed)
if(isempty(beatIndices) | isnan(beatIndices))
    [ beatIndices ] = pqe_beatDetection_lazaro( PPG', samplingFrequency, 0 );%find peaks (maximum slopes)
    beatIndices = beatIndices';
    % check consistency of available beats
    
    % number of beats range
    dataLengthInSeconds=numel(PPG)/samplingFrequency;%get length of data in seconds
    expectedMinimumNumberOfBeats=dataLengthInSeconds/60*minimumExpectedHR;%estimate minimum number of beats (assume HR of 30 bpm)
    expectedMaximumNumberOfBeats=dataLengthInSeconds/60*maximumExpectedHR;%estimate maximum number of beats (assume HR of 180 BPM=
    
    % check consistency
    if(isempty(beatIndices) | numel(beatIndices)<expectedMinimumNumberOfBeats | numel(beatIndices)>expectedMaximumNumberOfBeats)%if number of beats was unexpected
        errorCode=1;
        beatIndices=NaN;%indices of beat occurences
        beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
        meanBeatTemplate=NaN;%template segment
        beatMaximumIndex=NaN;%maximum of delineated beat
        beatStartIndex=NaN;%start index of delineated beat
        beatStopIndex=NaN;%end index of delineated beat
        acPart=NaN;%AC from ensemble beat
        perfusionIndex=NaN;%PI from enememble beat
        dcPart=NaN;%DC from ensemble beat
        ppgArea=NaN;%area of ensemble beats
        return
    end
end


%% here a routine for alignement (to match the slope) should be added
if(0)
    % still to do
end


%% determine segment length if not passed
if(isempty(segmentLength))%if no segment length is passed calculate it from the beat detections
    segmentLength=diff(beatIndices);%calculate beat to beat differences
    segmentLength=ceil(median(segmentLength));%get median length
    
    if(isnan(segmentLength))%if too few beat --> leave function
        errorCode=5;
        beatIndices=NaN;%indices of beat occurences
        beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
        meanBeatTemplate=NaN;%template segment
        beatMaximumIndex=NaN;%maximum of delineated beat
        beatStartIndex=NaN;%start index of delineated beat
        beatStopIndex=NaN;%end index of delineated beat
        acPart=NaN;%AC from ensemble beat
        perfusionIndex=NaN;%PI from enememble beat
        dcPart=NaN;%DC from ensemble beat
        ppgArea=NaN;%area of ensemble beats
        return
    end
    
    
end

%% create new template beat larger than a single beat (detection point - 45 % of segmentLength until detectionPoint + segmentLength)
beatIndicesEnsembleBeat=beatIndices;%get current beat indices
beforeInterval=round(segmentLength*0.45);%time interval before annotation
while(beatIndicesEnsembleBeat(1)-beforeInterval<=0)%remove beats which occur too early
    beatIndicesEnsembleBeat(1)=[];
    if(isempty(beatIndicesEnsembleBeat))
        break
    end
end
while( beatIndicesEnsembleBeat(end)+segmentLength >numel(PPG) )%remove beats which occur too late
    beatIndicesEnsembleBeat(end)=[];
    if(isempty(beatIndicesEnsembleBeat))
        break
    end
end
if(numel(beatIndicesEnsembleBeat)==0)%no beat left
    errorCode=2;
    beatIndices=NaN;%indices of beat occurences
    beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
    meanBeatTemplate=NaN;%template segment
    beatMaximumIndex=NaN;%maximum of delineated beat
    beatStartIndex=NaN;%start index of delineated beat
    beatStopIndex=NaN;%end index of delineated beat
    acPart=NaN;%AC from ensemble beat
    perfusionIndex=NaN;%PI from enememble beat
    dcPart=NaN;%DC from ensemble beat
    ppgArea=NaN;%area of ensemble beats
    return
end

beatSegments=arrayfun(@(x)PPG(x-beforeInterval:x+segmentLength),beatIndicesEnsembleBeat,...
    'UniformOutput', false); %concatenate single segments (unit length)
beatSegments=cell2mat(beatSegments')';%convert to matrix
toBeRemoved=unique(find( (sum(corr(beatSegments'))-1)/(size(beatSegments,1)-1) < requiredInterbeatCorrelation));%find beats which have too low correlation
beatSegments(toBeRemoved,:)=[];%remove beats with too low correlation
beatIndicesEnsembleBeat(toBeRemoved)=[];%remove beat indices with too low correlation
if(numel(beatIndicesEnsembleBeat)<mimimumNumberOfEnsembledBeats)%if too few beat --> leave function
    errorCode=2;
    beatIndices=NaN;%indices of beat occurences
    beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
    meanBeatTemplate=NaN;%template segment
    beatMaximumIndex=NaN;%maximum of delineated beat
    beatStartIndex=NaN;%start index of delineated beat
    beatStopIndex=NaN;%end index of delineated beat
    acPart=NaN;%AC from ensemble beat
    perfusionIndex=NaN;%PI from enememble beat
    dcPart=NaN;%DC from ensemble beat
    ppgArea=NaN;%area of ensemble beats
    return
end
meanBeatTemplate=mean(beatSegments,1);%calcuate mean beat of the remaining segments
alignementPoint = beforeInterval+1;%alignment point is the point were the detection was placed (rising edge)

%% delineate template

% delineate template beat - get initial minimum of beat
startingSegment=(meanBeatTemplate(1 : alignementPoint));%get frst part of the mean beat
[minima,minimaIndices] = findpeaks(-startingSegment);%get minima
if(~isempty(minima))
    if(1)%take last minimum before slope
        index = numel(minimaIndices);
    else%take smallest minimum
        [~,index]=min(-minima);%take lowest minimum
    end
    beatStartIndex=minimaIndices(index);
else
    beatStartIndex=NaN;
end
clear minima minimaIndices

% delineate template beat - get ending minimum of beat
endingSegment=(meanBeatTemplate(alignementPoint : end));%get second part of the mean beat
[minima,minimaIndices] = findpeaks(-endingSegment);
if(~isempty(minima))
    [~,index]=min(-minima);%take lowest minimum
    beatStopIndex=alignementPoint-1+minimaIndices(index);
else
    beatStopIndex=NaN;
end
clear minima minimaIndices

% check consistency
if(isnan(beatStartIndex) | isnan(beatStopIndex))
    errorCode=3;
    beatIndices=NaN;%indices of beat occurences
    beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
    meanBeatTemplate=NaN;%template segment
    beatMaximumIndex=NaN;%maximum of delineated beat
    beatStartIndex=NaN;%start index of delineated beat
    beatStopIndex=NaN;%end index of delineated beat
    acPart=NaN;%AC from ensemble beat
    perfusionIndex=NaN;%PI from enememble beat
    dcPart=NaN;%DC from ensemble beat
    ppgArea=NaN;%area of ensemble beats
    return
end

% do trend subtraction (from minimum to minimum)
trenddata=interp1([beatStartIndex beatStopIndex], [meanBeatTemplate(beatStartIndex); meanBeatTemplate(beatStopIndex)],1:numel(meanBeatTemplate),'linear','extrap')';%calculate straight line from first to last point
meanBeatTemplate = meanBeatTemplate-trenddata';%do detrending by removing the straight line

% delineate template beat to get maximum
endingSegment=(meanBeatTemplate(alignementPoint : end));
[maxima,maximaIndices] = findpeaks(endingSegment);
if(~isempty(maxima))
    if(1)%take first maximum after slope
        index = 1;
    else%take highest maximum
        [~,index]=max(maxima);
    end
    ensembleMaximum=maxima(index);
    beatMaximumIndex=alignementPoint-1+maximaIndices(index);
else
    ensembleMaximum=NaN;
    beatMaximumIndex=NaN;
end

%% calculate parameters (PI etc) by using an ensemble beat
if(~isnan(beatMaximumIndex) & ensembleMaximum > 0)
    acPart=ensembleMaximum;%the minum is forced to zero before
    dcPart=mean(PPG_dc(beatIndicesEnsembleBeat));%get dc
    perfusionIndex=acPart./dcPart;%calculate PI
    ppgArea = trapz(meanBeatTemplate(beatStartIndex:beatStopIndex));%calculate area under each beat
else%should not be possible...
    errorCode=4;
    beatIndices=NaN;%indices of beat occurences
    beatIndicesEnsembleBeat=NaN;%beat indices which were used for the ensemble beat
    meanBeatTemplate=NaN;%template segment
    beatMaximumIndex=NaN;%maximum of delineated beat
    beatStartIndex=NaN;%start index of delineated beat
    beatStopIndex=NaN;%end index of delineated beat
    acPart=NaN;%AC from ensemble beat
    perfusionIndex=NaN;%PI from enememble beat
    dcPart=NaN;%DC from ensemble beat
    ppgArea=NaN;%area of ensemble beats
    return
end

end
