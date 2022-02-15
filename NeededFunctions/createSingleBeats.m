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

%% TODO
% option for no window (should work like before)

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO:

% problem: bei Fabi hat das mit beat indices in 1xN nicht geklappt --> das
% mal vorher auslesen und anpassen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% check input arguments
% both signal and sampling frequency are needed
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
% turn signal into 1xn array
if(size(signal,1)>size(signal,2))
    signal = signal';
end
% check optional arguments
okargs = {'windowLength'} ; % allowed argument specifiers
windowLength = 10; % window length
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
            if(~isscalar(varargin{i+1}))
                errordlg('Window Length needs to be scalar',...
                    'Input Error','modal');
                return;
            end
            % TODO: window length must be greater than zero and less than
            % whole signal;
            % TODO: what about option not to use a window?
    end
    i=i+2;
end

%% do windowing
% get window length(s)
windowSamples = windowLength*sampFreq;
numFullWindows = floor(numel(signal)/windowSamples);
numWindows = numFullWindows + 1; % TODO: alsways the case? what if this is exactly numWindows?

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
    
    % TODO: what if beatIndicesWindow is empty?
    % --> could (or should?!) jump to next iteration (next window)
    if(numel(beatIndicesWindow) == 0)
        continue;
    end
    
    %% prepare extraction
    % check number of beats in window; if too few, take last segment length
    if(numel(beatIndicesWindow) > 3 && currentWindow > 1)
        % get segment length
        segmentLength = diff(beatIndicesWindow); % calculate beat to beat differences
        segmentLength = ceil(median(segmentLength)); % get median segment length
        beatIntervalBefore = round(0.45*segmentLength); % beat interval before detection point
        
        %%%%%%% Changed this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %beatIntervalAfter = segmentLength; % beat interval after detection point
        beatIntervalAfter = max(diff(beatIndicesWindow)); % beat interval after detection point
        %%%%%%% Changed this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    elseif(currentWindow == 1)
        % initial segment length
        segmentLength = diff(beatIndicesWindow); % calculate beat to beat differences
        segmentLength = ceil(median(segmentLength)); % get median segment length
        beatIntervalBefore = round(0.45*segmentLength); % beat interval before detection point
        
        %%%%%%% Changed this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %beatIntervalAfter = segmentLength; % beat interval after detection point
        beatIntervalAfter = max(diff(beatIndicesWindow)); % beat interval after detection point
        %%%%%%% Changed this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    end
    
    % remove incomplete beats --> TODO: what if
    % only window is too short for loop?
    numInsertBefore = 0;
    numInsertAfter = 0;
    while(beatIndicesWindow(1)-beatIntervalBefore <= 0)%remove beats which occur too early
        beatIndicesWindow(1)=[];
        numInsertBefore = numInsertBefore + 1;
        if(isempty(beatIndicesWindow)) % TODO: what if window is so short that intervalBefore longer than a window?
            % that way currentWindow above 1 could need rejection and
            % become empty
            % TODO: return something
            break
        end
    end
    while(beatIndicesWindow(end)+beatIntervalAfter > numel(signal))%remove beats which occur too late
        beatIndicesWindow(end)=[];
        numInsertAfter = numInsertAfter + 1;
        if(isempty(beatIndicesWindow))
            % TODO: return something
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
        
        % catch nan beats (TODO: necessary?)
        if(isnan(currentBeat))
            singleBeatsProcessedWindow{beatNumber} = currentBeat;
            % TODO: need to fill other returned vars with nan
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
        clear minima minimaIndices % TODO: needed as the number of detected minima can vary between different beats?
        
        % get ending minimum (end)
        endingSegment = currentBeat(beatIntervalBefore:end); % get second part of the beat
        [minima,minimaIndices] = findpeaks(-endingSegment); % get minima
        
        
        %%%%%%% Changed this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % delete all minima after beatindex of next beat        
        if(currentOverallBeat < numel(beatIndices))
            while(minimaIndices(end)+beatIndices(currentOverallBeat) > beatIndices(currentOverallBeat+1))
                minimaIndices(end) = [];
                minima(end) = [];
            end
        end
        %%%%%%% Changed this %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        if(~isempty(minima))
            % TODO: sebastian uses first minimum
            [~,index] = min(-minima);%take lowest minimum
            beatStopIndex = beatIntervalBefore + minimaIndices(index) - 1; % -1 because beatInterval_before is already in endingSegment
        else
            beatStopIndex = length(currentBeat); % use last sample if there are no minima
        end
        clear minima minimaIndices % TODO:  needed as the number of detected minima can vary between different beats?
        
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
    
    % TODO: insert beats depending on current window if necessary
    % TODO: add description
    importantPointsInsert = struct;
    importantPointsInsert(1).trends = NaN;
    importantPointsInsert(1).beatStartIndex = NaN;
    importantPointsInsert(1).beatStopIndex = NaN;
    importantPointsInsert(1).detectionPoint = NaN;
    importantPointsInsert(1).borders = [NaN;NaN];
    if(currentWindow==1 && numInsertBefore > 0)
        for insertion = 1:numInsertBefore
            singleBeatsWindow = [{NaN},singleBeatsWindow];
            singleBeatsProcessedWindow = [{NaN};singleBeatsProcessedWindow];
            importantPointsWindow = [importantPointsInsert;importantPointsWindow];
        end
    end
    if((currentWindow==numWindows || currentWindow==numWindows-1) && numInsertAfter > 0)
        for insertion = 1:numInsertAfter
            singleBeatsWindow = [singleBeatsWindow;{NaN}];
            singleBeatsProcessedWindow = [singleBeatsProcessedWindow;{NaN}];
            importantPointsWindow = [importantPointsWindow,importantPointsInsert];
        end
    end
    
    %% fuse windows to one output
    % concatenate everything
    % TODO: initialize before the loop?
    % TODO: i do not take into account deleting beats at beginning and end
    singleBeatsProcessed = [singleBeatsProcessed;singleBeatsProcessedWindow];
    singleBeats = [singleBeats;singleBeatsWindow];
    importantPoints = [importantPoints,importantPointsWindow];
    
    % clear window variables
    clear('singleBeatsProcessedWindow','singleBeatsWindow','importantPointsWindow');
    if(currentWindow==1)
        importantPoints(1) = [];
    end

end
end