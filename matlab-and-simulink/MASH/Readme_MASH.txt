# MASH — Multi-Stage Noise-Shaping Models

This folder contains two Simulink models used to study the behaviour of 
MASH (Multi-Stage Noise-Shaping) Delta–Sigma architectures and to compare 
their performance with common loop-filter topologies such as CIFF, CIFB, 
CRFF, and CRFB. These models were used primarily for understanding 
noise-cancellation principles and structural differences, rather than for 
final architecture selection.

---

## File Overview

### **MASH_Derived.slx**
A higher-level Simulink implementation that compares derived MASH structures 
against standard loop-filter forms (CIFF, CIFB, CRFB, CRFF).  
Useful for observing:
- noise-cancellation effectiveness,  
- residual tone behaviour,  
- stability differences across architectures.

This model relies on Simulink blocks and is well suited for architectural comparison.

### **MASH.slx**
A lower-level, more fundamental implementation of a MASH modulator.  
This version was created for conceptual understanding of:
- interstage residue generation,  
- noise transfer behaviour,  
- digital noise-cancellation logic.

It is not intended as a high-performance or optimized MASH design, but rather 
as a learning and validation model.

---

## Notes
- These models were exploratory and were not used for the final Delta–Sigma 
  architecture, since the project adopted a single-loop 4th-order CRFF design.
- The purpose of this folder is educational: to illustrate how MASH structures 
  operate and why they were not chosen for the final implementation.
