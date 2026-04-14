`timescale 1ns / 1ps

module CurrentPhaseController #(
    parameter CLK_DIV_MAX = 22'd1000000, 
    parameter PHASE_BITS  = 5            
)(
    input  wire                  clk_pixel,
    input  wire                  rst,
    output reg  [PHASE_BITS-1:0] anim_phase
);

    reg [21:0] tick_counter;

    always @(posedge clk_pixel) begin
        if (rst) begin
            tick_counter <= 0;
            anim_phase   <= 0;
        end else begin
            if (tick_counter >= CLK_DIV_MAX - 1) begin
                tick_counter <= 0;
                anim_phase   <= anim_phase + 1; 
            end else begin
                tick_counter <= tick_counter + 1;
            end
        end
    end

endmodule