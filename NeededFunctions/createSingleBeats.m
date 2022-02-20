function [singleBeatsProcessed,singleBeats,importantPoints] = createSingleBeats(signal,sampFreq,beatIndices,varargin)
% createSingleBeats Segments a pulse wave signal into single beats.
%
% REFERENCES:
%
% INPUT:
% 'signal':                 pulse wave signal
%
% 'freq':                   sampling frequency
%
% 'beatIndices':            indices of beats (obtained by using Lazaro
%                           algorithm)
%
% OUTPUT:
% 'singleBeatsProcessed':
%
% 'singleBeats':
%

%% TODO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 10s -> beachte, dass vllt nur wenige Schläge innerhalb der 10s gefunden
% werden; falls zu wenige, dann nimm letze segment length, falls es noch
% gar keine gibt, nimm segment length von gesamtem Signal
% wie macht zauni das?

% darf LAzaro für mehr als 10 s verwendet werden? Was sagt
% Veröffentlichung? SAgt nichts dagegen...Code mal analysieren Zauni hatte
% da ja eine Begrenzung auf 10s eingebaut

% signal muss gefiltert sein und lazaro durchlaufen haben

% TODO: reales Problem: singleBeats sind dann nicht mehr gleich lang für
% ensemble beats zB... aber machen ensemble beats über ein mehr als ein
% window sinn? sollte vllt trotzdem nen möglichen output für ensembles über
% gesamtes signal geben... (vllt am ende nochmal signal mit maximal großen
% borders zerlegen?

% check TODOs in code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% check input arguments
% signal, sampling frequency and beatindices are needed
if(nargin<3)
    errordlg('Too few arguments','Input Error','modal');
    return;
elseif(nargin>5)
    errordlg('Too many arguments','Input Error','modal');
    return;
end
% signal needs to be an array with more than one element
if(~(isvector(signal) && ~(isscalar(signal)) && ~(ischar(signal)) && ~isstring(signal)))
    errordlg('Signal needs to be an array with more than one element',...
        'Input Error','modal');
    return;
end
% sampFreq needs to be a scalar
if(~(isscalar(sampFreq) && ~(ischar(sampFreq)) && ~isstring(sampFreq)))
    errordlg('Sampling frequency needs to be a scalar value',...
        'Input Error','modal');
    return;
end
% beatIndices needs to be an array with at least one element
if(~(isvector(beatIndices) && ~(ischar(beatIndices)) && ~isstring(beatIndices)))
    errordlg('beatIndices needs to be an array with at least one element',...
        'Input Error','modal');
    return;
end
% turn signal into 1xn array
if(size(signal,1)>size(signal,2))
    signal = signal';
end
% turn beatIndices into nx1 array
if(size(beatIndices,1)<size(beatIndices,2))
    beatIndices = beatIndices';
end
% check optional arguments
okargs = {'windowLength'} ; % allowed argument specifiers
windowLength = 10; % window length (default = 10s)
i=1;
while(1)
    if(mod(size(varargin,2),2)~=0) % check if number of variable arguments is even
        errordlg('Uneven number of optional arguments not supported',...
            'Input Error','modal');
        return;
    end
    
    if(i>size(varargin,2)) % leave while loop if there are no more new variable arguments
        break;
    end
    
    if(ischar(varargin{i})) % evaluate key word of next argument
        if(ismember(varargin{i},okargs))
            actualArgument=varargin{i};
        else
            errordlg(['Specified Option ''' varargin{i} ''' is not a valid option'],...
                'Input Error','modal');
            return;
        end
        
    else
        errordlg(['Argument ' num2str(i+2) ' is not a valid option. A keyword needs to be inserted here.'],...
            'Input Error','modal');
        return;
    end
    
    switch actualArgument % set values for the actual arguments
        case 'windowLength'
            if(strcmp(varargin{i+1},'all'))
                % set windowLength to whole signal
                windowLength = numel(signal)/sampFreq;
            else
                if(~isscalar(varargin{i+1}))
                    errordlg('Window Length needs to be scalar',...
                        'Input Error','modal');
                    return;
                end
                if(~((varargin{i+1} > 0) && (varargin{i+1} < numel(signal)/sampFreq)))
                    errordlg('Window Length needs to be greater than 0 and smaller than signal duration',...
                        'Input Error','modal');
                    return;
                end
                windowLength = varargin{i+1};
            end
    end
    i=i+2;
end

%% assumptions
maxHeartRate = 200; % assumed maximum heart rate in bpm
minHeartRate = 35; % assumed minimum heart rate in bmp
minBeatNumberWindow = 3; % assumed minimum number of beats in a window
% TODO: needs to be adapted according to window length

%% derived from assumptions
minCardiacCycleTime = 1/(maxHeartRate/60); % minimum duration of a cardiac cycle in s
minCardiacCycleNumBeats = floor(minCardiacCycleTime*sampFreq); % minimum number of beats of a cardiac cycle
maxCardiacCycleTime = 1/(minHeartRate/60); % maximum duration of a cardiac cycle in s
maxCardiacCycleNumBeats = floor(maxCardiacCycleTime*sampFreq); % maximum number of beats of a cardiac cycle

%% do windowing
% get window length(s)
windowSamples = windowLength*sampFreq;
numFullWindows = floor(numel(signal)/windowSamples);
if(~(numFullWindows == numel(signal)/windowSamples)) % get number of windows
    numWindows = numFullWindows + 1; 
else
    numWindows = numFullWindows;
end

% initialize containers for output
singleBeatsProcessed = cell(0,0);
singleBeats = cell(0,0);
importantPoints = struct;
importantPoints(1).trends = NaN;
importantPoints(1).beatStartIndex = NaN;
importantPoints(1).beatStopIndex = NaN;
importantPoints(1).detectionPoint = NaN;
importantPoints(1).borders = [NaN;NaN];

currentOverallBeat = 0;

for currentWindow = 1:numWindows
    windowBorderStart = (currentWindow-1)*windowSamples+1;
    if(currentWindow == numWindows)
        windowBorderEnd = numel(signal);
    else
        windowBorderEnd = (currentWindow-1)*windowSamples+windowSamples;
    end
    
    % get all beat indices within current window
    beatIndicesWindow = beatIndices(beatIndices>=windowBorderStart & beatIndices<=windowBorderEnd);
    
    % if beatIndicesWindow is empty jump to next iteration (next window)
    if(numel(beatIndicesWindow) == 0)
        continue;
    end
    
    %% prepare extraction
    % check number of beats in window; if too few, take last segment length
    % (done implicitly as segmentLength etc is not deleted)
    if(numel(beatIndicesWindow) > minBeatNumberWindow && currentWindow > 1)
        % get segment length
        segmentLength = diff(beatIndicesWindow); % calculate beat to beat differences
        segmentLength = ceil(median(segmentLength)); % get median segment length
        beatIntervalBefore = round(0.45*segmentLength); % beat interval before detection point
        beatIntervalAfter = max(diff(beatIndicesWindow)); % beat interval after detection point
    elseif(currentWindow == 1)
        % initial segment length
        segmentLength = diff(beatIndicesWindow); % calculate beat to beat differences
        segmentLength = ceil(median(segmentLength)); % get median segment length
        beatIntervalBefore = round(0.45*segmentLength); % beat interval before detection point
        beatIntervalAfter = max(diff(beatIndicesWindow)); % beat interval after detection point
    end
    
    % remove incomplete beats
    numInsertBefore = 0;
    numInsertAfter = 0;
    while(beatIndicesWindow(1)-beatIntervalBefore <= 0)%remove beats which occur too early
        beatIndicesWindow(1)=[];
        numInsertBefore = numInsertBefore + 1;
        currentOverallBeat = currentOverallBeat + 1;
        if(isempty(beatIndicesWindow)) % TODO: what if window is so short that intervalBefore longer than a window?
            % that way currentWindow above 1 could need rejection and
            % become empty
            break
        end
    end
    while(beatIndicesWindow(end)+beatIntervalAfter > numel(signal))%remove beats which occur too late
        beatIndicesWindow(end)=[];
        numInsertAfter = numInsertAfter + 1;
        if(isempty(beatIndicesWindow))
            break
        end
    end

    
    %% cut signal
    singleBeatsWindow = arrayfun(@(x) signal(x-beatIntervalBefore:x+beatIntervalAfter),beatIndicesWindow,'UniformOutput',false); % cut PPG into single beats
    
    %% process single beats
    % initialize processing
    singleBeatsProcessedWindow = cell(size(singleBeatsWindow)); % initialize cell array for processed beats
    importantPointsWindow(numel(singleBeatsWindow)) = struct;
    
    for beatNum = 1:numel(singleBeatsWindow)
        % get current beat
        currentBeat = singleBeatsWindow{beatNum};
        currentOverallBeat = currentOverallBeat + 1;
        
        % catch nan beats
        if(isnan(currentBeat))
            singleBeatsProcessedWindow{beatNum} = currentBeat;
            importantPointsWindow(beatNum).trends = NaN;
            importantPointsWindow(beatNum).beatStartIndex = NaN;
            importantPointsWindow(beatNum).beatStopIndex = NaN;
            importantPointsWindow(beatNum).detectionPoint = NaN;
            importantPointsWindow(beatNum).borders = NaN;
            continue
        end
        
        % get initial minimum (start)
        startingSegment = currentBeat(1:beatIntervalBefore); % get frst part of the beat
        [minima,minimaIndices] = findpeaks(-startingSegment); % get minima
        if(~isempty(minima))
            beatStartIndex = minimaIndices(end); % take last minimum before slope
        else
            beatStartIndex = 1; % use earliest sample if there are no minima
        end
        clear minima minimaIndices
        
        % get ending minimum (end)
        endingSegment = currentBeat(beatIntervalBefore:end); % get second part of the beat
        [minima,minimaIndices] = findpeaks(-endingSegment); % get minima
        if(currentOverallBeat < numel(beatIndices)) % delete all minima after beatindex of next beat  
            while(minimaIndices(end)+beatIndices(currentOverallBeat) > beatIndices(currentOverallBeat+1))
                minimaIndices(end) = [];
                minima(end) = [];
                if(isempty(minimaIndices))
                    break;
                end
            end
        end     
        if(~isempty(minima)) % delete all minima after maximum cardiac cycle duration
            while(beatIntervalBefore + minimaIndices(end) - 1 > maxCardiacCycleNumBeats) 
                minimaIndices(end) = [];
                minima(end) = [];
                if(isempty(minimaIndices))
                    break;
                end
            end
        end
        if(~isempty(minima)) % delete all minima before minimum cardiac cycle duration
            while(beatIntervalBefore + minimaIndices(1) - 1 < minCardiacCycleNumBeats) 
                minimaIndices(1) = [];
                minima(1) = [];
                if(isempty(minimaIndices))
                    break;
                end
            end
        end
        if(~isempty(minima))
            beatStopIndex = beatIntervalBefore + minimaIndices(end) - 1; % -1 because beatInterval_before is already in endingSegment
        else
            if(length(currentBeat) < maxCardiacCycleNumBeats)
                beatStopIndex = length(currentBeat); % use last sample if there are no minima
            else
                beatStopIndex = maxCardiacCycleNumBeats; % use maximum possible cardiac cycle length if there are no minima and currentBeat seems to be longer than possible
            end
        end
        clear minima minimaIndices
        
        % detrend beat
        trenddata = interp1([beatStartIndex beatStopIndex],[currentBeat(beatStartIndex),currentBeat(beatStopIndex)], ...
            1:length(currentBeat),'linear','extrap'); %calculate straight line from first to last point
        currentBeat = currentBeat - trenddata; % do detrending by removing the straight line
        
        % shorten beat
        currentBeat = currentBeat(beatStartIndex:beatStopIndex);
        
        % fill temporary variables
        importantPointsWindow(beatNum).trends = trenddata(beatStartIndex:beatStopIndex);
        importantPointsWindow(beatNum).beatStartIndex = beatStartIndex;
        importantPointsWindow(beatNum).beatStopIndex = beatStopIndex;
        importantPointsWindow(beatNum).detectionPoint = beatIndicesWindow(beatNum);
        importantPointsWindow(beatNum).borders = [beatIntervalBefore;beatIntervalAfter];
        singleBeatsProcessedWindow{beatNum} = currentBeat;
    end
    
    % insert beats depending on current window if necessary
    importantPointsInsert = struct;
    importantPointsInsert(1).trends = NaN;
    importantPointsInsert(1).beatStartIndex = NaN;
    importantPointsInsert(1).beatStopIndex = NaN;
    importantPointsInsert(1).detectionPoint = NaN;
    importantPointsInsert(1).borders = [NaN;NaN];
    if(currentWindow==1 && numInsertBefore > 0) % TODO: would be goo to be independent of currentWindow
        for insertion = 1:numInsertBefore
            singleBeatsWindow = [{NaN};singleBeatsWindow];
            singleBeatsProcessedWindow = [{NaN};singleBeatsProcessedWindow];
            importantPointsWindow = [importantPointsInsert,importantPointsWindow];
        end
    end
    if((currentWindow==numWindows || currentWindow==numWindows-1) && numInsertAfter > 0) % TODO: would be goo to be independent of currentWindow
        for insertion = 1:numInsertAfter
            singleBeatsWindow = [singleBeatsWindow;{NaN}];
            singleBeatsProcessedWindow = [singleBeatsProcessedWindow;{NaN}];
            importantPointsWindow = [importantPointsWindow,importantPointsInsert];
        end
    end
    
    %% fuse windows to one output
    % concatenate everything
    % TODO: initialize before the loop?
    singleBeatsProcessed = [singleBeatsProcessed;singleBeatsProcessedWindow];
    singleBeats = [singleBeats;singleBeatsWindow];
    importantPoints = [importantPoints,importantPointsWindow];
    
    % clear window variables
    clear('singleBeatsProcessedWindow','singleBeatsWindow','importantPointsWindow');
    if(currentWindow==1)
        importantPoints(1) = []; % delete initial important points that are only made for initialization
    end

end
end