function [T_sys_dia] = calculate_T_sys_diaMode(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% T_sys_diaMode     ...     time difference between systolic component and
%                           diastolic component (based on mode)

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
timeAxis = 0:1/freq:(length(PPGbeat)-1)/freq; % create time vector
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of time difference possible','Input Error','modal');
        return
    case 1
        errordlg('Number of kernels is 1. No calculation of time difference possible','Input Error','modal');
        return
    case 2
        T_sys = timeAxis(y{1}==max(y{1}));
        T_sys = T_sys(1);
        mode2 = timeAxis(y{2}==max(y{2}));
        T_dia = mode2(1);
    case 3
        T_sys = timeAxis(y{1}==max(y{1}));
        T_sys = T_sys(1);
        mode2 = timeAxis(y{2}==max(y{2}));
        mode2 = mode2(1);
        mode3 = timeAxis(y{3}==max(y{3}));
        mode3 = mode3(1);
        T_dia = ((max(y{2})*mode2)+(max(y{3})*mode3))/(max(y{2})+max(y{3}));
    case 4
        T_sys = timeAxis(y{1}==max(y{1}));
        T_sys = T_sys(1);
        mode2 = timeAxis(y{2}==max(y{2}));
        mode2 = mode2(1);
        mode3 = timeAxis(y{3}==max(y{3}));
        mode3 = mode3(1);
        mode4 = timeAxis(y{4}==max(y{4}));
        mode4 = mode4(1);
        T_dia = ((max(y{2})*mode2)+(max(y{3})*mode3)+(max(y{4})*mode4))/...
            (max(y{2})+max(y{3})+max(y{4}));
    case 5
        T_sys = timeAxis(y{1}==max(y{1}));
        T_sys = T_sys(1);
        mode2 = timeAxis(y{2}==max(y{2}));
        mode2 = mode2(1);
        mode3 = timeAxis(y{3}==max(y{3}));
        mode3 = mode3(1);
        mode4 = timeAxis(y{4}==max(y{4}));
        mode4 = mode4(1);
        mode5 = timeAxis(y{5}==max(y{5}));
        mode5 = mode5(1);
        T_dia = ((max(y{2})*mode2)+(max(y{3})*mode3)+(max(y{4})*mode4)+(max(y{5})*mode5))/...
            (max(y{2})+max(y{3})+max(y{4})+max(y{5}));
    otherwise
        error('Number of kernels exceeds 5.');
end
T_sys_dia = T_dia - T_sys;

end