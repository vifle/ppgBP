function unisens_utility_add_valuesentry(path, unisens)
%UNISENS_UTILITY_ADD_VALUESENTRY creates new values entry in Unisens file
%   UNISENS_UTILITY_ADD_VALUESENTRY(PATH, UNISENS) adds a new entry to an 
%   existing unisens file in PATH. UNISENS is a struct: 
%   
%   unisens.entryId:        ID of the entry (filename)
%   unisens.entryComment:   comment for this entry
%   unisens.contentClass:   data classification
%   unisens.fileFormat:     fileformat to save to (bin, csv or xml)
%   unisens.sampleRate:     (virtual) samplerate
%   unisens.dataType:       datatype of the values
%   unisens.channelNames:   String Array of names for channels
%   unisens.data:           data as an array of Values
%   
%   necessary if datatype isn't FLOAT or DOUBLE:
%   unisens.adcResolution:  bitdepth of the ADC
%   unisens.adcZero:        value of zero
%   unisens.baseline:       baseline of ADC
%   unisens.lsbValue:       value of least significant bit
%
%   optional:
%   unisens.source:         string naming the source of data
%   unisens.sourceId:       string for the ID of the datasource
%   unisens.separator:      (only for CSV files)
%   unisens.decimalSeparator:(only for CSV files)
%   unisens.physicalUnit:   physical unit of represented data
%
%   function adapted from unisens_utility_add_eventsentry r1272
%   
%   author: Enrico Grunitz
%   version: 2012-09-28

%% check arguments
% file extension check
unisens.entryId = unisens_utility_file_extension_check(unisens.entryId, unisens.fileFormat);
% Check dataType
if (ischar(unisens.dataType))
    unisens.dataType = org.unisens.DataType.fromValue(lower(unisens.dataType));
end
% default values for adc properties for double and float datatypes
if(~((unisens.dataType ~= org.unisens.DataType.DOUBLE) && (unisens.dataType ~= org.unisens.DataType.FLOAT)))
    unisens.adcZero = 0;
    unisens.adcResolution = 32;
    unisens.baseline = 0;
    unisens.lsbValue = 1;
end

%% create or open dataset and add entry
j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

j_entry = j_unisens.createValuesEntry(unisens.entryId, ...
                                      unisens.channelNames, ...
                                      unisens.dataType, ...
                                      unisens.sampleRate);
                                  
%% set nonoptional attributes
j_entry.setComment(unisens.entryComment);
j_entry.setContentClass(unisens.contentClass);
j_entry.setSampleRate(unisens.sampleRate);
j_entry.setDataType(unisens.dataType);
j_entry.setChannelNames(unisens.channelNames);
j_entry.setAdcProperties(unisens.adcZero, ...
                         unisens.adcResolution, ...
                         unisens.baseline, ...
                         unisens.lsbValue);

%% set optional attributes
if(isfield(unisens, 'physicalUnit') == true)
    j_entry.setUnit(unisens.physicalUnit);
end
if (isfield(unisens, 'sourceId') == true)
    j_entry.setSourceId(unisens.sourceId);
end
if (isfield(unisens, 'source') == true)
    j_entry.setSource(unisens.source);
end

if (~isempty(unisens.data))
    % Write BIN data
    if (strcmpi(unisens.fileFormat, 'bin'))
        j_entry.setFileFormat(org.unisens.ri.BinFileFormatImpl());
        j_entry.append(unisens.data);
        
    % Write CSV data
    elseif (strcmpi(unisens.fileFormat, 'csv'));
        j_fileFormat = org.unisens.ri.CsvFileFormatImpl();
        if (isfield(unisens, 'separator') ~= true)
            unisens.separator = ';';
        elseif (strcmpi(unisens.separator, '\t'))
            % \t is the commen abbrevation for tabulator (ASCII 0x09), but
            % Matlab cannot pass this value to the Java library. SPRINTF
            % converts the string '\t' to ASCII 0x09.
            unisens.separator = sprintf('\t');
        end
        if (isfield(unisens, 'decimalSeparator') ~= true)
            unisens.decimalSeparator = '.';
        end
        j_fileFormat.setSeparator(unisens.separator);
        j_fileFormat.setDecimalSeparator(unisens.decimalSeparator);
        j_entry.setFileFormat(j_fileFormat);        
        j_entry.append(unisens.data);
        
    % Write XML data
    elseif (strcmpi(unisens.fileFormat, 'xml'));
        j_entry.setFileFormat(org.unisens.ri.XmlFileFormatImpl());
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
end