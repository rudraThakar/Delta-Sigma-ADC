# 4th Order CRFF — Final Continuous-Time DSM Architecture

This folder contains the complete behavioural implementation of the final, 
validated 4th-order CRFF continuous-time Delta–Sigma modulator. This is the 
primary model used for all wideband ENOB analysis, non-ideality studies, and 
performance verification presented in the project report.

---

## How to Run

1. Open MATLAB and navigate to this folder.
2. Run **init.m** to load all modulator parameters, filter-chain coefficients, 
   and gain values.
3. Open and simulate either:
   - **Ideal.slx** — modulator without any non-idealities.
   - **Non_ideal.slx** — modulator including flicker noise, thermal noise, jitter, 
     finite OTA bandwidth, slew-rate limits, saturation, and excess-loop delay.

After simulation, SNR and ENOB may be evaluated by running:

- **SNR_postModulator.m** — computes SNR/ENOB at the modulator output.  
- **SNR_postFilter.m** — computes SNR/ENOB after the full decimation chain.

---

## File Overview

### **init.m**
Initializes all parameters for both Simulink models:
- OSR, sampling rate, quantizer resolution  
- CRFF loop-filter coefficients  
- Feedforward and resonator gains  
- CIC, halfband, and FIR filter-chain coefficients  
All filter-related scripts are executed automatically.

### **Ideal.slx**
Behavioural model of the CRFF modulator without any noise or circuit non-idealities.

### **Non_ideal.slx**
Full model including jitter, finite GBW, loop delay, flicker noise, thermal noise, 
saturation, slew-rate limitation, and DAC non-idealities.

### **fir_coeff.m, fir_halfband_coeff.m, cic_comp_coeff_calc.m**
Scripts used by `init.m` to compute FIR, halfband, and CIC compensator coefficients.

### **gain_calculate.m**
Computes feedforward and resonator gains for the CRFF modulator.

### **CIFF_Opt_4th_Order_2.m**
Auxiliary script used for reference coefficient generation and comparative analysis.

### **SNR_postModulator.m** / **SNR_postFilter.m**
Post-processing tools for computing **SNR** and **ENOB** from simulation outputs.

---

## Notes
- This folder contains the final, most robust CRFF implementation used for all 
  performance plots (ENOB vs amplitude, ENOB vs frequency, and 3-D ENOB surfaces).  
- All supporting scripts are automatically called within `init.m`; no manual 
  parameter editing is required.

