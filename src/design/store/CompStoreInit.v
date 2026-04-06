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
    reg [31:0] init_counter;
    reg [3:0] step_counter;  // 步骤计数器 (0-8)

    localparam INIT_IDLE = 8'd0;
    localparam INIT_WRITE = 8'd1;
    localparam INIT_WAIT = 8'd2;
    localparam INIT_DONE = 8'd255;

    // 测试数据存储 (地址 -> 40位数据)
    // 地址计算公式: addr = Xpos + Ypos * 16
    // 40位格式：{type[3:0], position[7:0], rotation[1:0], value[12:0], node1[3:0], node2[3:0], enable[1:0], 保留[2:0]}
    // 实际分配：[39:36]=type, [35:28]=position, [27:26]=rotation, [25:13]=value, [12:9]=node1, [8:5]=node2, [4:0]=5位(其中[1:0]=enable)
    function [DATA_WIDTH-1:0] make_comp_data;
        input [3:0] type;
        input [7:0] position;
        input [1:0] rotation;
        input [12:0] value;
        input [3:0] node1;
        input [3:0] node2;
        begin
            // 总共 40 位：4+8+2+13+4+4+5 = 40
            // 最后 5 位中，低 2 位是 enable，高 3 位保留
            make_comp_data = {type, position, rotation, value, node1, node2, 3'b000, 2'b01};
        end
    endfunction
    
    always @(posedge clk) begin
        if (sw_init_edge) begin
            init_state <= INIT_IDLE;
            init_addr <= 8'd0;
            init_data <= 40'd0;
            init_w_en <= 1'b0;
            init_done <= 1'b0;
            step_counter <= 4'd0;
            init_counter <= 32'd0;
        end else begin
            case (init_state)
                INIT_IDLE: begin
                    init_counter <= init_counter + 1;
                    if (init_counter == 32'd1000000) begin  // 延迟约40ms
                        init_state <= INIT_WRITE;
                        step_counter <= 4'd0;
                        init_counter <= 32'd0;
                    end
                end
                
                INIT_WRITE: begin
                    // 写入测试数据 - 根据步骤设置正确的 RAM 地址
                    // 地址计算公式: addr = Xpos + Ypos * 16
                    case (step_counter)
                        4'd0: begin
                            init_addr <= 8'd0;   // 线缆 at (0,0)
                            init_data <= make_comp_data(4'b0000, 8'h00, 2'b00, {13'd0}, 4'd0, 4'd0);
                        end
                        4'd1: begin
                            init_addr <= 8'd17;  // 线缆 at (1,1)
                            init_data <= make_comp_data(4'b0000, 8'h11, 2'b00, {13'd0}, 4'd0, 4'd1);
                        end
                        4'd2: begin
                            init_addr <= 8'd50;  // 电阻 100 Ohm at (2,3)
                            init_data <= make_comp_data(4'b0010, 8'h32, 2'b00, {10'd100, 3'd0}, 4'd2, 4'd3);
                        end
                        4'd3: begin
                            init_addr <= 8'd85;  // 电压源 5V at (5,5)
                            init_data <= make_comp_data(4'b0101, 8'h55, 2'b00, {10'd5, 3'd0}, 4'd4, 4'd5);
                        end
                        4'd4: begin
                            init_addr <= 8'd40;  // 电容 10uF at (8,2)
                            init_data <= make_comp_data(4'b0011, 8'h28, 2'b00, {10'd10, 3'd1}, 4'd1, 4'd2);
                        end
                        4'd5: begin
                            init_addr <= 8'd115; // 电感 100mH at (3,7)
                            init_data <= make_comp_data(4'b0100, 8'h73, 2'b00, {10'd100, 3'd0}, 4'd5, 4'd6);
                        end
                        4'd6: begin
                            init_addr <= 8'd170; // 电流源 20mA at (10,10)
                            init_data <= make_comp_data(4'b0110, 8'hAA, 2'b00, {10'd20, 3'd0}, 4'd6, 4'd7);
                        end
                        4'd7: begin
                            init_addr <= 8'd71;  // 电阻 1k Ohm at (7,4)
                            init_data <= make_comp_data(4'b0010, 8'h47, 2'b00, {10'd1, 3'd3}, 4'd3, 4'd4);
                        end
                        default: begin
                            init_data <= 40'd0;
                        end
                    endcase

                    init_w_en <= 1'b1;
                    init_state <= INIT_WAIT;
                end
                
                INIT_WAIT: begin
                    // 等待一个周期（不复位 init_addr，保持上一步设置的地址）
                    init_w_en <= 1'b0;
                    if (step_counter < 4'd8) begin
                        step_counter <= step_counter + 1'b1;
                        init_state <= INIT_WRITE;
                    end else begin
                        // 所有测试数据写完，初始化完成
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
