function [entries,j_entries] =  unisens_utility_get_entries(path)
%   author: Martin Schmidt
%   version: 2015-02-10

%% create or open dataset and add entry
j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

j_entries = j_unisens.getEntries();
nEntries = j_entries.size();

for i=0:nEntries-1
    j_entry = j_entries.get(i);
    try
        content_class = char(j_entry.getContentClass());
    catch
        content_class = '';
    end
    if (nargin == 1  ||  ismember(content_class, varargin))
        entries(i+1).Id = j_entry.getId();
        entries(i+1).Comment = j_entry.getComment();
        try
            entries(i+1).ChannelCount = j_entry.getChannelCount;
        catch
            entries(i+1).ChannelCount = NaN;
        end
        try
            entries(i+1).Length = j_entry.getCount;
        catch
            entries(i+1).Length = NaN;
        end
        try
            entries(i+1).SampleRate = j_entry.getSampleRate();
        catch
            entries(i+1).SampleRate = NaN;
        end
    end
end

j_unisens.closeAll();

end