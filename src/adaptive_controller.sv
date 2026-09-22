module adaptive_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [31:0] wsa_total,
    input  logic [7:0]  wsa_peak,
    input  logic        coverage_stagnated,
    output logic        power_aware_mode,
    output logic        fault_boost_mode
);
    // Hysteresis thresholds for WSA control
    localparam logic [7:0] WSA_HIGH_THRESHOLD = 8'd42;
    localparam logic [7:0] WSA_LOW_THRESHOLD  = 8'd25;

    always_ff @(posedge clk) begin
        if (reset) begin
            power_aware_mode <= 1'b0;
            fault_boost_mode <= 1'b0;
        end else if (enable) begin
            if (coverage_stagnated) begin
                fault_boost_mode <= 1'b1;
                power_aware_mode <= 1'b0; // Sacrifice power for coverage
            end else begin
                fault_boost_mode <= 1'b0;
                
                if (wsa_peak > WSA_HIGH_THRESHOLD) begin
                    power_aware_mode <= 1'b1;
                end else if (wsa_peak < WSA_LOW_THRESHOLD) begin
                    power_aware_mode <= 1'b0;
                end
            end
        end
    end
endmodule
