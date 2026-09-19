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

    // Configurable active seed (defaults to input seed, testbench can set for Monte Carlo)
    logic [31:0] active_seed = 32'h00000001;

    // Maximal-length feedback for x^32 + x^22 + x^2 + x + 1
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

    // -------------------------------------------------------------------------
    // 1. Bit-Swapping Logic (Abu-Issa Style)
    // -------------------------------------------------------------------------
    logic [31:0] swapped_a;
    logic [31:0] swapped_b;
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

    // -------------------------------------------------------------------------
    // 2. Interleaved Bank Registers (Proposed WA-LP-BIST)
    // -------------------------------------------------------------------------
    logic [31:0] lp_a_reg;
    logic [31:0] lp_b_reg;

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

    // -------------------------------------------------------------------------
    // 3. Opcode Generation Paths
    // -------------------------------------------------------------------------
    // Standard uniform opcode (updates every cycle)
    logic [3:0] std_op;
    assign std_op = (lfsr_reg[3:0] >= 4'd10) ? (lfsr_reg[3:0] - 4'd10) : lfsr_reg[3:0];

    // Abu-Issa BS opcode (updates every cycle from swapped bits)
    logic [3:0] bs_op;
    assign bs_op = (swapped_a[3:0] >= 4'd10) ? (swapped_a[3:0] - 4'd10) : swapped_a[3:0];

    // Workload-Aware Opcode Mapper (CoreMark/Dhrystone distribution + Phase Clustering)
    logic [3:0] wom_op;
    bist_workload_mapper u_wom (
        .clk(clk),
        .reset(reset || load_seed),
        .enable(enable),
        .entropy_window(lfsr_reg[4:0]),
        .phase_counter(sub_counter[3:0]),
        .workload_opcode(wom_op)
    );

    // -------------------------------------------------------------------------
    // 4. Multiplexing Based on bist_mode
    // -------------------------------------------------------------------------
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
                pattern_a  = lp_a_reg;
                pattern_b  = lp_b_reg;
                pattern_op = wom_op;
            end
            default: begin
                pattern_a  = lfsr_reg;
                pattern_b  = {lfsr_reg[15:0], lfsr_reg[31:16]} ^ 32'hA5A55A5A;
                pattern_op = std_op;
            end
        endcase
    end
endmodule
