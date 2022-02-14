function attributes = unisens_utility_get_customAttributes(path)
%UNISENS_UTILITY_ADD_CUSTOMATTRIBUTE creates new custom attribute in Unisens file
%   UNISENS_UTILITY_ADD_CUSTOMATTRIBUTE(PATH, UNISENS) adds a new attribute to an 
%   existing unisens file in PATH. UNISENS is a struct: 
%   path
%
%   2016-06-02 Martin Schmidt


j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

attributes = j_unisens.getCustomAttributes();

keys = attributes.keySet.toArray.cell;
values = attributes.values.toArray.cell;

attributes = [keys, values];
