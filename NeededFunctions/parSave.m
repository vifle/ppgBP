% Wrapper function for save for use in parfor loops
% Based on http://www.mathworks.com/matlabcentral/answers/135285#answer_149537
% Handles save options such as -append
%
% Test Example 1
% a = 10;
% b = 'blah';
% c.test = 1;
% d = {'a'};
% e = [100 100];
% parSave('test.mat', a, b , c, d, e, '-v7.3')
%
% Test Example 2
% f = 500;
% parSave('test.mat', f, '-append')
%
% Test Example 3
%
% parfor k = 1:3,
%     parSave(sprintf('test%d.mat', k), a, b , c, d, e, '-v7.3')
% end
function parSave(varargin)

filename = varargin{1};
opts = {};

for ind = 2:length(varargin)
    curVarName = inputname(ind);
    % Handle save options such as -append, -v7.3, etc
    if strcmp(curVarName, '')
        opts{length(opts) + 1} = varargin{ind};
    else
        varNames.(curVarName) = varargin{ind};
    end
end

if ~isempty(opts)
    save(filename, '-struct', 'varNames', opts{:})
else
    save(filename, '-struct', 'varNames')
end

end