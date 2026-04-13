`timescale 1ns / 1ps

module FrontendVoltagePacketParser_test;

    localparam integer MAX_LINE_BYTES = 48;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg line_valid = 1'b0;
    reg line_overflow = 1'b0;
    reg [7:0] line_len = 8'd0;
    reg [MAX_LINE_BYTES*8-1:0] line_data = {(MAX_LINE_BYTES*8){1'b0}};

    wire        voltage_begin_valid;
    wire [15:0] voltage_begin_frame;
    wire [7:0]  voltage_begin_node_count;
    wire [7:0]  voltage_begin_status;
    wire        voltage_node_valid;
    wire [15:0] voltage_node_frame;
    wire [7:0]  voltage_node_idx;
    wire [31:0] voltage_node_value_bits;
    wire        voltage_end_valid;
    wire [15:0] voltage_end_frame;
    wire [7:0]  voltage_end_node_count;
    wire [7:0]  voltage_end_status;
    wire        error_packet_valid;
    wire [15:0] error_packet_frame;
    wire [7:0]  error_packet_code;
    wire [15:0] error_packet_arg;
    wire        parse_error;
    wire [7:0]  parse_error_code;
    wire [15:0] parse_error_arg;

    FrontendVoltagePacketParser #(
        .MAX_LINE_BYTES(MAX_LINE_BYTES),
        .MAX_NODES(32)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .line_valid(line_valid),
        .line_overflow(line_overflow),
        .line_len(line_len),
        .line_data(line_data),
        .voltage_begin_valid(voltage_begin_valid),
        .voltage_begin_frame(voltage_begin_frame),
        .voltage_begin_node_count(voltage_begin_node_count),
        .voltage_begin_status(voltage_begin_status),
        .voltage_node_valid(voltage_node_valid),
        .voltage_node_frame(voltage_node_frame),
        .voltage_node_idx(voltage_node_idx),
        .voltage_node_value_bits(voltage_node_value_bits),
        .voltage_end_valid(voltage_end_valid),
        .voltage_end_frame(voltage_end_frame),
        .voltage_end_node_count(voltage_end_node_count),
        .voltage_end_status(voltage_end_status),
        .error_packet_valid(error_packet_valid),
        .error_packet_frame(error_packet_frame),
        .error_packet_code(error_packet_code),
        .error_packet_arg(error_packet_arg),
        .parse_error(parse_error),
        .parse_error_code(parse_error_code),
        .parse_error_arg(parse_error_arg)
    );

    always #5 clk = ~clk;

    task automatic drive_line;
        input [8*64-1:0] text;
        integer idx;
        integer length;
        reg [7:0] ch;
        begin
            line_data = {(MAX_LINE_BYTES*8){1'b0}};
            length = 0;
            for (idx = 63; idx >= 0; idx = idx - 1) begin
                ch = text[idx*8 +: 8];
                if (ch != 8'h00) begin
                    line_data[length*8 +: 8] = ch;
                    length = length + 1;
                end
            end
            @(posedge clk);
            line_len <= length[7:0];
            line_valid <= 1'b1;
            @(posedge clk);
            line_valid <= 1'b0;
            line_len <= 8'd0;
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        drive_line("@VB,0001,02,00*3B");
        @(posedge clk);
        if (!voltage_begin_valid || voltage_begin_frame != 16'h0001 ||
            voltage_begin_node_count != 8'h02 || voltage_begin_status != 8'h00) begin
            $fatal(1, "VB parse failed");
        end

        drive_line("@VN,0001,00,43FA0000*35");
        @(posedge clk);
        if (!voltage_node_valid || voltage_node_frame != 16'h0001 ||
            voltage_node_idx != 8'h00 || voltage_node_value_bits != 32'h43FA0000) begin
            $fatal(1, "VN parse failed");
        end

        drive_line("@VE,0001,02,00*3C");
        @(posedge clk);
        if (!voltage_end_valid || voltage_end_frame != 16'h0001 ||
            voltage_end_node_count != 8'h02 || voltage_end_status != 8'h00) begin
            $fatal(1, "VE parse failed");
        end

        drive_line("@ER,0002,81,0003*33");
        @(posedge clk);
        if (!error_packet_valid || error_packet_frame != 16'h0002 ||
            error_packet_code != 8'h81 || error_packet_arg != 16'h0003) begin
            $display("ER debug: valid=%0d frame=%h code=%h arg=%h parse_err=%0d parse_code=%h parse_arg=%h",
                error_packet_valid, error_packet_frame, error_packet_code, error_packet_arg,
                parse_error, parse_error_code, parse_error_arg);
            $fatal(1, "ER parse failed");
        end

        drive_line("@VB,0001,02,00*00");
        @(posedge clk);
        if (!parse_error || parse_error_code != 8'h01) begin
            $fatal(1, "checksum error was not detected");
        end

        $display("FrontendVoltagePacketParser_test passed.");
        $finish;
    end

endmodule
