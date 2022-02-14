function [freq4] = calculate_freq4(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% freq4             ...     third harmonic of PPGbeat

%% exceptions
if(any(isnan(PPGmod)))
    freq4 = NaN;
    return
end

%% calculate third harmonic
signal = repmat(PPGbeat,[1 10]);                   
L = numel(signal);
Y = fft(signal);
P2 = abs(Y/L);
P1 = P2(1:L/2+1);
P1(2:end-1) = 2*P1(2:end-1);
f = freq*(0:(L/2))/L;
[peaks,locs] = findpeaks(P1);
[~,ind] = maxk(peaks,4);
locs = locs(ind);
freq4 = f(locs(4));

end