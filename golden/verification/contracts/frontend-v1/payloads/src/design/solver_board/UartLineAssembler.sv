`timescale 1ns / 1ps

module UartLineAssembler #(
    parameter integer MAX_LINE_BYTES = 48
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           byte_valid,
    input  wire [7:0]                     byte_data,
    output reg                            line_valid = 1'b0,
    output reg                            line_overflow = 1'b0,
    output reg [7:0]                      line_len = 8'd0,
    output reg [MAX_LINE_BYTES*8-1:0]     line_data = {(MAX_LINE_BYTES*8){1'b0}}
);

    reg [7:0] write_len = 8'd0;
    reg       overflow_seen = 1'b0;
    reg [MAX_LINE_BYTES*8-1:0] buffer = {(MAX_LINE_BYTES*8){1'b0}};

    always @(posedge clk) begin
        if (!rst_n) begin
            line_valid <= 1'b0;
            line_overflow <= 1'b0;
            line_len <= 8'd0;
            line_data <= {(MAX_LINE_BYTES*8){1'b0}};
            write_len <= 8'd0;
            overflow_seen <= 1'b0;
            buffer <= {(MAX_LINE_BYTES*8){1'b0}};
        end else begin
            line_valid <= 1'b0;
            line_overflow <= 1'b0;

            if (byte_valid) begin
                if (byte_data == 8'h0A) begin
                    if (write_len != 8'd0 || overflow_seen) begin
                        line_valid <= 1'b1;
                        line_overflow <= overflow_seen;
                        line_len <= write_len;
                        line_data <= buffer;
                    end
                    write_len <= 8'd0;
                    overflow_seen <= 1'b0;
                    buffer <= {(MAX_LINE_BYTES*8){1'b0}};
                end else if (byte_data == 8'h0D) begin
                    // Ignore CR.
                end else if (write_len < MAX_LINE_BYTES) begin
                    buffer[(write_len*8) +: 8] <= byte_data;
                    write_len <= write_len + 1'b1;
                end else begin
                    overflow_seen <= 1'b1;
                end
            end
        end
    end
endmodule
