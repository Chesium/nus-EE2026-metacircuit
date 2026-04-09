`timescale 1ns / 1ps

module Design2_Toolbar_test;
    import UiThemePkg::*;
    import ToolbarPkg::*;

    reg         clk = 1'b0;
    reg         clk_pixel = 1'b0;
    reg         rst = 1'b1;
    reg         switch_override_en = 1'b0;
    reg [15:0]  sw = 16'd0;
    reg [11:0]  mouse_x = 12'd0;
    reg [11:0]  mouse_y = 12'd0;
    reg         mouse_left = 1'b0;
    reg         video_on = 1'b1;
    reg [11:0]  hcount = 12'd0;
    reg [11:0]  vcount = 12'd0;

    wire [3:0] mode_select;
    wire hover_valid;
    wire [3:0] hover_tool_idx;
    wire toolbar_rendered;
    wire [11:0] toolbar_rgb;

    always #5 clk = ~clk;
    always #20 clk_pixel = ~clk_pixel;

    ToolbarStateController u_state_controller (
        .clk(clk),
        .rst(rst),
        .switch_override_en(switch_override_en),
        .sw(sw),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .mouse_left(mouse_left),
        .mode_select(mode_select),
        .hover_valid(hover_valid),
        .hover_tool_idx(hover_tool_idx)
    );

    ToolbarRenderer u_toolbar_renderer (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .mouse_left(mouse_left),
        .selected_mode(mode_select),
        .rendered(toolbar_rendered),
        .rgb(toolbar_rgb)
    );

    function automatic [11:0] brighten_color(input [11:0] color);
        reg [4:0] r;
        reg [4:0] g;
        reg [4:0] b;
        begin
            r = color[11:8] + 1'b1;
            g = color[7:4] + 1'b1;
            b = color[3:0] + 1'b1;
            brighten_color = {
                (r > 5'd15) ? 4'hF : r[3:0],
                (g > 5'd15) ? 4'hF : g[3:0],
                (b > 5'd15) ? 4'hF : b[3:0]
            };
        end
    endfunction

    function automatic [11:0] darken_color(input [11:0] color);
        reg [4:0] r;
        reg [4:0] g;
        reg [4:0] b;
        begin
            r = (color[11:8] > 0) ? (color[11:8] - 1'b1) : 5'd0;
            g = (color[7:4] > 0) ? (color[7:4] - 1'b1) : 5'd0;
            b = (color[3:0] > 0) ? (color[3:0] - 1'b1) : 5'd0;
            darken_color = {r[3:0], g[3:0], b[3:0]};
        end
    endfunction

    task automatic click_toolbar_slot(input integer index);
        begin
            mouse_x = toolbar_slot_x(index) + 12'd8;
            mouse_y = toolbar_slot_y(index) + 12'd8;
            @(posedge clk);
            mouse_left = 1'b1;
            @(posedge clk);
            mouse_left = 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic sample_pixel(input [11:0] sx, input [11:0] sy);
        begin
            hcount = sx;
            vcount = sy;
            @(posedge clk_pixel);
            #1;
        end
    endtask

    integer idx;
    reg [11:0] expected_rgb;

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        if (mode_select != MODE_SELECT) begin
            $fatal(1, "Toolbar state did not reset to MODE_SELECT");
        end

        for (idx = 0; idx < TOOLBAR_TOOL_COUNT; idx = idx + 1) begin
            click_toolbar_slot(idx);
            if (mode_select != tool_mode_by_index(idx)) begin
                $fatal(1, "Toolbar click mismatch at index %0d: got %0d expected %0d",
                       idx, mode_select, tool_mode_by_index(idx));
            end
            if (!hover_valid || (hover_tool_idx != idx[3:0])) begin
                $fatal(1, "Toolbar hover decode mismatch at index %0d", idx);
            end
        end

        mouse_x = 12'd500;
        mouse_y = 12'd450;
        @(posedge clk);
        mouse_left = 1'b1;
        @(posedge clk);
        mouse_left = 1'b0;
        @(posedge clk);
        if (mode_select != MODE_DELETE) begin
            $fatal(1, "Clicking outside toolbar changed the selected mode");
        end

        switch_override_en = 1'b1;
        sw[3:0] = MODE_WIRE;
        @(posedge clk);
        if (mode_select != MODE_WIRE) begin
            $fatal(1, "Switch override failed to set MODE_WIRE");
        end

        sw[3:0] = 4'hF;
        @(posedge clk);
        if (mode_select != MODE_SELECT) begin
            $fatal(1, "Switch override failed to sanitize invalid tool mode");
        end

        switch_override_en = 1'b0;
        click_toolbar_slot(6);
        if (mode_select != MODE_RES) begin
            $fatal(1, "Toolbar click failed after switch override was released");
        end

        sample_pixel(UI_TOOLBAR_X, UI_TOOLBAR_Y + 12'd8);
        if (!toolbar_rendered || (toolbar_rgb != UI_COLOR_PANEL_BORDER)) begin
            $fatal(1, "Toolbar border pixel mismatch");
        end

        sample_pixel(toolbar_slot_x(0) + 12'd4, toolbar_slot_y(0) + 12'd4);
        expected_rgb = darken_color(tool_color_by_index(0));
        if (!toolbar_rendered || (toolbar_rgb != expected_rgb)) begin
            $fatal(1, "Toolbar base face color mismatch for slot 0");
        end

        sample_pixel(toolbar_slot_x(6), toolbar_slot_y(6) + 12'd6);
        if (!toolbar_rendered || (toolbar_rgb != UI_COLOR_TOOLBAR_ACCENT)) begin
            $fatal(1, "Toolbar selected border color mismatch");
        end

        mouse_x = toolbar_slot_x(1) + 12'd6;
        mouse_y = toolbar_slot_y(1) + 12'd6;
        sample_pixel(toolbar_slot_x(1) + 12'd4, toolbar_slot_y(1) + 12'd4);
        expected_rgb = tool_color_by_index(1);
        if (!toolbar_rendered || (toolbar_rgb != expected_rgb)) begin
            $fatal(1, "Toolbar hover face color mismatch");
        end

        sample_pixel(toolbar_slot_x(0) + 12'd4, toolbar_slot_y(0) + TOOLBAR_SLOT_H + 12'd1);
        if (!toolbar_rendered || (toolbar_rgb != UI_COLOR_TOOLBAR_BG)) begin
            $fatal(1, "Toolbar gap/background color mismatch");
        end

        sample_pixel(UI_TOOLBAR_X + UI_TOOLBAR_W + 12'd2, UI_TOOLBAR_Y + 12'd8);
        if (toolbar_rendered) begin
            $fatal(1, "Toolbar rendered outside its panel bounds");
        end

        $display("Design2_Toolbar_test passed");
        $finish;
    end
endmodule
