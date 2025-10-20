// fir_4_tap_direct_form.

// NAMA : WILLIAM ANTHONY
// NIM  : 13223048


module fir_4_tap_direct_form #(
    parameter DATA_WIDTH = 16,
    parameter COEFF_WIDTH = 16,
    parameter COEFF_FRACTION_WIDTH = 15 // Untuk representasi Q1.15
) (
    input wire clk,
    input wire reset,
    input wire signed [DATA_WIDTH-1:0] i_data,
    output wire signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH + 1:0] o_data_sum, // Lebar output untuk mencegah overflow
    output wire o_data_valid
);

    // Koefisien filter (contoh, Anda bisa mengubahnya sesuai kebutuhan)
    // Untuk representasi Q1.15, 0.5 = 16'h4000, 0.25 = 16'h2000
    // Pastikan koefisien adalah signed
    localparam signed [COEFF_WIDTH-1:0] H0 = 16'h1000; // Contoh: 0.125
    localparam signed [COEFF_WIDTH-1:0] H1 = 16'h2000; // Contoh: 0.25
    localparam signed [COEFF_WIDTH-1:0] H2 = 16'h2000; // Contoh: 0.25
    localparam signed [COEFF_WIDTH-1:0] H3 = 16'h1000; // Contoh: 0.125

    // Register untuk menunda input
    reg signed [DATA_WIDTH-1:0] data_reg [3:0]; // x(n), x(n-1), x(n-2), x(n-3)

    // Output dari setiap perkalian
    wire signed [DATA_WIDTH + COEFF_WIDTH -1:0] mul0_out;
    wire signed [DATA_WIDTH + COEFF_WIDTH -1:0] mul1_out;
    wire signed [DATA_WIDTH + COEFF_WIDTH -1:0] mul2_out;
    wire signed [DATA_WIDTH + COEFF_WIDTH -1:0] mul3_out;

    // Output dari penjumlahan
    wire signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH:0] add0_out; // Sum of two products
    wire signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH + 1:0] add1_out; // Sum of three products
    // o_data_sum akan menampung hasil akhir dari penjumlahan 4 produk

    // Register untuk validasi data output
    reg data_valid_reg;

    assign o_data_valid = data_valid_reg;

    // Penggeseran register input pada setiap tepi clock
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_reg[0] <= 'd0;
            data_reg[1] <= 'd0;
            data_reg[2] <= 'd0;
            data_reg[3] <= 'd0;
            data_valid_reg <= 1'b0;
        end else begin
            data_reg[3] <= data_reg[2];
            data_reg[2] <= data_reg[1];
            data_reg[1] <= data_reg[0];
            data_reg[0] <= i_data;
            data_valid_reg <= 1'b1; // Data output valid setelah N tap delay terisi
        end
    end

    // Perkalian untuk setiap tap
    assign mul0_out = data_reg[0] * H0;
    assign mul1_out = data_reg[1] * H1;
    assign mul2_out = data_reg[2] * H2;
    assign mul3_out = data_reg[3] * H3;

    // Penjumlahan (struktur pohon penjumlah untuk Direct Form)
    // Perhatikan bahwa setiap penjumlahan dapat menambah 1 bit ke lebar data untuk menghindari overflow
    assign add0_out = (mul0_out >>> COEFF_FRACTION_WIDTH) + (mul1_out >>> COEFF_FRACTION_WIDTH);
    assign add1_out = add0_out + (mul2_out >>> COEFF_FRACTION_WIDTH);
    assign o_data_sum = add1_out + (mul3_out >>> COEFF_FRACTION_WIDTH);

endmodule


// cd D:\FIR_Filter
// iverilog -o fir_direct_form.vvp fir_4_tap_direct_form.v tb_fir_direct_form.v
// vvp fir_direct_form.vvp
// gtkwave fir_direct_form.vcd
