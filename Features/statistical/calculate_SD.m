function [SD] = calculate_SD(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% SD                ...     standard deviation of PPGbeat

%% exceptions
if(any(isnan(PPGbeat)))
    SD = NaN;
    return
end

%% calculate standard deviation
SD = std(PPGbeat);

end