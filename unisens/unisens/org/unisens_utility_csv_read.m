function rs = unisens_utility_csv_read(j_entry, pos, lngth)
%UNISENS_CSV_READ reads an EventEntry from a CSV file
%   UNISENS_CSV_READ(J_ENTRY) reads the J_ENTRY from a CSV file. J_ENTRY
%   is of the type org.unisens.ri.Entry.
%   UNISENS_CSV_READ(J_ENTRY, POS, LENGTH) reads LENGTH samples from the
%   CSV file starting at POS

%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Julius Neuffer (neuffer@fzi.de)

%   Change Log
%   2011-01-28  file established

nSamples = j_entry.getCount();
if (nargin == 1)
    pos = 0;
    lngth = nSamples;
elseif (nargin == 3 && (pos + lngth) > nSamples)
    lngth = nSamples - pos;
end

% getting the path
path = char(concat(j_entry.getUnisens().getPath(), j_entry.getId()));

% checking the delimiter
delimiter = char(j_entry.getFileFormat.getSeparator());

% read the whole CSV file and transpose the results
[rs.samplestamp, rs.type, rs.comment] = textread(path, '%n%s%s', 'delimiter', delimiter);
rs.samplestamp = rs.samplestamp';
rs.type = rs.type';
rs.comment = rs.comment';

% trim start position 
if (pos > 0)
    rs.samplestamp(1:pos) = [];
    rs.type(1:pos) = [];
    rs.comment(1:pos) = [];
end

% trim length
if (lngth < length(rs.samplestamp))
    rs.samplestamp(lngth + 1:end) = [];
    rs.type(lngth + 1:end) = [];
    rs.comment(lngth + 1:end) = [];
end

end