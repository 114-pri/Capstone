// 32-bit Fault Injector supporting both Output Bit and Internal Gate Net Faults.
module fault_injector_32bit (
    input  logic [31:0] normal_response,
    input  logic        fault_enable,
    input  logic [1:0]  fault_type,             // 00: None, 01: SA0, 10: SA1
    input  logic [4:0]  fault_select,           // Output pin bit 0..31
    input  logic        fault_is_internal,      // 0: Output fault, 1: Internal gate fault
    input  logic [1:0]  fault_internal_target,  // 00: Carry-16, 01: Shifter-St2, 10: CompSign
    output logic [31:0] injected_response,
    output logic        inject_internal_fault,
    output logic [1:0]  internal_fault_type,
    output logic [1:0]  internal_fault_target
);
    localparam logic [1:0] NO_FAULT   = 2'b00;
    localparam logic [1:0] STUCK_AT_0 = 2'b01;
    localparam logic [1:0] STUCK_AT_1 = 2'b10;

    always_comb begin
        injected_response     = normal_response;
        inject_internal_fault = 1'b0;
        internal_fault_type   = 2'b00;
        internal_fault_target = 2'b00;

        if (fault_enable) begin
            if (fault_is_internal) begin
                inject_internal_fault = 1'b1;
                internal_fault_type   = fault_type;
                internal_fault_target = fault_internal_target;
            end else begin
                unique case (fault_type)
                    STUCK_AT_0: injected_response[fault_select] = 1'b0;
                    STUCK_AT_1: injected_response[fault_select] = 1'b1;
                    default:     injected_response = normal_response;
                endcase
            end
        end
    end
endmodule
