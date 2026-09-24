`timescale 1ns / 1ps

module uart_tx #(
    parameter int CLK_FREQ = 100_000_000,
    parameter int BAUD_RATE = 115200
)(
    input  logic       clk,
    input  logic       reset,
    input  logic [7:0] tx_data,
    input  logic       tx_start,
    output logic       tx,
    output logic       tx_busy
);

    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_t;

    state_t state, next_state;
    
    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;
    logic [2:0] bit_idx;
    logic [7:0] tx_data_reg;

    always_ff @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            clk_count <= 0;
            bit_idx <= 0;
            tx_data_reg <= 0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    clk_count <= 0;
                    bit_idx <= 0;
                    if (tx_start) begin
                        tx_data_reg <= tx_data;
                        state <= START;
                        tx_busy <= 1'b1;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx <= tx_data_reg[bit_idx];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_idx < 7) begin
                            bit_idx <= bit_idx + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
