`timescale 1ns / 1ps

module ToolbarStateController (
    input  wire        clk,
    input  wire        rst,
    input  wire        switch_override_en,
    input  wire [15:0] sw,
    input  wire [11:0] mouse_x,
    input  wire [11:0] mouse_y,
    input  wire        mouse_left,
    output reg  [3:0]  mode_select,
    output wire        hover_valid,
    output wire [3:0]  hover_tool_idx
);
    import ToolbarPkg::*;

    reg mouse_left_d;

    assign hover_valid = toolbar_hit_valid(mouse_x, mouse_y);
    assign hover_tool_idx = toolbar_hit_index(mouse_x, mouse_y);

    always @(posedge clk) begin
        if (rst) begin
            mode_select <= MODE_SELECT;
            mouse_left_d <= 1'b0;
        end else begin
            mouse_left_d <= mouse_left;

            if (switch_override_en) begin
                mode_select <= sanitize_tool_mode(sw[3:0]);
            end else if (mouse_left && !mouse_left_d && hover_valid) begin
                mode_select <= tool_mode_by_index(hover_tool_idx);
            end
        end
    end
endmodule
