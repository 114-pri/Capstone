// Synthesizable Programmable Workload-Aware Opcode Mapper
// Replaces fixed 50/25/12.5/12.5 logic with programmable profiles.

module programmable_workload_mapper (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [4:0]  entropy_window,
    input  logic [3:0]  phase_counter,
    input  logic [1:0]  profile_select,   // 00: Uniform, 01: CoreMark/Dhrystone, 10: Logic-Heavy, 11: Shift-Heavy
    output logic [3:0]  workload_opcode
);
    // Profile definitions (Scaled 0-255)
    // Profile 0: Baseline Uniform (25% each class)
    localparam int unsigned P0_W_ARITH = 64;
    localparam int unsigned P0_W_LOGIC = 64;
    localparam int unsigned P0_W_SHIFT = 64;
    localparam int unsigned P0_W_COMP  = 63; // 255 total

    // Profile 1: CoreMark/Dhrystone (50% Arith, 25% Logic, 12.5% Shift, 12.5% Comp)
    localparam int unsigned P1_W_ARITH = 128;
    localparam int unsigned P1_W_LOGIC = 64;
    localparam int unsigned P1_W_SHIFT = 32;
    localparam int unsigned P1_W_COMP  = 31;

    // Profile 2: Logic Heavy (25% Arith, 50% Logic, 12.5% Shift, 12.5% Comp)
    localparam int unsigned P2_W_ARITH = 64;
    localparam int unsigned P2_W_LOGIC = 128;
    localparam int unsigned P2_W_SHIFT = 32;
    localparam int unsigned P2_W_COMP  = 31;

    // Profile 3: Shift Heavy (25% Arith, 25% Logic, 37.5% Shift, 12.5% Comp)
    localparam int unsigned P3_W_ARITH = 64;
    localparam int unsigned P3_W_LOGIC = 64;
    localparam int unsigned P3_W_SHIFT = 96;
    localparam int unsigned P3_W_COMP  = 31;

    logic [7:0] t_arith, t_logic, t_shift;

    always_comb begin
        case(profile_select)
            2'b00: begin
                t_arith = P0_W_ARITH;
                t_logic = P0_W_ARITH + P0_W_LOGIC;
                t_shift = P0_W_ARITH + P0_W_LOGIC + P0_W_SHIFT;
            end
            2'b01: begin
                t_arith = P1_W_ARITH;
                t_logic = P1_W_ARITH + P1_W_LOGIC;
                t_shift = P1_W_ARITH + P1_W_LOGIC + P1_W_SHIFT;
            end
            2'b10: begin
                t_arith = P2_W_ARITH;
                t_logic = P2_W_ARITH + P2_W_LOGIC;
                t_shift = P2_W_ARITH + P2_W_LOGIC + P2_W_SHIFT;
            end
            2'b11: begin
                t_arith = P3_W_ARITH;
                t_logic = P3_W_ARITH + P3_W_LOGIC;
                t_shift = P3_W_ARITH + P3_W_LOGIC + P3_W_SHIFT;
            end
        endcase
    end

    // Use 8 bits of entropy to select class
    logic [7:0] random_val;
    assign random_val = {entropy_window, phase_counter[2:0]}; 

    logic [1:0] selected_class;
    always_comb begin
        if (random_val < t_arith)
            selected_class = 2'b00; // Arithmetic
        else if (random_val < t_logic)
            selected_class = 2'b01; // Logic
        else if (random_val < t_shift)
            selected_class = 2'b10; // Shift
        else
            selected_class = 2'b11; // Compare
    end

    // Map to specific opcodes
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
        case (selected_class)
            2'b00: mapped_op = (entropy_window[0]) ? ALU_SUB : ALU_ADD;
            2'b01: begin
                case (entropy_window[2:1])
                    2'b00: mapped_op = ALU_AND;
                    2'b01: mapped_op = ALU_OR;
                    default: mapped_op = ALU_XOR;
                endcase
            end
            2'b10: begin
                case (entropy_window[2:1])
                    2'b00: mapped_op = ALU_SLL;
                    2'b01: mapped_op = ALU_SRL;
                    default: mapped_op = ALU_SRA;
                endcase
            end
            2'b11: mapped_op = entropy_window[0] ? ALU_SLTU : ALU_SLT;
        endcase
    end

    // Hold mapped opcode for 2-cycle burst to eliminate intra-cycle pipeline thrashing
    logic [3:0] burst_op_reg;
    always_ff @(posedge clk) begin
        if (reset)
            burst_op_reg <= ALU_ADD;
        else if (enable) begin
            if (phase_counter[0] == 1'b0) begin
                burst_op_reg <= mapped_op;
            end
        end
    end

    assign workload_opcode = burst_op_reg;
endmodule
