`timescale 1ns / 1ps
// Default frozen bench; supplemental bench supplies its selected real DUT path.
`ifndef M5D
`define M5D GlobalRenderUartLoop_test.dut
`endif
module M5FrontendObserver(input wire clk);
    reg previous_busy = 1, checked_ready = 0;
    reg [8:0] previous_selected_addr=9'h1ff, older_selected_addr=9'h1ff;
    integer selected_read_checks=0;
    // Bound a fresh clear/rebuild under quiescence, not arbitrary dirty restarts.
    localparam integer REBUILD_BOUND=870;
    reg progress_active=0;
    integer progress_age=0, progress_completed=0, progress_max=0;
    // After the last accepted edit, finish at most one old rebuild and one
    // fresh rebuild. Repeated edits restart this deadline; no fairness claim
    // is made while edits continue forever.
    localparam integer RESTART_BOUND=2*REBUILD_BOUND+4;
    reg restart_active=0;
    integer restart_age=0, restart_completed=0, restart_max=0, restart_edits=0;
    wire edit_possible=`M5D.clear_canvas_active || `M5D.pending_pair_value_write ||
        `M5D.keyboard_edit_event || (`M5D.interaction_bg_cmd_valid &&
        `M5D.interaction_bg_cmd_write && `M5D.interaction_bg_cmd_ready);
    reg model_bank = 0, model_valid = 0, model_stage = 0;
    reg [15:0] model_frame = 0, stage_frame = 0;
    reg [7:0] model_nodes = 0, model_status = 0, stage_nodes = 0, stage_status = 0;
    reg [31:0] stage_values [0:31], active_values [0:31];
    reg [31:0] stage_seen = 0;
    reg [8:0] wanted_map [0:287];
    integer ready_checks = 0, bank_checks = 0, commits = 0, stage_writes = 0;
    integer stale_events = 0, aborts = 0, sys_clocks = 0;
    integer i, sprite, rotation, partner, step, count, pos_x, pos_y;
    reg [39:0] wanted_entry;
    wire inject_map = $test$plusargs("m5-inject-component-map");
    wire inject_bank = $test$plusargs("m5-inject-voltage-bank");
    wire inject_data = $test$plusargs("m5-inject-voltage-data");
    wire inject_stage = $test$plusargs("m5-inject-stage-state");
    wire inject_read = $test$plusargs("m5-inject-selected-read");
    wire inject_progress = $test$plusargs("m5-inject-rebuild-progress");
    wire inject_entry = $test$plusargs("m5-inject-component-entry");
    wire observed_bank = `M5D.frontend_reply_active_bank ^ (inject_bank && model_valid);
    reg check_active = 0;
    reg complete;

    always @(posedge clk) begin
        sys_clocks++;
        if (`M5D.init_cycles<1000) begin restart_active=0; restart_age=0; end
        else if (edit_possible) begin
            restart_active=1; restart_age=0; restart_edits++;
        end else if (restart_active) begin
            restart_age++;
            if (restart_age+($test$plusargs("m5-inject-restart-progress") ? RESTART_BOUND+1 : 0)>RESTART_BOUND)
                $fatal(1,"M5_FRONTEND_FAILURE dirty restart progress");
            if (!`M5D.component_store_busy) begin
                restart_completed++;
                if(restart_age>restart_max) restart_max=restart_age;
                restart_active=0;
            end
        end
        if (`M5D.init_cycles<1000 || edit_possible || `M5D.component_store_dirty) begin
            progress_active=0; progress_age=0;
        end else if (!progress_active && `M5D.component_index_map_clear_active &&
                     `M5D.component_index_map_clear_addr==0) begin
            progress_active=1; progress_age=0;
        end else if (progress_active) begin
            progress_age++;
            if (progress_age+(inject_progress ? REBUILD_BOUND+1 : 0)>REBUILD_BOUND)
                $fatal(1,"M5_FRONTEND_FAILURE quiescent component rebuild progress");
            if (!`M5D.component_store_busy) begin
                progress_completed++;
                if(progress_age>progress_max) progress_max=progress_age;
                progress_active=0;
            end
        end
        // Sample pre-NBA: outputs here reflect the previous clock's event.
        if ((`M5D.frontend_reply_stage_active ^ (inject_stage && ($test$plusargs("m5-abort-only") ? (aborts>0 && !model_stage) : model_stage))) !== model_stage)
            $fatal(1, "M5_FRONTEND_FAILURE staged reply cancellation");
        if (observed_bank !== model_bank || `M5D.frontend_reply_valid !== model_valid ||
            `M5D.frontend_reply_frame !== model_frame || `M5D.frontend_reply_node_count !== model_nodes ||
            `M5D.frontend_reply_status !== model_status)
            $fatal(1, "M5_FRONTEND_FAILURE voltage metadata atomicity");
        if (`M5D.frontend_reply_ram0_w_en && `M5D.frontend_reply_ram1_w_en)
            $fatal(1, "M5_FRONTEND_FAILURE simultaneous voltage bank writes");
        if (model_valid && ((`M5D.frontend_reply_ram0_w_en && !observed_bank) ||
                            (`M5D.frontend_reply_ram1_w_en && observed_bank)))
            $fatal(1, "M5_FRONTEND_FAILURE active voltage bank overwritten");
        if (`M5D.frontend_reply_stage_active && `M5D.frontend_reply_stage_bank == observed_bank)
            $fatal(1, "M5_FRONTEND_FAILURE staging uses active voltage bank");
        if (check_active && model_valid) begin
            for (i = 0; i < model_nodes; i++)
                if (((observed_bank ? `M5D.frontend_reply_ram1_inst.mem[i] :
                                      `M5D.frontend_reply_ram0_inst.mem[i]) ^
                     ((inject_data && i == 0) ? 32'd1 : 32'd0)) !== active_values[i])
                    $fatal(1, "M5_FRONTEND_FAILURE committed voltage data at node %0d", i);
            bank_checks++;
        end
        check_active = 0;

        // Independently reconstruct the component store from enabled primary
        // sprite cells, including geometry and row-major indices. Check the
        // actual advertised !busy boundary; do not add a hidden drain cycle.
        if (`M5D.init_cycles >= 1000 && !`M5D.component_store_busy &&
            (!checked_ready || previous_busy)) begin
            foreach (wanted_map[k]) wanted_map[k] = 9'h1ff;
            count = 0;
            for (i = 0; i < 288; i++) begin
                sprite = `M5D.canvas_shadow_data[i][6:1];
                if (`M5D.canvas_shadow_data[i][0] && sprite >= 5 && sprite <= 14 && sprite % 2 == 1) begin
                    rotation = `M5D.canvas_shadow_data[i][8:7];
                    case (rotation)
                        0: step = 1; 1: step = 18; 2: step = -1; 3: step = -18;
                    endcase
                    partner = i + step;
                    if (partner < 0 || partner >= 288 ||
                        ((rotation % 2 == 0) && partner / 18 != i / 18))
                        $fatal(1, "M5_FRONTEND_FAILURE component geometry bounds");
                    if (!`M5D.canvas_shadow_data[partner][0] ||
                        `M5D.canvas_shadow_data[partner][6:1] != sprite + 1 ||
                        `M5D.canvas_shadow_data[partner][8:7] != rotation)
                        $fatal(1, "M5_FRONTEND_FAILURE component geometry pairing");
                    wanted_map[i] = count; wanted_map[partner] = count;
                    pos_x = i % 18; pos_y = i / 18;
                    wanted_entry = {`M5D.value_unit_shadow_data[i], 9'(count), 4'(sprite),
                                    2'(rotation), `M5D.value_shadow_data[i], 4'(pos_y), 5'(pos_x)};
                    if ((`M5D.component_store_ram_inst.mem[count] ^ (inject_entry ? 40'd1 : 40'd0)) !== wanted_entry)
                        $fatal(1, "M5_FRONTEND_FAILURE component store entry %0d", count);
                    count++;
                end
            end
            if (`M5D.component_store_count != count)
                $fatal(1, "M5_FRONTEND_FAILURE component store count");
            for (i = 0; i < 288; i++) begin
                sprite = `M5D.canvas_shadow_data[i][6:1];
                if (`M5D.canvas_shadow_data[i][0] && sprite >= 5 && sprite <= 14 &&
                    sprite % 2 == 0 && wanted_map[i] == 9'h1ff)
                    $fatal(1, "M5_FRONTEND_FAILURE orphan component partner");
                if ((`M5D.component_index_map_ram_inst.mem[i] ^ ((inject_map && i == 0) ? 9'd1 : 9'd0)) !== wanted_map[i])
                    $fatal(1, "M5_FRONTEND_FAILURE component index map at %0d", i);
            end
            if (`M5D.has_selection_sys && `M5D.selected_cell_addr_sys<288 &&
                `M5D.selected_cell_addr_sys==previous_selected_addr &&
                `M5D.selected_cell_addr_sys==older_selected_addr) begin
                if ((`M5D.selected_component_index_map_data ^ (inject_read ? 9'd1 : 9'd0)) !==
                    wanted_map[`M5D.selected_cell_addr_sys])
                    $fatal(1,"M5_FRONTEND_FAILURE selected index synchronous read");
                selected_read_checks++;
            end
            ready_checks++; checked_ready = 1;
        end
        previous_busy = `M5D.component_store_busy;
        older_selected_addr=previous_selected_addr;
        previous_selected_addr=`M5D.selected_cell_addr_sys;
        if (`M5D.component_store_w_en && `M5D.component_store_w_addr >= 288)
            $fatal(1, "M5_FRONTEND_FAILURE component write address bounds");
        if (`M5D.component_index_map_w_en && `M5D.component_index_map_w_addr >= 288)
            $fatal(1, "M5_FRONTEND_FAILURE index write address bounds");

        // Independent packet-level acceptance model. Parser checksums/framing
        // remain the frozen bench/protocol.py's responsibility.
        if (!`M5D.frontend_uart_client_enable) begin
            model_stage = 0; model_valid = 0; model_bank = 0;
            model_frame = 0; model_nodes = 0; model_status = 0;
        end else begin
            if (`M5D.frontend_reply_parse_error) begin
                if (model_stage) aborts++;
                model_stage = 0; model_status = 8'h83; check_active = 1;
            end
            if (`M5D.frontend_error_packet_valid) begin
                if (model_stage) aborts++;
                model_stage = 0; check_active = 1;
                if (`M5D.frontend_snapshot_id_valid && `M5D.frontend_error_packet_frame == `M5D.frontend_snapshot_frame) begin
                    model_valid = 0; model_frame = `M5D.frontend_error_packet_frame;
                    model_status = `M5D.frontend_error_packet_code;
                end else stale_events++;
            end
            if (`M5D.frontend_voltage_begin_valid) begin
                if (model_stage) aborts++;
                check_active = 1;
                if (`M5D.frontend_snapshot_id_valid && `M5D.frontend_voltage_begin_frame == `M5D.frontend_snapshot_frame) begin
                    model_stage = 1; stage_frame = `M5D.frontend_voltage_begin_frame;
                    stage_nodes = `M5D.frontend_voltage_begin_node_count;
                    stage_status = `M5D.frontend_voltage_begin_status; stage_seen = 0;
                end else begin model_stage = 0; stale_events++; end
            end
            if (model_stage && `M5D.frontend_voltage_node_valid && `M5D.frontend_voltage_node_frame == stage_frame) begin
                if (`M5D.frontend_voltage_node_idx >= stage_nodes || `M5D.frontend_voltage_node_idx >= 32 ||
                    stage_seen[`M5D.frontend_voltage_node_idx])
                    $fatal(1, "M5_FRONTEND_FAILURE duplicate/out-of-range staged node");
                stage_values[`M5D.frontend_voltage_node_idx] = `M5D.frontend_voltage_node_value_bits;
                stage_seen[`M5D.frontend_voltage_node_idx] = 1; stage_writes++; check_active = 1;
            end
            if (model_stage && `M5D.frontend_voltage_end_valid) begin
                complete = `M5D.frontend_voltage_end_frame == stage_frame &&
                           `M5D.frontend_voltage_end_node_count == stage_nodes &&
                           `M5D.frontend_voltage_end_status == stage_status;
                for (i = 0; i < stage_nodes; i++) if (!stage_seen[i]) complete = 0;
                model_stage = 0; check_active = 1;
                if (complete && `M5D.frontend_snapshot_id_valid && stage_frame == `M5D.frontend_snapshot_frame) begin
                    model_bank = !model_bank; model_valid = 1; model_frame = stage_frame;
                    model_nodes = stage_nodes; model_status = stage_status;
                    for (i = 0; i < stage_nodes; i++) active_values[i] = stage_values[i];
                    commits++;
                end else if (complete) stale_events++;
                else begin model_status = 8'h83; aborts++; end
            end
        end
    end
    final $display("M5_FRONTEND_PROGRESS completed=%0d max_cycles=%0d bound=%0d selected_read_checks=%0d",
                   progress_completed,progress_max,REBUILD_BOUND,selected_read_checks);
    final $display("M5_FRONTEND_RESTART completed=%0d max_cycles=%0d bound=%0d edit_clocks=%0d",
                   restart_completed,restart_max,RESTART_BOUND,restart_edits);
    final $display("M5_FRONTEND_OBSERVER ready_checks=%0d bank_checks=%0d commits=%0d stage_writes=%0d stale_events=%0d aborts=%0d sys_clocks=%0d",
                   ready_checks, bank_checks, commits, stage_writes, stale_events, aborts, sys_clocks);
endmodule
bind GlobalRender_top M5FrontendObserver m5_frontend (.clk(CLK100MHZ));
`undef M5D

module M5FloodQueueObserver #(
    parameter integer Depth=256, LenWidth=16, PtrWidth=8
)(input wire clk, rst_n, clear, do_add, do_pop,
  input wire [LenWidth-1:0] count, input wire [PtrWidth-1:0] head, tail);
    integer clocks=0, adds=0, pops=0, expected_count=0;
    reg known=0;
    wire inject=$test$plusargs("m5-inject-queue-count");
    always @(posedge clk) begin
        clocks++;
        if (!rst_n || clear) begin expected_count=0; known=1; end
        else begin
            if (known && count != expected_count)
                $fatal(1, "M5_FRONTEND_FAILURE flood queue count conservation");
            if ((count + (inject ? Depth+1 : 0)) > Depth || head >= Depth || tail >= Depth)
                $fatal(1, "M5_FRONTEND_FAILURE flood queue bounds");
            if (do_add) adds++;
            if (do_pop) pops++;
            expected_count=count + (do_add ? 1 : 0) - (do_pop ? 1 : 0);
        end
    end
    final $display("M5_FRONTEND_QUEUE depth=%0d clocks=%0d adds=%0d pops=%0d",Depth,clocks,adds,pops);
endmodule
bind FloodQueueStore M5FloodQueueObserver #(.Depth(DEPTH),.LenWidth(LEN_WIDTH),.PtrWidth(PTR_WIDTH))
    m5_queue(.clk(clk),.rst_n(rst_n),.clear(clear),.do_add(do_add),.do_pop(do_pop),.count(count),.head(head_ptr),.tail(tail_ptr));
