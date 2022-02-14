function entryId = unisens_utility_entry_chooser(j_unisensFile, varargin)
%UNISENS_UTILITY_ENTRY_CHOOSER  select entry
%   UNISENS_UTILITY_ENTRY_CHOOSER(J_UNISENS_FILE) let select you one entry
%   of J_UNISENS_FILE
%   UNISENS_UTILITY_ENTRY_CHOOSER(J_UNISENS_FILE, CLASS_TYPE, ...)
%   CLASS_TYPE specifies a list of Unisens class types that should be
%   available
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2007-12-06  file established for Unisens 2.0, rev409   
%   2008-04-11  selection via contentClass

j_entries = j_unisensFile.getEntries();
nEntries = j_entries.size();

j = 0;
for ( i = 0:nEntries - 1)
    j_entry = j_entries.get(i);
    try
        content_class = char(j_entry.getContentClass());
    catch
        content_class = '';
    end
    if (nargin == 1  ||  ismember(content_class, varargin))
        j = j + 1;
        entryIdList{j} = char(j_entry.getId());
        disp([num2str(j), '.: ', char(j_entry.getId())]);
        if (~isempty(content_class))
            disp(['    ', content_class]);
        end
        disp(['    ', char(j_entry.getComment())]);
        try
            channels = [', ', num2str(j_entry.getChannelCount), ' Channels'];
        catch
            channels = '';
        end
        try
            count = [', ', num2str(j_entry.getCount), ' Samples'];
        catch
            count = '';
        end
        try
            disp(['    ', num2str(j_entry.getSampleRate()), ' Hz, ', count, channels]);
        catch
            disp(['    ', count, channels]);
        end
        disp(' ');
    end
end

% choose entry, if there are more than one entry
if (j > 1)
    iEntry = input(['Choose entry number (1 to ', num2str(j), ') or contentClass: '], 's');

    if (isempty(str2num(iEntry)))
        % recursive function call
        entryId = unisens_utility_entry_chooser(j_unisensFile, upper(iEntry));
        return
    else
        iEntry = str2num(iEntry);
    end
else
    iEntry = 1;
end



if (isempty(iEntry(1)) || iEntry(1) > j || iEntry(1) < 1)
    error('Abort...');
    return;
end

for i = 1:length(iEntry)
    entryId{i} = entryIdList{iEntry(i)};
end