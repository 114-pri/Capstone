module fault_coverage_monitor (
    input  logic        clk,
    input  logic        reset,
    input  logic        fault_injection_valid, 
    input  logic        fault_detection_valid, 
    input  logic        fault_campaign_active,
    output logic [15:0] total_injected,
    output logic [15:0] total_detected,
    output logic        coverage_stagnated     
);
    logic [15:0] cycles_since_last_detect;

    always_ff @(posedge clk) begin
        if (reset) begin
            total_injected <= '0;
            total_detected <= '0;
            cycles_since_last_detect <= '0;
            coverage_stagnated <= 1'b0;
        end else begin
            if (fault_campaign_active) begin
                if (fault_injection_valid) total_injected <= total_injected + 1'b1;
                
                if (fault_detection_valid) begin
                    total_detected <= total_detected + 1'b1;
                    cycles_since_last_detect <= '0;
                    coverage_stagnated <= 1'b0;
                end else begin
                    // If 50 cycles pass without detecting a new fault, flag stagnation
                    if (cycles_since_last_detect > 16'd50) begin
                        coverage_stagnated <= 1'b1;
                    end else begin
                        cycles_since_last_detect <= cycles_since_last_detect + 1'b1;
                    end
                end
            end else begin
                cycles_since_last_detect <= '0;
                coverage_stagnated <= 1'b0;
            end
        end
    end
endmodule
