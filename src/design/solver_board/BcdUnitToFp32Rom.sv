`timescale 1ns / 1ps

module BcdUnitToFp32Rom #(
    parameter MEM_FILE = "bcd_unit_to_fp32_rom.mem"
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [11:0] value_bcd,
    input  wire [7:0]  unit_code,
    output reg         done = 1'b0,
    output reg         invalid = 1'b0,
    output reg [31:0]  value_fp32 = 32'd0
);

    localparam integer ROM_ADDR_WIDTH = 13;
    localparam integer ROM_WORDS = (1 << ROM_ADDR_WIDTH);

    (* rom_style = "block", ram_style = "block" *)
    reg [31:0] rom [0:ROM_WORDS-1];

    reg [ROM_ADDR_WIDTH-1:0] rom_addr = {ROM_ADDR_WIDTH{1'b0}};
    reg pending = 1'b0;
    reg pending_invalid = 1'b0;

    wire [3:0] digit_h = value_bcd[11:8];
    wire [3:0] digit_t = value_bcd[7:4];
    wire [3:0] digit_o = value_bcd[3:0];
    wire bcd_valid = (digit_h <= 4'd9) && (digit_t <= 4'd9) && (digit_o <= 4'd9);
    wire unit_valid = (unit_code <= 8'd6);
    wire [9:0] decimal_value = (digit_h * 10'd100) + (digit_t * 10'd10) + digit_o;
    wire [ROM_ADDR_WIDTH-1:0] next_addr = {unit_code[2:0], decimal_value};

    initial begin
        $readmemh(MEM_FILE, rom);
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            rom_addr <= {ROM_ADDR_WIDTH{1'b0}};
            pending <= 1'b0;
            pending_invalid <= 1'b0;
            done <= 1'b0;
            invalid <= 1'b0;
            value_fp32 <= 32'd0;
        end else begin
            done <= 1'b0;
            if (start) begin
                rom_addr <= next_addr;
                pending <= 1'b1;
                pending_invalid <= !(bcd_valid && unit_valid);
            end else if (pending) begin
                pending <= 1'b0;
                done <= 1'b1;
                invalid <= pending_invalid;
                value_fp32 <= pending_invalid ? 32'd0 : rom[rom_addr];
            end
        end
    end
endmodule
