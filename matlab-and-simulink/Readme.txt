# Delta–Sigma ADC System Modelling and Architecture Analysis

This repository contains all Simulink models, scripts, and behavioural analysis files used for 
the design and evaluation of a 4th-order CRFF continuous-time Delta–Sigma modulator (CT-DSM) 
and related architectures. The work follows a complete modelling methodology that includes 
architecture exploration (DT, CT, Hybrid, MASH), noise analysis, non-ideality evaluation, and 
the final selection of the CRFF topology based on ENOB, stability, and robustness metrics.

All files correspond to the modelling experiments and architecture studies referenced in the project report.

---

## MATLAB Version and Toolbox Requirements

The models in this repository have been tested and verified to work with:

- **MATLAB R2025b** (primary)
- **MATLAB R2025a** (fully compatible)

Required toolboxes:

- **DSP System Toolbox**
- **Simulink**
- **Sigma-Delta Toolbox** (for NTF/STF generation and analysis)
- **HDL Coder / HDL Support Packages** (for verification of the digital decimation filter)
---

## Folder Overview

### **MASH/**
Contains Simulink models and scripts for multi-stage noise-shaping (MASH) Delta–Sigma modulators. 
Includes 2-1 and 1-1-1 structures, noise-cancellation behaviour, pole–zero analysis, and ENOB 
results used to justify the non-selection of MASH for this design.

### **4th Order CRFF/**
This is the main folder for the selected architecture.  
Includes the complete behavioural model of the 4th-order CRFF CT-DSM, NTF/STF plots, 
ENOB–amplitude and ENOB–frequency sweeps, 3-D ENOB performance surfaces, and robustness 
evaluations such as jitter and excess-loop-delay analysis. All parameters used for the final design 
are contained here.

### **3rd Order FF and FB/**
Contains reference models for CIFF, CIFB, and classical FF/FB continuous-time structures.  
These files were used to evaluate pole–zero stability, internal swing, and ELD sensitivity during the 
architecture-elimination phase prior to selecting the CRFF topology.

### **ModelAContinuoustimeDSMExample/**
A baseline continuous-time DSM example used to validate the modelling framework, test quantizer 
and DAC feedback behaviour, and confirm numerical consistency before building the final architecture.

---

## Summary

Together, these folders document the complete exploration process, behavioural simulations, and 
design decisions leading to the selection of a 4th-order CRFF modulator for a 20-bit, low-bandwidth 
(0.5–2 ksps) Delta–Sigma ADC system.  
Each subfolder includes its own README with detailed file descriptions and usage instructions.
