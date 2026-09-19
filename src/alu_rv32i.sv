// 32-bit RISC-V RV32I Execution ALU with Internal Net Structural Probing
// and In-Circuit Gate Fault Injection (Carry Chain, Barrel Shifter, Signed Comparator).

module alu_rv32i (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  operation,
    // Internal gate-level fault injection interface
    input  logic        inject_internal_fault,
    input  logic [1:0]  internal_fault_type,     // 01: SA0, 10: SA1
    input  logic [1:0]  internal_fault_target,   // 00: Carry16, 01: ShifterStage2, 10: CompSign
    output logic [31:0] result,
    output logic        zero
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

    // -------------------------------------------------------------------------
    // 1. Structural 2-Stage Adder/Subtractor with Carry-16 Fault Hook
    // -------------------------------------------------------------------------
    logic [31:0] b_operand;
    logic        sub_mode;
    logic [16:0] sum_lower;
    logic        carry_16_internal;
    logic        carry_16_injected;
    logic [16:0] sum_upper;
    logic [31:0] adder_result;

    assign sub_mode  = (operation == ALU_SUB);
    assign b_operand = sub_mode ? (~b) : b;

    assign sum_lower = {1'b0, a[15:0]} + {1'b0, b_operand[15:0]} + sub_mode;
    assign carry_16_internal = sum_lower[16];

    // Carry-16 Fault Injection Mux
    always_comb begin
        carry_16_injected = carry_16_internal;
        if (inject_internal_fault && (internal_fault_target == 2'b00)) begin
            if (internal_fault_type == 2'b01)      carry_16_injected = 1'b0; // SA0
            else if (internal_fault_type == 2'b10) carry_16_injected = 1'b1; // SA1
        end
    end

    assign sum_upper    = {1'b0, a[31:16]} + {1'b0, b_operand[31:16]} + carry_16_injected;
    assign adder_result = {sum_upper[15:0], sum_lower[15:0]};

    // -------------------------------------------------------------------------
    // 2. Structural Logarithmic Barrel Shifter with Stage-2 Fault Hook
    // -------------------------------------------------------------------------
    logic [31:0] shift_in;
    logic [31:0] sll_stage0, sll_stage1, sll_stage2, sll_stage3, sll_stage4;
    logic [31:0] srl_stage0, srl_stage1, srl_stage2, srl_stage3, srl_stage4;
    logic [31:0] sra_stage0, sra_stage1, sra_stage2, sra_stage3, sra_stage4;

    assign shift_in = a;

    // Logical Left Shifter (SLL)
    assign sll_stage0 = b[0] ? {shift_in[30:0], 1'b0}   : shift_in;
    assign sll_stage1 = b[1] ? {sll_stage0[29:0], 2'b0} : sll_stage0;
    
    // Stage 2 (Shift by 4) with robust LSB fault injection
    logic [31:0] sll_st2_normal;
    assign sll_st2_normal = b[2] ? {sll_stage1[27:0], 4'b0} : sll_stage1;
    always_comb begin
        sll_stage2 = sll_st2_normal;
        if (inject_internal_fault && (internal_fault_target == 2'b01)) begin
            if (internal_fault_type == 2'b01)      sll_stage2[4] = 1'b0; // SA0 on intermediate mux output
            else if (internal_fault_type == 2'b10) sll_stage2[4] = 1'b1; // SA1 on intermediate mux output
        end
    end
    assign sll_stage3 = b[3] ? {sll_stage2[23:0], 8'b0}  : sll_stage2;
    assign sll_stage4 = b[4] ? {sll_stage3[15:0], 16'b0} : sll_stage3;

    // Logical Right Shifter (SRL)
    assign srl_stage0 = b[0] ? {1'b0, shift_in[31:1]}    : shift_in;
    assign srl_stage1 = b[1] ? {2'b0, srl_stage0[31:2]}  : srl_stage0;
    assign srl_stage2 = b[2] ? {4'b0, srl_stage1[31:4]}  : srl_stage1;
    assign srl_stage3 = b[3] ? {8'b0, srl_stage2[31:8]}  : srl_stage2;
    assign srl_stage4 = b[4] ? {16'b0, srl_stage3[31:16]}: srl_stage3;

    // Arithmetic Right Shifter (SRA)
    logic sign_ext;
    assign sign_ext   = a[31];
    assign sra_stage0 = b[0] ? {sign_ext, shift_in[31:1]}      : shift_in;
    assign sra_stage1 = b[1] ? {{2{sign_ext}}, sra_stage0[31:2]}  : sra_stage0;
    assign sra_stage2 = b[2] ? {{4{sign_ext}}, sra_stage1[31:4]}  : sra_stage1;
    assign sra_stage3 = b[3] ? {{8{sign_ext}}, sra_stage2[31:8]}  : sra_stage2;
    assign sra_stage4 = b[4] ? {{16{sign_ext}}, sra_stage3[31:16]}: sra_stage3;

    // -------------------------------------------------------------------------
    // 3. Signed & Unsigned Magnitude Comparator with Sign Fault Hook
    // -------------------------------------------------------------------------
    logic comp_slt_normal;
    logic comp_slt_injected;

    assign comp_slt_normal = ($signed(a) < $signed(b));
    always_comb begin
        comp_slt_injected = comp_slt_normal;
        if (inject_internal_fault && (internal_fault_target == 2'b10)) begin
            if (internal_fault_type == 2'b01)      comp_slt_injected = 1'b0; // SA0
            else if (internal_fault_type == 2'b10) comp_slt_injected = 1'b1; // SA1
        end
    end

    // -------------------------------------------------------------------------
    // 4. Output Multiplexer
    // -------------------------------------------------------------------------
    always_comb begin
        unique case (operation)
            ALU_ADD:  result = adder_result;
            ALU_SUB:  result = adder_result;
            ALU_SLL:  result = sll_stage4;
            ALU_SLT:  result = {31'b0, comp_slt_injected};
            ALU_SLTU: result = {31'b0, (a < b)};
            ALU_XOR:  result = a ^ b;
            ALU_SRL:  result = srl_stage4;
            ALU_SRA:  result = sra_stage4;
            ALU_OR:   result = a | b;
            ALU_AND:  result = a & b;
            default:  result = 32'h00000000;
        endcase
        zero = (result == 32'h00000000);
    end
endmodule
