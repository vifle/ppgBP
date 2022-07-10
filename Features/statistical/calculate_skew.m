function [skew] = calculate_skew(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% skew              ...     sample skewness of PPGbeat

%% exceptions
if(any(isnan(PPGmod)))
    skew = NaN;
    return
end

%% calculate skew
skew = skewness(PPGbeat);

end