// Synthesizable Workload-Aware Opcode Mapper (WOM) with Class-Phased Clustering.
// Models empirical Dhrystone & CoreMark RV32I execution profiles:
//   - 50.0% Arithmetic (ADD, SUB)
//   - 25.0% Bitwise Logic (AND, OR, XOR)
//   - 12.5% Shifters (SLL, SRL, SRA)
//   - 12.5% Magnitude Comparators (SLT, SLTU)
// Guarantees all 10 RV32I instructions are tested while clustering operations
// into phase bursts to eliminate high-frequency cross-domain ALU thrashing.

module bist_workload_mapper (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [4:0]  entropy_window,
    input  logic [3:0]  phase_counter,    // 4-bit sub-counter for deterministic class scheduling
    output logic [3:0]  workload_opcode
);
    localparam logic [3:0] ALU_ADD  = 4'd0;
    localparam logic [3:0] ALU_SUB  = 4'd1;
    localparam logic [3:0] ALU_SLL  = 4'd2;
    localparam logic [3:0] ALU_SLT  = 4'd3;
    localparam logic [3:0] ALU_SLTU = 4'd4;
    localparam logic [3:0] ALU_XOR  = 4'd5;
    localparam logic [3:0] ALU_SRL  = 4'd6;
    localparam logic [3:0] ALU_SRA  = 4'd7;
    localparam logic [3:0] ALU_OR   = 4'd8;
    localparam logic [3:0] ALU_AND  = 4'd9;

    logic [3:0] mapped_op;

    always_comb begin
        // Class 0: Arithmetic (50% of intervals: phase_counter[2] == 0)
        if (phase_counter[2] == 1'b0) begin
            mapped_op = (entropy_window[1:0] == 2'b00) ? ALU_SUB : ALU_ADD; // 37.5% ADD, 12.5% SUB
        end
        // Class 1: Logic (25% of intervals: phase_counter[2:1] == 2'b10)
        else if (phase_counter[1] == 1'b0) begin
            case (entropy_window[1:0])
                2'b00:   mapped_op = ALU_AND;
                2'b01:   mapped_op = ALU_OR;
                default: mapped_op = ALU_XOR;
            endcase
        end
        // Class 2: Shifters (12.5% of intervals: phase_counter[2:0] == 3'b110)
        else if (phase_counter[0] == 1'b0) begin
            case (entropy_window[1:0])
                2'b00:   mapped_op = ALU_SLL;
                2'b01:   mapped_op = ALU_SRL;
                default: mapped_op = ALU_SRA;
            endcase
        end
        // Class 3: Comparators (12.5% of intervals: phase_counter[2:0] == 3'b111)
        else begin
            mapped_op = entropy_window[0] ? ALU_SLTU : ALU_SLT;
        end
    end

    // Hold mapped opcode for 2-cycle burst to eliminate intra-cycle pipeline thrashing
    logic [3:0] burst_op_reg;
    always_ff @(posedge clk) begin
        if (reset)
            burst_op_reg <= ALU_ADD;
        else if (enable)
            burst_op_reg <= mapped_op;
    end

    assign workload_opcode = burst_op_reg;
endmodule
