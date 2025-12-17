`timescale 1ns/1ps

module tb_top_module;

    // =========================================================================
    // 1. Configuration
    // =========================================================================
    parameter INPUT_WIDTH      = 32;
    parameter OUTPUT_WIDTH     = 32;
    parameter CLK_PERIOD       = 10; 
    parameter EXPECTED_DEC_FACTOR = 64;
    parameter TARGET_OUTPUTS   = 10; // How many outputs to verify before finishing

    // =========================================================================
    // 2. Signals
    // =========================================================================
    logic                      clk;
    logic                      rst;
    logic signed [INPUT_WIDTH-1:0] d_in;
    logic                      data_in_valid;
    wire signed [OUTPUT_WIDTH-1:0] d_out;
    wire                       data_out_valid;

    // Verification Counters
    integer total_inputs_sent;
    integer inputs_since_last_output;
    integer output_count;
    integer errors;

    // =========================================================================
    // 3. DUT Instantiation
    // =========================================================================
    top_module #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .OUTPUT_WIDTH(OUTPUT_WIDTH)
    ) dut (
        .clk            (clk),
        .rst            (rst),
        .d_in           (d_in),
        .data_in_valid  (data_in_valid),
        .d_out          (d_out),
        .data_out_valid (data_out_valid)
    );

    // =========================================================================
    // 4. Clock Generation
    // =========================================================================
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // =========================================================================
    // 5. Driver Process (Stimulus)
    // =========================================================================
    initial begin
        // --- Initialization ---
        rst = 1;
        d_in = 1000; // Constant DC input is sufficient for rate checking
        data_in_valid = 0;
        
        // --- Verbose Header ---
        $display("\n========================================================");
        $display("   DECIMATION FACTOR VERIFICATION TESTBENCH");
        $display("========================================================");
        $display("Target Decimation Factor: %0d", EXPECTED_DEC_FACTOR);
        $display("Checking for %0d consecutive correct outputs...", TARGET_OUTPUTS);
        $display("--------------------------------------------------------");

        // --- Reset Phase ---
        $display("[%0t ns] Status: Applying System Reset...", $time);
        #(10 * CLK_PERIOD);
        rst = 0;
        $display("[%0t ns] Status: Reset Released. Driving continuous valid inputs.", $time);

        // --- Driving Loop ---
        // We simply drive valid data forever. The Monitor block stops the test.
        forever begin
            @(posedge clk);
            d_in <= d_in + 1; // Vary data slightly just to be safe
            data_in_valid <= 1'b1;
        end
    end

    // =========================================================================
    // 6. Monitor & Checker Process (CORRECTED)
    // =========================================================================
    always @(posedge clk) begin
        if (rst) begin
            total_inputs_sent <= 0;
            inputs_since_last_output <= 0;
            output_count <= 0;
            errors <= 0;
        end 
        else if (data_in_valid) begin
            // Track total inputs
            total_inputs_sent <= total_inputs_sent + 1;

            if (data_out_valid) begin
                output_count <= output_count + 1;

                // --- CHECK LOGIC FIX ---
                // We add +1 to account for the input happening in the CURRENT cycle.
                // Counter (Past Inputs) + 1 (Current Input) = Total Period
                if (output_count > 0) begin
                    if ((inputs_since_last_output + 1) == EXPECTED_DEC_FACTOR) begin
                         // Green color code for PASS
                        $display("\033[32m[%0t ns] [PASS]  Output #%0d. Inputs: %0d + 1 (Current) = %0d. (MATCH)\033[0m", 
                                 $time, output_count, inputs_since_last_output, EXPECTED_DEC_FACTOR);
                    end else begin
                         // Red color code for FAIL
                        $display("\033[31m[%0t ns] [FAIL]  Output #%0d. Inputs: %0d + 1 = %0d. (EXPECTED: %0d)\033[0m", 
                                 $time, output_count, inputs_since_last_output, inputs_since_last_output + 1, EXPECTED_DEC_FACTOR);
                        errors <= errors + 1;
                    end
                end else begin
                     $display("[%0t ns] [INFO]  Pipeline Filled. First Output Received.", $time);
                end

                // Reset counter for the next batch
                inputs_since_last_output <= 0;
                
                // --- End of Test Condition ---
                if (output_count >= TARGET_OUTPUTS) begin
                    $display("--------------------------------------------------------");
                    if (errors == 0) 
                        $display("\033[32mRESULT: SUCCESS. Decimation factor verified as %0d.\033[0m", EXPECTED_DEC_FACTOR);
                    else 
                        $display("\033[31mRESULT: FAILED. Found %0d timing errors.\033[0m", errors);
                    $display("========================================================\n");
                    $stop;
                end
            end 
            else begin
                // Only increment if we didn't output this cycle
                inputs_since_last_output <= inputs_since_last_output + 1;
            end
        end
    end
endmodule