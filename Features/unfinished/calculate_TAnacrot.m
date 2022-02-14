function [TAnacrot] = calculate_TAnacrot(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% TAnacrot          ...     point in time of peak in anacrotic phase

%% exceptions
% PPGbeat contains NaN
if(any(isnan(PPGbeat)))
    TAnacrot = NaN;
    return
end

%% calculate TAnacrot
t = 0:1/freq:(length(PPGbeat)-1); % create time axis
TAnacrot = t(PPGbeat==max(PPGbeat)); % find maximum
TAnacrot = TAnacrot(1); % ensure first maximum is selected if there are multiples

end