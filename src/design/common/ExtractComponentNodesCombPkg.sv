`timescale 1ns / 1ps

package ExtractComponentNodesCombPkg;

  function automatic logic ExtractComponentNodesCombPkg__is_ground_component_comb(
      input logic [7:0] t
  );
    begin
      ExtractComponentNodesCombPkg__is_ground_component_comb = (t == 8'd15);
    end
  endfunction

  function automatic logic is_ground_component_comb(
      input logic [7:0] t
  );
    begin
      is_ground_component_comb = ExtractComponentNodesCombPkg__is_ground_component_comb(t);
    end
  endfunction

  function automatic logic ExtractComponentNodesCombPkg__is_ground_cell_comb(
      input logic [15:0] cell_data
  );
    begin
      ExtractComponentNodesCombPkg__is_ground_cell_comb = cell_data[0] && (cell_data[6:1] == 6'd15);
    end
  endfunction

  function automatic logic is_ground_cell_comb(
      input logic [15:0] cell_data
  );
    begin
      is_ground_cell_comb = ExtractComponentNodesCombPkg__is_ground_cell_comb(cell_data);
    end
  endfunction

  function automatic logic [1:0] ExtractComponentNodesCombPkg__get_cell_rotation_comb(
      input logic [15:0] cell_data
  );
    begin
      ExtractComponentNodesCombPkg__get_cell_rotation_comb = cell_data[8:7];
    end
  endfunction

  function automatic logic [1:0] get_cell_rotation_comb(
      input logic [15:0] cell_data
  );
    begin
      get_cell_rotation_comb = ExtractComponentNodesCombPkg__get_cell_rotation_comb(cell_data);
    end
  endfunction

  function automatic logic [1:0] ExtractComponentNodesCombPkg__rotation_to_dir_comb(
      input logic [1:0] rot
  );
    begin
      case (rot)
        2'd0: ExtractComponentNodesCombPkg__rotation_to_dir_comb = 2'd1;
        2'd1: ExtractComponentNodesCombPkg__rotation_to_dir_comb = 2'd0;
        2'd2: ExtractComponentNodesCombPkg__rotation_to_dir_comb = 2'd3;
        default: ExtractComponentNodesCombPkg__rotation_to_dir_comb = 2'd2;
      endcase
    end
  endfunction

  function automatic logic [1:0] rotation_to_dir_comb(
      input logic [1:0] rot
  );
    begin
      rotation_to_dir_comb = ExtractComponentNodesCombPkg__rotation_to_dir_comb(rot);
    end
  endfunction

  function automatic logic ExtractComponentNodesCombPkg__is_two_terminal_component_comb(
      input logic [7:0] t
  );
    begin
      ExtractComponentNodesCombPkg__is_two_terminal_component_comb = (t >= 8'd5) && (t <= 8'd14);
    end
  endfunction

  function automatic logic is_two_terminal_component_comb(
      input logic [7:0] t
  );
    begin
      is_two_terminal_component_comb = ExtractComponentNodesCombPkg__is_two_terminal_component_comb(t);
    end
  endfunction

  function automatic logic [1:0] ExtractComponentNodesCombPkg__get_opp_dir_comb(
      input logic [1:0] d
  );
    begin
      case (d)
        2'd0: ExtractComponentNodesCombPkg__get_opp_dir_comb = 2'd2;
        2'd1: ExtractComponentNodesCombPkg__get_opp_dir_comb = 2'd3;
        2'd2: ExtractComponentNodesCombPkg__get_opp_dir_comb = 2'd0;
        default: ExtractComponentNodesCombPkg__get_opp_dir_comb = 2'd1;
      endcase
    end
  endfunction

  function automatic logic [1:0] get_opp_dir_comb(
      input logic [1:0] d
  );
    begin
      get_opp_dir_comb = ExtractComponentNodesCombPkg__get_opp_dir_comb(d);
    end
  endfunction

  function automatic logic [7:0] ExtractComponentNodesCombPkg__get_nxt_i_comb(
      input logic [7:0] i,
      input logic [1:0] d
  );
    begin
      case (d)
        2'd1: ExtractComponentNodesCombPkg__get_nxt_i_comb = i + 8'd1;
        2'd3: ExtractComponentNodesCombPkg__get_nxt_i_comb = i - 8'd1;
        default: ExtractComponentNodesCombPkg__get_nxt_i_comb = i;
      endcase
    end
  endfunction

  function automatic logic [7:0] get_nxt_i_comb(
      input logic [7:0] i,
      input logic [1:0] d
  );
    begin
      get_nxt_i_comb = ExtractComponentNodesCombPkg__get_nxt_i_comb(i, d);
    end
  endfunction

  function automatic logic [7:0] ExtractComponentNodesCombPkg__get_nxt_j_comb(
      input logic [7:0] j,
      input logic [1:0] d
  );
    begin
      case (d)
        2'd0: ExtractComponentNodesCombPkg__get_nxt_j_comb = j + 8'd1;
        2'd2: ExtractComponentNodesCombPkg__get_nxt_j_comb = j - 8'd1;
        default: ExtractComponentNodesCombPkg__get_nxt_j_comb = j;
      endcase
    end
  endfunction

  function automatic logic [7:0] get_nxt_j_comb(
      input logic [7:0] j,
      input logic [1:0] d
  );
    begin
      get_nxt_j_comb = ExtractComponentNodesCombPkg__get_nxt_j_comb(j, d);
    end
  endfunction

  // Current source halves (IL, IR): extraction puts node0 beyond the partner
  // half for these (D-015).
  function automatic logic is_current_source_comb(
      input logic [7:0] t
  );
    begin
      is_current_source_comb = (t == 8'd9) || (t == 8'd10);
    end
  endfunction

  // Whether a cell has a conducting port in flooding direction d (0 down,
  // 1 right, 2 up, 3 left). Same port table as fetchP's decode_p_from_cell
  // (BackendFetchers.v): {down, right, up, left}, rotated left by rotation.
  function automatic logic [3:0] cell_ports_comb(
      input logic [15:0] cell_data
  );
    logic [3:0] base;
    begin
      case (cell_data[6:1])
        6'd0: base = 4'b0101;
        6'd1: base = 4'b0110;
        6'd2: base = 4'b0111;
        6'd3, 6'd4: base = 4'b1111;
        6'd15: base = 4'b0001;
        default: base = 4'b0000;
      endcase
      case (cell_data[8:7])
        2'd0: cell_ports_comb = base;
        2'd1: cell_ports_comb = {base[2:0], base[3]};
        2'd2: cell_ports_comb = {base[1:0], base[3:2]};
        default: cell_ports_comb = {base[0], base[3:1]};
      endcase
      if (!cell_data[0]) cell_ports_comb = 4'b0000;
    end
  endfunction

  function automatic logic cell_has_port_comb(
      input logic [15:0] cell_data,
      input logic [1:0] d
  );
    logic [3:0] p;
    begin
      p = cell_ports_comb(cell_data);
      case (d)
        2'd0: cell_has_port_comb = p[3];
        2'd1: cell_has_port_comb = p[2];
        2'd2: cell_has_port_comb = p[1];
        default: cell_has_port_comb = p[0];
      endcase
    end
  endfunction

endpackage
