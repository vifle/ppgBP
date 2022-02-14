function fs = unisens_get_samplerate(path, entry)
%UNISENS_GET_SAMPLERATE displays sample rate of a unisens entry
%   SAMPLERATE = UNISENS_GET_SAMPLERATE()
%   SAMPLERATE = UNISENS_GET_SAMPLERATE(PATH) 
%   SAMPLERATE = UNISENS_GET_SAMPLERATE(PATH, ENTRY_ID) 
%   SAMPLERATE = UNISENS_GET_SAMPLERATE(PATH, CONTENT_CLASS) 
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2010-04-13  file established 
%   2011-02-25  added content_class as argin


if (nargin >= 1)
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

try
    disp(['Sampling Rate:  ', num2str(j_entry.getSampleRate()), ' Hz']);
    fs = j_entry.getSampleRate();
catch
    fs = 0;
end

j_unisens.closeAll();