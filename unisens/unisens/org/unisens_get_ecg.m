function rs = unisens_get_ecg(path)
%UNISENS_GET_ECG    loads ecg
%   UNISENS_GET_ECG()
%   UNISENS_GET_ECG(PATH) loads ecg data from PATH. If there is more than 
%   one ECG entry, the entry has to be chosen.
%
%   This function is deprecated. Use UNISENS_GET_DATA instead.
%
%   See also unisens_get_data
%
%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)
%                       Julius Neuffer (neuffer@fzi.de)

%   Change Log         
%   2007-12-06  file established for Unisens 2.0, rev409   
%   2008-02-05  working with revision 534 and Matlab 7.5
%   2010-03-31  uses unisens_get_data to do the trick
%   2010-04-21  deprecated

if (nargin == 0)
    path = '';
end

rs = unisens_get_data(path, 'ECG');

end