// tb_fir_hardware_share.v
`timescale 1ns / 1ps

module tb_fir_hardware_share;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter COEFF_WIDTH = 16;
    parameter COEFF_FRACTION_WIDTH = 15; // Q1.15 for coefficients

    // Signals
    reg clk;
    reg reset;
    reg signed [DATA_WIDTH-1:0] i_data;
    reg i_data_valid; // Input valid signal
    wire signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH + 1:0] o_data_sum;
    wire o_data_valid;

    // Clock Generation
    always #5 clk = ~clk; // 10ns period (100 MHz)

    // DUT Instantiation
    fir_4_tap_hardware_share #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .COEFF_FRACTION_WIDTH(COEFF_FRACTION_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .i_data(i_data),
        .i_data_valid(i_data_valid),
        .o_data_sum(o_data_sum),
        .o_data_valid(o_data_valid)
    );

    // Initial Block
    initial begin
        // Initialize signals
        clk = 1'b0;
        reset = 1'b1;
        i_data = 'd0;
        i_data_valid = 1'b0;

        // Dump waves for GTKWave
        $dumpfile("fir_hardware_share.vcd");
        $dumpvars(0, tb_fir_hardware_share);

        // Apply reset
        #10 reset = 1'b0;

        // Test vectors for hardware share (requires multiple clock cycles per output)
        // h0=0.125, h1=0.25, h2=0.25, h3=0.125

        // Cycle 0: IDLE
        #10; // First cycle after reset

        // Cycle 1: Input 100
        // State: IDLE -> LOAD_INPUT
        i_data = 16'd100;
        i_data_valid = 1'b1;
        #10; // clk edge, state becomes LOAD_INPUT

        // Cycle 2: MAC_0
        i_data_valid = 1'b0; // Input is processed, deassert valid for next cycle
        #10; // clk edge, state becomes MAC_0

        // Cycle 3: MAC_1
        #10; // clk edge, state becomes MAC_1

        // Cycle 4: MAC_2
        #10; // clk edge, state becomes MAC_2

        // Cycle 5: MAC_3
        #10; // clk edge, state becomes MAC_3

        // Cycle 6: OUTPUT_READY - Output for i_data=100 should be ready (Expected: 12)
        #10; // clk edge, state becomes OUTPUT_READY
        // At this point, o_data_sum should be 12.
        // It's the first actual output that has processed all taps.

        // Cycle 7: Input 200
        // State: OUTPUT_READY -> LOAD_INPUT
        i_data = 16'd200;
        i_data_valid = 1'b1;
        #10; // clk edge, state becomes LOAD_INPUT

        // Cycle 8: MAC_0
        i_data_valid = 1'b0;
        #10; // clk edge, state becomes MAC_0

        // Cycle 9: MAC_1
        #10; // clk edge, state becomes MAC_1

        // Cycle 10: MAC_2
        #10; // clk edge, state becomes MAC_2

        // Cycle 11: MAC_3
        #10; // clk edge, state becomes MAC_3

        // Cycle 12: OUTPUT_READY - Output for i_data=200 should be ready (Expected: 50)
        #10; // clk edge, state becomes OUTPUT_READY
        // At this point, o_data_sum should be 50.

        // Cycle 13: Input 300
        // State: OUTPUT_READY -> LOAD_INPUT
        i_data = 16'd300;
        i_data_valid = 1'b1;
        #10; // clk edge, state becomes LOAD_INPUT

        // Cycle 14: MAC_0
        i_data_valid = 1'b0;
        #10; // clk edge, state becomes MAC_0

        // Cycle 15: MAC_1
        #10; // clk edge, state becomes MAC_1

        // Cycle 16: MAC_2
        #10; // clk edge, state becomes MAC_2

        // Cycle 17: MAC_3
        #10; // clk edge, state becomes MAC_3

        // Cycle 18: OUTPUT_READY - Output for i_data=300 should be ready (Expected: 112)
        #10; // clk edge, state becomes OUTPUT_READY
        // At this point, o_data_sum should be 112.

        // Cycle 19: Input 400
        // State: OUTPUT_READY -> LOAD_INPUT
        i_data = 16'd400;
        i_data_valid = 1'b1;
        #10; // clk edge, state becomes LOAD_INPUT

        // Cycle 20: MAC_0
        i_data_valid = 1'b0;
        #10; // clk edge, state becomes MAC_0

        // Cycle 21: MAC_1
        #10; // clk edge, state becomes MAC_1

        // Cycle 22: MAC_2
        #10; // clk edge, state becomes MAC_2

        // Cycle 23: MAC_3
        #10; // clk edge, state becomes MAC_3

        // Cycle 24: OUTPUT_READY - Output for i_data=400 should be ready (Expected: 187)
        #10; // clk edge, state becomes OUTPUT_READY
        // At this point, o_data_sum should be 187.

        #50 $finish;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (o_data_valid) begin
            $display("Time: %0t, Input data for this output cycle (i_data when LOAD_INPUT state): %0d, Output: %0d", $time, dut.data_reg[0], o_data_sum);
        end
    end

endmodule
