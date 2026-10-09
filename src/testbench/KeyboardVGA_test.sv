`timescale 1ns/1ps
module KeyboardVGA_test;
    reg clk_pixel = 0;
    always #5 clk_pixel = ~clk_pixel;
    reg [11:0] mouse_x = 0, mouse_y = 0;
    reg mouse_left = 0;
    wire [4:0] key_id;
    wire key_valid;
    wire [7:0] key_ascii;
    KeyboardVGA #(.KEY_COUNT(19), .KEYBOARD_X0(485)) dut (
        .clk_nav(clk_pixel), .mouse_x(mouse_x), .mouse_y(mouse_y),
        .mouse_left(mouse_left), .x(12'd500), .y(12'd368),
        .key_id(key_id), .key_valid(key_valid), .key_ascii(key_ascii),
        .pixel_rgb(), .key_rgb(), .key_is_digit(), .key_is_unit(), .key_is_action()
    );
    task tick;
        @(posedge clk_pixel); #1;
    endtask
    initial begin
        tick();
        @(negedge clk_pixel); mouse_x = 500; mouse_y = 368;
        tick();
        if (key_valid || key_ascii != "1") $fatal(1, "hover must not type");
        @(negedge clk_pixel); mouse_left = 1;
        tick();
        if (!key_valid || key_ascii != "1") $fatal(1, "one-sample press lost");
        tick();
        if (key_valid) $fatal(1, "held key repeats");
        @(negedge clk_pixel); mouse_x = 531;
        tick();
        if (key_valid || key_ascii != "2") $fatal(1, "drag must only change hover");
        @(negedge clk_pixel); mouse_left = 0;
        tick();
        @(negedge clk_pixel); mouse_left = 1;
        tick();
        if (!key_valid || key_ascii != "2") $fatal(1, "adjacent short click lost");
        @(negedge clk_pixel); mouse_left = 0; mouse_x = 592; mouse_y = 479;
        tick();
        if (key_id != 17 || key_ascii != 8'h08) $fatal(1, "DEL merged boundary");
        @(negedge clk_pixel); mouse_x = 593;
        tick();
        if (key_id != 18 || key_ascii != 8'h7f) $fatal(1, "RST merged boundary");
        @(negedge clk_pixel); mouse_x = 484; mouse_left = 1;
        tick();
        if (key_valid) $fatal(1, "outside keyboard typed");
        $display("KeyboardVGA_test passed");
        $finish;
    end
endmodule
