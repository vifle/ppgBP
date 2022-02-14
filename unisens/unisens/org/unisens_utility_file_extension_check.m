function r = unisens_utility_file_extension_check(entryId, fileFormat)
%UNISENS_UTILITY_FILE_EXTENSION_CHECK checks the matching of file format
%and file extension
%   ENTEY_ID = UNISENS_UTILITY_FILE_EXTENSION_CHECK(ENTRY_ID, FILE_FORMAT) 
%
%   Copyright 2010      FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2010-04-23  file established for Unisens 2.0   

% file extension check
if (length(entryId) <= 3)
    r = [entryId, '.', lower(fileFormat)];
elseif (~strcmpi(...
        entryId(length(entryId) - length(fileFormat):end), ...
        ['.' fileFormat]))
    r = [entryId, '.', lower(fileFormat)];
else
    r = entryId;
end
