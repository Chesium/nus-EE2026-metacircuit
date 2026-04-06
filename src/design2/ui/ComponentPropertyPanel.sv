`timescale 1ns / 1ps

module ComponentPropertyPanel #(
    parameter integer PANEL_X = 0,
    parameter integer PANEL_Y = 0,
    parameter integer PANEL_W = 640,
    parameter integer PANEL_H = 64
)(
    input  wire        clk_sys,
    input  wire        rst,
    input  wire        clk_pixel,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    input  wire        video_on,
    input  wire        has_selection_sys,
    input  wire [5:0]  selected_comp_idx_sys,
    input  wire [39:0] selected_comp_data_sys,
    input  wire        has_selection_pix,
    input  wire [39:0] selected_comp_data_pix,
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    output reg         cmd_valid,
    output reg  [63:0] cmd_payload,
    output reg         panel_rendered,
    output reg  [11:0] panel_rgb
);

  import ComponentStorePkg::*;
  import MetaCommandPkg::*;

  reg btnU_d;
  reg btnD_d;
  reg btnR_d;
  reg btnC_d;

  wire btnU_rise = btnU && !btnU_d;
  wire btnD_rise = btnD && !btnD_d;
  wire btnR_rise = btnR && !btnR_d;
  wire btnC_rise = btnC && !btnC_d;

  wire [12:0] current_value = component_value(selected_comp_data_sys);

  always @(posedge clk_sys) begin
    if (rst) begin
      btnU_d <= 1'b0;
      btnD_d <= 1'b0;
      btnR_d <= 1'b0;
      btnC_d <= 1'b0;
      cmd_valid <= 1'b0;
      cmd_payload <= pack_command(CMD_NONE, 6'd0, 5'd0, 5'd0, 6'd0, 2'd0, 4'd0, 13'd0, 1'b0, 8'sd0, 8'sd0);
    end else begin
      btnU_d <= btnU;
      btnD_d <= btnD;
      btnR_d <= btnR;
      btnC_d <= btnC;
      cmd_valid <= 1'b0;
      cmd_payload <= pack_command(CMD_NONE, 6'd0, 5'd0, 5'd0, 6'd0, 2'd0, 4'd0, 13'd0, 1'b0, 8'sd0, 8'sd0);

      if (has_selection_sys) begin
        if (btnU_rise) begin
          cmd_valid <= 1'b1;
          cmd_payload <= pack_command(
              CMD_COMPONENT_UPDATE,
              selected_comp_idx_sys,
              5'd0,
              5'd0,
              6'd0,
              2'd0,
              component_type(selected_comp_data_sys),
              current_value + 13'd1,
              1'b0,
              8'sd0,
              8'sd0
          );
        end else if (btnD_rise && (current_value != 13'd0)) begin
          cmd_valid <= 1'b1;
          cmd_payload <= pack_command(
              CMD_COMPONENT_UPDATE,
              selected_comp_idx_sys,
              5'd0,
              5'd0,
              6'd0,
              2'd0,
              component_type(selected_comp_data_sys),
              current_value - 13'd1,
              1'b0,
              8'sd0,
              8'sd0
          );
        end else if (btnR_rise) begin
          cmd_valid <= 1'b1;
          cmd_payload <= pack_command(
              CMD_COMPONENT_ROTATE,
              selected_comp_idx_sys,
              5'd0,
              5'd0,
              6'd0,
              2'd0,
              component_type(selected_comp_data_sys),
              current_value,
              1'b0,
              8'sd0,
              8'sd0
          );
        end else if (btnC_rise) begin
          cmd_valid <= 1'b1;
          cmd_payload <= pack_command(
              CMD_COMPONENT_DELETE,
              selected_comp_idx_sys,
              5'd0,
              5'd0,
              6'd0,
              2'd0,
              component_type(selected_comp_data_sys),
              current_value,
              1'b0,
              8'sd0,
              8'sd0
          );
        end
      end
    end
  end

  wire in_panel = (hcount >= PANEL_X) && (hcount < PANEL_X + PANEL_W) &&
                  (vcount >= PANEL_Y) && (vcount < PANEL_Y + PANEL_H);
  wire is_border = in_panel && (
      (hcount == PANEL_X) || (hcount == PANEL_X + PANEL_W - 1) ||
      (vcount == PANEL_Y) || (vcount == PANEL_Y + PANEL_H - 1)
  );

  always @(posedge clk_pixel) begin
    panel_rendered <= 1'b0;
    panel_rgb <= 12'h111;
    if (video_on && in_panel) begin
      panel_rendered <= 1'b1;
      if (is_border) begin
        panel_rgb <= 12'hFFF;
      end else if (!has_selection_pix) begin
        panel_rgb <= 12'h223;
      end else begin
        case (component_type(selected_comp_data_pix))
          COMP_RESISTOR:  panel_rgb <= 12'h431;
          COMP_VOLTAGE:   panel_rgb <= 12'h134;
          COMP_CURRENT:   panel_rgb <= 12'h341;
          COMP_CAPACITOR: panel_rgb <= 12'h245;
          COMP_INDUCTOR:  panel_rgb <= 12'h352;
          default:        panel_rgb <= 12'h444;
        endcase
      end
    end
  end

endmodule
