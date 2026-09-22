module transition_model (
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic [4:0]  entropy_window,
    input  logic [3:0]  phase_counter,
    input  logic [3:0]  prev_opcode,
    output logic [3:0]  next_opcode
);
    localparam logic [3:0] ALU_ADD  = 4'd0;
    localparam logic [3:0] ALU_SUB  = 4'd1;
    localparam logic [3:0] ALU_SLL  = 4'd2;
    localparam logic [3:0] ALU_SLT  = 4'd3;
    localparam logic [3:0] ALU_SLTU = 4'd4;
    localparam logic [3:0] ALU_XOR  = 4'd5;
    localparam logic [3:0] ALU_SRL  = 4'd6;
    localparam logic [3:0] ALU_SRA  = 4'd7;
    localparam logic [3:0] ALU_OR   = 4'd8;
    localparam logic [3:0] ALU_AND  = 4'd9;
    
    logic [7:0] rand_val;
    assign rand_val = {entropy_window, phase_counter[2:0]};
    
    // 75% probability to stay in same operation to reduce datapath thrashing
    logic stay_in_class;
    assign stay_in_class = (rand_val < 8'd192);

    logic [3:0] new_op;
    
    always_comb begin
        if (stay_in_class) begin
            next_opcode = prev_opcode;
        end else begin
            case(rand_val[3:0])
                4'd0, 4'd1: new_op = ALU_ADD;
                4'd2:       new_op = ALU_SUB;
                4'd3:       new_op = ALU_AND;
                4'd4:       new_op = ALU_OR;
                4'd5:       new_op = ALU_XOR;
                4'd6:       new_op = ALU_SLL;
                4'd7:       new_op = ALU_SRL;
                4'd8:       new_op = ALU_SRA;
                4'd9:       new_op = ALU_SLT;
                4'd10,4'd11:new_op = ALU_SLTU;
                default:    new_op = ALU_ADD;
            endcase
            next_opcode = new_op;
        end
    end
endmodule
