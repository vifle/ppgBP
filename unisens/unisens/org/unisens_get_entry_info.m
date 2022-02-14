function unisens_get_entry_info(path, entry_id)
%UNISENS_GET_ENTRY_INFO displays all information of a unisens entry
%   UNISENS_GET_ENTRY_INFO()
%   UNISENS_GET_ENTRY_INFO(PATH) 
%   UNISENS_GET_ENTRY_INFO(PATH, ENTRY_ID) 
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2008-02-26  file established for Unisens 2.0, rev409   
%   2008-03-04  fixed data type bug
%   2008-06-27  updates for new repository, rev21
%   2011-02-25  added timestampStart


if (nargin >= 1)
    path = unisens_utility_path(path);
else
    path = unisens_utility_path();
end

j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

if (nargin == 2)
    entryId = entry_id;
else
    entryId = unisens_utility_entry_chooser(j_unisens);
end

j_entry = j_unisens.getEntry(entryId);

disp(' ');
disp('===========================================');
disp('                Information');
disp('===========================================');
disp(' ');
disp('File');
disp(['Path:           ', path]);

try
    disp(['Comment:        ', char(j_unisens.getComment())]);
catch
end

try
    disp(['Source Type:    ', char(j_unisens.getSourceType())]);
catch
end

try
    disp(['Source:         ', char(j_unisens.getSource())]);
catch
end

try
    disp(['Start:          ', char(j_unisens.getTimestampStart())]);
catch
end

disp(' ');
disp('===========================================');
disp(' ');
disp('Entry');
disp(['ID:             ', entryId]);

try
    disp(['Content Class:  ', char(j_entry.getContentClass())]);
catch
end

try
    disp(['Comment:        ', char(j_entry.getComment())]);
catch
end

try
    disp(['Channels:       ', num2str(j_entry.getChannelCount)]);
    channelNames = char(j_entry.getChannelNames());
    for ( i = 1: size(channelNames, 1) )
        disp(['                ', channelNames(i, : )]);
    end
catch
end

try
    disp(['Samples:        ', num2str(j_entry.getCount)]);
catch
end

try
    disp(['Sampling Rate:  ', num2str(j_entry.getSampleRate()), ' Hz']);
catch
end

try
    disp(['ADC Zero:       ', num2str(j_entry.getAdcZero()), ' ']);
catch
end

try
    disp(['Baseline:       ', num2str(j_entry.getBaseline()), ' ']);
catch
end

try
    disp(['ADC Resolution: ', num2str(j_entry.getAdcResolution()), ' bit']);
catch
end

try
    unit = char(j_entry.getUnit());
    disp(['Unit:           ', unit, ' ']);
catch
end

try
    disp(['LSB:            ', num2str(j_entry.getLsbValue()), ' ', unit]);
catch
end

try
    disp(['Data Type:      ', char(j_entry.getDataType()), ' ']);
catch
end

try
    disp(['Type Length:    ', num2str(j_entry.getTypeLength()), ' ']);
catch
end

try
    disp(['Comment Lenght: ', num2str(j_entry.getCommentLength()), ' ']);
catch
end


disp(' ');
disp('===========================================');