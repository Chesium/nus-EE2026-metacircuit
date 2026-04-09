`timescale 1ns / 1ps

module Design2_ToolbarIntegration_test;
    import CellStorePkg::*;
    import ComponentStorePkg::*;
    import MetaCommandPkg::*;
    import ToolbarPkg::*;

    reg         clk = 1'b0;
    reg         rst = 1'b1;
    reg         switch_override_en = 1'b0;
    reg [15:0]  sw = 16'd0;
    reg [11:0]  mouse_x = 12'd0;
    reg [11:0]  mouse_y = 12'd0;
    reg         mouse_left = 1'b0;
    reg         mouse_middle = 1'b0;
    reg         mouse_right = 1'b0;
    reg         frame_start_pulse = 1'b0;
    reg signed [12:0] grid_pos_x = 13'sd0;
    reg signed [12:0] grid_pos_y = 13'sd0;

    wire [3:0] mode_select;
    wire hover_valid;
    wire [3:0] hover_tool_idx;
    wire cmd_valid;
    wire [63:0] cmd_payload;
    wire frame_done;
    wire frame_drop_flag;
    reg  captured_cmd_valid = 1'b0;
    reg  [63:0] captured_cmd_payload = 64'd0;

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            captured_cmd_valid <= 1'b0;
            captured_cmd_payload <= 64'd0;
        end else if (cmd_valid) begin
            captured_cmd_valid <= 1'b1;
            captured_cmd_payload <= cmd_payload;
        end
    end

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

    InteractionCommandController #(
        .CanvasPosX(64),
        .CanvasPosY(64),
        .CanvasWidth(420),
        .CanvasHeight(288),
        .CellSize(32),
        .GridWidth(32),
        .GridHeight(32)
    ) u_interaction_controller (
        .clk(clk),
        .reset(rst),
        .frame_start_pulse(frame_start_pulse),
        .mode_select(mode_select),
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .mouse_left(mouse_left),
        .mouse_middle(mouse_middle),
        .mouse_right(mouse_right),
        .grid_pos_x(grid_pos_x),
        .grid_pos_y(grid_pos_y),
        .cmd_valid(cmd_valid),
        .cmd_payload(cmd_payload),
        .frame_done(frame_done),
        .frame_drop_flag(frame_drop_flag)
    );

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

    task automatic frame_click_canvas(
        input [11:0] x,
        input [11:0] y,
        input        left_btn,
        input        right_btn
    );
        integer iter;
        reg found_valid;
        begin
            captured_cmd_valid = 1'b0;
            captured_cmd_payload = 64'd0;
            mouse_x = x;
            mouse_y = y;
            mouse_left = left_btn;
            mouse_right = right_btn;
            frame_start_pulse = 1'b1;
            @(posedge clk);
            frame_start_pulse = 1'b0;
            found_valid = 1'b0;
            for (iter = 0; iter < 3; iter = iter + 1) begin
                @(posedge clk);
                #1;
                if (cmd_valid) begin
                    found_valid = 1'b1;
                end
            end
            mouse_left = 1'b0;
            mouse_right = 1'b0;
            if (!found_valid) begin
                #1;
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rst = 1'b0;
        @(posedge clk);

        click_toolbar_slot(6);
        if (mode_select != MODE_RES) begin
            $fatal(1, "Toolbar did not select resistor mode for integration test");
        end

        frame_click_canvas(12'd144, 12'd112, 1'b1, 1'b0);
        if (!captured_cmd_valid ||
            (command_kind(captured_cmd_payload) != CMD_COMPONENT_CREATE) ||
            (command_comp_type(captured_cmd_payload) != COMP_RESISTOR) ||
            (command_cell_x(captured_cmd_payload) != 5'd2) ||
            (command_cell_y(captured_cmd_payload) != 5'd1)) begin
            $fatal(1, "Resistor toolbar selection did not feed interaction command generation");
        end

        $display("Design2_ToolbarIntegration_test passed");
        $finish;
    end
endmodule
