`timescale 1ns / 1ps

module UART_FrameDemo_top (
    input  wire        CLK100MHZ,
    input  wire [15:0] SW,
    output reg  [15:0] LED = 16'h0000,
    output wire [7:0]  SEG,
    output wire [3:0]  AN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTND,
    input  wire        RsRx,
    output wire        RsTx
);

    localparam integer ClkHz = 100_000_000;
    localparam integer UARTBaud = 115200;
    localparam integer FrameHz = 60;
    localparam integer PacketLen = 43;

    reg [26:0] frame_accum = 27'd0;
    reg        frame_tick = 1'b0;
    reg [31:0] free_run_counter = 32'd0;
    reg [31:0] frame_counter = 32'd0;
    reg [15:0] lfsr = 16'h1ACE;
    reg [15:0] drop_counter = 16'd0;

    reg stream_enable = 1'b1;
    reg frame_blink = 1'b0;
    reg drop_pulse = 1'b0;

    reg btnc_d = 1'b0;
    reg btnu_d = 1'b0;
    reg btnl_d = 1'b0;
    reg btnr_d = 1'b0;
    reg btnd_d = 1'b0;

    reg [2:0] page_index = 3'd0;

    reg [31:0] snap_frame_counter = 32'd0;
    reg [31:0] snap_cycle_counter = 32'd0;
    reg [15:0] snap_switches = 16'd0;
    reg [7:0]  snap_buttons = 8'd0;
    reg [15:0] snap_lfsr = 16'd0;
    reg [15:0] snap_drop_counter = 16'd0;

    reg        packet_pending = 1'b0;
    reg        packet_sending = 1'b0;
    reg        last_char_inflight = 1'b0;
    reg [5:0]  packet_index = 6'd0;
    reg        uart_start = 1'b0;
    reg [7:0]  uart_data = 8'h00;
    wire       uart_busy;

    reg [15:0] seg_hex_value = 16'h0000;
    wire frame_request = (stream_enable && frame_tick) || (BTNC && !btnc_d);
    wire clear_request = BTND && !btnd_d;

    function [7:0] ascii_hex;
        input [3:0] nibble;
        begin
            case (nibble)
                4'h0: ascii_hex = "0";
                4'h1: ascii_hex = "1";
                4'h2: ascii_hex = "2";
                4'h3: ascii_hex = "3";
                4'h4: ascii_hex = "4";
                4'h5: ascii_hex = "5";
                4'h6: ascii_hex = "6";
                4'h7: ascii_hex = "7";
                4'h8: ascii_hex = "8";
                4'h9: ascii_hex = "9";
                4'hA: ascii_hex = "A";
                4'hB: ascii_hex = "B";
                4'hC: ascii_hex = "C";
                4'hD: ascii_hex = "D";
                4'hE: ascii_hex = "E";
                default: ascii_hex = "F";
            endcase
        end
    endfunction

    function [7:0] hex32_char;
        input [31:0] value;
        input [2:0] index;
        begin
            case (index)
                3'd0: hex32_char = ascii_hex(value[31:28]);
                3'd1: hex32_char = ascii_hex(value[27:24]);
                3'd2: hex32_char = ascii_hex(value[23:20]);
                3'd3: hex32_char = ascii_hex(value[19:16]);
                3'd4: hex32_char = ascii_hex(value[15:12]);
                3'd5: hex32_char = ascii_hex(value[11:8]);
                3'd6: hex32_char = ascii_hex(value[7:4]);
                default: hex32_char = ascii_hex(value[3:0]);
            endcase
        end
    endfunction

    function [7:0] hex16_char;
        input [15:0] value;
        input [1:0] index;
        begin
            case (index)
                2'd0: hex16_char = ascii_hex(value[15:12]);
                2'd1: hex16_char = ascii_hex(value[11:8]);
                2'd2: hex16_char = ascii_hex(value[7:4]);
                default: hex16_char = ascii_hex(value[3:0]);
            endcase
        end
    endfunction

    function [7:0] hex8_char;
        input [7:0] value;
        input index;
        begin
            if (!index) begin
                hex8_char = ascii_hex(value[7:4]);
            end else begin
                hex8_char = ascii_hex(value[3:0]);
            end
        end
    endfunction

    function [7:0] packet_char;
        input [5:0] index;
        begin
            case (index)
                6'd0:  packet_char = "F";
                6'd1:  packet_char = hex32_char(snap_frame_counter, 3'd0);
                6'd2:  packet_char = hex32_char(snap_frame_counter, 3'd1);
                6'd3:  packet_char = hex32_char(snap_frame_counter, 3'd2);
                6'd4:  packet_char = hex32_char(snap_frame_counter, 3'd3);
                6'd5:  packet_char = hex32_char(snap_frame_counter, 3'd4);
                6'd6:  packet_char = hex32_char(snap_frame_counter, 3'd5);
                6'd7:  packet_char = hex32_char(snap_frame_counter, 3'd6);
                6'd8:  packet_char = hex32_char(snap_frame_counter, 3'd7);
                6'd9:  packet_char = " ";
                6'd10: packet_char = "C";
                6'd11: packet_char = hex32_char(snap_cycle_counter, 3'd0);
                6'd12: packet_char = hex32_char(snap_cycle_counter, 3'd1);
                6'd13: packet_char = hex32_char(snap_cycle_counter, 3'd2);
                6'd14: packet_char = hex32_char(snap_cycle_counter, 3'd3);
                6'd15: packet_char = hex32_char(snap_cycle_counter, 3'd4);
                6'd16: packet_char = hex32_char(snap_cycle_counter, 3'd5);
                6'd17: packet_char = hex32_char(snap_cycle_counter, 3'd6);
                6'd18: packet_char = hex32_char(snap_cycle_counter, 3'd7);
                6'd19: packet_char = " ";
                6'd20: packet_char = "S";
                6'd21: packet_char = hex16_char(snap_switches, 2'd0);
                6'd22: packet_char = hex16_char(snap_switches, 2'd1);
                6'd23: packet_char = hex16_char(snap_switches, 2'd2);
                6'd24: packet_char = hex16_char(snap_switches, 2'd3);
                6'd25: packet_char = " ";
                6'd26: packet_char = "B";
                6'd27: packet_char = hex8_char(snap_buttons, 1'b0);
                6'd28: packet_char = hex8_char(snap_buttons, 1'b1);
                6'd29: packet_char = " ";
                6'd30: packet_char = "L";
                6'd31: packet_char = hex16_char(snap_lfsr, 2'd0);
                6'd32: packet_char = hex16_char(snap_lfsr, 2'd1);
                6'd33: packet_char = hex16_char(snap_lfsr, 2'd2);
                6'd34: packet_char = hex16_char(snap_lfsr, 2'd3);
                6'd35: packet_char = " ";
                6'd36: packet_char = "D";
                6'd37: packet_char = hex16_char(snap_drop_counter, 2'd0);
                6'd38: packet_char = hex16_char(snap_drop_counter, 2'd1);
                6'd39: packet_char = hex16_char(snap_drop_counter, 2'd2);
                6'd40: packet_char = hex16_char(snap_drop_counter, 2'd3);
                6'd41: packet_char = 8'h0D;
                default: packet_char = 8'h0A;
            endcase
        end
    endfunction

    UartTx #(
        .ClkHz(ClkHz),
        .BAUD(UARTBaud)
    ) uart_tx_inst (
        .clk(CLK100MHZ),
        .start(uart_start),
        .data(uart_data),
        .tx(RsTx),
        .busy(uart_busy)
    );

    Hex7SegMux hex_mux_inst (
        .clk(CLK100MHZ),
        .hex_value(seg_hex_value),
        .SEG(SEG),
        .AN(AN)
    );

    always @(posedge CLK100MHZ) begin
        frame_tick <= 1'b0;
        uart_start <= 1'b0;
        drop_pulse <= 1'b0;

        btnc_d <= BTNC;
        btnu_d <= BTNU;
        btnl_d <= BTNL;
        btnr_d <= BTNR;
        btnd_d <= BTND;

        free_run_counter <= free_run_counter + 1'b1;
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

        if (frame_accum >= (ClkHz - FrameHz)) begin
            frame_accum <= frame_accum + FrameHz - ClkHz;
            frame_tick <= 1'b1;
            frame_blink <= ~frame_blink;
        end else begin
            frame_accum <= frame_accum + FrameHz;
        end

        if (BTNU && !btnu_d) begin
            stream_enable <= ~stream_enable;
        end

        if (BTNL && !btnl_d) begin
            page_index <= page_index - 1'b1;
        end

        if (BTNR && !btnr_d) begin
            page_index <= page_index + 1'b1;
        end

        if (clear_request) begin
            frame_counter <= 32'd0;
            drop_counter <= 16'd0;
        end

        if (frame_request) begin
            if (packet_pending || packet_sending) begin
                drop_counter <= drop_counter + 1'b1;
                drop_pulse <= 1'b1;
            end else begin
                frame_counter <= frame_counter + 1'b1;
                snap_frame_counter <= frame_counter + 1'b1;
                snap_cycle_counter <= free_run_counter;
                snap_switches <= SW;
                snap_buttons <= {3'b000, BTND, BTNR, BTNL, BTNU, BTNC};
                snap_lfsr <= lfsr;
                snap_drop_counter <= drop_counter;
                packet_pending <= 1'b1;
            end
        end

        if (!packet_sending) begin
            last_char_inflight <= 1'b0;
            if (packet_pending && !uart_busy) begin
                uart_data <= packet_char(6'd0);
                uart_start <= 1'b1;
                packet_pending <= 1'b0;
                packet_sending <= 1'b1;
                packet_index <= 6'd1;
                last_char_inflight <= (PacketLen == 1);
            end
        end else if (!uart_busy) begin
            if (last_char_inflight) begin
                packet_sending <= 1'b0;
                last_char_inflight <= 1'b0;
            end else begin
                uart_data <= packet_char(packet_index);
                uart_start <= 1'b1;
                last_char_inflight <= (packet_index == PacketLen - 1);
                packet_index <= packet_index + 1'b1;
            end
        end

        case (page_index)
            3'd0: seg_hex_value <= snap_frame_counter[15:0];
            3'd1: seg_hex_value <= snap_frame_counter[31:16];
            3'd2: seg_hex_value <= snap_cycle_counter[15:0];
            3'd3: seg_hex_value <= snap_cycle_counter[31:16];
            3'd4: seg_hex_value <= snap_switches;
            3'd5: seg_hex_value <= {8'h00, snap_buttons};
            3'd6: seg_hex_value <= snap_lfsr;
            default: seg_hex_value <= snap_drop_counter;
        endcase

        LED <= {
            1'b0,
            stream_enable,
            uart_busy,
            packet_sending,
            packet_pending,
            frame_blink,
            drop_pulse,
            page_index,
            RsRx,
            BTNC,
            BTNU,
            BTNL,
            BTNR,
            BTND
        };
    end
endmodule
