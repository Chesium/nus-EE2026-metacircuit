`timescale 1ns / 1ps
// Continuous protocol checks, independent of controller/guard FSM encodings.
// The existing directed bench supplies delayed replies and memory backpressure.
module M5RequestInvariant #(
    parameter string Name = "request"
) (
    input wire clk, reset, valid, write, ready,
    input wire [8:0] addr,
    input wire [15:0] wdata
);
    reg stalled = 0, previous_write = 0;
    reg [8:0] previous_addr = 0;
    reg [15:0] previous_data = 0;
    integer cycles = 0, stalled_reads = 0, stalled_writes = 0;
    integer accepted_reads = 0, accepted_writes = 0;
    wire inject = $test$plusargs("m5-inject-request-corruption") && Name == "guard.background";
    wire [8:0] observed_addr = addr ^ (inject ? (cycles & 1) : 0);
    always @(posedge clk) begin
        cycles <= cycles + 1;
        if (reset) stalled <= 0;
        else begin
            if (stalled && (!valid || write !== previous_write || observed_addr !== previous_addr ||
                            (previous_write && wdata !== previous_data)))
                $fatal(1, "M5_INVARIANT_FAILURE %s stalled request changed", Name);
            if (valid && addr >= 288)
                $fatal(1, "M5_INVARIANT_FAILURE %s request outside logical memory", Name);
            if (valid && !ready) begin
                if (write) stalled_writes <= stalled_writes + 1;
                else stalled_reads <= stalled_reads + 1;
            end
            if (valid && ready) begin
                if (write) accepted_writes <= accepted_writes + 1;
                else accepted_reads <= accepted_reads + 1;
            end
            stalled <= valid && !ready;
            previous_write <= write;
            previous_addr <= observed_addr;
            previous_data <= wdata;
        end
    end
    final begin
        $display("M5_INVARIANT_CHANNEL %s stalled_reads=%0d stalled_writes=%0d accepted_reads=%0d accepted_writes=%0d",
                 Name, stalled_reads, stalled_writes, accepted_reads, accepted_writes);
    end
endmodule

bind CanvasCommandGuard M5RequestInvariant #(.Name("guard.background")) m5_background (
    .clk(clk), .reset(reset), .valid(bg_cmd_valid), .write(bg_cmd_write),
    .ready(bg_cmd_ready), .addr(bg_cmd_addr), .wdata(bg_cmd_wdata));
bind InteractionController M5RequestInvariant #(.Name("controller.request")) m5_controller (
    .clk(clk), .reset(reset), .valid(bg_cmd_valid), .write(bg_cmd_write),
    .ready(bg_cmd_ready), .addr(bg_cmd_addr), .wdata(bg_cmd_wdata));

// A separate top keeps the frozen M1 directed bench unchanged. Expected write
// events and the full settled memory image are specified before each action.
module M5CanvasInvariants_test;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1, tick = 0, left = 0, allow_memory = 1;
    reg [3:0] mode = 15;
    reg [11:0] x = 320, y = 240;
    wire raw_valid, raw_write, raw_ready, raw_response, done, dropped;
    wire [8:0] raw_addr;
    wire [15:0] raw_word, raw_response_word;
    wire valid, write, idle, value_read, copy_value;
    wire [8:0] addr, value_addr;
    wire [15:0] word;
    reg response = 0;
    reg [15:0] response_word = 0, pending_word = 0;
    reg [15:0] cells [0:287], expected_cells [0:287];
    reg [8:0] expected_addr [0:127];
    reg [15:0] expected_word [0:127];
    integer cycles = 0, response_delay = 1, reply_countdown = 0;
    integer expected_count = 0, committed_count = 0, settled_checks = 0;
    integer read_accepts = 0, replies = 0, max_progress = 0;
    integer directed_read_stall = 0, directed_write_stall = 0;
    wire ready = allow_memory && cycles % 7 != 0;
    wire corrupt_commit = $test$plusargs("m5-inject-commit-corruption");
    wire corrupt_map = $test$plusargs("m5-inject-map-corruption");
    wire suppress_reply = $test$plusargs("m5-inject-reply-loss");
    InteractionController #(.CanvasPosX(64), .CanvasPosY(64), .CanvasWidth(576),
        .CanvasHeight(288), .GridWidth(18), .GridHeight(16), .RotateFramesPerStep(3)) controller (
        .clk(clk), .reset(reset), .frame_start_pulse(tick), .mode_select(mode),
        .mouse_x(x), .mouse_y(y), .mouse_left(left), .mouse_middle(1'b0), .mouse_right(1'b0),
        .grid_pos_x(13'sd0), .grid_pos_y(13'sd0), .bg_cmd_ready(raw_ready),
        .bg_rsp_valid(raw_response), .bg_rsp_rdata(raw_response_word),
        .bg_cmd_valid(raw_valid), .bg_cmd_write(raw_write), .bg_cmd_addr(raw_addr),
        .bg_cmd_wdata(raw_word), .frame_done(done), .frame_drop_flag(dropped));
    CanvasCommandGuard guard (
        .clk(clk), .reset(reset), .mode_select(mode), .controller_done(done),
        .cmd_valid(raw_valid), .cmd_write(raw_write), .cmd_addr(raw_addr), .cmd_wdata(raw_word),
        .cmd_ready(raw_ready), .rsp_valid(raw_response), .rsp_rdata(raw_response_word),
        .bg_cmd_valid(valid), .bg_cmd_write(write), .bg_cmd_addr(addr), .bg_cmd_wdata(word),
        .bg_cmd_ready(ready), .bg_rsp_valid(response), .bg_rsp_rdata(response_word), .idle(idle),
        .value_read_en(value_read), .value_read_addr(value_addr), .copy_value(copy_value));

    // One outstanding read, exactly one reply. The memory samples data at read
    // acceptance; latency counts rising edges before its response is visible.
    always @(posedge clk) begin
        cycles <= cycles + 1;
        response <= 0;
        if (!reset) begin
            if (reply_countdown > 0) begin
                reply_countdown <= reply_countdown - 1;
                if (reply_countdown == 1 && !suppress_reply) begin
                    response <= 1;
                    response_word <= pending_word;
                    replies <= replies + 1;
                end
            end
            if (valid && ready) begin
                if (write) begin
                    if (committed_count >= expected_count || addr !== expected_addr[committed_count] ||
                        (word ^ (corrupt_commit ? 16'h0002 : 16'h0000)) !== expected_word[committed_count])
                        $fatal(1, "M5_INVARIANT_FAILURE commit sequence mismatch at %0d", committed_count);
                    cells[addr] <= word;
                    expected_cells[expected_addr[committed_count]] <= expected_word[committed_count];
                    committed_count <= committed_count + 1;
                end else begin
                    if (reply_countdown != 0 || response)
                        $fatal(1, "M5_INVARIANT_FAILURE multiple outstanding reads");
                    pending_word <= cells[addr];
                    reply_countdown <= response_delay;
                    read_accepts <= read_accepts + 1;
                end
            end
            if (copy_value && valid && ready && (!write || !value_read || value_addr != 19))
                $fatal(1, "M5_INVARIANT_FAILURE rotation value source mismatch");
        end
    end

    task automatic expect_write(input integer at, input reg [15:0] data);
        begin
            expected_addr[expected_count] = at;
            expected_word[expected_count] = data;
            expected_count++;
        end
    endtask
    task automatic start_frame(input integer col, input integer row, input bit held);
        begin
            @(negedge clk);
            x = 64 + col * 32 + 16;
            y = 64 + row * 32 + 16;
            left = held; tick = 1;
            @(negedge clk); tick = 0;
        end
    endtask
    task automatic settle(input bit require_all = 1);
        integer budget, i, sprite, partner, rotation, step;
        begin
            // Derived conservative schedule bound, not an arbitrary-stall claim:
            // 64 nonreply clocks plus <=4 read-response latencies. Includes
            // pipeline stages and the two-edit overlap (4 validation reads),
            // buffered writes and %7 backpressure. The runner reports this as
            // a directed simulation watchdog, not a proven architectural bound.
            budget = 0;
            repeat (4) begin @(negedge clk); budget++; end
            while (!(done && idle) && budget < 64 + 4 * response_delay) begin
                @(negedge clk); budget++;
            end
            if (!(done && idle) || dropped || reply_countdown || response)
                $fatal(1, "M5_INVARIANT_FAILURE bounded progress/reply drain");
            if (budget > max_progress) max_progress = budget;
            if (require_all && committed_count != expected_count)
                $fatal(1, "M5_INVARIANT_FAILURE lost committed command");
            for (i = 0; i < 288; i++) begin
                if ((cells[i] ^ ((corrupt_map && i == 287) ? 16'h0001 : 16'h0000)) !== expected_cells[i])
                    $fatal(1, "M5_INVARIANT_FAILURE settled map mismatch at %0d", i);
                sprite = cells[i][6:1];
                if (cells[i][0] && sprite >= 5 && sprite <= 14) begin
                    rotation = cells[i][8:7];
                    case (rotation)
                        0: step = 1; 1: step = 18; 2: step = -1; 3: step = -18;
                    endcase
                    partner = i + ((sprite % 2) ? step : -step);
                    if (partner < 0 || partner >= 288 ||
                        ((rotation % 2 == 0) && partner / 18 != i / 18))
                        $fatal(1, "M5_INVARIANT_FAILURE component partner bounds");
                    if (!cells[partner][0] || cells[partner][8:7] != rotation ||
                        cells[partner][6:1] != sprite + ((sprite % 2) ? 1 : -1))
                        $fatal(1, "M5_INVARIANT_FAILURE component pair disagreement");
                end
            end
            settled_checks++;
        end
    endtask
    task automatic sample(input integer col, input integer row, input bit held);
        begin start_frame(col, row, held); settle(); end
    endtask
    task automatic click(input integer col, input integer row);
        begin start_frame(col, row, 0); settle(0); sample(col, row, 1); sample(col, row, 0); end
    endtask

    reg held_background_write = 0;
    initial begin
        wait (!reset);
        // bg write becomes visible after a rising edge. Detect it at the next
        // falling edge, before the memory can accept it on a rising edge.
        while (!(valid && write)) @(negedge clk);
        allow_memory = 0;
        repeat (12) @(negedge clk);
        held_background_write = 1;
        allow_memory = 1;
    end
    integer budget;
    initial begin
        if ($value$plusargs("m5-response-delay=%d", response_delay)) begin end
        if (response_delay < 1 || response_delay > 9) $fatal(1, "unsupported response delay");
        foreach (cells[i]) begin cells[i] = 0; expected_cells[i] = 0; end
        repeat (3) @(negedge clk); reset = 0;
        mode = 4; expect_write(19, 16'h000b); expect_write(20, 16'h000d); click(1, 1);
        click(0, 1); click(2, 1); // rejected entire edits, no expected writes
        mode = 0; click(1, 1); // rejected component overwrite
        expect_write(18, 1); sample(0, 1, 1);
        expect_write(36, 1); sample(0, 2, 1); sample(0, 2, 0);

        // Hold an actual controller read through the real guard/memory path.
        mode = 7; sample(2, 1, 0); allow_memory = 0;
        expect_write(19, 16'h008b); expect_write(37, 16'h008d); expect_write(20, 0);
        start_frame(2, 1, 1);
        repeat (20) begin
            @(negedge clk);
            if (raw_valid && !raw_write && !raw_ready) directed_read_stall++;
        end
        if (!raw_valid || raw_write || raw_ready || directed_read_stall == 0)
            $fatal(1, "M5_INVARIANT_FAILURE missing directed controller read stall");
        allow_memory = 1; settle(); sample(2, 1, 0);
        click(1, 1); // blocked rotation: partner contains wire
        mode = 8; expect_write(19, 0); expect_write(37, 0); click(1, 2);

        // Two same-mode frames: issue the second only after controller_done,
        // while the guard is validating the first with memory held. This
        // creates real upstream WRITE backpressure without signal forcing.
        mode = 4; sample(5, 1, 0); allow_memory = 0;
        expect_write(23, 16'h000b); expect_write(24, 16'h000d);
        start_frame(5, 1, 1);
        budget = 0;
        while (!(done && !idle && valid && !write) && budget < 32) begin
            @(negedge clk); budget++;
        end
        if (budget == 32) $fatal(1, "M5_INVARIANT_FAILURE overlap setup did not finish controller");
        start_frame(8, 1, 0); // release frame; no command
        repeat (8) @(negedge clk);
        if (!done) $fatal(1, "M5_INVARIANT_FAILURE release frame incomplete");
        expect_write(26, 16'h000b); expect_write(27, 16'h000d);
        start_frame(8, 1, 1);
        repeat (20) begin
            @(negedge clk);
            if (raw_valid && raw_write && !raw_ready) directed_write_stall++;
        end
        if (!raw_valid || !raw_write || raw_ready || directed_write_stall == 0)
            $fatal(1, "M5_INVARIANT_FAILURE missing directed controller write stall");
        allow_memory = 1; settle(); sample(8, 1, 0);

        mode = 0; expect_write(57, 1); click(3, 3);
        mode = 7; expect_write(57, 16'h0081); click(3, 3);
        mode = 0; click(3, 3); // same sprite preserves rotated word
        mode = 11; expect_write(57, 16'h001f); click(3, 3);
        mode = 0; sample(-1, 2, 1); sample(9, 2, 1); sample(9, 2, 0);
        if (!held_background_write) $fatal(1, "M5_INVARIANT_FAILURE missing background write hold");
        if (read_accepts != replies) $fatal(1, "M5_INVARIANT_FAILURE read/reply conservation");
        $display("M5_INVARIANT_SCENARIO settled_checks=%0d commits=%0d reads=%0d replies=%0d max_progress=%0d directed_read_stall=%0d directed_write_stall=%0d response_delay=%0d",
                 settled_checks, committed_count, read_accepts, replies, max_progress,
                 directed_read_stall, directed_write_stall, response_delay);
        $display("M5CanvasInvariants_test passed."); $finish;
    end
endmodule

// Local guard storage bounds. These checks intentionally depend on the audited
// guard encoding; they do not imply anything about queues elsewhere in the chip.
module M5GuardBounds(input wire clk, reset, input wire [1:0] state, count, index);
    always @(posedge clk) if (!reset) begin
        if (count > 3 || (state != 0 && (count == 0 || index >= count)))
            $fatal(1, "M5_INVARIANT_FAILURE guard queue bounds");
    end
endmodule
bind CanvasCommandGuard M5GuardBounds m5_bounds (.clk(clk), .reset(reset), .state(state), .count(count), .index(index));
