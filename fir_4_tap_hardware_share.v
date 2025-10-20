// fir_4_tap_hardware_share.v

// NAMA : WILLIAM ANTHONY
// NIM  : 13223048

module fir_4_tap_hardware_share #(
    parameter DATA_WIDTH = 16,
    parameter COEFF_WIDTH = 16,
    parameter COEFF_FRACTION_WIDTH = 15 // Untuk representasi Q1.15
) (
    input wire clk,
    input wire reset,
    input wire signed [DATA_WIDTH-1:0] i_data,
    input wire i_data_valid, // Sinyal validasi untuk input data
    output wire signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH + 1:0] o_data_sum, // Lebar output untuk mencegah overflow
    output wire o_data_valid
);

    // Koefisien filter (contoh, Anda bisa mengubahnya sesuai kebutuhan)
    // Untuk representasi Q1.15, 0.5 = 16'h4000, 0.25 = 16'h2000
    // Menggunakan localparam terpisah karena array literal tidak didukung secara universal untuk localparam di Icarus Verilog
    localparam signed [COEFF_WIDTH-1:0] H0_VAL = 16'h1000; // h0 = 0.125
    localparam signed [COEFF_WIDTH-1:0] H1_VAL = 16'h2000; // h1 = 0.25
    localparam signed [COEFF_WIDTH-1:0] H2_VAL = 16'h2000; // h2 = 0.25
    localparam signed [COEFF_WIDTH-1:0] H3_VAL = 16'h1000; // h3 = 0.125

    // FSM States (menggunakan localparam untuk kompatibilitas Verilog murni)
    localparam [2:0]
        IDLE         = 3'b000,
        LOAD_INPUT   = 3'b001,
        MAC_0        = 3'b010,
        MAC_1        = 3'b011,
        MAC_2        = 3'b100,
        MAC_3        = 3'b101,
        OUTPUT_READY = 3'b110;

    reg [2:0] current_state, next_state; // Menggunakan reg untuk state

    // Register untuk menunda input
    reg signed [DATA_WIDTH-1:0] data_reg [0:3]; // x(n), x(n-1), x(n-2), x(n-3)

    // Accumulator untuk menyimpan hasil penjumlahan parsial
    reg signed [DATA_WIDTH + COEFF_WIDTH - COEFF_FRACTION_WIDTH + 1:0] accumulator_reg;

    // Sinyal untuk memilih input data dan koefisien untuk MAC unit
    wire signed [DATA_WIDTH-1:0] mac_data_in;
    wire signed [COEFF_WIDTH-1:0] mac_coeff_in;

    // Output dari MAC unit (perkalian)
    wire signed [DATA_WIDTH + COEFF_WIDTH -1:0] mac_mul_out; // Lebar penuh hasil perkalian sebelum fractional shift

    // Register untuk validasi data output
    reg data_valid_reg_int; // Internal register untuk validasi data

    assign o_data_sum = accumulator_reg;
    assign o_data_valid = data_valid_reg_int;

    // FSM State Register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // FSM Next State Logic
    always @(*) begin // Menggunakan always @(*) untuk combinational logic
        next_state = current_state; // Default ke current state
        data_valid_reg_int = 1'b0; // Default output valid low

        case (current_state)
            IDLE: begin
                if (i_data_valid) // Hanya transisi jika ada input valid baru
                    next_state = LOAD_INPUT;
            end
            LOAD_INPUT: begin
                next_state = MAC_0;
            end
            MAC_0: begin
                next_state = MAC_1;
            end
            MAC_1: begin
                next_state = MAC_2;
            end
            MAC_2: begin
                next_state = MAC_3;
            end
            MAC_3: begin
                next_state = OUTPUT_READY;
            end
            OUTPUT_READY: begin
                data_valid_reg_int = 1'b1; // Output valid
                // Kembali ke IDLE atau LOAD_INPUT jika ada input baru
                if (i_data_valid)
                    next_state = LOAD_INPUT;
                else
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Register input data dan accumulator logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_reg[0] <= 'd0;
            data_reg[1] <= 'd0;
            data_reg[2] <= 'd0;
            data_reg[3] <= 'd0;
            accumulator_reg <= 'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    accumulator_reg <= 'd0; // Reset accumulator saat IDLE
                end
                LOAD_INPUT: begin
                    data_reg[3] <= data_reg[2];
                    data_reg[2] <= data_reg[1];
                    data_reg[1] <= data_reg[0];
                    data_reg[0] <= i_data; // Muat input baru
                end
                MAC_0: begin
                    accumulator_reg <= (mac_mul_out >>> COEFF_FRACTION_WIDTH);
                end
                MAC_1: begin
                    accumulator_reg <= accumulator_reg + (mac_mul_out >>> COEFF_FRACTION_WIDTH);
                end
                MAC_2: begin
                    accumulator_reg <= accumulator_reg + (mac_mul_out >>> COEFF_FRACTION_WIDTH);
                end
                MAC_3: begin
                    accumulator_reg <= accumulator_reg + (mac_mul_out >>> COEFF_FRACTION_WIDTH);
                end
                default: begin
                    // No change
                end
            endcase
        end
    end

    // Multiplexer untuk memilih input data ke MAC unit
    assign mac_data_in = (current_state == MAC_0) ? data_reg[0] :
                         (current_state == MAC_1) ? data_reg[1] :
                         (current_state == MAC_2) ? data_reg[2] :
                         (current_state == MAC_3) ? data_reg[3] : 'd0;

    // Multiplexer untuk memilih koefisien ke MAC unit
    // Menggunakan localparam Hx_VAL yang terpisah
    assign mac_coeff_in = (current_state == MAC_0) ? H0_VAL :
                          (current_state == MAC_1) ? H1_VAL :
                          (current_state == MAC_2) ? H2_VAL :
                          (current_state == MAC_3) ? H3_VAL : 'd0;

    // MAC unit (single multiplier)
    assign mac_mul_out = mac_data_in * mac_coeff_in;

endmodule


// cd D:\FIR_Filter
// iverilog -o fir_hardware_share.vvp fir_4_tap_hardware_share.v tb_fir_hardware_share.v
// vvp fir_hardware_share.vvp
// gtkwave fir_hardware_share.vcd