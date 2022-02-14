function unisens_utility_add_signalentry(path, unisens)
%UNISENS_UTILITY_ADD_SIGNALENTRY creates new signalEntry in Unisens file
%   UNISENS_UTILITY_ADD_ENTRY(PATH, UNISENS) adds a new entry to an 
%   existing unisens file in PATH. UNISENS is a struct:
%   unisens.fileFormat
%   unisens.entryId
%   unisens.adcResolution
%   unisens.adcZero
%   unisens.sampleRate
%   unisens.lsbValue
%   unisens.unit
%   unisens.entryComment
%   unisens.contentClass
%   unisens.channelNames
%   unisens.dataType
%   unisens.data
%
%   optional:
%   unisens.baseline
%   unisens.source
%   unisens.sourceId
%   unisens.separator (only for CSV files)
%   unisens.decimalSeparator (only for CSV files)
%
%   See also unisens_utility_add_evententry
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)
%                       Kristina Schaaff (schaaff@fzi.de)

%   Change Log         
%   2007-11-26  file established for Unisens 2.0   
%   2008-02-05  working with revision 534 and Matlab 7.5
%   2008-03-13  Beautify
%   2008-06-27  updates for new repository, rev21
%   2010-04-09  fwrite instead of append
%   2010-04-22  changes for fileFormat 'csv' and 'xml'
%               file extension check
%   2010-04-26  support for tabulator seperated values for CSV file format
%	2011-12-20	Bugfix: Use matlab build-in write function instead of Java library

j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

% file extension check
entryId = unisens_utility_file_extension_check(unisens.entryId, unisens.fileFormat);

% Check dataType
if (isstr(unisens.dataType))
    unisens.dataType = org.unisens.DataType.fromValue(lower(unisens.dataType));
end

% Create entry
j_entry = j_unisens.createSignalEntry(...
    entryId, unisens.channelNames, ...
    unisens.dataType, unisens.sampleRate);

% Required attributes
j_entry.setAdcResolution(unisens.adcResolution); 
j_entry.setAdcZero(unisens.adcZero);
j_entry.setLsbValue(unisens.lsbValue);
j_entry.setUnit(unisens.unit);
j_entry.setSampleRate(unisens.sampleRate);
j_entry.setComment(unisens.entryComment);
j_entry.setContentClass(unisens.contentClass);
j_entry.setDataType(unisens.dataType);

% Optional attributes
if (isfield(unisens, 'sourceId') == 1)
    j_entry.setSourceId(unisens.sourceId);
end
if (isfield(unisens, 'source') == 1)
    j_entry.setSource(unisens.source);
end
if (isfield(unisens, 'baseline') == 1)
    j_entry.setBaseline(unisens.baseline);
end


if (~isempty(unisens.data))
    % Write BIN data
    if (strcmpi(unisens.fileFormat, 'bin'))
        %j_entry.append(unisens.data);
        % Do not use the Java method append() due to performance reasons (speed, memory)    
        h = fopen([path '\' entryId], 'a');
        fwrite(h, unisens.data, lower(char(unisens.dataType)));
        fclose(h);

    % Write CSV data
    elseif (strcmpi(unisens.fileFormat, 'csv'));
        j_fileFormat = org.unisens.ri.CsvFileFormatImpl();
        if (isfield(unisens, 'separator') ~= 1)
            unisens.separator = ';';
        elseif (strcmpi(unisens.separator, '\t'))
            % \t is the commen abbrevation for tabulator (ASCII 0x09), but
            % Matlab cannot pass this value to the Java library. SPRINTF
            % converts the string '\t' to ASCII 0x09.
            unisens.separator = sprintf('\t');
        end
        if (isfield(unisens, 'decimalSeparator') ~= 1)
            unisens.decimalSeparator = '.';
        end
        j_fileFormat.setSeparator(unisens.separator);
        j_fileFormat.setDecimalSeparator(unisens.decimalSeparator);
        j_entry.setFileFormat(j_fileFormat);
        % Do not use the Java method append() due to performance reasons (speed, memory)    
        dlmwrite([path '\' entryId], unisens.data, unisens.separator);
    
    % Write XML data
    elseif (strcmpi(unisens.fileFormat, 'xml'));
        j_fileFormat = org.unisens.ri.XmlFileFormatImpl();
        j_entry.setFileFormat(j_fileFormat);
        j_entry.append(unisens.data);
    else
        fprintf('Unknown file format: %s\n', unisens.fileFormat);
    end
end

% Save and close dataset
j_unisens.save();
j_unisens.closeAll();


% This is a workaround for the XMLNS problem: Read the XML file, add the
% xmlns attribute when necessary and save the file.
xmlDoc = xmlread([path, filesep, 'unisens.xml']);
xmlDoc.getDocumentElement;
if (isempty(xmlDoc.getDocumentElement.getAttributes.getNamedItem('xmlns')))
    xmlDoc.getDocumentElement.setAttribute('xmlns', 'http://www.unisens.org/unisens2.0');
    xmlwrite([path, filesep, 'unisens.xml'], xmlDoc)
end