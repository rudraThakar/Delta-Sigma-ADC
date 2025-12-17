`timescale 1ns/1ns

module Halfband #(
    parameter integer DATA_WIDTH  = 32,
    parameter integer COEFF_WIDTH = 32, 
    parameter integer NUM_TAPS    = 14,  // Number of taps in the 'dense' branch (Branch 0)
    
    // Default 0.5 in Q14 (8192)
    parameter signed [COEFF_WIDTH-1:0] CENTER_COEFF = 16'sd8192,

    // Branch 0 Coefficients (Dense Branch)
    parameter logic signed [COEFF_WIDTH-1:0] COEFFS [0:NUM_TAPS-1] = '{default: '0}

)(
    input  wire                                     clk,
    input  wire                                     rst_n,
    input  wire                                     en,           // Global Enable
    input  wire signed [DATA_WIDTH-1:0]             data_in,
    input  wire                                     valid_in,
    output reg  signed [DATA_WIDTH+COEFF_WIDTH-1:0] data_out_lp, // Low Pass
    output reg  signed [DATA_WIDTH+COEFF_WIDTH-1:0] data_out_hp, // High Pass
    output reg                                      valid_out
);


    // Input Commutator
    
    reg phase_sel; // 0 = Even, 1 = Odd
    reg signed [DATA_WIDTH-1:0] samp_even;
    reg signed [DATA_WIDTH-1:0] samp_odd;
    reg pair_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_sel  <= 1'b0;
            samp_even  <= {DATA_WIDTH{1'b0}};
            samp_odd   <= {DATA_WIDTH{1'b0}};
            pair_ready <= 1'b0;
        end else if (en && valid_in) begin
            if (phase_sel == 1'b0) begin
                samp_even  <= data_in;
                pair_ready <= 1'b0;
                phase_sel  <= 1'b1;
            end else begin
                samp_odd   <= data_in;
                pair_ready <= 1'b1; // We have a pair (Even + Odd)
                phase_sel  <= 1'b0;
            end
        end else begin
            pair_ready <= 1'b0; 
        end
    end


    // Polyphase Branch 0 (Dense)
  
    integer i;
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] b0_acc [0:NUM_TAPS-1];
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] branch0_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<NUM_TAPS; i=i+1) b0_acc[i] <= {(DATA_WIDTH+COEFF_WIDTH){1'b0}};
            branch0_out <= {(DATA_WIDTH+COEFF_WIDTH){1'b0}};
        end else if (en && pair_ready) begin
            
            //Branch 0 Output
            b0_acc[0]   <= (samp_even * COEFFS[0]) + b0_acc[1];
            branch0_out <= (samp_even * COEFFS[0]) + b0_acc[1];
            
            // Middle Taps
            for (i=1; i < NUM_TAPS-1; i=i+1) begin
                b0_acc[i] <= (samp_even * COEFFS[i]) + b0_acc[i+1];
            end
            
            // Last Tap (Input only)
            b0_acc[NUM_TAPS-1] <= (samp_even * COEFFS[NUM_TAPS-1]);
        end
    end

 
    // Polyphase Branch 1 (Delay)
    
    localparam DELAY_CYCLES = NUM_TAPS / 2; 
    
    integer j;
    reg signed [DATA_WIDTH-1:0] delay_line [0:DELAY_CYCLES-1];
    reg signed [DATA_WIDTH+COEFF_WIDTH-1:0] branch1_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(j=0; j<DELAY_CYCLES; j=j+1) delay_line[j] <= {DATA_WIDTH{1'b0}};
            branch1_out <= {(DATA_WIDTH+COEFF_WIDTH){1'b0}};
        end else if (en && pair_ready) begin
            // Shift Register
            delay_line[0] <= samp_odd;
            for(j=1; j<DELAY_CYCLES; j=j+1) begin
                delay_line[j] <= delay_line[j-1];
            end
            
            // Apply Center Coefficient (Gain)
            branch1_out <= delay_line[DELAY_CYCLES-1] * CENTER_COEFF;
        end
    end

   
    // Output Recombination
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_lp <= {(DATA_WIDTH+COEFF_WIDTH){1'b0}};
            data_out_hp <= {(DATA_WIDTH+COEFF_WIDTH){1'b0}};
            valid_out   <= 1'b0;
        end else if (en) begin
            valid_out <= pair_ready; 
            if (pair_ready) begin
                data_out_lp <= branch0_out + branch1_out;
                data_out_hp <= branch0_out - branch1_out;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule