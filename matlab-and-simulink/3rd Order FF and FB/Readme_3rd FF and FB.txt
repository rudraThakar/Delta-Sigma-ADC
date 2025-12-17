# 3rd Order FF and FB — Continuous-Time DSM Topology Exploration

This folder contains behavioural Simulink models and supporting MATLAB scripts used to study 
3rd-order feedforward (FF) and feedback (FB) continuous-time Delta–Sigma modulator topologies. 
These models form an intermediate analysis step in comparing classical 3rd-order structures 
before moving to the final 4th-order CRFF architecture adopted in the project.

---

## Contents

### • init_ctdsm_ff.m
Initializes coefficients and simulation parameters for the 3rd-order feedforward 
(FF) CT DSM model. This script must be run before opening or simulating 
`ctdsm_3OrderFF.slx`.

### • init_ctdsm_fb.m
Initializes coefficients and simulation parameters for the 3rd-order feedback 
(FB) CT DSM model. Must be run before simulating `ctdsm_3OrderFB.slx`.

### • ctdsm_3OrderFF.slx
Simulink model for the 3rd-order feedforward topology. Used to evaluate 
noise-shaping behaviour, internal swing, stability, and sensitivity 
to non-idealities.

### • ctdsm_3OrderFB.slx
Simulink model for the 3rd-order feedback topology. Useful for comparing 
loop dynamics, zero placement, and integrator stress relative to the FF design.

### • calibrate_DSM_gains.m
An alternative gain-tuning script that automatically adjusts loop coefficients. 
While this method produced ENOB values approaching 20 bits, its optimisation was 
narrow-band and did not yield consistent performance across the entire sampling 
bandwidth, and was therefore not used in the final architecture selection.

### • Readme_3rd FF and FB.txt
Early notes and scratch documentation retained for completeness.

---

## Purpose of These Models

These 3rd-order FF/FB implementations were used to understand baseline 
continuous-time DSM behaviour, compare structural advantages and weaknesses, 
and verify simulation methodology prior to moving to higher-order resonator-based 
designs. The observations from these models helped motivate the transition to 
the 4th-order CRFF architecture, which offered improved robustness, tunability, 
and noise-shaping performance.

---

## How to Use

1. Open MATLAB and navigate to this folder.
2. Run the corresponding initialization script:
   - `init_ctdsm_ff.m` → for `ctdsm_3OrderFF.slx`
   - `init_ctdsm_fb.m` → for `ctdsm_3OrderFB.slx`
3. Open the Simulink model and run simulations as needed.
4. Inspect NTF/STF behaviour, internal node waveforms, stability, and ENOB.

---

## Notes
- These models do not include resonator (CRFF/CRFB) structures; they represent 
  classical 3rd-order FF and FB loops only.
- Simulation environment requirements (MATLAB version, toolboxes) are documented 
  in the main project README.
