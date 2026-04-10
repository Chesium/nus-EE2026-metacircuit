`timescale 1ns / 1ps

module ColorOverlayRAM (
    // ==========================================
    // Write Port (Connected to Backend/PostProcessing)
    // ==========================================
    input  wire        clk_wr,
    input  wire        we,           // Write Enable
    input  wire [4:0]  wr_i,         // Cell X position (0 to 17)
    input  wire [3:0]  wr_j,         // Cell Y position (0 to 15)
    input  wire [3:0]  wr_color_idx, // Color value 0 to 15

    // ==========================================
    // Read Port (Connected to VGA Frontend / GlobalRender_top)
    // ==========================================
    input  wire        clk_rd,
    input  wire [4:0]  rd_i,         // Target Cell X to render
    input  wire [3:0]  rd_j,         // Target Cell Y to render
    output wire [11:0] rd_rgb_out    // Mapped 12-bit RGB Color Output
);

    // Canvas Size is 18x16 = 288. We use a 512-deep RAM (9-bit address)
    reg [3:0] color_ram [0:511];
    
    // 1D Address calculation: i + (j * 18)
    wire [8:0] wr_addr = wr_i + (wr_j * 18);
    wire [8:0] rd_addr = rd_i + (rd_j * 18);
    
    reg [3:0] read_idx;

    // RAM Write Process
    always @(posedge clk_wr) begin
        if (we) begin
            color_ram[wr_addr] <= wr_color_idx;
        end
    end

    // RAM Read Process
    always @(posedge clk_rd) begin
        read_idx <= color_ram[rd_addr];
    end

    // Color Mapping LUT (Look-Up Table)
    reg [11:0] rgb_mapped;
    always @(*) begin
        case (read_idx)
            // Gradient: Red -> White
            4'd0:  rgb_mapped = 12'hF00; // Red
            4'd1:  rgb_mapped = 12'hF22;
            4'd2:  rgb_mapped = 12'hF44;
            4'd3:  rgb_mapped = 12'hF77;
            4'd4:  rgb_mapped = 12'hF99;
            4'd5:  rgb_mapped = 12'hFBB;
            4'd6:  rgb_mapped = 12'hFDD;
            4'd7:  rgb_mapped = 12'hFFF; // White
            // Gradient: White -> Green
            4'd8:  rgb_mapped = 12'hFFF; // White
            4'd9:  rgb_mapped = 12'hDFD;
            4'd10: rgb_mapped = 12'hBFB;
            4'd11: rgb_mapped = 12'h9F9;
            4'd12: rgb_mapped = 12'h7F7;
            4'd13: rgb_mapped = 12'h4F4;
            4'd14: rgb_mapped = 12'h2F2;
            4'd15: rgb_mapped = 12'h0F0; // Green
        endcase
    end
    
    assign rd_rgb_out = rgb_mapped;

endmodule