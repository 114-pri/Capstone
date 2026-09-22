// BIST Controller FSM: Coordinates pattern generator seed loading, test cycling,
// response capture, switching activity monitoring, signature evaluation, and phase tracking.
module bist_controller #(
    parameter int unsigned TEST_CYCLES = 255
) (
    input  logic clk,
    input  logic reset,
    input  logic start,
    input  logic signature_match,
    input  logic fault_boost_mode, // From adaptive controller
    output logic lfsr_seed_load,
    output logic lfsr_step,
    output logic misr_reset,
    output logic misr_capture,
    output logic monitor_clear,
    output logic monitor_sample,
    output logic test_done,
    output logic pass,
    output logic fail,
    output logic [2:0] current_phase
);
    typedef enum logic [1:0] {IDLE, RUN, DONE} state_t;
    state_t state;
    localparam int COUNTER_WIDTH = (TEST_CYCLES <= 1) ? 1 : $clog2(TEST_CYCLES);
    logic [COUNTER_WIDTH-1:0] cycle_count;

    always_comb begin
        lfsr_seed_load = 1'b0;
        lfsr_step      = 1'b0;
        misr_reset     = 1'b0;
        misr_capture   = 1'b0;
        monitor_clear  = 1'b0;
        monitor_sample = 1'b0;

        case (state)
            IDLE: begin
                if (start) begin
                    lfsr_seed_load = 1'b1;
                    misr_reset     = 1'b1;
                    monitor_clear  = 1'b1;
                end
            end
            RUN: begin
                lfsr_step      = 1'b1;
                misr_capture   = 1'b1;
                monitor_sample = 1'b1;
            end
            DONE: begin
                if (start) begin
                    lfsr_seed_load = 1'b1;
                    misr_reset     = 1'b1;
                    monitor_clear  = 1'b1;
                end
            end
            default: begin
            end
        endcase
    end

    // Phase determination logic for logging
    always_comb begin
        if (state == IDLE) current_phase = 3'd0; // Init
        else if (state == DONE) current_phase = 3'd5; // Eval
        else if (fault_boost_mode) current_phase = 3'd4; // Boost
        else if (cycle_count < 10) current_phase = 3'd1; // Profiling/Config
        else if (cycle_count < 50) current_phase = 3'd2; // Workload-Guided
        else current_phase = 3'd3; // Adaptive LP
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            cycle_count <= '0;
            test_done   <= 1'b0;
            pass        <= 1'b0;
            fail        <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    test_done <= 1'b0;
                    pass      <= 1'b0;
                    fail      <= 1'b0;
                    if (start) begin
                        cycle_count <= '0;
                        state       <= RUN;
                    end
                end
                RUN: begin
                    if (cycle_count == TEST_CYCLES - 1) begin
                        state     <= DONE;
                        test_done <= 1'b1;
                        pass      <= signature_match;
                        fail      <= ~signature_match;
                    end else begin
                        cycle_count <= cycle_count + 1'b1;
                    end
                end
                DONE: begin
                    if (start) begin
                        cycle_count <= '0;
                        test_done   <= 1'b0;
                        pass        <= 1'b0;
                        fail        <= 1'b0;
                        state       <= RUN;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
