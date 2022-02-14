function [rs, j_entry] = unisens_get_data(path, entry, range)
%UNISENS_GET_DATA    loads data
%   DATA = UNISENS_GET_DATA()
%   DATA = UNISENS_GET_DATA(PATH) loads data from PATH. If there is more 
%   than one entry, the entry has to be chosen. If PATH is empty, a
%   directory open dialog appears.
%   DATA = UNISENS_GET_DATA(PATH, CONTENT_CLASS) Only entries of the given
%   classType CONTENT_CLASS are listed. If there is only one entry of the
%   given classType, the entry is opened automaticly.
%   DATA = UNISENS_GET_DATA(PATH, ENTRY_ID) ENTRY_ID is the entyId of a 
%   specific entry.
%
%   DATA = UNISENS_GET_DATA(PATH, ENTRY_ID, RANGE) or 
%   DATA = UNISENS_GET_DATA(PATH, CONTENT_CLASS, RANGE) preselects a start
%   position and a length (e.g. [0, 100] for the 1st 100 values of each
%   channel). If RANGE = 'all', all data is read. If RANGE exceeds the data
%   range, a warning is given.
%
%   When used with two left-hand arguments, as in 
%   [DATA, J_ENTRY] = UNISENS_GET_DATA(...), the Java object J_ENTRY 
%   contains all entry information.

%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)
%                       Julius Neuffer (neuffer@fzi.de)

%   Change Log         
%   2007-12-06  file established for Unisens 2.0, rev409   
%   2008-02-05  working with revision 534 and Matlab 7.5
%   2008-03-13  entry_id via command
%   2008-06-27  updates for new repository, rev21
%   2010-03-17  returns MathLab data types for EventEntry and SignalEntry
%   2010-03-30  returns structs instead of cell array for EventEntry and
%               SignalEntry, uses unisens_utility_bin_read to read in SignalEntry
%               binary files
%   2010-03-31  parameter entry is either entryId or classType, user is
%               prompted for a range to read
%   2010-04-01  returns eventEntry.type as cell array
%   2010-04-21  new prompt text, new help text, 2nd return value (j_entry)
%               and RANGE as 3rd parameter
%   2011-02-25  unisens_utility_csv_read established

if (nargin >= 1 && ~isempty(path))
    path = unisens_utility_path(path);
else
    path = unisens_utility_path();
end

j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

if (nargin >= 2)
    % 2nd parameter is either entryId or contentClass. Try if it's an
    % entryId first...
    entryId = entry;
    j_entry = j_unisens.getEntry(entryId);
    
    % ... if the result is empty, it is a contentClass.
    if (isempty(j_entry))
        entryId = unisens_utility_entry_chooser(j_unisens, entry);
        j_entry = j_unisens.getEntry(entryId);
    end
else
    entryId = unisens_utility_entry_chooser(j_unisens);
    j_entry = j_unisens.getEntry(entryId);
end

nSamples = j_entry.getCount();


% check the optional 3rd parameter RANGE
if (nargin < 3)
    range = input(['Enter length or offset and length (default is [0, ', num2str(nSamples), ']): ']);
elseif (nargin == 3 && strcmp(range, 'all'))
    range = [];
end

% check the range
if (isempty(range))
    pos = 0;
    nRead = nSamples;
elseif (length(range) == 1)
    pos = 0;
    if (range > nSamples)
        warning('Given range exceeds data');
        nRead = nSamples;
    else
        nRead = range;
    end
elseif (length(range) == 2)
    if ((range(1) + range(2)) > nSamples)
        pos = range(1);
        if (range(2) > nSamples)
            warning('Given range exceeds data');
        end
        nRead = nSamples - pos;
    else
        pos = range(1);
        nRead = range(2);
    end
end

% SignalEntry bin files can be read with unisens_utility_bin_read
% disp(['Reads ', num2str(nRead), ' samples from entry ', entryId, '...']);
if (isa(j_entry, 'org.unisens.ri.SignalEntryImpl') && strcmp(char(j_entry.getFileFormat.getFileFormatName), 'BIN'))
    rs = unisens_utility_bin_read(j_entry, pos, nRead);
% EventEntry csv files can be read using unisens_utility_csv_read
elseif (isa(j_entry, 'org.unisens.ri.EventEntryImpl') && strcmp(char(j_entry.getFileFormat.getFileFormatName), 'CSV'))
    rs = unisens_utility_csv_read(j_entry, pos, nRead);
else
    rs = j_entry.read(pos, nRead);
end

% convert Java data types to Matlab
if (isjava(rs))
    % EventEntry
    if (isa(rs, 'java.util.ArrayList'))
        j_eventArray = rs.toArray();
        arrayLength = j_eventArray.length;
        rs = struct;
        rs.samplestamp = zeros(1, arrayLength);
        rs.type = cell(1, arrayLength);
        rs.comment = cell(1, arrayLength);
        for i = 1:arrayLength
            rs.samplestamp(i) = j_eventArray(i).getSamplestamp();
            rs.type(i) = j_eventArray(i).getType();
            rs.comment(i) = j_eventArray(i).getComment();
        end
    % ValueEntry
    elseif (isa(rs, 'org.unisens.Value[]'))
        j_valueArray = rs;
        arrayLength = j_valueArray.length;
        rs = struct;
        rs.samplestamp = zeros(arrayLength, 1);
        rs.values = zeros(arrayLength, j_entry.getChannelCount());
        for i = 1:arrayLength
            rs.samplestamp(i) = j_valueArray(i).getSamplestamp();
            rs.values(i, 1:end) = j_valueArray(i).getData();
        end
    end
end

j_unisens.closeAll();


