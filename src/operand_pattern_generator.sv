module operand_pattern_generator (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic        power_aware_mode,
    input  logic [31:0] raw_lfsr_a,
    input  logic [31:0] raw_lfsr_b,
    output logic [31:0] out_pattern_a,
    output logic [31:0] out_pattern_b
);
    logic [31:0] hold_a, hold_b;
    logic        hold_en;

    // Suppress transitions 12.5% of the time (when lower 3 bits are 000) in power aware mode
    assign hold_en = power_aware_mode & (raw_lfsr_a[2:0] == 3'd0); 

    always_ff @(posedge clk) begin
        if (reset) begin
            hold_a <= 32'd0;
            hold_b <= 32'd0;
        end else if (enable && !hold_en) begin
            hold_a <= raw_lfsr_a;
            hold_b <= raw_lfsr_b;
        end
    end

    always_comb begin
        if (power_aware_mode) begin
            out_pattern_a = hold_en ? hold_a : raw_lfsr_a;
            out_pattern_b = hold_en ? hold_b : raw_lfsr_b;
        end else begin
            out_pattern_a = raw_lfsr_a;
            out_pattern_b = raw_lfsr_b;
        end
    end
endmodule
