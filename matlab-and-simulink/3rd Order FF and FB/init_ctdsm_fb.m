% init_ctdsm.m  (corrected for installed dsmAdcFindCTcoeff signature)
modelName = 'ct3rdOrderFB';   %
order = 3;
OSR   = 64;
form  = 'FB';
fsVal = 128e3;    % sampling frequency you want in the model
optimFlag = 0;
OBG = 1.4;        % out-of-band gain (called OBG in your help text)
f0 = 0;           % center frequency (0 for low-pass)

% Call the function with the correct signature
try
    [a, g, b, c] = msblks.ADC.dsmAdcFindCTcoeff(order, OSR, form, optimFlag, OBG, f0);
catch ME
    error('Failed calling dsmAdcFindCTcoeff with signature (order,OSR,form,optimFlag,OBG,f0): %s', ME.message);
end

% Load model and write into model workspace
if ~bdIsLoaded(modelName)
    load_system(modelName);
end
mws = get_param(modelName,'ModelWorkspace');

mws.assignin('a', a);
mws.assignin('b', b);
mws.assignin('g', g);
mws.assignin('c', c);
mws.assignin('fs', fsVal);      
mws.assignin('DSM_order', order);
mws.assignin('DSM_OSR', OSR);

save_system(modelName);
fprintf('init_ctdsm: wrote fs=%g and coefficients to model workspace of %s\n', fsVal, modelName);
