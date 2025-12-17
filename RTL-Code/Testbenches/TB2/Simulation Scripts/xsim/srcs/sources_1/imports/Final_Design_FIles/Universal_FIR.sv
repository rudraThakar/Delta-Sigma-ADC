`timescale 1ns/1ns

module Universal_FIR #(
    parameter integer IN_WIDTH  = 32,
    parameter integer COEFF_W   = 16,
    parameter integer OUT_WIDTH = 32,    
    parameter integer NUM_TAPS  = 462,
    parameter signed [COEFF_W-1:0] COEFFS [0 : (NUM_TAPS + 1)/2 - 1] = '{default:0}
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      ce,
    input  wire signed [IN_WIDTH-1:0] d_in,
    output reg signed [OUT_WIDTH-1:0] d_out,
    output reg                        d_valid
    //output reg                        round_bit;
);

    localparam NUM_PAIRS = NUM_TAPS / 2;
    localparam IS_ODD    = NUM_TAPS % 2;
    localparam NUM_UNIQUE_COEFFS = NUM_PAIRS + IS_ODD;
    localparam signed [63:0] SAT_MAX =  (1 <<< (OUT_WIDTH-1)) - 1;
    localparam signed [63:0] SAT_MIN = -(1 <<< (OUT_WIDTH-1));

    localparam signed [63:0] ROUND_CONST = 64'sd8192; 
    
    
    reg signed [IN_WIDTH-1:0] tap [0:NUM_TAPS-1];
    integer k;

    always @(posedge clk) begin
        if (rst) begin
            for (k=0; k<NUM_TAPS; k=k+1) tap[k] <= {IN_WIDTH{1'b0}};
        end else if (ce) begin
            tap[0] <= d_in;
            for (k=1; k<NUM_TAPS; k=k+1) tap[k] <= tap[k-1];
        end
    end


    reg signed [IN_WIDTH:0]   sum_r    [0:NUM_PAIRS-1];
    reg signed [IN_WIDTH-1:0] center_r; 
    reg ce_stage1;
    
    genvar i;
    generate
        for (i=0; i<NUM_PAIRS; i=i+1) begin : PAIR_ADD_LOOP
            always @(posedge clk) begin
                if (rst) sum_r[i] <= 0;
                else if (ce) begin
                    sum_r[i] <= tap[i] + tap[NUM_TAPS - 1 - i];
                end
            end
        end

        if (IS_ODD == 1) begin : CENTER_TAP_LOGIC
            always @(posedge clk) begin
                if (rst) center_r <= 0;
                else if (ce) center_r <= tap[NUM_PAIRS]; 
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) ce_stage1 <= 1'b0;
        else      ce_stage1 <= ce;
    end



    reg signed [IN_WIDTH+COEFF_W:0] mult_r [0:NUM_UNIQUE_COEFFS-1];
    reg ce_stage2;

    generate
        for (i=0; i<NUM_PAIRS; i=i+1) begin : MULT_PAIR_LOOP
            always @(posedge clk) begin
                if (rst) mult_r[i] <= 0;
                else if (ce_stage1) mult_r[i] <= sum_r[i] * COEFFS[i];
            end
        end

        if (IS_ODD == 1) begin : MULT_CENTER_LOOP
            always @(posedge clk) begin
                if (rst) mult_r[NUM_PAIRS] <= 0;
                else if (ce_stage1) begin
                    mult_r[NUM_PAIRS] <= center_r * COEFFS[NUM_PAIRS];
                end
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) ce_stage2 <= 1'b0;
        else      ce_stage2 <= ce_stage1;
    end



    reg signed [63:0] acc_r;
    reg ce_stage3;
    reg signed [63:0] comb_sum; 
    integer j;

    always @(*) begin
        comb_sum = 64'd0;
        for (j=0; j<NUM_UNIQUE_COEFFS; j=j+1) begin
            comb_sum = comb_sum + mult_r[j];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            acc_r <= 64'b0;
            ce_stage3 <= 1'b0;
        end else if (ce_stage2) begin
            acc_r <= comb_sum; 
            ce_stage3 <= 1'b1;
        end else begin
            ce_stage3 <= 1'b0;
        end
    end
    
    
    
    wire signed [63:0] acc_rounded = acc_r + ROUND_CONST;
    
    always @(posedge clk) begin
        if (rst) begin
            d_out   <= {OUT_WIDTH{1'b0}};
            d_valid <= 1'b0;
        end else if (ce_stage3) begin
            if (acc_rounded > SAT_MAX) d_out <= 32'sh7FFFFFFF;
            else if (acc_rounded < SAT_MIN) d_out <= 32'sh80000000;
            else d_out <= acc_rounded[14 + OUT_WIDTH - 1 : 14];
            d_valid <= 1'b1;
        end else begin
            d_valid <= 1'b0;
        end
    end

endmodule