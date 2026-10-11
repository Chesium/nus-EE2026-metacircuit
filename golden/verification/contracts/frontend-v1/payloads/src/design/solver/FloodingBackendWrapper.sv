`timescale 1ns / 1ps

module FloodingBackendWrapper #(
    parameter integer GRID_WIDTH = 18,
    parameter integer GRID_HEIGHT = 16,
    parameter integer QUEUE_DEPTH = GRID_WIDTH * GRID_HEIGHT * 4
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    output reg        busy,
    output reg        done,

    output wire       fetchP_ram_ren,
    output wire [8:0] fetchP_ram_addr,
    input  wire [15:0] fetchP_ram_rdata,

    input  wire       fetchR_start,
    input  wire [7:0] fetchR_i,
    input  wire [7:0] fetchR_j,
    output wire       fetchR_done,
    output wire [7:0] fetchR_result
);
    localparam [2:0] WRAP_IDLE  = 3'd0;
    localparam [2:0] WRAP_RESET = 3'd1;
    localparam [2:0] WRAP_START = 3'd2;
    localparam [2:0] WRAP_WAIT  = 3'd3;
    localparam [2:0] WRAP_DONE  = 3'd4;

    reg [2:0] wrap_state = WRAP_IDLE;
    wire      store_clear = (wrap_state == WRAP_RESET);
    wire      inner_rst_n = rst_n && (wrap_state != WRAP_RESET);
    reg       core_start = 1'b0;

    wire       core_busy;
    wire       core_done;
    wire       core_fetchP_start;
    wire [7:0] core_fetchP_i;
    wire [7:0] core_fetchP_j;
    wire       core_fetchP_done;
    wire [3:0] core_fetchP_result;
    wire       core_getVisited_start;
    wire [7:0] core_getVisited_i;
    wire [7:0] core_getVisited_j;
    wire       core_getVisited_done;
    wire       core_getVisited_result;
    wire       core_setVisited_start;
    wire [7:0] core_setVisited_i;
    wire [7:0] core_setVisited_j;
    wire       core_setVisited_done;
    wire       core_storeR_start;
    wire [7:0] core_storeR_i;
    wire [7:0] core_storeR_j;
    wire [7:0] core_storeR_v;
    wire       core_storeR_done;
    wire       core_addQueue_start;
    wire [7:0] core_addQueue_i;
    wire [7:0] core_addQueue_j;
    wire [31:0] core_addQueue_d;
    wire       core_addQueue_done;
    wire       core_getQueueLen_start;
    wire       core_getQueueLen_done;
    wire [15:0] core_getQueueLen_result;
    wire       core_popQueue_start;
    wire       core_popQueue_done;
    wire [17:0] core_popQueue_result;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wrap_state <= WRAP_IDLE;
            core_start <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            core_start <= 1'b0;
            done <= 1'b0;

            case (wrap_state)
                WRAP_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        wrap_state <= WRAP_RESET;
                    end
                end
                WRAP_RESET: begin
                    busy <= 1'b1;
                    wrap_state <= WRAP_START;
                end
                WRAP_START: begin
                    busy <= 1'b1;
                    core_start <= 1'b1;
                    wrap_state <= WRAP_WAIT;
                end
                WRAP_WAIT: begin
                    busy <= 1'b1;
                    if (core_done) begin
                        wrap_state <= WRAP_DONE;
                    end
                end
                WRAP_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    wrap_state <= WRAP_IDLE;
                end
                default: begin
                    busy <= 1'b0;
                    wrap_state <= WRAP_IDLE;
                end
            endcase
        end
    end

    fetchP fetchP_inst (
        .clk(clk),
        .start(core_fetchP_start),
        .busy(),
        .done(core_fetchP_done),
        .i(core_fetchP_i[4:0]),
        .j(core_fetchP_j[3:0]),
        .result(core_fetchP_result),
        .ram_ren(fetchP_ram_ren),
        .ram_addr(fetchP_ram_addr),
        .ram_rdata(fetchP_ram_rdata)
    );

    VisitedMatrixStore #(
        .GRID_WIDTH(GRID_WIDTH),
        .GRID_HEIGHT(GRID_HEIGHT)
    ) visited_store_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clear(store_clear),
        .getVisited_start(core_getVisited_start),
        .getVisited_i(core_getVisited_i),
        .getVisited_j(core_getVisited_j),
        .getVisited_done(core_getVisited_done),
        .getVisited_result(core_getVisited_result),
        .setVisited_start(core_setVisited_start),
        .setVisited_i(core_setVisited_i),
        .setVisited_j(core_setVisited_j),
        .setVisited_done(core_setVisited_done)
    );

    ResultMatrixStore #(
        .GRID_WIDTH(GRID_WIDTH),
        .GRID_HEIGHT(GRID_HEIGHT)
    ) result_store_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clear(store_clear),
        .storeR_start(core_storeR_start),
        .storeR_i(core_storeR_i),
        .storeR_j(core_storeR_j),
        .storeR_v(core_storeR_v),
        .storeR_done(core_storeR_done),
        .fetchR_start(fetchR_start),
        .fetchR_i(fetchR_i),
        .fetchR_j(fetchR_j),
        .fetchR_done(fetchR_done),
        .fetchR_result(fetchR_result)
    );

    FloodQueueStore #(
        .DEPTH(QUEUE_DEPTH)
    ) queue_store_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clear(store_clear),
        .addQueue_start(core_addQueue_start),
        .addQueue_i(core_addQueue_i),
        .addQueue_j(core_addQueue_j),
        .addQueue_d(core_addQueue_d),
        .addQueue_done(core_addQueue_done),
        .getQueueLen_start(core_getQueueLen_start),
        .getQueueLen_done(core_getQueueLen_done),
        .getQueueLen_result(core_getQueueLen_result),
        .popQueue_start(core_popQueue_start),
        .popQueue_done(core_popQueue_done),
        .popQueue_result(core_popQueue_result)
    );

    flooding_core flooding_core_inst (
        .clk(clk),
        .rst_n(inner_rst_n),
        .start(core_start),
        .busy(core_busy),
        .done(core_done),
        .grid_height(GRID_HEIGHT),
        .grid_width(GRID_WIDTH),
        .fetchP_start(core_fetchP_start),
        .fetchP_i(core_fetchP_i),
        .fetchP_j(core_fetchP_j),
        .fetchP_done(core_fetchP_done),
        .fetchP_result(core_fetchP_result),
        .getVisited_start(core_getVisited_start),
        .getVisited_i(core_getVisited_i),
        .getVisited_j(core_getVisited_j),
        .getVisited_done(core_getVisited_done),
        .getVisited_result(core_getVisited_result),
        .setVisited_start(core_setVisited_start),
        .setVisited_i(core_setVisited_i),
        .setVisited_j(core_setVisited_j),
        .setVisited_done(core_setVisited_done),
        .storeR_start(core_storeR_start),
        .storeR_i(core_storeR_i),
        .storeR_j(core_storeR_j),
        .storeR_v(core_storeR_v),
        .storeR_done(core_storeR_done),
        .addQueue_start(core_addQueue_start),
        .addQueue_i(core_addQueue_i),
        .addQueue_j(core_addQueue_j),
        .addQueue_d(core_addQueue_d),
        .addQueue_done(core_addQueue_done),
        .getQueueLen_start(core_getQueueLen_start),
        .getQueueLen_done(core_getQueueLen_done),
        .getQueueLen_result(core_getQueueLen_result),
        .popQueue_start(core_popQueue_start),
        .popQueue_done(core_popQueue_done),
        .popQueue_result(core_popQueue_result)
    );

endmodule
