function [ ind ] = pqe_beatDetection_lazaro( ppg, fs, DEBUG )
% PQE_BEATDETECTION_LAZARO detects beats in a ppg signal based on an adaptive
% threshold similar to Lazaro2014
% [ ind ] = beatDetection_lazaro( ppg, fs, DEBUG )
%
%
%
% Lázaro, J., Gil, E., Vergara, J. M., & Laguna, P. (2014). Pulse rate
%   variability analysis for discrimination of sleep-apnea-related
%   decreases in the amplitude fluctuations of pulse photoplethysmographic
%   signal in children. IEEE Journal of Biomedical and Health Informatics,
%   18(1), 240–246. http://doi.org/10.1109/JBHI.2013.2267096
if nargin < 3
    DEBUG = false;
end

fir_order = round(fs/3);
df = smooth_diff(fir_order);
delay = round(mean(grpdelay(df)));

deriv = filter(-df,1,[ppg zeros(1,delay)]);
deriv = deriv(delay+1:end);

%% Detections in smoothdiff
[slope,ind] = findpeaks(deriv,'MinPeakDistance',round(fs*60/200));

%% Create adaptive threshold
thres = median(slope)*0.3 * ones(1,numel(ppg)); % base threshold for first detection
medianRR_samples = round(median(diff( ind(slope>thres(ind)) )));
nBeatExpect = round(medianRR_samples * 0.7); % to find extra systoles with shorter RR time
nRefrac = round(0.15*fs);
% Loop through all detections
for i = 1:numel(ind)
    if slope(i) >= thres(ind(i))
        if ind(i)+nRefrac < numel(ppg)
            thres(ind(i):ind(i)+nRefrac) = slope(i);
            
            if ind(i) + nRefrac + nBeatExpect < numel(ppg)
                thres(ind(i)+nRefrac+1 : ind(i) + nRefrac + nBeatExpect ) = slope(i) - (1:nBeatExpect).*(slope(i)*0.8/nBeatExpect);
                thres(ind(i) + nRefrac + nBeatExpect : end ) = slope(i)*0.2;
            else
                thres(ind(i):end) = slope(i);
            end
        else
            thres(ind(i):end) = slope(i);
        end
    end    
end

ind(slope < thres(ind)) = [];

%% Remove detections at start and end of signal (incomplete beats)
if(0)%holds only for data of 10s!!!
ind(ind < 0.1*fs) = [];
ind(ind > fs*10 - 0.25*fs) = [];
end

if DEBUG
    figure;
    subplot(2,1,1);
    x = 0:1/fs:10-1/fs;
    plot(x,ppg);
    hold on
    plot(x(ind),ppg(ind),'*r');
    
    subplot(2,1,2);
    plot(x,deriv);
    hold on
    plot(x(ind),deriv(ind),'*r');
    plot(x,thres,':k');
end

end