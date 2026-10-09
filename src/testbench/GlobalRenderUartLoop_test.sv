`timescale 1ns / 1ps

// RTL-4: frontend UART loop on the full GlobalRender_top with SW[5] = 1.
//
// The testbench is the host side of src/uart_link/README.md: an independent
// 115200-baud line decoder on RsTx and a line driver on RsRx (both timed in
// nanoseconds, not by the DUT's clock divider). It
//   1. captures the boot circuit's netlist snapshots (@NB/@NC/@NE),
//   2. replies to one of them with @VB/@VN/@VE and checks the voltage store,
//      the 7-segment value (both halves, via BTNU/BTND) and the LED status,
//   3. deletes the lower resistor through the mouse (golden scenario macros
//      "click_tool delete", "click_cell 3 6"; inputs change at line 10 of a
//      frame, D-008) and measures, in frames, edit -> netlist TX -> reply ->
//      voltage visible,
//   4. documents that a stale reply (frame id of an older snapshot) is still
//      accepted (spec: "should ignore late responses"; Q-009 in the report).
// Every RsTx/RsRx line is printed as "TXLINE"/"RXLINE" so golden/tools can
// re-check framing and checksums with src/uart_link/protocol.py.
//
// Frames are counted at VSYNC leading edges (framescope's frame boundaries):
// frame f is the interval after the f-th leading edge, and "visible in frame
// f" means a probe taken at the leading edge that ends frame f shows it.

module MouseCtl (
    input  wire        clk,
    input  wire        rst,
    output reg  [11:0] xpos = 12'd320,
    output reg  [11:0] ypos = 12'd240,
    output wire [3:0]  zpos,
    output reg         left = 1'b0,
    output reg         middle = 1'b0,
    output reg         right = 1'b0,
    output reg         new_event = 1'b0,
    input  wire [11:0] value,
    input  wire        setx,
    input  wire        sety,
    input  wire        setmax_x,
    input  wire        setmax_y,
    inout  wire        ps2_clk,
    inout  wire        ps2_data
);
  // Absolute position and buttons at the MouseCtl outputs (D-010), written by
  // the testbench through hierarchical references, like framescope's stub.
  assign zpos = 4'd0;
endmodule

module MouseDisplay (
    input  wire        pixel_clk,
    input  wire [11:0] xpos,
    input  wire [11:0] ypos,
    input  wire        mouse_left,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    output wire        enable_mouse_display_out,
    output wire [3:0]  red_out,
    output wire [3:0]  green_out,
    output wire [3:0]  blue_out
);
  assign enable_mouse_display_out = 1'b0;
  assign red_out = 4'd0;
  assign green_out = 4'd0;
  assign blue_out = 4'd0;
endmodule

module GlobalRenderUartLoop_test;
  localparam real BIT_NS = 1.0e9 / 115200.0;
  localparam real LINE_NS = 800.0 * 40.0;      // one VGA line at 25 MHz
  localparam integer MAX_LINES = 512;

  reg CLK100MHZ = 1'b0;
  always #5 CLK100MHZ = ~CLK100MHZ;

  reg [15:0] SW = 16'h0020;  // SW[5]: frontend UART client
  wire [15:0] LED;
  wire [7:0] SEG;
  wire [3:0] AN;
  reg BTNC = 1'b0, BTNU = 1'b0, BTNL = 1'b0, BTNR = 1'b0, BTND = 1'b0;
  wire [7:0] JC;
  wire [3:0] VGARED, VGABLUE, VGAGREEN;
  wire HSYNC, VSYNC;
  reg RsRx = 1'b1;
  wire RsTx;
  tri PS2CLK, PS2DATA;

  GlobalRender_top dut (
      .CLK100MHZ(CLK100MHZ), .SW(SW), .LED(LED), .SEG(SEG), .AN(AN),
      .BTNC(BTNC), .BTNU(BTNU), .BTNL(BTNL), .BTNR(BTNR), .BTND(BTND),
      .JC(JC), .VGARED(VGARED), .VGABLUE(VGABLUE), .VGAGREEN(VGAGREEN),
      .HSYNC(HSYNC), .VSYNC(VSYNC), .RsRx(RsRx), .RsTx(RsTx),
      .PS2CLK(PS2CLK), .PS2DATA(PS2DATA)
  );

  // ---------------------------------------------------------------- frames
  integer frame = -1;
  realtime frame_t0 = 0.0;
  always @(negedge VSYNC) begin
    frame = frame + 1;
    frame_t0 = $realtime;
  end

  function automatic integer line_now();
    line_now = $rtoi(($realtime - frame_t0) / LINE_NS);
  endfunction

  // ------------------------------------------------------ RsTx line decoder
  string  tx_text[MAX_LINES];
  integer tx_start_frame[MAX_LINES];
  integer tx_start_line[MAX_LINES];
  integer tx_end_frame[MAX_LINES];
  integer tx_end_line[MAX_LINES];
  integer tx_count = 0;
  integer tx_framing_errors = 0;
  string  tx_cur = "";
  integer cur_start_frame = 0, cur_start_line = 0;

  initial begin : tx_decoder
    reg [7:0] b;
    integer k;
    forever begin
      @(negedge RsTx);
      if (tx_cur.len() == 0) begin
        cur_start_frame = frame;
        cur_start_line = line_now();
      end
      #(BIT_NS * 1.5);
      for (k = 0; k < 8; k = k + 1) begin
        b[k] = RsTx;
        #(BIT_NS);
      end
      if (RsTx !== 1'b1) tx_framing_errors = tx_framing_errors + 1;
      if (b == 8'h0A) begin
        if (tx_count < MAX_LINES) begin
          tx_text[tx_count] = tx_cur;
          tx_start_frame[tx_count] = cur_start_frame;
          tx_start_line[tx_count] = cur_start_line;
          tx_end_frame[tx_count] = frame;
          tx_end_line[tx_count] = line_now();
          $display("TXLINE %0d frame=%0d line=%0d end_frame=%0d end_line=%0d %s", tx_count,
                   cur_start_frame, cur_start_line, frame, line_now(), tx_cur);
        end
        tx_count = tx_count + 1;
        tx_cur = "";
      end else if (b != 8'h0D) begin
        tx_cur = {tx_cur, string'(b)};
      end
    end
  end

  // Snapshot bookkeeping, filled by parse_tx(): the last complete snapshot.
  function automatic integer hex_val(input string s, input integer pos, input integer n);
    integer k, v;
    byte c;
    v = 0;
    for (k = 0; k < n; k = k + 1) begin
      c = s[pos + k];
      v = v * 16 + ((c >= "0" && c <= "9") ? (c - "0") : (c - "A" + 10));
    end
    hex_val = v;
  endfunction

  function automatic [7:0] xor_sum(input string payload);
    integer k;
    xor_sum = 8'h00;
    for (k = 0; k < payload.len(); k = k + 1) xor_sum = xor_sum ^ payload[k];
  endfunction

  // A line is "@<payload>*CC" with CC = XOR of the payload bytes.
  function automatic bit line_ok(input string s);
    integer n;
    n = s.len();
    line_ok = (n > 4) && (s[0] == "@") && (s[n - 3] == "*") &&
              (hex_val(s, n - 2, 2) == xor_sum(s.substr(1, n - 4)));
  endfunction

  // Index of the NE that completes the first snapshot starting at or after
  // line `from`, with matching NB/NC/NE frame ids and counts; -1 if none yet.
  function automatic integer find_snapshot(input integer from, output integer nb_idx);
    integer k, fid, elems, ncs;
    find_snapshot = -1;
    nb_idx = -1;
    fid = -1;
    for (k = from; k < tx_count && k < MAX_LINES; k = k + 1) begin
      if (tx_text[k].substr(0, 2) == "@NB") begin
        nb_idx = k;
        fid = hex_val(tx_text[k], 4, 4);
        elems = hex_val(tx_text[k], 9, 2);
        ncs = 0;
      end else if (fid >= 0 && tx_text[k].substr(0, 2) == "@NC" && hex_val(tx_text[k], 4, 4) == fid) begin
        ncs = ncs + 1;
      end else if (fid >= 0 && tx_text[k].substr(0, 2) == "@NE" && hex_val(tx_text[k], 4, 4) == fid &&
                   ncs == elems) begin
        return k;
      end
    end
  endfunction

  // ------------------------------------------------------ RsRx line driver
  integer rx_count = 0;
  task automatic send_byte(input [7:0] b);
    integer k;
    RsRx = 1'b0;
    #(BIT_NS);
    for (k = 0; k < 8; k = k + 1) begin
      RsRx = b[k];
      #(BIT_NS);
    end
    RsRx = 1'b1;
    #(BIT_NS);
  endtask

  task automatic send_line(input string payload);
    string line;
    string up;
    integer k;
    up = payload.toupper();  // the protocol wants uppercase hex; %X here prints lowercase
    line = $sformatf("@%s*%02X", up, xor_sum(up));
    line = line.toupper();
    $display("RXLINE %0d frame=%0d line=%0d %s", rx_count, frame, line_now(), line);
    rx_count = rx_count + 1;
    for (k = 0; k < line.len(); k = k + 1) send_byte(line[k]);
    send_byte(8'h0D);
    send_byte(8'h0A);
  endtask

  // Sent verbatim (no checksum computed), e.g. to inject a corrupted line.
  task automatic send_line_raw(input string line);
    integer k;
    $display("RXLINE %0d frame=%0d line=%0d %s", rx_count, frame, line_now(), line);
    rx_count = rx_count + 1;
    for (k = 0; k < line.len(); k = k + 1) send_byte(line[k]);
    send_byte(8'h0D);
    send_byte(8'h0A);
  endtask

  // @VB/@VN.../@VE for `nodes` nodes: node 0 = v0, nodes 1.. = v1.
  task automatic send_reply(input integer fid, input integer nodes, input [31:0] v0, input [31:0] v1);
    integer k;
    send_line($sformatf("VB,%04X,%02X,00", fid, nodes));
    for (k = 0; k < nodes; k = k + 1)
      send_line($sformatf("VN,%04X,%02X,%08X", fid, k, (k == 0) ? v0 : v1));
    send_line($sformatf("VE,%04X,%02X,00", fid, nodes));
  endtask

  // ------------------------------------------------------------ mouse
  task automatic set_mouse(input integer x, input integer y, input bit l);
    dut.mouse_ctrl_inst.xpos = x[11:0];
    dut.mouse_ctrl_inst.ypos = y[11:0];
    dut.mouse_ctrl_inst.left = l;
  endtask

  // Apply at line 10 of frame f (the vertical back porch, D-008).
  task automatic at_frame_line10(input integer f);
    wait (frame >= f);
    #(LINE_NS * 10.0);
  endtask

  task automatic wait_frames(input integer n);
    integer target;
    target = frame + n;
    wait (frame >= target);
  endtask

  // ------------------------------------------------------------ 7-segment
  function automatic [3:0] seg_to_hex(input [7:0] s);
    case (s)
      8'b1100_0000: seg_to_hex = 4'h0; 8'b1111_1001: seg_to_hex = 4'h1;
      8'b1010_0100: seg_to_hex = 4'h2; 8'b1011_0000: seg_to_hex = 4'h3;
      8'b1001_1001: seg_to_hex = 4'h4; 8'b1001_0010: seg_to_hex = 4'h5;
      8'b1000_0010: seg_to_hex = 4'h6; 8'b1111_1000: seg_to_hex = 4'h7;
      8'b1000_0000: seg_to_hex = 4'h8; 8'b1001_0000: seg_to_hex = 4'h9;
      8'b1000_1000: seg_to_hex = 4'hA; 8'b1000_0011: seg_to_hex = 4'hB;
      8'b1100_0110: seg_to_hex = 4'hC; 8'b1010_0001: seg_to_hex = 4'hD;
      8'b1000_0110: seg_to_hex = 4'hE; default: seg_to_hex = 4'hF;
    endcase
  endfunction

  // Read the four multiplexed digits off SEG/AN (one full refresh cycle).
  task automatic read_7seg(output [15:0] value);
    reg [3:0] seen;
    seen = 4'b0000;
    value = 16'h0000;
    while (seen != 4'b1111) begin
      @(posedge CLK100MHZ);
      #1;
      case (AN)
        4'b1110: begin value[3:0]   = seg_to_hex(SEG); seen[0] = 1'b1; end
        4'b1101: begin value[7:4]   = seg_to_hex(SEG); seen[1] = 1'b1; end
        4'b1011: begin value[11:8]  = seg_to_hex(SEG); seen[2] = 1'b1; end
        4'b0111: begin value[15:12] = seg_to_hex(SEG); seen[3] = 1'b1; end
        default: begin end
      endcase
    end
  endtask


  // ------------------------------------------------------- event tracing
  // Edges that the latency measurement needs, as "EVENT" lines.
  reg last_store_busy = 1'b0;
  reg [3:0] last_tx_state = 4'd0;
  reg [15:0] last_reply_frame = 16'd0;
  reg last_reply_valid = 1'b0;
  integer edit_frame = -1, edit_line = -1;
  integer reply_seen_frame = -1, reply_seen_line = -1;
  always @(posedge CLK100MHZ) begin
    if (dut.component_store_busy && !last_store_busy) begin
      $display("EVENT frame=%0d line=%0d component_store_busy", frame, line_now());
      if (edit_frame < 0 && frame > 0) begin
        edit_frame = frame;
        edit_line = line_now();
      end
    end
    last_store_busy <= dut.component_store_busy;
    if (dut.netlist_tx_state == 4'd1 && last_tx_state == 4'd0)
      $display("EVENT frame=%0d line=%0d extract_start snapshot_frame=%04h", frame, line_now(),
               dut.frontend_snapshot_frame);
    last_tx_state <= dut.netlist_tx_state;
    if (dut.frontend_reply_valid != last_reply_valid || dut.frontend_reply_frame != last_reply_frame) begin
      $display("EVENT frame=%0d line=%0d reply_valid=%0d reply_frame=%04h status=%02h nodes=%0d", frame,
               line_now(), dut.frontend_reply_valid, dut.frontend_reply_frame, dut.frontend_reply_status,
               dut.frontend_reply_node_count);
      reply_seen_frame = frame;
      reply_seen_line = line_now();
    end
    last_reply_valid <= dut.frontend_reply_valid;
    last_reply_frame <= dut.frontend_reply_frame;
  end

  // ------------------------------------------------------------ checks
  integer errors = 0;
  task automatic check(input bit cond, input string what);
    if (!cond) begin
      errors = errors + 1;
      $display("FAIL: %s", what);
    end else begin
      $display("ok: %s", what);
    end
  endtask

  function automatic string payload(input integer idx);
    payload = tx_text[idx].substr(1, tx_text[idx].len() - 4);
  endfunction

  // Wait until a complete snapshot starting at or after TX line `from` exists.
  task automatic wait_snapshot(input integer from, output integer nb_idx, output integer ne_idx);
    ne_idx = -1;
    while (ne_idx < 0) begin
      ne_idx = find_snapshot(from, nb_idx);
      if (ne_idx < 0) @(tx_count);
    end
  endtask

  function automatic [31:0] stored_voltage(input integer node);
    stored_voltage = dut.frontend_reply_active_bank ? dut.frontend_reply_ram1_inst.mem[node]
                                                     : dut.frontend_reply_ram0_inst.mem[node];
  endfunction

  task automatic wait_reply(input integer fid);
    integer guard;
    guard = frame + 4;
    while (!(dut.frontend_reply_valid && dut.frontend_reply_frame == fid[15:0]) && frame < guard)
      @(posedge CLK100MHZ);
  endtask

  task automatic expect_7seg(input [15:0] value, input string what);
    reg [15:0] shown;
    repeat (8) @(posedge CLK100MHZ);  // view RAM read + register
    read_7seg(shown);
    check(dut.hex_display_value == value && shown == value,
          $sformatf("%s: hex_display_value=%04h 7-seg=%04h (want %04h)", what, dut.hex_display_value, shown, value));
  endtask

  task automatic press_btn(input integer which);  // 0 U, 1 D, 2 L, 3 R
    case (which)
      0: BTNU = 1'b1;
      1: BTND = 1'b1;
      2: BTNL = 1'b1;
      default: BTNR = 1'b1;
    endcase
    repeat (4) @(posedge CLK100MHZ);
    {BTNU, BTND, BTNL, BTNR} = 4'b0000;
    repeat (4) @(posedge CLK100MHZ);
  endtask

  // ------------------------------------------------------------ main
  localparam [31:0] MINUS_10V = 32'hC1200000;  // IEEE-754 -10.0
  localparam [31:0] ZERO_V = 32'h00000000;
  localparam [31:0] PLUS_5V = 32'h40A00000;    // IEEE-754 5.0

  integer nb0, ne0, nb1, ne1, nb2, ne2, nbe, nee, k, fid_boot, fid_edit, n_input;
  integer tx_lines_before_edit, reply_end_frame, reply_end_line;
  string want[5];

  initial begin : watchdog
    wait (frame >= 40);
    $display("FAIL: watchdog at frame %0d", frame);
    $fatal(1, "GlobalRenderUartLoop_test timed out");
  end

  initial begin
    // ---- 1. Boot circuit: three consecutive snapshots, one per frame.
    wait_snapshot(0, nb0, ne0);
    wait_snapshot(ne0 + 1, nb1, ne1);
    wait_snapshot(ne1 + 1, nb2, ne2);
    fid_boot = hex_val(tx_text[nb0], 4, 4);
    check(fid_boot == 1, $sformatf("first snapshot frame id is 0001 (got %04h)", fid_boot));
    check(nb0 == 0 && nb1 == ne0 + 1 && nb2 == ne1 + 1, "snapshots are back to back, no other lines");
    check(hex_val(tx_text[nb1], 4, 4) == fid_boot + 1 && hex_val(tx_text[nb2], 4, 4) == fid_boot + 2,
          "frame id increments by one per snapshot");
    check(tx_start_frame[nb1] == tx_start_frame[nb0] + 1 && tx_start_frame[nb2] == tx_start_frame[nb1] + 1 &&
          tx_start_line[nb1] == tx_start_line[nb2] && tx_end_frame[ne1] == tx_start_frame[nb1],
          $sformatf("one snapshot per frame, NB at the same line (lines %0d/%0d/%0d)",
                    tx_start_line[nb0], tx_start_line[nb1], tx_start_line[nb2]));
    // Boot circuit (golden/src/core/bootCircuit.ts): 10 V source and two 100
    // ohm resistors between the grounded left rail and the right rail.
    // RTL-observed element order and terminal order; the golden netlist
    // (GM-8) decides whether they are right.
    want = '{$sformatf("NB,%04X,03,01", fid_boot),
             $sformatf("NC,%04X,00,03,FF,00,010,00", fid_boot),
             $sformatf("NC,%04X,01,01,FF,00,100,00", fid_boot),
             $sformatf("NC,%04X,02,01,FF,00,100,00", fid_boot),
             $sformatf("NE,%04X,03,01", fid_boot)};
    for (k = 0; k < 5; k = k + 1)
      check(payload(nb0 + k) == want[k].toupper(), $sformatf("boot line %0d: %s", k, tx_text[nb0 + k]));
    for (k = 0; k <= ne2; k = k + 1) check(line_ok(tx_text[k]), $sformatf("checksum %s", tx_text[k]));
    check(dut.frontend_reply_valid == 1'b0 && dut.hex_display_value == 16'h0000 && LED[7] == 1'b0,
          "no reply yet: reply_valid 0, 7-seg 0000");

    // ---- 2. Reply to the boot snapshot. src/uart_link's simulated solver
    // answers V(node 0) = -10 V for this netlist (V source n0 = ground).
    send_reply(fid_boot, 1, MINUS_10V, ZERO_V);
    wait_reply(fid_boot);
    check(dut.frontend_reply_valid && dut.frontend_reply_frame == fid_boot[15:0] &&
          dut.frontend_reply_status == 8'h00 && dut.frontend_reply_node_count == 8'd1,
          $sformatf("reply accepted: frame %04h status %02h nodes %0d", dut.frontend_reply_frame,
                    dut.frontend_reply_status, dut.frontend_reply_node_count));
    check(stored_voltage(0) == MINUS_10V, $sformatf("voltage store node 0 = %08h", stored_voltage(0)));
    check(LED[7] == 1'b1 && LED[15:8] == 8'h00 && LED[6] == 1'b0, $sformatf("LED = %04h", LED));
    expect_7seg(16'h0000, "node 0 lower half");
    press_btn(0);
    expect_7seg(16'hC120, "node 0 upper half (BTNU)");
    check(LED[5] == 1'b1, "LED[5] shows the upper half");

    // ---- 3. Edit: delete tool, then delete the right-rail wire at (5,5)
    // (golden macros "click_tool delete", "click_cell 5 5"). The press goes
    // in at line 10 of frame n_input.
    tx_lines_before_edit = tx_count;
    at_frame_line10(frame + 1); set_mouse(32, 318, 0);
    at_frame_line10(frame + 1); set_mouse(32, 318, 1);
    at_frame_line10(frame + 1); set_mouse(32, 318, 0);
    at_frame_line10(frame + 1); set_mouse(240, 240, 0);
    edit_frame = -1;
    at_frame_line10(frame + 1); set_mouse(240, 240, 1);
    n_input = frame;
    at_frame_line10(frame + 1); set_mouse(240, 240, 0);
    // First snapshot with the split rail: node count 02.
    nbe = -1;
    nee = -1;
    while (nee < 0) begin
      wait_snapshot(tx_lines_before_edit, nbe, nee);
      if (hex_val(tx_text[nbe], 12, 2) != 2) begin
        tx_lines_before_edit = nee + 1;
        nee = -1;
      end
    end
    fid_edit = hex_val(tx_text[nbe], 4, 4);
    want = '{$sformatf("NB,%04X,03,02", fid_edit),
             $sformatf("NC,%04X,00,03,FF,00,010,00", fid_edit),
             $sformatf("NC,%04X,01,01,FF,00,100,00", fid_edit),
             $sformatf("NC,%04X,02,01,FF,01,100,00", fid_edit),
             $sformatf("NE,%04X,03,02", fid_edit)};
    for (k = 0; k < 5; k = k + 1)
      check(payload(nbe + k) == want[k].toupper(), $sformatf("split-rail line %0d: %s", k, tx_text[nbe + k]));
    check(edit_frame == n_input + 1, $sformatf("edit lands in frame N+1 (N=%0d, got %0d)", n_input, edit_frame));
    check(tx_start_frame[nbe] == n_input + 1 && tx_end_frame[nee] == n_input + 1,
          $sformatf("new netlist sent in frame N+1 (NB frame %0d line %0d, NE frame %0d line %0d)",
                    tx_start_frame[nbe], tx_start_line[nbe], tx_end_frame[nee], tx_end_line[nee]));
    // Node 1 is the lower resistor's dangling terminal: 0 V.
    send_reply(fid_edit, 2, MINUS_10V, ZERO_V);
    reply_end_frame = frame;
    reply_end_line = line_now();
    wait_reply(fid_edit);
    check(dut.frontend_reply_valid && dut.frontend_reply_frame == fid_edit[15:0] &&
          dut.frontend_reply_node_count == 8'd2, $sformatf("split-rail reply accepted (frame %04h)", fid_edit));
    check(reply_seen_frame == n_input + 2, $sformatf("voltage visible in frame N+2 (got %0d)", reply_seen_frame));
    $display("LATENCY input_frame=N=%0d edit=N+%0d(line %0d) tx_start=N+%0d(line %0d) tx_end=N+%0d(line %0d) reply_end=N+%0d(line %0d) visible=N+%0d(line %0d)",
             n_input, edit_frame - n_input, edit_line, tx_start_frame[nbe] - n_input, tx_start_line[nbe],
             tx_end_frame[nee] - n_input, tx_end_line[nee], reply_end_frame - n_input, reply_end_line,
             reply_seen_frame - n_input, reply_seen_line);
    expect_7seg(16'hC120, "split rail: node 0 upper half");
    press_btn(3);
    check(LED[1:0] == 2'd1, "BTNR selects node 1");
    expect_7seg(16'h0000, "split rail: node 1 upper half");
    press_btn(3);
    check(LED[1:0] == 2'd1, "BTNR stops at the last node");
    press_btn(2);
    press_btn(1);
    expect_7seg(16'h0000, "node 0 lower half (BTNL, BTND)");

    // ---- 4. A corrupted line raises the reply status (83) and keeps the
    // stored voltages.
    send_line_raw("@VB,0000,01,00*00");
    repeat (8) @(posedge CLK100MHZ);
    check(dut.frontend_reply_status == 8'h83 && dut.frontend_reply_valid && LED[6] == 1'b1 &&
          stored_voltage(0) == MINUS_10V, $sformatf("bad checksum: status %02h, voltages kept", dut.frontend_reply_status));

    // ---- 5. Pinned current behaviour (Q-009): a reply for an old snapshot
    // (the boot frame id) is still accepted, although the spec says board F
    // "should ignore late responses whose frame no longer matches the newest
    // outstanding request".
    send_reply(fid_boot, 1, PLUS_5V, ZERO_V);
    wait_reply(fid_boot);
    check(dut.frontend_reply_frame == fid_boot[15:0] && stored_voltage(0) == PLUS_5V,
          $sformatf("stale reply (frame %04h) accepted [pinned, Q-009]", fid_boot));

    for (k = 0; k < tx_count && k < MAX_LINES; k = k + 1)
      if (!line_ok(tx_text[k])) check(1'b0, $sformatf("checksum %s", tx_text[k]));
    check(tx_framing_errors == 0, $sformatf("no RsTx framing errors (%0d)", tx_framing_errors));
    $display("SUMMARY frames=%0d tx_lines=%0d rx_lines=%0d errors=%0d", frame, tx_count, rx_count, errors);
    if (errors != 0) $fatal(1, "GlobalRenderUartLoop_test: %0d check(s) failed", errors);
    $display("GlobalRenderUartLoop_test passed");
    $finish;
  end
endmodule
