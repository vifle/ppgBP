function unisens_utility_add_customAttribute(path, key, value)
%UNISENS_UTILITY_ADD_CUSTOMATTRIBUTE creates new custom attribute in Unisens file
%   UNISENS_UTILITY_ADD_CUSTOMATTRIBUTE(PATH, UNISENS) adds a new attribute to an 
%   existing unisens file in PATH. UNISENS is a struct: 
%   key
%   value
%
%   2016-06-02 Martin Schmidt


j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

j_unisens.addCustomAttribute(key,value);

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