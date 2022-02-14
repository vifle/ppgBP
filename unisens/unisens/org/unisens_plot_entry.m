function unisens_plot_entry(path)
%UNISENS_PLOT_ENTRY plots an entry
%   UNISENS_PLOT_ENTRY(PATH) plots one entry choosen by entry chooser from
%   a Unisens 2.0 file in PATH
%
%   UNISENS_PLOT_ENTRY() opens a directory chooser dialog 
%
%   See also unisens_plot
%
%   Copyright 2008-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2008-09-22  file established 
%   2010-05-04  legend added

if (nargin >= 1)
    path = unisens_utility_path(path);
else
    path = unisens_utility_path();
end

j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);
disp(['Comment: ', char(j_unisens.getComment())]);

entryId = unisens_utility_entry_chooser(j_unisens);


figure;
nSubplots = length(entryId)
for i = 1:nSubplots
    subplot(nSubplots, 1, i);
    j_entry = j_unisens.getEntry(entryId{i});
    if (~strcmp(j_entry.getClass.toString, 'class org.unisens.ri.SignalEntryImpl'))
        return;
    end

    sampleRate = j_entry.getSampleRate;
    data = unisens_get_data(path, entryId);
    plot(data);
%    plot(j_entry.read(j_entry.getCount()));
    xlim([1 j_entry.getCount()]);
    
    title([char(j_entry.getContentClass), ': ', char(j_entry.getComment)]);
    
    % channel names as legend
    legend(char(j_entry.getChannelNames()));

    % set(gca, 'XTick', 0:sampleRate:j_entry.getCount())
    % set(gca, 'XTickLabel', 0:20);
    xlabel(['time / samples', ' (', num2str(sampleRate), 'Hz)']);
    % ylabel(['LSB = ', num2str(j_entry.getLsbValue()), j_entry.getUnit()]);
    ylabel(['LSB = ', num2str(j_entry.getLsbValue()), char(j_entry.getUnit())]);
end
j_unisens.closeAll();

