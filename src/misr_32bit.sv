// 32-bit Multiple-Input Signature Register (MISR) Response Compactor.
// Uses matched primitive polynomial: x^32 + x^22 + x^2 + x + 1.
// Compacts parallel 32-bit ALU responses with minimal aliasing probability.
module misr_32bit (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [31:0] response,
    output logic [31:0] signature,
    output logic [31:0] next_signature
);
    logic feedback;

    always_comb begin
        feedback       = signature[31] ^ signature[21] ^ signature[1] ^ signature[0];
        next_signature = {signature[30:0], feedback} ^ response;
    end

    always_ff @(posedge clk) begin
        if (reset)
            signature <= 32'h00000000;
        else if (enable)
            signature <= next_signature;
    end
endmodule
