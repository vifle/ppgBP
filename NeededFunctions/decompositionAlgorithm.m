function [signal_mod,y,opt_val_sort] = decompositionAlgorithm(ppg_signal,freq,varargin)
% decompositionAlgorithm    Uses pulse wave decomposition to retrieve the
%                           basis functions (kernels) from a pulse wave.
%
% REFERENCES: 
% Fleischhauer, V., Ruprecht, N., Sorelli, M., Bocchi, L., & Zaunseder, S. (2020). 
% Pulse decomposition analysis in photoplethysmography imaging. Physiological Measurement, 41(9). 
% https://doi.org/10.1088/1361-6579/abb005
%
% INPUT: 
% 'ppg_signal':     detrended pulse wave (single beat from minimum to 
%                   minimum) that is to be decomposed
%                   if noOpt == true, the resulting beat has the same
%                   length as ppg_signal (n)
%                   type: 1 x n or n x 1 array of doubles
%
% 'freq':           sampling frequency of ppg_signal
%                   type: double
%
% 'varargin':       optional arguments:
%                       'numKernels' - determines the number of kernels 
%                       (default: 2) used to decompose the beat
%                       type: double
%
%                       'kernelTypes' - determines the types of kernels
%                       used for the decomposition. Allowed are the
%                       following types: 'Gamma', 'Gaussian',
%                       'GammaGaussian' (default: 'GammaGaussian')
%                       type: char
%
%                       'method' - determines the method for getting the
%                       initial values. Allowed are the follwing methods:
%                       'generic', 'Sorelli', 'Couceiro'(default = 
%                       'generic')
%                       type: 'char'
%
%                       'normalizeOutput' - determines whether (default = 
%                       true) the output kernels and reconstructed signal
%                       are normalized to the range [0,1] or the output is
%                       not normalized (false)
%                       type: logical
%
%                       'noOpt' - determines whether (default: false) 
%                       optimization is executed or the optimization
%                       is skipped (true)
%                       type: logical
%
%                       'initialValues' - contains initial values for the 
%                       kernels (default: []); if no vector is passed, the 
%                       default initial values for the chosen decomposition 
%                       algorithm are used
%                       type: 1 x (3*numKernels) array of doubles
%
% OUTPUT:
% 'signal_mod':     reconstructed signal (sum of kernels) of length 1xn
%                   type: 1 x n array of doubles
%
% 'y':              contains the numKernels basis functionns, each with a 
%                   size of 1 x n sorted by the occurence of their maxima
%                   type: numKernels x 1 cell array
%
% 'opt_val_sort':   optimized values of parameters that determine the basis
%                   functions
%                   type: 1 x (3*numKernels) array of doubles

%% TODO
% - add possibility to work with non-detrended signal
%   --> check if beat is from zero to zero and assume linear trend and save
%   that trend; make this at least optional?
% - add examples?
% - adapt old testing environment to this new structure
% - improve returning to outer script after error
% - outsource initial values, boundaries and constraints?
% - add missing return statements after errordlg in needed functions
% - possible to omit ppg_signal when noOpt is true?
% - unify snake and camel case
% - delete unnecessary variables
% - test comparison between old Gamma4 and Gamma4 with this function
% - test speed differences between old and new version
% - give a more detailed description in doc string

%% check input arguments
% both signal and sampling frequency are needed
if(nargin<2)
    errordlg('Too few arguments','Input Error','modal');
    return;
elseif(nargin>14)
    errordlg('Too many arguments','Input Error','modal');
    return;
end
% ppg_signal needs to be an array with more than one element
if(~(isvector(ppg_signal) && ~(isscalar(ppg_signal)) && ~(ischar(ppg_signal)) && ~isstring(ppg_signal)))
    errordlg('PPG signal needs to be an array with more than one element',...
        'Input Error','modal');
    return;
end
% freq needs to be a scalar
if(~(isscalar(freq) && ~(ischar(freq)) && ~isstring(freq)))
    errordlg('Sampling frequency needs to be a scalar value',...
        'Input Error','modal');
    return;
end
% turn ppg_signal into 1xn array
if(size(ppg_signal,1)>size(ppg_signal,2))
    ppg_signal = ppg_signal';
end
% check optional arguments
okargs = {'numKernels','kernelTypes','method','normalizeOutput','noOpt',...
    'initialValues'} ; % allowed argument specifiers
numKernels = 2; % number of kernels
kernelTypes = 'GammaGaussian'; % types of kernels
method = 'generic'; % method for initial values
normOut = true; % flag for normalization of input
x0 = []; % initial values
noOpt = false; % optimization flag
i=1;
% rearrange optional arguments (dependent ones last)
oldIndex = find(strcmp(varargin,'initialValues'));
if ~isempty(oldIndex)
    varargin(end+1:end+2) = varargin(oldIndex:oldIndex+1);
    varargin(oldIndex:oldIndex+1) = [];
