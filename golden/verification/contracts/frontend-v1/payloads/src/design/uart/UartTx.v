`timescale 1ns / 1ps

module UartTx #(
    parameter integer ClkHz = 100_000_000,
    parameter integer BAUD   = 115200
) (
    input  wire       clk,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx = 1'b1,
    output reg        busy = 1'b0
);

    localparam integer ClksPerBit = ClkHz / BAUD;
    localparam integer StateIdle  = 3'd0;
    localparam integer StateStart = 3'd1;
    localparam integer StateData  = 3'd2;
    localparam integer StateStop  = 3'd3;

    reg [2:0] state = StateIdle;
    reg [12:0] baud_ctr = 13'd0;
    reg [2:0] bit_idx = 3'd0;
    reg [7:0] data_latched = 8'h00;

    always @(posedge clk) begin
        case (state)
            StateIdle: begin
                tx <= 1'b1;
                busy <= 1'b0;
                baud_ctr <= 13'd0;
                bit_idx <= 3'd0;

                if (start) begin
                    data_latched <= data;
                    busy <= 1'b1;
                    tx <= 1'b0;
                    state <= StateStart;
                end
            end

            StateStart: begin
                if (baud_ctr == ClksPerBit - 1) begin
                    baud_ctr <= 13'd0;
                    tx <= data_latched[0];
                    bit_idx <= 3'd0;
                    state <= StateData;
                end else begin
                    baud_ctr <= baud_ctr + 1'b1;
                end
            end

            StateData: begin
                if (baud_ctr == ClksPerBit - 1) begin
                    baud_ctr <= 13'd0;
                    if (bit_idx == 3'd7) begin
                        tx <= 1'b1;
                        state <= StateStop;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                        tx <= data_latched[bit_idx + 1'b1];
                    end
                end else begin
                    baud_ctr <= baud_ctr + 1'b1;
                end
            end

            StateStop: begin
                if (baud_ctr == ClksPerBit - 1) begin
                    baud_ctr <= 13'd0;
                    state <= StateIdle;
                end else begin
                    baud_ctr <= baud_ctr + 1'b1;
                end
            end

            default: begin
                state <= StateIdle;
                tx <= 1'b1;
                busy <= 1'b0;
            end
        endcase
    end
endmodule
