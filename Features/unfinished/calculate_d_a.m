function [d_a] = calculate_d_a(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% d_a               ...     amplitude of d wave of the second derivative of 
%                           a PPG beat over the amplitude of the a wave

%% exceptions
if(any(isnan(PPGmod)))
    d_a = NaN;
    return
end

%% calculate b over a
second_deriv = deriv2(PPGmod);
a = max(second_deriv); % find a
d = min(second_deriv); % find d
d_a = d/a; % calculate d over a

%% verification
% d should come after a
t = 0:1/freq:(length(second_deriv)-1);
t_a = t(second_deriv==a);
t_a = t_a(1);
t_d = t(second_deriv==d); % this only works if i really search for the absolute minimum, for d this does not work
t_d = t_d(1);
if(t_a > t_d)
    d_a = NaN;
end

end