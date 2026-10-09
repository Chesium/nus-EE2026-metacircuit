`timescale 1ns / 1ps

// Exercise the controller and guard against a real, delayed-response memory,
// including backpressure. Expected outcomes come from the accepted M1 behavior.
module CanvasCommandGuard_test;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1;
    reg tick = 0;
    reg [3:0] mode = 15;
    reg [11:0] x = 320, y = 240;
    reg left = 0, middle = 0, right = 0;
    wire raw_valid, raw_write, raw_ready, raw_rsp_valid, done, dropped;
    wire [8:0] raw_addr;
    wire [15:0] raw_word, raw_rsp_word;
    wire valid, write, idle, value_read, copy_value;
    wire [8:0] addr, value_addr;
    wire [15:0] word;
    reg response = 0;
    reg [15:0] response_word = 0;
    reg [15:0] cells [0:287];
    integer cycles = 0, writes = 0, value_copies = 0;
    reg allow_memory = 1;
    wire ready = allow_memory && cycles % 7 != 0;

    InteractionController #(.CanvasPosX(64), .CanvasPosY(64), .CanvasWidth(576),
        .CanvasHeight(288), .GridWidth(18), .GridHeight(16), .RotateFramesPerStep(3)) controller (
        .clk(clk), .reset(reset), .frame_start_pulse(tick), .mode_select(mode),
        .mouse_x(x), .mouse_y(y), .mouse_left(left), .mouse_middle(middle), .mouse_right(right),
        .grid_pos_x(13'sd0), .grid_pos_y(13'sd0),
        .bg_cmd_ready(raw_ready), .bg_rsp_valid(raw_rsp_valid), .bg_rsp_rdata(raw_rsp_word),
        .bg_cmd_valid(raw_valid), .bg_cmd_write(raw_write), .bg_cmd_addr(raw_addr), .bg_cmd_wdata(raw_word),
        .frame_done(done), .frame_drop_flag(dropped)
    );
    CanvasCommandGuard guard (
        .clk(clk), .reset(reset), .mode_select(mode), .controller_done(done),
        .cmd_valid(raw_valid), .cmd_write(raw_write), .cmd_addr(raw_addr), .cmd_wdata(raw_word),
        .cmd_ready(raw_ready), .rsp_valid(raw_rsp_valid), .rsp_rdata(raw_rsp_word),
        .bg_cmd_valid(valid), .bg_cmd_write(write), .bg_cmd_addr(addr), .bg_cmd_wdata(word),
        .bg_cmd_ready(ready), .bg_rsp_valid(response), .bg_rsp_rdata(response_word), .idle(idle),
        .value_read_en(value_read), .value_read_addr(value_addr), .copy_value(copy_value)
    );
    always @(posedge clk) begin
        cycles <= cycles + 1;
        response <= 0;
        if (valid && ready) begin
            if (write) begin
                cells[addr] <= word;
                writes <= writes + 1;
                if (copy_value) begin
                    if (!value_read || value_addr != 19) $fatal(1, "rotation value source is not the anchor");
                    value_copies <= value_copies + 1;
                end
            end else begin
                response <= 1;
                response_word <= cells[addr];
            end
        end
    end

    task automatic finish_frame;
        integer budget;
        begin
            repeat (10) @(negedge clk);
            budget = 0;
            while (!(done && idle) && budget < 200) begin
                @(negedge clk);
                budget++;
            end
            if (!done || !idle || dropped) $fatal(1, "frame failed to finish without a drop");
        end
    endtask
    task automatic sample(input integer col, input integer row, input bit held);
        begin
            @(negedge clk);
            x = 64 + col * 32 + 16;
            y = 64 + row * 32 + 16;
            left = held;
            tick = 1;
            @(negedge clk);
            tick = 0;
            finish_frame();
        end
    endtask
    task automatic click(input integer col, input integer row);
        begin
            sample(col, row, 0);
            sample(col, row, 1);
            sample(col, row, 0);
        end
    endtask
    task automatic check(input integer at, input reg [15:0] wanted);
        if (cells[at] !== wanted) $fatal(1, "cell %0d: got %h expected %h", at, cells[at], wanted);
    endtask

    integer before_writes;
    initial begin
        foreach (cells[i]) cells[i] = 0;
        repeat (3) @(negedge clk);
        reset = 0;

        mode = 4; click(1, 1); check(19, 16'h000b); check(20, 16'h000d);
        before_writes = writes;
        click(0, 1); // empty anchor, occupied partner
        check(18, 0); check(19, 16'h000b); check(20, 16'h000d);
        click(2, 1); // occupied anchor
        check(20, 16'h000d); check(21, 0);
        if (writes != before_writes) $fatal(1, "blocked placement performed a partial write");

        mode = 0; click(1, 1); check(19, 16'h000b); // wire cannot overwrite component
        sample(0, 1, 1); sample(0, 2, 1); sample(0, 2, 0);
        check(18, 1); check(36, 1); // held wire paints both cells

        mode = 7; click(2, 1); // rotate via right half
        check(19, 16'h008b); check(37, 16'h008d); check(20, 0);
        if (value_copies != 1) $fatal(1, "rotation did not request partner value copy");
        before_writes = writes;
        click(1, 1); // next partner would overwrite wire at (0,1)
        check(19, 16'h008b); check(37, 16'h008d); check(18, 1);
        if (writes != before_writes) $fatal(1, "blocked rotation performed a partial write");

        mode = 8; click(1, 2); check(19, 0); check(37, 0); // delete via rotated right half
        mode = 4; sample(5, 1, 1); sample(8, 1, 1); sample(8, 1, 0);
        check(23, 16'h000b); check(24, 16'h000d); check(26, 0); // held component stamps once

        mode = 0; click(3, 3);
        mode = 7; click(3, 3); check(57, 16'h0081);
        mode = 0; click(3, 3); check(57, 16'h0081); // same sprite preserves rotation
        mode = 11; click(3, 3); check(57, 16'h001f); // different noncomponent may replace it

        mode = 0;
        sample(-1, 2, 1); sample(9, 2, 1); sample(9, 2, 0);
        check(45, 0); // press outside followed by drag into canvas does nothing
        right = 1; sample(9, 2, 0); right = 0; middle = 1; sample(9, 2, 0); middle = 0;
        check(45, 0);

        // Backpressure while validating a dual placement must leave both cells
        // unchanged and hold the read command until the memory accepts it.
        mode = 4; allow_memory = 0;
        @(negedge clk); x = 400; y = 240; left = 1; tick = 1;
        @(negedge clk); tick = 0;
        repeat (20) @(negedge clk);
        check(100, 0); check(101, 0);
        if (idle || !valid || write) $fatal(1, "guard failed to hold validation read under backpressure");
        allow_memory = 1; finish_frame();
        check(100, 16'h000b); check(101, 16'h000d);

        $display("CanvasCommandGuard_test passed.");
        $finish;
    end
endmodule
