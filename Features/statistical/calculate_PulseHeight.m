function [PulseHeight] = calculate_PulseHeight(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% PulseHeight       ...     height of PPGbeat in a.u.

%% exceptions
if(any(isnan(PPGbeat)))
    PulseHeight = NaN;
    return
end

%% calculate pulse width
PulseHeight = max(PPGbeat) - min(PPGbeat);

end