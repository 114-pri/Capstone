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
            case (raw_lfsr_a[2:0])
                3'b000: boost_op = 4'd0; // ADD
                3'b001: boost_op = 4'd1; // SUB
                3'b010: boost_op = 4'd5; // XOR
                3'b011: boost_op = 4'd8; // OR
                3'b100: boost_op = 4'd6; // SLL (Shift)
                3'b101: boost_op = 4'd9; // SRA (Shift)
                3'b110: boost_op = 4'd2; // SLT (Compare)
                3'b111: boost_op = 4'd3; // SLTU (Compare)
            endcase
        end else begin
            boost_pattern_a = raw_lfsr_a;
            boost_pattern_b = raw_lfsr_b;
            boost_op = normal_op;
        end
    end
endmodule
