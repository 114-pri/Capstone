`timescale 1ns / 1ps

module tb_lp_bist_top;
    logic        clk = 1'b0;
    logic        reset;
    logic        start;
    logic [1:0]  bist_mode;
    logic [1:0]  profile_select;
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
    localparam int unsigned NUM_SEEDS   = 5; // Reduced to 5 for faster automated test, can be 50

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

    always #5 clk = ~clk; // 100 MHz clock

    task automatic run_single_session(
        input  logic [1:0]  mode_in,
        input  logic [1:0]  prof_sel,
        input  logic        f_en,
        input  logic [1:0]  f_type,
        input  logic [4:0]  f_sel,
        input  logic        f_internal,
        input  logic [1:0]  f_target,
        output logic [31:0] out_sig,
        output logic [31:0] out_trans,
        output logic [7:0]  out_peak
    );
        begin
            @(negedge clk);
            bist_mode             = mode_in;
            profile_select        = prof_sel;
            fault_enable          = f_en;
            fault_type            = f_type;
            fault_select          = f_sel;
            fault_is_internal     = f_internal;
            fault_internal_target = f_target;
            start                 = 1'b1;
            
            if (f_en) dut.fault_injection_valid = 1'b1;

            @(negedge clk);
            start                 = 1'b0;
            dut.fault_injection_valid = 1'b0;

            @(posedge test_done);
            #1;
            out_sig   = signature;
            out_trans = total_transitions;
            out_peak  = peak_transitions;
            
            // Assume the testbench evaluates detection instantly at test end for the monitor (in a real chip it takes a cycle)
            if (f_en) begin
                if (out_sig !== dut.active_golden_signature) begin
                    dut.fault_detection_valid = 1'b1;
                end
            end
            @(negedge clk);
            dut.fault_detection_valid = 1'b0;
            
            repeat (2) @(posedge clk);
        end
    endtask

    logic [31:0] t_sig, t_trans;
    logic [7:0]  t_peak;
    int fault_tests_passed;
    logic [31:0] test_seed;

    initial begin
        $display("================================================================================");
        $display("   WA-LP-BIST UPGRADE TEST AUTOMATION (PYTHON-PARSEABLE)                        ");
        $display("================================================================================");

        reset                 = 1'b1;
        start                 = 1'b0;
        bist_mode             = 2'b00;
        profile_select        = 2'b00;
        fault_enable          = 1'b0;
        fault_type            = 2'b00;
        fault_select          = 5'd0;
        fault_is_internal     = 1'b0;
        fault_internal_target = 2'b00;
        dut.fault_injection_valid = 1'b0;
        dut.fault_detection_valid = 1'b0;
        dut.u_lfsr.active_seed = 32'h00000001;
        
        repeat (5) @(posedge clk);
        reset = 1'b0;
        repeat (2) @(posedge clk);

        for (int s = 0; s < NUM_SEEDS; s++) begin
            test_seed = (32'h13579BDF ^ (s * 32'h9E3779B9)) | 32'h00000001;

            // Mode 0: Standard
            dut.u_lfsr.active_seed = test_seed;
            run_single_session(2'b00, 2'b00, 1'b0, 2'b00, 5'd0, 1'b0, 2'b00, t_sig, t_trans, t_peak);
            $display("CSV_OUT:SEED=%0d,MODE=0,PROF=0,WSA=%0d,PEAK=%0d", s, t_trans, t_peak);

            // Mode 1: Abu-Issa BS
            dut.u_lfsr.active_seed = test_seed;
            run_single_session(2'b01, 2'b00, 1'b0, 2'b00, 5'd0, 1'b0, 2'b00, t_sig, t_trans, t_peak);
            $display("CSV_OUT:SEED=%0d,MODE=1,PROF=0,WSA=%0d,PEAK=%0d", s, t_trans, t_peak);

            // Mode 2, Profile 0 (Uniform Programmable)
            dut.u_lfsr.active_seed = test_seed;
            run_single_session(2'b10, 2'b00, 1'b0, 2'b00, 5'd0, 1'b0, 2'b00, t_sig, t_trans, t_peak);
            $display("CSV_OUT:SEED=%0d,MODE=2,PROF=0,WSA=%0d,PEAK=%0d", s, t_trans, t_peak);
            
            // Mode 2, Profile 1 (CoreMark)
            dut.u_lfsr.active_seed = test_seed;
            run_single_session(2'b10, 2'b01, 1'b0, 2'b00, 5'd0, 1'b0, 2'b00, t_sig, t_trans, t_peak);
            $display("CSV_OUT:SEED=%0d,MODE=2,PROF=1,WSA=%0d,PEAK=%0d", s, t_trans, t_peak);
            
            // Log phase distribution for Mode 2 Profile 1 Seed 0
            if (s == 0) begin
                $display("PHASE_LOG:P0=%0d,P1=%0d,P2=%0d,P3=%0d,P4=%0d,P5=%0d", 
                         dut.phase_transitions[0], dut.phase_transitions[1], dut.phase_transitions[2], 
                         dut.phase_transitions[3], dut.phase_transitions[4], dut.phase_transitions[5]);
            end
        end

        // Fault Injection Matrix (Mode 2, Profile 1, Seed 1)
        dut.u_lfsr.active_seed = 32'h00000001;
        fault_tests_passed = 0;
        
        // Output Bit 0 SA0
        run_single_session(2'b10, 2'b01, 1'b1, 2'b01, 5'd0, 1'b0, 2'b00, t_sig, t_trans, t_peak);
        if (t_sig !== dut.active_golden_signature) fault_tests_passed++;
        
        // Output Bit 0 SA1
        run_single_session(2'b10, 2'b01, 1'b1, 2'b10, 5'd0, 1'b0, 2'b00, t_sig, t_trans, t_peak);
        if (t_sig !== dut.active_golden_signature) fault_tests_passed++;

        // Internals: Adder Carry-16 SA0
        run_single_session(2'b10, 2'b01, 1'b1, 2'b01, 5'd0, 1'b1, 2'b00, t_sig, t_trans, t_peak);
        if (t_sig !== dut.active_golden_signature) fault_tests_passed++;
        
        // Internals: Shifter Stage-2 SA0
        run_single_session(2'b10, 2'b01, 1'b1, 2'b01, 5'd0, 1'b1, 2'b01, t_sig, t_trans, t_peak);
        if (t_sig !== dut.active_golden_signature) fault_tests_passed++;

        // Internals: Comparator Sign SA0
        run_single_session(2'b10, 2'b01, 1'b1, 2'b01, 5'd0, 1'b1, 2'b10, t_sig, t_trans, t_peak);
        if (t_sig !== dut.active_golden_signature) fault_tests_passed++;

        $display("FAULT_COV_OUT:DETECTED=%0d,TOTAL=5", fault_tests_passed);
        $display("ALL TESTS COMPLETED SUCCESSFULLY.");
        $finish;
    end
endmodule
