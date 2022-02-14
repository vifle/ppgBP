function rs = unisens_utility_bin_read(j_entry, pos, length)
%UNISENS_BIN_READ reads a SignalEntry from a binary file
%   UNISENS_BIN_READ(J_ENTRY) reads the J_ENTRY from a binary file. J_ENTRY
%   is of the type org.unisens.ri.Entry.
%   UNISENS_BIN_READ(J_ENTRY, POS, LENGTH) reads LENGTH samples from the binary
%   file starting at POS
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Julius Neuffer (neuffer@fzi.de)

%   Change Log
%   2010-03-29  file established
%   2010-03-31  added reading range

nSamples = j_entry.getCount();
if (nargin == 1)
    pos = 0;
    length = nSamples;
elseif (nargin == 3 && (pos + length) > nSamples)
    length = nSamples - pos;
end

% getting the path
path = char(concat(j_entry.getUnisens().getPath(), j_entry.getId()));

% checking the endianess
endianess = j_entry.getFileFormat().getEndianess();
if (endianess == org.unisens.Endianess.LITTLE)
    endianess = 'l';
elseif (endianess == org.unisens.Endianess.BIG)
    endianess = 'b';
end

% getting the channelCount
channelCount = j_entry.getChannelCount();

% getting the dataType
dataType = char(j_entry.getDataType().value());

if (strcmp(dataType, 'byte') || strcmp(dataType, 'short8'))
    dataType = 'integer*1';
elseif (strcmp(dataType, 'long32'))
    dataType = 'integer*3';
end

% open
fid = fopen(path, 'r', endianess);

% seek
if (pos > 0)
    size = 1;
    if (strcmp(dataType, 'short16') || strcmp(dataType, 'int16'))
        size = 2;
    elseif (strcmp(dataType, 'int32') || strcmp(dataType, 'integer*3') || strcmp(dataType, 'float'))
        size = 4;
    elseif (strcmp(dataType, 'double'))
        size = 8;
    end
    
    fseek(fid, channelCount * pos * size, 'bof');
end

% read
rs = fread(fid, [channelCount, length], dataType)';

% close
fclose(fid);

end