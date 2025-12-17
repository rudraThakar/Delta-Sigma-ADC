% init_ctdsm_ff.m  – Initialization script for ct3rdOrderFF (Feed-Forward Model)

modelName = 'ct3rdOrderFF';     % FF model name (without .slx)

order = 3;          % 3rd order CT DSM
OSR   = 256;         % Oversampling ratio
form  = 'FF';       % FEED-FORWARD architecture
fsVal = 512e3;      % Sampling frequency in Hz
optimFlag = 0;      % No NTF optimization
Hinf = 1.4;         % Infinity norm / out-of-band gain limit
f0 = 0;             % Low-pass system

try
    % Feed-forward uses aff, gff, bff, cff
    [aff, gff, bff, cff] = msblks.ADC.dsmAdcFindCTcoeff( ...
                                order, OSR, form, optimFlag, Hinf, f0);
catch ME
    error(['Failed calling dsmAdcFindCTcoeff for Feed-Forward topology:' newline ME.message]);
end

if ~bdIsLoaded(modelName)
    load_system(modelName);
end

mws = get_param(modelName, 'ModelWorkspace');

mws.assignin('aff', aff);
mws.assignin('gff', gff);
mws.assignin('bff', bff);
mws.assignin('cff', cff);
mws.assignin('fs',  fsVal);
mws.assignin('DSM_order', order);
mws.assignin('DSM_OSR',   OSR);

save_system(modelName);

fprintf('init_ctdsm_ff: coefficients + fs written to model workspace of %s\n', modelName);
