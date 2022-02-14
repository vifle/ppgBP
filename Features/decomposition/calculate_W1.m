function [W1] = calculate_W1(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% W1                ...     width of first kernel

%% exceptions
% GammaGauss4
if(strcmp(algorithmName,'GammaGauss4'))
    W1 = NaN;
    return
end

% opt_params is NaN
if(isnan(opt_params))
    W1 = NaN;
    return
end

%% calculate width of first kernel
numKernels = length(opt_params)/3; % get number of kernels
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of W1 possible','Input Error','modal');
        return
    otherwise
        W1 = opt_params(3);
end

end