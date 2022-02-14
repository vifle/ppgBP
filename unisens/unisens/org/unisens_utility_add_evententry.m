function unisens_utility_add_evententry(path, unisens)
%UNISENS_UTILITY_ADD_EVENTENTRY creates new event entry in Unisens file
%   UNISENS_UTILITY_ADD_EVENTENTRY(PATH, UNISENS) adds a new entry to an 
%   existing unisens file in PATH. UNISENS is a struct: 
%   unisens.fileFormat
%   unisens.entryId
%   unisens.contentClass
%   unisens.sampleRate
%   unisens.typeLength (only for BIN files)
%   unisens.commentLength (only for BIN files)
%   unisens.entryComment 
%   unisens.data (as ArrayList or struct)
%
%   optional:
%   unisens.source (optional)
%   unisens.sourceId (optional)
%   unisens.separator (only for CSV files)
%   unisens.decimalSeparator (only for CSV files)
%
%   See also unisens_utility_add_signalentry

%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2007-11-26  file established for Unisens 2.0   
%   2008-02-05  working with revision 534 and Matlab 7.5
%   2008-06-27  updates for new repository, rev21
%   2010-04-22  support for different file formats
%   2010-04-26  support for tabulator separated values for CSV file format
%   2010-04-27  optional attributes included


j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

% file extension check
entryId = unisens_utility_file_extension_check(unisens.entryId, unisens.fileFormat);

j_entry = j_unisens.createEventEntry(entryId, unisens.sampleRate);

j_entry.setComment(unisens.entryComment);
j_entry.setContentClass(unisens.contentClass);

% Optional attributes
if (isfield(unisens, 'sourceId') == 1)
    j_entry.setSourceId(unisens.sourceId);
end
if (isfield(unisens, 'source') == 1)
    j_entry.setSource(unisens.source);
end

if (~isempty(unisens.data))
    % Convert data to ArrayList, when necessary
    if (~isa(unisens.data, 'java.util.ArrayList'))
        tmpData = java.util.ArrayList();
        for (i = 1:length(unisens.data.samplestamp))
            tmpData.add(org.unisens.Event(unisens.data.samplestamp(i), unisens.data.type{i}, unisens.data.comment{i}));
        end
        unisens.data = tmpData;
    end


    % Write BIN data
    if (strcmpi(unisens.fileFormat, 'bin'))
        j_fileFormat = org.unisens.ri.BinFileFormatImpl();
        j_entry.setTypeLength(unisens.typeLength);
        j_entry.setCommentLength(unisens.commentLength);
        j_entry.setFileFormat(j_fileFormat);
        j_entry.append(unisens.data);
        
    % Write CSV data
    elseif (strcmpi(unisens.fileFormat, 'csv'));
        j_fileFormat = org.unisens.ri.CsvFileFormatImpl();
        isfield(unisens, 'separator');
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
        j_entry.setTypeLength(unisens.typeLength);
        j_entry.append(unisens.data);
        
    % Write XML data
    elseif (strcmpi(unisens.fileFormat, 'xml'));
        j_fileFormat = org.unisens.ri.XmlFileFormatImpl();
        j_entry.setFileFormat(j_fileFormat);
        j_entry.append(unisens.data);
        
    else
        fprintf('Unknown file format: %s\n', unisens.fileFormat);
    end
end

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