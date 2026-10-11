`timescale 1ns / 1ps

module FrontendVoltagePacketParser #(
    parameter integer MAX_LINE_BYTES = 48,
    parameter integer MAX_NODES = 32
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           line_valid,
    input  wire                           line_overflow,
    input  wire [7:0]                     line_len,
    input  wire [MAX_LINE_BYTES*8-1:0]    line_data,

    output reg                            voltage_begin_valid = 1'b0,
    output reg [15:0]                     voltage_begin_frame = 16'd0,
    output reg [7:0]                      voltage_begin_node_count = 8'd0,
    output reg [7:0]                      voltage_begin_status = 8'd0,

    output reg                            voltage_node_valid = 1'b0,
    output reg [15:0]                     voltage_node_frame = 16'd0,
    output reg [7:0]                      voltage_node_idx = 8'd0,
    output reg [31:0]                     voltage_node_value_bits = 32'd0,

    output reg                            voltage_end_valid = 1'b0,
    output reg [15:0]                     voltage_end_frame = 16'd0,
    output reg [7:0]                      voltage_end_node_count = 8'd0,
    output reg [7:0]                      voltage_end_status = 8'd0,

    output reg                            error_packet_valid = 1'b0,
    output reg [15:0]                     error_packet_frame = 16'd0,
    output reg [7:0]                      error_packet_code = 8'd0,
    output reg [15:0]                     error_packet_arg = 16'd0,

    output reg                            parse_error = 1'b0,
    output reg [7:0]                      parse_error_code = 8'd0,
    output reg [15:0]                     parse_error_arg = 16'd0
);

    localparam [7:0] ERR_PARSE = 8'h01;
    localparam [7:0] ERR_RANGE = 8'h02;

    function automatic [7:0] byte_at;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer idx;
        begin
            byte_at = data[(idx*8) +: 8];
        end
    endfunction

    function automatic is_hex_char;
        input [7:0] ch;
        begin
            is_hex_char =
                ((ch >= "0") && (ch <= "9")) ||
                ((ch >= "A") && (ch <= "F"));
        end
    endfunction

    function automatic [3:0] hex_nibble;
        input [7:0] ch;
        begin
            if ((ch >= "0") && (ch <= "9")) begin
                hex_nibble = ch - "0";
            end else begin
                hex_nibble = ch - "A" + 4'd10;
            end
        end
    endfunction

    function automatic [7:0] parse_hex2;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer pos;
        begin
            parse_hex2 = {hex_nibble(byte_at(data, pos)), hex_nibble(byte_at(data, pos + 1))};
        end
    endfunction

    function automatic [15:0] parse_hex4;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer pos;
        begin
            parse_hex4 = {
                hex_nibble(byte_at(data, pos)),
                hex_nibble(byte_at(data, pos + 1)),
                hex_nibble(byte_at(data, pos + 2)),
                hex_nibble(byte_at(data, pos + 3))
            };
        end
    endfunction

    function automatic [31:0] parse_hex8;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer pos;
        begin
            parse_hex8 = {
                hex_nibble(byte_at(data, pos)),
                hex_nibble(byte_at(data, pos + 1)),
                hex_nibble(byte_at(data, pos + 2)),
                hex_nibble(byte_at(data, pos + 3)),
                hex_nibble(byte_at(data, pos + 4)),
                hex_nibble(byte_at(data, pos + 5)),
                hex_nibble(byte_at(data, pos + 6)),
                hex_nibble(byte_at(data, pos + 7))
            };
        end
    endfunction

    function automatic valid_field_hex;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer pos;
        input integer width;
        integer idx;
        begin
            valid_field_hex = 1'b1;
            for (idx = 0; idx < width; idx = idx + 1) begin
                if (!is_hex_char(byte_at(data, pos + idx))) begin
                    valid_field_hex = 1'b0;
                end
            end
        end
    endfunction

    function automatic [7:0] compute_checksum;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer start_idx;
        input integer end_idx;
        integer idx;
        begin
            compute_checksum = 8'h00;
            for (idx = start_idx; idx <= end_idx; idx = idx + 1) begin
                compute_checksum = compute_checksum ^ byte_at(data, idx);
            end
        end
    endfunction

    task automatic raise_error;
        input [7:0] code;
        input [15:0] arg;
        begin
            parse_error <= 1'b1;
            parse_error_code <= code;
            parse_error_arg <= arg;
        end
    endtask

    reg [7:0] checksum_actual;
    reg [7:0] checksum_line;
    reg [15:0] frame_value;
    reg [7:0] node_count_value;
    reg [7:0] status_value;
    reg [7:0] node_idx_value;
    reg [31:0] node_value_bits_value;
    reg [7:0] error_code_value;
    reg [15:0] error_arg_value;

    always @(posedge clk) begin
        if (!rst_n) begin
            voltage_begin_valid <= 1'b0;
            voltage_node_valid <= 1'b0;
            voltage_end_valid <= 1'b0;
            error_packet_valid <= 1'b0;
            parse_error <= 1'b0;
            parse_error_code <= 8'd0;
            parse_error_arg <= 16'd0;
        end else begin
            voltage_begin_valid <= 1'b0;
            voltage_node_valid <= 1'b0;
            voltage_end_valid <= 1'b0;
            error_packet_valid <= 1'b0;
            parse_error <= 1'b0;

            if (line_valid) begin
                if (line_overflow) begin
                    raise_error(ERR_PARSE, 16'h00FF);
                end else if ((line_len == 8'd17) &&
                             (byte_at(line_data, 0) == "@") &&
                             (byte_at(line_data, 1) == "V") &&
                             ((byte_at(line_data, 2) == "B") || (byte_at(line_data, 2) == "E")) &&
                             (byte_at(line_data, 3) == ",") &&
                             (byte_at(line_data, 8) == ",") &&
                             (byte_at(line_data, 11) == ",") &&
                             (byte_at(line_data, 14) == "*")) begin
                    if (!(valid_field_hex(line_data, 4, 4) &&
                          valid_field_hex(line_data, 9, 2) &&
                          valid_field_hex(line_data, 12, 2) &&
                          valid_field_hex(line_data, 15, 2))) begin
                        raise_error(ERR_PARSE, 16'h0002);
                    end else begin
                        checksum_actual = compute_checksum(line_data, 1, 13);
                        checksum_line = parse_hex2(line_data, 15);
                        frame_value = parse_hex4(line_data, 4);
                        node_count_value = parse_hex2(line_data, 9);
                        status_value = parse_hex2(line_data, 12);
                        if (checksum_actual != checksum_line) begin
                            raise_error(ERR_PARSE, 16'h0003);
                        end else if (node_count_value > MAX_NODES) begin
                            raise_error(ERR_RANGE, {8'h00, node_count_value});
                        end else if (byte_at(line_data, 2) == "B") begin
                            voltage_begin_valid <= 1'b1;
                            voltage_begin_frame <= frame_value;
                            voltage_begin_node_count <= node_count_value;
                            voltage_begin_status <= status_value;
                        end else begin
                            voltage_end_valid <= 1'b1;
                            voltage_end_frame <= frame_value;
                            voltage_end_node_count <= node_count_value;
                            voltage_end_status <= status_value;
                        end
                    end
                end else if ((line_len == 8'd23) &&
                             (byte_at(line_data, 0) == "@") &&
                             (byte_at(line_data, 1) == "V") &&
                             (byte_at(line_data, 2) == "N") &&
                             (byte_at(line_data, 3) == ",") &&
                             (byte_at(line_data, 8) == ",") &&
                             (byte_at(line_data, 11) == ",") &&
                             (byte_at(line_data, 20) == "*")) begin
                    if (!(valid_field_hex(line_data, 4, 4) &&
                          valid_field_hex(line_data, 9, 2) &&
                          valid_field_hex(line_data, 12, 8) &&
                          valid_field_hex(line_data, 21, 2))) begin
                        raise_error(ERR_PARSE, 16'h0004);
                    end else begin
                        checksum_actual = compute_checksum(line_data, 1, 19);
                        checksum_line = parse_hex2(line_data, 21);
                        frame_value = parse_hex4(line_data, 4);
                        node_idx_value = parse_hex2(line_data, 9);
                        node_value_bits_value = parse_hex8(line_data, 12);
                        if (checksum_actual != checksum_line) begin
                            raise_error(ERR_PARSE, 16'h0005);
                        end else if (node_idx_value >= MAX_NODES) begin
                            raise_error(ERR_RANGE, {8'h00, node_idx_value});
                        end else begin
                            voltage_node_valid <= 1'b1;
                            voltage_node_frame <= frame_value;
                            voltage_node_idx <= node_idx_value;
                            voltage_node_value_bits <= node_value_bits_value;
                        end
                    end
                end else if ((line_len == 8'd19) &&
                             (byte_at(line_data, 0) == "@") &&
                             (byte_at(line_data, 1) == "E") &&
                             (byte_at(line_data, 2) == "R") &&
                             (byte_at(line_data, 3) == ",") &&
                             (byte_at(line_data, 8) == ",") &&
                             (byte_at(line_data, 11) == ",") &&
                             (byte_at(line_data, 16) == "*")) begin
                    if (!(valid_field_hex(line_data, 4, 4) &&
                          valid_field_hex(line_data, 9, 2) &&
                          valid_field_hex(line_data, 12, 4) &&
                          valid_field_hex(line_data, 17, 2))) begin
                        raise_error(ERR_PARSE, 16'h0006);
                    end else begin
                        checksum_actual = compute_checksum(line_data, 1, 15);
                        checksum_line = parse_hex2(line_data, 17);
                        frame_value = parse_hex4(line_data, 4);
                        error_code_value = parse_hex2(line_data, 9);
                        error_arg_value = parse_hex4(line_data, 12);
                        if (checksum_actual != checksum_line) begin
                            raise_error(ERR_PARSE, 16'h0007);
                        end else begin
                            error_packet_valid <= 1'b1;
                            error_packet_frame <= frame_value;
                            error_packet_code <= error_code_value;
                            error_packet_arg <= error_arg_value;
                        end
                    end
                end else begin
                    raise_error(ERR_PARSE, line_len);
                end
            end
        end
    end
endmodule
