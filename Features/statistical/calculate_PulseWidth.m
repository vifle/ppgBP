function [PulseWidth] = calculate_PulseWidth(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% PulseWidth        ...     width of PPGbeat in s

%% exceptions
if(any(isnan(PPGbeat)))
    PulseWidth = NaN;
    return
end

%% calculate pulse width
t = 0:1/freq:(length(PPGbeat)-1)/freq;
PulseWidth = t(end);

end