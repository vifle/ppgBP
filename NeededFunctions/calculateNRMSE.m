function [nrmse,reconstructedSignal,kernels,opt_vals] = calculateNRMSE(inputSignal,referenceSignal,freq,varargin)
% input:
% inputSignal           ...     signal that is to be decomposed
% referenceSignal       ...     signal that serves as a reference for NRMSE
%                               calculation
% freq                  ...     sampling frequency
% algorithmName         ...     name of the algorithm that is used for the
%                               decomposition
% varargin              ...     optional arguments for decomposition
%
% outputs:
% nrmse                 ...     normalized root mean square error of
%                               reconstructed signal vs reference signal
% reconstructedSignal   ...     sum of kernels
% kernels               ...     optimized basis functions that result from
%                               the decomposition
% opt_vals              ...     optimized parameters of the basis functions


%% call decomposition function

% TODO: add checking of varargin (should be same as decomposition
% algorithm)

% get input and reference to 1 x n array
if(size(inputSignal,1)>size(inputSignal,2))
    inputSignal = inputSignal';
end
if(size(referenceSignal,1)>size(referenceSignal,2))
    referenceSignal = referenceSignal';
end

if(~isempty(varargin))
    [reconstructedSignal,kernels,opt_vals] = decompositionAlgorithm(inputSignal,freq,varargin{:});
    entry = find(ismember('normalizeOutput',varargin(:,1)));
    if(~(isempty(entry)))
        normalizationFlag = varargin{entry,2};
    end
else
    [reconstructedSignal,kernels,opt_vals] = decompositionAlgorithm(inputSignal,freq);
end

% if decomposition is normalized, reference must be normalized
if(normalizationFlag)
    referenceSignal = (referenceSignal - min(referenceSignal))/(max(referenceSignal) - min(referenceSignal));
end

%% calculate second derivatives and NRMSE
deriv_ref = deriv2(referenceSignal);
deriv_rec = deriv2(reconstructedSignal);
RSS_deriv2 = sum((deriv_ref-deriv_rec).^2);
std_deriv2 = sum((deriv_ref-mean(deriv_ref)).^2);
nrmse=1-(sqrt(RSS_deriv2)/sqrt(std_deriv2));

end