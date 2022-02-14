function varargout = unisens_version(varargin)
%UNISENS_VERSION returns the current Unisens version number
%   VERSION = UNISENS_VERSION('library') returns the current version of the 
%   Unisens library
%   VERSION = UNISENS_VERSION('matlab') displays the current version of the 
%   Matlab toolbox
%   VERSION = UNISENS_VERSION('java') displays the current version of Java
%   NAME = UNISENS_VERSION('toolbox') displays the name of the installed
%   Unisens toolbox
%
%   When used with without left-hand argument, as in 
%   UNISENS_VERSION(...), the current version numbers will be displayed

%   Copyright 2007-2010 FZI Forschungszentrum Informatik Karlsruhe,
%                       Embedded Systems and Sensors Engineering
%                       Malte Kirst (kirst@fzi.de)

%   2010-02-26  file established
%   2010-04-15  variable output arguments
%   2010-05-21  variable input arguments


% default input argument is 'library'
if (nargin ~= 1)
    varargin = cell({'library'});
end


% get the different version numbers
try
    libraryVersion = char(org.unisens.ri.Version.getVersion());
catch
    libraryVersion = '';
end
matlabVersion = '1272';
javaVersion = char(version('-java'));
toolboxName = 'unisenstoolbox_rev1272.zip';
   
% build the return value or display result
if (nargout == 1)
    switch lower(varargin{1})
        case 'library'
            varargout{1} = libraryVersion;
        case 'matlab'
            varargout{1} = matlabVersion;
        case 'java'
            varargout{1} = javaVersion;
        case 'toolbox'
            varargout{1} = toolboxName;
        otherwise
            error('Invalid option passed to ''unisens_version'' command');
    end
else
    disp(' ');
    disp(['  This is Unisens Reference Implementation Version ', libraryVersion]);
    disp(['  This is Unisens Toolbox Version ', matlabVersion]);
    disp(['  This is Java Version ', javaVersion]);
    disp('  For more information, visit http://www.unisens.org');
    disp(' ');
end

