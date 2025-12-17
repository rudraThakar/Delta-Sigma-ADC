% USER INPUTS
Fs     = 4e3;     % Sampling rate
N      = 26;      % Filter order (must be even for halfband)
beta   = 8;       % Kaiser beta => stopband ≈ 80 dB for this size

% Halfband FIR design
halfband_coeff = firhalfband(N, kaiser(N+1, beta));

L = length(halfband_coeff);

% DISPLAY RESULTS
fprintf('Sampling Rate   : %.2f Hz\n', Fs);
fprintf('Filter Order    : %d\n', N);
fprintf('Number of Taps  : %d\n', L);
fprintf('Halfband cutoff : %.2f Hz (fixed)\n', Fs/4);
fprintf('halfband_coeff = [%s];\n\n', sprintf('%.16f ', halfband_coeff));

% PLOT FILTER RESPONSE
%figure;
%freqz(halfband_coeff, 1, 2048, Fs);
%title('Halfband FIR Filter Frequency Response');

%fvtool(halfband_coeff,1);
