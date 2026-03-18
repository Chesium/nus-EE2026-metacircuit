`timescale 1ns / 1ps

module lab_evaluation_top (
    input  wire        CLK100MHZ,  // 100MHz system CLK100MHZ
    input  wire        BTNC,
    // input  wire        BTNU,
    // input  wire        BTNL,
    // input  wire        BTNR,
    // input  wire        BTND,
    input  wire [15:0] SW,         // Switches
    output wire [15:0] LED,
    output wire [ 7:0] JC,         // PMOD OLED connections
    output wire [ 7:0] SEG,
    output wire [ 3:0] AN
);

  assign SEG = 8'b1111_1111;
  assign AN  = 4'b1111;

  // FEDC BA98 7654 3210
  localparam integer IsStation = 16'b0000_1001_0010_0000;
  localparam integer StartStation = 4'd3;

  reg activated = 0;

  wire started;

  // assign started = 1;
  assign started = SW[0] && SW[1] && SW[14] && SW[15];

  reg moving_dir = 0;  // 0:right, 1:left
  reg [3:0] pos = StartStation;

  assign LED = IsStation | (1'b1 << pos);

  wire nxt_moving_dir;
  wire [3:0] nxt_pos;

  assign nxt_moving_dir = (pos == 4'b0001 && moving_dir == 0)
        ? 1 : ((pos == 4'b1110 && moving_dir == 1) ? 0 : moving_dir);

  assign nxt_pos = moving_dir ? pos + 1 : pos - 1;

  wire clk_1500ms;

  ClockDividerMs #(
      .MS(1_500)
  ) clk_1500_ms (
      .CLK100MHZ(CLK100MHZ),
      .enable(started),
      .clk_out(clk_1500ms)
  );

  // ClockDivider #(
  //     .FREQ(1_000_000)
  // ) clk_1500_ms (
  //     .CLK100MHZ(CLK100MHZ),
  //     .enable(stared),
  //     .clk_out(clk_1500ms)
  // );

  reg [1:0] station_tick = 2'b00;  // 00 01 10 11
  always @(posedge clk_1500ms) begin
    // if (started) begin
    if(pos==1)
    activated <= 1;
      if (IsStation[pos]) begin
        if (station_tick == 2'b11) begin
          station_tick <= 2'b00;
          pos <= nxt_pos;
          moving_dir <= nxt_moving_dir;
        end else begin
          station_tick <= station_tick + 1;
        end
      end else begin
        pos <= nxt_pos;
        moving_dir <= nxt_moving_dir;
      end
    // end
  end

  /* OLED SECTION */

  ClockDivider #(
      .FREQ(6_250_000)
  ) clk_6_25mHz (
      .CLK100MHZ(CLK100MHZ),
      .clk_out  (clk6p25m)
  );

  wire frame_begin, sending_pixels, sample_pixel;


  wire [ 6:0] x_pos;
  wire [ 5:0] y_pos;
  wire [12:0] pixel_index;

  assign x_pos = pixel_index % 96;
  assign y_pos = pixel_index / 96;

  localparam integer ColorCyan = 16'b00000_111111_11111;
  localparam integer ColorGreen = 16'b00000_111111_00000;
  localparam integer ColorBlack = 16'b00000_000000_00000;
  localparam integer ColorWhite = 16'b11111_111111_11111;
  localparam integer ColorBlue = 16'b00000_000000_11111;

  wire in_margin;

  assign in_margin = x_pos < 12 || x_pos >= 96 - 12 || y_pos < 12 || y_pos >= 64 - 12;

  wire [15:0] margin_color;

  // assign margin_color = activated ? ColorCyan : ColorBlack;

    assign margin_color = activated ? (IsStation[pos] ? (

station_tick == 0 ? ColorGreen
: station_tick == 1 ? ColorBlack
: station_tick == 2 ? ColorWhite : ColorBlue


  ) : ColorCyan) : ColorBlack;

  reg [15:0] oled_data = ColorBlack;  // default green

  always @(*) begin
    oled_data = in_margin ? margin_color : ColorBlack;
  end

  

  Oled_Display oled_inst (
      .clk           (clk6p25m),
      .reset         (BTNC),            // can tie to pushbutton or 0
      .frame_begin   (frame_begin),
      .sending_pixels(sending_pixels),
      .sample_pixel  (sample_pixel),
      .pixel_index   (pixel_index),
      .pixel_data    (oled_data),
      .cs            (JC[0]),
      .sdin          (JC[1]),
      .sclk          (JC[3]),
      .d_cn          (JC[4]),
      .resn          (JC[5]),
      .vccen         (JC[6]),
      .pmoden        (JC[7])
  );

endmodule
