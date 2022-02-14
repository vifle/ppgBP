% call: unisens_converter(pathname, datasetname, data)
% this function can be used to create an unisens dataset from a predefined
% data structure
% 
% pathname: path in the filesystem to save the unisens dataset
% datasetname: name for the dataset
% data: structure of the data to save
%
% data.comment (optional): comment for the dataset (dafault: 'Matlab converted <datasetname>')
% data.starttime (optional): starting time of the measurement (dafault: current time)
%
% data.signals: all entries below this struct are treated as signals to save in the dataset
% data.signals.<name>.sampleRate (optional): sampleRate in Hz (default: 1000)
% data.signals.<name>.physicalUnit (optional): string of physical units of the data (default: 'V')
% data.signals.<name>.comment (optional): comment for this signal (default: '')
% data.signals.<name>.content (optional): string specifying the kind of data (ex. 'ECG', 'TRIGGER', 'PPG', etc.; default is '')
% data.signals.<name>.data: the data in rows, each row is a different channel
% data.signals.<name>.readonly (optional): if true the entry's file is marked as readonly (default: false)
%
% data.annotations: all entries below this struct are treated as annotations
% data.annotations.<name>.sampleRate (optional): sampleRate in Hz (default: 1000)
% data.annotations.<name>.comment (optional): comment for this annotation (default: '')
% data.annotations.<name>.data: the samplestamps as vector
% data.annotations.<name>.marker: the marker to use (ex. 'N')
% data.annotations.<name>.readonly (optional): if true the entry's file is marked as readonly (default: false)
%
% data.values: all entries below this struct are treated as value entries
% data.values.<name>.comment (optional): comment on entry
% data.values.<name>.content (optional): string specifying the class of data (ex. 'ECG', 'TRIGGER', 'PPG', etc.; default is '')
% data.values.<name>.sampleRate (optional): sampleRate in Hz (default: 1000)
% data.values.<name>.data: a c-by-n matrix with n values, first column are the timestamps and second to c-th column contains values (each row on another channel)
% data.values.<name>.physicalUnit (optional): string of physical units of the data (default: '')
% data.values.<name>.readonly (optional): if true the entry's file is marked as readonly (default: false)
% data.values.<name>.channelNames (optional): vector of strings naming the channels of the data (by default 'ch1', 'ch2' and so on)
%
% author: Enrico Grunitz
% version: 2012-11-12

function unisens_converter(pathname, datasetname, data)
%read function definition file for help

% checking for unisens and imports
if(0)%this check should only be activated if unsiens is installed - if unisens libraries are temporaily added to path check fails
    if(~checkUnisens())
        return;
    end
    import org.unisens.Unisens
    import org.unisens.ri.UnisensImpl
    import org.unisens.SignalEntry
    import org.unisens.Entry
    import org.unisens.ri.SignalEntryImpl
end

%% checking paths
if(~isdir(pathname)) 
    disp(['Given path ' pathname ' is not a valid directory - abort operation.']);
    return;
