function [T1] = calculate_T1(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% T1                ...     instant of time of first kernel (based on mean)

%% exceptions
% GammaGauss4
if(strcmp(algorithmName,'GammaGauss4'))
    T1 = NaN;
    return
end

% opt_params is NaN
if(isnan(opt_params))
    T1 = NaN;
    return
end

%% calculate time between systolic and diastolic component
numKernels = length(opt_params)/3; % get number of kernels
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of T1 possible','Input Error','modal');
        return
    otherwise
        T1 = opt_params(2);
end

end