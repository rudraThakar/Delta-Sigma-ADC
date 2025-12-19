## Delta-Sigma ADC ASIC development

# Sigma-Delta ADC Design and Implementation

This repository contains the complete design flow of a **Sigma-Delta Analog-to-Digital Converter (ΣΔ ADC)**, starting from system-level modeling to RTL implementation and post-synthesis evaluation. The project focuses on achieving high-resolution, low-frequency data conversion using a carefully designed modulator and an efficient digital decimation filter chain.

---

## Project Overview

- **ADC Architecture**: 4th-order CRFF (Cascade of Resonators with Feed-Forward) Sigma-Delta Modulator  
- **Modulator Sampling Frequency**: 128 kHz  
- **Target Output Data Rate**: 1–4 kSPS (after decimation)  
- **Digital Decimation Factor**: 64  
- **Implementation Focus**: Algorithm-to-RTL flow with hardware-efficient digital filters

![Alt text](relative/path/to/image)

The design was iteratively developed by exploring multiple Sigma-Delta architectures before converging on a final, optimized solution.


## Repository Structure


---

## 1. matlab and simulink models

This directory contains all **system-level models** developed during the exploration and design phase.

### Contents
- Experimental and reference models:
  - 3rd-order Continuous-Time Sigma-Delta Modulator (CTDSM)
  - Discrete-Time Sigma-Delta Modulator (DTDSM)
  - Zoom ADC
  - MASH (Multi-stage Noise Shaping) ADC
- **Final Model**:
  - 4th-order CRFF Sigma-Delta Modulator
  - Complete digital filter chain connected to the modulator

### Purpose
- Evaluate different Sigma-Delta architectures in terms of noise shaping, stability, and ENOB
- Validate design choices such as modulator order, OSR, and quantizer resolution
- Perform frequency-domain and time-domain analysis before RTL implementation

---

## 2. RTL Code

This directory contains the **SystemVerilog RTL implementation** of the digital back-end of the ADC.

### Implemented Digital Filter Chain
1. **5th-order CIC Decimator**
   - Decimation factor: 32  
   - Multiplier-less architecture using only adders and registers  
   - Provides major rate reduction

2. **CIC Compensation Filter**
   - FIR-based filter
   - Compensates for passband droop introduced by the CIC filter

3. **Halfband Filter**
   - Decimation factor: 2  
   - Improves stopband attenuation
   - Hardware-efficient due to symmetric coefficients and zero-valued taps

### Purpose
- Translate the validated MATLAB filter models into synthesizable RTL
- Ensure bit-growth handling, fixed-point correctness, and timing feasibility
- Enable seamless integration with the Sigma-Delta modulator output

---

## 3. post synthesis results

This directory contains the **results obtained after RTL synthesis** of the digital filter chain.

### Tool and Technology Details
- **Synthesis Tool**: Synopsys Design Compiler  
- **Technology Node**: SCL 180 nm PDK  

### Contents
- Synthesized gate-level netlist
- Power reports
- Area utilization reports
- Timing analysis reports

### Purpose
- Evaluate the hardware cost of the proposed digital filter architecture
- Verify that the design meets power, area, and timing constraints
- Assess suitability for real silicon implementation

---

## Key Highlights

- Systematic comparison of multiple Sigma-Delta ADC architectures
- Final selection of a **4th-order CRFF modulator** for performance and simplicity
- Hardware-efficient digital decimation using CIC-based filtering
- Complete algorithm-to-RTL-to-synthesis design flow
- Technology-aware synthesis using an industry-standard PDK and EDA tool

---


