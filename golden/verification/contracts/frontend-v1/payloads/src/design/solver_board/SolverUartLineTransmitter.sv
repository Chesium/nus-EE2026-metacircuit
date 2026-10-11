`timescale 1ns / 1ps

module SolverUartLineTransmitter #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer BAUD = 115200
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [1:0]  mode,
    input  wire [15:0] frame,
    input  wire [7:0]  node_count,
    input  wire [7:0]  status,
    input  wire [7:0]  node_idx,
    input  wire [31:0] node_value_bits,
    input  wire [7:0]  error_code,
    input  wire [15:0] error_arg,
    output wire        tx,
    output reg         busy = 1'b0,
    output reg         done = 1'b0
);

    localparam [1:0] MODE_VB = 2'd0;
    localparam [1:0] MODE_VN = 2'd1;
    localparam [1:0] MODE_VE = 2'd2;
    localparam [1:0] MODE_ER = 2'd3;

    reg  [1:0]  line_mode = MODE_VB;
    reg  [15:0] line_frame = 16'd0;
    reg  [7:0]  line_node_count = 8'd0;
    reg  [7:0]  line_status = 8'd0;
    reg  [7:0]  line_node_idx = 8'd0;
    reg  [31:0] line_node_value_bits = 32'd0;
    reg  [7:0]  line_error_code = 8'd0;
    reg  [15:0] line_error_arg = 16'd0;

    reg         uart_start = 1'b0;
    reg  [7:0]  uart_data = 8'h00;
    wire        uart_busy;

    reg         wait_busy = 1'b0;
    reg  [5:0]  char_index = 6'd0;
    reg  [5:0]  line_len = 6'd0;
    reg         last_char = 1'b0;

    function automatic [7:0] ascii_hex_nibble;
        input [3:0] nibble;
        begin
            ascii_hex_nibble = (nibble < 4'd10) ? (8'd48 + nibble) : (8'd55 + nibble);
        end
    endfunction

    function automatic [5:0] payload_len_for_mode;
        input [1:0] tx_mode;
        begin
            case (tx_mode)
                MODE_VB: payload_len_for_mode = 6'd13;
                MODE_VN: payload_len_for_mode = 6'd19;
                MODE_VE: payload_len_for_mode = 6'd13;
                default: payload_len_for_mode = 6'd15;
            endcase
        end
    endfunction

    function automatic [7:0] payload_char;
        input [1:0] tx_mode;
        input [5:0] idx;
        input [15:0] tx_frame;
        input [7:0] tx_node_count;
        input [7:0] tx_status;
        input [7:0] tx_node_idx;
        input [31:0] tx_node_value_bits;
        input [7:0] tx_error_code;
        input [15:0] tx_error_arg;
        begin
            payload_char = 8'h20;
            case (tx_mode)
                MODE_VB, MODE_VE: begin
                    case (idx)
                        6'd0: payload_char = "V";
                        6'd1: payload_char = (tx_mode == MODE_VB) ? "B" : "E";
                        6'd2: payload_char = ",";
                        6'd3: payload_char = ascii_hex_nibble(tx_frame[15:12]);
                        6'd4: payload_char = ascii_hex_nibble(tx_frame[11:8]);
                        6'd5: payload_char = ascii_hex_nibble(tx_frame[7:4]);
                        6'd6: payload_char = ascii_hex_nibble(tx_frame[3:0]);
                        6'd7: payload_char = ",";
                        6'd8: payload_char = ascii_hex_nibble(tx_node_count[7:4]);
                        6'd9: payload_char = ascii_hex_nibble(tx_node_count[3:0]);
                        6'd10: payload_char = ",";
                        6'd11: payload_char = ascii_hex_nibble(tx_status[7:4]);
                        default: payload_char = ascii_hex_nibble(tx_status[3:0]);
                    endcase
                end
                MODE_VN: begin
                    case (idx)
                        6'd0: payload_char = "V";
                        6'd1: payload_char = "N";
                        6'd2: payload_char = ",";
                        6'd3: payload_char = ascii_hex_nibble(tx_frame[15:12]);
                        6'd4: payload_char = ascii_hex_nibble(tx_frame[11:8]);
                        6'd5: payload_char = ascii_hex_nibble(tx_frame[7:4]);
                        6'd6: payload_char = ascii_hex_nibble(tx_frame[3:0]);
                        6'd7: payload_char = ",";
                        6'd8: payload_char = ascii_hex_nibble(tx_node_idx[7:4]);
                        6'd9: payload_char = ascii_hex_nibble(tx_node_idx[3:0]);
                        6'd10: payload_char = ",";
                        6'd11: payload_char = ascii_hex_nibble(tx_node_value_bits[31:28]);
                        6'd12: payload_char = ascii_hex_nibble(tx_node_value_bits[27:24]);
                        6'd13: payload_char = ascii_hex_nibble(tx_node_value_bits[23:20]);
                        6'd14: payload_char = ascii_hex_nibble(tx_node_value_bits[19:16]);
                        6'd15: payload_char = ascii_hex_nibble(tx_node_value_bits[15:12]);
                        6'd16: payload_char = ascii_hex_nibble(tx_node_value_bits[11:8]);
                        6'd17: payload_char = ascii_hex_nibble(tx_node_value_bits[7:4]);
                        default: payload_char = ascii_hex_nibble(tx_node_value_bits[3:0]);
                    endcase
                end
                default: begin
                    case (idx)
                        6'd0: payload_char = "E";
                        6'd1: payload_char = "R";
                        6'd2: payload_char = ",";
                        6'd3: payload_char = ascii_hex_nibble(tx_frame[15:12]);
                        6'd4: payload_char = ascii_hex_nibble(tx_frame[11:8]);
                        6'd5: payload_char = ascii_hex_nibble(tx_frame[7:4]);
                        6'd6: payload_char = ascii_hex_nibble(tx_frame[3:0]);
                        6'd7: payload_char = ",";
                        6'd8: payload_char = ascii_hex_nibble(tx_error_code[7:4]);
                        6'd9: payload_char = ascii_hex_nibble(tx_error_code[3:0]);
                        6'd10: payload_char = ",";
                        6'd11: payload_char = ascii_hex_nibble(tx_error_arg[15:12]);
                        6'd12: payload_char = ascii_hex_nibble(tx_error_arg[11:8]);
                        6'd13: payload_char = ascii_hex_nibble(tx_error_arg[7:4]);
                        default: payload_char = ascii_hex_nibble(tx_error_arg[3:0]);
                    endcase
                end
            endcase
        end
    endfunction

    function automatic [7:0] payload_checksum;
        input [1:0] tx_mode;
        input [15:0] tx_frame;
        input [7:0] tx_node_count;
        input [7:0] tx_status;
        input [7:0] tx_node_idx;
        input [31:0] tx_node_value_bits;
        input [7:0] tx_error_code;
        input [15:0] tx_error_arg;
        integer idx;
        reg [7:0] checksum;
        begin
            checksum = 8'h00;
            for (idx = 0; idx < payload_len_for_mode(tx_mode); idx = idx + 1) begin
                checksum = checksum ^ payload_char(
                    tx_mode, idx, tx_frame, tx_node_count, tx_status,
                    tx_node_idx, tx_node_value_bits, tx_error_code, tx_error_arg
                );
            end
            payload_checksum = checksum;
        end
    endfunction

    function automatic [7:0] line_char;
        input [5:0] idx;
        input [1:0] tx_mode;
        input [15:0] tx_frame;
        input [7:0] tx_node_count;
        input [7:0] tx_status;
        input [7:0] tx_node_idx;
        input [31:0] tx_node_value_bits;
        input [7:0] tx_error_code;
        input [15:0] tx_error_arg;
        reg [7:0] checksum;
        reg [5:0] payload_len;
        begin
            payload_len = payload_len_for_mode(tx_mode);
            checksum = payload_checksum(
                tx_mode, tx_frame, tx_node_count, tx_status,
                tx_node_idx, tx_node_value_bits, tx_error_code, tx_error_arg
            );
            if (idx == 0) begin
                line_char = "@";
            end else if (idx <= payload_len) begin
                line_char = payload_char(
                    tx_mode, idx - 1'b1, tx_frame, tx_node_count, tx_status,
                    tx_node_idx, tx_node_value_bits, tx_error_code, tx_error_arg
                );
            end else if (idx == payload_len + 1'b1) begin
                line_char = "*";
            end else if (idx == payload_len + 2'd2) begin
                line_char = ascii_hex_nibble(checksum[7:4]);
            end else if (idx == payload_len + 2'd3) begin
                line_char = ascii_hex_nibble(checksum[3:0]);
            end else if (idx == payload_len + 3'd4) begin
                line_char = 8'h0D;
            end else begin
                line_char = 8'h0A;
            end
        end
    endfunction

    UartTx #(
        .ClkHz(CLK_FREQ_HZ),
        .BAUD(BAUD)
    ) uart_tx_inst (
        .clk(clk),
        .start(uart_start),
        .data(uart_data),
        .tx(tx),
        .busy(uart_busy)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            line_mode <= MODE_VB;
            line_frame <= 16'd0;
            line_node_count <= 8'd0;
            line_status <= 8'd0;
            line_node_idx <= 8'd0;
            line_node_value_bits <= 32'd0;
            line_error_code <= 8'd0;
            line_error_arg <= 16'd0;
            busy <= 1'b0;
            done <= 1'b0;
            uart_start <= 1'b0;
            uart_data <= 8'h00;
            wait_busy <= 1'b0;
            char_index <= 6'd0;
            line_len <= 6'd0;
            last_char <= 1'b0;
        end else begin
            done <= 1'b0;
            uart_start <= 1'b0;

            if (!busy) begin
                if (start) begin
                    line_mode <= mode;
                    line_frame <= frame;
                    line_node_count <= node_count;
                    line_status <= status;
                    line_node_idx <= node_idx;
                    line_node_value_bits <= node_value_bits;
                    line_error_code <= error_code;
                    line_error_arg <= error_arg;
                    line_len <= payload_len_for_mode(mode) + 6'd6;
                    busy <= 1'b1;
                    wait_busy <= 1'b1;
                    char_index <= 6'd1;
                    last_char <= (payload_len_for_mode(mode) + 6'd6 == 6'd1);
                    uart_data <= line_char(
                        6'd0, mode, frame, node_count, status,
                        node_idx, node_value_bits, error_code, error_arg
                    );
                    uart_start <= 1'b1;
                end
            end else if (wait_busy) begin
                if (uart_busy) begin
                    wait_busy <= 1'b0;
                end
            end else if (!uart_busy) begin
                if (last_char) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    last_char <= 1'b0;
                end else begin
                    uart_data <= line_char(
                        char_index, line_mode, line_frame, line_node_count, line_status,
                        line_node_idx, line_node_value_bits, line_error_code, line_error_arg
                    );
                    uart_start <= 1'b1;
                    last_char <= (char_index == line_len - 1'b1);
                    char_index <= char_index + 1'b1;
                    wait_busy <= 1'b1;
                end
            end
        end
    end
endmodule
