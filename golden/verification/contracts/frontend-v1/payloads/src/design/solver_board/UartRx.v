`timescale 1ns / 1ps

module UartRx #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg [7:0]  data = 8'h00,
    output reg        data_valid = 1'b0
);

    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD;
    localparam integer HALF_CLKS = CLKS_PER_BIT / 2;

    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_START = 2'd1;
    localparam [1:0] S_DATA  = 2'd2;
    localparam [1:0] S_STOP  = 2'd3;

    reg [1:0] state = S_IDLE;
    reg [15:0] clk_count = 16'd0;
    reg [2:0] bit_index = 3'd0;
    reg [7:0] shift_reg = 8'h00;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE;
            clk_count <= 16'd0;
            bit_index <= 3'd0;
            shift_reg <= 8'h00;
            data <= 8'h00;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    clk_count <= 16'd0;
                    bit_index <= 3'd0;
                    if (!rx) begin
                        state <= S_START;
                    end
                end

                S_START: begin
                    if (clk_count == HALF_CLKS - 1) begin
                        clk_count <= 16'd0;
                        if (!rx) begin
                            state <= S_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                S_DATA: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        shift_reg[bit_index] <= rx;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state <= S_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                S_STOP: begin
                    if (clk_count == CLKS_PER_BIT - 1) begin
                        clk_count <= 16'd0;
                        state <= S_IDLE;
                        if (rx) begin
                            data <= shift_reg;
                            data_valid <= 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
