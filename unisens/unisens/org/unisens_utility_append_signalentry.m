function unisens_utility_append_signalentry(path, unisens)
%UNISENS_UTILITY_APPEND_SIGNALENTRY appends data to an existing entry
%   UNISENS_UTILITY_APPEND_SIGNALENTRY(PATH, UNISENS) appends data to an 
%   exsiting entry in an existing unisens file in PATH. UNISENS is
%   a struct 
%
%   See also unisens_utility_add_signalentry
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   Change Log         
%   2007-12-04  file established for Unisens 2.0   


j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens = j_unisensFactory.createUnisens(path);

% file extension check
entryId = unisens_utility_file_extension_check(unisens.entryId, unisens.fileFormat);



j_entry = j_unisens.getEntry(entryId);
j_entry.append(unisens.data);
j_unisens.closeAll();
