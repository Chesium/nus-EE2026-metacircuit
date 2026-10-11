`timescale 1ns / 1ps

package FloodingCombPkg;

  function automatic logic decode_iswire_comb(input logic [3:0] p);
    decode_iswire_comb = (p != 4'b0000);
  endfunction

  function automatic logic getport_comb(
      input logic [3:0] p,
      input logic [31:0] i
  );
    case (i[1:0])
      2'd0: getport_comb = p[3];
      2'd1: getport_comb = p[2];
      2'd2: getport_comb = p[1];
      2'd3: getport_comb = p[0];
      default: getport_comb = 1'b0;
    endcase
  endfunction

  function automatic logic [1:0] get_opp_dir_comb(input logic [1:0] d);
    case (d)
      2'd0: get_opp_dir_comb = 2'd2;
      2'd1: get_opp_dir_comb = 2'd3;
      2'd2: get_opp_dir_comb = 2'd0;
      2'd3: get_opp_dir_comb = 2'd1;
      default: get_opp_dir_comb = 2'd0;
    endcase
  endfunction

  function automatic logic [7:0] get_nxt_i_comb(
      input logic [7:0] i,
      input logic [1:0] d
  );
    case (d)
      2'd1: get_nxt_i_comb = i + 8'd1;
      2'd3: get_nxt_i_comb = i - 8'd1;
      default: get_nxt_i_comb = i;
    endcase
  endfunction

  function automatic logic [7:0] get_nxt_j_comb(
      input logic [7:0] j,
      input logic [1:0] d
  );
    case (d)
      2'd0: get_nxt_j_comb = j + 8'd1;
      2'd2: get_nxt_j_comb = j - 8'd1;
      default: get_nxt_j_comb = j;
    endcase
  endfunction

  function automatic logic [7:0] decode_i_comb(input logic [17:0] q_item);
    decode_i_comb = q_item[17:10];
  endfunction

  function automatic logic [7:0] decode_j_comb(input logic [17:0] q_item);
    decode_j_comb = q_item[9:2];
  endfunction

  function automatic logic [1:0] decode_d_comb(input logic [17:0] q_item);
    decode_d_comb = q_item[1:0];
  endfunction

  function automatic logic [17:0] pack_queue_item_comb(
      input logic [7:0] i,
      input logic [7:0] j,
      input logic [1:0] d
  );
    pack_queue_item_comb = {i, j, d};
  endfunction

endpackage