end
while(1)
    if(mod(size(varargin,2),2)~=0) % check if number of variable arguments is even
        errordlg('Uneven number of optional arguments not supported',...
            'Input Error','modal');
        return;
    end
    
    if(i>size(varargin,2)) % leave while loop if there are no more new variable arguments
        break;
    end
    
    if(ischar(varargin{i})) % evaluate key word of next argument
        if(ismember(varargin{i},okargs))
            actualArgument=varargin{i};
        else
            errordlg(['Specified Option ''' varargin{i} ''' is not a valid option'],...
                'Input Error','modal');
            return;
        end
        
    else
        errordlg(['Argument ' num2str(i+2) ' is not a valid option. A keyword needs to be inserted here.'],...
            'Input Error','modal');
        return;
    end
    
    switch actualArgument % set values for the actual arguments
        case 'initialValues'
            % turn ppg_signal into 1xn array
            if(size(varargin{i+1},1)>size(varargin{i+1},2))
                varargin{i+1} = varargin{i+1}';
            end
            if(~(isvector(varargin{i+1}) && (size(varargin{i+1},2)==numKernels*3)))
                errordlg(['InitialValues needs to be an array with a length of ' num2str(numKernels*3)],...
                    'Input Error','modal');
                return;
            end
            x0=varargin{i+1};
        case 'noOpt'
            if(~islogical(varargin{i+1}))
                errordlg('Optimization flag needs to be logical',...
                    'Input Error','modal');
                return;
            end
            noOpt=varargin{i+1};
        case 'numKernels'
            if(~isscalar(varargin{i+1}))
                errordlg('Number of kernels needs to be scalar',...
                    'Input Error','modal');
                return;
            end
            if(varargin{i+1} < 2 || varargin{i+1} > 5)
                errordlg('Number of kernels cannot be less than 2 or more than 5',...
                    'Input Error','modal');
                return;
            end
            numKernels=varargin{i+1};
        case 'kernelTypes'
            allowedTypes = {'Gamma','GammaGaussian','Gaussian'};
            if(~ischar(varargin{i+1}))
                errordlg('Kernel types need to be char',...
                    'Input Error','modal');
                return;
            end
            if(~ismember(varargin{i+1},allowedTypes))
                errordlg('Kernel types need to be either Gamma, GammaGaussian or Gaussian',...
                    'Input Error','modal');
                return;
            end
            kernelTypes=varargin{i+1};
        case 'method'
            allowedMethods = {'generic','Sorelli','Couceiro'};
            if(~ischar(varargin{i+1}))
                errordlg('Method needs to be char',...
                    'Input Error','modal');
                return;
            end
            if(~ismember(varargin{i+1},allowedMethods))
                errordlg('Method needs to be either generic, Sorelli or Couceiro',...
                    'Input Error','modal');
                return;
            end
            method=varargin{i+1};
        case 'normalizeOutput'
            if(~islogical(varargin{i+1}))
                errordlg('Normalization flag needs to be logical',...
                    'Input Error','modal');
                return;
            end
            normOut=varargin{i+1};
    end
    i=i+2;
end

%% needed functions
% Gamma kernel
    function alpha = alpha(x)
        alpha = ((1/(2*(x(3)^2)))*(x(2)^2+x(2)*sqrt(x(2)^2+4*(x(3)^2)))+1);
    end

    function beta = beta(x)
        beta = ((1/(2*(x(3)^2)))*(x(2)+sqrt(x(2)^2+4*(x(3)^2))));
    end

    function s = s(x,t_ppg)
        s = max(gampdf(t_ppg,alpha(x),1/beta(x)))/x(1);
    end

    function gamma = gamma(x,t_ppg)
        gamma = gampdf(t_ppg,alpha(x),1/beta(x))/s(x,t_ppg);
    end

% Gaussian kernel
    function gaussian = gaussian(x,t_ppg)
        gaussian = (x(1)*exp(-(t_ppg-x(2)).^2/(2*x(3)^2)));
    end

% kernel composition
    function [g,kernels,errorFlag] = createKernels(t_ppg,kernelTypes,numKernels)
        if strcmp(kernelTypes,'Gamma')
            if numKernels == 1
                g = false;
                kernels = false;
                errorFlag = true;
                errordlg('Too few kernels','Input Error','modal');
                return;
            elseif numKernels == 2
                g=@(x) gamma(x(1:3),t_ppg)+gamma(x(4:6),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gamma(x(4:6),t_ppg)];
                errorFlag = false;
            elseif numKernels == 3
                g=@(x) gamma(x(1:3),t_ppg)+gamma(x(4:6),t_ppg)+gamma(x(7:9),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gamma(x(4:6),t_ppg);gamma(x(7:9),t_ppg)];
                errorFlag = false;
            elseif numKernels == 4
                g=@(x) gamma(x(1:3),t_ppg)+gamma(x(4:6),t_ppg)+gamma(x(7:9),t_ppg)+gamma(x(10:12),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gamma(x(4:6),t_ppg);gamma(x(7:9),t_ppg);gamma(x(10:12),t_ppg)];
                errorFlag = false;
            elseif numKernels == 5
                g=@(x) gamma(x(1:3),t_ppg)+gamma(x(4:6),t_ppg)+gamma(x(7:9),t_ppg)+gamma(x(10:12),t_ppg)+gamma(x(13:15),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gamma(x(4:6),t_ppg);gamma(x(7:9),t_ppg);gamma(x(10:12),t_ppg);gamma(x(13:15),t_ppg)];
                errorFlag = false;
            else
                g = false;
                kernels = false;
                errorFlag = true;
                errordlg('Too many kernels','Input Error','modal');
                return;
            end
        elseif strcmp(kernelTypes,'GammaGaussian')
            if numKernels == 1
                g = false;
                kernels = false;
                errorFlag = true;
                errordlg('Too few kernels','Input Error','modal');
                return;
            elseif numKernels == 2
                g=@(x) gamma(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gaussian(x(4:6),t_ppg)];
                errorFlag = false;
            elseif numKernels == 3
                g=@(x) gamma(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg)+gaussian(x(7:9),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gaussian(x(4:6),t_ppg);gaussian(x(7:9),t_ppg)];
                errorFlag = false;
            elseif numKernels == 4
                g=@(x) gamma(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg)+gaussian(x(7:9),t_ppg)+gaussian(x(10:12),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gaussian(x(4:6),t_ppg);gaussian(x(7:9),t_ppg);gaussian(x(10:12),t_ppg)];
                errorFlag = false;
            elseif numKernels == 5
                g=@(x) gamma(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg)+gaussian(x(7:9),t_ppg)+gaussian(x(10:12),t_ppg)+gaussian(x(13:15),t_ppg);
                kernels=@(x) [gamma(x(1:3),t_ppg);gaussian(x(4:6),t_ppg);gaussian(x(7:9),t_ppg);gaussian(x(10:12),t_ppg);gaussian(x(13:15),t_ppg)];
                errorFlag = false;
            else
                g = false;
                kernels = false;
                errorFlag = true;
                errordlg('Too many kernels','Input Error','modal');
                return;
            end
        elseif strcmp(kernelTypes,'Gaussian')
            if numKernels == 1
                g = false;
                kernels = false;
                errorFlag = true;
                errordlg('Too few kernels','Input Error','modal');
                return;
            elseif numKernels == 2
                g=@(x) gaussian(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg);
                kernels=@(x) [gaussian(x(1:3),t_ppg);gaussian(x(4:6),t_ppg)];
                errorFlag = false;
            elseif numKernels == 3
                g=@(x) gaussian(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg)+gaussian(x(7:9),t_ppg);
                kernels=@(x) [gaussian(x(1:3),t_ppg);gaussian(x(4:6),t_ppg);gaussian(x(7:9),t_ppg)];
                errorFlag = false;
            elseif numKernels == 4
                g=@(x) gaussian(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg)+gaussian(x(7:9),t_ppg)+gaussian(x(10:12),t_ppg);
                kernels=@(x) [gaussian(x(1:3),t_ppg);gaussian(x(4:6),t_ppg);gaussian(x(7:9),t_ppg);gaussian(x(10:12),t_ppg)];
                errorFlag = false;
            elseif numKernels == 5
                g=@(x) gaussian(x(1:3),t_ppg)+gaussian(x(4:6),t_ppg)+gaussian(x(7:9),t_ppg)+gaussian(x(10:12),t_ppg)+gaussian(x(13:15),t_ppg);
                kernels=@(x) [gaussian(x(1:3),t_ppg);gaussian(x(4:6),t_ppg);gaussian(x(7:9),t_ppg);gaussian(x(10:12),t_ppg);gaussian(x(13:15),t_ppg)];
                errorFlag = false;
            else
                g = false;
                kernels = false;
                errorFlag = true;
                errordlg('Too many kernels','Input Error','modal');
                return;
            end
        else
            g = false;
            kernels = false;
            errordlg('Kernel type not supported','Input Error','modal');
            return;
        end
    end

% normalization/denormalization
    function [m,n] = getNormalizationFactors(ppg_signal)
        m = 1/(max(ppg_signal) - min(ppg_signal));
        n = min(ppg_signal)/(max(ppg_signal) - min(ppg_signal));
    end

    function ppg_signal = normalize(ppg_signal)
       ppg_signal = (ppg_signal - min(ppg_signal))/(max(ppg_signal) - min(ppg_signal));
    end

% initial values, boundaries and constriants
    function [inc_ref,delta_t_sys,delta_t_dia] = getSorelliPoints(ppg_signal,t_ppg,freq)
        % 1. search for systolic reference (highest maximum)
        [peaks,~] = findpeaks(ppg_signal);
        sys_ref = find(ppg_signal==max(peaks));
        
        % 2. find end-diastolic perfusion through as absolute minimum (but not
        % first point in signal)
        leave_out = 5;
        dia_ref = find(ppg_signal(leave_out+1:end)==min(ppg_signal(leave_out+1:end))); % leave out few first points
        dia_ref = dia_ref+leave_out; % add samples to be in line with real signal input
        dia_ref = t_ppg(dia_ref); % turn diastolic reference to time point instead of sample
        
        % 3. refinement step for systolic detection: search for all maxima
        % preceding the original solution, whose prominence with respect to the
        % corresponding valley does not fall below 80% of the original peak
        % amplitude
        [~,maxima_loc] = findpeaks(ppg_signal,'MinPeakProminence',0.8*ppg_signal(sys_ref)); % find all peaks with required prominence
        maxima_loc(maxima_loc>=sys_ref) = []; % keep only maxima before systolic reference
        if ~(isempty(maxima_loc))
            sys_ref = maxima_loc(1); % make first found maximum to new systolic reference
            % this step is not explicitly stated in sorellis Paper
        end
        sys_ref = t_ppg(sys_ref); % turn systolic reference to time point instead of sample
        
        % 4. refinement step for diastolic detection: not needed in this function
        % because input signals should be beats from minimum to minimum
        
        % 5. calculte derivative (by 3point differentiator) (zentrierte differenz)
        deriv_1 = deriv1(ppg_signal); % not using central difference
        
        % 6. filter derivative with 7point moving average
        windowWidth = 7;
        b = (1/windowWidth)*ones(1,windowWidth);
        a = 1;
        deriv_1 = filtfilt(b,a,deriv_1);
        
        % 7. search for earliest neg to pos zero crossing of first derivative after
        % systolic reference. If none are detected, end-diastolic reference is
        % selected
        sign_deriv_1 = sign(deriv_1); % Array mit Vorzeichen (-1 = negativ, 1= positiv)
        zero_cross = t_ppg([diff(sign_deriv_1) 0] ~= 0); % find time stamps of sign change
        if(~(isempty(zero_cross)))
            zero_cross(zero_cross<=sys_ref) = [];
            if(~(isempty(zero_cross)))
                cross_ref = zero_cross(1);
            else
                cross_ref = dia_ref;
            end
        else
            cross_ref = dia_ref;
        end
        
        % 8. time span between this point and the systolic peak is analyzed for the
        % presence of local p'(t) maxima exceeding the average pulse slope (average
        % of first derivative in this interval) in the same interval: if detected,
        % the earliest of them is adopted as the incisura reference, otherwise the
        % original p'(t) zero crossing is chosen
        av_slope = mean(deriv_1(find(t_ppg==sys_ref):find(t_ppg==cross_ref)));
        try
            [~,inc_ref] = findpeaks(deriv_1(find(t_ppg==sys_ref):find(t_ppg==cross_ref)),'MinPeakHeight',av_slope);
        catch
            inc_ref = [];
        end
        if(~(isempty(inc_ref)))
            inc_ref = inc_ref+(sys_ref*freq); % am ende anzahl samples von sys_ref wieder raufrechnen
            inc_ref = inc_ref/freq; % turn incisura reference to time point instead of sample
        else
            if(~(cross_ref==dia_ref))
                inc_ref = cross_ref;
            else
                inc_ref = sys_ref;
            end
        end
        
        % calculate systolic and diastolic time span
        inc_ref = inc_ref(1); % make sure there is only one inc_ref
        delta_t_sys = inc_ref; % delta_t_sys is time from beginning to incisura
        delta_t_dia = t_ppg(end)-inc_ref; % delta_t_sys is time from incisura to the end
    end

    function [pos_a_time,pos_b_time,pos_c_time,pos_d_time,pos_f_time, ...
            bound_before_time,bound_after_time,bound_after] ...
            = getCouceiroPoints(ppg_signal,freq)
        % finding dicrotic notch
        deriv_2 = deriv2Couceiro(ppg_signal);
        
        %do moving average filter to smoothen second derivative
        deriv_2 = movmean(deriv_2,50);
        %specify min peak prominence
        minProm = (max(deriv_2)-min(deriv_2))/10;
        
        sample_vec = 1:length(deriv_2);
        interval_beg = 0.2*freq;
        interval_end = 0.4*freq;
        % find reference point for dicrotic notch
        try
            [max_amp,max_loc] = findpeaks(deriv_2(interval_beg:interval_end),'MinPeakProminence',minProm);
            max_loc = max_loc+interval_beg;
            if(length(max_amp)>1)
                max_loc = max_loc(max_amp==max(max_amp));
                if(length(max_loc)>1) % if there is more than one peak of same height
                    max_loc = max_loc(1); % take first peak
                end
                max_amp = max(max_amp);
            end
            if(isempty(max_loc))
                % if there are no peaks in temporal window, take maximum of signal
                % in defined interval
                max_amp = max(deriv_2(interval_beg:interval_end));
                max_loc = sample_vec(deriv_2 == max_amp);
                max_loc(max_loc>interval_end) = [];
                max_loc(max_loc<interval_beg) = [];
            end
        catch
            % if there are no peaks in temporal window, take maximum of signal
            % in defined interval
            max_amp = max(deriv_2(interval_beg:interval_end));
            max_loc = sample_vec(deriv_2 == max_amp);
            max_loc(max_loc>interval_end) = [];
            max_loc(max_loc<interval_beg) = [];
        end
        dic_ref = max_loc;
        % find boundaries
        deriv_2_sign = sign(deriv_2);
        zero_cross = sample_vec([0 diff(deriv_2_sign)] ~= 0);
        zero_cross_before = zero_cross(zero_cross<max_loc);
        zero_cross_before = max(zero_cross_before);
        if(zero_cross_before<interval_beg)
            zero_cross_before = [];
        else
            bound_before = zero_cross_before;
        end
        zero_cross_after = zero_cross(zero_cross>max_loc);
        zero_cross_after = max(zero_cross_after);
        if(zero_cross_after>interval_end)
            zero_cross_after = [];
        else
            bound_after = zero_cross_after;
        end
        if(isempty(zero_cross_before))% needs refinement
            deriv_4 = deriv4Couceiro(ppg_signal);
            deriv_4_sign = sign(deriv_4);
            zero_cross4 = sample_vec([0 diff(deriv_4_sign)] ~= 0);
            zero_cross4_before = zero_cross4(zero_cross4<max_loc);
            zero_cross4_before = max(zero_cross4_before);
            bound_before = zero_cross4_before;
        end
        if(isempty(zero_cross_after))
            deriv_4 = deriv4Couceiro(ppg_signal);
            deriv_4_sign = sign(deriv_4);
            zero_cross4 = sample_vec([0 diff(deriv_4_sign)] ~= 0);
            zero_cross4_after = zero_cross4(zero_cross4>max_loc);
            zero_cross4_after = min(zero_cross4_after);
            bound_after = zero_cross4_after;
        end
        
        % search for important points
        [peaks_pos_amp,peaks_pos_loc] = findpeaks(deriv_2,'MinPeakProminence',minProm);
        [peaks_neg_amp,peaks_neg_loc] = findpeaks(-deriv_2,'MinPeakProminence',minProm);
        peaks_pos_loc_sys = peaks_pos_loc(peaks_pos_loc<=bound_before);
        peaks_neg_loc_sys = peaks_neg_loc(peaks_neg_loc<=bound_before);
        peaks_pos_loc_dias = peaks_pos_loc(peaks_pos_loc>=bound_after);
        peaks_neg_loc_dias = peaks_neg_loc(peaks_neg_loc>=bound_after);
        pos_a = peaks_pos_loc_sys(1);
        pos_b = peaks_neg_loc_sys(1);
        if(length(peaks_pos_loc_sys)>1)
            pos_c = peaks_pos_loc_sys(2);
            pos_d = peaks_neg_loc_sys(2);
        else
            pos_c = pos_b;
            pos_d = bound_before;
        end
        if(~isempty(peaks_neg_loc_dias))
            pos_f = peaks_neg_loc_dias(1);
        else
            pos_f = bound_after;
        end
        
        % convert positions to time points
        pos_a_time = pos_a/freq;
        pos_b_time = pos_b/freq;
        pos_c_time = pos_c/freq;
        pos_d_time = pos_d/freq;
        pos_f_time = pos_f/freq;
        bound_before_time = bound_before/freq;
        bound_after_time = bound_after/freq;
        dic_ref_time = dic_ref/freq;
    end

    function [c, ceq] = constr_generic2kernels(x)
        c = [x(2)-x(5); % 1. mean is less than 2. mean
            x(4)-x(1)]; % 1. amplitude is higher than 2. amplitude
        ceq = [];
    end

    function [c, ceq] = constr_generic3kernels(x)
        c = [x(2)-x(5); % 1. mean is less than 2. mean
            x(5)-x(8); % 2. mean is less than 3. mean
            x(4)-x(1); % 1. amplitude is higher than 2. amplitude
            x(7)-x(1)]; % 1. amplitude is higher than 3. amplitude
        ceq = [];
    end

    function [c, ceq] = constr_generic4kernels(x)
        c = [x(2)-x(5); % 1. mean is less than 2. mean
            x(5)-x(8); % 2. mean is less than 3. mean
            x(8)-x(11); % 3. mean is less than 4. mean
            x(4)-x(1); % 1. amplitude is higher than 2. amplitude
            x(7)-x(1); % 1. amplitude is higher than 3. amplitude
            x(10)-x(1)]; % 1. amplitude is higher than 4. amplitude
        ceq = [];
    end

    function [c, ceq] = constr_generic5kernels(x)
        c = [x(2)-x(5); % 1. mean is less than 2. mean
            x(5)-x(8); % 2. mean is less than 3. mean
            x(8)-x(11); % 3. mean is less than 4. mean
            x(11)-x(14); % 4. mean is less than 5. mean
            x(4)-x(1); % 1. amplitude is higher than 2. amplitude
            x(7)-x(1); % 1. amplitude is higher than 3. amplitude
            x(10)-x(1); % 1. amplitude is higher than 4. amplitude
            x(13)-x(1)]; % 1. amplitude is higher than 5. amplitude
        ceq = [];
    end

    function [c, ceq] = constr_sorelli3kernels(x)
        c = x(5)-x(8); % 2. mean is less than 3. mean
        ceq = [];
    end

    function [c, ceq] = constr_sorelli4kernels(x)
        c = [x(5)-x(8); % 2. mean is less than 3. mean
            x(8)-x(11)]; % 3. mean is less than 4. mean
        ceq = [];
    end

    function [c, ceq] = constr_couceiro5kernels(x)
        c = [x(1)-x(4); % 1. amplitude is less than 2. amplitude
            x(1)-x(7); % 1. amplitude is less than 3. amplitude
            x(7)-x(4); % 3. amplitude is less than 2. amplitude
            x(10)-x(4); % 4. amplitude is less than 2. amplitude
            x(13)-x(4); % 5. amplitude is less than 2. amplitude
            x(13)-x(10); % 5. amplitude is less than 4. amplitude
            x(2)-x(5); % 1. mean is less than 2. mean
            x(5)-x(8); % 2. mean is less than 3. mean
            x(8)-x(11); % 3. mean is less than 4. mean
            x(11)-x(14)]; % 4. mean is less than 5. mean
        ceq = [];
    end

    function [x0,lb,ub,cons,errorFlag] = getOptSpecs(ppg_signal,t_ppg,freq,numKernels,method)
        errorFlag = false;
        if(strcmp(method,'generic'))
            if(numKernels==2)
                % intial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=(2/7)*max(t_ppg); % position (my)
                x0(3)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 2. wave
                x0(4)=0.5*max(ppg_signal); % amplitude (a)
                x0(5)=(4/7)*max(t_ppg); % position (my)
                x0(6)=(((3/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % boundaries
                lb=[0 0 0 0 0 0]; % lower boundary
                ub=[max(ppg_signal) max(t_ppg) max(t_ppg) ...
                    max(ppg_signal) max(t_ppg) max(t_ppg)]; % upper boundary
                % constraints
                cons = @constr_generic2kernels;
            elseif(numKernels==3)
                % initial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=(2/7)*max(t_ppg); % position (my)
                x0(3)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 2. wave
                x0(4)=0.4*max(ppg_signal); % amplitude (a)
                x0(5)=(4/7)*max(t_ppg); % position (my)
                x0(6)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 3. wave
                x0(7)=0.2*max(ppg_signal); % amplitude (a)
                x0(8)=(5/7)*max(t_ppg); % position (my)
                x0(9)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % boundaries
                lb=[0 0 0 0 0 0 0 0 0]; % lower boundary
                ub=[max(ppg_signal) max(t_ppg) max(t_ppg) ...
                    max(ppg_signal) max(t_ppg) max(t_ppg)...
                    max(ppg_signal) max(t_ppg) max(t_ppg)]; % upper boundary
                % constraints
                cons = @constr_generic3kernels;
            elseif(numKernels==4)
                % initial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=(2/7)*max(t_ppg); % position (my)
                x0(3)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 2. wave
                x0(4)=0.4*max(ppg_signal); % amplitude (a)
                x0(5)=(3/7)*max(t_ppg); % position (my)
                x0(6)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 3. wave
                x0(7)=0.4*max(ppg_signal); % amplitude (a)
                x0(8)=(1/2)*max(t_ppg); % position (my)
                x0(9)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 4. wave
                x0(10)=0.4*max(ppg_signal); % amplitude (a)
                x0(11)=(45/70)*max(t_ppg); % position (my)
                x0(12)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % boundaries
                lb=[0 0 0 0 0 0 0 0 0 0 0 0]; % lower boundary
                ub=[max(ppg_signal) max(t_ppg) max(t_ppg) ...
                    max(ppg_signal) max(t_ppg) max(t_ppg)...
                    max(ppg_signal) max(t_ppg) max(t_ppg)...
                    max(ppg_signal) max(t_ppg) max(t_ppg)]; % upper boundary
                % constraints
                cons = @constr_generic4kernels;
            elseif(numKernels==5)
                % initial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=(2/7)*max(t_ppg); % position (my)
                x0(3)=(((2/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 2. wave
                x0(4)=0.3*max(ppg_signal); % amplitude (a)
                x0(5)=(3/7)*max(t_ppg); % position (my)
                x0(6)=(((1/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 3. wave
                x0(7)=0.3*max(ppg_signal); % amplitude (a)
                x0(8)=(4/7)*max(t_ppg); % position (my)
                x0(9)=(((1/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 4. wave
                x0(10)=0.3*max(ppg_signal); % amplitude (a)
                x0(11)=(5/7)*max(t_ppg); % position (my)
                x0(12)=(((1/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % 5. wave
                x0(13)=0.3*max(ppg_signal); % amplitude (a)
                x0(14)=(6/7)*max(t_ppg); % position (my)
                x0(15)=(((1/7)*max(t_ppg))/(2*sqrt(2*log(2)))); % width (sigma)
                % boundaries
                lb=[0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]; % lower boundary
                ub=[max(ppg_signal) max(t_ppg) max(t_ppg) ...
                    max(ppg_signal) max(t_ppg) max(t_ppg)...
                    max(ppg_signal) max(t_ppg) max(t_ppg)...
                    max(ppg_signal) max(t_ppg) max(t_ppg) ...
                    max(ppg_signal) max(t_ppg) max(t_ppg)]; % upper boundary
                % constraints
                cons = @constr_generic5kernels;
            else
                errorFlag = true;
                errordlg('More than 5 or less than 2 kernels not supported for generic method',...
                    'Input Error','modal');
                return;
            end
        elseif(strcmp(method,'Sorelli'))
            [inc_ref,delta_t_sys,delta_t_dia] = getSorelliPoints(ppg_signal,t_ppg,freq);
            if(numKernels==2)
                % initial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=t_ppg(1)+0.5*delta_t_sys; % position (my)
                x0(3)=delta_t_sys/(2*sqrt(2*log(2))); % width (sigma)
                % 2. wave
                x0(4)=0.4*max(ppg_signal); % amplitude (a)
                x0(5)=inc_ref+0.33*delta_t_dia; % position (my)
                x0(6)=0.75*delta_t_dia/(2*sqrt(2*log(2))); % width (sigma)
                % boundaries
                lb=[0.5*max(ppg_signal) t_ppg(1) 0.5*delta_t_sys/(2*sqrt(2*log(2)))...
                    0 inc_ref 0.3*delta_t_dia/(2*sqrt(2*log(2)))]; % lower boundary
                ub=[max(ppg_signal) inc_ref 1.5*delta_t_sys/(2*sqrt(2*log(2)))...
                    0.6*max(ppg_signal) max(t_ppg) 1*delta_t_dia/(2*sqrt(2*log(2)))]; % upper boundary
                % constraints
                cons = [];
            elseif(numKernels==3)
                % initial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=t_ppg(1)+0.5*delta_t_sys; % position (my)
                x0(3)=delta_t_sys/(2*sqrt(2*log(2))); % width (sigma)
                % 2. wave
                x0(4)=0.4*max(ppg_signal); % amplitude (a)
                x0(5)=inc_ref+0.167*delta_t_dia; % position (my)
                x0(6)=0.375*delta_t_dia/(2*sqrt(2*log(2))); % width (sigma)
                % 3. wave
                x0(7)=0.4*max(ppg_signal); % amplitude (a)
                x0(8)=inc_ref+0.5*delta_t_dia; % position (my)
                x0(9)=0.375*delta_t_dia/(2*sqrt(2*log(2))); % width (sigma)
                % boundaries
                lb=[0.5*max(ppg_signal) t_ppg(1) 0.5*delta_t_sys/(2*sqrt(2*log(2)))...
                    0 inc_ref 0.15*delta_t_dia/(2*sqrt(2*log(2)))...
                    0 inc_ref 0.15*delta_t_dia/(2*sqrt(2*log(2)))]; % lower boundary
                ub=[max(ppg_signal) inc_ref 1.5*delta_t_sys/(2*sqrt(2*log(2)))...
                    0.6*max(ppg_signal) max(t_ppg) 0.5*delta_t_dia/(2*sqrt(2*log(2)))...
                    0.6*max(ppg_signal) max(t_ppg) 0.5*delta_t_dia/(2*sqrt(2*log(2)))]; % upper boundary
                % constraints
                cons = @constr_sorelli3kernels;
            elseif(numKernels==4)
                % initial values
                % 1. wave
                x0(1)=0.8*max(ppg_signal); % amplitude (a)
                x0(2)=t_ppg(1)+0.5*delta_t_sys; % position (my)
                x0(3)=delta_t_sys/(2*sqrt(2*log(2))); % width (sigma)
                % 2. wave
                x0(4)=0.4*max(ppg_signal); % amplitude (a)
                x0(5)=inc_ref; % position (my)
                x0(6)=0.25*delta_t_dia/(2*sqrt(2*log(2))); % width (sigma)
                % 3. wave
                x0(7)=0.4*max(ppg_signal); % amplitude (a)
                x0(8)=inc_ref+0.33*delta_t_dia; % position (my)
                x0(9)=0.25*delta_t_dia/(2*sqrt(2*log(2))); % width (sigma)
                % 4. wave
                x0(10)=0.4*max(ppg_signal); % amplitude (a)
                x0(11)=inc_ref+0.67*delta_t_dia; % position (my)
                x0(12)=0.25*delta_t_dia/(2*sqrt(2*log(2))); % width (sigma)
                % boundaries
                lb=[0.5*max(ppg_signal) t_ppg(1) 0.5*delta_t_sys/(2*sqrt(2*log(2)))...
                    0 inc_ref 0.1*delta_t_dia/(2*sqrt(2*log(2)))...
                    0 inc_ref 0.1*delta_t_dia/(2*sqrt(2*log(2)))...
                    0 inc_ref 0.1*delta_t_dia/(2*sqrt(2*log(2)))]; % lower boundary
                ub=[max(ppg_signal) inc_ref 1.5*delta_t_sys/(2*sqrt(2*log(2)))...
                    0.6*max(ppg_signal) max(t_ppg) 0.33*delta_t_dia/(2*sqrt(2*log(2)))...
                    0.6*max(ppg_signal) max(t_ppg) 0.33*delta_t_dia/(2*sqrt(2*log(2)))...
                    0.6*max(ppg_signal) max(t_ppg) 0.33*delta_t_dia/(2*sqrt(2*log(2)))]; % upper boundary
                % constraints
                cons = @constr_sorelli4kernels;
            else
                errorFlag = true;
                errordlg('More than 4 or less than 2 kernels not supported for Sorelli method',...
                    'Input Error','modal');
                return;
            end
        elseif(strcmp(method,'Couceiro'))
            [pos_a_time,pos_b_time,pos_c_time,pos_d_time,pos_f_time, ...
            bound_before_time,bound_after_time,bound_after] ...
            = getCouceiroPoints(ppg_signal,freq);
            if(numKernels==5)
                % initial values
                % 1. wave
                x0(1)=0.7*ppg_signal(pos_a); % amplitude (a)
                x0(2)=pos_a_time; % position (my)
                x0(3)=pos_a_time/3; % width (sigma)
                % 2. wave
                x0(4)=0.9*max([ppg_signal(pos_b) ppg_signal(pos_c) ppg_signal(pos_d)]); % amplitude (a)
                x0(5)=pos_b_time; % position (my)
                x0(6)=pos_b_time/3; % width (sigma)
                % 3. wave
                x0(7)=0.5*max([ppg_signal(pos_b) ppg_signal(pos_c) ppg_signal(pos_d)]); % amplitude (a)
                x0(8)=pos_d_time; % position (my)
                x0(9)=pos_d_time/3; % width (sigma)
                % 4. wave
                x0(10)=0.8*max(ppg_signal(bound_after:end)); % amplitude (a)
                x0(11)=pos_f_time; % position (my)
                x0(12)=min([pos_f_time (t_ppg(end)-pos_f_time)/3]); % width (sigma)
                % 5. wave
                x0(13)=0.3*max(ppg_signal(bound_after:end)); % amplitude (a)
                x0(14)=t_ppg(ppg_signal==max(ppg_signal(bound_after:end))); % position (my)
                x0(15)=t_ppg(end)-mean([t_ppg(end) pos_f_time]); % width (sigma)
                % NOTE: i=5 in couceiro nicht konsistent definiert, da B_dias außerhalb von
                % pos_f und T liegen kann; hier sind Grenzen auf bound_after und T
                % geändert worden
                % boundaries
                lb=[0.5*ppg_signal(pos_a) pos_a_time 0 ...
                    0.5*max([ppg_signal(pos_b) ppg_signal(pos_c) ppg_signal(pos_d)]) pos_a_time pos_a_time/3 ...
                    0.2*max([ppg_signal(pos_b) ppg_signal(pos_c) ppg_signal(pos_d)]) pos_b_time pos_b_time/3 ...
                    0 bound_after_time 0 ...
                    0 pos_f_time 0]; % lower boundary
                ub=[ppg_signal(pos_b) pos_b_time pos_b_time/3 ...
                    max([ppg_signal(pos_b) ppg_signal(pos_c) ppg_signal(pos_d)]) pos_c_time pos_d_time/3 ...
                    0.8*max([ppg_signal(pos_b) ppg_signal(pos_c) ppg_signal(pos_d)]) bound_before_time bound_before_time/3 ...
                    max(ppg_signal(bound_after:end)) max(t_ppg) bound_after_time ...
                    max(ppg_signal(bound_after:end)) max(t_ppg) bound_after_time]; % upper boundary
                % constraints
                cons = @constr_couceiro5kernels;
            else
                errorFlag = true;
                errordlg('Only 5 kernels supported for Couceiro method',...
                    'Input Error','modal');
                return;
            end
        else
            errorFlag = true;
            errordlg('Other methods than generic, Sorelli or Couceiro not supported',...
                'Input Error','modal');
            return;
        end
    end

%% produce time axis for input beat
t_ppg = 0:1/freq:(length(ppg_signal)-1)/freq;

%% normalize input
[m,n] = getNormalizationFactors(ppg_signal);
ppg_signal = normalize(ppg_signal);

%% initial values, boundaries and constraints
if (isempty(x0))
    [x0,lb,ub,cons,errorFlag] = getOptSpecs(ppg_signal,t_ppg,freq,numKernels,method);
else
    [~,lb,ub,cons,errorFlag] = getOptSpecs(ppg_signal,t_ppg,freq,numKernels,method);
end
if errorFlag
    % TODO: improve returning to outer script (give back some value, maybe
    % stop creating modal messages
    return;
end

%% optimization
[g,kernels,errorFlag]=createKernels(t_ppg,kernelTypes,numKernels);
if errorFlag
    % TODO: improve returning to outer script (give back some value, maybe
    % stop creating modal messages
    return;
end
h=@(x) sum((ppg_signal-g(x)).^2); % Residual Sum of Squares (RSS)

if(~(isempty(noOpt)) && (noOpt==true)) % is noOpt is set true, skip optimization
    % initial values are given as output
    opt_val_sort = x0;
    % kernels
    y = kernels(opt_val_sort);
    % denormalization if selected
    if(~normOut)
        opt_val_sort(1:3:end) = (opt_val_sort(1:3:end)+n)/m;
        y = (y+n)/m;
    end
    % sum of basis functions
    signal_mod=sum(y); % reconstructed signal
    % produce cell array of basis functions
    y = mat2cell(y,ones(1,numKernels),length(ppg_signal));
    
else % do optimization
    options = optimoptions(@fmincon,'MaxFunctionEvaluations',Inf);
    opt_values=fmincon(h,x0,[],[],[],[],lb,ub,cons,options);
    
    %% reconstruction
    % kernels
    yTmp = kernels(opt_values);
    
    % sorting the waves
    peakTmp=zeros(size(yTmp,1),1);
    for i=1:size(yTmp,1)
        try
            [~,peakTmp(i)]=find(yTmp(i,:)==max((yTmp(i,:))));
        catch
            peakTmp(i) = length(yTmp(i,:)); % take last sample as peak index if no peak exists 
        end
    end
    [~,cc]=sort(peakTmp);
    y=yTmp(cc,:);
    
    % sorting the optimized parameters
    for i=1:size(yTmp,1)
        opt_val_sort((1+(i-1)*3):(3+(i-1)*3))=...
            opt_values((1+(cc(i)-1)*3):(3+(cc(i)-1)*3));
    end
    
    % denormalization if selected
    if(~normOut)
        opt_val_sort(1:3:end) = (opt_val_sort(1:3:end)+n)/m;
        y = (y+n)/m;
    end
    
    % sum of basis functions
    signal_mod=sum(y); % reconstructed signal
    
    % produce cell array of basis functions
    y = mat2cell(y,ones(1,numKernels),length(ppg_signal));
end

end