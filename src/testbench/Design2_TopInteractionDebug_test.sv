`timescale 1ns / 1ps

module MouseCtl (
    input  wire        clk,
    input  wire        rst,
    output wire [11:0] xpos,
    output wire [11:0] ypos,
    output wire [3:0]  zpos,
    output wire        left,
    output wire        middle,
    output wire        right,
    output wire        new_event,
    input  wire [11:0] value,
    input  wire        setx,
    input  wire        sety,
    input  wire        setmax_x,
    input  wire        setmax_y,
    inout              ps2_clk,
    inout              ps2_data
);
    assign xpos = 12'd0;
    assign ypos = 12'd0;
    assign zpos = 4'd0;
    assign left = 1'b0;
    assign middle = 1'b0;
    assign right = 1'b0;
    assign new_event = 1'b0;
endmodule

module MouseDisplay (
    input  wire        pixel_clk,
    input  wire [11:0] xpos,
    input  wire [11:0] ypos,
    input  wire        mouse_left,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    output wire        enable_mouse_display_out,
    output wire [3:0]  red_out,
    output wire [3:0]  green_out,
    output wire [3:0]  blue_out
);
    assign enable_mouse_display_out = 1'b0;
    assign red_out = 4'd0;
    assign green_out = 4'd0;
    assign blue_out = 4'd0;
endmodule

module Design2_TopInteractionDebug_test;
    import CellStorePkg::*;
    import ComponentStorePkg::*;
    import MetaCommandPkg::*;
    import ToolbarPkg::*;

    reg         CLK100MHZ = 1'b0;
    reg [15:0]  SW = 16'd0;
    wire [15:0] LED;
    wire [7:0]  SEG;
    wire [3:0]  AN;
    reg         BTNC = 1'b1;
    reg         BTNU = 1'b0;
    reg         BTNL = 1'b0;
    reg         BTNR = 1'b0;
    reg         BTND = 1'b0;
    reg [11:0]  mouse_x_drive = 12'd0;
    reg [11:0]  mouse_y_drive = 12'd0;
    reg         mouse_left_drive = 1'b0;
    reg         mouse_middle_drive = 1'b0;
    reg         mouse_right_drive = 1'b0;
    wire [7:0]  JC;
    wire [3:0]  VGARED;
    wire [3:0]  VGABLUE;
    wire [3:0]  VGAGREEN;
    wire        HSYNC;
    wire        VSYNC;
    tri         PS2CLK;
    tri         PS2DATA;

    always #5 CLK100MHZ = ~CLK100MHZ;

    MetaCircuit_top dut (
        .CLK100MHZ(CLK100MHZ),
        .SW(SW),
        .LED(LED),
        .SEG(SEG),
        .AN(AN),
        .BTNC(BTNC),
        .BTNU(BTNU),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTND(BTND),
        .JC(JC),
        .VGARED(VGARED),
        .VGABLUE(VGABLUE),
        .VGAGREEN(VGAGREEN),
        .HSYNC(HSYNC),
        .VSYNC(VSYNC),
        .PS2CLK(PS2CLK),
        .PS2DATA(PS2DATA)
    );

    task automatic request_frame_flip;
        begin
            force dut.render_bank_sel_pix = ~dut.render_bank_sel_pix;
            repeat (4) @(posedge CLK100MHZ);
            #1;
            release dut.render_bank_sel_pix;
        end
    endtask

    task automatic wait_for_idle;
        integer guard;
        begin
            guard = 0;
            while ((dut.sys_state != 5'd3) && (guard < 20000)) begin
                @(posedge CLK100MHZ);
                guard = guard + 1;
            end
            if (guard >= 20000) begin
                $fatal(1, "system did not return to SYS_WAIT_FLIP");
            end
        end
    endtask

    task automatic issue_canvas_click(
        input [11:0] mx,
        input [11:0] my,
        input [3:0]  tool_mode
    );
        begin
            SW[15] = 1'b1;
            SW[3:0] = tool_mode;
            mouse_x_drive = mx;
            mouse_y_drive = my;
            mouse_left_drive = 1'b1;
            request_frame_flip();
            wait_for_idle();
            #1;
            mouse_left_drive = 1'b0;
            request_frame_flip();
            wait_for_idle();
        end
    endtask

    initial begin
        force dut.mouse_xpos = mouse_x_drive;
        force dut.mouse_ypos = mouse_y_drive;
        force dut.mouse_left = mouse_left_drive;
        force dut.mouse_middle = mouse_middle_drive;
        force dut.mouse_right = mouse_right_drive;

        repeat (4) @(posedge CLK100MHZ);
        BTNC = 1'b0;

        wait (dut.sys_state == 5'd3);
        @(posedge CLK100MHZ);
        #1;

        if (!component_valid(dut.comp_store_inst.mem[0])) begin
            $fatal(1, "Seeded demo component missing after reset");
        end
        if (component_anchor_x(dut.comp_store_inst.mem[0]) != 5'd10 ||
            component_anchor_y(dut.comp_store_inst.mem[0]) != 5'd8) begin
            $fatal(1, "Seeded demo component anchor mismatch");
        end

        request_frame_flip();
        wait_for_idle();

        issue_canvas_click(12'd144, 12'd112, MODE_WIRE);

        if (dut.interaction_cmd_pending || dut.executor_busy || (dut.sys_state != 5'd3)) begin
            $display("debug: sys_state=%0d mode=%0d arb_valid=%0d kind=%0d pending_kind=%0d exec_busy=%0d exec_done=%0d proj_busy=%0d proj_done=%0d",
                     dut.sys_state,
                     dut.mode_select,
                     dut.arb_cmd_valid,
                     command_kind(dut.arb_cmd_payload),
                     command_kind(dut.interaction_cmd_pending_payload),
                     dut.executor_busy,
                     dut.executor_done,
                     dut.projector_busy,
                     dut.projector_done);
            $fatal(1, "interaction command flow did not return to idle after a wire command");
        end

        if (dut.LED[14]) begin
            $fatal(1, "LED[14]/bg_overrun_flag stayed asserted after normal runtime");
        end

        if (!cell_valid(dut.cell_ram_a_inst.mem[flatten_addr(5'd2, 5'd1)]) &&
            !cell_valid(dut.cell_ram_b_inst.mem[flatten_addr(5'd2, 5'd1)])) begin
            $fatal(1, "Wire placement did not update either cell buffer");
        end

        $display("Design2_TopInteractionDebug_test passed");
        $finish;
    end
endmodule
