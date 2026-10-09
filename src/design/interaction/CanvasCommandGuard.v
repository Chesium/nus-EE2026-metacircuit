`timescale 1ns / 1ps

// Validate a complete edit before writing either half. The controller's read
// commands pass through; its (at most three) writes are buffered until done.
module CanvasCommandGuard #(
    parameter integer AddrWidth = 9,
    parameter integer DataWidth = 16
) (
    input wire clk,
    input wire reset,
    input wire [3:0] mode_select,
    input wire controller_done,
    input wire cmd_valid,
    input wire cmd_write,
    input wire [AddrWidth-1:0] cmd_addr,
    input wire [DataWidth-1:0] cmd_wdata,
    output wire cmd_ready,
    output wire rsp_valid,
    output wire [DataWidth-1:0] rsp_rdata,
    output reg bg_cmd_valid,
    output reg bg_cmd_write,
    output reg [AddrWidth-1:0] bg_cmd_addr,
    output reg [DataWidth-1:0] bg_cmd_wdata,
    input wire bg_cmd_ready,
    input wire bg_rsp_valid,
    input wire [DataWidth-1:0] bg_rsp_rdata,
    output wire idle,
    output wire value_read_en,
    output wire [AddrWidth-1:0] value_read_addr,
    output wire copy_value
);
    localparam COLLECT = 2'd0, CHECK = 2'd1, WAIT_RESPONSE = 2'd2, WRITE = 2'd3;
    reg [1:0] state = COLLECT;
    reg [1:0] count = 0;
    reg [1:0] index = 0;
    reg [3:0] edit_mode = 0;
    reg [AddrWidth-1:0] addresses [0:2];
    reg [DataWidth-1:0] words [0:2];

    wire dual_placement = count == 2 && edit_mode != 4'd8;
    wire component_rotation = count == 3 && edit_mode == 4'd7;
    wire single_placement = count == 1 && edit_mode != 4'd7 && edit_mode != 4'd8;
    wire target_is_component = bg_rsp_rdata[0] &&
                              bg_rsp_rdata[6:1] >= 6'd5 && bg_rsp_rdata[6:1] <= 6'd14;
    assign idle = state == COLLECT && count == 0;
    assign cmd_ready = state == COLLECT && (cmd_write ? count < 3 : bg_cmd_ready);
    assign rsp_valid = state == COLLECT && bg_rsp_valid;
    assign rsp_rdata = bg_rsp_rdata;
    // Steer the synchronous value RAM read to the anchor while checking a
    // component rotation. It is ready before the second (new partner) write.
    assign value_read_en = state != COLLECT && component_rotation;
    assign value_read_addr = addresses[0];
    assign copy_value = state == WRITE && component_rotation && index == 1;

    always @(*) begin
        bg_cmd_valid = 1'b0;
        bg_cmd_write = 1'b0;
        bg_cmd_addr = cmd_addr;
        bg_cmd_wdata = cmd_wdata;
        case (state)
            COLLECT: bg_cmd_valid = cmd_valid && !cmd_write;
            CHECK: begin
                bg_cmd_valid = 1'b1;
                bg_cmd_addr = addresses[index];
            end
            WRITE: begin
                bg_cmd_valid = 1'b1;
                bg_cmd_write = 1'b1;
                bg_cmd_addr = addresses[index];
                bg_cmd_wdata = words[index];
            end
            default: begin end
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            state <= COLLECT;
            count <= 0;
            index <= 0;
            edit_mode <= 0;
        end else begin
            case (state)
                COLLECT: begin
                    if (cmd_valid && cmd_write && cmd_ready) begin
                        addresses[count] <= cmd_addr;
                        words[count] <= cmd_wdata;
                        count <= count + 1'b1;
                        if (count == 0) edit_mode <= mode_select;
                    end else if (controller_done && count != 0) begin
                        if (dual_placement || single_placement) begin
                            index <= 0;
                            state <= CHECK;
                        end else if (component_rotation) begin
                            index <= 1; // reject an occupied new partner before changing the anchor
                            state <= CHECK;
                        end else begin
                            index <= 0;
                            state <= WRITE;
                        end
                    end
                end
                CHECK: if (bg_cmd_ready) state <= WAIT_RESPONSE;
                WAIT_RESPONSE: if (bg_rsp_valid) begin
                    if ((single_placement && (target_is_component ||
                         (bg_rsp_rdata[0] && bg_rsp_rdata[6:1] == words[0][6:1]))) ||
                        (!single_placement && bg_rsp_rdata[0])) begin
                        count <= 0;
                        state <= COLLECT;
                    end else if (dual_placement && index == 0) begin
                        index <= 1;
                        state <= CHECK;
                    end else begin
                        index <= 0;
                        state <= WRITE;
                    end
                end
                WRITE: if (bg_cmd_ready) begin
                    if (index + 1'b1 == count) begin
                        count <= 0;
                        state <= COLLECT;
                    end else index <= index + 1'b1;
                end
                default: state <= COLLECT;
            endcase
        end
    end
endmodule
