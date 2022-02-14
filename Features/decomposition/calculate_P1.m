function [P1] = calculate_P1(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% P1                ...     amplitude of first kernel

%% exceptions
% opt_params is NaN
if(isnan(opt_params))
    P1 = NaN;
    return
end

%% calculate amplitude of first kernel
numKernels = length(opt_params)/3; % get number of kernels
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of P1 possible','Input Error','modal');
        return
    otherwise
        P1 = max(y{1});
end

end