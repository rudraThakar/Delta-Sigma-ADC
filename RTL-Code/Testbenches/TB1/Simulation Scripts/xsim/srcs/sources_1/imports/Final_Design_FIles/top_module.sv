`timescale 1ns/1ns

import FilterLib::*; 

module top_module #(
    parameter integer INPUT_WIDTH  = 32,
    parameter integer OUTPUT_WIDTH = 32
)(
    input  wire                      clk,
    input  wire                      rst,           // Active High System Reset
    input  wire signed [INPUT_WIDTH-1:0] d_in,
    input  wire                      data_in_valid, 
    output reg  signed [OUTPUT_WIDTH-1:0] d_out,
    output reg                       data_out_valid
);
    

    // LPF -> CIC
    wire signed [31:0] lpf_data_out;
    wire               lpf_valid_out; 
    
    // CIC -> Compensator
    wire signed [31:0] cic_data_out;
    wire               cic_valid_out; 

    // Compensator -> Halfband
    wire signed [31:0] comp_data_out;
    wire               comp_valid_out;

    // Halfband -> Output Logic
    wire signed [63:0] hb_data_out; 
    wire               hb_valid_out;


    // 1. FIR Lowpass 
    
    localparam LPF_TAPS = 462; 
    
    Universal_FIR #(
        .IN_WIDTH       (INPUT_WIDTH),
        .OUT_WIDTH      (OUTPUT_WIDTH),
        .COEFF_W        (16),
        .NUM_TAPS       (LPF_TAPS),
        .COEFFS         (FilterLib::COEFFS_LP) 
    ) lpf_inst (
        .clk            (clk), 
        .rst            (rst),            // Active High
        .ce             (data_in_valid),    
        .d_in           (d_in),
        .d_out          (lpf_data_out), 
        .d_valid        (lpf_valid_out)   
    );
    
//    Lowpass #(
//        .IN_WIDTH       (INPUT_WIDTH),
//        .OUT_WIDTH      (OUTPUT_WIDTH),
//        .COEFF_W        (16),
//        .NUM_TAPS       (LPF_TAPS),
//        .COEFFS         (FilterLib::COEFFS_LP) 
//    ) lpf_inst (
//        .clk            (clk), 
//        .rst            (rst),            // Active High
//        .ce             (data_in_valid),    
//        .d_in           (d_in),
//        .d_out          (lpf_data_out), 
//        .d_valid        (lpf_valid_out)
//    );


    // 2. CIC Decimator (Decimate by 32)  
    
    localparam CIC_ORDER = 5;
    localparam CIC_GROWTH = 5;
    
    CIC_Decimator #(
        .M              (CIC_ORDER),
        .IN_WIDTH       (INPUT_WIDTH),
        .OUT_WIDTH      (OUTPUT_WIDTH),
        .LOG2_MAX_R     (CIC_GROWTH)
    ) cic_inst (
        .clk            (clk),
        .rst            (rst),             // Active High
        .decimation_ratio(16'd32),         
        .d_in           (lpf_data_out),
        .ce             (lpf_valid_out), 
        .d_out          (cic_data_out),
        .d_out_valid    (cic_valid_out)    
    );       
    

    // 3. FIR Compensator
    
    localparam COMP_TAPS = 15;
    
    Universal_FIR #(
        .IN_WIDTH       (INPUT_WIDTH),
        .OUT_WIDTH      (OUTPUT_WIDTH),
        .COEFF_W        (16),
        .NUM_TAPS       (COMP_TAPS),
        .COEFFS         (FilterLib::COEFFS_COMP)
    ) comp_inst (
        .clk            (clk), 
        .rst            (rst),              // Active High
        .ce             (cic_valid_out), 
        .d_in           (cic_data_out),
        .d_out          (comp_data_out), 
        .d_valid        (comp_valid_out)    
    );


    // 4. Halfband Filter (Decimate by 2)
    
    localparam HB_TAPS = 14;     
    Halfband #(
        .DATA_WIDTH     (INPUT_WIDTH),
        .COEFF_WIDTH    (32),        // FIX: Match FilterLib array width (32-bit)
        .NUM_TAPS       (HB_TAPS),
        .COEFFS         (FilterLib::COEFFS_HB) 
    ) hb_inst (
        .clk            (clk),
        .rst_n          (~rst),            // Active Low
        .en             (1'b1),
        .data_in        (comp_data_out),
        .valid_in       (comp_valid_out),
        .data_out_lp    (hb_data_out), 
        .data_out_hp    (),                 // Unused
        .valid_out      (hb_valid_out)
    );
        


    // 5. Output Logic

    always @(posedge clk) begin
        if (rst) begin
            d_out          <= 0;
            data_out_valid <= 1'b0;
        end else begin
            data_out_valid <= 1'b0; // Default low
            
            if (hb_valid_out) begin
                d_out <= hb_data_out[63:31];                 
                data_out_valid <= 1'b1;
            end
        end
    end

endmodule