`timescale 1ns / 1ps

module CommandExecutor (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        cmd_valid,
    input  wire [63:0] cmd_payload,
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
  import MetaCommandPkg::*;

  typedef enum logic [4:0] {
    S_IDLE,
    S_LATCH,
    S_CELL_READ_REQ,
    S_CELL_READ_WAIT,
    S_COMP_READ_REQ,
    S_COMP_READ_WAIT,
    S_COMP_SCAN_REQ,
    S_COMP_SCAN_WAIT,
    S_WRITE_CELL,
    S_WRITE_COMP,
    S_DONE
  } state_t;

  state_t state;
  reg [63:0] cmd_latched;
  reg [5:0] scan_idx;
  reg [5:0] target_comp_idx;
  reg [15:0] target_cell_data;
  reg [39:0] target_comp_data;

  function automatic logic [9:0] cmd_cell_addr(input logic [63:0] cmd);
    cmd_cell_addr = flatten_addr(command_cell_x(cmd), command_cell_y(cmd));
  endfunction

  function automatic logic [15:0] make_direct_cell(input logic [63:0] cmd);
    make_direct_cell = pack_cell(
        1'b1,
        command_sprite(cmd),
        command_rot(cmd),
        NON_COMPONENT_IDX,
        command_meta(cmd)
    );
  endfunction

  function automatic logic [39:0] make_new_component(
      input logic [63:0] cmd
  );
    make_new_component = pack_component(
        command_comp_type(cmd),
        command_value(cmd),
        NODE_NONE,
        NODE_NONE,
        command_cell_x(cmd),
        command_cell_y(cmd),
        command_rot(cmd),
        5'b00001
    );
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      state <= S_IDLE;
      cmd_latched <= '0;
      scan_idx <= '0;
      target_comp_idx <= '0;
      target_cell_data <= '0;
      target_comp_data <= '0;
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
          if (start && cmd_valid) begin
            cmd_latched <= cmd_payload;
            busy <= 1'b1;
            state <= S_LATCH;
          end
        end

        S_LATCH: begin
          case (command_kind(cmd_latched))
            CMD_CELL_WRITE: state <= S_WRITE_CELL;
            CMD_CELL_CLEAR: state <= S_WRITE_CELL;
            CMD_COMPONENT_CREATE: begin
              scan_idx <= 6'd0;
              state <= S_COMP_SCAN_REQ;
            end
            CMD_COMPONENT_UPDATE: begin
              target_comp_idx <= command_comp_idx(cmd_latched);
              state <= S_COMP_READ_REQ;
            end
            CMD_COMPONENT_ROTATE: begin
              target_comp_idx <= command_comp_idx(cmd_latched);
              state <= S_COMP_READ_REQ;
            end
            CMD_COMPONENT_DELETE: begin
              target_comp_idx <= command_comp_idx(cmd_latched);
              state <= S_WRITE_COMP;
            end
            CMD_ROTATE_TARGET,
            CMD_DELETE_TARGET,
            CMD_SELECT_TARGET: state <= S_CELL_READ_REQ;
            default: state <= S_DONE;
          endcase
        end

        S_CELL_READ_REQ: begin
          cell_req_valid <= 1'b1;
          cell_req_write <= 1'b0;
          cell_req_addr <= cmd_cell_addr(cmd_latched);
          state <= S_CELL_READ_WAIT;
        end

        S_CELL_READ_WAIT: begin
          if (cell_rsp_valid) begin
            target_cell_data <= cell_rsp_rdata;
            if (command_kind(cmd_latched) == CMD_SELECT_TARGET) begin
              state <= S_DONE;
            end else if (is_component_cell(cell_rsp_rdata)) begin
              target_comp_idx <= cell_comp_idx(cell_rsp_rdata);
              if (command_kind(cmd_latched) == CMD_DELETE_TARGET) begin
                state <= S_WRITE_COMP;
              end else begin
                state <= S_COMP_READ_REQ;
              end
            end else begin
              state <= S_WRITE_CELL;
            end
          end
        end

        S_COMP_READ_REQ: begin
          comp_req_valid <= 1'b1;
          comp_req_write <= 1'b0;
          comp_req_addr <= target_comp_idx;
          state <= S_COMP_READ_WAIT;
        end

        S_COMP_READ_WAIT: begin
          if (comp_rsp_valid) begin
            target_comp_data <= comp_rsp_rdata;
            state <= S_WRITE_COMP;
          end
        end

        S_COMP_SCAN_REQ: begin
          comp_req_valid <= 1'b1;
          comp_req_write <= 1'b0;
          comp_req_addr <= scan_idx;
          state <= S_COMP_SCAN_WAIT;
        end

        S_COMP_SCAN_WAIT: begin
          if (comp_rsp_valid) begin
            if (!component_valid(comp_rsp_rdata)) begin
              target_comp_idx <= scan_idx;
              state <= S_WRITE_COMP;
            end else if (scan_idx == COMPONENT_COUNT - 1) begin
              state <= S_DONE;
            end else begin
              scan_idx <= scan_idx + 1'b1;
              state <= S_COMP_SCAN_REQ;
            end
          end
        end

        S_WRITE_CELL: begin
          cell_req_valid <= 1'b1;
          cell_req_write <= 1'b1;
          cell_req_addr <= cmd_cell_addr(cmd_latched);
          case (command_kind(cmd_latched))
            CMD_CELL_WRITE: cell_req_wdata <= make_direct_cell(cmd_latched);
            CMD_CELL_CLEAR: cell_req_wdata <= empty_cell();
            CMD_DELETE_TARGET: cell_req_wdata <= empty_cell();
            CMD_ROTATE_TARGET: begin
              cell_req_wdata <= pack_cell(
                  cell_valid(target_cell_data),
                  cell_sprite(target_cell_data),
                  cell_rot(target_cell_data) + 2'd1,
                  NON_COMPONENT_IDX,
                  cell_meta(target_cell_data)
              );
            end
            default: cell_req_wdata <= empty_cell();
          endcase
          state <= S_DONE;
        end

        S_WRITE_COMP: begin
          comp_req_valid <= 1'b1;
          comp_req_write <= 1'b1;
          comp_req_addr <= target_comp_idx;
          case (command_kind(cmd_latched))
            CMD_COMPONENT_CREATE: comp_req_wdata <= make_new_component(cmd_latched);
            CMD_COMPONENT_UPDATE: comp_req_wdata <= component_with_value(target_comp_data, command_value(cmd_latched));
            CMD_COMPONENT_ROTATE: comp_req_wdata <= component_with_rot(target_comp_data, component_rot(target_comp_data) + 2'd1);
            CMD_COMPONENT_DELETE: comp_req_wdata <= empty_component();
            CMD_DELETE_TARGET: comp_req_wdata <= empty_component();
            CMD_ROTATE_TARGET: comp_req_wdata <= component_with_rot(target_comp_data, component_rot(target_comp_data) + 2'd1);
            default: comp_req_wdata <= target_comp_data;
          endcase
          state <= S_DONE;
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
