`timescale 1ns / 1ps

module DummyDataGenerate (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       vsync_edge,
    output reg        wr_en,
    output reg  [7:0] wr_addr,
    output reg  [7:0] wr_data
);

    localparam IDLE  = 1'b0;
    localparam WRITE = 1'b1;
    reg state;
    reg [5:0] phase_offset;

    // 完美適配高度 128 的 64 點正弦波 LUT
    // 中心 Y=63，振幅 60 (數值範圍 3~123)，絕對不會發生溢位削平！
    reg [7:0] sin_lut [0:63];
    initial begin
        sin_lut[0]=63;  sin_lut[1]=68;  sin_lut[2]=74;  sin_lut[3]=80;
        sin_lut[4]=85;  sin_lut[5]=91;  sin_lut[6]=96;  sin_lut[7]=101;
        sin_lut[8]=105; sin_lut[9]=109; sin_lut[10]=112;sin_lut[11]=115;
        sin_lut[12]=118;sin_lut[13]=120;sin_lut[14]=121;sin_lut[15]=122;
        sin_lut[16]=123;sin_lut[17]=122;sin_lut[18]=121;sin_lut[19]=120;
        sin_lut[20]=118;sin_lut[21]=115;sin_lut[22]=112;sin_lut[23]=109;
        sin_lut[24]=105;sin_lut[25]=101;sin_lut[26]=96; sin_lut[27]=91;
        sin_lut[28]=85; sin_lut[29]=80; sin_lut[30]=74; sin_lut[31]=68;
        sin_lut[32]=63; sin_lut[33]=58; sin_lut[34]=52; sin_lut[35]=46;
        sin_lut[36]=41; sin_lut[37]=35; sin_lut[38]=30; sin_lut[39]=25;
        sin_lut[40]=21; sin_lut[41]=17; sin_lut[42]=14; sin_lut[43]=11;
        sin_lut[44]=8;  sin_lut[45]=6;  sin_lut[46]=5;  sin_lut[47]=4;
        sin_lut[48]=3;  sin_lut[49]=4;  sin_lut[50]=5;  sin_lut[51]=6;
        sin_lut[52]=8;  sin_lut[53]=11; sin_lut[54]=14; sin_lut[55]=17;
        sin_lut[56]=21; sin_lut[57]=25; sin_lut[58]=30; sin_lut[59]=35;
        sin_lut[60]=41; sin_lut[61]=46; sin_lut[62]=52; sin_lut[63]=58;
    end

    wire [5:0] lut_index = wr_addr[5:0] + phase_offset;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            wr_en        <= 1'b0;
            wr_addr      <= 8'd0;
            wr_data      <= 8'd0;
            phase_offset <= 6'd0;
        end else begin
            case (state)
                IDLE: begin
                    wr_en <= 1'b0;
                    if (vsync_edge) begin
                        state   <= WRITE;
                        wr_addr <= 8'd0;
                        phase_offset <= phase_offset + 6'd1; 
                    end
                end
                WRITE: begin
                    wr_en <= 1'b1;
                    wr_data <= sin_lut[lut_index];

                    // 【重點修復】：寫滿整個 256 位址的 RAM，防止讀取時遇到空資料造成水平截斷
                    if (wr_addr == 8'd255) begin
                        state <= IDLE;
                        wr_en <= 1'b0;
                    end else begin
                        wr_addr <= wr_addr + 8'd1;
                    end
                end
            endcase
        end
    end
endmodule