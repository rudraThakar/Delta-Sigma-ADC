`timescale 1ns/1ps

module tb_file_io_hex;

    parameter INPUT_WIDTH  = 32;
    parameter OUTPUT_WIDTH = 32;
    parameter CLK_PERIOD   = 10; 
    
    // File Paths
    parameter IN_FILE_NAME  = "input_hex.txt";    
    parameter OUT_FILE_NAME = "output_dec.txt";   
    parameter LPF_FILE_NAME = "lpf_debug_dec.txt"; // Internal LPF capture
    parameter CIC_FILE_NAME = "cic_debug_dec.txt"; // Internal CIC capture


    logic                      clk;
    logic                      rst;
    logic signed [INPUT_WIDTH-1:0] d_in;
    logic                      d_in_valid;
    wire signed [OUTPUT_WIDTH-1:0] d_out;
    wire                       d_out_valid;

    // File Handles
    integer f_in;
    integer f_out;
    integer f_lpf; 
    integer f_cic; 
    
    integer scan_status;
    reg [31:0] sample_val_raw; 


    top_module #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .clk            (clk),
        .rst            (rst),
        .d_in           (d_in),
        .data_in_valid  (d_in_valid),
        .d_out          (d_out),
        .data_out_valid (d_out_valid)
    );

  
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;


    initial begin
        f_out = $fopen(OUT_FILE_NAME, "w");
        if (f_out == 0) begin
            $display("Error: Could not open output file!");
            $stop;
        end
    end

    always @(posedge clk) begin
        if (d_out_valid) begin
            $fdisplay(f_out, "%d", d_out);
        end
    end


    initial begin
        f_lpf = $fopen(LPF_FILE_NAME, "w");
        if (f_lpf == 0) begin
            $display("Error: Could not open LPF debug file!");
            $stop;
        end
    end

    always @(posedge clk) begin
        
        if (dut.lpf_valid_out == 1'b1) begin 
            $fdisplay(f_lpf, "%d", $signed(dut.lpf_data_out)); 
        end
    end

  
    initial begin
        f_cic = $fopen(CIC_FILE_NAME, "w");
        if (f_cic == 0) begin
            $display("Error: Could not open CIC debug file!");
            $stop;
        end
    end

    always @(posedge clk) begin        
        if (dut.cic_valid_out == 1'b1) begin 
            $fdisplay(f_cic, "%d", $signed(dut.cic_data_out)); 
        end
    end


    initial begin
        f_in = $fopen(IN_FILE_NAME, "r");
        if (f_in == 0) begin
            $display("FATAL ERROR: Could not open %s.", IN_FILE_NAME);
            $stop;
        end

        // Reset Sequence
        rst = 1;
        d_in = 0;
        d_in_valid = 0;
        #(10 * CLK_PERIOD);
        
        rst = 0;
        #(10 * CLK_PERIOD);

        $display("Reading Hex file...");

        // Read Loop
        while (!$feof(f_in)) begin
            @(posedge clk);
            scan_status = $fscanf(f_in, "%h\n", sample_val_raw);
            
            if (scan_status == 1) begin
                if (DO_SIGN_EXTEND_16) begin
                    d_in <= {{16{sample_val_raw[15]}}, sample_val_raw[15:0]};
                end else begin
                    d_in <= sample_val_raw;
                end
                d_in_valid <= 1;
            end else begin
                d_in_valid <= 0;
            end
        end

        d_in_valid <= 0;
        $display("File read complete. Waiting for pipeline flush...");
        
        // Wait for filters to finish processing 
        repeat(5000) @(posedge clk);

        $display("Done.");
        
        // Close all files
        $fclose(f_in);
        $fclose(f_out);
        $fclose(f_lpf); // Fixed: Now closing LPF file
        $fclose(f_cic); // Fixed: Now closing CIC file
        
        $stop;
    end

endmodule