function [RI_area] = calculate_RI_area(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% RI_area           ...     area of diastolic wave(s) over area of systolic
%                           waves

%% exceptions
% GammaGauss4
if(strcmp(algorithmName,'GammaGauss4'))
    RI_area = NaN;
    return
end

% opt_params is NaN
if(isnan(opt_params))
    RI_area = NaN;
    return
end

%% calculate area ratio of systolic and diastolic component
numKernels = length(opt_params)/3; % get number of kernels
switch numKernels
    case 0
        errordlg('Number of kernels is 0. No calculation of area ratio possible','Input Error','modal');
        return
    case 1
        errordlg('Number of kernels is 1. No calculation of area ratio possible','Input Error','modal');
        return
    case 2
        curve_sys = y{1};
        A_sys = trapz(curve_sys);
        curve_dia = y{2};
        A_dia = trapz(curve_dia);
    case 3
        curve_sys = y{1};
        A_sys = trapz(curve_sys);
        curve_dia = sum([y{2};y{3}]);
        A_dia = trapz(curve_dia);
    case 4
        curve_sys = y{1};
        A_sys = trapz(curve_sys);
        curve_dia = sum([y{2};y{3};y{4}]);
        A_dia = trapz(curve_dia);
    case 5
        curve_sys = sum([y{1};y{2}]);
        A_sys = trapz(curve_sys);
        curve_dia = sum([y{3};y{4};y{5}]);
        A_dia = trapz(curve_dia);
    otherwise
        error('Number of kernels exceeds 5.');
end
RI_area = A_dia/A_sys;

end