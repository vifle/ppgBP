function unisens_utility_create(unisens)
%UNISENS_UTILITY_CREATE creates Unisens file
%   UNISENS_UTILITY_CREATE(UNISENS) creates a new unisens file. UNISENS is
%   a struct with the following structure:
%   unisens.path
%   unisens.name (optional)
%   unisens.measurementId
%   unisens.timestampStart
%   unisens.comment
%
%   If unisens.name is empty, the file will be created in unisens.path. 
%   Otherwise a folder unisens.name is created in unisens.path.
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering (ESS)
%                       Malte Kirst (kirst@fzi.de)

%   2007-11-26  working with revision 390 and Matlab 7.0
%   2008-02-05  working with revision 534 and Matlab 7.5
%   2008-06-27  updates for new repository, rev21
%   2010-04-15  setVersion deleted (deprecated)
%   2010-04-22  XMLNS workaround established

% create directory if nessecary 
if(~isempty(unisens.name))
    if (unisens.path(end) ~= filesep)
        unisens.path = [unisens.path, filesep];
    end
    mkdir(unisens.path, unisens.name);
    unisens.path = [unisens.path, filesep, unisens.name];
end

% create new unisens file
j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(unisens.path);

% add information to unisens object
j_unisens.setTimestampStart(unisens.timestampStart);
j_unisens.setMeasurementId(unisens.measurementId);
j_unisens.setComment(unisens.comment);

% save unisens object
j_unisens.save();
j_unisens.closeAll();

% This is a workaround for the XMLNS problem: Read the XML file, add the
% xmlns attribute when necessary and save the file.
xmlDoc = xmlread([unisens.path, filesep, 'unisens.xml']);
xmlDoc.getDocumentElement;
if (isempty(xmlDoc.getDocumentElement.getAttributes.getNamedItem('xmlns')))
    xmlDoc.getDocumentElement.setAttribute('xmlns', 'http://www.unisens.org/unisens2.0');
    xmlwrite([unisens.path, filesep, 'unisens.xml'], xmlDoc)
end


