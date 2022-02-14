function [AmpCatacrot] = calculate_AmpCatacrot(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% AmpCatacrot       ...     amplitude of peak of PPG in catacrotic phase

%% exceptions
% PPGbeat contains NaN
if(any(isnan(PPGbeat)))
    AmpCatacrot = NaN;
    return
end

%% calculate amplitude of peak in anacrotic phase
% use find peaks to find two peaks?
% use some derivative?

end