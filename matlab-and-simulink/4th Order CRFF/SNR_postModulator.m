%% User Inputs
OSR = 64;          % Oversampling ratio for all cases
Fs  = 128e3;       % Sampling frequency for all cases


saveFile = 'dsm_results.mat';


% Function to compute SNR/ENOB from DSM output
function [SNR, ENOB] = computeSNR(y, OSR)
    % Remove DC component
    y = y - mean(y);
    
    % Adjust length to power of 2
    y = y(1:2^(nextpow2(length(y))-1));
    L = length(y);
    NFFT = 2^nextpow2(L);
    
    % Apply Hanning window and compute FFT
    fft_out = fft(y .* hanning(L), NFFT);
    Ptot = (abs(fft_out)).^2;
    fft_onesided = abs(Ptot(1:NFFT/2+1));
    
    % Find signal bin (peak in the spectrum)
    % Search in the signal band (excluding DC and very low frequencies)
    signal_band_end = floor(NFFT/(2*OSR));
    [~, peak_idx] = max(fft_onesided(3:signal_band_end));
    peak_idx = peak_idx + 2; % Adjust for starting at index 3
    
    % Define signal bins around the peak (±6 bins as in template)
    sigbin = max(3, peak_idx-6):min(signal_band_end, peak_idx+6);
    
    % Signal power: integrate over signal bins
    sigpow = sum(fft_onesided(sigbin));
    
    % Noise power: integrate till Nyquist/OSR and subtract signal power
    npow = sum(fft_onesided(3:floor(end/OSR))) - sigpow;
    
    % Compute SNR
    SNR = 10*log10(sigpow/npow);
    
    % Compute ENOB from SNR
    % ENOB = (SNR - 1.76) / 6.02
    ENOB = (SNR - 1.76) / 6.02;
end

yCT = [];
yDT = [];

% 1) Direct workspace arrays (To Workspace blocks with Save format = Array)
if evalin('base','exist(''post_mod'',''var'')')
    tmp = evalin('base','post_mod');
    if isa(tmp,'timeseries')
        yCT = tmp.Data(:);
    else
        yCT = tmp(:);
    end
end



% 2) Check 'out' struct or simOut
if (isempty(yCT) || isempty(yDT)) && evalin('base','exist(''out'',''var'')')
    outVar = evalin('base','out');
    try
        if isstruct(outVar)
            if isfield(outVar,'post_mod')
                t = outVar.ctdsmoutff;
                if isa(t,'timeseries')
                    yCT = t.Data(:);
                else
                    yCT = t(:);
                end
            end

        else
            % Try SimulationOutput style
            try
                if ismethod(outVar,'get')
                    if isempty(yCT)
                        try
                            v = outVar.get('post_mod');
                            if isa(v,'timeseries')
                                yCT = v.Data(:);
                            else
                                yCT = v(:);
                            end
                        catch
                        end
                    end
                    
                end
            catch
            end
        end
    catch
    end
end

% 3) Check logsout dataset (signal logging)
if (isempty(yCT) || isempty(yDT)) && evalin('base','exist(''logsout'',''var'')')
    ds = evalin('base','logsout');
    try
        for kk = 1:ds.numElements
            nm = ds.get(kk-1).Name;
            v = ds.get(kk-1).Values;
            if isa(v,'timeseries')
                dat = v.Data(:);
            elseif isstruct(v) && isfield(v,'Data')
                dat = v.Data(:);
            else
                dat = [];
            end
            if contains(lower(nm),'ct') && isempty(yCT)
                yCT = dat;
            end

        end
    catch
    end
end


results = struct();

% Process CT DSM output
if ~isempty(yCT)
    try
        [SNR_CT, ENOB_CT] = computeSNR(yCT, OSR);
        results.SNR_CT = SNR_CT;
        results.ENOB_CT = ENOB_CT;
        fprintf('CT DSM:  SNR = %.3f dB, ENOB = %.4f bits\n', SNR_CT, ENOB_CT);
    catch ME
        warning('Error computing CT SNR/ENOB: %s', ME.message);
        results.SNR_CT = NaN;
        results.ENOB_CT = NaN;
    end
else
    warning('CT output not found in workspace. Ensure To Workspace var name = ''post_mod'' or logsout contains CT signal.');
    results.SNR_CT = NaN;
    results.ENOB_CT = NaN;
end


try
    save(saveFile,'results','-v7.3');
    fprintf('Saved results to %s\n', saveFile);
catch
    warning('Could not save results to %s', saveFile);
end