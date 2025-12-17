# Zoom ADC — Coarse–Fine Conversion Architecture

This folder contains an exploratory Simulink model of a Zoom ADC, a hybrid architecture 
that combines a coarse SAR conversion stage with a fine Delta–Sigma residue modulator. 
Zoom ADCs are widely used in high-resolution, near-20-ENOB data converters because they 
reduce the dynamic-range burden on the sigma–delta loop and enable aggressive noise 
shaping with lower OSR and lower power consumption.

---

## Model Overview

The Simulink diagram implements the core functional blocks of a Zoom ADC:

- **SAR ADC Section**  
  Performs a coarse quantization of the input signal. The resulting SAR output is used 
  to generate a residue for the fine loop.

- **Fine ΔΣ Modulator**  
  A feedback-based continuous-time modulator processes only the residue, allowing the 
  loop to operate over a much smaller input range with reduced overload risk.

- **DAC Feedback Paths**  
  Multiple DAC elements reconstruct the SAR decision, apply signed residue contributions, 
  and feed the combined signal into the fine modulator.

- **Decimation Chain**  
  A multistage FIR and downsampling chain that converts the high-rate modulator output 
  into a low-rate digital word.

The model captures the architectural flow of a Zoom converter but remains a 
**preliminary/underdeveloped implementation**, created primarily for understanding system 
partitioning rather than for full performance evaluation.

---

## Purpose in the Project

Zoom ADCs represent a high-performance class of converters frequently used to achieve 
near-20-bit resolution in modern precision applications. The development of simpler 
architectures such as CT-DSMs and DT-DSMs historically enabled the evolution of hybrid 
structures like the Zoom ADC.

In this project, this model was used to:

- study the coarse–fine interaction between SAR and ΔΣ stages,  
- understand residue computation and timing alignment,  
- examine DAC path structure and decimation requirements,  
- contextualize why a single-loop CRFF CT-DSM was ultimately chosen for implementation.

This exploration provides conceptual grounding but is **not** the final architecture 
selected for the system.

---

## Notes
- This model is not fully optimized; several blocks are placeholders for future 
  refinement (e.g., calibration, DAC linearity, timing alignment).  
- It serves educational and exploratory purposes rather than complete behavioural 
  validation.

