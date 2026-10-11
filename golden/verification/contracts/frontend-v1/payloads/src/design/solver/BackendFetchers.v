`timescale 1ns / 1ps

module fetchCell (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [4:0]  i,
    input  wire [3:0]  j,
    output reg  [15:0] result,
    output reg         ram_ren,
    output reg  [8:0]  ram_addr,
    input  wire [15:0] ram_rdata
);
    localparam [1:0] STATE_IDLE    = 2'd0;
    localparam [1:0] STATE_WAIT    = 2'd1;
    localparam [1:0] STATE_CAPTURE = 2'd2;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                ram_ren <= 1'b0;
                if (start) begin
                    ram_ren <= 1'b1;
                    ram_addr <= i + (j * 18);
                    state <= STATE_WAIT;
                end
            end
            STATE_WAIT: begin
                done <= 1'b0;
                ram_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                ram_ren <= 1'b0;
                result <= ram_rdata;
                done <= 1'b1;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                ram_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

module fetchP (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [4:0]  i,
    input  wire [3:0]  j,
    output reg  [3:0]  result,
    output wire        ram_ren,
    output wire [8:0]  ram_addr,
    input  wire [15:0] ram_rdata
);
    wire        cell_busy;
    wire        cell_done;
    wire [15:0] cell_result;

    function automatic [3:0] decode_p_from_cell(input [15:0] cell_data);
        reg [5:0] sprite_id;
        reg [1:0] rotation;
        begin
            if (!cell_data[0]) begin
                decode_p_from_cell = 4'b0000;
            end else begin
                sprite_id = cell_data[6:1];
                rotation = cell_data[8:7];
                case (sprite_id)
                    6'd0: begin
                        case (rotation)
                            2'd0, 2'd2: decode_p_from_cell = 4'b0101;
                            default:    decode_p_from_cell = 4'b1010;
                        endcase
                    end
                    6'd1: begin
                        case (rotation)
                            2'd0: decode_p_from_cell = 4'b0110;
                            2'd1: decode_p_from_cell = 4'b1100;
                            2'd2: decode_p_from_cell = 4'b1001;
                            default: decode_p_from_cell = 4'b0011;
                        endcase
                    end
                    6'd2: begin
                        case (rotation)
                            2'd0: decode_p_from_cell = 4'b0111;
                            2'd1: decode_p_from_cell = 4'b1110;
                            2'd2: decode_p_from_cell = 4'b1101;
                            default: decode_p_from_cell = 4'b1011;
                        endcase
                    end
                    6'd3, 6'd4: decode_p_from_cell = 4'b1111;
                    6'd15: begin
                        case (rotation)
                            2'd0: decode_p_from_cell = 4'b0001;
                            2'd1: decode_p_from_cell = 4'b0010;
                            2'd2: decode_p_from_cell = 4'b0100;
                            default: decode_p_from_cell = 4'b1000;
                        endcase
                    end
                    default: decode_p_from_cell = 4'b0000;
                endcase
            end
        end
    endfunction

    fetchCell fetch_cell_inst (
        .clk(clk),
        .start(start),
        .busy(cell_busy),
        .done(cell_done),
        .i(i),
        .j(j),
        .result(cell_result),
        .ram_ren(ram_ren),
        .ram_addr(ram_addr),
        .ram_rdata(ram_rdata)
    );

    assign busy = cell_busy;

    always @(posedge clk) begin
        if (cell_done) begin
            result <= decode_p_from_cell(cell_result);
            done <= 1'b1;
        end else begin
            done <= 1'b0;
        end
    end
endmodule

module fetchAnchorPositionX (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [4:0]  result,
    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    localparam [1:0] STATE_IDLE        = 2'd0;
    localparam [1:0] STATE_WAIT_ISSUE  = 2'd1;
    localparam [1:0] STATE_WAIT_DATA   = 2'd2;
    localparam [1:0] STATE_CAPTURE     = 2'd3;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                if (start) begin
                    comp_ren <= 1'b1;
                    comp_addr <= idx;
                    state <= STATE_WAIT_ISSUE;
                end
            end
            STATE_WAIT_ISSUE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_WAIT_DATA;
            end
            STATE_WAIT_DATA: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                comp_ren <= 1'b0;
                result <= comp_rdata[4:0];
                done <= 1'b1;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

module fetchAnchorPositionY (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [3:0]  result,
    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    localparam [1:0] STATE_IDLE        = 2'd0;
    localparam [1:0] STATE_WAIT_ISSUE  = 2'd1;
    localparam [1:0] STATE_WAIT_DATA   = 2'd2;
    localparam [1:0] STATE_CAPTURE     = 2'd3;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                if (start) begin
                    comp_ren <= 1'b1;
                    comp_addr <= idx;
                    state <= STATE_WAIT_ISSUE;
                end
            end
            STATE_WAIT_ISSUE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_WAIT_DATA;
            end
            STATE_WAIT_DATA: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                comp_ren <= 1'b0;
                result <= comp_rdata[8:5];
                done <= 1'b1;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

module fetchComponentType (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [3:0]  result,
    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    localparam [1:0] STATE_IDLE        = 2'd0;
    localparam [1:0] STATE_WAIT_ISSUE  = 2'd1;
    localparam [1:0] STATE_WAIT_DATA   = 2'd2;
    localparam [1:0] STATE_CAPTURE     = 2'd3;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                if (start) begin
                    comp_ren <= 1'b1;
                    comp_addr <= idx;
                    state <= STATE_WAIT_ISSUE;
                end
            end
            STATE_WAIT_ISSUE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_WAIT_DATA;
            end
            STATE_WAIT_DATA: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                comp_ren <= 1'b0;
                result <= comp_rdata[26:23];
                done <= 1'b1;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

module fetchComponentRotation (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [1:0]  result,
    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    localparam [1:0] STATE_IDLE        = 2'd0;
    localparam [1:0] STATE_WAIT_ISSUE  = 2'd1;
    localparam [1:0] STATE_WAIT_DATA   = 2'd2;
    localparam [1:0] STATE_CAPTURE     = 2'd3;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                if (start) begin
                    comp_ren <= 1'b1;
                    comp_addr <= idx;
                    state <= STATE_WAIT_ISSUE;
                end
            end
            STATE_WAIT_ISSUE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_WAIT_DATA;
            end
            STATE_WAIT_DATA: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                comp_ren <= 1'b0;
                result <= comp_rdata[22:21];
                done <= 1'b1;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

module fetchComponentValue (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [11:0] result,
    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    localparam [1:0] STATE_IDLE        = 2'd0;
    localparam [1:0] STATE_WAIT_ISSUE  = 2'd1;
    localparam [1:0] STATE_WAIT_DATA   = 2'd2;
    localparam [1:0] STATE_CAPTURE     = 2'd3;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                if (start) begin
                    comp_ren <= 1'b1;
                    comp_addr <= idx;
                    state <= STATE_WAIT_ISSUE;
                end
            end
            STATE_WAIT_ISSUE: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_WAIT_DATA;
            end
            STATE_WAIT_DATA: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                comp_ren <= 1'b0;
                result <= comp_rdata[20:9];
                done <= 1'b1;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                comp_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

module storeNode0 (
    input  wire       clk,
    input  wire       start,
    output wire       busy,
    output reg        done,
    input  wire [8:0] idx,
    input  wire [7:0] node_i,
    output wire       ram0_wen,
    output wire [8:0] ram0_addr,
    output wire [7:0] ram0_wdata
);
    assign busy = 1'b0;
    assign ram0_wen = start;
    assign ram0_addr = idx;
    assign ram0_wdata = node_i;

    always @(posedge clk) begin
        done <= start;
    end
endmodule

module storeNode1 (
    input  wire       clk,
    input  wire       start,
    output wire       busy,
    output reg        done,
    input  wire [8:0] idx,
    input  wire [7:0] node_i,
    output wire       ram1_wen,
    output wire [8:0] ram1_addr,
    output wire [7:0] ram1_wdata
);
    assign busy = 1'b0;
    assign ram1_wen = start;
    assign ram1_addr = idx;
    assign ram1_wdata = node_i;

    always @(posedge clk) begin
        done <= start;
    end
endmodule

module storeVoltage (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    input  wire [31:0] value,
    output wire        wave_wen,
    output wire [5:0]  wave_node,
    output wire [31:0] wave_wdata
);
    assign busy = 1'b0;
    assign wave_wen = start;
    assign wave_node = idx[5:0];
    assign wave_wdata = value;

    always @(posedge clk) begin
        done <= start;
    end
endmodule

module setColor (
    input  wire       clk,
    input  wire       start,
    output wire       busy,
    output reg        done,
    input  wire [4:0] i,
    input  wire [3:0] j,
    input  wire [3:0] c1,
    input  wire [3:0] c2,
    output wire       color_wen,
    output wire [8:0] color_addr,
    output wire [7:0] color_wdata
);
    assign busy = 1'b0;
    assign color_wen = start;
    assign color_addr = i + (j * 18);
    assign color_wdata = {c1, c2};

    always @(posedge clk) begin
        done <= start;
    end
endmodule
