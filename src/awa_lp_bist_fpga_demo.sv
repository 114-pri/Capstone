`timescale 1ns / 1ps

module debouncer (
    input  logic clk,
    input  logic btn_in,
    output logic btn_out
);
    logic [19:0] counter = 0; // ~20ms at 50MHz is 1,000,000 cycles
    logic state = 0;
    always_ff @(posedge clk) begin
        if (btn_in != state) begin
            counter <= counter + 1;
            if (counter == 20'd1_000_000) begin
                state <= btn_in;
                counter <= 0;
            end
        end else begin
            counter <= 0;
        end
    end
    assign btn_out = state;
endmodule

module awa_lp_bist_fpga_demo (
    input  logic       clk_50mhz,
    input  logic       reset,
    input  logic       start,
    input  logic [1:0] mode,
    
    output logic [7:0] led,
    output logic [3:0] an,
    output logic [7:0] seg,
    
    output logic       uart_tx
);

    // 1. Button Debouncing
    logic reset_debounced;
    logic start_debounced;
    
    debouncer u_deb_reset (.clk(clk_50mhz), .btn_in(reset), .btn_out(reset_debounced));
    debouncer u_deb_start (.clk(clk_50mhz), .btn_in(start), .btn_out(start_debounced));
    
    // Start pulse generation
    logic start_q;
    always_ff @(posedge clk_50mhz) start_q <= start_debounced;
    logic start_pulse;
    assign start_pulse = start_debounced && !start_q && !running_reg; // Do not retrigger while running

    // 2. BIST Instance Wires
    logic        bist_pass;
    logic        bist_fail;
    logic        bist_done;
    logic [31:0] bist_sig;
    logic [31:0] bist_trans;
    logic [7:0]  bist_peak;
    logic        bist_pa;
    logic        bist_fb;
    
    // Hardcoded config for demonstration
    logic [2:0] profile_select = 3'b000; // Uniform
    logic       fault_enable = 1'b0;     // Nominal run
    logic [1:0] fault_type = 2'b00;
    logic [4:0] fault_select = 5'd0;
    logic       fault_internal = 1'b0;
    logic [1:0] fault_target = 2'b00;

    bist_top #(
        .TEST_CYCLES(255)
    ) u_bist (
        .clk(clk_50mhz),
        .reset(reset_debounced),
        .start(start_pulse),
        .bist_mode(mode),
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

    // 3. Status and LED Assignments
    logic running_reg = 0;
    always_ff @(posedge clk_50mhz) begin
        if (reset_debounced) running_reg <= 1'b0;
        else if (start_pulse) running_reg <= 1'b1;
        else if (bist_done) running_reg <= 1'b0;
    end

    assign led[0] = running_reg;
    assign led[1] = bist_done;
    assign led[2] = bist_pass;
    assign led[3] = bist_fail;
    assign led[4] = bist_pa;
    assign led[5] = bist_fb;
    assign led[6] = mode[1]; // Mode indicator
    assign led[7] = bist_fail; // Fault detected

    // PA Counters
    logic pa_reg = 0;
    logic [15:0] pa_acts = 0, pa_deacts = 0;
    
    always_ff @(posedge clk_50mhz) begin
        if (reset_debounced || start_pulse) begin
            pa_reg <= 1'b0;
            pa_acts <= 0;
            pa_deacts <= 0;
        end else if (running_reg) begin
            pa_reg <= bist_pa;
            if (bist_pa && !pa_reg) pa_acts <= pa_acts + 1;
            if (!bist_pa && pa_reg) pa_deacts <= pa_deacts + 1;
        end
    end

    // 4. 7-Segment Display Controller
    logic [16:0] seg_clk_div = 0;
    always_ff @(posedge clk_50mhz) seg_clk_div <= seg_clk_div + 1;
    logic [1:0] anode_sel;
    assign anode_sel = seg_clk_div[16:15]; // ~760 Hz refresh rate
    
    logic [25:0] display_timer = 0; // ~1.3 seconds per cycle at 50MHz
    logic [1:0] display_state = 0;
    always_ff @(posedge clk_50mhz) begin
        if (display_timer == 26'd67_108_863) begin
            display_timer <= 0;
            display_state <= display_state + 1;
        end else begin
            display_timer <= display_timer + 1;
        end
    end

    function logic [7:0] hex2seg(input logic [3:0] hex);
        case (hex)
            //             DP G F E D C B A (0 means ON)
            4'h0: return 8'b1_1_0_0_0_0_0_0;
            4'h1: return 8'b1_1_1_1_1_0_0_1;
            4'h2: return 8'b1_0_1_0_0_1_0_0;
            4'h3: return 8'b1_0_1_1_0_0_0_0;
            4'h4: return 8'b1_0_0_1_1_0_0_1;
            4'h5: return 8'b1_0_0_1_0_0_1_0;
            4'h6: return 8'b1_0_0_0_0_0_1_0;
            4'h7: return 8'b1_1_1_1_1_0_0_0;
            4'h8: return 8'b1_0_0_0_0_0_0_0;
            4'h9: return 8'b1_0_0_1_0_0_0_0;
            4'hA: return 8'b1_0_0_0_1_0_0_0;
            4'hB: return 8'b1_0_0_0_0_0_1_1; // b
            4'hC: return 8'b1_1_0_0_0_1_1_0; // C
            4'hD: return 8'b1_0_1_0_0_0_0_1; // d
            4'hE: return 8'b1_0_0_0_0_1_1_0; // E
            4'hF: return 8'b1_0_0_0_1_1_1_0; // F
            default: return 8'b1_1_1_1_1_1_1_1;
        endcase
    endfunction

    logic [7:0] char0, char1, char2, char3;
    always_comb begin
        if (running_reg) begin
            char3 = 8'b1_0_1_0_1_1_1_1; // r
            char2 = 8'b1_1_1_0_0_0_1_1; // u
            char1 = 8'b1_0_1_0_1_0_1_1; // n
            char0 = 8'b1_1_1_1_1_1_1_1; // blank
        end else if (!bist_done) begin
            char3 = 8'b1_1_1_1_1_0_0_1; // I
            char2 = 8'b1_0_1_0_0_0_0_1; // d
            char1 = 8'b1_1_0_0_0_1_1_1; // L
            char0 = 8'b1_0_0_0_0_1_1_0; // E
        end else begin
            case (display_state)
                2'd0: begin // MODE
                    if (mode == 2'b00) begin
                        char3 = 8'b1_1_1_1_1_1_1_1; // blank
                        char2 = 8'b1_0_0_1_0_0_1_0; // S
                        char1 = 8'b1_0_0_0_0_1_1_1; // t
                        char0 = 8'b1_0_1_0_0_0_0_1; // d
                    end else if (mode == 2'b01) begin
                        char3 = 8'b1_0_0_1_0_0_1_0; // S
                        char2 = 8'b1_0_0_0_0_1_1_1; // t
                        char1 = 8'b1_0_0_0_1_0_0_0; // A
                        char0 = 8'b1_0_0_0_0_1_1_1; // t
                    end else begin
                        char3 = 8'b1_0_0_0_1_0_0_0; // A
                        char2 = 8'b1_0_1_0_0_0_0_1; // d
                        char1 = 8'b1_0_0_0_1_0_0_0; // A
                        char0 = 8'b1_0_0_0_1_1_0_0; // P
                    end
                end
                2'd1: begin // CYCLES
                    char3 = hex2seg(4'd0);
                    char2 = hex2seg(4'd2);
                    char1 = hex2seg(4'd5);
                    char0 = hex2seg(4'd5); // 0255
                end
                2'd2: begin // TRANSITIONS (lower 16-bits in hex)
                    char3 = hex2seg(bist_trans[15:12]);
                    char2 = hex2seg(bist_trans[11:8]);
                    char1 = hex2seg(bist_trans[7:4]);
                    char0 = hex2seg(bist_trans[3:0]);
                end
                2'd3: begin // PASS/FAIL
                    if (bist_pass) begin
                        char3 = 8'b1_0_0_0_1_1_0_0; // P
                        char2 = 8'b1_0_0_0_1_0_0_0; // A
                        char1 = 8'b1_0_0_1_0_0_1_0; // S
                        char0 = 8'b1_0_0_1_0_0_1_0; // S
                    end else begin
                        char3 = 8'b1_0_0_0_1_1_1_0; // F
                        char2 = 8'b1_0_0_0_1_0_0_0; // A
                        char1 = 8'b1_1_1_1_1_0_0_1; // I
                        char0 = 8'b1_1_0_0_0_1_1_1; // L
                    end
                end
            endcase
        end
    end
    
    logic [3:0] an_reg;
    logic [7:0] seg_reg;
    always_comb begin
        case (anode_sel)
            2'b00: begin an_reg = 4'b1110; seg_reg = char0; end
            2'b01: begin an_reg = 4'b1101; seg_reg = char1; end
            2'b10: begin an_reg = 4'b1011; seg_reg = char2; end
            2'b11: begin an_reg = 4'b0111; seg_reg = char3; end
        endcase
    end
    assign an = an_reg;
    assign seg = seg_reg;

    // 5. UART Transmitter (50MHz clock)
    logic [7:0] tx_data;
    logic tx_start;
    logic tx_busy;

    uart_tx #(
        .CLK_FREQ(50_000_000), // Adjusted to 50MHz EDGE Artix-7
        .BAUD_RATE(115200)
    ) u_uart (
        .clk(clk_50mhz),
        .reset(reset_debounced),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(uart_tx),
        .tx_busy(tx_busy)
    );

    // Formatted ASCII Transmission FSM
    logic [7:0] msg_rom [0:180];
    initial begin
        msg_rom[0]  = "A"; msg_rom[1]  = "W"; msg_rom[2]  = "A"; msg_rom[3]  = "-"; msg_rom[4]  = "L"; msg_rom[5]  = "P"; msg_rom[6]  = "-"; msg_rom[7]  = "B"; msg_rom[8]  = "I"; msg_rom[9] = "S"; msg_rom[10] = "T"; msg_rom[11] = "\r"; msg_rom[12] = "\n";
        msg_rom[13] = "M"; msg_rom[14] = "O"; msg_rom[15] = "D"; msg_rom[16] = "E"; msg_rom[17] = ":"; msg_rom[18] = " "; msg_rom[19] = "%"; msg_rom[20] = "M"; msg_rom[21] = "\r"; msg_rom[22] = "\n";
        msg_rom[23] = "S"; msg_rom[24] = "T"; msg_rom[25] = "A"; msg_rom[26] = "T"; msg_rom[27] = "U"; msg_rom[28] = "S"; msg_rom[29] = ":"; msg_rom[30] = " "; msg_rom[31] = "%"; msg_rom[32] = "P"; msg_rom[33] = "\r"; msg_rom[34] = "\n";
        msg_rom[35] = "C"; msg_rom[36] = "Y"; msg_rom[37] = "C"; msg_rom[38] = "L"; msg_rom[39] = "E"; msg_rom[40] = "S"; msg_rom[41] = ":"; msg_rom[42] = " "; msg_rom[43] = "2"; msg_rom[44] = "5"; msg_rom[45] = "5"; msg_rom[46] = "\r"; msg_rom[47] = "\n";
        msg_rom[48] = "T"; msg_rom[49] = "R"; msg_rom[50] = "A"; msg_rom[51] = "N"; msg_rom[52] = "S"; msg_rom[53] = "I"; msg_rom[54] = "T"; msg_rom[55] = "I"; msg_rom[56] = "O"; msg_rom[57] = "N"; msg_rom[58] = "S"; msg_rom[59] = ":"; msg_rom[60] = " "; msg_rom[61] = "0"; msg_rom[62] = "x"; msg_rom[63] = "%"; msg_rom[64] = "T"; msg_rom[65] = "\r"; msg_rom[66] = "\n";
        msg_rom[67] = "C"; msg_rom[68] = "O"; msg_rom[69] = "V"; msg_rom[70] = "E"; msg_rom[71] = "R"; msg_rom[72] = "A"; msg_rom[73] = "G"; msg_rom[74] = "E"; msg_rom[75] = ":"; msg_rom[76] = " "; msg_rom[77] = "N"; msg_rom[78] = "/"; msg_rom[79] = "A"; msg_rom[80] = " "; msg_rom[81] = "\r"; msg_rom[82] = "\n";
        msg_rom[83] = "P"; msg_rom[84] = "A"; msg_rom[85] = " "; msg_rom[86] = "A"; msg_rom[87] = "C"; msg_rom[88] = "T"; msg_rom[89] = ":"; msg_rom[90] = " "; msg_rom[91] = "0"; msg_rom[92] = "x"; msg_rom[93] = "%"; msg_rom[94] = "A"; msg_rom[95] = "\r"; msg_rom[96] = "\n";
        msg_rom[97] = "P"; msg_rom[98] = "A"; msg_rom[99] = " "; msg_rom[100] = "D"; msg_rom[101] = "E"; msg_rom[102] = "A"; msg_rom[103] = "C"; msg_rom[104] = "T"; msg_rom[105] = ":"; msg_rom[106] = " "; msg_rom[107] = "0"; msg_rom[108] = "x"; msg_rom[109] = "%"; msg_rom[110] = "D"; msg_rom[111] = "\r"; msg_rom[112] = "\n"; msg_rom[113] = "\r"; msg_rom[114] = "\n";
        msg_rom[115] = 8'h00; // NULL terminator
    end

    function [7:0] hex2ascii(input [3:0] hex);
        if (hex < 10) return 8'h30 + hex;
        else return 8'h41 + (hex - 10);
    endfunction

    typedef enum logic [2:0] {
        TX_IDLE = 3'd0,
        TX_WAIT_DONE = 3'd1,
        TX_SEND = 3'd2,
        TX_SEND_MODE_WAIT = 3'd3,
        TX_SEND_PASS_WAIT = 3'd4,
        TX_WAIT_UART = 3'd5,
        TX_MODE_WAIT = 3'd6,
        TX_PASS_WAIT = 3'd7
    } tx_state_t;

    tx_state_t tx_state = TX_IDLE;
    logic [7:0] msg_idx = 0;
    logic [3:0] hex_idx = 0;
    logic [2:0] sub_str_idx = 0;

    always_ff @(posedge clk_50mhz) begin
        if (reset_debounced || start_pulse) begin
            tx_state <= TX_IDLE;
            tx_start <= 1'b0;
            msg_idx <= 0;
            hex_idx <= 0;
            sub_str_idx <= 0;
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
                            if (msg_rom[msg_idx] == "%") begin
                                logic [7:0] next_char = msg_rom[msg_idx+1];
                                if (next_char == "M") begin
                                    tx_state <= TX_SEND_MODE_WAIT;
                                    sub_str_idx <= 0;
                                end else if (next_char == "T") begin
                                    logic [3:0] nibble = bist_trans >> ((7 - hex_idx) * 4);
                                    tx_data <= hex2ascii(nibble);
                                    tx_start <= 1'b1;
                                    if (hex_idx == 7) begin
                                        hex_idx <= 0;
                                        msg_idx <= msg_idx + 2;
                                    end else begin
                                        hex_idx <= hex_idx + 1;
                                    end
                                    tx_state <= TX_WAIT_UART;
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
                                    tx_state <= TX_WAIT_UART;
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
                                    tx_state <= TX_WAIT_UART;
                                end else if (next_char == "P") begin
                                    tx_state <= TX_SEND_PASS_WAIT;
                                    sub_str_idx <= 0;
                                end else begin
                                    tx_data <= "%";
                                    tx_start <= 1'b1;
                                    msg_idx <= msg_idx + 1;
                                    tx_state <= TX_WAIT_UART;
                                end
                            end else begin
                                tx_data <= msg_rom[msg_idx];
                                tx_start <= 1'b1;
                                msg_idx <= msg_idx + 1;
                                tx_state <= TX_WAIT_UART;
                            end
                        end
                    end
                end
                
                TX_SEND_MODE_WAIT: begin
                    if (!tx_busy && !tx_start) begin
                        if (mode == 2'b00) begin
                            if (sub_str_idx == 0) tx_data <= "S";
                            else if (sub_str_idx == 1) tx_data <= "T";
                            else if (sub_str_idx == 2) tx_data <= "D";
                        end else if (mode == 2'b01) begin
                            if (sub_str_idx == 0) tx_data <= "S";
                            else if (sub_str_idx == 1) tx_data <= "T";
                            else if (sub_str_idx == 2) tx_data <= "A";
                            else if (sub_str_idx == 3) tx_data <= "T";
                            else if (sub_str_idx == 4) tx_data <= "I";
                            else if (sub_str_idx == 5) tx_data <= "C";
                        end else begin
                            if (sub_str_idx == 0) tx_data <= "A";
                            else if (sub_str_idx == 1) tx_data <= "D";
                            else if (sub_str_idx == 2) tx_data <= "A";
                            else if (sub_str_idx == 3) tx_data <= "P";
                            else if (sub_str_idx == 4) tx_data <= "T";
                            else if (sub_str_idx == 5) tx_data <= "I";
                            else if (sub_str_idx == 6) tx_data <= "V";
                            else if (sub_str_idx == 7) tx_data <= "E";
                        end
                        
                        tx_start <= 1'b1;
                        tx_state <= TX_WAIT_UART;
                        
                        if ((mode == 2'b00 && sub_str_idx == 2) ||
                            (mode == 2'b01 && sub_str_idx == 5) ||
                            (mode == 2'b10 && sub_str_idx == 7)) begin
                            msg_idx <= msg_idx + 2;
                        end else begin
                            sub_str_idx <= sub_str_idx + 1;
                        end
                    end
                end
                
                TX_SEND_PASS_WAIT: begin
                    if (!tx_busy && !tx_start) begin
                        if (bist_pass) begin
                            if (sub_str_idx == 0) tx_data <= "P";
                            else if (sub_str_idx == 1) tx_data <= "A";
                            else if (sub_str_idx == 2) tx_data <= "S";
                            else if (sub_str_idx == 3) tx_data <= "S";
                        end else begin
                            if (sub_str_idx == 0) tx_data <= "F";
                            else if (sub_str_idx == 1) tx_data <= "A";
                            else if (sub_str_idx == 2) tx_data <= "I";
                            else if (sub_str_idx == 3) tx_data <= "L";
                        end
                        
                        tx_start <= 1'b1;
                        if (sub_str_idx == 3) begin
                            msg_idx <= msg_idx + 2;
                            tx_state <= TX_WAIT_UART;
                        end else begin
                            sub_str_idx <= sub_str_idx + 1;
                        end
                    end
                end

                TX_WAIT_UART: begin
                    tx_start <= 1'b0;
                    if (!tx_busy) tx_state <= TX_SEND;
                end
            endcase
            
            // Sub-string wait overrides
            if (tx_start) begin
                if (tx_state == TX_SEND_MODE_WAIT) tx_state <= TX_MODE_WAIT;
                if (tx_state == TX_SEND_PASS_WAIT) tx_state <= TX_PASS_WAIT;
            end
            if (tx_state == TX_MODE_WAIT) begin
                tx_start <= 1'b0;
                if (!tx_busy) tx_state <= TX_SEND_MODE_WAIT;
            end
            if (tx_state == TX_PASS_WAIT) begin
                tx_start <= 1'b0;
                if (!tx_busy) tx_state <= TX_SEND_PASS_WAIT;
            end
        end
    end

endmodule
