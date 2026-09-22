// 32-bit Multi-Mode Pattern Generator:
//   - Mode 2'b00: Standard Baseline LFSR (Uniform pseudo-random distribution)
//   - Mode 2'b01: Classic Abu-Issa Bit-Swapping LFSR (BS-LFSR, TVLSI 2007)
//   - Mode 2'b10: Proposed Workload-Aware Low-Power BIST (WA-LP-BIST)
//                 Combines Interleaved Bank Bit-Swapping (IB-BS) with
//                 CoreMark/Dhrystone Weighted Opcode Mapping (WOM) and Phase Clustering.

module lt_lfsr_32bit (
    input  logic        clk,
    input  logic        reset,
    input  logic        load_seed,
    input  logic        enable,
    input  logic [1:0]  bist_mode,
    input  logic [31:0] seed,
    input  logic        power_aware_mode,
    input  logic        fault_boost_mode,
    input  logic [1:0]  profile_select,
    output logic [31:0] pattern_a,
    output logic [31:0] pattern_b,
    output logic [3:0]  pattern_op,
    output logic [31:0] raw_lfsr
);
    localparam logic [1:0] MODE_STD     = 2'b00;
    localparam logic [1:0] MODE_BS      = 2'b01;
    localparam logic [1:0] MODE_WA_BIST = 2'b10;

    logic [31:0] lfsr_reg;
    logic        feedback;
    logic [3:0]  sub_counter;

    logic [31:0] active_seed = 32'h00000001;

    always_comb begin
        feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];
    end

    always_ff @(posedge clk) begin
        if (reset || load_seed) begin
            lfsr_reg    <= (active_seed == 32'h00000000) ? 32'h00000001 : active_seed;
            sub_counter <= 4'd0;
        end else if (enable) begin
            lfsr_reg    <= {lfsr_reg[30:0], feedback};
            sub_counter <= sub_counter + 1'b1;
        end
    end

    assign raw_lfsr = lfsr_reg;

    // 1. Bit-Swapping Logic
    logic [31:0] swapped_a, swapped_b;
    logic        swap_control;
    assign swap_control = lfsr_reg[0] ^ sub_counter[1];

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            if (swap_control) begin
                swapped_a[2*i]     = lfsr_reg[2*i+1];
                swapped_a[2*i+1]   = lfsr_reg[2*i];
            end else begin
                swapped_a[2*i]     = lfsr_reg[2*i];
                swapped_a[2*i+1]   = lfsr_reg[2*i+1];
            end
        end
        swapped_b = {swapped_a[15:0], swapped_a[31:16]} ^ 32'hA5A55A5A;
    end

    // 2. Interleaved Bank Registers
    logic [31:0] lp_a_reg, lp_b_reg;
    always_ff @(posedge clk) begin
        if (reset || load_seed) begin
            lp_a_reg <= (active_seed == 32'h00000000) ? 32'h00000001 : active_seed;
            lp_b_reg <= {active_seed[15:0], active_seed[31:16]} ^ 32'hA5A55A5A;
        end else if (enable) begin
            if (sub_counter[0] == 1'b0) begin
                lp_a_reg[15:0]  <= swapped_a[15:0];
                lp_b_reg[31:16] <= swapped_b[31:16];
            end else begin
                lp_a_reg[31:16] <= swapped_a[31:16];
                lp_b_reg[15:0]  <= swapped_b[15:0];
            end
        end
    end

    // Power-Aware Operand Generation
    logic [31:0] pa_pattern_a, pa_pattern_b;
    operand_pattern_generator u_op_gen (
        .clk(clk),
        .reset(reset || load_seed),
        .enable(enable),
        .power_aware_mode(power_aware_mode),
        .raw_lfsr_a(lp_a_reg),
        .raw_lfsr_b(lp_b_reg),
        .out_pattern_a(pa_pattern_a),
        .out_pattern_b(pa_pattern_b)
    );

    // 3. Opcode Generation Paths
    logic [3:0] std_op, bs_op;
    assign std_op = (lfsr_reg[3:0] >= 4'd10) ? (lfsr_reg[3:0] - 4'd10) : lfsr_reg[3:0];
    assign bs_op = (swapped_a[3:0] >= 4'd10) ? (swapped_a[3:0] - 4'd10) : swapped_a[3:0];

    // Programmable Workload Mapper
    logic [3:0] pwm_op;
    programmable_workload_mapper u_pwm (
        .clk(clk),
        .reset(reset || load_seed),
        .enable(enable),
        .entropy_window(lfsr_reg[4:0]),
        .phase_counter(sub_counter[3:0]),
        .profile_select(profile_select),
        .workload_opcode(pwm_op)
    );

    // Transition Model
    logic [3:0] tm_op;
    logic [3:0] prev_op_reg;
    always_ff @(posedge clk) begin
        if (reset || load_seed) prev_op_reg <= 4'd0;
        else if (enable) prev_op_reg <= pattern_op;
    end

    transition_model u_tm (
        .clk(clk),
        .reset(reset || load_seed),
        .enable(enable),
        .entropy_window(lfsr_reg[9:5]), // Use different entropy bits
        .phase_counter(sub_counter[3:0]),
        .prev_opcode(prev_op_reg),
        .next_opcode(tm_op)
    );

    // Choose WA opcode based on power aware mode
    logic [3:0] wa_final_op;
    assign wa_final_op = power_aware_mode ? tm_op : pwm_op;

    // Fault Boost Generator
    logic [31:0] boost_a, boost_b;
    logic [3:0]  boost_op;
    fault_boost_generator u_boost (
        .clk(clk),
        .reset(reset || load_seed),
        .enable(enable),
        .fault_boost_mode(fault_boost_mode),
        .raw_lfsr_a(pa_pattern_a),
        .raw_lfsr_b(pa_pattern_b),
        .normal_op(wa_final_op),
        .boost_pattern_a(boost_a),
        .boost_pattern_b(boost_b),
        .boost_op(boost_op)
    );

    // 4. Multiplexing Based on bist_mode
    always_comb begin
        case (bist_mode)
            MODE_STD: begin
                pattern_a  = lfsr_reg;
                pattern_b  = {lfsr_reg[15:0], lfsr_reg[31:16]} ^ 32'hA5A55A5A;
                pattern_op = std_op;
            end
            MODE_BS: begin
                pattern_a  = swapped_a;
                pattern_b  = swapped_b;
                pattern_op = bs_op;
            end
            MODE_WA_BIST: begin
                pattern_a  = boost_a;
                pattern_b  = boost_b;
                pattern_op = boost_op;
            end
            default: begin
                pattern_a  = lfsr_reg;
                pattern_b  = {lfsr_reg[15:0], lfsr_reg[31:16]} ^ 32'hA5A55A5A;
                pattern_op = std_op;
            end
        endcase
    end
endmodule
