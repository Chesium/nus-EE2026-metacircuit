`timescale 1ns / 1ps

module DummyDataGenerate (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       vsync_edge,
    output reg        wr_en,
    output reg  [7:0] wr_addr,
    output reg  [7:0] wr_data,
    output reg  [7:0] max_out 
);

    localparam IDLE  = 1'b0;
    localparam WRITE = 1'b1;
    reg state;
    reg [5:0] phase_offset;

    // =========================================================
    // 【時序修復】解耦螢幕刷新率 (60Hz) 與波形動畫率 (10Hz)
    // =========================================================
    reg [21:0] speed_counter;
    reg        phase_advance_req;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            speed_counter     <= 22'd0;
            phase_advance_req <= 1'b0;
        end else begin
            // 25MHz clock, 2,500,000 cycles = 100ms
            if (speed_counter >= 22'd2499999) begin
                speed_counter     <= 22'd0;
                phase_advance_req <= 1'b1; // 發出波形平移請求
            end else begin
                speed_counter <= speed_counter + 22'd1;
            end
            
            // 當狀態機在 IDLE 準備進入下一個 Frame 且確認吃到平移請求時，清除請求旗標
            if (state == IDLE && vsync_edge && phase_advance_req) begin
                phase_advance_req <= 1'b0;
            end
        end
    end

    // =========================================================
    // 64 點正弦波 LUT (完美適配 128 高度，振幅安全區 3~123)
    // =========================================================
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
    reg  [7:0] current_max;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            wr_en        <= 1'b0;
            wr_addr      <= 8'd0;
            wr_data      <= 8'd0;
            phase_offset <= 6'd0;
            current_max  <= 8'd0;
            max_out      <= 8'd0;
        end else begin
            case (state)
                IDLE: begin
                    wr_en <= 1'b0;
                    
                    // 【關鍵修復】不管時間到了沒，每個 VSYNC 都強制重繪整個 Ping-Pong Buffer 確保畫面穩定！
                    if (vsync_edge) begin
                        state <= WRITE;
                        wr_addr <= 8'd0;
                        
                        // 只有當 100ms 的平移請求到達時，才允許波形往前走一步
                        if (phase_advance_req) begin
                            phase_offset <= phase_offset + 6'd1; 
                        end
                        
                        max_out     <= current_max; 
                        current_max <= 8'd0;        
                    end
                end
                WRITE: begin
                    wr_en <= 1'b1;
                    wr_data <= sin_lut[lut_index];

                    // 硬體即時峰值比對邏輯 (Peak Detector)
                    if (sin_lut[lut_index] > current_max) begin
                        current_max <= sin_lut[lut_index];
                    end

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