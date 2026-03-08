module font_rom_20x20 (
    input [3:0] char_idx, // 0: '2', 1: '6'
    input [4:0] row_addr, // 0-19
    output reg [19:0] row_data
);

    always @(*) begin
        case(char_idx)
            4'd0: begin // --- 2's 20*20 matrix ---
                case(row_addr)
                    5'd0, 5'd1:   row_data = 20'b00001111111111110000; 
                    5'd2, 5'd3:   row_data = 20'b00001111111111110000;
                    5'd4, 5'd5:   row_data = 20'b00000000000011110000; 
                    5'd6, 5'd7:   row_data = 20'b00000000000011110000;
                    5'd8, 5'd9:   row_data = 20'b00001111111111110000; 
                    5'd10, 5'd11: row_data = 20'b00001111111111110000;
                    5'd12, 5'd13: row_data = 20'b00001111000000000000; 
                    5'd14, 5'd15: row_data = 20'b00001111000000000000;
                    5'd16, 5'd17: row_data = 20'b00001111111111110000; 
                    5'd18, 5'd19: row_data = 20'b00001111111111110000;
                    default:      row_data = 20'b0;
                endcase
            end
            
            4'd1: begin // --- 6's 20*20 matrix---
                case(row_addr)
                    5'd0, 5'd1:   row_data = 20'b00001111111111110000; 
                    5'd2, 5'd3:   row_data = 20'b00001111111111110000;
                    5'd4, 5'd5:   row_data = 20'b00001111000000000000; 
                    5'd6, 5'd7:   row_data = 20'b00001111000000000000;
                    5'd8, 5'd9:   row_data = 20'b00001111111111110000; 
                    5'd10, 5'd11: row_data = 20'b00001111111111110000;
                    5'd12, 5'd13: row_data = 20'b00001111000011110000; 
                    5'd14, 5'd15: row_data = 20'b00001111000011110000;
                    5'd16, 5'd17: row_data = 20'b00001111111111110000; 
                    5'd18, 5'd19: row_data = 20'b00001111111111110000;
                    default:      row_data = 20'b0;
                endcase
            end
            default: row_data = 20'b0;
        endcase
    end
endmodule

module BasicTaskQ (
  input CLK100MHZ,
  input [6:0] x,
  input [5:0] y,
  input btnD,
  output reg [15:0] rgb = 0
);
  wire clk_1kHZ;

  ClockDivider #(.FREQ(1000)) clk_1KHz (.CLK100MHZ (CLK100MHZ), .clk_out (clk_1kHZ));

    wire [12:0]pixel_index;


    reg [2:0]COUNT = 0;
    reg [7:0]debounce_timer = 0;
    reg btnD_prev = 0;

   //obtain the corresponding position of pixel in the ROM data
    wire [4:0] ROM_row = y - 38;
    wire [4:0] ROM_col_2 = x - 13;
    wire [4:0] ROM_col_6 = x - 63;

    wire [19:0] current_row_bit_2;
    wire [19:0] current_row_bit_6;
    

    font_rom_20x20 unit_2(
      .char_idx(0),
      .row_addr(ROM_row), 
      .row_data(current_row_bit_2)
    );

    font_rom_20x20 unit_6(
      .char_idx(1), 
      .row_addr(ROM_row), 
      .row_data(current_row_bit_6)
    );

    wire is_pixel_on_2 = current_row_bit_2[19 - ROM_col_2];
    wire is_pixel_on_6 = current_row_bit_6[19 - ROM_col_6];

    
    always @(posedge clk_1kHZ) 
        begin
            btnD_prev <= btnD;

            if (debounce_timer > 0) 
                begin
                    debounce_timer <= debounce_timer - 1;
                end 
            else 
                begin
                    if (btnD == 1 && btnD_prev == 0) 
                        begin
                            COUNT <= (COUNT >= 3) ? 0 : COUNT + 1;
                            debounce_timer <= 200; 
                        end
                end
        end
    
   

    always @ (posedge CLK100MHZ)
        begin
           if(x>=38 & x<=58 & y>=38 & y<=58)
                begin
                    case(COUNT)
                        0: rgb <= 16'b00000_111111_00000;
                        1: rgb <= 16'b11111_000000_00000;
                        2: rgb <= 16'b00000_000000_11111;
                        3: rgb <= 16'b11111_111111_00000;
                    endcase
                end
           else if(x>=13 & x<=33 & y>=38 & y<=58)
                begin
                      if(is_pixel_on_2 == 1)
                        begin
                          rgb <= 16'b11111_000000_00000;
                        end
                       else
                        begin
                            rgb <= 0;
                        end
                end
           else if(x>=63 & x<=83 & y>=38 & y<=58)
                begin
                      if(is_pixel_on_6 == 1)
                        begin
                          rgb <= 16'b00000_000000_11111;
                        end
                      else
                        begin
                            rgb <= 0;
                        end
                end
           else
                begin
                        rgb <= 0;
                end
        end


endmodule