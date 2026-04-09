`timescale 1ns / 1ps

module ComponentProjector (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    output reg         busy,
    output reg         done,

    output reg         cell_req_valid,
    output reg         cell_req_write,
    output reg  [9:0]  cell_req_addr,
    output reg  [15:0] cell_req_wdata,
    input  wire        cell_rsp_valid,
    input  wire [15:0] cell_rsp_rdata,

    output reg         comp_req_valid,
    output reg         comp_req_write,
    output reg  [5:0]  comp_req_addr,
    output reg  [39:0] comp_req_wdata,
    input  wire        comp_rsp_valid,
    input  wire [39:0] comp_rsp_rdata
);

  import CellStorePkg::*;
  import ComponentStorePkg::*;

  typedef enum logic [3:0] {
    S_IDLE,
    S_CLEAR_READ_REQ,
    S_CLEAR_READ_WAIT,
    S_CLEAR_WRITE,
    S_COMP_READ_REQ,
    S_COMP_READ_WAIT,
    S_DRAW_FIRST,
    S_DRAW_SECOND,
    S_DONE
  } state_t;

  state_t state;
  reg [9:0] cell_idx;
  reg [5:0] comp_idx;
  reg [15:0] cell_latched;
  reg [39:0] comp_latched;

  function automatic logic [5:0] first_sprite(input logic [3:0] comp_type);
    case (comp_type)
      COMP_RESISTOR: first_sprite = SPRITE_RES_LEFT;
      COMP_VOLTAGE:  first_sprite = SPRITE_VOLT_LEFT;
      COMP_CURRENT:  first_sprite = SPRITE_CURR_LEFT;
      COMP_CAPACITOR:first_sprite = SPRITE_CAP_LEFT;
      COMP_INDUCTOR: first_sprite = SPRITE_IND_LEFT;
      default:       first_sprite = SPRITE_RES_LEFT;
    endcase
  endfunction

  function automatic logic [5:0] second_sprite(input logic [3:0] comp_type);
    case (comp_type)
      COMP_RESISTOR: second_sprite = SPRITE_RES_RIGHT;
      COMP_VOLTAGE:  second_sprite = SPRITE_VOLT_RIGHT;
      COMP_CURRENT:  second_sprite = SPRITE_CURR_RIGHT;
      COMP_CAPACITOR:second_sprite = SPRITE_CAP_RIGHT;
      COMP_INDUCTOR: second_sprite = SPRITE_IND_RIGHT;
      default:       second_sprite = SPRITE_RES_RIGHT;
    endcase
  endfunction

  function automatic logic [1:0] cell_rot_from_component_rot(input logic [1:0] comp_rot);
    case (comp_rot)
      2'd0: cell_rot_from_component_rot = 2'd1;
      2'd1: cell_rot_from_component_rot = 2'd0;
      2'd2: cell_rot_from_component_rot = 2'd3;
      default: cell_rot_from_component_rot = 2'd2;
    endcase
  endfunction

  function automatic logic [4:0] second_x(input logic [39:0] comp);
    case (component_rot(comp))
      2'd1: second_x = component_anchor_x(comp) + 1'b1;
      2'd3: second_x = component_anchor_x(comp) - 1'b1;
      default: second_x = component_anchor_x(comp);
    endcase
  endfunction

  function automatic logic [4:0] second_y(input logic [39:0] comp);
    case (component_rot(comp))
      2'd0: second_y = component_anchor_y(comp) + 1'b1;
      2'd2: second_y = component_anchor_y(comp) - 1'b1;
      default: second_y = component_anchor_y(comp);
    endcase
  endfunction

  function automatic logic second_in_bounds(input logic [39:0] comp);
    logic [4:0] sx;
    logic [4:0] sy;
    begin
      sx = second_x(comp);
      sy = second_y(comp);
      second_in_bounds = (sx < GRID_WIDTH) && (sy < GRID_HEIGHT);
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      state <= S_IDLE;
      cell_idx <= '0;
      comp_idx <= '0;
      cell_latched <= '0;
      comp_latched <= '0;
      busy <= 1'b0;
      done <= 1'b0;
      cell_req_valid <= 1'b0;
      cell_req_write <= 1'b0;
      cell_req_addr <= '0;
      cell_req_wdata <= '0;
      comp_req_valid <= 1'b0;
      comp_req_write <= 1'b0;
      comp_req_addr <= '0;
      comp_req_wdata <= '0;
    end else begin
      done <= 1'b0;
      cell_req_valid <= 1'b0;
      comp_req_valid <= 1'b0;

      case (state)
        S_IDLE: begin
          busy <= 1'b0;
          if (start) begin
            busy <= 1'b1;
            cell_idx <= '0;
            state <= S_CLEAR_READ_REQ;
          end
        end

        S_CLEAR_READ_REQ: begin
          cell_req_valid <= 1'b1;
          cell_req_write <= 1'b0;
          cell_req_addr <= cell_idx;
          state <= S_CLEAR_READ_WAIT;
        end

        S_CLEAR_READ_WAIT: begin
          if (cell_rsp_valid) begin
            cell_latched <= cell_rsp_rdata;
            if (is_component_cell(cell_rsp_rdata)) begin
              state <= S_CLEAR_WRITE;
            end else if (cell_idx == CELL_COUNT - 1) begin
              comp_idx <= '0;
              state <= S_COMP_READ_REQ;
            end else begin
              cell_idx <= cell_idx + 1'b1;
              state <= S_CLEAR_READ_REQ;
            end
          end
        end

        S_CLEAR_WRITE: begin
          cell_req_valid <= 1'b1;
          cell_req_write <= 1'b1;
          cell_req_addr <= cell_idx;
          cell_req_wdata <= empty_cell();
          if (cell_idx == CELL_COUNT - 1) begin
            comp_idx <= '0;
            state <= S_COMP_READ_REQ;
          end else begin
            cell_idx <= cell_idx + 1'b1;
            state <= S_CLEAR_READ_REQ;
          end
        end

        S_COMP_READ_REQ: begin
          comp_req_valid <= 1'b1;
          comp_req_write <= 1'b0;
          comp_req_addr <= comp_idx;
          state <= S_COMP_READ_WAIT;
        end

        S_COMP_READ_WAIT: begin
          if (comp_rsp_valid) begin
            comp_latched <= comp_rsp_rdata;
            if (component_valid(comp_rsp_rdata)) begin
              state <= S_DRAW_FIRST;
            end else if (comp_idx == COMPONENT_COUNT - 1) begin
              state <= S_DONE;
            end else begin
              comp_idx <= comp_idx + 1'b1;
              state <= S_COMP_READ_REQ;
            end
          end
        end

        S_DRAW_FIRST: begin
          cell_req_valid <= 1'b1;
          cell_req_write <= 1'b1;
          cell_req_addr <= flatten_addr(component_anchor_x(comp_latched), component_anchor_y(comp_latched));
          cell_req_wdata <= pack_cell(
              1'b1,
              first_sprite(component_type(comp_latched)),
              cell_rot_from_component_rot(component_rot(comp_latched)),
              comp_idx,
              1'b0
          );
          if (second_in_bounds(comp_latched)) begin
            state <= S_DRAW_SECOND;
          end else if (comp_idx == COMPONENT_COUNT - 1) begin
            state <= S_DONE;
          end else begin
            comp_idx <= comp_idx + 1'b1;
            state <= S_COMP_READ_REQ;
          end
        end

        S_DRAW_SECOND: begin
          cell_req_valid <= 1'b1;
          cell_req_write <= 1'b1;
          cell_req_addr <= flatten_addr(second_x(comp_latched), second_y(comp_latched));
          cell_req_wdata <= pack_cell(
              1'b1,
              second_sprite(component_type(comp_latched)),
              cell_rot_from_component_rot(component_rot(comp_latched)),
              comp_idx,
              1'b0
          );
          if (comp_idx == COMPONENT_COUNT - 1) begin
            state <= S_DONE;
          end else begin
            comp_idx <= comp_idx + 1'b1;
            state <= S_COMP_READ_REQ;
          end
        end

        S_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;
          state <= S_IDLE;
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
