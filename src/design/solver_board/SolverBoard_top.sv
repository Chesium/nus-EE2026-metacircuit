`timescale 1ns / 1ps

module SolverBoard_top #(
    parameter integer CLK_FREQ_HZ = 100_000_000,
    parameter integer UART_BAUD = 115200
) (
    input  wire        CLK100MHZ,
    input  wire        BTNC,
    input  wire        RsRx,
    output wire        RsTx,
    output wire [15:0] LED,
    output wire [7:0]  SEG,
    output wire [3:0]  AN
);

    localparam integer MAX_LINE_BYTES = 48;
    localparam integer MAX_ELEMS = 32;
    localparam integer MAX_NODES = 32;

    localparam [7:0] STATUS_OK = 8'h00;
    localparam [7:0] STATUS_PARSE = 8'h01;
    localparam [7:0] STATUS_RANGE = 8'h02;
    localparam [7:0] STATUS_CAPACITY = 8'h03;
    localparam [7:0] STATUS_TIMEOUT = 8'h04;
    localparam [7:0] STATUS_FP = 8'h05;

    localparam [3:0]
        S_IDLE = 4'd0,
        S_CLEAR_WAIT = 4'd1,
        S_WAIT_COMPONENT = 4'd2,
        S_CONVERT_WAIT = 4'd3,
        S_LOAD_WAIT = 4'd4,
        S_SOLVER_WAIT = 4'd5,
        S_TX_BEGIN_START = 4'd6,
        S_TX_BEGIN_WAIT = 4'd7,
        S_TX_NODE_FETCH = 4'd8,
        S_TX_NODE_START = 4'd9,
        S_TX_NODE_WAIT = 4'd10,
        S_TX_END_START = 4'd11,
        S_TX_END_WAIT = 4'd12,
        S_TX_ERROR_START = 4'd13,
        S_TX_ERROR_WAIT = 4'd14;

    reg [3:0] state = S_IDLE;

    wire rst_n = ~BTNC;

    wire [7:0] rx_byte;
    wire       rx_byte_valid;
    wire       line_valid;
    wire       line_overflow;
    wire [7:0] line_len;
    wire [MAX_LINE_BYTES*8-1:0] line_data;

    wire        snapshot_begin_valid;
    wire [15:0] snapshot_begin_frame;
    wire [7:0]  snapshot_begin_elem_count;
    wire [7:0]  snapshot_begin_node_count;
    wire        component_valid;
    wire [15:0] component_frame;
    wire [7:0]  component_idx;
    wire [7:0]  component_kind;
    wire [7:0]  component_n0;
    wire [7:0]  component_n1;
    wire [11:0] component_value_bcd;
    wire [7:0]  component_unit;
    wire        snapshot_end_valid;
    wire [15:0] snapshot_end_frame;
    wire [7:0]  snapshot_end_elem_count;
    wire [7:0]  snapshot_end_node_count;
    wire        parse_error;
    wire [7:0]  parse_error_code;
    wire [15:0] parse_error_arg;
    wire [15:0] parse_error_frame;

    reg        converter_start = 1'b0;
    reg [11:0] converter_value_bcd = 12'd0;
    reg [7:0]  converter_unit = 8'd0;
    wire       converter_done;
    wire       converter_invalid;
    wire [31:0] converter_value_fp32;

    reg        clear_netlist_start = 1'b0;
    wire       clear_netlist_done;
    reg        load_start = 1'b0;
    reg [15:0] load_idx = 16'd0;
    reg [7:0]  load_kind = 8'd0;
    reg [7:0]  load_n0 = 8'd0;
    reg [7:0]  load_n1 = 8'd0;
    reg [31:0] load_v0 = 32'd0;
    wire       load_done;

    reg        solver_start = 1'b0;
    reg [31:0] solver_elem_count = 32'd0;
    reg [31:0] solver_node_count = 32'd0;
    wire       solver_busy;
    wire       solver_done;
    wire       solver_fp_exception;

    reg        result_fetch_start = 1'b0;
    reg [15:0] result_fetch_idx = 16'd0;
    wire       result_fetch_done;
    wire [31:0] result_fetch_value;

    reg        tx_start = 1'b0;
    reg [1:0]  tx_mode = 2'd0;
    reg [15:0] tx_frame = 16'd0;
    reg [7:0]  tx_node_count = 8'd0;
    reg [7:0]  tx_status = 8'd0;
    reg [7:0]  tx_node_idx = 8'd0;
    reg [31:0] tx_node_value_bits = 32'd0;
    reg [7:0]  tx_error_code = 8'd0;
    reg [15:0] tx_error_arg = 16'd0;
    wire       tx_busy;
    wire       tx_done;

    reg [15:0] current_frame = 16'd0;
    reg [7:0]  current_elem_count = 8'd0;
    reg [7:0]  current_node_count = 8'd0;
    reg [7:0]  loaded_elem_count = 8'd0;
    reg [7:0]  current_status = STATUS_OK;
    reg [31:0] tx_result_value_latched = 32'd0;

    reg [7:0]  staged_idx = 8'd0;
    reg [7:0]  staged_kind = 8'd0;
    reg [7:0]  staged_n0 = 8'd0;
    reg [7:0]  staged_n1 = 8'd0;
    reg [11:0] staged_value_bcd = 12'd0;
    reg [7:0]  staged_unit = 8'd0;

    reg [19:0] rx_led_ctr = 20'd0;
    reg [19:0] tx_led_ctr = 20'd0;
    reg        error_latched = 1'b0;

    UartRx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD(UART_BAUD)
    ) uart_rx_inst (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .rx(RsRx),
        .data(rx_byte),
        .data_valid(rx_byte_valid)
    );

    UartLineAssembler #(
        .MAX_LINE_BYTES(MAX_LINE_BYTES)
    ) line_assembler_inst (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .byte_valid(rx_byte_valid),
        .byte_data(rx_byte),
        .line_valid(line_valid),
        .line_overflow(line_overflow),
        .line_len(line_len),
        .line_data(line_data)
    );

    UartPacketParser #(
        .MAX_LINE_BYTES(MAX_LINE_BYTES),
        .MAX_ELEMS(MAX_ELEMS),
        .MAX_NODES(MAX_NODES)
    ) parser_inst (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .line_valid(line_valid),
        .line_overflow(line_overflow),
        .line_len(line_len),
        .line_data(line_data),
        .snapshot_begin_valid(snapshot_begin_valid),
        .snapshot_begin_frame(snapshot_begin_frame),
        .snapshot_begin_elem_count(snapshot_begin_elem_count),
        .snapshot_begin_node_count(snapshot_begin_node_count),
        .component_valid(component_valid),
        .component_frame(component_frame),
        .component_idx(component_idx),
        .component_kind(component_kind),
        .component_n0(component_n0),
        .component_n1(component_n1),
        .component_value_bcd(component_value_bcd),
        .component_unit(component_unit),
        .snapshot_end_valid(snapshot_end_valid),
        .snapshot_end_frame(snapshot_end_frame),
        .snapshot_end_elem_count(snapshot_end_elem_count),
        .snapshot_end_node_count(snapshot_end_node_count),
        .parse_error(parse_error),
        .parse_error_code(parse_error_code),
        .parse_error_arg(parse_error_arg),
        .parse_error_frame(parse_error_frame)
    );

    BcdUnitToFp32Rom converter_inst (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .start(converter_start),
        .value_bcd(converter_value_bcd),
        .unit_code(converter_unit),
        .done(converter_done),
        .invalid(converter_invalid),
        .value_fp32(converter_value_fp32)
    );

    SolverDcPipeline #(
        .ELEM_COUNT(MAX_ELEMS),
        .DIM(MAX_NODES)
    ) pipeline_inst (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .clear_netlist_start(clear_netlist_start),
        .clear_netlist_done(clear_netlist_done),
        .load_start(load_start),
        .load_idx(load_idx),
        .load_kind(load_kind),
        .load_n0(load_n0),
        .load_n1(load_n1),
        .load_v0(load_v0),
        .load_done(load_done),
        .start(solver_start),
        .par_elem_n(solver_elem_count),
        .par_node_n(solver_node_count),
        .busy(solver_busy),
        .done(solver_done),
        .fp_exception(solver_fp_exception),
        .result_fetch_start(result_fetch_start),
        .result_fetch_idx(result_fetch_idx),
        .result_fetch_done(result_fetch_done),
        .result_fetch_value(result_fetch_value)
    );

    SolverUartLineTransmitter #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD(UART_BAUD)
    ) tx_line_inst (
        .clk(CLK100MHZ),
        .rst_n(rst_n),
        .start(tx_start),
        .mode(tx_mode),
        .frame(tx_frame),
        .node_count(tx_node_count),
        .status(tx_status),
        .node_idx(tx_node_idx),
        .node_value_bits(tx_node_value_bits),
        .error_code(tx_error_code),
        .error_arg(tx_error_arg),
        .tx(RsTx),
        .busy(tx_busy),
        .done(tx_done)
    );

    Hex7SegMux hex_mux_inst (
        .clk(CLK100MHZ),
        .hex_value({state, current_status[3:0], current_node_count[3:0], current_elem_count[3:0]}),
        .SEG(SEG),
        .AN(AN)
    );

    assign LED[0] = (rx_led_ctr != 20'd0);
    assign LED[1] = (state == S_CLEAR_WAIT) || (state == S_WAIT_COMPONENT) || (state == S_CONVERT_WAIT) || (state == S_LOAD_WAIT);
    assign LED[2] = (state == S_CONVERT_WAIT);
    assign LED[3] = 1'b0;
    assign LED[4] = (state == S_SOLVER_WAIT) || solver_busy;
    assign LED[5] = (tx_led_ctr != 20'd0) || tx_busy;
    assign LED[6] = error_latched;
    assign LED[7] = (state != S_IDLE);
    assign LED[15:8] = error_latched ? current_status : current_frame[7:0];

    always @(posedge CLK100MHZ) begin
        if (!rst_n) begin
            state <= S_IDLE;
            converter_start <= 1'b0;
            converter_value_bcd <= 12'd0;
            converter_unit <= 8'd0;
            clear_netlist_start <= 1'b0;
            load_start <= 1'b0;
            load_idx <= 16'd0;
            load_kind <= 8'd0;
            load_n0 <= 8'd0;
            load_n1 <= 8'd0;
            load_v0 <= 32'd0;
            solver_start <= 1'b0;
            solver_elem_count <= 32'd0;
            solver_node_count <= 32'd0;
            result_fetch_start <= 1'b0;
            result_fetch_idx <= 16'd0;
            tx_start <= 1'b0;
            tx_mode <= 2'd0;
            tx_frame <= 16'd0;
            tx_node_count <= 8'd0;
            tx_status <= STATUS_OK;
            tx_node_idx <= 8'd0;
            tx_node_value_bits <= 32'd0;
            tx_error_code <= 8'd0;
            tx_error_arg <= 16'd0;
            current_frame <= 16'd0;
            current_elem_count <= 8'd0;
            current_node_count <= 8'd0;
            loaded_elem_count <= 8'd0;
            current_status <= STATUS_OK;
            tx_result_value_latched <= 32'd0;
            staged_idx <= 8'd0;
            staged_kind <= 8'd0;
            staged_n0 <= 8'd0;
            staged_n1 <= 8'd0;
            staged_value_bcd <= 12'd0;
            staged_unit <= 8'd0;
            rx_led_ctr <= 20'd0;
            tx_led_ctr <= 20'd0;
            error_latched <= 1'b0;
        end else begin
            converter_start <= 1'b0;
            clear_netlist_start <= 1'b0;
            load_start <= 1'b0;
            solver_start <= 1'b0;
            result_fetch_start <= 1'b0;
            tx_start <= 1'b0;

            if (rx_byte_valid) begin
                rx_led_ctr <= 20'hFFFFF;
            end else if (rx_led_ctr != 20'd0) begin
                rx_led_ctr <= rx_led_ctr - 1'b1;
            end

            if (tx_busy || tx_start) begin
                tx_led_ctr <= 20'hFFFFF;
            end else if (tx_led_ctr != 20'd0) begin
                tx_led_ctr <= tx_led_ctr - 1'b1;
            end

            case (state)
                S_IDLE: begin
                    loaded_elem_count <= 8'd0;
                    error_latched <= 1'b0;
                    if (parse_error) begin
                        current_frame <= parse_error_frame;
                        current_status <= (parse_error_code == 8'h02) ? STATUS_RANGE : STATUS_PARSE;
                        tx_frame <= parse_error_frame;
                        tx_error_code <= (parse_error_code == 8'h02) ? STATUS_RANGE : STATUS_PARSE;
                        tx_error_arg <= parse_error_arg;
                        error_latched <= 1'b1;
                        state <= S_TX_ERROR_START;
                    end else if (snapshot_begin_valid) begin
                        current_frame <= snapshot_begin_frame;
                        current_elem_count <= snapshot_begin_elem_count;
                        current_node_count <= snapshot_begin_node_count;
                        current_status <= STATUS_OK;
                        loaded_elem_count <= 8'd0;
                        clear_netlist_start <= 1'b1;
                        state <= S_CLEAR_WAIT;
                    end
                end

                S_CLEAR_WAIT: begin
                    if (parse_error) begin
                        current_status <= (parse_error_code == 8'h02) ? STATUS_RANGE : STATUS_PARSE;
                        tx_frame <= parse_error_frame;
                        tx_error_code <= current_status;
                        tx_error_arg <= parse_error_arg;
                        error_latched <= 1'b1;
                        state <= S_TX_ERROR_START;
                    end else if (clear_netlist_done) begin
                        state <= S_WAIT_COMPONENT;
                    end
                end

                S_WAIT_COMPONENT: begin
                    if (parse_error) begin
                        current_status <= (parse_error_code == 8'h02) ? STATUS_RANGE : STATUS_PARSE;
                        tx_frame <= parse_error_frame;
                        tx_error_code <= current_status;
                        tx_error_arg <= parse_error_arg;
                        error_latched <= 1'b1;
                        state <= S_TX_ERROR_START;
                    end else if (component_valid) begin
                        staged_idx <= component_idx;
                        staged_kind <= component_kind;
                        staged_n0 <= component_n0;
                        staged_n1 <= component_n1;
                        staged_value_bcd <= component_value_bcd;
                        staged_unit <= component_unit;
                        converter_value_bcd <= component_value_bcd;
                        converter_unit <= component_unit;
                        converter_start <= 1'b1;
                        state <= S_CONVERT_WAIT;
                    end else if (snapshot_end_valid) begin
                        solver_elem_count <= {24'd0, snapshot_end_elem_count};
                        solver_node_count <= {24'd0, snapshot_end_node_count};
                        solver_start <= 1'b1;
                        state <= S_SOLVER_WAIT;
                    end
                end

                S_CONVERT_WAIT: begin
                    if (converter_done) begin
                        if (converter_invalid) begin
                            current_status <= STATUS_RANGE;
                            tx_frame <= current_frame;
                            tx_error_code <= STATUS_RANGE;
                            tx_error_arg <= {staged_unit[3:0], staged_value_bcd};
                            error_latched <= 1'b1;
                            state <= S_TX_ERROR_START;
                        end else begin
                            load_idx <= {8'd0, staged_idx};
                            load_kind <= staged_kind;
                            load_n0 <= staged_n0;
                            load_n1 <= staged_n1;
                            load_v0 <= converter_value_fp32;
                            load_start <= 1'b1;
                            state <= S_LOAD_WAIT;
                        end
                    end
                end

                S_LOAD_WAIT: begin
                    if (load_done) begin
                        loaded_elem_count <= loaded_elem_count + 1'b1;
                        state <= S_WAIT_COMPONENT;
                    end
                end

                S_SOLVER_WAIT: begin
                    if (solver_done) begin
                        current_status <= solver_fp_exception ? STATUS_FP : STATUS_OK;
                        tx_frame <= current_frame;
                        tx_node_count <= current_node_count;
                        tx_status <= solver_fp_exception ? STATUS_FP : STATUS_OK;
                        state <= S_TX_BEGIN_START;
                    end
                end

                S_TX_BEGIN_START: begin
                    tx_mode <= 2'd0;
                    tx_start <= 1'b1;
                    state <= S_TX_BEGIN_WAIT;
                end

                S_TX_BEGIN_WAIT: begin
                    if (tx_done) begin
                        if (current_node_count == 8'd0) begin
                            state <= S_TX_END_START;
                        end else begin
                            tx_node_idx <= 8'd0;
                            result_fetch_idx <= 16'd0;
                            result_fetch_start <= 1'b1;
                            state <= S_TX_NODE_FETCH;
                        end
                    end
                end

                S_TX_NODE_FETCH: begin
                    if (result_fetch_done) begin
                        tx_result_value_latched <= result_fetch_value;
                        state <= S_TX_NODE_START;
                    end
                end

                S_TX_NODE_START: begin
                    tx_mode <= 2'd1;
                    tx_node_value_bits <= tx_result_value_latched;
                    tx_start <= 1'b1;
                    state <= S_TX_NODE_WAIT;
                end

                S_TX_NODE_WAIT: begin
                    if (tx_done) begin
                        if ((tx_node_idx + 1'b1) >= current_node_count) begin
                            state <= S_TX_END_START;
                        end else begin
                            tx_node_idx <= tx_node_idx + 1'b1;
                            result_fetch_idx <= tx_node_idx + 1'b1;
                            result_fetch_start <= 1'b1;
                            state <= S_TX_NODE_FETCH;
                        end
                    end
                end

                S_TX_END_START: begin
                    tx_mode <= 2'd2;
                    tx_start <= 1'b1;
                    state <= S_TX_END_WAIT;
                end

                S_TX_END_WAIT: begin
                    if (tx_done) begin
                        state <= S_IDLE;
                    end
                end

                S_TX_ERROR_START: begin
                    tx_mode <= 2'd3;
                    tx_start <= 1'b1;
                    state <= S_TX_ERROR_WAIT;
                end

                S_TX_ERROR_WAIT: begin
                    if (tx_done) begin
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule
