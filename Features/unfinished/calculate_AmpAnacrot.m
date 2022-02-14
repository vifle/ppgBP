function [AmpAnacrot] = calculate_AmpAnacrot(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% AmpAnacrot        ...     amplitude of peak of PPG in anacrotic phase

%% exceptions
% PPGbeat contains NaN
if(any(isnan(PPGbeat)))
    AmpAnacrot = NaN;
    return
end

%% calculate amplitude of peak in anacrotic phase
AmpAnacrot = max(PPGbeat);

end