
% CIC Filter Design Parameters

CIC_order  = 5;         % Number of integrator/comb sections
M          = 1;         % Differential delay
CIC_decim  = 32;        % Decimation factor
CIC_fs_in  = 128000;    % Input sampling frequency (Hz)
fs_lo      = CIC_fs_in / CIC_decim; % Output sampling frequency

% Compensator Design Parameters
comp_bits  = 12;        % Fixed-point coefficient bits
comp_order = 14;        % FIR order (L), must be even

% fir2 parameters
fc = CIC_fs_in / CIC_decim / 2;
Fo = CIC_decim * fc / CIC_fs_in;

% Generate CIC and compensation filter responses
p = 2e3;
s = 0.25 / p;
fpass = 0:s:Fo;
fstop = (Fo + s):s:0.5;

freq_grid = [fpass fstop] * 2;
freq_grid(end) = 1;

Mp = ones(1, length(fpass));
Mp(2:end) = abs(M * CIC_decim * sin(pi * fpass(2:end) / CIC_decim) ./ ...
                sin(pi * M * fpass(2:end))).^CIC_order;
Mf = [Mp zeros(1, length(fstop))];

h = fir2(comp_order, freq_grid, Mf);
h = h / max(h);

hz = round(h * 2^(comp_bits-1) - 1) / 2^(comp_bits-1);

% Commented diagnostic code
%{
freq_axis = linspace(0, 1, 4 * length(freq_grid));
f_lo = [freq_grid freq_grid+1 freq_grid+2 freq_grid+3];

CIC_H  = (CIC_decim^-CIC_order .* abs(CIC_decim * M * sin(pi * M * CIC_decim * freq_axis) ./ ...
        (pi * M * CIC_decim * freq_axis)).^CIC_order);
HH = (CIC_decim^-CIC_order .* abs(CIC_decim * M * sin(pi * M * freq_grid) ./ ...
        (pi * M * freq_grid)).^CIC_order);
HHH = (CIC_decim^-CIC_order .* abs(CIC_decim * M * sin(pi * M * f_lo) ./ ...
        (pi * M * f_lo)).^CIC_order);
H_comp = abs(fft(hz, length(freq_grid)));

figure('Name','CIC Frequency Response','NumberTitle','off');
subplot(2,1,1);
plot(freq_axis * CIC_fs_in, mag2db(abs(CIC_H)));
subplot(2,1,2);
plot(f_lo * fs_lo, mag2db(abs(HHH)));

figure('Name','CIC + Compensator','NumberTitle','off');
subplot(2,1,1);
plot(f_lo * fs_lo, mag2db(abs([HHH HHH*0+H_comp HHH .* (H_comp)])));
subplot(2,1,2);
plot(freq_grid * fs_lo, abs(HH)); hold on;
plot(freq_grid * fs_lo, abs(H_comp)); hold on;
plot(freq_grid * fs_lo, abs(HH .* H_comp)); grid on;

fprintf('\nFloating-point coefficients (h):\n[');
fprintf(' %.6f', h);
fprintf(' ]\n');
fprintf('\nFixed-point coefficients (hz):\n[');
fprintf(' %.6f', hz);
fprintf(' ]\n\n');
%}

