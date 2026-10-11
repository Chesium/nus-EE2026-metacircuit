`timescale 1ns / 1ps

module UartPacketParser #(
    parameter integer MAX_LINE_BYTES = 48,
    parameter integer MAX_ELEMS = 32,
    parameter integer MAX_NODES = 32
) (
    input  wire                           clk,
    input  wire                           rst_n,
    input  wire                           line_valid,
    input  wire                           line_overflow,
    input  wire [7:0]                     line_len,
    input  wire [MAX_LINE_BYTES*8-1:0]    line_data,

    output reg                            snapshot_begin_valid = 1'b0,
    output reg [15:0]                     snapshot_begin_frame = 16'd0,
    output reg [7:0]                      snapshot_begin_elem_count = 8'd0,
    output reg [7:0]                      snapshot_begin_node_count = 8'd0,

    output reg                            component_valid = 1'b0,
    output reg [15:0]                     component_frame = 16'd0,
    output reg [7:0]                      component_idx = 8'd0,
    output reg [7:0]                      component_kind = 8'd0,
    output reg [7:0]                      component_n0 = 8'd0,
    output reg [7:0]                      component_n1 = 8'd0,
    output reg [11:0]                     component_value_bcd = 12'd0,
    output reg [7:0]                      component_unit = 8'd0,

    output reg                            snapshot_end_valid = 1'b0,
    output reg [15:0]                     snapshot_end_frame = 16'd0,
    output reg [7:0]                      snapshot_end_elem_count = 8'd0,
    output reg [7:0]                      snapshot_end_node_count = 8'd0,

    output reg                            parse_error = 1'b0,
    output reg [7:0]                      parse_error_code = 8'd0,
    output reg [15:0]                     parse_error_arg = 16'd0,
    output reg [15:0]                     parse_error_frame = 16'd0
);

    localparam [7:0] ERR_PARSE = 8'h01;
    localparam [7:0] ERR_RANGE = 8'h02;

    reg        in_snapshot = 1'b0;
    reg [15:0] expected_frame = 16'd0;
    reg [7:0]  expected_elem_count = 8'd0;
    reg [7:0]  expected_node_count = 8'd0;
    reg [7:0]  next_component_idx = 8'd0;

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

    function automatic [11:0] parse_hex3;
        input [MAX_LINE_BYTES*8-1:0] data;
        input integer pos;
        begin
            parse_hex3 = {
                hex_nibble(byte_at(data, pos)),
                hex_nibble(byte_at(data, pos + 1)),
                hex_nibble(byte_at(data, pos + 2))
            };
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
        input [15:0] frame;
        begin
            parse_error <= 1'b1;
            parse_error_code <= code;
            parse_error_arg <= arg;
            parse_error_frame <= frame;
            in_snapshot <= 1'b0;
            next_component_idx <= 8'd0;
        end
    endtask

    reg [7:0] checksum_actual;
    reg [7:0] checksum_line;
    reg [15:0] frame_value;
    reg [7:0] elem_count_value;
    reg [7:0] node_count_value;
    reg [7:0] idx_value;
    reg [7:0] kind_value;
    reg [7:0] n0_value;
    reg [7:0] n1_value;
    reg [11:0] value_bcd_value;
    reg [7:0] unit_value;

    always @(posedge clk) begin
        if (!rst_n) begin
            snapshot_begin_valid <= 1'b0;
            component_valid <= 1'b0;
            snapshot_end_valid <= 1'b0;
            parse_error <= 1'b0;
            parse_error_code <= 8'd0;
            parse_error_arg <= 16'd0;
            parse_error_frame <= 16'd0;
            in_snapshot <= 1'b0;
            expected_frame <= 16'd0;
            expected_elem_count <= 8'd0;
            expected_node_count <= 8'd0;
            next_component_idx <= 8'd0;
        end else begin
            snapshot_begin_valid <= 1'b0;
            component_valid <= 1'b0;
            snapshot_end_valid <= 1'b0;
            parse_error <= 1'b0;

            if (line_valid) begin
                if (line_overflow) begin
                    raise_error(ERR_PARSE, 16'h00FF, expected_frame);
                end else if ((line_len == 8'd17) &&
                             (byte_at(line_data, 0) == "@") &&
                             (byte_at(line_data, 1) == "N") &&
                             (byte_at(line_data, 2) == "B") &&
                             (byte_at(line_data, 3) == ",") &&
                             (byte_at(line_data, 8) == ",") &&
                             (byte_at(line_data, 11) == ",") &&
                             (byte_at(line_data, 14) == "*")) begin
                    if (!(valid_field_hex(line_data, 4, 4) &&
                          valid_field_hex(line_data, 9, 2) &&
                          valid_field_hex(line_data, 12, 2) &&
                          valid_field_hex(line_data, 15, 2))) begin
                        raise_error(ERR_PARSE, 16'h0002, expected_frame);
                    end else begin
                        checksum_actual = compute_checksum(line_data, 1, 13);
                        checksum_line = parse_hex2(line_data, 15);
                        frame_value = parse_hex4(line_data, 4);
                        elem_count_value = parse_hex2(line_data, 9);
                        node_count_value = parse_hex2(line_data, 12);
                        if (checksum_actual != checksum_line) begin
                            raise_error(ERR_PARSE, 16'h0003, frame_value);
                        end else if (in_snapshot) begin
                            raise_error(ERR_PARSE, 16'h0004, frame_value);
                        end else if ((elem_count_value > MAX_ELEMS) || (node_count_value > MAX_NODES)) begin
                            raise_error(ERR_RANGE, {elem_count_value, node_count_value}, frame_value);
                        end else begin
                            in_snapshot <= 1'b1;
                            expected_frame <= frame_value;
                            expected_elem_count <= elem_count_value;
                            expected_node_count <= node_count_value;
                            next_component_idx <= 8'd0;
                            snapshot_begin_valid <= 1'b1;
                            snapshot_begin_frame <= frame_value;
                            snapshot_begin_elem_count <= elem_count_value;
                            snapshot_begin_node_count <= node_count_value;
                        end
                    end
                end else if ((line_len == 8'd30) &&
                             (byte_at(line_data, 0) == "@") &&
                             (byte_at(line_data, 1) == "N") &&
                             (byte_at(line_data, 2) == "C") &&
                             (byte_at(line_data, 3) == ",") &&
                             (byte_at(line_data, 8) == ",") &&
                             (byte_at(line_data, 11) == ",") &&
                             (byte_at(line_data, 14) == ",") &&
                             (byte_at(line_data, 17) == ",") &&
                             (byte_at(line_data, 20) == ",") &&
                             (byte_at(line_data, 24) == ",") &&
                             (byte_at(line_data, 27) == "*")) begin
                    if (!(valid_field_hex(line_data, 4, 4) &&
                          valid_field_hex(line_data, 9, 2) &&
                          valid_field_hex(line_data, 12, 2) &&
                          valid_field_hex(line_data, 15, 2) &&
                          valid_field_hex(line_data, 18, 2) &&
                          valid_field_hex(line_data, 21, 3) &&
                          valid_field_hex(line_data, 25, 2) &&
                          valid_field_hex(line_data, 28, 2))) begin
                        raise_error(ERR_PARSE, 16'h0005, expected_frame);
                    end else begin
                        checksum_actual = compute_checksum(line_data, 1, 26);
                        checksum_line = parse_hex2(line_data, 28);
                        frame_value = parse_hex4(line_data, 4);
                        idx_value = parse_hex2(line_data, 9);
                        kind_value = parse_hex2(line_data, 12);
                        n0_value = parse_hex2(line_data, 15);
                        n1_value = parse_hex2(line_data, 18);
                        value_bcd_value = parse_hex3(line_data, 21);
                        unit_value = parse_hex2(line_data, 25);

                        if (checksum_actual != checksum_line) begin
                            raise_error(ERR_PARSE, 16'h0006, frame_value);
                        end else if (!in_snapshot) begin
                            raise_error(ERR_PARSE, 16'h0007, frame_value);
                        end else if (frame_value != expected_frame) begin
                            raise_error(ERR_PARSE, 16'h0008, frame_value);
                        end else if (idx_value != next_component_idx) begin
                            raise_error(ERR_PARSE, {8'h00, idx_value}, frame_value);
                        end else if (!((kind_value == 8'h01) || (kind_value == 8'h02) || (kind_value == 8'h03))) begin
                            raise_error(ERR_RANGE, {8'h01, kind_value}, frame_value);
                        end else if (!(((n0_value < MAX_NODES) || (n0_value == 8'hFF)) &&
                                       ((n1_value < MAX_NODES) || (n1_value == 8'hFF)))) begin
                            raise_error(ERR_RANGE, {n0_value, n1_value}, frame_value);
                        end else begin
                            component_valid <= 1'b1;
                            component_frame <= frame_value;
                            component_idx <= idx_value;
                            component_kind <= kind_value;
                            component_n0 <= n0_value;
                            component_n1 <= n1_value;
                            component_value_bcd <= value_bcd_value;
                            component_unit <= unit_value;
                            next_component_idx <= next_component_idx + 1'b1;
                        end
                    end
                end else if ((line_len == 8'd17) &&
                             (byte_at(line_data, 0) == "@") &&
                             (byte_at(line_data, 1) == "N") &&
                             (byte_at(line_data, 2) == "E") &&
                             (byte_at(line_data, 3) == ",") &&
                             (byte_at(line_data, 8) == ",") &&
                             (byte_at(line_data, 11) == ",") &&
                             (byte_at(line_data, 14) == "*")) begin
                    if (!(valid_field_hex(line_data, 4, 4) &&
                          valid_field_hex(line_data, 9, 2) &&
                          valid_field_hex(line_data, 12, 2) &&
                          valid_field_hex(line_data, 15, 2))) begin
                        raise_error(ERR_PARSE, 16'h0009, expected_frame);
                    end else begin
                        checksum_actual = compute_checksum(line_data, 1, 13);
                        checksum_line = parse_hex2(line_data, 15);
                        frame_value = parse_hex4(line_data, 4);
                        elem_count_value = parse_hex2(line_data, 9);
                        node_count_value = parse_hex2(line_data, 12);
                        if (checksum_actual != checksum_line) begin
                            raise_error(ERR_PARSE, 16'h000A, frame_value);
                        end else if (!in_snapshot) begin
                            raise_error(ERR_PARSE, 16'h000B, frame_value);
                        end else if ((frame_value != expected_frame) ||
                                     (elem_count_value != expected_elem_count) ||
                                     (node_count_value != expected_node_count)) begin
                            raise_error(ERR_PARSE, 16'h000C, frame_value);
                        end else if (next_component_idx != expected_elem_count) begin
                            raise_error(ERR_PARSE, {8'h00, next_component_idx}, frame_value);
                        end else begin
                            in_snapshot <= 1'b0;
                            snapshot_end_valid <= 1'b1;
                            snapshot_end_frame <= frame_value;
                            snapshot_end_elem_count <= elem_count_value;
                            snapshot_end_node_count <= node_count_value;
                        end
                    end
                end else begin
                    raise_error(ERR_PARSE, line_len, expected_frame);
                end
            end
        end
    end
endmodule
