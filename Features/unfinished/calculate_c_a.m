function [c_a] = calculate_c_a(inputArg1,inputArg2)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% c_a               ...     amplitude of c wave of the second derivative of 
%                           a PPG beat over the amplitude of the a wave

%% exceptions
if(any(isnan(PPGmod)))
    b_a = NaN;
    return
end

%% calculate b over a
second_deriv = deriv2(PPGmod);
a = max(second_deriv); % find a
b = min(second_deriv); % find b
b_a = b/a; % calculate b over a

%% verification
% b should come after a
t = 0:1/freq:(length(second_deriv)-1);
t_a = t(second_deriv==a);
t_a = t_a(1);
t_b = t(second_deriv==b);
t_b = t_b(1);
if(t_a > t_b)
    b_a = NaN;
end

end