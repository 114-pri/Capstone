module fault_boost_generator (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic        fault_boost_mode,
    input  logic [31:0] raw_lfsr_a,
    input  logic [31:0] raw_lfsr_b,
    input  logic [3:0]  normal_op,
    output logic [31:0] boost_pattern_a,
    output logic [31:0] boost_pattern_b,
    output logic [3:0]  boost_op
);
    // In fault boost mode, generate high-transition patterns to excite hard-to-detect faults.
    always_comb begin
        if (fault_boost_mode) begin
            // XOR with alternating masks to ensure high bitwise transitions
            boost_pattern_a = raw_lfsr_a ^ 32'hAAAAAAAA;
            boost_pattern_b = raw_lfsr_b ^ 32'h55555555;
            // Force operations good for error propagation (e.g. XOR, ADD, SUB)
            case (raw_lfsr_a[1:0])
                2'b00: boost_op = 4'd0; // ADD
                2'b01: boost_op = 4'd1; // SUB
                2'b10: boost_op = 4'd5; // XOR
                2'b11: boost_op = 4'd8; // OR
            endcase
        end else begin
            boost_pattern_a = raw_lfsr_a;
            boost_pattern_b = raw_lfsr_b;
            boost_op = normal_op;
        end
    end
endmodule
