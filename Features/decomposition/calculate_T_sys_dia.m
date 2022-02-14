function [T_sys_dia] = calculate_T_sys_dia(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% T_sys_dia         ...     time difference between systolic component and
%                           diastolic component (based on means)

%% exceptions
% GammaGauss4
if(strcmp(algorithmName,'GammaGauss4'))
    T_sys_dia = NaN;
    return
end

% opt_params is NaN
if(isnan(opt_params))
    T_sys_dia = NaN;
    return
end

%% calculate time between systolic and diastolic component
numKernels = length(opt_params)/3; % get number of kernels
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of time difference possible','Input Error','modal');
        return
    case 1
        errordlg('Number of kernels is 1. No calculation of time difference possible','Input Error','modal');
        return
    case 2
        T_sys = opt_params(2);
        T_dia = opt_params(5);
    case 3
        T_sys = opt_params(2);
        T_dia = mean([opt_params(5),opt_params(8)]);
    case 4
        T_sys = opt_params(2);
        T_dia = mean([opt_params(5),opt_params(8),opt_params(11)]);
    case 5
        T_sys = mean([opt_params(2),opt_params(5)]);
        T_dia = mean([opt_params(8),opt_params(11),opt_params(14)]);
    otherwise
        error('Number of kernels exceeds 5.');
end
T_sys_dia = T_dia - T_sys;

end