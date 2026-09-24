`timescale 1ns / 1ps

// Power characterization testbench — runs a single BIST mode for SAIF capture.
// POWER_MODE is set via +define at compile time: 0=STD, 1=STATIC_AWA, 2=ADAPTIVE_AWA

module tb_power_char;
    logic        clk = 1'b0;
    logic        reset;
    logic        start;
    logic [1:0]  bist_mode;
    logic [2:0]  profile_select;
    logic        fault_enable;
    logic [1:0]  fault_type;
    logic [4:0]  fault_select;
    logic        fault_is_internal;
    logic [1:0]  fault_internal_target;

    logic        pass, fail, test_done;
    logic [31:0] signature;
    logic [31:0] total_transitions;
    logic [7:0]  peak_transitions;

    localparam int unsigned TEST_CYCLES = 255;

    bist_top #(
        .TEST_CYCLES(TEST_CYCLES)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .bist_mode(bist_mode),
        .profile_select(profile_select),
        .fault_enable(fault_enable),
        .fault_type(fault_type),
        .fault_select(fault_select),
        .fault_is_internal(fault_is_internal),
        .fault_internal_target(fault_internal_target),
        .pass(pass),
        .fail(fail),
        .test_done(test_done),
        .signature(signature),
        .total_transitions(total_transitions),
        .peak_transitions(peak_transitions)
    );

    // 14ns period to match the real 71.4 MHz clock constraint
    always #7 clk = ~clk;

    task automatic run_one_session(
        input logic [1:0] mode_in,
        input logic [2:0] prof_sel,
        input logic [31:0] seed_val
    );
        dut.u_lfsr.active_seed = seed_val;
        
        @(negedge clk);
        bist_mode             = mode_in;
        profile_select        = prof_sel;
        fault_enable          = 1'b0;
        fault_type            = 2'b00;
        fault_select          = 5'd0;
        fault_is_internal     = 1'b0;
        fault_internal_target = 2'b00;
        start                 = 1'b1;

        @(negedge clk);
        start = 1'b0;

        @(posedge test_done);
        repeat (2) @(posedge clk);
    endtask

    // 5 seeds, 4 profiles — same as validated campaign
    logic [31:0] seeds [5];
    int power_mode;
    
    initial begin
        seeds[0] = 32'h13579BDF;
        seeds[1] = 32'h5A5A5A5A;
        seeds[2] = 32'hA5A5A5A5;
        seeds[3] = 32'hFFFFFFFF;
        seeds[4] = 32'h00000001;

        // Read mode from plusarg
        if (!$value$plusargs("POWER_MODE=%d", power_mode))
            power_mode = 0; // Default to STD

        reset = 1'b1;
        start = 1'b0;
        dut.fault_injection_valid = 1'b0;
        dut.fault_detection_valid = 1'b0;

        repeat (5) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        $display("POWER_CHAR: Starting mode=%0d", power_mode);

        for (int s = 0; s < 5; s++) begin
            for (int p = 0; p < 4; p++) begin
                if (power_mode == 0) begin
                    // STANDARD mode
                    run_one_session(2'b00, p[2:0], seeds[s]);
                end else if (power_mode == 1) begin
                    // STATIC AWA — force PA off
                    force dut.u_adaptive.power_aware_mode = 0;
                    run_one_session(2'b10, p[2:0], seeds[s]);
                    release dut.u_adaptive.power_aware_mode;
                end else begin
                    // ADAPTIVE AWA — natural behavior
                    run_one_session(2'b10, p[2:0], seeds[s]);
                end
                $display("  Seed %0d, Profile %0d complete. Transitions=%0d", s, p, total_transitions);
            end
        end

        $display("POWER_CHAR: Mode %0d complete.", power_mode);
        $finish;
    end
endmodule
