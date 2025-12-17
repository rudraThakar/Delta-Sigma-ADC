================================================================================
MODULE: top_module (Digital Filter Chain)
================================================================================

DESCRIPTION:
This module implements a multi-stage digital decimation filter chain. It processes
32-bit signed input data through a series of FIR and CIC filters to produce a 
filtered, decimated, and compensated 32-bit output.

TOTAL DECIMATION FACTOR: 64 (32 from CIC * 2 from Halfband)

================================================================================
HIERARCHICAL STRUCTURE
================================================================================

top_module (Parameters: INPUT_WIDTH=32, OUTPUT_WIDTH=32)
│
├── [1] lpf_inst (Universal_FIR)
│       ├── Function:     Initial Lowpass Filter
│       ├── Taps:         462
│       ├── Coefficients: FilterLib::COEFFS_LP
│       └── Output:       lpf_data_out (Pass-through rate)
│
├── [2] cic_inst (CIC_Decimator)
│       ├── Function:     Cascaded Integrator-Comb Decimator
│       ├── Decimation:   32 (Downsamples by 32)
│       ├── Order (M):    5
│       ├── Growth:       5 bits
│       └── Output:       cic_data_out 
│
├── [3] comp_inst (Universal_FIR)
│       ├── Function:     CIC Droop Compensator
│       ├── Taps:         15
│       ├── Coefficients: FilterLib::COEFFS_COMP
│       └── Output:       comp_data_out 
│
└── [4] hb_inst (Halfband)
        ├── Function:     Halfband Filter
        ├── Decimation:   2 (Downsamples by 2)
        ├── Taps:         14
        ├── Coefficients: FilterLib::COEFFS_HB
        └── Output:       hb_data_out 

================================================================================
DATA FLOW & OUTPUT LOGIC
================================================================================

1. Input Stage:
   - Receives 32-bit signed `d_in`.
   - Valid signal `data_in_valid` acts as clock enable for the first stage.

2. Processing Chain:
   [Input] -> LPF (FIR) -> [Decimate /32] -> CIC -> Compensator (FIR) -> 
   [Decimate /2] -> Halfband -> [Output Logic]

3. Output Stage (Bit Slicing):
   - The Halfband filter outputs a wide signal (64-bit) to preserve precision.
   - The final logic block truncates the output to 32 bits.
   - Assignment: d_out = hb_data_out[63:31] (Takes MSBs).

================================================================================
DEPENDENCIES
================================================================================
1. FilterLib (Package containing coefficients)
2. Universal_FIR.v
3. CIC_Decimator.v
4. Halfband.v



################################################################################
# 
# SIMULATION STEPS
#
# Please read the sections below to understand the steps required to
# run the exported script and how to fetch design source file details
# from the file_info.txt file.
#
################################################################################

1. Simulate Design

To simulate design, cd to the simulator directory and execute the script.

For example:-

% cd questa
% ./top.sh

The export simulation flow requires the AMD pre-compiled simulation library
components for the target simulator. These components are referred using the
'-lib_map_path' switch. If this switch is specified, then the export simulation
will automatically set this library path in the generated script and update,
copy the simulator setup file(s) in the exported directory.

If '-lib_map_path' is not specified, then the pre-compiled simulation library
information will not be included in the exported scripts and that may cause
simulation errors when running this script. Alternatively, you can provide the
library information using this switch while executing the generated script.

For example:-

% ./top.sh -lib_map_path /design/questa/clibs

Please refer to the generated script header 'Prerequisite' section for more details.

2. Directory Structure

By default, if the -directory switch is not specified, export_simulation will
create the following directory structure:-

<current_working_directory>/export_sim/<simulator>

For example, if the current working directory is /tmp/test, export_simulation
will create the following directory path:-

/tmp/test/export_sim/questa

If -directory switch is specified, export_simulation will create a simulator
sub-directory under the specified directory path.

For example, 'export_simulation -directory /tmp/test/my_test_area/func_sim'
command will create the following directory:-

/tmp/test/my_test_area/func_sim/questa

By default, if -simulator is not specified, export_simulation will create a
simulator sub-directory for each simulator and export the files for each simulator
in this sub-directory respectively.

IMPORTANT: Please note that the simulation library path must be specified manually
in the generated script for the respective simulator. Please refer to the generated
script header 'Prerequisite' section for more details.

3. Exported script and files

Export simulation will create the driver shell script, setup files and copy the
design sources in the output directory path.

By default, when the -script_name switch is not specified, export_simulation will
create the following script name:-

<simulation_top>.sh  (Unix)
When exporting the files for an IP using the -of_objects switch, export_simulation
will create the following script name:-

<ip-name>.sh  (Unix)
Export simulation will create the setup files for the target simulator specified
with the -simulator switch.

For example, if the target simulator is "xcelium", export_simulation will create the
'cds.lib', 'hdl.var' and design library diectories and mappings in the 'cds.lib'
file.



################################################################################
# 
# TESTBENCHES 
#
################################################################################

1. TB1

Checks the most basic code functionality, i.e, decimation factor and timing mismatch.
Fires a set of input samples at the model and checks for the final decimation factor.

2. TB2

Runs the decimation chain for the "Ideal" model's modulator output.
The output plots and results are attached in the final report. 

3. TB3

Runs the decimation chain for the "Non-Ideal" model's modulator output.
The output plots and results are attached in the final report. 