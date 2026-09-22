// Top-Level Workload-Aware Low-Power BIST (WA-LP-BIST) Module for 32-Bit RISC-V RV32I ALU.
module bist_top #(
    parameter int unsigned TEST_CYCLES    = 255,
    parameter logic [31:0] GOLDEN_SIG_STD = 32'ha03133e1,
    parameter logic [31:0] GOLDEN_SIG_BS  = 32'hdeed1b06,
    parameter logic [31:0] GOLDEN_SIG_WA  = 32'h409b4a9d
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [1:0]  bist_mode,             // 00: STD, 01: BS-LFSR, 10: Proposed WA-BIST
    input  logic [1:0]  profile_select,        // 00: Uniform, 01: CoreMark, 10: Logic, 11: Shift
    input  logic        fault_enable,
    input  logic [1:0]  fault_type,            
    input  logic [4:0]  fault_select,          
    input  logic        fault_is_internal,     
    input  logic [1:0]  fault_internal_target, 
    output logic        pass,
    output logic        fail,
    output logic        test_done,
    output logic [31:0] signature,
    output logic [31:0] total_transitions,
    output logic [7:0]  peak_transitions
);
    // Internal interconnects and hierarchical testbench access points
    logic        fault_injection_valid;
    logic        fault_detection_valid;
    logic [2:0]  current_phase;
    logic [31:0] phase_transitions [6];
    logic        lfsr_seed_load, lfsr_step;
    logic        misr_reset, misr_capture;
    logic        monitor_clear, monitor_sample;
    logic [31:0] alu_a, alu_b;
    logic [3:0]  alu_op;
    logic [31:0] alu_result;
    logic        alu_zero;
    logic [31:0] faulted_result;
    logic [31:0] next_signature;
    logic        signature_match;
    logic [31:0] active_golden_signature;
    logic [31:0] raw_lfsr_internal;

    logic        inject_internal_fault;
    logic [1:0]  internal_fault_type;
    logic [1:0]  internal_fault_target;

    logic        power_aware_mode;
    logic        fault_boost_mode;
    logic        coverage_stagnated;
    logic [15:0] total_injected;
    logic [15:0] total_detected;
    logic [7:0]  last_cycle_transitions;

    always_comb begin
        case (bist_mode)
            2'b00:   active_golden_signature = GOLDEN_SIG_STD;
            2'b01:   active_golden_signature = GOLDEN_SIG_BS;
            2'b10:   active_golden_signature = GOLDEN_SIG_WA;
            default: active_golden_signature = GOLDEN_SIG_STD;
        endcase
    end

    // Adaptive Controller
    adaptive_controller u_adaptive (
        .clk(clk),
        .reset(reset || lfsr_seed_load),
        .enable(lfsr_step),
        .wsa_total(total_transitions),
        .wsa_peak(peak_transitions),
        .coverage_stagnated(coverage_stagnated),
        .power_aware_mode(power_aware_mode),
        .fault_boost_mode(fault_boost_mode)
    );

    // Fault Coverage Monitor
    fault_coverage_monitor u_fc_monitor (
        .clk(clk),
        .reset(reset || lfsr_seed_load),
        .fault_injection_valid(fault_injection_valid),
        .fault_detection_valid(fault_detection_valid),
        .total_injected(total_injected),
        .total_detected(total_detected),
        .coverage_stagnated(coverage_stagnated)
    );

    // 1. 3-Mode Pattern Generator (STD, Abu-Issa BS, Proposed WA)
    lt_lfsr_32bit u_lfsr (
        .clk(clk),
        .reset(reset),
        .load_seed(lfsr_seed_load),
        .enable(lfsr_step),
        .bist_mode(bist_mode),
        .seed(32'h00000001),
        .power_aware_mode(power_aware_mode),
        .fault_boost_mode(fault_boost_mode),
        .profile_select(profile_select),
        .pattern_a(alu_a),
        .pattern_b(alu_b),
        .pattern_op(alu_op),
        .raw_lfsr(raw_lfsr_internal)
    );

    // 2. Hardware Transition / WSA Monitor (Enhanced)
    enhanced_wsa_monitor u_wsa (
        .clk(clk),
        .reset(reset),
        .clear(monitor_clear),
        .sample_enable(monitor_sample),
        .current_phase(current_phase),
        .vector_a(alu_a),
        .vector_b(alu_b),
        .vector_op(alu_op),
        .total_transitions(total_transitions),
        .peak_transitions(peak_transitions),
        .last_cycle_transitions(last_cycle_transitions),
        .phase_transitions(phase_transitions)
    );

    // 3. Circuit Under Test: 32-bit RISC-V RV32I ALU with Internal Net Fault Hooks
    alu_rv32i u_alu (
        .a(alu_a),
        .b(alu_b),
        .operation(alu_op),
        .inject_internal_fault(inject_internal_fault),
        .internal_fault_type(internal_fault_type),
        .internal_fault_target(internal_fault_target),
        .result(alu_result),
        .zero(alu_zero)
    );

    // 4. In-Circuit Multi-Target Fault Injector
    fault_injector_32bit u_fault_injector (
        .normal_response(alu_result),
        .fault_enable(fault_enable),
        .fault_type(fault_type),
        .fault_select(fault_select),
        .fault_is_internal(fault_is_internal),
        .fault_internal_target(fault_internal_target),
        .injected_response(faulted_result),
        .inject_internal_fault(inject_internal_fault),
        .internal_fault_type(internal_fault_type),
        .internal_fault_target(internal_fault_target)
    );

    // 5. 32-bit MISR Response Compactor
    misr_32bit u_misr (
        .clk(clk),
        .reset(reset | misr_reset),
        .enable(misr_capture),
        .response(faulted_result),
        .signature(signature),
        .next_signature(next_signature)
    );

    // 6. Signature Comparator
    signature_comparator_32bit u_comparator (
        .measured_signature(next_signature),
        .golden_signature(active_golden_signature),
        .match(signature_match)
    );

    // 7. BIST Controller FSM
    bist_controller #(.TEST_CYCLES(TEST_CYCLES)) u_controller (
        .clk(clk),
        .reset(reset),
        .start(start),
        .signature_match(signature_match),
        .fault_boost_mode(fault_boost_mode),
        .lfsr_seed_load(lfsr_seed_load),
        .lfsr_step(lfsr_step),
        .misr_reset(misr_reset),
        .misr_capture(misr_capture),
        .monitor_clear(monitor_clear),
        .monitor_sample(monitor_sample),
        .test_done(test_done),
        .pass(pass),
        .fail(fail),
        .current_phase(current_phase)
    );
endmodule
