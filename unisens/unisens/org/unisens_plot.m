function unisens_plot(path)
%UNISENS_PLOT plots first 20s of all signal entries
%   UNISENS_PLOT(PATH) plots first 20s of all signal entries found in
%   Unisens 2.0 file in PATH
%
%   UNISENS_PLOT() opens a directory chooser dialog 
%
%   See also unisens_plot_entry
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2007-11-26  file established for Unisens 2.0   
%   2007-12-06  file established for Unisens 2.0, rev409   
%   2008-06-27  updates for new repository, rev21
%   2008-07-03  bugfixes

if (nargin >= 1)
    path = unisens_utility_path(path);
else
    path = unisens_utility_path();
end

j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

j_entries = j_unisens.getEntries();
nEntries = j_entries.size();


nSubplots = 0;
for ( i = 0:nEntries-1)
    if (strcmp(j_entries.get(i).getClass.toString, 'class org.unisens.ri.SignalEntryImpl'))
        nSubplots = nSubplots + 1;
    end
end

figure;
j = 0;
for ( i = 0:nEntries-1)
    j_entry = j_entries.get(i);
    
    if (~strcmp(j_entry.getClass.toString, 'class org.unisens.ri.SignalEntryImpl'))
        continue;
    end
    
    j = j + 1;
    subplot(nSubplots, 1, j);
    sampleRate = j_entry.getSampleRate;
    plot(j_entry.read(sampleRate * 20));
    title([char(j_entry.getContentClass), ': ', char(j_entry.getComment), ' (', num2str(sampleRate), 'Hz)']);
    
    set(gca, 'XTick', 0:sampleRate:sampleRate*20)
    set(gca, 'XTickLabel', 0:20);
    xlabel('time / s');
    
%     LSB = j_entry.getLsbValue()
%     Unist = j_entry.getUnit()
    
%     yTickLabel = get(gca, 'YTick');
%     set(gca, 'YTick', yTickLabel);
%     set(gca, 'YTickLabel', yTickLabel * j_entry.getLsbvalue);
%     ylabel([char(j_entry.getClass_), ' / ', char(j_entry.getUnit)]);
end
