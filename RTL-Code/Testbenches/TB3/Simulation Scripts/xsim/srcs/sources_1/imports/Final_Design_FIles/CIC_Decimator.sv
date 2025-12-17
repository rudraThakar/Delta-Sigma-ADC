`timescale 1ns/1ns

module CIC_Decimator #(
    parameter integer M          = 5,    // 5 Stages
    parameter integer IN_WIDTH   = 32,  
    parameter integer OUT_WIDTH  = 32,   
    parameter integer LOG2_MAX_R = 5     // log2(32) = 5 (Bit Growth)
)(
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      ce,               
    input  wire [15:0]               decimation_ratio,
    input  wire signed [IN_WIDTH-1:0] d_in,
    output reg  signed [OUT_WIDTH-1:0] d_out,
    output reg                       d_out_valid       
);

 
    // Bit Width Calculations
    
    // Gain = (R * Differential_Delay)^N = 32^5 = 2^25    
    localparam integer GROWTH = M * LOG2_MAX_R; // 25 bits
    localparam integer REG_W  = IN_WIDTH + GROWTH; // 32 + 25 = 57 bits


    // Integrator Section 

    reg signed [REG_W-1:0] integ1, integ2, integ3, integ4, integ5;
    
    always @(posedge clk) begin
        if (rst) begin
            integ1 <= {REG_W{1'b0}};
            integ2 <= {REG_W{1'b0}};
            integ3 <= {REG_W{1'b0}};
            integ4 <= {REG_W{1'b0}};
            integ5 <= {REG_W{1'b0}};
        end else if (ce) begin 
            integ1 <= integ1 + {{ (REG_W-IN_WIDTH){d_in[IN_WIDTH-1]} }, d_in};  // Sign extend to 57 bits
            integ2 <= integ2 + integ1;
            integ3 <= integ3 + integ2;
            integ4 <= integ4 + integ3;
            integ5 <= integ5 + integ4;
        end
    end


    // Decimation Generation
    
    reg [15:0] count;
    reg        v_comb; 
    reg signed [REG_W-1:0] d_tmp;           // Snapshot register

    always @(posedge clk) begin
        if (rst) begin
            count  <= 16'd0;
            v_comb <= 1'b0;
            d_tmp  <= {REG_W{1'b0}};
        end else if (ce) begin              // Valid input samples
            if (decimation_ratio != 16'd0 && count == decimation_ratio - 16'd1) begin
                count  <= 16'd0;
                d_tmp  <= integ5;           // Store last integrator
                v_comb <= 1'b1;  
            end else begin
                count  <= count + 16'd1;
                v_comb <= 1'b0;
            end
        end else begin
            v_comb <= 1'b0;                 
        end
    end


    // Comb Section 
    
    reg signed [REG_W-1:0] comb_d1, comb_d2, comb_d3, comb_d4, comb_d5;
    reg signed [REG_W-1:0] comb_y1, comb_y2, comb_y3, comb_y4, comb_y5;

    always @(posedge clk) begin
        if (rst) begin
            comb_d1 <= {REG_W{1'b0}}; comb_y1 <= {REG_W{1'b0}};
            comb_d2 <= {REG_W{1'b0}}; comb_y2 <= {REG_W{1'b0}};
            comb_d3 <= {REG_W{1'b0}}; comb_y3 <= {REG_W{1'b0}};
            comb_d4 <= {REG_W{1'b0}}; comb_y4 <= {REG_W{1'b0}};
            comb_d5 <= {REG_W{1'b0}}; comb_y5 <= {REG_W{1'b0}};
            d_out       <= {OUT_WIDTH{1'b0}};
            d_out_valid <= 1'b0;
        end else if (v_comb) begin
        
            // Stage 1 
            comb_y1 <= d_tmp - comb_d1;
            comb_d1 <= d_tmp;

            // Stage 2
            comb_y2 <= comb_y1 - comb_d2;
            comb_d2 <= comb_y1;

            // Stage 3
            comb_y3 <= comb_y2 - comb_d3;
            comb_d3 <= comb_y2;

            // Stage 4
            comb_y4 <= comb_y3 - comb_d4;
            comb_d4 <= comb_y3;

            // Stage 5
            comb_y5 <= comb_y4 - comb_d5;
            comb_d5 <= comb_y4;

 
            // Discard the lower GROWTH bits to achieve unity gain
            d_out <= comb_y5[REG_W-1 : REG_W - OUT_WIDTH] + comb_y5[REG_W - OUT_WIDTH-1];
            d_out_valid <= 1'b1;
        end else begin
            d_out_valid <= 1'b0;
        end
    end

endmodule