`timescale 1ns / 1ps

module CurrentPatternGenerator #(
    parameter SQUARE_SIZE = 5,
    parameter PHASE_BITS  = 5  
)(
    input  wire signed [12:0] virtual_x, 
    input  wire signed [12:0] virtual_y,  
    input  wire [PHASE_BITS-1:0] anim_phase,
    
    output wire pattern_move_right,
    output wire pattern_move_left,
    output wire pattern_move_down,
    output wire pattern_move_up
);

    wire [PHASE_BITS-1:0] mod_x_right = virtual_x[4:0] - anim_phase;
    wire [PHASE_BITS-1:0] mod_x_left  = virtual_x[4:0] + anim_phase;
    wire [PHASE_BITS-1:0] mod_y_down  = virtual_y[4:0] - anim_phase;
    wire [PHASE_BITS-1:0] mod_y_up    = virtual_y[4:0] + anim_phase;

    assign pattern_move_right = (mod_x_right < SQUARE_SIZE);
    assign pattern_move_left  = (mod_x_left  < SQUARE_SIZE);
    assign pattern_move_down  = (mod_y_down  < SQUARE_SIZE);
    assign pattern_move_up    = (mod_y_up    < SQUARE_SIZE);

endmodule