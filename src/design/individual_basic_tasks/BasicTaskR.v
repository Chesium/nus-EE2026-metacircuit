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


module BasicTaskR (
  input CLK100MHZ,
  input [6:0] x,
  input [5:0] y,
  input SW1,
  output reg [15:0] rgb = 0
);
    wire clk_25Hz, my_fb, send_pix, samp_pix;
    wire [12:0] pixel_index;
    
    parameter digit9_x = 3;   // left light_blue 9
    parameter digit9_y = 20;
    parameter digit4_x = 41;  // middle orange 4
    parameter digit4_y = 20;
        
    parameter LIGHT_BLUE = 16'b00010_010000_11111;
    parameter ORANGE = 16'b11111_101000_00000;
    parameter BLACK = 0;
    
    reg [6:0] digit9_x_pos;   // current x position
    reg dir_right;            // direction: right = 1, left = 0
    
    initial begin
        digit9_x_pos = digit9_x;
        dir_right = 1'b1;  // right direction
    end
    
    // Bitmap for digit 9 (15x25, lines 5px thick)
    reg [14:0] bitmap_9 [24:0];
    
    initial begin
        bitmap_9[0]  = 15'b111111111111111;
        bitmap_9[1]  = 15'b111111111111111;
        bitmap_9[2]  = 15'b111111111111111;
        bitmap_9[3]  = 15'b111111111111111;
        bitmap_9[4]  = 15'b111111111111111;
        bitmap_9[5]  = 15'b111110000011111;
        bitmap_9[6]  = 15'b111110000011111;
        bitmap_9[7]  = 15'b111110000011111;
        bitmap_9[8]  = 15'b111110000011111;
        bitmap_9[9]  = 15'b111110000011111;
        bitmap_9[10] = 15'b111111111111111;
        bitmap_9[11] = 15'b111111111111111;
        bitmap_9[12] = 15'b111111111111111;
        bitmap_9[13] = 15'b111111111111111;
        bitmap_9[14] = 15'b111111111111111;
        bitmap_9[15] = 15'b000000000011111;
        bitmap_9[16] = 15'b000000000011111;
        bitmap_9[17] = 15'b000000000011111;
        bitmap_9[18] = 15'b000000000011111;
        bitmap_9[19] = 15'b000000000011111;
        bitmap_9[20] = 15'b111111111111111;
        bitmap_9[21] = 15'b111111111111111;
        bitmap_9[22] = 15'b111111111111111;
        bitmap_9[23] = 15'b111111111111111;
        bitmap_9[24] = 15'b111111111111111;
    end

    // Bitmap for digit 4 (15x25, lines 5px thick)
    reg [14:0] bitmap_4 [24:0];
    
    initial begin
        bitmap_4[0]  = 15'b111110000011111;
        bitmap_4[1]  = 15'b111110000011111;
        bitmap_4[2]  = 15'b111110000011111;
        bitmap_4[3]  = 15'b111110000011111;
        bitmap_4[4]  = 15'b111110000011111;
        bitmap_4[5]  = 15'b111110000011111;
        bitmap_4[6]  = 15'b111110000011111;
        bitmap_4[7]  = 15'b111110000011111;
        bitmap_4[8]  = 15'b111110000011111;
        bitmap_4[9]  = 15'b111110000011111;
        bitmap_4[10] = 15'b111111111111111;
        bitmap_4[11] = 15'b111111111111111;
        bitmap_4[12] = 15'b111111111111111;
        bitmap_4[13] = 15'b111111111111111;
        bitmap_4[14] = 15'b111111111111111;
        bitmap_4[15] = 15'b000000000011111;
        bitmap_4[16] = 15'b000000000011111;
        bitmap_4[17] = 15'b000000000011111;
        bitmap_4[18] = 15'b000000000011111;
        bitmap_4[19] = 15'b000000000011111;
        bitmap_4[20] = 15'b000000000011111;
        bitmap_4[21] = 15'b000000000011111;
        bitmap_4[22] = 15'b000000000011111;
        bitmap_4[23] = 15'b000000000011111;
        bitmap_4[24] = 15'b000000000011111;
    end

    ClockDivider #(.FREQ(25)) clk_1KHz (.CLK100MHZ (CLK100MHZ), .clk_out (clk_25Hz));
                            
    always @(posedge clk_25Hz) begin
        if (SW1) begin
            if (dir_right) begin
                if (digit9_x_pos < 78) digit9_x_pos <= digit9_x_pos + 1;
                else dir_right <= 0;
            end else begin
                if (digit9_x_pos > 3) digit9_x_pos <= digit9_x_pos - 1;
                else dir_right <= 1;
            end
        end
    end

    always @ (posedge CLK100MHZ) begin
        rgb = BLACK;
    
        if (x >= digit9_x_pos && x < digit9_x_pos + 15 &&
            y >= digit9_y && y < digit9_y + 25 &&
            bitmap_9[y - digit9_y][14 - (x - digit9_x_pos)])
        begin rgb = LIGHT_BLUE; end
    
        else if (x >= digit4_x && x < digit4_x + 15 &&
                  y >= digit4_y && y < digit4_y + 25 &&
                  bitmap_4[y - digit4_y][14 - (x - digit4_x)])
        begin rgb = ORANGE; end
    
    end

endmodule