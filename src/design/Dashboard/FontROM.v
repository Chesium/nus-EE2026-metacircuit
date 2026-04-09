`timescale 1ns / 1ps

module FontROM (
    input wire [6:0] char_addr, // Input: ASCII code - 32 (Range 0-94)
    input wire [2:0] row,       // Input: Row index (0-7)
    output reg [7:0] pixel_data // Output: 8-bit row pattern
);

    always @(*) begin
        case (char_addr)
            // 0: Space (ASCII 32)
            7'd0:  pixel_data = 8'b00000000;
            
            // 1: ! (ASCII 33)
            7'd1:  case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00111100; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 2: " (ASCII 34)
            7'd2:  case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000;
                    7: pixel_data = 8'b00000000; default: pixel_data = 8'b00000000;
                  endcase

            // 3: # (ASCII 35)
            7'd3:  case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b01101110;
                    2: pixel_data = 8'b01101110; 3: pixel_data = 8'b11111111;
                    4: pixel_data = 8'b01101110; 5: pixel_data = 8'b01101110;
                    6: pixel_data = 8'b11111111; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 4: $ (ASCII 36)
            7'd4:  case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 5: % (ASCII 37)
            7'd5:  case(row)
                    0: pixel_data = 8'b01100011; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00001100;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b11000110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 6: & (ASCII 38)
            7'd6:  case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b01101100; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111010; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 7: ' (ASCII 39)
            7'd7:  case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 8: ( (ASCII 40)
            7'd8:  case(row)
                    0: pixel_data = 8'b00011100; 1: pixel_data = 8'b00110000;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b01100000;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b00011100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 9: ) (ASCII 41)
            7'd9:  case(row)
                    0: pixel_data = 8'b00111000; 1: pixel_data = 8'b00001100;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00000110;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b00001100;
                    6: pixel_data = 8'b00111000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 10: * (ASCII 42)
            7'd10: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b01111110; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b01111110;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 11: + (ASCII 43)
            7'd11: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b11111111;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 12: , (ASCII 44)
            7'd12: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00000000; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b01100000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 13: - (ASCII 45)
            7'd13: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00000000; 3: pixel_data = 8'b11111111;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 14: . (ASCII 46)
            7'd14: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00000000; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00011000; 7: pixel_data = 8'b00011000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 15: / (ASCII 47)
            7'd15: case(row)
                    0: pixel_data = 8'b00000110; 1: pixel_data = 8'b00001100;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b00110000;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b11000000;
                    6: pixel_data = 8'b10000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 16: 0 (ASCII 48)
            7'd16: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 17: 1 (ASCII 49)
            7'd17: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 18: 2 (ASCII 50)
            7'd18: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00001100;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b01111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 19: 3 (ASCII 51)
            7'd19: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 20: 4 (ASCII 52)
            7'd20: case(row)
                    0: pixel_data = 8'b00001100; 1: pixel_data = 8'b00011100;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b01101100;
                    4: pixel_data = 8'b11111111; 5: pixel_data = 8'b00001100;
                    6: pixel_data = 8'b00001100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 21: 5 (ASCII 53)
            7'd21: case(row)
                    0: pixel_data = 8'b01111110; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01111100; 3: pixel_data = 8'b00000110;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 22: 6 (ASCII 54)
            7'd22: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 23: 7 (ASCII 55)
            7'd23: case(row)
                    0: pixel_data = 8'b01111110; 1: pixel_data = 8'b00000110;
                    2: pixel_data = 8'b00001100; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00110000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b00110000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 24: 8 (ASCII 56)
            7'd24: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 25: 9 (ASCII 57)
            7'd25: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b00111110;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 26: : (ASCII 58)
            7'd26: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 27: ; (ASCII 59)
            7'd27: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b01100000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 28: < (ASCII 60)
            7'd28: case(row)
                    0: pixel_data = 8'b00001100; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00110000; 3: pixel_data = 8'b01100000;
                    4: pixel_data = 8'b00110000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00001100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 29: = (ASCII 61)
            7'd29: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01111110; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b01111110; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 30: > (ASCII 62)
            7'd30: case(row)
                    0: pixel_data = 8'b00110000; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00001100; 3: pixel_data = 8'b00000110;
                    4: pixel_data = 8'b00001100; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00110000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 31: ? (ASCII 63)
            7'd31: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00001100;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00011000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 32: @ (ASCII 64)
            7'd32: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01011010; 3: pixel_data = 8'b01011010;
                    4: pixel_data = 8'b01011110; 5: pixel_data = 8'b00110010;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 33: A (ASCII 65)
            7'd33: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01111110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 34: B (ASCII 66)
            7'd34: case(row)
                    0: pixel_data = 8'b01111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01111100;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 35: C (ASCII 67)
            7'd35: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b01100000;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 36: D (ASCII 68)
            7'd36: case(row)
                    0: pixel_data = 8'b01111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 37: E (ASCII 69)
            7'd37: case(row)
                    0: pixel_data = 8'b01111110; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b01111100;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b01111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 38: F (ASCII 70)
            7'd38: case(row)
                    0: pixel_data = 8'b01111110; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b01111100;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b01100000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 39: G (ASCII 71)
            7'd39: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b01101110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 40: H (ASCII 72)
            7'd40: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01111110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 41: I (ASCII 73)
            7'd41: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 42: J (ASCII 74)
            7'd42: case(row)
                    0: pixel_data = 8'b00000110; 1: pixel_data = 8'b00000110;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00000110;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 43: K (ASCII 75)
            7'd43: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01101100; 3: pixel_data = 8'b01111000;
                    4: pixel_data = 8'b01101100; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 44: L (ASCII 76)
            7'd44: case(row)
                    0: pixel_data = 8'b01100000; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b01100000;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b01111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 45: M (ASCII 77)
            7'd45: case(row)
                    0: pixel_data = 8'b01100011; 1: pixel_data = 8'b01110111;
                    2: pixel_data = 8'b01101011; 3: pixel_data = 8'b01100011;
                    4: pixel_data = 8'b01100011; 5: pixel_data = 8'b01100011;
                    6: pixel_data = 8'b01100011; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 46: N (ASCII 78)
            7'd46: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01110110; 3: pixel_data = 8'b01101110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 47: O (ASCII 79)
            7'd47: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 48: P (ASCII 80)
            7'd48: case(row)
                    0: pixel_data = 8'b01111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01111100;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b01100000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 49: Q (ASCII 81)
            7'd49: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b00110110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000110;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 50: R (ASCII 82)
            7'd50: case(row)
                    0: pixel_data = 8'b01111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01111100;
                    4: pixel_data = 8'b01101100; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 51: S (ASCII 83)
            7'd51: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 52: T (ASCII 84)
            7'd52: case(row)
                    0: pixel_data = 8'b11111110; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00011000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 53: U (ASCII 85)
            7'd53: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 54: V (ASCII 86)
            7'd54: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 55: W (ASCII 87)
            7'd55: case(row)
                    0: pixel_data = 8'b01100011; 1: pixel_data = 8'b01100011;
                    2: pixel_data = 8'b01100011; 3: pixel_data = 8'b01100011;
                    4: pixel_data = 8'b01101101; 5: pixel_data = 8'b01110111;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 56: X (ASCII 88)
            7'd56: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00111100; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 57: Y (ASCII 89)
            7'd57: case(row)
                    0: pixel_data = 8'b01100110; 1: pixel_data = 8'b01100110;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00011000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 58: Z (ASCII 90)
            7'd58: case(row)
                    0: pixel_data = 8'b01111110; 1: pixel_data = 8'b00000110;
                    2: pixel_data = 8'b00001100; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00110000; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b01111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 59: [ (ASCII 91)
            7'd59: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00110000;
                    2: pixel_data = 8'b00110000; 3: pixel_data = 8'b00110000;
                    4: pixel_data = 8'b00110000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 60: \ (ASCII 92)
            7'd60: case(row)
                    0: pixel_data = 8'b10000000; 1: pixel_data = 8'b11000000;
                    2: pixel_data = 8'b01100000; 3: pixel_data = 8'b00110000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00001100;
                    6: pixel_data = 8'b00000110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 61: ] (ASCII 93)
            7'd61: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00001100;
                    2: pixel_data = 8'b00001100; 3: pixel_data = 8'b00001100;
                    4: pixel_data = 8'b00001100; 5: pixel_data = 8'b00001100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 62: ^ (ASCII 94)
            7'd62: case(row)
                    0: pixel_data = 8'b00011000; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 63: _ (ASCII 95)
            7'd63: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00000000; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b11111111;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 64: ` (ASCII 96)
            7'd64: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b00000000; 3: pixel_data = 8'b00000000;
                    4: pixel_data = 8'b00000000; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 65: a (ASCII 97)
            7'd65: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00000110;
                    4: pixel_data = 8'b00111110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 66: b (ASCII 98)
            7'd66: case(row)
                    0: pixel_data = 8'b01100000; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 67: c (ASCII 99)
            7'd67: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 68: d (ASCII 100)
            7'd68: case(row)
                    0: pixel_data = 8'b00000110; 1: pixel_data = 8'b00000110;
                    2: pixel_data = 8'b00111110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 69: e (ASCII 101)
            7'd69: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01111110; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 70: f (ASCII 102)
            7'd70: case(row)
                    0: pixel_data = 8'b00011100; 1: pixel_data = 8'b00110000;
                    2: pixel_data = 8'b00110000; 3: pixel_data = 8'b01111100;
                    4: pixel_data = 8'b00110000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b00110000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 71: g (ASCII 103)
            7'd71: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b00111110;
                    6: pixel_data = 8'b00000110; 7: pixel_data = 8'b00111100;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 72: h (ASCII 104)
            7'd72: case(row)
                    0: pixel_data = 8'b01100000; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 73: i (ASCII 105)
            7'd73: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 74: j (ASCII 106)
            7'd74: case(row)
                    0: pixel_data = 8'b00000110; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00000110; 3: pixel_data = 8'b00000110;
                    4: pixel_data = 8'b00000110; 5: pixel_data = 8'b00000110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00111100;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 75: k (ASCII 107)
            7'd75: case(row)
                    0: pixel_data = 8'b01100000; 1: pixel_data = 8'b01100000;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01101100;
                    4: pixel_data = 8'b01111000; 5: pixel_data = 8'b01101100;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 76: l (ASCII 108)
            7'd76: case(row)
                    0: pixel_data = 8'b00111000; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00011000; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00011000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 77: m (ASCII 109)
            7'd77: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01010100; 3: pixel_data = 8'b01101010;
                    4: pixel_data = 8'b01101010; 5: pixel_data = 8'b01101010;
                    6: pixel_data = 8'b01000010; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 78: n (ASCII 110)
            7'd78: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 79: o (ASCII 111)
            7'd79: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 80: p (ASCII 112)
            7'd80: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01111100; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01111100;
                    6: pixel_data = 8'b01100000; 7: pixel_data = 8'b01100000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 81: q (ASCII 113)
            7'd81: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b00111110;
                    6: pixel_data = 8'b00000110; 7: pixel_data = 8'b00000110;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 82: r (ASCII 114)
            7'd82: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01101100; 3: pixel_data = 8'b01110110;
                    4: pixel_data = 8'b01100000; 5: pixel_data = 8'b01100000;
                    6: pixel_data = 8'b01100000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 83: s (ASCII 115)
            7'd83: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b01100010;
                    4: pixel_data = 8'b00111100; 5: pixel_data = 8'b00000110;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00111100;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 84: t (ASCII 116)
            7'd84: case(row)
                    0: pixel_data = 8'b00011000; 1: pixel_data = 8'b00011000;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00011000;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00011000;
                    6: pixel_data = 8'b00001100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 85: u (ASCII 117)
            7'd85: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b01100110;
                    6: pixel_data = 8'b00111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 86: v (ASCII 118)
            7'd86: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 87: w (ASCII 119)
            7'd87: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01100011; 3: pixel_data = 8'b01100011;
                    4: pixel_data = 8'b01101101; 5: pixel_data = 8'b01110111;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 88: x (ASCII 120)
            7'd88: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b01100110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 89: y (ASCII 121)
            7'd89: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01100110; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b01100110; 5: pixel_data = 8'b00111110;
                    6: pixel_data = 8'b00000110; 7: pixel_data = 8'b00111100;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 90: z (ASCII 122)
            7'd90: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b01111110; 3: pixel_data = 8'b00001100;
                    4: pixel_data = 8'b00011000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b01111110; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 91: { (ASCII 123)
            7'd91: case(row)
                    0: pixel_data = 8'b00011100; 1: pixel_data = 8'b00110000;
                    2: pixel_data = 8'b00110000; 3: pixel_data = 8'b01111000;
                    4: pixel_data = 8'b00110000; 5: pixel_data = 8'b00110000;
                    6: pixel_data = 8'b00011100; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 92: | (ASCII 124)
            7'd92: case(row)
                    0: pixel_data = 8'b00111100; 1: pixel_data = 8'b00111100;
                    2: pixel_data = 8'b00111100; 3: pixel_data = 8'b00111100;
                    4: pixel_data = 8'b00111100; 5: pixel_data = 8'b00111100;
                    6: pixel_data = 8'b00111100; 7: pixel_data = 8'b00111100;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 93: } (ASCII 125)
            7'd93: case(row)
                    0: pixel_data = 8'b00111000; 1: pixel_data = 8'b00001100;
                    2: pixel_data = 8'b00001100; 3: pixel_data = 8'b00011110;
                    4: pixel_data = 8'b00001100; 5: pixel_data = 8'b00001100;
                    6: pixel_data = 8'b00111000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            // 94: ~ (ASCII 126)
            7'd94: case(row)
                    0: pixel_data = 8'b00000000; 1: pixel_data = 8'b00000000;
                    2: pixel_data = 8'b00000000; 3: pixel_data = 8'b01100110;
                    4: pixel_data = 8'b10011001; 5: pixel_data = 8'b00000000;
                    6: pixel_data = 8'b00000000; 7: pixel_data = 8'b00000000;
                    default: pixel_data = 8'b00000000;
                  endcase

            default: pixel_data = 8'b00000000;
        endcase
    end
endmodule