end
if(isdir([pathname '\' datasetname]))
    disp(['Dataset directory ' [pathname '\' datasetname] ' already exists.']);
    userInput = input('Delete dataset to continue operation? (y/n) ', 's');
    switch userInput
        case {'y' 'Y'}
            retval = rmdir([pathname '\' datasetname], 's');
            if retval ~= 1
                disp('Could not delete existing directory - abort operation.');
                disp(retval);
                return;
            end
        otherwise
            disp('Aborting operation.');
            return;
    end
end
clear retval userInput;

%% creating general dataset data
unisens.path = pathname;
unisens.name = datasetname;
unisens.measurementId = datasetname;
if(isfield(data, 'comment'))
    unisens.comment = data.comment;
else
    unisens.comment = ['Matlab converted ' datasetname];
end
if(isfield(data, 'starttime'))
    unisens.timestampStart = data.starttime;
else
    unisens.timestampStart = java.util.Date();
end
unisens_utility_create(unisens);
% prepare file attribute modification
roFilenames = cell(java.lang.String());
fnSize = 0;

%% creating signals
if(isfield(data, 'signals'))
    names = fieldnames(data.signals);
    if(~isempty(names))
        for i = 1:size(names)
            disp(['converting signal ' names{i}]);
            tempDataStruct = data.signals.(names{i});
            se.fileFormat = 'bin';
            se.adcResolution = 32;
            se.adcZero = 2^(se.adcResolution - 1);
            se.lsbValue = 0.0;
            se.dataType = 'DOUBLE';
            se.entryId = [names{i} '.bin'];
            se.data = tempDataStruct.data;
            se.channelNames = 'ch1';
            for j = 2:size(se.data, 1);
                se.channelNames = char(se.channelNames, ['ch' num2str(j)]);
            end
            if(isfield(tempDataStruct, 'sampleRate'))
                se.sampleRate = tempDataStruct.sampleRate;
            else
                se.sampleRate = 1000;
            end
            if(isfield(tempDataStruct, 'physicalUnit'))
                se.unit = tempDataStruct.physicalUnit;
            else
                se.unit = 'V';
            end
            if(isfield(tempDataStruct, 'comment'))
                se.entryComment = tempDataStruct.comment;
            else
                se.entryComment = '';
            end
            if(isfield(tempDataStruct, 'content'))
                se.contentClass = tempDataStruct.content;
            else
                se.contentClass = '';
            end
            unisens_utility_add_signalentry([unisens.path '\' unisens.name], se);
            if(isfield(tempDataStruct, 'readonly'))
                if(tempDataStruct.readonly == true)
                    fnSize = fnSize + 1;
                    roFilenames(fnSize) = cell(java.lang.String([names{i} '.' se.fileFormat]));
                end
            end
        end
    else
        disp('no signals converted');
    end
else
    disp('no signals converted');
end
clear tempDataStruct names se;
%% creating annotations
if(isfield(data, 'annotations'))
    names = fieldnames(data.annotations);
    if(~isempty(names))
        for i = 1:size(names)
            disp(['converting annotation ' names{i}]);
            %tempAnnoStruct = getfield(data.annotations, names{i});
            tempAnnoStruct = data.annotations.(names{i});   % dynamic fieldnames are awesome
            ee.contentClass = 'TRIGGER';
            ee.fileFormat = 'csv';
            if(isfield(tempAnnoStruct, 'sampleRate'))
                ee.sampleRate = tempAnnoStruct.sampleRate;
            else
                ee.sampleRate = 1000;
            end
            ee.entryId = names{i};
            if(isfield(tempAnnoStruct, 'marker'))
                marker = tempAnnoStruct.marker;
            else
                marker = 'N';
            end
            if(isfield(tempAnnoStruct, 'comment'))
                ee.entryComment = tempAnnoStruct.comment;
            else
                ee.entryComment = '';
            end
            ee.data = convertVectorToEventList(tempAnnoStruct.data, marker);
            ee.typeLength = max(cellfun(@length, marker));
            unisens_utility_add_evententry([unisens.path '\' unisens.name], ee);
            if(isfield(tempAnnoStruct, 'readonly'))
                if(tempAnnoStruct.readonly == true)
                    fnSize = fnSize + 1;
                    roFilenames(fnSize) = cell(java.lang.String([names{i} '.' ee.fileFormat]));
                end
            end
        end
    else
        disp('no annotations converted');
    end
else
    disp('no annotations converted');
end
clear tempAnnoStruct names marker ee;
%% creating values
if(isfield(data, 'values'))
    names = fieldnames(data.values);
    if(~isempty(names))
        for i = 1:size(names)
            disp(['converting value ' names{i}]);
            tempValueStruct = data.values.(names{i});
            ve.entryId = names{i};
            if(isfield(tempValueStruct, 'comment'))
                ve.entryComment = tempValueStruct.comment;
            else
                ve.entryComment = '';
            end
            if(isfield(tempValueStruct, 'content'))
                ve.contentClass = tempValueStruct.content;
            else
                ve.contentClass = '';
            end
            if(isfield(tempValueStruct, 'fileFormat'))
                ve.fileFormat = tempValueStruct.fileFormat;
            else
                ve.fileFormat = 'csv';
            end
            if(isfield(tempValueStruct, 'sampleRate'))
                ve.sampleRate = tempValueStruct.sampleRate;
            else
                ve.sampleRate = 1000;
            end
            ve.dataType = 'DOUBLE';
            ve.data = convertMatrixToValueArrayMD(tempValueStruct.data);
            %ve.channelNames(1) = java.lang.String('ch1');
            ve.channelNames = 'ch1';
            for j = 2:(size(tempValueStruct.data, 2) - 1);
                ve.channelNames = char(ve.channelNames, ['ch' num2str(j)]);
            end
            if(isfield(tempValueStruct, 'physicalUnit'))
                ve.physicalUnit = tempValueStruct.physicalUnit;
            end
            unisens_utility_add_valuesentry([unisens.path '\' unisens.name], ve);
            if(isfield(tempValueStruct, 'readonly'))
                if(tempValueStruct.readonly == true)
                    fnSize = fnSize + 1;
                    roFilenames(fnSize) = cell(java.lang.String([names{i} '.' ve.fileFormat]));
                end
            end
        end
    else
        disp('no values converted');
    end
else
    disp('no values converted');
end
clear tempValueStruct names ve;

%% set readonly attribute to selected files
if(fnSize > 0)
    markReadOnly([unisens.path '\' unisens.name '\'], roFilenames);
end

clear fnSize roFilenames;
end % of function unisens_converter(pathname, datasetname, data)

%% convertVectorToEventList(data)
% Converts array into Java's ArrayList
function eventList = convertVectorToEventList(data, marker)
import org.unisens.Event;
import java.util.ArrayList;

iMax = length(data);
eventList = ArrayList(iMax);
for i = 1:iMax
    event = Event(data(i),marker{i}, '');
    eventList.add(event);
end
end % of function convertVectorToEventList(data, marker)

%% convertMatrixToValueArray(data)
% Converts a 2-by-n matrix into a Java array of org.unisens.Value's. First
% row is the Values value and second row is the timestamp.
%
% replaced by new version convertMatrixToValueArrayMD(data)
function valueArray = convertMatrixToValueArray(data)
import org.unisens.Value;

iMax = size(data,2);
valueArray(iMax) = Value(0, 0);
for i = 1:iMax
    valueArray(i) = Value(data(2,i), data(1,i));
end

end % of function convertMatrixToValueArray(data)

%% convertMatrixToValueArrayMD(data)
% Converts a m-by-n matrix into a Java array of org.unisens.Value's. First
% row is the Values timestamp and second to m-th row is the value (each
% row is a different channel).
function valueArray = convertMatrixToValueArrayMD(data)
import org.unisens.Value;

iMax = size(data, 1);
valueArray(iMax) = Value(0, 0);
for i = 1:iMax
    valueArray(i) = Value(data(i, 1), data(i, 2:end));
end

end % of function convertMatrixToValueArrayMD(data)


%% checkUnisens()
% Checks for correct installation of the unisens toolbox. If it is
% installed it adds the toolbox directory to the path-variable.
% author: Enrico Grunitz
% version: 2012-09-28
function retVal = checkUnisens()
    if(isdir([toolboxdir('') '\unisens']))
        % unisens dir exists
        addpath(toolboxdir('unisens'));
        retVal = true;
    else
        %unisens dir doesn't exist
        disp('It looks like the unisens toolbox isn''t installed correctly on your Matlab.');
        disp('Please make sure the toolbox is installed to ''%matlabroot%\toolbox\unisens''.');
        disp('See also http://www.unisens.org on the interwebs for further details.')
        retVal = false;
    end
end

%% markReadOnly(path, filenames)
% Marks all files in filenames as readonly in the file system.
% parameters:
%   path: path in the filesystem
%   filenames: cell array of java.lang.String containing the filenames
function markReadOnly(path, filenames)
    counter = 0;
    if(isdir(path))
        for i = 1:length(filenames)
            if(exist([path char(filenames(i))], 'file'))
                fileattrib([path char(filenames(i))], '-w');
                counter = counter + 1;
                fprintf('\t%s (readonly)\n', [path char(filenames(i))])
            else
                disp(['File ' path char(filenames(i)) ' doesn''t exist.']);
            end
        end
    end
    disp(['Marked ' num2str(counter) ' files as readonly.']);
end
