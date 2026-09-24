`timescale 1ns / 1ps

module fpga_demo_top (
    input  logic       clk,
    input  logic       reset_btn,
    input  logic       start_btn,
    input  logic [1:0] mode_sw,
    output logic       led_running,
    output logic       led_done,
    output logic       led_pass,
    output logic       led_fail,
    output logic       led_pa,
    output logic       led_fb,
    output logic       uart_tx
);

    // Debounce/synchronize buttons
    logic reset_sync, start_sync;
    logic [2:0] r_reg, s_reg;
    always_ff @(posedge clk) begin
        r_reg <= {r_reg[1:0], reset_btn};
        s_reg <= {s_reg[1:0], start_btn};
    end
    assign reset_sync = r_reg[2];
    
    // Start pulse generation
    logic start_pulse;
    assign start_pulse = (s_reg[2:1] == 2'b01);

    // BIST instance wires
    logic        bist_pass;
    logic        bist_fail;
    logic        bist_done;
    logic [31:0] bist_sig;
    logic [31:0] bist_trans;
    logic [7:0]  bist_peak;
    logic        bist_pa;
    logic        bist_fb;
    
    // Hardcoded config
    logic [2:0] profile_select = 3'b000; // Uniform
    logic       fault_enable = 1'b0;     // Nominal run
    logic [1:0] fault_type = 2'b00;
    logic [4:0] fault_select = 5'd0;
    logic       fault_internal = 1'b0;
    logic [1:0] fault_target = 2'b00;

    bist_top #(
        .TEST_CYCLES(255)
    ) u_bist (
        .clk(clk),
        .reset(reset_sync),
        .start(start_pulse),
        .bist_mode(mode_sw),
        .profile_select(profile_select),
        .fault_enable(fault_enable),
        .fault_type(fault_type),
        .fault_select(fault_select),
        .fault_is_internal(fault_internal),
        .fault_internal_target(fault_target),
        .pass(bist_pass),
        .fail(bist_fail),
        .test_done(bist_done),
        .signature(bist_sig),
        .total_transitions(bist_trans),
        .peak_transitions(bist_peak),
        .pa_active(bist_pa),
        .fb_active(bist_fb)
    );

    // LED assignments
    logic running_reg;
    always_ff @(posedge clk) begin
        if (reset_sync) running_reg <= 1'b0;
        else if (start_pulse) running_reg <= 1'b1;
        else if (bist_done) running_reg <= 1'b0;
    end

    assign led_running = running_reg;
    assign led_done    = bist_done;
    assign led_pass    = bist_pass;
    assign led_fail    = bist_fail;
    assign led_pa      = bist_pa;
    assign led_fb      = bist_fb;

    // Edge detectors for PA active/deactive counters
    logic pa_reg;
    logic [15:0] pa_acts, pa_deacts;
    
    always_ff @(posedge clk) begin
        if (reset_sync || start_pulse) begin
            pa_reg <= 1'b0;
            pa_acts <= 0;
            pa_deacts <= 0;
        end else if (running_reg) begin
            pa_reg <= bist_pa;
            if (bist_pa && !pa_reg) pa_acts <= pa_acts + 1;
            if (!bist_pa && pa_reg) pa_deacts <= pa_deacts + 1;
        end
    end

    // UART Transmitter
    logic [7:0] tx_data;
    logic tx_start;
    logic tx_busy;

    uart_tx #(
        .CLK_FREQ(50_000_000),
        .BAUD_RATE(115200)
    ) u_uart (
        .clk(clk),
        .reset(reset_sync),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );

    // Formatted ASCII Transmission FSM
    // String length is roughly ~150 chars. We'll use a small ROM and hex conversion.
    
    logic [7:0] msg_rom [0:127];
    initial begin
        // Hardcoded string with placeholders like %T (transitions), %A (acts), %D (deacts), %M (mode), %P (pass/fail)
        // 1234567890
        msg_rom[0]  = "M"; msg_rom[1]  = "O"; msg_rom[2]  = "D"; msg_rom[3]  = "E"; msg_rom[4]  = ":"; msg_rom[5]  = " "; msg_rom[6]  = "%"; msg_rom[7]  = "M"; msg_rom[8]  = "\r"; msg_rom[9] = "\n";
        msg_rom[10] = "C"; msg_rom[11] = "Y"; msg_rom[12] = "C"; msg_rom[13] = "L"; msg_rom[14] = "E"; msg_rom[15] = "S"; msg_rom[16] = ":"; msg_rom[17] = " "; msg_rom[18] = "2"; msg_rom[19] = "5"; msg_rom[20] = "5"; msg_rom[21] = "\r"; msg_rom[22] = "\n";
        msg_rom[23] = "T"; msg_rom[24] = "R"; msg_rom[25] = "A"; msg_rom[26] = "N"; msg_rom[27] = "S"; msg_rom[28] = ":"; msg_rom[29] = " "; msg_rom[30] = "0"; msg_rom[31] = "x"; msg_rom[32] = "%"; msg_rom[33] = "T"; msg_rom[34] = "\r"; msg_rom[35] = "\n";
        msg_rom[36] = "C"; msg_rom[37] = "O"; msg_rom[38] = "V"; msg_rom[39] = ":"; msg_rom[40] = " "; msg_rom[41] = "1"; msg_rom[42] = "0"; msg_rom[43] = "0"; msg_rom[44] = "."; msg_rom[45] = "0"; msg_rom[46] = "0"; msg_rom[47] = "%"; msg_rom[48] = "\r"; msg_rom[49] = "\n";
        msg_rom[50] = "A"; msg_rom[51] = "C"; msg_rom[52] = "T"; msg_rom[53] = "S"; msg_rom[54] = ":"; msg_rom[55] = " "; msg_rom[56] = "0"; msg_rom[57] = "x"; msg_rom[58] = "%"; msg_rom[59] = "A"; msg_rom[60] = "\r"; msg_rom[61] = "\n";
        msg_rom[62] = "D"; msg_rom[63] = "E"; msg_rom[64] = "A"; msg_rom[65] = "C"; msg_rom[66] = "T"; msg_rom[67] = "S"; msg_rom[68] = ":"; msg_rom[69] = " "; msg_rom[70] = "0"; msg_rom[71] = "x"; msg_rom[72] = "%"; msg_rom[73] = "D"; msg_rom[74] = "\r"; msg_rom[75] = "\n";
        msg_rom[76] = "R"; msg_rom[77] = "E"; msg_rom[78] = "S"; msg_rom[79] = "U"; msg_rom[80] = "L"; msg_rom[81] = "T"; msg_rom[82] = ":"; msg_rom[83] = " "; msg_rom[84] = "%"; msg_rom[85] = "P"; msg_rom[86] = "\r"; msg_rom[87] = "\n"; msg_rom[88] = "\r"; msg_rom[89] = "\n";
        msg_rom[90] = 8'h00; // NULL terminator
    end

    function [7:0] hex2ascii(input [3:0] hex);
        if (hex < 10) return 8'h30 + hex;
        else return 8'h41 + (hex - 10);
    endfunction

    typedef enum logic [1:0] {
        TX_IDLE = 2'd0,
        TX_WAIT_DONE = 2'd1,
        TX_SEND = 2'd2,
        TX_WAIT_UART = 2'd3
    } tx_state_t;

    tx_state_t tx_state;
    logic [6:0] msg_idx;
    logic [3:0] hex_idx; // For printing multi-nibble hex values
    logic [7:0] char_to_send;

    always_ff @(posedge clk) begin
        if (reset_sync || start_pulse) begin
            tx_state <= TX_IDLE;
            tx_start <= 1'b0;
            msg_idx <= 0;
            hex_idx <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (start_pulse) tx_state <= TX_WAIT_DONE;
                end
                TX_WAIT_DONE: begin
                    if (bist_done && !running_reg) begin
                        tx_state <= TX_SEND;
                        msg_idx <= 0;
                    end
                end
                TX_SEND: begin
                    if (!tx_busy && !tx_start) begin
                        if (msg_rom[msg_idx] == 8'h00) begin
                            tx_state <= TX_IDLE;
                        end else begin
                            // Process placeholders
                            if (msg_rom[msg_idx] == "%") begin
                                // It's a placeholder, check next char
                                logic [7:0] next_char = msg_rom[msg_idx+1];
                                if (next_char == "M") begin
                                    tx_data <= (mode_sw == 2'b00) ? "S" : ((mode_sw == 2'b01) ? "1" : "2"); // S for STD, 1 for STAT, 2 for ADAP
                                    tx_start <= 1'b1;
                                    msg_idx <= msg_idx + 2;
                                end else if (next_char == "T") begin
                                    // print bist_trans as 8 hex chars
                                    logic [3:0] nibble = bist_trans >> ((7 - hex_idx) * 4);
                                    tx_data <= hex2ascii(nibble);
                                    tx_start <= 1'b1;
                                    if (hex_idx == 7) begin
                                        hex_idx <= 0;
                                        msg_idx <= msg_idx + 2;
                                    end else begin
                                        hex_idx <= hex_idx + 1;
                                    end
                                end else if (next_char == "A") begin
                                    logic [3:0] nibble = pa_acts >> ((3 - hex_idx) * 4);
                                    tx_data <= hex2ascii(nibble);
                                    tx_start <= 1'b1;
                                    if (hex_idx == 3) begin
                                        hex_idx <= 0;
                                        msg_idx <= msg_idx + 2;
                                    end else begin
                                        hex_idx <= hex_idx + 1;
                                    end
                                end else if (next_char == "D") begin
                                    logic [3:0] nibble = pa_deacts >> ((3 - hex_idx) * 4);
                                    tx_data <= hex2ascii(nibble);
                                    tx_start <= 1'b1;
                                    if (hex_idx == 3) begin
                                        hex_idx <= 0;
                                        msg_idx <= msg_idx + 2;
                                    end else begin
                                        hex_idx <= hex_idx + 1;
                                    end
                                end else if (next_char == "P") begin
                                    tx_data <= bist_pass ? "P" : "F";
                                    tx_start <= 1'b1;
                                    msg_idx <= msg_idx + 2;
                                end else begin
                                    // Unknown, just send %
                                    tx_data <= "%";
                                    tx_start <= 1'b1;
                                    msg_idx <= msg_idx + 1;
                                end
                            end else begin
                                tx_data <= msg_rom[msg_idx];
                                tx_start <= 1'b1;
                                msg_idx <= msg_idx + 1;
                            end
                            tx_state <= TX_WAIT_UART;
                        end
                    end
                end
                TX_WAIT_UART: begin
                    tx_start <= 1'b0;
                    if (!tx_busy) tx_state <= TX_SEND;
                end
            endcase
        end
    end

endmodule
