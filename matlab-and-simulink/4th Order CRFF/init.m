%% Delta-Sigma Modulator Initialization Script (init.m)
% Initializes all parameters and coefficients for the 4th-order CIFF DSM
% with optimized NTF zeros.

%% 0. Global Modulator Parameters
order = 4;      % Order of the DSM
OSR = 64;       % OverSampling Ratio
Ain = 1.8;      % Input Amplitude
fin = 250;      %Input Frequency
fs = 128e3;     % Oversampling frequency
nLev = 15;      % Number of quantizer levels (14 steps, levels -7 to +7)
Nfft = 2^13;    % Number of samples for simulation/FFT
tone_bin = 31;  % Input tone frequency bin

w = 1000*fs;    %Finite bandwidth
scale = 1.6;    % Fixed Amplitude gain for Vin
Gj = 1e5;       % Fixed finite integrator gains
A0 = 1/w;       % Non ideal Transfer fuction parameter
fsr = (2*pi)*fs*1.8; % Slew Rate
Amax = 1.8;     % Maximum saturation Amplitude with non-ideality
j_rms = 0.3;    % Clock Jitter parameter
A_flick = 1e-9; % Flicker Noise Amplitude parameter

% 1. Loading Filter Coefficients
fir_coeff;
fir_halfband_coeff;
cic_comp_coeff_calc;
%% 2. Calculate Coefficients
% Call the previous script to calculate a, g, b, c vectors.
% This assumes you saved the previous code as 'calculate_dsm_coeffs.m'
fprintf('Running coefficient calculation script...\n');
gain_calculate; 

%% 3. Map Coefficients to Simulink Variables
% The calculation script provides vectors (a, g, b, c).
% We must unpack them into scalars (a1, a2...) for the Simulink blocks.

% DAC Feedback Coefficients (a) - Vector size: [1 x order]
if length(a) >= 4
    a1 = a(1);
    a2 = a(2);
    a3 = a(3);
    a4 = a(4);
else
    error('Coefficient vector "a" is too short.');
end

% Resonator Feedback Coefficients (g) - Vector size: [1 x order/2]
% g1 is the inner loop, g2 the outer loop.
if length(g) >= 2
    g1 = g(1);
    g2 = g(2);
else
    error('Coefficient vector "g" is too short.');
end

% Feed-in Coefficients (b) - Vector size: [1 x order+1]
% Note: MATLAB indices are 1-based. b(1) corresponds to b1 (or b0 in some texts).
if length(b) >= 5
    b1 = b(1); % Input to 1st integrator
    b2 = b(2);
    b3 = b(3);
    b4 = b(4);
    b5 = b(5); % Input to Quantizer directly (if applicable)
else
    error('Coefficient vector "b" is too short.');
end

% Interstage Coefficients (c) - Vector size: [1 x order]
if length(c) >= 4
    c1 = c(1);
    c2 = c(2);
    c3 = c(3);
    c4 = c(4);
else
    error('Coefficient vector "c" is too short.');
end

fprintf('\n------------------------------------------------\n');
fprintf('Initialization Complete.\n');
fprintf('Coefficients loaded from calculation script:\n');
fprintf('a: [%.4f, %.4f, %.4f, %.4f]\n', a1, a2, a3, a4);
fprintf('g: [%.4f, %.4f]\n', g1, g2);
fprintf('b: [%.4f, %.4f, %.4f, %.4f, %.4f]\n', b1, b2, b3, b4, b5);
fprintf('c: [%.4f, %.4f, %.4f, %.4f]\n', c1, c2, c3, c4);
fprintf('------------------------------------------------\n');

disp('DSM parameters and coefficients initialized successfully.')

