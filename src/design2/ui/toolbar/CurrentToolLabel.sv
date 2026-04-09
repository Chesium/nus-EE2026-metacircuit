`timescale 1ns / 1ps

module CurrentToolLabel (
    input  wire        clk_pixel,
    input  wire        video_on,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    input  wire [3:0]  selected_mode,
    output wire        rendered,
    output wire [11:0] rgb
);
    import UiThemePkg::*;
    import UiTextPkg::*;
    import ToolbarPkg::*;

    reg [255:0] label_data;
    reg [5:0]   label_len;

    always @(*) begin
        case (selected_mode)
            MODE_SELECT: begin
                label_data = {"TOOL: SELECT", 160'd0};
                label_len = 6'd12;
            end
            MODE_WIRE: begin
                label_data = {"TOOL: WIRE", 176'd0};
                label_len = 6'd10;
            end
            MODE_JUNCTION: begin
                label_data = {"TOOL: JUNCTION", 144'd0};
                label_len = 6'd14;
            end
            MODE_ELBOW: begin
                label_data = {"TOOL: ELBOW", 168'd0};
                label_len = 6'd11;
            end
            MODE_TEE: begin
                label_data = {"TOOL: TEE", 184'd0};
                label_len = 6'd9;
            end
            MODE_GROUND: begin
                label_data = {"TOOL: GROUND", 160'd0};
                label_len = 6'd12;
            end
            MODE_RES: begin
                label_data = {"TOOL: RESISTOR", 144'd0};
                label_len = 6'd14;
            end
            MODE_VOLT: begin
                label_data = {"TOOL: VOLTAGE", 152'd0};
                label_len = 6'd13;
            end
            MODE_CURR: begin
                label_data = {"TOOL: CURRENT", 152'd0};
                label_len = 6'd13;
            end
            MODE_ROTATE: begin
                label_data = {"TOOL: ROTATE", 160'd0};
                label_len = 6'd12;
            end
            MODE_DELETE: begin
                label_data = {"TOOL: DELETE", 160'd0};
                label_len = 6'd12;
            end
            default: begin
                label_data = {"TOOL: UNKNOWN", 152'd0};
                label_len = 6'd13;
            end
        endcase
    end

    TextDisplay #(
        .MAX_CHARS(32)
    ) u_text_display (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .start_x(12'd520),
        .start_y(12'd10),
        .region_width(12'd112),
        .scale(4'd1),
        .align(UI_ALIGN_RIGHT),
        .text_data(label_data),
        .text_len(label_len),
        .text_rgb(UI_COLOR_TEXT_PRIMARY),
        .rendered(rendered),
        .rgb(rgb),
        .char_index_out()
    );
endmodule
