%% Unisens Example
% This is an example how to use Unisens 2.0 with Matlab.
% 
%   Example:
%
%       web(publish('unisens_example', 'html'))
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)


%% Checking Unisens version
unisens_version();

%% Creating a Unisens File
% We create first a struct 'unisens' with general data. The Unisens folder
% is to be selected first. By the way: There are a lot of applicable 
% m-files for use in other m-files or functions. Their names always begin 
% with |unisens_utility_|.

unisens.path = tempname;
unisens.name = ['Unisens_Sample_', strrep(strrep(datestr(now), ':', '-'), ' ', '_')];
unisens.measurementId = 'test-id 001';
unisens.comment = 'Das ist eine Testdatei';
unisens.timestampStart = java.util.Date;

% The created general data are written to a new Unisens file.
unisens_utility_create(unisens);

% The created file contains no data. So we have to fill it with data now.

%% Adding a Signal Entry to a Unisens File
% A random signal should be stored in a signal entry. So we provide a
% struct containing all data.

signalentry.fileFormat = 'bin'; 
signalentry.entryId = 'test-entry'; 
signalentry.adcResolution = 16; 
signalentry.adcZero = 32768;
signalentry.sampleRate = 250;
signalentry.lsbValue = 0.0001;
signalentry.unit = 'mV';
signalentry.entryComment = 'generated test data';
signalentry.contentClass = 'TEST';
signalentry.channelNames = {'I', 'II', 'III'};
signalentry.dataType = 'int32';
signalentry.data = int32(floor(2^16 * rand(3, 1000)));

% Now we add it to our Unisens file:
unisens_utility_add_signalentry([unisens.path, filesep, unisens.name], signalentry);

% You need help? Type
help unisens_utility_add_signalentry
% Most of the Unisens functions have an English help.

%% Adding an Event Entry to a Unisens File
% Besides the signal entry we will store some event information to the
% Unisens file. We need a struct with event information first.

evententry.fileFormat = 'csv';
evententry.entryId = signalentry.entryId;
evententry.contentClass = 'TRIGGER';
evententry.sampleRate = 200;
evententry.typeLength = 1;
evententry.commentLength = 0;
evententry.entryComment = 'generated test list';
evententry.data.samplestamp = zeros(1, 10);
evententry.data.type = cell(1, 10);
evententry.data.comment = cell(1, 10);
for(i = 1:10)
    evententry.data.samplestamp(i) = 20 * i + 10;
    evententry.data.type(i) =  {'N'};
    evententry.data.comment(i) = {''};
end

% After generating the data, we save it.
unisens_utility_add_evententry([unisens.path, filesep, unisens.name], evententry);

%% Plotting the Data
% Okay, now we have a nice Unisens file with generated data - but we don't
% now the data. A first overview (more precisely the first 20 seconds) is
% given by the function unisens_plot.

unisens_plot([unisens.path, filesep, unisens.name]);

%% Getting File Information
% If you want to read informations from a Unisens file, try
% |unisens_get_entry_info|. You can run this function without parameters, too. 

unisens_get_entry_info([unisens.path, filesep, unisens.name], [signalentry.entryId, '.', signalentry.fileFormat]);


%% Reading Data from a File
% For reading data try |unisens_get_data|. It will promp for more
% information, so it can't be shown here. Only the help text:

help unisens_get_data

%% Unisens Toolbox
% All functions in the Unisens toolbox are listed here:

help unisens
