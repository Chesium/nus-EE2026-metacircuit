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
        2'd0: ExtractComponentNodesCombPkg__get_nxt_i_comb = i + 8'd1;
        2'd2: ExtractComponentNodesCombPkg__get_nxt_i_comb = i - 8'd1;
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
        2'd1: ExtractComponentNodesCombPkg__get_nxt_j_comb = j + 8'd1;
        2'd3: ExtractComponentNodesCombPkg__get_nxt_j_comb = j - 8'd1;
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

endpackage
