function unisens_utility_remove_valuesentry(path, entryID)
%   author: Martin Schmidt
%   version: 2015-02-10

%% create or open dataset and add entry
j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

j_unisens.deleteEntry(j_unisens.getEntry(entryID));

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