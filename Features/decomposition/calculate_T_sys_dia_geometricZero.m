function [T_sys_dia_geometricZero] = calculate_T_sys_dia_geometricZero(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                     ...     shapes of kernels based on optimized 
%                               parameters
% opt_params            ...     optimized parameters of the kernels
% algorithmName         ...     algorithm that was used for the 
%                               decomposition
% freq                  ...     sampling frequency of input signal
%
% outputs:
% T_sys_dia_geometric   ...     time difference between systolic component 
%                               and diastolic component (based on centroids
%                               of sums of systolic and diastolic
%                               components)

%% exceptions
% GammaGauss4
if(strcmp(algorithmName,'GammaGauss4'))
    T_sys_dia_geometricZero = NaN;
    return
end

% opt_params is NaN
if(isnan(opt_params))
    T_sys_dia_geometricZero = NaN;
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
        curve_sys = y{1}; % get shape of systolic component
        curve_sys(1) = 0; % force first entry of systolic curve to zero
        curve_sys(end) = 0; % force last entry of systolic curve to zero
        systolicShape = polyshape(timeAxis,curve_sys); % make polygon out of curve
        [T_sys,~] = centroid(systolicShape); % get time for systolic component
        curve_dia = y{2}; % get shape of diastolic component
        curve_dia(1) = 0; % force first entry of diastolic curve to zero
        curve_dia(end) = 0; % force last entry of diastolic curve to zero
        diastolicShape = polyshape(timeAxis,curve_dia); % make polygon out of curve
        [T_dia,~] = centroid(diastolicShape); % get time for systolic component
    case 3
        curve_sys = y{1}; % get shape of systolic component
        curve_sys(1) = 0; % force first entry of systolic curve to zero
        curve_sys(end) = 0; % force last entry of systolic curve to zero
        systolicShape = polyshape(timeAxis,curve_sys); % make polygon out of curve
        [T_sys,~] = centroid(systolicShape); % get time for systolic component
        curve_dia = sum([y{2};y{3}]); % get shape of diastolic component
        curve_dia(1) = 0; % force first entry of diastolic curve to zero
        curve_dia(end) = 0; % force last entry of diastolic curve to zero
        diastolicShape = polyshape(timeAxis,curve_dia); % make polygon out of curve
        [T_dia,~] = centroid(diastolicShape); % get time for systolic component
    case 4
        curve_sys = y{1}; % get shape of systolic component
        curve_sys(1) = 0; % force first entry of systolic curve to zero
        curve_sys(end) = 0; % force last entry of systolic curve to zero
        systolicShape = polyshape(timeAxis,curve_sys); % make polygon out of curve
        [T_sys,~] = centroid(systolicShape); % get time for systolic component
        curve_dia = sum([y{2};y{3};y{4}]); % get shape of diastolic component
        curve_dia(1) = 0; % force first entry of diastolic curve to zero
        curve_dia(end) = 0; % force last entry of diastolic curve to zero
        diastolicShape = polyshape(timeAxis,curve_dia); % make polygon out of curve
        [T_dia,~] = centroid(diastolicShape); % get time for systolic component
    case 5
        curve_sys = sum([y{1};y{2}]); % get shape of systolic component
        curve_sys(1) = 0; % force first entry of systolic curve to zero
        curve_sys(end) = 0; % force last entry of systolic curve to zero
        systolicShape = polyshape(timeAxis,curve_sys); % make polygon out of curve
        [T_sys,~] = centroid(systolicShape); % get time for systolic component
        curve_dia = sum([y{3};y{4};y{5}]); % get shape of diastolic component
        curve_dia(1) = 0; % force first entry of diastolic curve to zero
        curve_dia(end) = 0; % force last entry of diastolic curve to zero
        diastolicShape = polyshape(timeAxis,curve_dia); % make polygon out of curve
        [T_dia,~] = centroid(diastolicShape); % get time for systolic component
    otherwise
        error('Number of kernels exceeds 5.');
end
T_sys_dia_geometricZero = T_dia - T_sys;

end