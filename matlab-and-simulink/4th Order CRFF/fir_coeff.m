%% AUTOMATIC FIR LOW-PASS FILTER DESIGN (Tap-limited, corrected)


%% USER PARAMETERS
Fs  = 128e3;      % Sampling frequency (Hz)
Fp  = 1e3;        % Passband edge (Hz)
Fst = 3e3;        % Stopband edge (Hz)
Ap  = 0.1;        % Desired passband ripple (dB)
Ast = 80;         % Desired stopband attenuation (dB)
MaxTaps = 100;    % Maximum allowed taps

%% DESIGN ATTEMPT 1: Let MATLAB choose order
d = designfilt('lowpassfir', ...
               'PassbandFrequency', Fp, ...
               'StopbandFrequency', Fst, ...
               'PassbandRipple', Ap, ...
               'StopbandAttenuation', Ast, ...
               'SampleRate', Fs);

fir_coefficients = d.Coefficients;
N_auto = length(fir_coefficients);

fprintf('Auto-designed filter taps = %d\n', N_auto);

%% CHECK IF TAP COUNT EXCEEDS LIMIT
if N_auto > MaxTaps
    fprintf('Tap limit exceeded (%d > %d). Redesigning with %d taps...\n', ...
        N_auto, MaxTaps, MaxTaps);

    % Normalized frequency vector for firpm (0..1 where 1 = Nyquist)
    F = [0  Fp  Fst  Fs/2] / (Fs/2);
    A = [1  1   0    0];
    W = [1 10];

    fir_coefficients = firpm(MaxTaps-1, F, A, W);
    N_final = length(fir_coefficients);

    [H, w] = freqz(fir_coefficients, 1, 4096, Fs);
    magdB = 20*log10(abs(H) + eps);

    passband_idx  = (w >= 0) & (w <= Fp);
    stopband_idx  = (w >= Fst) & (w <= Fs/2);

    ActualAp  = max(magdB(passband_idx)) - min(magdB(passband_idx));
    ActualAst = -max(magdB(stopband_idx));

    fprintf('\n=== NEW FILTER PERFORMANCE WITH TAP LIMIT ===\n');
    fprintf('Passband ripple   : %.4f dB\n', ActualAp);
    fprintf('Stopband atten.   : %.4f dB\n', ActualAst);
    fprintf('Final tap count   : %d\n', N_final);
else
    fprintf('Tap count within limit; using auto-designed filter.\n');
    N_final = N_auto;

    [H, w] = freqz(fir_coefficients, 1, 4096, Fs);
    magdB = 20*log10(abs(H) + eps);

    passband_idx  = (w >= 0) & (w <= Fp);
    stopband_idx  = (w >= Fst) & (w <= Fs/2);

    ActualAp  = max(magdB(passband_idx)) - min(magdB(passband_idx));
    ActualAst = -max(magdB(stopband_idx));

    fprintf('\n=== FILTER PERFORMANCE ===\n');
    fprintf('Passband ripple   : %.4f dB\n', ActualAp);
    fprintf('Stopband atten.   : %.4f dB\n', ActualAst);
    fprintf('Final tap count   : %d\n', N_final);
end

%% PRINT COEFFICIENTS IN COPY-PASTE FORMAT
%fprintf('\n=== FIR COEFFICIENTS (%d taps) ===\n\n', N_final);

%fprintf('[');
%fprintf('%.15g ', fir_coefficients);
%fprintf(']\n\n');

%fprintf('Copy the above row vector into Simulink FIR Filter block (Numerator coefficients).\n');
