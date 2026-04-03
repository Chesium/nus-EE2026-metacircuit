`timescale 1ns / 1ps

module CurrentPatternGenerator #(
    parameter SQUARE_SIZE = 5, // 黃色方塊的長度 (Pixels)
    parameter PHASE_BITS  = 5  // 週期 32 (2^5)
)(
    input  wire signed [12:0] virtual_x,  // 已扣除 Panning 的絕對畫布 X 座標
    input  wire signed [12:0] virtual_y,  // 已扣除 Panning 的絕對畫布 Y 座標
    input  wire [PHASE_BITS-1:0] anim_phase, // 當前動畫影格
    
    // 輸出四個方向的動態遮罩 (1 代表該像素當下應該是電流方塊)
    output wire pattern_move_right,
    output wire pattern_move_left,
    output wire pattern_move_down,
    output wire pattern_move_up
);

    // 透過擷取低 5 bit 進行加減法，硬體上等同於 % 32 的取餘數運算
    wire [PHASE_BITS-1:0] mod_x_right = virtual_x[4:0] - anim_phase;
    wire [PHASE_BITS-1:0] mod_x_left  = virtual_x[4:0] + anim_phase;
    wire [PHASE_BITS-1:0] mod_y_down  = virtual_y[4:0] - anim_phase;
    wire [PHASE_BITS-1:0] mod_y_up    = virtual_y[4:0] + anim_phase;

    // 比較運算決定方塊範圍
    assign pattern_move_right = (mod_x_right < SQUARE_SIZE);
    assign pattern_move_left  = (mod_x_left  < SQUARE_SIZE);
    assign pattern_move_down  = (mod_y_down  < SQUARE_SIZE);
    assign pattern_move_up    = (mod_y_up    < SQUARE_SIZE);

endmodule