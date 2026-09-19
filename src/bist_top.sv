// Top-Level Workload-Aware Low-Power BIST (WA-LP-BIST) Module for 32-Bit RISC-V RV32I ALU.
// Supports 3 selectable test modes:
//   - Mode 2'b00: Standard Baseline LFSR (Uniform pseudo-random)
//   - Mode 2'b01: Classic Abu-Issa Bit-Swapping LFSR (BS-LFSR)
//   - Mode 2'b10: Proposed Workload-Aware BIST (CoreMark/Dhrystone-Correlated WA-LP-BIST)
// Optimized to 91 I/O pins, comfortably fitting the 106-pin Artix-7 cpg236 FPGA package.

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
    input  logic        fault_enable,
    input  logic [1:0]  fault_type,             // 00: None, 01: SA0, 10: SA1
    input  logic [4:0]  fault_select,           // Output pin bit 0..31
    input  logic        fault_is_internal,      // 0: Output fault, 1: Internal gate fault
    input  logic [1:0]  fault_internal_target,  // 00: Carry-16, 01: Shifter-St2, 10: CompSign
    output logic        pass,
    output logic        fail,
    output logic        test_done,
    output logic [31:0] signature,
    output logic [31:0] total_transitions,
    output logic [7:0]  peak_transitions
);
    // Internal interconnects
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

    // Internal gate fault injection control
    logic        inject_internal_fault;
    logic [1:0]  internal_fault_type;
    logic [1:0]  internal_fault_target;

    always_comb begin
        case (bist_mode)
            2'b00:   active_golden_signature = GOLDEN_SIG_STD;
            2'b01:   active_golden_signature = GOLDEN_SIG_BS;
            2'b10:   active_golden_signature = GOLDEN_SIG_WA;
            default: active_golden_signature = GOLDEN_SIG_STD;
        endcase
    end

    // 1. 3-Mode Pattern Generator (STD, Abu-Issa BS, Proposed Workload-Aware)
    lt_lfsr_32bit u_lfsr (
        .clk(clk),
        .reset(reset),
        .load_seed(lfsr_seed_load),
        .enable(lfsr_step),
        .bist_mode(bist_mode),
        .seed(32'h00000001),
        .pattern_a(alu_a),
        .pattern_b(alu_b),
        .pattern_op(alu_op),
        .raw_lfsr(raw_lfsr_internal)
    );

    // 2. Hardware Transition / WSA Monitor
    wsa_monitor u_wsa (
        .clk(clk),
        .reset(reset),
        .clear(monitor_clear),
        .sample_enable(monitor_sample),
        .vector_a(alu_a),
        .vector_b(alu_b),
        .vector_op(alu_op),
        .total_transitions(total_transitions),
        .peak_transitions(peak_transitions),
        .last_cycle_transitions()
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
        .lfsr_seed_load(lfsr_seed_load),
        .lfsr_step(lfsr_step),
        .misr_reset(misr_reset),
        .misr_capture(misr_capture),
        .monitor_clear(monitor_clear),
        .monitor_sample(monitor_sample),
        .test_done(test_done),
        .pass(pass),
        .fail(fail)
    );
endmodule
