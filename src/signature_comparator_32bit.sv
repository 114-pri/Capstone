// 32-bit Signature Comparator.
module signature_comparator_32bit (
    input  logic [31:0] measured_signature,
    input  logic [31:0] golden_signature,
    output logic        match
);
    always_comb begin
        match = (measured_signature == golden_signature);
    end
endmodule
