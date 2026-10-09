`timescale 1ns / 1ps

// Checks that CircuitCanvas's registered cell data lines up with the pixel it is
// drawn at. x_pos/y_pos are driven like the VGA counter registers (they change on
// the clock edge), and at every canvas pixel the latched cell word and colour
// indices are compared, mid-cycle, with the RAM entries of the cell under that
// pixel. Misaligned data shows up at each cell's left column (dx = 0), which
// would otherwise draw the left neighbour's sprite.
module CircuitCanvas_left_edge_test ();

  wire done_vga, done_tight;
  wire [31:0] failures_vga, failures_tight;

  // The canvas as GlobalRender_top instantiates it, scanned with the 800-pixel VGA line.
  CircuitCanvasAlignmentCase #(
      .CanvasPosX(64), .CanvasPosY(64), .CanvasWidth(576), .CanvasHeight(288),
      .GridWidth(18), .GridHeight(16), .LineLength(800), .FrameLines(525)
  ) vga_case (
      .done(done_vga), .failures(failures_vga)
  );

  // A canvas at x = 0 that fills the whole line, so the fetch must wrap to the next row.
  CircuitCanvasAlignmentCase #(
      .CanvasPosX(0), .CanvasPosY(0), .CanvasWidth(400), .CanvasHeight(300),
      .GridWidth(16), .GridHeight(16), .LineLength(400), .FrameLines(300)
  ) tight_case (
      .done(done_tight), .failures(failures_tight)
  );

  initial begin
    wait (done_vga && done_tight);
    if (failures_vga + failures_tight == 0) begin
      $display("CircuitCanvas_left_edge_test passed.");
      $finish;
    end else begin
      $fatal(1, "CircuitCanvas_left_edge_test: %0d misaligned pixel(s).", failures_vga + failures_tight);
    end
  end

endmodule

module CircuitCanvasAlignmentCase #(
    parameter integer CanvasPosX = 0,
    parameter integer CanvasPosY = 0,
    parameter integer CanvasWidth = 400,
    parameter integer CanvasHeight = 300,
    parameter integer GridWidth = 16,
    parameter integer GridHeight = 16,
    parameter integer LineLength = 400,
    parameter integer FrameLines = 300
) (
    output reg        done = 1'b0,
    output reg [31:0] failures = 0
);

  localparam integer CellSize = 32;
  localparam integer CellCount = GridWidth * GridHeight;
  localparam integer AddrWidth = $clog2(CellCount);
  localparam integer DataWidth = 16;
  localparam integer MinPanX = CanvasWidth > GridWidth * CellSize ? 0 : CanvasWidth - GridWidth * CellSize;
  localparam integer MinPanY = CanvasHeight > GridHeight * CellSize ? 0 : CanvasHeight - GridHeight * CellSize;
  localparam [11:0] LastX = LineLength - 1;
  localparam [11:0] LastY = FrameLines - 1;

  reg clk_pixel = 1'b0;
  always #20 clk_pixel = ~clk_pixel;  // 25 MHz

  // VGA-style counters: they advance on the clock edge, like h_count_reg/v_count_reg.
  reg [11:0] x_pos = 0;
  reg [11:0] y_pos = 0;
  always @(posedge clk_pixel) begin
    if (x_pos == LastX) begin
      x_pos <= 0;
      y_pos <= (y_pos == LastY) ? 12'd0 : y_pos + 1;
    end else begin
      x_pos <= x_pos + 1;
    end
  end

  wire [11:0] rgb;
  wire rendered;
  wire [AddrWidth-1:0] data_addr;
  wire [DataWidth-1:0] incoming_data;
  wire [3:0] incoming_fg_color_idx;
  wire [3:0] incoming_bg_color_idx;

  SimpleRam #(.WordWidth(DataWidth), .WordCount(CellCount)) cell_ram (
      .clk(clk_pixel), .w_en(1'b0), .w_addr({AddrWidth{1'b0}}), .r_addr(data_addr),
      .d_in({DataWidth{1'b0}}), .d_out(incoming_data)
  );
  SimpleRam #(.WordWidth(4), .WordCount(CellCount)) fg_ram (
      .clk(clk_pixel), .w_en(1'b0), .w_addr({AddrWidth{1'b0}}), .r_addr(data_addr),
      .d_in(4'd0), .d_out(incoming_fg_color_idx)
  );
  SimpleRam #(.WordWidth(4), .WordCount(CellCount)) bg_ram (
      .clk(clk_pixel), .w_en(1'b0), .w_addr({AddrWidth{1'b0}}), .r_addr(data_addr),
      .d_in(4'd0), .d_out(incoming_bg_color_idx)
  );

  CircuitCanvas #(
      .CanvasPosX(CanvasPosX), .CanvasPosY(CanvasPosY),
      .CanvasWidth(CanvasWidth), .CanvasHeight(CanvasHeight),
      .CellSize(CellSize), .GridWidth(GridWidth), .GridHeight(GridHeight)
  ) dut (
      .clk_pixel(clk_pixel), .x_pos(x_pos), .y_pos(y_pos), .anim_phase(5'd0),
      .rgb(rgb), .rendered(rendered), .mouse_x_pos(12'd0), .mouse_y_pos(12'd0),
      .data_addr(data_addr), .incoming_data(incoming_data),
      .incoming_fg_color_idx(incoming_fg_color_idx), .incoming_bg_color_idx(incoming_bg_color_idx),
      .display_grid(1'b1), .mouse_left_click(1'b0),
      .grid_pos_x_out(), .grid_pos_y_out()
  );

  // Every cell gets a distinct word and neighbouring cells get distinct colours.
  function automatic [DataWidth-1:0] word_at(input integer addr);
    word_at = {addr[DataWidth-2:0], 1'b1};
  endfunction
  function automatic [3:0] fg_at(input integer addr);
    integer m;
    begin
      m = addr % 15;
      fg_at = m[3:0];
    end
  endfunction
  function automatic [3:0] bg_at(input integer addr);
    integer m;
    begin
      m = 14 - (addr % 15);
      bg_at = m[3:0];
    end
  endfunction

  reg checking = 1'b0;
  integer pan_x = 0;
  integer pan_y = 0;
  integer checked = 0;

  always @(negedge clk_pixel) begin
    if (checking && rendered) begin : check_pixel
      integer ax, ay, i, j, addr;
      reg [DataWidth-1:0] want_word;
      reg [3:0] want_fg, want_bg;
      ax = x_pos - CanvasPosX - pan_x;
      ay = y_pos - CanvasPosY - pan_y;
      i = ax / CellSize;
      j = ay / CellSize;
      addr = i + j * GridWidth;
      if (i < GridWidth && j < GridHeight) begin
        want_word = word_at(addr);
        want_fg = fg_at(addr);
        want_bg = bg_at(addr);
      end else begin
        want_word = 0;
        want_fg = 4'hF;
        want_bg = 4'h0;
      end
      checked = checked + 1;
      if (dut.cell_data !== want_word || dut.cell_fg_color_idx !== want_fg || dut.cell_bg_color_idx !== want_bg) begin
        if (failures < 10) begin
          $display("FAIL canvas@(%0d,%0d) pan=(%0d,%0d) pixel=(%0d,%0d) cell=(%0d,%0d) dx=%0d: data=%h fg=%h bg=%h, expected %h %h %h",
                   CanvasPosX, CanvasPosY, pan_x, pan_y, x_pos, y_pos, i, j, ax % CellSize,
                   dut.cell_data, dut.cell_fg_color_idx, dut.cell_bg_color_idx, want_word, want_fg, want_bg);
        end
        failures = failures + 1;
      end
    end
  end

  task automatic scan_frame;
    input integer px;
    input integer py;
    begin
      @(negedge clk_pixel);
      checking = 1'b0;
      pan_x = px;
      pan_y = py;
      dut.grid_pos_x = px;
      dut.grid_pos_y = py;
      repeat (LineLength) @(negedge clk_pixel);  // let the fetch pipeline refill
      checking = 1'b1;
      repeat (LineLength * FrameLines) @(negedge clk_pixel);
      checking = 1'b0;
    end
  endtask

  initial begin : run
    integer addr;
    for (addr = 0; addr < CellCount; addr = addr + 1) begin
      cell_ram.mem[addr] = word_at(addr);
      fg_ram.mem[addr] = fg_at(addr);
      bg_ram.mem[addr] = bg_at(addr);
    end

    scan_frame(0, 0);
    scan_frame(MinPanX < -8 ? -8 : MinPanX, MinPanY < -5 ? -5 : MinPanY);
    scan_frame(MinPanX < -31 ? -31 : MinPanX, MinPanY < -31 ? -31 : MinPanY);
    scan_frame(MinPanX, MinPanY);

    $display("canvas@(%0d,%0d): %0d pixels checked, %0d misaligned", CanvasPosX, CanvasPosY, checked, failures);
    done = 1'b1;
  end

endmodule
