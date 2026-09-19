// Hardware Transition & Weighted Switching Activity (WSA) Monitor.
// Measures cycle-by-cycle Hamming distance (bit transitions) across the 68-bit ALU input vector.
// Accumulates total test transitions for quantitative switching activity evaluation.

module wsa_monitor (
    input  logic        clk,
    input  logic        reset,
    input  logic        clear,
    input  logic        sample_enable,
    input  logic [31:0] vector_a,
    input  logic [31:0] vector_b,
    input  logic [3:0]  vector_op,
    output logic [31:0] total_transitions,
    output logic [7:0]  peak_transitions,
    output logic [7:0]  last_cycle_transitions
);
    logic [67:0] current_vector;
    logic [67:0] prev_vector;
    logic [67:0] diff_vector;
    logic [7:0]  cycle_toggles;

    assign current_vector = {vector_a, vector_b, vector_op};
    assign diff_vector    = current_vector ^ prev_vector;

    // Count transitions across all 68 input bits
    always_comb begin
        cycle_toggles = 8'd0;
        for (int i = 0; i < 68; i++) begin
            if (diff_vector[i])
                cycle_toggles = cycle_toggles + 1'b1;
        end
    end

    assign last_cycle_transitions = cycle_toggles;

    always_ff @(posedge clk) begin
        if (reset || clear) begin
            prev_vector       <= 68'd0;
            total_transitions <= 32'd0;
            peak_transitions  <= 8'd0;
        end else if (sample_enable) begin
            prev_vector       <= current_vector;
            total_transitions <= total_transitions + cycle_toggles;
            if (cycle_toggles > peak_transitions)
                peak_transitions <= cycle_toggles;
        end
    end
endmodule
