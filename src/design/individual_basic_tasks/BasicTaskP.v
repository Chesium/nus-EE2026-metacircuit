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

module digit_rom_1 (
    input clk,
    input [5:0] row_addr,      // 0-48 (49行)
    input [6:0] col_addr,      // 0-27 (28列)
    output reg pixel_out       // 1=笔画, 0=背景
);

    reg [0:27] font_1 [0:48];  // 数字1，49行，每行28bit
    integer i;

    always @(posedge clk ) begin
        pixel_out <= font_1[row_addr][col_addr];//数字1字体
    end

    initial begin
        for (i = 0; i < 49; i = i + 1) begin
        font_1[i] = 28'b0000000_0000000_0000000_1111111;
        end     
    end
endmodule

module digit_rom_9 (
    input clk,
    input [5:0] row_addr,      // 0-48 (49行)
    input [6:0] col_addr,      // 0-27 (28列)
    output reg pixel_out       // 1=笔画, 0=背景
);

    reg [0:27] font_9 [0:48];  // 数字9，49行，每行28bit
    integer i;

    always @(posedge clk ) begin
       pixel_out <= font_9[row_addr][col_addr];//数字9字体 
    end
    
    initial begin
        for (i = 0; i < 7; i = i + 1) begin 
        font_9[i] = 28'b1111111_1111111_1111111_1111111;
        end
        for (i = 7; i < 21; i = i + 1) begin 
        font_9[i] = 28'b1111111_0000000_0000000_1111111;
        end
        for (i = 21; i < 28; i = i + 1) begin 
        font_9[i] = 28'b1111111_1111111_1111111_1111111;
        end
        for (i = 28; i < 42; i = i + 1) begin 
        font_9[i] = 28'b0000000_0000000_0000000_1111111;
        end
        for (i = 42; i < 49; i = i + 1) begin 
        font_9[i] = 28'b1111111_1111111_1111111_1111111;
        end        
    end
endmodule

module BasicTaskP (
  input CLK100MHZ,
  input [6:0] x,
  input [5:0] y,
  input btnU,
  output reg [15:0] rgb
);
  wire slowclk_25hz;
  wire slowclk_1Khz;
  wire my_fb, send_pix;
  wire [13:0] pix_index; //当前渲染像素（1~6143）

  reg [7:0] debounce_counter = 8'd200;
  reg [0:0] display_en = 1'b1;
  reg [0:0] btnU_prev = 0;

  parameter [6:0] c_c_x = 7'd7;
  parameter [5:0] c_c_y = 6'd7;
  reg signed [6:0] dx;
  reg signed [5:0] dy;
  reg [13:0] dist_q;

  wire digit_pix_1;
  wire [5:0] digit_row_1 = y-6;
  wire [6:0] digit_col_1 = x-16;
  wire in_digit_area_1 = (x >= 16 && x < 44 && y >= 6 && y < 55);

  wire digit_pix_2;
  wire [5:0] digit_row_2 = y-6;
  wire [6:0] digit_col_2 = x-51;
  wire in_digit_area_2 = (x >= 51 && x < 79 && y >= 6 && y < 55);

  ClockDivider #(.FREQ(20)) clk_20Hz (.CLK100MHZ (CLK100MHZ), .clk_out (slowclk_25hz));
  ClockDivider #(.FREQ(1000)) clk_1KHz (.CLK100MHZ (CLK100MHZ), .clk_out (slowclk_1Khz));

  digit_rom_9 drawdigit_1 (.clk (CLK100MHZ), .row_addr (digit_row_1), .col_addr (digit_col_1), .pixel_out (digit_pix_1));
  digit_rom_1 drawdigit_2 (.clk (CLK100MHZ), .row_addr (digit_row_2), .col_addr (digit_col_2), .pixel_out (digit_pix_2));

  // assign x = pix_index % 96;
  // assign y = pix_index / 96;
  always @ (posedge slowclk_1Khz) begin //除抖
    btnU_prev <= btnU;
    if (debounce_counter > 0) begin
        debounce_counter <= debounce_counter - 1;
    end
    else begin
        if (btnU == 1 && btnU_prev == 0) begin
            display_en <= ~display_en;
            debounce_counter <= 200;
        end
    end
  end

  always @ (posedge CLK100MHZ) begin //渲染
      if (display_en)begin
          dx = $signed(x) - $signed(c_c_x);
          dy = $signed(y) - $signed(c_c_y);
          dist_q = dx * dx + dy * dy;
          if (dist_q < 25) begin 
              rgb <= 16'b11111_111111_11111;
          end
          else if (digit_pix_1 && in_digit_area_1) begin
              rgb <= 16'b11111_000000_00000;
          end
          else if (digit_pix_2 && in_digit_area_2) begin
              rgb <= 16'b00000_111111_00000;
          end
          else begin
              rgb <= 16'b00000_000000_00000;
          end
      end
      else begin
              rgb <= 16'b00000_000000_00000;
      end
  end

endmodule