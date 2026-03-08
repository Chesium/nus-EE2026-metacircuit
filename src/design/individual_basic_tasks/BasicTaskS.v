`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.03.2026 16:08:31
// Design Name: 
// Module Name: BasicTaskS
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BasicTaskS(
    input [6:0] x,
    input [6:0] y,
    input btnR,
    input btnL,
    output reg [15:0] rgb,
    input CLK100MHZ
    );

    parameter black = 0;

    parameter digit_x = 8;
    parameter digit_y = 24;
    parameter digit_dx = 8;
    parameter digit_dy = 16;
    parameter digit_color = 16'b00100_111111_00100; // light green

    parameter wall_x = 25;
    parameter wall_y = 10;
    parameter wall_dx = 5;
    parameter wall_dy = 50;
    parameter wall_color = 16'b11111_111111_11111; // white

    // clock divider
    reg mov_clk = 0; // 45Hz clk
    parameter pixel_per_second = 45;
    parameter clk_divider_counter_N = 10000000/pixel_per_second/2;
    reg [$clog2(clk_divider_counter_N)-1:0] clk_cnt = 0;

    reg moving = 0;
    reg direction = 0; // 0:right (x+)  1:left (x-)

    always @(posedge CLK100MHZ) begin
        if (clk_cnt == clk_divider_counter_N) begin
            mov_clk <= ~mov_clk;
            clk_cnt <= 0;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
        if (btnR) begin
            moving <= 1;
            direction <= 0;
        end else if (btnL) begin
            moving <= 1;
            direction <= 1;
        end
    end


    // state representation
    parameter circle_x_initial = 96/2;
    parameter circle_y = 64/2;
    parameter circle_r = 12;
    parameter circle_x_min = wall_x + wall_dx + circle_r;
    parameter circle_x_max = 96 - circle_r;
    parameter circle_color = 16'b11111_000000_00000; // red

    reg [6:0] circle_x = circle_x_initial;

    always @(posedge mov_clk) begin
        if (moving) begin
            if(direction) begin // command: left  (-)
                if (circle_x > circle_x_min) circle_x = circle_x - 1;
            end else begin      // command: right (+)
                if (circle_x < circle_x_max) circle_x = circle_x + 1;
            end
        end
    end

    // dx^2+dy^2 < r^2

    function hit_circle;
        input [6:0] px, py;
        input [6:0] x0, y0;
        reg   signed [8:0] dx, dy;      // allow negative
        reg          [17:0] dx2, dy2;     // (max 4095)^2 < 2^24, use wider
        reg          [18:0] dist2;
        reg          [18:0] t2;
    begin
        dx = $signed({1'b0, px}) - $signed({1'b0, x0});
        dy = $signed({1'b0, py}) - $signed({1'b0, y0});

        (* use_dsp = "yes" *) dx2 = dx * dx;
        (* use_dsp = "yes" *) dy2 = dy * dy;
        dist2 = dx2 + dy2;

        (* use_dsp = "yes" *) t2 = circle_r * circle_r;              // up to 8^2=64 (if radius<=8)
        hit_circle = (dist2 <= t2);
    end
    endfunction

    reg [7:0] bitmap_2 [15:0];

    initial begin
        bitmap_2[0]  = 8'b11111111;
        bitmap_2[1]  = 8'b11111111;
        bitmap_2[2]  = 8'b11111111;
        bitmap_2[3]  = 8'b00000111;
        bitmap_2[4]  = 8'b00000111;
        bitmap_2[5]  = 8'b00000111;
        bitmap_2[6]  = 8'b11111111;
        bitmap_2[7]  = 8'b11111111;
        bitmap_2[8]  = 8'b11111111;
        bitmap_2[9]  = 8'b11100000;
        bitmap_2[10] = 8'b11100000;
        bitmap_2[11] = 8'b11100000;
        bitmap_2[12] = 8'b11100000;
        bitmap_2[13] = 8'b11111111;
        bitmap_2[14] = 8'b11111111;
        bitmap_2[15] = 8'b11111111;
    end

    always @(*) begin
        if (x >= digit_x && x < digit_x + digit_dx && y >= digit_y && y < digit_y + digit_dy)
            rgb = bitmap_2[y-digit_y][digit_x-x+7] ? digit_color : black;
        else if (x >= wall_x && x < wall_x + wall_dx && y >= wall_y && y < wall_y + wall_dy)
            rgb = wall_color;
        else if (hit_circle(x,y,circle_x,circle_y))
            rgb = circle_color;
        else
            rgb = black;
    end

/*
number: 2

###########
#@@@@@@@@>>x  11111111
#@@@@@@@@#    11111111
#@@@@@@@@#    11111111
#     @@@#    00000111
#     @@@#    00000111
#     @@@#    00000111
#@@@@@@@@#    11111111
#@@@@@@@@#    11111111
#@@@@@@@@#    11111111
#@@@     #    11100000
#@@@     #    11100000
#@@@     #    11100000
#@@@     #    11100000
#@@@@@@@@#    11111111
#@@@@@@@@#    11111111
#@@@@@@@@#    11111111
#V#########
 y
*/
    
endmodule
