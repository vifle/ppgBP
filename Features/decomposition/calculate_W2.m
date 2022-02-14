function [W2] = calculate_W2(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% W2                ...     width of second kernel

%% exceptions
% GammaGauss4
if(strcmp(algorithmName,'GammaGauss4'))
    W2 = NaN;
    return
end

% opt_params is NaN
if(isnan(opt_params))
    W2 = NaN;
    return
end

%% calculate width of second kernel
numKernels = length(opt_params)/3; % get number of kernels
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of W2 possible','Input Error','modal');
        return
    case 1
        errordlg('Number of kernels is 1. No calculation of W2 possible','Input Error','modal');
        return
    otherwise
        W2 = opt_params(6);
end

end