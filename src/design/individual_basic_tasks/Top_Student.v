`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: 
//  STUDENT B NAME:
//  STUDENT C NAME: 
//  STUDENT D NAME:  
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input wire CLK100MHZ,          // 100MHz system CLK100MHZ
    input wire btnC,
    input wire btnU,
    input wire btnL,
    input wire btnR,
    input wire btnD,
    input wire [15:0] sw,      // Switches
    output wire [7:0] JC,       // PMOD OLED connections
    output wire [7:0] SEG,
    output wire [3:0] AN
);
    // === 3.A2 CLK100MHZ divider: 100MHz -> 6.25MHz ===
    // CLK100MHZ divider to generate 6.25 MHz from 100 MHz system CLK100MHZ
    reg [3:0] clk_div_counter = 0;
    reg [22:0] clk_div_20hz = 0;
    reg clk6p25m = 0;
    reg clk20hz = 0;
    
    always @(posedge CLK100MHZ or posedge btnC) begin
            if (btnC)
                clk_div_counter <= 0;
            else begin
                if (clk_div_counter == 7) begin  // 100MHz / 6.25MHz / 2 = 8
                    clk_div_counter <= 0;
                    clk6p25m <= ~clk6p25m;
                end else
                    clk_div_counter <= clk_div_counter + 1;

                if (clk_div_20hz == 2500000) begin
                    clk_div_20hz <= 0;
                    clk20hz <= ~clk20hz;
                end else
                    clk_div_20hz <= clk_div_20hz + 1;
            end
        end
        
    reg [15:0] oled_data = 16'h07E0; // default green

    wire [6:0] x_pos;
    wire [5:0] y_pos;
    wire [12:0] pixel_index;

    assign x_pos = pixel_index % 96;
    assign y_pos = pixel_index / 96;

    wire [15:0] rgb_p;
    wire [15:0] rgb_q;
    wire [15:0] rgb_r;
    wire [15:0] rgb_s;
    wire frame_begin, sending_pixels, sample_pixel;
    wire [15:0] rgb_kb;
    wire [7:0]  kb_ascii;
    wire [23:0] kb_rgb;
    wire        kb_is_digit;
    wire        kb_is_unit;
    wire        kb_is_action;
    wire [4:0]  kb_key_id;
    wire        kb_key_valid;

    always @(posedge clk6p25m) begin
        if (sw[15]) begin
            oled_data <= rgb_s;
        end else if (sw[14]) begin
            oled_data <= rgb_r;
        end else if (sw[13]) begin
            oled_data <= rgb_q;
        end else if (sw[12]) begin
            oled_data <= rgb_p;
        end else begin
            // Default: show on-screen keyboard
            oled_data <= rgb_kb;
        end
    end

    reg [5:0] char1 = 6'b001001; // 1
    reg [5:0] char2 = 6'b000000; // .
    reg [5:0] char3 = 6'b000001; // 0
    reg [5:0] char4 = 6'b000101; // 9 *
    reg [3:0] decimalpoints = 4'b0100;

    SevenSeg sevenseg_inst(
        .CLK100MHZ(CLK100MHZ),
        .char1(char1),
        .char2(char2),
        .char3(char3),
        .char4(char4),
        .decimalpoints(decimalpoints),
        .seg(SEG),
        .an(AN)
    );

    BasicTaskP task_p_inst (
        .x(x_pos),
        .y(y_pos),
        .btnU(btnU),
        .rgb(rgb_p),
        .CLK100MHZ(CLK100MHZ)
    );

    BasicTaskQ task_q_inst (
        .x(x_pos),
        .y(y_pos),
        .btnD(btnD),
        .rgb(rgb_q),
        .CLK100MHZ(CLK100MHZ)
    );

    BasicTaskR task_r_inst (
        .x(x_pos),
        .y(y_pos),
        .SW1(sw[1]),
        .rgb(rgb_r),
        .CLK100MHZ(CLK100MHZ)
    );

    BasicTaskS task_s_inst (
        .x(x_pos),
        .y(y_pos),
        .btnR(btnR),
        .btnL(btnL),
        .rgb(rgb_s),
        .CLK100MHZ(CLK100MHZ)
    );

    // On-screen keyboard (OLED 96x64)
    Keyboard keyboard_inst (
        .clk_nav(clk20hz),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .btnC(btnC),
        .x(x_pos),
        .y(y_pos),
        .pixel_rgb(rgb_kb),
        .key_id(kb_key_id),
        .key_valid(kb_key_valid),
        .key_ascii(kb_ascii),
        .key_rgb(kb_rgb),
        .key_is_digit(kb_is_digit),
        .key_is_unit(kb_is_unit),
        .key_is_action(kb_is_action)
    );
    
    Oled_Display oled_inst (
        .clk(clk6p25m),
        .reset(btnC),             // can tie to pushbutton or 0
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(oled_data),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );

endmodule
