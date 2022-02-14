function [kurt] = calculate_kurt(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% kurt              ...     sample kurtosis of PPGbeat

%% exceptions
if(any(isnan(PPGbeat)))
    kurt = NaN;
    return
end

%% calculate kurtosis
kurt = kurtosis(PPGbeat);

end