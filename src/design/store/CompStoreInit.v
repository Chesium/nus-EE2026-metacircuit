`timescale 1ns / 1ps
/*
 * ComponentStore初始化示例
 * 用于测试ComponentPropertyPanel功能
 * 
 * 数据格式：40位
 * - type[3:0]     : 4位元件类型
 * - position[7:0] : 8位位置 (Xpos[3:0] + Ypos[3:0]<<4)
 * - rotation[1:0] : 2位旋转角度
 * - value[12:0]   : 13位数值 (10位数值 + 3位单位)
 * - node1[3:0]    : 4位节点1
 * - node2[3:0]    : 4位节点2
 *
 * 元件类型编码：
 * 4'b0000 = Wire (线缆)
 * 4'b0001 = Ground (接地)
 * 4'b0010 = Resistor (电阻)
 * 4'b0011 = Capacitor (电容)
 * 4'b0100 = Inductor (电感)
 * 4'b0101 = Voltage Source (电压源)
 * 4'b0110 = Current Source (电流源)
 */

module CompStoreInit #(
    parameter integer ADDR_WIDTH = 8,
    parameter integer DATA_WIDTH = 40
)(
    input wire clk,
    input wire sw_init,          // SW[14] 上升沿触发初始化
    output reg init_done,
    output reg [ADDR_WIDTH-1:0] init_addr,
    output reg [DATA_WIDTH-1:0] init_data,
    output reg init_w_en
);

    // 检测 SW[14] 上升沿 (从0→1时触发)
    reg sw_init_d1, sw_init_d2;
    wire sw_init_edge;
    always @(posedge clk) begin
        sw_init_d1 <= sw_init;
        sw_init_d2 <= sw_init_d1;
    end
    assign sw_init_edge = sw_init_d1 & ~sw_init_d2;  // 上升沿检测

    // 初始化状态机
    reg [7:0] init_state;
    reg [7:0] INIT_MARKER;
    reg [7:0] INIT_MARKER_WAIT;
    reg [31:0] init_counter;
    
    localparam INIT_IDLE = 8'd0;
    localparam INIT_WRITE = 8'd1;
    localparam INIT_WAIT = 8'd2;
    localparam INIT_DONE = 8'd255;
    
    // 测试数据存储 (地址 -> 40位数据)
    // 格式：{type[3:0], position[7:0], rotation[1:0], value[12:0], node1[3:0], node2[3:0]}
    function [DATA_WIDTH-1:0] make_comp_data;
        input [3:0] type;
        input [7:0] position;
        input [1:0] rotation;
        input [12:0] value;
        input [3:0] node1;
        input [3:0] node2;
        begin
            make_comp_data = {type, position, rotation, value, node1, node2};
        end
    endfunction
    
    always @(posedge clk) begin
        if (sw_init_edge) begin
            init_state <= INIT_IDLE;
            init_addr <= 8'd0;
            init_data <= 40'd0;
            init_w_en <= 1'b0;
            init_done <= 1'b0;
            init_counter <= 32'd0;
        end else begin
            case (init_state)
                INIT_IDLE: begin
                    init_counter <= init_counter + 1;
                    if (init_counter == 32'd1000000) begin  // 延迟约40ms
                        init_state <= INIT_WRITE;
                        init_addr <= 8'd0;
                        init_counter <= 32'd0;
                    end
                end
                
                INIT_WRITE: begin
                    // 写入测试数据
                    case (init_addr)
                        // 地址0: 电阻 100 Ohm at (2,3)
                        8'd0: init_data <= make_comp_data(4'b0010, 8'h32, 2'b00, {10'd100, 3'd0}, 4'd0, 4'd1);
                        
                        // 地址1: 电压源 5V at (5,5)
                        8'd1: init_data <= make_comp_data(4'b0101, 8'h55, 2'b00, {10'd5, 3'd0}, 4'd1, 4'd2);
                        
                        // 地址2: 电容 10uF at (8,2)
                        8'd2: init_data <= make_comp_data(4'b0011, 8'h28, 2'b00, {10'd10, 3'd1}, 4'd2, 4'd3);
                        
                        // 地址3: 电感 100mH at (3,7)
                        8'd3: init_data <= make_comp_data(4'b0100, 8'h73, 2'b00, {10'd100, 3'd0}, 4'd3, 4'd4);
                        
                        // 地址4: 电流源 20mA at (10,10)
                        8'd4: init_data <= make_comp_data(4'b0110, 8'hAA, 2'b00, {10'd20, 3'd0}, 4'd4, 4'd5);
                        
                        // 地址5: 接地 at (1,1)
                        8'd5: init_data <= make_comp_data(4'b0001, 8'h11, 2'b00, {13'd0}, 4'd0, 4'd0);
                        
                        // 地址6: 线缆 at (0,0)
                        8'd6: init_data <= make_comp_data(4'b0000, 8'h00, 2'b00, {13'd0}, 4'd5, 4'd0);
                        
                        // 地址7: 电阻 1k Ohm at (6,4)
                        8'd7: init_data <= make_comp_data(4'b0010, 8'h46, 2'b00, {10'd1, 3'd3}, 4'd5, 4'd6);
                        
                        // 未初始化的地址写入特殊标记 (非零)，以便识别为空单元格
                        default: init_data <= 40'hFFFF_FFFF_F;  // 全F标记表示空单元格
                    endcase
                    
                    init_w_en <= 1'b1;
                    init_state <= INIT_WAIT;
                end
                
                INIT_WAIT: begin
                    // 等待一个周期
                    init_w_en <= 1'b0;
                    if (init_addr < 8'd255) begin
                        init_addr <= init_addr + 1'b1;
                        if (init_addr < 8'd8) begin
                            init_state <= INIT_WRITE;  // 继续写有效数据 (地址 0-7)
                        end else begin
                            init_state <= INIT_MARKER;  // 开始写空标记 (地址 8-255)
                        end
                    end else begin
                        init_state <= INIT_DONE;
                        init_done <= 1'b1;
                    end
                end
                
                INIT_MARKER: begin
                    // 为未使用的地址写入空标记
                    init_data <= 40'hFFFF_FFFF_F;
                    init_w_en <= 1'b1;
                    init_state <= INIT_MARKER_WAIT;
                end
                
                INIT_MARKER_WAIT: begin
                    init_w_en <= 1'b0;
                    if (init_addr < 8'd255) begin
                        init_addr <= init_addr + 1'b1;
                        init_state <= INIT_MARKER;
                    end else begin
                        init_state <= INIT_DONE;
                        init_done <= 1'b1;
                    end
                end
                
                INIT_DONE: begin
                    init_w_en <= 1'b0;
                    init_done <= 1'b1;
                end
                
                default: begin
                    init_state <= INIT_IDLE;
                end
            endcase
        end
    end

endmodule
