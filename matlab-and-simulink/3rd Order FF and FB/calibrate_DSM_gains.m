% calibrate_dsm_gains.m
% Simple calibration script to find optimal DSM gains for maximum SNR

modelName = 'ct3rdOrderFB';
order = 3;
OSR = 64;
form = 'FB';
fsVal = 128e3;
fout = 2e3;
optimFlag = 0;
f0 = 0;

% Simulation parameters
simTime = 1.0;

% Test different OBG values
OBG_range = [1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.5, 2.7];


fprintf('DSM Gain Calibration Started\n');
fprintf('Model: %s\n', modelName);
fprintf('Testing %d OBG values...\n\n', length(OBG_range));

% Load model
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

% Pre-allocate arrays
num_tests = length(OBG_range);
OBG_vals = zeros(num_tests, 1);
SNR_vals = zeros(num_tests, 1);
ENOB_vals = zeros(num_tests, 1);

% Store coefficients as matrices
a_store = cell(num_tests, 1);
g_store = cell(num_tests, 1);
b_store = cell(num_tests, 1);
c_store = cell(num_tests, 1);

fprintf('%4s | %6s | %8s | %8s\n', 'Iter', 'OBG', 'SNR(dB)', 'ENOB');
fprintf('-----|--------|----------|----------\n');

% Test each OBG value
for i = 1:num_tests
    OBG = OBG_range(i);
    
    % Get coefficients
    try
        [a, g, b, c] = msblks.ADC.dsmAdcFindCTcoeff(order, OSR, form, optimFlag, OBG, f0);
    catch
        fprintf('Failed to get coefficients for OBG=%.2f\n', OBG);
        SNR_vals(i) = -Inf;
        ENOB_vals(i) = -Inf;
        continue;
    end
    
    % Store coefficients
    a_store{i} = a;
    g_store{i} = g;
    b_store{i} = b;
    c_store{i} = c;
    
    % Apply to model
    mws = get_param(modelName, 'ModelWorkspace');
    mws.assignin('a', a);
    mws.assignin('b', b);
    mws.assignin('g', g);
    mws.assignin('c', c);
    mws.assignin('fs', fsVal);
    mws.assignin('DSM_order', order);
    mws.assignin('DSM_OSR', OSR);
    
    % Run simulation
    try
        simOut = sim(modelName, 'StopTime', num2str(simTime), 'SaveOutput', 'on');
        
        % Get output from simOut
        output = [];
        try
            tmp = simOut.get('ctdsmoutfb');
            if isa(tmp, 'timeseries')
                output = tmp.Data(:);
            else
                output = tmp(:);
            end
        catch
            % Fallback: try base workspace
            if evalin('base', 'exist(''ctdsmoutfb'',''var'')')
                tmp = evalin('base', 'ctdsmoutfb');
                if isa(tmp, 'timeseries')
                    output = tmp.Data(:);
                else
                    output = tmp(:);
                end
            end
        end
        
        % Compute SNR
        if ~isempty(output) && length(output) > 64
            y = output - mean(output);
            y = y(1:2^(nextpow2(length(y))-1));
            L = length(y);
            NFFT = 2^nextpow2(L);
            
            fft_out = fft(y .* hanning(L), NFFT);
            Ptot = abs(fft_out).^2;
            fft_onesided = abs(Ptot(1:NFFT/2+1));
            
            signal_band_end = floor(NFFT/(2*OSR));
            [~, peak_idx] = max(fft_onesided(3:signal_band_end));
            peak_idx = peak_idx + 2;
            
            sigbin = max(3, peak_idx-6):min(signal_band_end, peak_idx+6);
            sigpow = sum(fft_onesided(sigbin));
            npow = sum(fft_onesided(3:floor(end/OSR))) - sigpow;
            
            if npow > 0
                SNR = 10*log10(sigpow/npow);
                ENOB = (SNR - 1.76) / 6.02;
            else
                SNR = -Inf;
                ENOB = -Inf;
            end
        else
            SNR = -Inf;
            ENOB = -Inf;
        end
        
    catch ME
        fprintf('Simulation failed: %s\n', ME.message);
        SNR = -Inf;
        ENOB = -Inf;
    end
    
    % Store results
    OBG_vals(i) = OBG;
    SNR_vals(i) = SNR;
    ENOB_vals(i) = ENOB;
    
    % Display
    if isfinite(SNR)
        fprintf('%4d | %6.2f | %8.2f | %8.4f\n', i, OBG, SNR, ENOB);
    else
        fprintf('%4d | %6.2f | %8s | %8s\n', i, OBG, 'FAIL', 'FAIL');
    end
end

fprintf('\n');

% Find best result
valid_idx = isfinite(SNR_vals) & (SNR_vals > 0);
if any(valid_idx)
    valid_SNRs = SNR_vals(valid_idx);
    valid_indices = find(valid_idx);
    [best_SNR, rel_idx] = max(valid_SNRs);
    best_idx = valid_indices(rel_idx);
    
    best_OBG = OBG_vals(best_idx);
    best_ENOB = ENOB_vals(best_idx);
    best_a = a_store{best_idx};
    best_g = g_store{best_idx};
    best_b = b_store{best_idx};
    best_c = c_store{best_idx};
    
    fprintf('BEST CONFIGURATION\n');
    fprintf('OBG:   %.2f\n', best_OBG);
    fprintf('SNR:   %.3f dB\n', best_SNR);
    fprintf('ENOB:  %.4f bits\n', best_ENOB);
    fprintf('a %.4f\n', best_a);
    fprintf('b %.4f\n', best_b);
    fprintf('\n');
    
    % Apply best configuration
    mws = get_param(modelName, 'ModelWorkspace');
    mws.assignin('a', best_a);
    mws.assignin('b', best_b);
    mws.assignin('g', best_g);
    mws.assignin('c', best_c);
    mws.assignin('fs', fsVal);
    mws.assignin('DSM_order', order);
    mws.assignin('DSM_OSR', OSR);
    save_system(modelName);
    
    fprintf('Applied best gains to model and saved.\n');
    
    % Save results
    results.best_OBG = best_OBG;
    results.best_SNR = best_SNR;
    results.best_ENOB = best_ENOB;
    results.best_a = best_a;
    results.best_g = best_g;
    results.best_b = best_b;
    results.best_c = best_c;
    results.all_OBG = OBG_vals;
    results.all_SNR = SNR_vals;
    results.all_ENOB = ENOB_vals;
    
    save('dsm_calibration_results.mat', 'results');
    fprintf('Results saved to dsm_calibration_results.mat\n');
    
    % Plot
    figure;
    valid_OBGs = OBG_vals(valid_idx);
    valid_SNRs = SNR_vals(valid_idx);
    plot(valid_OBGs, valid_SNRs, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 8);
    hold on;
    plot(best_OBG, best_SNR, 'r*', 'MarkerSize', 15, 'LineWidth', 2);
    xlabel('Out-of-Band Gain (OBG)');
    ylabel('SNR (dB)');
    title('SNR vs Out-of-Band Gain');
    grid on;
    legend('Tested', 'Best', 'Location', 'best');
    
else
    fprintf('No valid configurations found!\n');
end

fprintf('\nCalibration complete!\n');