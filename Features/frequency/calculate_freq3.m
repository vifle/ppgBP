function [freq3] = calculate_freq3(PPGmod,PPGbeat,y,opt_params,algorithmName,freq)
% input:
% PPGmod            ...     PPG beat modeled by kernels
% PPGbeat           ...     beat of PPG signal that is to be decomposed
% y                 ...     shapes of kernels based on optimized parameters
% opt_params        ...     optimized parameters of the kernels
% algorithmName     ...     algorithm that was used for the decomposition
% freq              ...     sampling frequency of input signal
%
% outputs:
% freq3             ...     second harmonic of PPGbeat

%% exceptions
if(any(isnan(PPGmod)))
    freq3 = NaN;
    return
end

%% calculate second harmonic
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
freq3 = f(locs(3));

end