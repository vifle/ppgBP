function path = unisens_utility_path(path)
%UNISENS_UTILITY_PATH   checks path
%   UNISENS_UTILITY_PATH(PATH) checks if PATH is a valid Unisens 2.0 path.
%
%   Copyright 2008-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   2008-06-27  updates for new repository, rev21


if (nargin == 0  ||  ~ischar(path))
    path = uigetdir('C:\', 'Select Unisens folder.');
elseif (nargin >= 1)
    path = strrep(path, '\unisens.xml', '');
end

% check if path exists
if (path == 0)
    error('Abort...');
    return;
elseif (~exist(path, 'dir'))
    error(['Path ''', path, ''' does not exist!']);
    path = 0;
    return;
end


% check if unisens file exists
if (~exist([path, '\unisens.xml'], 'file'))
    error(['Path ''', path, ''' is no regular Unisens path!']);
    path = 0;
    return;
end


