module adaptive_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [31:0] wsa_total,
    input  logic [7:0]  wsa_toggles,
    input  logic        coverage_stagnated,
    output logic        power_aware_mode,
    output logic        fault_boost_mode
);
    // Hysteresis thresholds for WSA control (using Window Average)
    localparam logic [7:0] WSA_HIGH_THRESHOLD = 8'd18;
    localparam logic [7:0] WSA_LOW_THRESHOLD  = 8'd14;

    // 16-Cycle Sliding Window Leaky Integrator
    localparam int WINDOW_SIZE = 16;
    logic [7:0]  window_history [0:15];
    logic [11:0] window_total;
    logic [7:0]  window_average;
    logic [4:0]  window_count;
    logic        window_valid;
    
    assign window_average = window_total >> 4;

    // Internal cycle counter for self-contained logging
    logic [31:0] internal_cycle_cnt;

    always_ff @(posedge clk) begin
        if (reset) begin
            power_aware_mode <= 1'b0;
            fault_boost_mode <= 1'b0;
            internal_cycle_cnt <= 32'd0;
            
            for (int i = 0; i < 16; i++) window_history[i] <= 8'd0;
            window_total <= 12'd0;
            window_count <= 5'd0;
            window_valid <= 1'b0;
        end else if (enable) begin
            internal_cycle_cnt <= internal_cycle_cnt + 1;
            
            // Shift register update
            window_history[0] <= wsa_toggles;
            for (int i = 1; i < 16; i++) begin
                window_history[i] <= window_history[i-1];
            end
            
            // Running sum update
            window_total <= window_total + wsa_toggles - window_history[15];
            
            // Valid condition
            if (window_count < 16) window_count <= window_count + 1'b1;
            if (window_count == 15) window_valid <= 1'b1;

            // Fault Boost Override
            if (coverage_stagnated) begin
                fault_boost_mode <= 1'b1;
                power_aware_mode <= 1'b0; // Sacrifice power for coverage
            end else begin
                fault_boost_mode <= 1'b0;
                
                // Autonomous Power-Aware Decision
                if (window_valid) begin
                    if (window_average > WSA_HIGH_THRESHOLD) begin
                        power_aware_mode <= 1'b1;
                    end else if (window_average < WSA_LOW_THRESHOLD) begin
                        power_aware_mode <= 1'b0;
                    end
                end
            end
        end
    end

`ifndef SYNTHESIS
    // Guarded Simulation Diagnostics - Triggers ONLY on actual state transitions
    // And uses a global flag to print only a small number of times (once per edge type)
    logic sim_printed_pa_on = 0;
    logic sim_printed_pa_off = 0;
    logic sim_printed_fb_on = 0;
    logic sim_printed_fb_off = 0;

    always @(posedge power_aware_mode) begin
        if (reset === 1'b0 && enable === 1'b1 && !sim_printed_pa_on) begin
            $display("\n[ADAPTIVE DECISION]");
            $display("Cycle = %0d", internal_cycle_cnt);
            $display("Window activity = %0d", window_average);
            $display("HIGH = %0d", WSA_HIGH_THRESHOLD);
            $display("LOW = %0d", WSA_LOW_THRESHOLD);
            $display("PA = 0 -> 1\n");
            sim_printed_pa_on = 1;
        end
    end

    always @(negedge power_aware_mode) begin
        if (reset === 1'b0 && enable === 1'b1 && !sim_printed_pa_off) begin
            $display("\n[ADAPTIVE DECISION]");
            $display("Cycle = %0d", internal_cycle_cnt);
            $display("Window activity = %0d", window_average);
            $display("HIGH = %0d", WSA_HIGH_THRESHOLD);
            $display("LOW = %0d", WSA_LOW_THRESHOLD);
            $display("PA = 1 -> 0\n");
            sim_printed_pa_off = 1;
        end
    end

    always @(posedge fault_boost_mode) begin
        if (reset === 1'b0 && enable === 1'b1 && !sim_printed_fb_on) begin
            $display("[CONTROLLER] Cycle = %0d | Coverage Stagnated. Fault Boost ON. Power Aware OFF.", internal_cycle_cnt);
            sim_printed_fb_on = 1;
        end
    end

    always @(negedge fault_boost_mode) begin
        if (reset === 1'b0 && enable === 1'b1 && !sim_printed_fb_off) begin
            $display("[CONTROLLER] Cycle = %0d | Coverage Stagnation cleared. Fault Boost OFF.", internal_cycle_cnt);
            sim_printed_fb_off = 1;
        end
    end
`endif

endmodule
