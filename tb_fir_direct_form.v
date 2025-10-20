// tb_fir_direct_form.v
`timescale 1ns / 1ps

module tb_fir_direct_form;

    // Parameters
    parameter DATA_WIDTH = 16;
    parameter COEFF_WIDTH = 16;
    parameter COEFF_FRACTION_WIDTH = 15; // Q1.15 for coefficients

    // Signals
    reg clk;
    reg reset;
    reg signed [DATA_WIDTH-1:0] i_data;
    wire signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH + 1:0] o_data_sum;
    wire o_data_valid;

    // Clock Generation
    always #5 clk = ~clk; // 10ns period (100 MHz)

    // DUT Instantiation
    fir_4_tap_direct_form #(
        .DATA_WIDTH(DATA_WIDTH),
        .COEFF_WIDTH(COEFF_WIDTH),
        .COEFF_FRACTION_WIDTH(COEFF_FRACTION_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .i_data(i_data),
        .o_data_sum(o_data_sum),
        .o_data_valid(o_data_valid)
    );

    // Initial Block
    initial begin
        // Initialize signals
        clk = 1'b0;
        reset = 1'b1;
        i_data = 'd0;

        // Dump waves for GTKWave
        $dumpfile("fir_direct_form.vcd");
        $dumpvars(0, tb_fir_direct_form);

        // Apply reset
        #10 reset = 1'b0;

        // Test vectors
        // Coefficients: h0=0.125, h1=0.25, h2=0.25, h3=0.125
        // Expected output formula: y(n) = round(h0*x(n) + h1*x(n-1) + h2*x(n-2) + h3*x(n-3))
        // Note: The shifting (>>> COEFF_FRACTION_WIDTH) effectively converts the fractional part to integer.
        // So, for 0.125 * 100 = 12.5, after shifting, it becomes 12.
        // The test data below is designed to produce easily verifiable integer outputs.

        // Example:
        // Assume x(n) = 8
        // h0*x(n) = 0.125 * 8 = 1.0
        // h1*x(n-1) = 0.25 * x(n-1)
        // h2*x(n-2) = 0.25 * x(n-2)
        // h3*x(n-3) = 0.125 * x(n-3)

        // y(n) = 1*x(n) + 2*x(n-1) + 2*x(n-2) + 1*x(n-3)  (after shifting, simplified example for integer coefficients)
        // With current fractional coefficients, we need to consider the rounding/truncation.

        // Let's use simple integer inputs to verify.
        // h0=0.125, h1=0.25, h2=0.25, h3=0.125
        // All coefficients are effectively (value * 2^15) in the module.
        // So a multiplication by H0 is actually data * 4096.
        // Then, the result is shifted right by 15. So, (data * 4096) / 2^15 = data * 0.125 (effectively).

        // Step 1: Input 100
        #10 i_data = 16'd100;
        // x(n)=100, x(n-1)=0, x(n-2)=0, x(n-3)=0
        // y(n) = 0.125*100 = 12.5 -> truncates to 12
        // o_data_sum should be 12 (after a few cycles for pipeline/register update)

        // Step 2: Input 200
        #10 i_data = 16'd200;
        // x(n)=200, x(n-1)=100, x(n-2)=0, x(n-3)=0
        // y(n) = 0.125*200 + 0.25*100 = 25 + 25 = 50

        // Step 3: Input 300
        #10 i_data = 16'd300;
        // x(n)=300, x(n-1)=200, x(n-2)=100, x(n-3)=0
        // y(n) = 0.125*300 + 0.25*200 + 0.25*100 = 37.5 + 50 + 25 = 112.5 -> truncates to 112

        // Step 4: Input 400
        #10 i_data = 16'd400;
        // x(n)=400, x(n-1)=300, x(n-2)=200, x(n-3)=100
        // y(n) = 0.125*400 + 0.25*300 + 0.25*200 + 0.125*100
        //      = 50 + 75 + 50 + 12.5 = 187.5 -> truncates to 187

        // Step 5: Input 0
        #10 i_data = 16'd0;
        // x(n)=0, x(n-1)=400, x(n-2)=300, x(n-3)=200
        // y(n) = 0.125*0 + 0.25*400 + 0.25*300 + 0.125*200
        //      = 0 + 100 + 75 + 25 = 200

        #50 $finish;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (o_data_valid) begin
            $display("Time: %0t, Input: %0d, Output: %0d", $time, i_data, o_data_sum);
        end
    end

endmodule
