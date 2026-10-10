
// Generated from LIR for function extract_component_nodes

// Entry block: entry

// Blocking primitives: fetchComponentType(latency=1), fetchAnchorPositionX(latency=1), storeNode0(latency=1), fetchAnchorPositionY(latency=1), fetchComponentRotation(latency=1), fetchCell(latency=1), fetchR(latency=1), storeNode1(latency=1)

module extract_component_nodes (

    input logic clk,

    input logic rst_n,

    input logic start,

    output logic busy,

    output logic done,

    input logic [31:0] par_elem_n,

    input logic [31:0] grid_height,

    input logic [31:0] grid_width,

    output logic fetchComponentType_start,

    output logic [15:0] fetchComponentType_idx,

    input logic fetchComponentType_done,

    input logic [7:0] fetchComponentType_result,

    output logic fetchAnchorPositionX_start,

    output logic [15:0] fetchAnchorPositionX_idx,

    input logic fetchAnchorPositionX_done,

    input logic [7:0] fetchAnchorPositionX_result,

    output logic storeNode0_start,

    output logic [15:0] storeNode0_idx,

    output logic [7:0] storeNode0_node_i,

    input logic storeNode0_done,

    output logic fetchAnchorPositionY_start,

    output logic [15:0] fetchAnchorPositionY_idx,

    input logic fetchAnchorPositionY_done,

    input logic [7:0] fetchAnchorPositionY_result,

    output logic fetchComponentRotation_start,

    output logic [15:0] fetchComponentRotation_idx,

    input logic fetchComponentRotation_done,

    input logic [1:0] fetchComponentRotation_result,

    output logic fetchCell_start,

    output logic [7:0] fetchCell_i,

    output logic [7:0] fetchCell_j,

    input logic fetchCell_done,

    input logic [15:0] fetchCell_result,

    output logic fetchR_start,

    output logic [7:0] fetchR_i,

    output logic [7:0] fetchR_j,

    input logic fetchR_done,

    input logic [7:0] fetchR_result,

    output logic storeNode1_start,

    output logic [15:0] storeNode1_idx,

    output logic [7:0] storeNode1_node_i,

    input logic storeNode1_done

);


import ExtractComponentNodesCombPkg::*;


typedef enum logic [7:0] {

    S_IDLE,

    S_ENTRY,

    S_FOR_HEADER_0,

    S_FOR_BODY_1,

    S_FOR_BODY_1_WAIT,

    S_FOR_END_2,

    S_AFTER_CALL_3,

    S_IF_THEN_4,

    S_IF_THEN_4_WAIT,

    S_IF_END_5,

    S_IF_ELSE_6,

    S_IF_ELSE_6_WAIT,

    S_AFTER_CALL_7,

    S_AFTER_CALL_7_WAIT,

    S_AFTER_CALL_8,

    S_AFTER_CALL_8_WAIT,

    S_AFTER_CALL_9,

    S_IF_THEN_10,

    S_IF_END_11,

    S_FOR_HEADER_12,

    S_FOR_BODY_13,

    S_FOR_END_14,

    S_IF_THEN_15,

    S_IF_END_16,

    S_IF_ELSE_17,

    S_IF_THEN_18,

    S_IF_END_19,

    S_IF_ELSE_20,

    S_IF_THEN_21,

    S_IF_THEN_21_WAIT,

    S_IF_END_22,

    S_AFTER_CALL_23,

    S_IF_THEN_24,

    S_IF_THEN_24_WAIT,

    S_IF_END_25,

    S_AFTER_CALL_26,

    S_IF_THEN_27,

    S_IF_END_28,

    S_FOR_HEADER_29,

    S_FOR_BODY_30,

    S_FOR_END_31,

    S_FOR_HEADER_32,

    S_FOR_BODY_33,

    S_FOR_BODY_33_WAIT,

    S_FOR_END_34,

    S_AFTER_CALL_35,

    S_IF_THEN_36,

    S_IF_THEN_36_WAIT,

    S_IF_END_37,

    S_AFTER_CALL_38,

    S_IF_THEN_39,

    S_IF_END_40,

    S_IF_THEN_41,

    S_IF_END_42,

    S_IF_THEN_43,

    S_IF_END_44,

    S_FOR_HEADER_45,

    S_FOR_BODY_46,

    S_FOR_END_47,

    S_FOR_HEADER_48,

    S_FOR_BODY_49,

    S_FOR_BODY_49_WAIT,

    S_FOR_END_50,

    S_AFTER_CALL_51,

    S_IF_THEN_52,

    S_IF_END_53,

    S_FOR_HEADER_54,

    S_FOR_BODY_55,

    S_FOR_END_56,

    S_FOR_HEADER_57,

    S_FOR_BODY_58,

    S_FOR_END_59,

    S_IF_THEN_60,

    S_IF_THEN_60_WAIT,

    S_IF_END_61,

    S_AFTER_CALL_62,

    S_IF_THEN_63,

    S_IF_END_64,

    S_IF_THEN_65,

    S_IF_END_66,

    S_FOR_HEADER_67,

    S_FOR_BODY_68,

    S_FOR_END_69,

    S_FOR_HEADER_70,

    S_FOR_BODY_71,

    S_FOR_BODY_71_WAIT,

    S_FOR_END_72,

    S_AFTER_CALL_73,

    S_IF_THEN_74,

    S_IF_THEN_74_WAIT,

    S_IF_END_75,

    S_AFTER_CALL_76,

    S_IF_THEN_77,

    S_IF_END_78,

    S_FOR_HEADER_79,

    S_FOR_BODY_80,

    S_FOR_BODY_80_WAIT,

    S_FOR_END_81,

    S_AFTER_CALL_82,

    S_IF_THEN_83,

    S_IF_THEN_83_WAIT,

    S_IF_END_84,

    S_AFTER_CALL_85,

    S_AFTER_CALL_85_WAIT,

    S_AFTER_CALL_86,

    S_AFTER_CALL_86_WAIT,

    S_AFTER_CALL_87,

    S_FOR_HEADER_88,

    S_FOR_BODY_89,

    S_FOR_END_90,

    S_IF_THEN_91,

    S_IF_END_92,

    S_IF_ELSE_93,

    S_IF_THEN_94,

    S_IF_THEN_94_WAIT,

    S_IF_END_95,

    S_AFTER_CALL_96,

    S_IF_THEN_97,

    S_IF_THEN_97_WAIT,

    S_IF_END_98,

    S_AFTER_CALL_99,

    S_IF_THEN_100,

    S_IF_END_101,

    S_IF_THEN_102,

    S_IF_END_103,

    S_IF_THEN_104,

    S_IF_END_105,

    S_IF_THEN_106,

    S_IF_END_107,

    S_IF_THEN_108,

    S_IF_THEN_108_WAIT,

    S_IF_END_109,

    S_IF_ELSE_110,

    S_IF_ELSE_110_WAIT,

    S_AFTER_CALL_111,

    S_AFTER_CALL_112,

    S_AFTER_CALL_113,

    S_AFTER_CALL_113_WAIT,

    S_AFTER_CALL_114,

    S_DONE

} state_t;

state_t state;
state_t next_state;


logic [15:0] u16_idx;

logic [7:0] u8_type;

logic [7:0] u8_anchor_x;

logic [7:0] u8_anchor_y;

logic [1:0] u2_dir;

logic [1:0] u2_out;

logic [1:0] u2_term;

logic u1_is_isrc;

logic u1_far;

logic [7:0] u8_term_x;

logic [7:0] u8_term_y;

logic [15:0] u16_cell;

logic [7:0] u8_raw;

logic [7:0] u8_node;

logic [7:0] u8_next_node;

logic [7:0] u8_region_rows;

logic u1_rows_known;

logic [7:0] u8_next_float;

logic [7:0] u8_scan_x;

logic [7:0] u8_scan_y;

logic [7:0] u8_prev_x;

logic [7:0] u8_prev_y;

logic [7:0] u8_ground_x;

logic [7:0] u8_ground_y;

logic [7:0] u8_region;

logic [7:0] u8_prev_region;

logic [7:0] u8_ground_region;

logic u1_seen;

logic u1_is_ground;

logic u1_region_is_ground;

logic u1_touched;

logic [15:0] u16_touch_idx;

logic [7:0] u8_touch_type;

logic [7:0] u8_touch_ax;

logic [7:0] u8_touch_ay;

logic [1:0] u2_touch_dir;

logic [1:0] u2_touch_out;

logic [1:0] u2_touch_term;

logic [7:0] u8_touch_x;

logic [7:0] u8_touch_y;

logic [15:0] u16_touch_cell;

logic [7:0] u8_touch_region;


logic [15:0] __for_idx_0;

logic [1:0] __for_idx_1;

logic [7:0] __for_idx_2;

logic [7:0] __for_idx_3;

logic [7:0] __for_idx_4;

logic [7:0] __for_idx_5;

logic [7:0] __for_idx_6;

logic [7:0] __for_idx_7;

logic [7:0] __for_idx_8;

logic [7:0] __for_idx_9;

logic [15:0] __for_idx_10;

logic [1:0] __for_idx_11;



logic [15:0] next_u16_idx;

logic [7:0] next_u8_type;

logic [7:0] next_u8_anchor_x;

logic [7:0] next_u8_anchor_y;

logic [1:0] next_u2_dir;

logic [1:0] next_u2_out;

logic [1:0] next_u2_term;

logic next_u1_is_isrc;

logic next_u1_far;

logic [7:0] next_u8_term_x;

logic [7:0] next_u8_term_y;

logic [15:0] next_u16_cell;

logic [7:0] next_u8_raw;

logic [7:0] next_u8_node;

logic [7:0] next_u8_next_node;

logic [7:0] next_u8_region_rows;

logic next_u1_rows_known;

logic [7:0] next_u8_next_float;

logic [7:0] next_u8_scan_x;

logic [7:0] next_u8_scan_y;

logic [7:0] next_u8_prev_x;

logic [7:0] next_u8_prev_y;

logic [7:0] next_u8_ground_x;

logic [7:0] next_u8_ground_y;

logic [7:0] next_u8_region;

logic [7:0] next_u8_prev_region;

logic [7:0] next_u8_ground_region;

logic next_u1_seen;

logic next_u1_is_ground;

logic next_u1_region_is_ground;

logic next_u1_touched;

logic [15:0] next_u16_touch_idx;

logic [7:0] next_u8_touch_type;

logic [7:0] next_u8_touch_ax;

logic [7:0] next_u8_touch_ay;

logic [1:0] next_u2_touch_dir;

logic [1:0] next_u2_touch_out;

logic [1:0] next_u2_touch_term;

logic [7:0] next_u8_touch_x;

logic [7:0] next_u8_touch_y;

logic [15:0] next_u16_touch_cell;

logic [7:0] next_u8_touch_region;

logic [15:0] next___for_idx_0;

logic [1:0] next___for_idx_1;

logic [7:0] next___for_idx_2;

logic [7:0] next___for_idx_3;

logic [7:0] next___for_idx_4;

logic [7:0] next___for_idx_5;

logic [7:0] next___for_idx_6;

logic [7:0] next___for_idx_7;

logic [7:0] next___for_idx_8;

logic [7:0] next___for_idx_9;

logic [15:0] next___for_idx_10;

logic [1:0] next___for_idx_11;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        u16_idx <=0;

        u8_type <=0;

        u8_anchor_x <=0;

        u8_anchor_y <=0;

        u2_dir <=0;

        u2_out <=0;

        u2_term <=0;

        u1_is_isrc <=0;

        u1_far <=0;

        u8_term_x <=0;

        u8_term_y <=0;

        u16_cell <=0;

        u8_raw <=0;

        u8_node <=0;

        u8_next_node <=0;

        u8_region_rows <=0;

        u1_rows_known <=0;

        u8_next_float <=0;

        u8_scan_x <=0;

        u8_scan_y <=0;

        u8_prev_x <=0;

        u8_prev_y <=0;

        u8_ground_x <=0;

        u8_ground_y <=0;

        u8_region <=0;

        u8_prev_region <=0;

        u8_ground_region <=0;

        u1_seen <=0;

        u1_is_ground <=0;

        u1_region_is_ground <=0;

        u1_touched <=0;

        u16_touch_idx <=0;

        u8_touch_type <=0;

        u8_touch_ax <=0;

        u8_touch_ay <=0;

        u2_touch_dir <=0;

        u2_touch_out <=0;

        u2_touch_term <=0;

        u8_touch_x <=0;

        u8_touch_y <=0;

        u16_touch_cell <=0;

        u8_touch_region <=0;


        __for_idx_0 <=0;

        __for_idx_1 <=0;

        __for_idx_2 <=0;

        __for_idx_3 <=0;

        __for_idx_4 <=0;

        __for_idx_5 <=0;

        __for_idx_6 <=0;

        __for_idx_7 <=0;

        __for_idx_8 <=0;

        __for_idx_9 <=0;

        __for_idx_10 <=0;

        __for_idx_11 <=0;


    end else begin
        state <= next_state;

        u16_idx <= next_u16_idx;

        u8_type <= next_u8_type;

        u8_anchor_x <= next_u8_anchor_x;

        u8_anchor_y <= next_u8_anchor_y;

        u2_dir <= next_u2_dir;

        u2_out <= next_u2_out;

        u2_term <= next_u2_term;

        u1_is_isrc <= next_u1_is_isrc;

        u1_far <= next_u1_far;

        u8_term_x <= next_u8_term_x;

        u8_term_y <= next_u8_term_y;

        u16_cell <= next_u16_cell;

        u8_raw <= next_u8_raw;

        u8_node <= next_u8_node;

        u8_next_node <= next_u8_next_node;

        u8_region_rows <= next_u8_region_rows;

        u1_rows_known <= next_u1_rows_known;

        u8_next_float <= next_u8_next_float;

        u8_scan_x <= next_u8_scan_x;

        u8_scan_y <= next_u8_scan_y;

        u8_prev_x <= next_u8_prev_x;

        u8_prev_y <= next_u8_prev_y;

        u8_ground_x <= next_u8_ground_x;

        u8_ground_y <= next_u8_ground_y;

        u8_region <= next_u8_region;

        u8_prev_region <= next_u8_prev_region;

        u8_ground_region <= next_u8_ground_region;

        u1_seen <= next_u1_seen;

        u1_is_ground <= next_u1_is_ground;

        u1_region_is_ground <= next_u1_region_is_ground;

        u1_touched <= next_u1_touched;

        u16_touch_idx <= next_u16_touch_idx;

        u8_touch_type <= next_u8_touch_type;

        u8_touch_ax <= next_u8_touch_ax;

        u8_touch_ay <= next_u8_touch_ay;

        u2_touch_dir <= next_u2_touch_dir;

        u2_touch_out <= next_u2_touch_out;

        u2_touch_term <= next_u2_touch_term;

        u8_touch_x <= next_u8_touch_x;

        u8_touch_y <= next_u8_touch_y;

        u16_touch_cell <= next_u16_touch_cell;

        u8_touch_region <= next_u8_touch_region;


        __for_idx_0 <= next___for_idx_0;

        __for_idx_1 <= next___for_idx_1;

        __for_idx_2 <= next___for_idx_2;

        __for_idx_3 <= next___for_idx_3;

        __for_idx_4 <= next___for_idx_4;

        __for_idx_5 <= next___for_idx_5;

        __for_idx_6 <= next___for_idx_6;

        __for_idx_7 <= next___for_idx_7;

        __for_idx_8 <= next___for_idx_8;

        __for_idx_9 <= next___for_idx_9;

        __for_idx_10 <= next___for_idx_10;

        __for_idx_11 <= next___for_idx_11;


    end
end

always_comb begin
    next_state = state;
    busy = 1'b1;
    done = 1'b0;

    next_u16_idx = u16_idx;

    next_u8_type = u8_type;

    next_u8_anchor_x = u8_anchor_x;

    next_u8_anchor_y = u8_anchor_y;

    next_u2_dir = u2_dir;

    next_u2_out = u2_out;

    next_u2_term = u2_term;

    next_u1_is_isrc = u1_is_isrc;

    next_u1_far = u1_far;

    next_u8_term_x = u8_term_x;

    next_u8_term_y = u8_term_y;

    next_u16_cell = u16_cell;

    next_u8_raw = u8_raw;

    next_u8_node = u8_node;

    next_u8_next_node = u8_next_node;

    next_u8_region_rows = u8_region_rows;

    next_u1_rows_known = u1_rows_known;

    next_u8_next_float = u8_next_float;

    next_u8_scan_x = u8_scan_x;

    next_u8_scan_y = u8_scan_y;

    next_u8_prev_x = u8_prev_x;

    next_u8_prev_y = u8_prev_y;

    next_u8_ground_x = u8_ground_x;

    next_u8_ground_y = u8_ground_y;

    next_u8_region = u8_region;

    next_u8_prev_region = u8_prev_region;

    next_u8_ground_region = u8_ground_region;

    next_u1_seen = u1_seen;

    next_u1_is_ground = u1_is_ground;

    next_u1_region_is_ground = u1_region_is_ground;

    next_u1_touched = u1_touched;

    next_u16_touch_idx = u16_touch_idx;

    next_u8_touch_type = u8_touch_type;

    next_u8_touch_ax = u8_touch_ax;

    next_u8_touch_ay = u8_touch_ay;

    next_u2_touch_dir = u2_touch_dir;

    next_u2_touch_out = u2_touch_out;

    next_u2_touch_term = u2_touch_term;

    next_u8_touch_x = u8_touch_x;

    next_u8_touch_y = u8_touch_y;

    next_u16_touch_cell = u16_touch_cell;

    next_u8_touch_region = u8_touch_region;


    next___for_idx_0 = __for_idx_0;

    next___for_idx_1 = __for_idx_1;

    next___for_idx_2 = __for_idx_2;

    next___for_idx_3 = __for_idx_3;

    next___for_idx_4 = __for_idx_4;

    next___for_idx_5 = __for_idx_5;

    next___for_idx_6 = __for_idx_6;

    next___for_idx_7 = __for_idx_7;

    next___for_idx_8 = __for_idx_8;

    next___for_idx_9 = __for_idx_9;

    next___for_idx_10 = __for_idx_10;

    next___for_idx_11 = __for_idx_11;



    fetchComponentType_start =0;

    fetchComponentType_idx =0;

    fetchAnchorPositionX_start =0;

    fetchAnchorPositionX_idx =0;

    storeNode0_start =0;

    storeNode0_idx =0;

    storeNode0_node_i =0;

    fetchAnchorPositionY_start =0;

    fetchAnchorPositionY_idx =0;

    fetchComponentRotation_start =0;

    fetchComponentRotation_idx =0;

    fetchCell_start =0;

    fetchCell_i =0;

    fetchCell_j =0;

    fetchR_start =0;

    fetchR_i =0;

    fetchR_j =0;

    storeNode1_start =0;

    storeNode1_idx =0;

    storeNode1_node_i =0;


    case (state)

        S_IDLE: begin

            // FSM idle state

            // Wait for start to enter the LIR entry block


            busy = 1'b0;





            if (start) begin
                next_state = S_ENTRY;
            end else begin
                next_state = S_IDLE;
            end

        end

        S_ENTRY: begin

            // LIR block: entry

            // line 45: u16_idx = 0




            next_u16_idx = 16'd0;

            next_u8_type = 8'd0;

            next_u8_anchor_x = 8'd0;

            next_u8_anchor_y = 8'd0;

            next_u2_dir = 2'd0;

            next_u2_out = 2'd0;

            next_u2_term = 2'd0;

            next_u1_is_isrc = 1'd0;

            next_u1_far = 1'd0;

            next_u8_term_x = 8'd0;

            next_u8_term_y = 8'd0;

            next_u16_cell = 16'd0;

            next_u8_raw = 8'd0;

            next_u8_node = 8'd255;

            next_u8_next_node = 8'd0;

            next_u8_region_rows = 8'd0;

            next_u1_rows_known = 1'd0;

            next_u8_next_float = 8'd0;

            next_u8_scan_x = 8'd0;

            next_u8_scan_y = 8'd0;

            next_u8_prev_x = 8'd0;

            next_u8_prev_y = 8'd0;

            next_u8_ground_x = 8'd0;

            next_u8_ground_y = 8'd0;

            next_u8_region = 8'd0;

            next_u8_prev_region = 8'd0;

            next_u8_ground_region = 8'd0;

            next_u1_seen = 1'd0;

            next_u1_is_ground = 1'd0;

            next_u1_region_is_ground = 1'd0;

            next_u1_touched = 1'd0;

            next_u16_touch_idx = 16'd0;

            next_u8_touch_type = 8'd0;

            next_u8_touch_ax = 8'd0;

            next_u8_touch_ay = 8'd0;

            next_u2_touch_dir = 2'd0;

            next_u2_touch_out = 2'd0;

            next_u2_touch_term = 2'd0;

            next_u8_touch_x = 8'd0;

            next_u8_touch_y = 8'd0;

            next_u16_touch_cell = 16'd0;

            next_u8_touch_region = 8'd0;

            next___for_idx_0 = 16'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 88: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)






            if ((__for_idx_0 < par_elem_n)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 88: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)




            next_u16_idx = __for_idx_0;


            fetchComponentType_idx = __for_idx_0;

            fetchComponentType_start = 1'b1;


            next_state = S_FOR_BODY_1_WAIT;

        end

        S_FOR_BODY_1_WAIT: begin

            // LIR block: for_body_1

            // line 88: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)

            // wait for blocking primitive: fetchComponentType






            if (fetchComponentType_done) begin

                next_u8_type = fetchComponentType_result;

                next_state = S_AFTER_CALL_3;
            end else begin
                next_state = S_FOR_BODY_1_WAIT;
            end

        end

        S_FOR_END_2: begin

            // LIR block: for_end_2







            next_state = S_DONE;

        end

        S_AFTER_CALL_3: begin

            // LIR block: after_call_3

            // line 91: if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)






            if (is_two_terminal_component_comb(u8_type)) begin
                next_state = S_IF_THEN_4;
            end else begin
                next_state = S_IF_ELSE_6;
            end

        end

        S_IF_THEN_4: begin

            // LIR block: if_then_4

            // line 92: u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)





            fetchAnchorPositionX_idx = u16_idx;

            fetchAnchorPositionX_start = 1'b1;


            next_state = S_IF_THEN_4_WAIT;

        end

        S_IF_THEN_4_WAIT: begin

            // LIR block: if_then_4

            // line 92: u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)

            // wait for blocking primitive: fetchAnchorPositionX






            if (fetchAnchorPositionX_done) begin

                next_u8_anchor_x = fetchAnchorPositionX_result;

                next_state = S_AFTER_CALL_7;
            end else begin
                next_state = S_IF_THEN_4_WAIT;
            end

        end

        S_IF_END_5: begin

            // LIR block: if_end_5

            // line 88: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)




            next___for_idx_0 = (__for_idx_0 + 16'd1);



            next_state = S_FOR_HEADER_0;

        end

        S_IF_ELSE_6: begin

            // LIR block: if_else_6

            // line 213: u8_node = 255




            next_u8_node = 8'd255;


            storeNode0_idx = u16_idx;

            storeNode0_node_i = 8'd255;

            storeNode0_start = 1'b1;


            next_state = S_IF_ELSE_6_WAIT;

        end

        S_IF_ELSE_6_WAIT: begin

            // LIR block: if_else_6

            // line 213: u8_node = 255

            // wait for blocking primitive: storeNode0






            if (storeNode0_done) begin

                next_state = S_AFTER_CALL_113;
            end else begin
                next_state = S_IF_ELSE_6_WAIT;
            end

        end

        S_AFTER_CALL_7: begin

            // LIR block: after_call_7

            // line 93: u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)





            fetchAnchorPositionY_idx = u16_idx;

            fetchAnchorPositionY_start = 1'b1;


            next_state = S_AFTER_CALL_7_WAIT;

        end

        S_AFTER_CALL_7_WAIT: begin

            // LIR block: after_call_7

            // line 93: u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)

            // wait for blocking primitive: fetchAnchorPositionY






            if (fetchAnchorPositionY_done) begin

                next_u8_anchor_y = fetchAnchorPositionY_result;

                next_state = S_AFTER_CALL_8;
            end else begin
                next_state = S_AFTER_CALL_7_WAIT;
            end

        end

        S_AFTER_CALL_8: begin

            // LIR block: after_call_8

            // line 94: u2_dir = fetchComponentRotation(idx=u16_idx)





            fetchComponentRotation_idx = u16_idx;

            fetchComponentRotation_start = 1'b1;


            next_state = S_AFTER_CALL_8_WAIT;

        end

        S_AFTER_CALL_8_WAIT: begin

            // LIR block: after_call_8

            // line 94: u2_dir = fetchComponentRotation(idx=u16_idx)

            // wait for blocking primitive: fetchComponentRotation






            if (fetchComponentRotation_done) begin

                next_u2_dir = fetchComponentRotation_result;

                next_state = S_AFTER_CALL_9;
            end else begin
                next_state = S_AFTER_CALL_8_WAIT;
            end

        end

        S_AFTER_CALL_9: begin

            // LIR block: after_call_9

            // line 95: u2_dir = rotation_to_dir_comb(rot=u2_dir)




            next_u2_dir = rotation_to_dir_comb(u2_dir);

            next_u1_is_isrc = 1'd0;



            if (is_current_source_comb(u8_type)) begin
                next_state = S_IF_THEN_10;
            end else begin
                next_state = S_IF_END_11;
            end

        end

        S_IF_THEN_10: begin

            // LIR block: if_then_10

            // line 98: u1_is_isrc = 1




            next_u1_is_isrc = 1'd1;



            next_state = S_IF_END_11;

        end

        S_IF_END_11: begin

            // LIR block: if_end_11

            // line 100: for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)




            next___for_idx_1 = 2'd0;



            next_state = S_FOR_HEADER_12;

        end

        S_FOR_HEADER_12: begin

            // LIR block: for_header_12

            // line 100: for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)






            if ((__for_idx_1 < 2'd2)) begin
                next_state = S_FOR_BODY_13;
            end else begin
                next_state = S_FOR_END_14;
            end

        end

        S_FOR_BODY_13: begin

            // LIR block: for_body_13

            // line 100: for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)




            next_u2_term = __for_idx_1;



            if ((__for_idx_1 == 32'd0)) begin
                next_state = S_IF_THEN_15;
            end else begin
                next_state = S_IF_ELSE_17;
            end

        end

        S_FOR_END_14: begin

            // LIR block: for_end_14

            // line 91: if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)






            next_state = S_IF_END_5;

        end

        S_IF_THEN_15: begin

            // LIR block: if_then_15

            // line 103: u1_far = u1_is_isrc




            next_u1_far = u1_is_isrc;



            next_state = S_IF_END_16;

        end

        S_IF_END_16: begin

            // LIR block: if_end_16

            // line 106: if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)






            if (u1_far) begin
                next_state = S_IF_THEN_18;
            end else begin
                next_state = S_IF_ELSE_20;
            end

        end

        S_IF_ELSE_17: begin

            // LIR block: if_else_17

            // line 105: u1_far = 1 - u1_is_isrc




            next_u1_far = (1'd1 - u1_is_isrc);



            next_state = S_IF_END_16;

        end

        S_IF_THEN_18: begin

            // LIR block: if_then_18

            // line 107: u2_out = u2_dir




            next_u2_out = u2_dir;

            next_u8_term_x = get_nxt_i_comb(u8_anchor_x, u2_dir);

            next_u8_term_y = get_nxt_j_comb(u8_anchor_y, u2_dir);

            next_u8_term_x = get_nxt_i_comb(get_nxt_i_comb(u8_anchor_x, u2_dir), u2_dir);

            next_u8_term_y = get_nxt_j_comb(get_nxt_j_comb(u8_anchor_y, u2_dir), u2_dir);



            next_state = S_IF_END_19;

        end

        S_IF_END_19: begin

            // LIR block: if_end_19

            // line 118: u8_raw = 0




            next_u8_raw = 8'd0;



            if (((((u8_term_x >= 32'd0) && (u8_term_y >= 32'd0)) && (u8_term_x < grid_width)) && (u8_term_y < grid_height))) begin
                next_state = S_IF_THEN_21;
            end else begin
                next_state = S_IF_END_22;
            end

        end

        S_IF_ELSE_20: begin

            // LIR block: if_else_20

            // line 113: u2_out = get_opp_dir_comb(d=u2_dir)




            next_u2_out = get_opp_dir_comb(u2_dir);

            next_u8_term_x = get_nxt_i_comb(u8_anchor_x, get_opp_dir_comb(u2_dir));

            next_u8_term_y = get_nxt_j_comb(u8_anchor_y, get_opp_dir_comb(u2_dir));



            next_state = S_IF_END_19;

        end

        S_IF_THEN_21: begin

            // LIR block: if_then_21

            // line 125: u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)





            fetchCell_i = u8_term_x;

            fetchCell_j = u8_term_y;

            fetchCell_start = 1'b1;


            next_state = S_IF_THEN_21_WAIT;

        end

        S_IF_THEN_21_WAIT: begin

            // LIR block: if_then_21

            // line 125: u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_cell = fetchCell_result;

                next_state = S_AFTER_CALL_23;
            end else begin
                next_state = S_IF_THEN_21_WAIT;
            end

        end

        S_IF_END_22: begin

            // LIR block: if_end_22

            // line 130: u1_is_ground = 0




            next_u1_is_ground = 1'd0;



            if ((u8_raw != 32'd0)) begin
                next_state = S_IF_THEN_27;
            end else begin
                next_state = S_IF_END_28;
            end

        end

        S_AFTER_CALL_23: begin

            // LIR block: after_call_23

            // line 126: if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)






            if (cell_has_port_comb(u16_cell, get_opp_dir_comb(u2_out))) begin
                next_state = S_IF_THEN_24;
            end else begin
                next_state = S_IF_END_25;
            end

        end

        S_IF_THEN_24: begin

            // LIR block: if_then_24

            // line 127: u8_raw = fetchR(i=u8_term_x, j=u8_term_y)





            fetchR_i = u8_term_x;

            fetchR_j = u8_term_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_24_WAIT;

        end

        S_IF_THEN_24_WAIT: begin

            // LIR block: if_then_24

            // line 127: u8_raw = fetchR(i=u8_term_x, j=u8_term_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_raw = fetchR_result;

                next_state = S_AFTER_CALL_26;
            end else begin
                next_state = S_IF_THEN_24_WAIT;
            end

        end

        S_IF_END_25: begin

            // LIR block: if_end_25

            // line 119: if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)






            next_state = S_IF_END_22;

        end

        S_AFTER_CALL_26: begin

            // LIR block: after_call_26

            // line 126: if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)






            next_state = S_IF_END_25;

        end

        S_IF_THEN_27: begin

            // LIR block: if_then_27

            // line 132: for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1




            next___for_idx_2 = 8'd0;



            next_state = S_FOR_HEADER_29;

        end

        S_IF_END_28: begin

            // LIR block: if_end_28

            // line 140: u8_node = 255




            next_u8_node = 8'd255;



            if ((! u1_is_ground)) begin
                next_state = S_IF_THEN_41;
            end else begin
                next_state = S_IF_END_42;
            end

        end

        S_FOR_HEADER_29: begin

            // LIR block: for_header_29

            // line 132: for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1






            if ((__for_idx_2 < grid_height)) begin
                next_state = S_FOR_BODY_30;
            end else begin
                next_state = S_FOR_END_31;
            end

        end

        S_FOR_BODY_30: begin

            // LIR block: for_body_30

            // line 132: for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1




            next_u8_ground_y = __for_idx_2;

            next___for_idx_3 = 8'd0;



            next_state = S_FOR_HEADER_32;

        end

        S_FOR_END_31: begin

            // LIR block: for_end_31

            // line 131: if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1






            next_state = S_IF_END_28;

        end

        S_FOR_HEADER_32: begin

            // LIR block: for_header_32

            // line 133: for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1






            if ((__for_idx_3 < grid_width)) begin
                next_state = S_FOR_BODY_33;
            end else begin
                next_state = S_FOR_END_34;
            end

        end

        S_FOR_BODY_33: begin

            // LIR block: for_body_33

            // line 133: for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1




            next_u8_ground_x = __for_idx_3;


            fetchCell_i = __for_idx_3;

            fetchCell_j = u8_ground_y;

            fetchCell_start = 1'b1;


            next_state = S_FOR_BODY_33_WAIT;

        end

        S_FOR_BODY_33_WAIT: begin

            // LIR block: for_body_33

            // line 133: for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_cell = fetchCell_result;

                next_state = S_AFTER_CALL_35;
            end else begin
                next_state = S_FOR_BODY_33_WAIT;
            end

        end

        S_FOR_END_34: begin

            // LIR block: for_end_34

            // line 132: for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1




            next___for_idx_2 = (__for_idx_2 + 8'd1);



            next_state = S_FOR_HEADER_29;

        end

        S_AFTER_CALL_35: begin

            // LIR block: after_call_35

            // line 135: if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1






            if (is_ground_cell_comb(u16_cell)) begin
                next_state = S_IF_THEN_36;
            end else begin
                next_state = S_IF_END_37;
            end

        end

        S_IF_THEN_36: begin

            // LIR block: if_then_36

            // line 136: u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)





            fetchR_i = u8_ground_x;

            fetchR_j = u8_ground_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_36_WAIT;

        end

        S_IF_THEN_36_WAIT: begin

            // LIR block: if_then_36

            // line 136: u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_ground_region = fetchR_result;

                next_state = S_AFTER_CALL_38;
            end else begin
                next_state = S_IF_THEN_36_WAIT;
            end

        end

        S_IF_END_37: begin

            // LIR block: if_end_37

            // line 133: for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1




            next___for_idx_3 = (__for_idx_3 + 8'd1);



            next_state = S_FOR_HEADER_32;

        end

        S_AFTER_CALL_38: begin

            // LIR block: after_call_38

            // line 137: if u8_ground_region == u8_raw:                                     u1_is_ground = 1






            if ((u8_ground_region == u8_raw)) begin
                next_state = S_IF_THEN_39;
            end else begin
                next_state = S_IF_END_40;
            end

        end

        S_IF_THEN_39: begin

            // LIR block: if_then_39

            // line 138: u1_is_ground = 1




            next_u1_is_ground = 1'd1;



            next_state = S_IF_END_40;

        end

        S_IF_END_40: begin

            // LIR block: if_end_40

            // line 135: if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1






            next_state = S_IF_END_37;

        end

        S_IF_THEN_41: begin

            // LIR block: if_then_41

            // line 144: if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1






            if (((u8_raw != 32'd0) || (! u1_rows_known))) begin
                next_state = S_IF_THEN_43;
            end else begin
                next_state = S_IF_END_44;
            end

        end

        S_IF_END_42: begin

            // LIR block: if_end_42

            // line 208: if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)






            if ((u2_term == 32'd0)) begin
                next_state = S_IF_THEN_108;
            end else begin
                next_state = S_IF_ELSE_110;
            end

        end

        S_IF_THEN_43: begin

            // LIR block: if_then_43

            // line 145: u8_next_node = 0




            next_u8_next_node = 8'd0;

            next___for_idx_4 = 8'd0;



            next_state = S_FOR_HEADER_45;

        end

        S_IF_END_44: begin

            // LIR block: if_end_44

            // line 204: if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1






            if ((u8_raw == 32'd0)) begin
                next_state = S_IF_THEN_106;
            end else begin
                next_state = S_IF_END_107;
            end

        end

        S_FOR_HEADER_45: begin

            // LIR block: for_header_45

            // line 146: for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            if ((__for_idx_4 < grid_height)) begin
                next_state = S_FOR_BODY_46;
            end else begin
                next_state = S_FOR_END_47;
            end

        end

        S_FOR_BODY_46: begin

            // LIR block: for_body_46

            // line 146: for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1




            next_u8_scan_y = __for_idx_4;

            next___for_idx_5 = 8'd0;



            next_state = S_FOR_HEADER_48;

        end

        S_FOR_END_47: begin

            // LIR block: for_end_47

            // line 202: u8_region_rows = u8_next_node




            next_u8_region_rows = u8_next_node;

            next_u1_rows_known = 1'd1;



            next_state = S_IF_END_44;

        end

        S_FOR_HEADER_48: begin

            // LIR block: for_header_48

            // line 147: for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            if ((__for_idx_5 < grid_width)) begin
                next_state = S_FOR_BODY_49;
            end else begin
                next_state = S_FOR_END_50;
            end

        end

        S_FOR_BODY_49: begin

            // LIR block: for_body_49

            // line 147: for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1




            next_u8_scan_x = __for_idx_5;


            fetchR_i = __for_idx_5;

            fetchR_j = u8_scan_y;

            fetchR_start = 1'b1;


            next_state = S_FOR_BODY_49_WAIT;

        end

        S_FOR_BODY_49_WAIT: begin

            // LIR block: for_body_49

            // line 147: for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_region = fetchR_result;

                next_state = S_AFTER_CALL_51;
            end else begin
                next_state = S_FOR_BODY_49_WAIT;
            end

        end

        S_FOR_END_50: begin

            // LIR block: for_end_50

            // line 146: for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1




            next___for_idx_4 = (__for_idx_4 + 8'd1);



            next_state = S_FOR_HEADER_45;

        end

        S_AFTER_CALL_51: begin

            // LIR block: after_call_51

            // line 149: if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            if ((u8_region != 32'd0)) begin
                next_state = S_IF_THEN_52;
            end else begin
                next_state = S_IF_END_53;
            end

        end

        S_IF_THEN_52: begin

            // LIR block: if_then_52

            // line 150: u1_seen = 0




            next_u1_seen = 1'd0;

            next___for_idx_6 = 8'd0;



            next_state = S_FOR_HEADER_54;

        end

        S_IF_END_53: begin

            // LIR block: if_end_53

            // line 147: for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1




            next___for_idx_5 = (__for_idx_5 + 8'd1);



            next_state = S_FOR_HEADER_48;

        end

        S_FOR_HEADER_54: begin

            // LIR block: for_header_54

            // line 151: for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1






            if ((__for_idx_6 < (u8_scan_y + 8'd1))) begin
                next_state = S_FOR_BODY_55;
            end else begin
                next_state = S_FOR_END_56;
            end

        end

        S_FOR_BODY_55: begin

            // LIR block: for_body_55

            // line 151: for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1




            next_u8_prev_y = __for_idx_6;

            next___for_idx_7 = 8'd0;



            next_state = S_FOR_HEADER_57;

        end

        S_FOR_END_56: begin

            // LIR block: for_end_56

            // line 160: if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            if ((! u1_seen)) begin
                next_state = S_IF_THEN_65;
            end else begin
                next_state = S_IF_END_66;
            end

        end

        S_FOR_HEADER_57: begin

            // LIR block: for_header_57

            // line 152: for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1






            if ((__for_idx_7 < grid_width)) begin
                next_state = S_FOR_BODY_58;
            end else begin
                next_state = S_FOR_END_59;
            end

        end

        S_FOR_BODY_58: begin

            // LIR block: for_body_58

            // line 152: for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1




            next_u8_prev_x = __for_idx_7;



            if (((! u1_seen) && ((u8_prev_y < u8_scan_y) || (__for_idx_7 < u8_scan_x)))) begin
                next_state = S_IF_THEN_60;
            end else begin
                next_state = S_IF_END_61;
            end

        end

        S_FOR_END_59: begin

            // LIR block: for_end_59

            // line 151: for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1




            next___for_idx_6 = (__for_idx_6 + 8'd1);



            next_state = S_FOR_HEADER_54;

        end

        S_IF_THEN_60: begin

            // LIR block: if_then_60

            // line 157: u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)





            fetchR_i = u8_prev_x;

            fetchR_j = u8_prev_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_60_WAIT;

        end

        S_IF_THEN_60_WAIT: begin

            // LIR block: if_then_60

            // line 157: u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_prev_region = fetchR_result;

                next_state = S_AFTER_CALL_62;
            end else begin
                next_state = S_IF_THEN_60_WAIT;
            end

        end

        S_IF_END_61: begin

            // LIR block: if_end_61

            // line 152: for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1




            next___for_idx_7 = (__for_idx_7 + 8'd1);



            next_state = S_FOR_HEADER_57;

        end

        S_AFTER_CALL_62: begin

            // LIR block: after_call_62

            // line 158: if u8_prev_region == u8_region:                                                     u1_seen = 1






            if ((u8_prev_region == u8_region)) begin
                next_state = S_IF_THEN_63;
            end else begin
                next_state = S_IF_END_64;
            end

        end

        S_IF_THEN_63: begin

            // LIR block: if_then_63

            // line 159: u1_seen = 1




            next_u1_seen = 1'd1;



            next_state = S_IF_END_64;

        end

        S_IF_END_64: begin

            // LIR block: if_end_64

            // line 153: if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1






            next_state = S_IF_END_61;

        end

        S_IF_THEN_65: begin

            // LIR block: if_then_65

            // line 161: u1_region_is_ground = 0




            next_u1_region_is_ground = 1'd0;

            next___for_idx_8 = 8'd0;



            next_state = S_FOR_HEADER_67;

        end

        S_IF_END_66: begin

            // LIR block: if_end_66

            // line 149: if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            next_state = S_IF_END_53;

        end

        S_FOR_HEADER_67: begin

            // LIR block: for_header_67

            // line 162: for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1






            if ((__for_idx_8 < grid_height)) begin
                next_state = S_FOR_BODY_68;
            end else begin
                next_state = S_FOR_END_69;
            end

        end

        S_FOR_BODY_68: begin

            // LIR block: for_body_68

            // line 162: for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1




            next_u8_ground_y = __for_idx_8;

            next___for_idx_9 = 8'd0;



            next_state = S_FOR_HEADER_70;

        end

        S_FOR_END_69: begin

            // LIR block: for_end_69

            // line 170: u1_touched = 0




            next_u1_touched = 1'd0;

            next___for_idx_10 = 16'd0;



            next_state = S_FOR_HEADER_79;

        end

        S_FOR_HEADER_70: begin

            // LIR block: for_header_70

            // line 163: for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1






            if ((__for_idx_9 < grid_width)) begin
                next_state = S_FOR_BODY_71;
            end else begin
                next_state = S_FOR_END_72;
            end

        end

        S_FOR_BODY_71: begin

            // LIR block: for_body_71

            // line 163: for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1




            next_u8_ground_x = __for_idx_9;


            fetchCell_i = __for_idx_9;

            fetchCell_j = u8_ground_y;

            fetchCell_start = 1'b1;


            next_state = S_FOR_BODY_71_WAIT;

        end

        S_FOR_BODY_71_WAIT: begin

            // LIR block: for_body_71

            // line 163: for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_cell = fetchCell_result;

                next_state = S_AFTER_CALL_73;
            end else begin
                next_state = S_FOR_BODY_71_WAIT;
            end

        end

        S_FOR_END_72: begin

            // LIR block: for_end_72

            // line 162: for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1




            next___for_idx_8 = (__for_idx_8 + 8'd1);



            next_state = S_FOR_HEADER_67;

        end

        S_AFTER_CALL_73: begin

            // LIR block: after_call_73

            // line 165: if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1






            if (is_ground_cell_comb(u16_cell)) begin
                next_state = S_IF_THEN_74;
            end else begin
                next_state = S_IF_END_75;
            end

        end

        S_IF_THEN_74: begin

            // LIR block: if_then_74

            // line 166: u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)





            fetchR_i = u8_ground_x;

            fetchR_j = u8_ground_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_74_WAIT;

        end

        S_IF_THEN_74_WAIT: begin

            // LIR block: if_then_74

            // line 166: u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_ground_region = fetchR_result;

                next_state = S_AFTER_CALL_76;
            end else begin
                next_state = S_IF_THEN_74_WAIT;
            end

        end

        S_IF_END_75: begin

            // LIR block: if_end_75

            // line 163: for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1




            next___for_idx_9 = (__for_idx_9 + 8'd1);



            next_state = S_FOR_HEADER_70;

        end

        S_AFTER_CALL_76: begin

            // LIR block: after_call_76

            // line 167: if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1






            if ((u8_ground_region == u8_region)) begin
                next_state = S_IF_THEN_77;
            end else begin
                next_state = S_IF_END_78;
            end

        end

        S_IF_THEN_77: begin

            // LIR block: if_then_77

            // line 168: u1_region_is_ground = 1




            next_u1_region_is_ground = 1'd1;



            next_state = S_IF_END_78;

        end

        S_IF_END_78: begin

            // LIR block: if_end_78

            // line 165: if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1






            next_state = S_IF_END_75;

        end

        S_FOR_HEADER_79: begin

            // LIR block: for_header_79

            // line 171: for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            if ((__for_idx_10 < par_elem_n)) begin
                next_state = S_FOR_BODY_80;
            end else begin
                next_state = S_FOR_END_81;
            end

        end

        S_FOR_BODY_80: begin

            // LIR block: for_body_80

            // line 171: for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1




            next_u16_touch_idx = __for_idx_10;


            fetchComponentType_idx = __for_idx_10;

            fetchComponentType_start = 1'b1;


            next_state = S_FOR_BODY_80_WAIT;

        end

        S_FOR_BODY_80_WAIT: begin

            // LIR block: for_body_80

            // line 171: for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1

            // wait for blocking primitive: fetchComponentType






            if (fetchComponentType_done) begin

                next_u8_touch_type = fetchComponentType_result;

                next_state = S_AFTER_CALL_82;
            end else begin
                next_state = S_FOR_BODY_80_WAIT;
            end

        end

        S_FOR_END_81: begin

            // LIR block: for_end_81

            // line 198: if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            if (((! u1_region_is_ground) && u1_touched)) begin
                next_state = S_IF_THEN_102;
            end else begin
                next_state = S_IF_END_103;
            end

        end

        S_AFTER_CALL_82: begin

            // LIR block: after_call_82

            // line 173: if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            if (is_two_terminal_component_comb(u8_touch_type)) begin
                next_state = S_IF_THEN_83;
            end else begin
                next_state = S_IF_END_84;
            end

        end

        S_IF_THEN_83: begin

            // LIR block: if_then_83

            // line 174: u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)





            fetchAnchorPositionX_idx = u16_touch_idx;

            fetchAnchorPositionX_start = 1'b1;


            next_state = S_IF_THEN_83_WAIT;

        end

        S_IF_THEN_83_WAIT: begin

            // LIR block: if_then_83

            // line 174: u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)

            // wait for blocking primitive: fetchAnchorPositionX






            if (fetchAnchorPositionX_done) begin

                next_u8_touch_ax = fetchAnchorPositionX_result;

                next_state = S_AFTER_CALL_85;
            end else begin
                next_state = S_IF_THEN_83_WAIT;
            end

        end

        S_IF_END_84: begin

            // LIR block: if_end_84

            // line 171: for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1




            next___for_idx_10 = (__for_idx_10 + 16'd1);



            next_state = S_FOR_HEADER_79;

        end

        S_AFTER_CALL_85: begin

            // LIR block: after_call_85

            // line 175: u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)





            fetchAnchorPositionY_idx = u16_touch_idx;

            fetchAnchorPositionY_start = 1'b1;


            next_state = S_AFTER_CALL_85_WAIT;

        end

        S_AFTER_CALL_85_WAIT: begin

            // LIR block: after_call_85

            // line 175: u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)

            // wait for blocking primitive: fetchAnchorPositionY






            if (fetchAnchorPositionY_done) begin

                next_u8_touch_ay = fetchAnchorPositionY_result;

                next_state = S_AFTER_CALL_86;
            end else begin
                next_state = S_AFTER_CALL_85_WAIT;
            end

        end

        S_AFTER_CALL_86: begin

            // LIR block: after_call_86

            // line 176: u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)





            fetchComponentRotation_idx = u16_touch_idx;

            fetchComponentRotation_start = 1'b1;


            next_state = S_AFTER_CALL_86_WAIT;

        end

        S_AFTER_CALL_86_WAIT: begin

            // LIR block: after_call_86

            // line 176: u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)

            // wait for blocking primitive: fetchComponentRotation






            if (fetchComponentRotation_done) begin

                next_u2_touch_dir = fetchComponentRotation_result;

                next_state = S_AFTER_CALL_87;
            end else begin
                next_state = S_AFTER_CALL_86_WAIT;
            end

        end

        S_AFTER_CALL_87: begin

            // LIR block: after_call_87

            // line 177: u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)




            next_u2_touch_dir = rotation_to_dir_comb(u2_touch_dir);

            next___for_idx_11 = 2'd0;



            next_state = S_FOR_HEADER_88;

        end

        S_FOR_HEADER_88: begin

            // LIR block: for_header_88

            // line 178: for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            if ((__for_idx_11 < 2'd2)) begin
                next_state = S_FOR_BODY_89;
            end else begin
                next_state = S_FOR_END_90;
            end

        end

        S_FOR_BODY_89: begin

            // LIR block: for_body_89

            // line 178: for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1




            next_u2_touch_term = __for_idx_11;



            if ((__for_idx_11 == 32'd0)) begin
                next_state = S_IF_THEN_91;
            end else begin
                next_state = S_IF_ELSE_93;
            end

        end

        S_FOR_END_90: begin

            // LIR block: for_end_90

            // line 173: if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            next_state = S_IF_END_84;

        end

        S_IF_THEN_91: begin

            // LIR block: if_then_91

            // line 180: u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)




            next_u2_touch_out = get_opp_dir_comb(u2_touch_dir);

            next_u8_touch_x = get_nxt_i_comb(u8_touch_ax, get_opp_dir_comb(u2_touch_dir));

            next_u8_touch_y = get_nxt_j_comb(u8_touch_ay, get_opp_dir_comb(u2_touch_dir));



            next_state = S_IF_END_92;

        end

        S_IF_END_92: begin

            // LIR block: if_end_92

            // line 189: if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            if (((((u8_touch_x >= 32'd0) && (u8_touch_y >= 32'd0)) && (u8_touch_x < grid_width)) && (u8_touch_y < grid_height))) begin
                next_state = S_IF_THEN_94;
            end else begin
                next_state = S_IF_END_95;
            end

        end

        S_IF_ELSE_93: begin

            // LIR block: if_else_93

            // line 184: u2_touch_out = u2_touch_dir




            next_u2_touch_out = u2_touch_dir;

            next_u8_touch_x = get_nxt_i_comb(u8_touch_ax, u2_touch_dir);

            next_u8_touch_y = get_nxt_j_comb(u8_touch_ay, u2_touch_dir);

            next_u8_touch_x = get_nxt_i_comb(get_nxt_i_comb(u8_touch_ax, u2_touch_dir), u2_touch_dir);

            next_u8_touch_y = get_nxt_j_comb(get_nxt_j_comb(u8_touch_ay, u2_touch_dir), u2_touch_dir);



            next_state = S_IF_END_92;

        end

        S_IF_THEN_94: begin

            // LIR block: if_then_94

            // line 193: u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)





            fetchCell_i = u8_touch_x;

            fetchCell_j = u8_touch_y;

            fetchCell_start = 1'b1;


            next_state = S_IF_THEN_94_WAIT;

        end

        S_IF_THEN_94_WAIT: begin

            // LIR block: if_then_94

            // line 193: u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_touch_cell = fetchCell_result;

                next_state = S_AFTER_CALL_96;
            end else begin
                next_state = S_IF_THEN_94_WAIT;
            end

        end

        S_IF_END_95: begin

            // LIR block: if_end_95

            // line 178: for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1




            next___for_idx_11 = (__for_idx_11 + 2'd1);



            next_state = S_FOR_HEADER_88;

        end

        S_AFTER_CALL_96: begin

            // LIR block: after_call_96

            // line 194: if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            if (cell_has_port_comb(u16_touch_cell, get_opp_dir_comb(u2_touch_out))) begin
                next_state = S_IF_THEN_97;
            end else begin
                next_state = S_IF_END_98;
            end

        end

        S_IF_THEN_97: begin

            // LIR block: if_then_97

            // line 195: u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)





            fetchR_i = u8_touch_x;

            fetchR_j = u8_touch_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_97_WAIT;

        end

        S_IF_THEN_97_WAIT: begin

            // LIR block: if_then_97

            // line 195: u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_touch_region = fetchR_result;

                next_state = S_AFTER_CALL_99;
            end else begin
                next_state = S_IF_THEN_97_WAIT;
            end

        end

        S_IF_END_98: begin

            // LIR block: if_end_98

            // line 189: if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            next_state = S_IF_END_95;

        end

        S_AFTER_CALL_99: begin

            // LIR block: after_call_99

            // line 196: if u8_touch_region == u8_region:                                                                 u1_touched = 1






            if ((u8_touch_region == u8_region)) begin
                next_state = S_IF_THEN_100;
            end else begin
                next_state = S_IF_END_101;
            end

        end

        S_IF_THEN_100: begin

            // LIR block: if_then_100

            // line 197: u1_touched = 1




            next_u1_touched = 1'd1;



            next_state = S_IF_END_101;

        end

        S_IF_END_101: begin

            // LIR block: if_end_101

            // line 194: if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1






            next_state = S_IF_END_98;

        end

        S_IF_THEN_102: begin

            // LIR block: if_then_102

            // line 199: if u8_region == u8_raw:                                                 u8_node = u8_next_node






            if ((u8_region == u8_raw)) begin
                next_state = S_IF_THEN_104;
            end else begin
                next_state = S_IF_END_105;
            end

        end

        S_IF_END_103: begin

            // LIR block: if_end_103

            // line 160: if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1






            next_state = S_IF_END_66;

        end

        S_IF_THEN_104: begin

            // LIR block: if_then_104

            // line 200: u8_node = u8_next_node




            next_u8_node = u8_next_node;



            next_state = S_IF_END_105;

        end

        S_IF_END_105: begin

            // LIR block: if_end_105

            // line 201: u8_next_node = u8_next_node + 1




            next_u8_next_node = (u8_next_node + 8'd1);



            next_state = S_IF_END_103;

        end

        S_IF_THEN_106: begin

            // LIR block: if_then_106

            // line 205: u8_node = u8_region_rows + u8_next_float




            next_u8_node = (u8_region_rows + u8_next_float);

            next_u8_next_float = (u8_next_float + 8'd1);



            next_state = S_IF_END_107;

        end

        S_IF_END_107: begin

            // LIR block: if_end_107

            // line 141: if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1






            next_state = S_IF_END_42;

        end

        S_IF_THEN_108: begin

            // LIR block: if_then_108

            // line 209: storeNode0(idx=u16_idx, node_i=u8_node)





            storeNode0_idx = u16_idx;

            storeNode0_node_i = u8_node;

            storeNode0_start = 1'b1;


            next_state = S_IF_THEN_108_WAIT;

        end

        S_IF_THEN_108_WAIT: begin

            // LIR block: if_then_108

            // line 209: storeNode0(idx=u16_idx, node_i=u8_node)

            // wait for blocking primitive: storeNode0






            if (storeNode0_done) begin

                next_state = S_AFTER_CALL_111;
            end else begin
                next_state = S_IF_THEN_108_WAIT;
            end

        end

        S_IF_END_109: begin

            // LIR block: if_end_109

            // line 100: for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)




            next___for_idx_1 = (__for_idx_1 + 2'd1);



            next_state = S_FOR_HEADER_12;

        end

        S_IF_ELSE_110: begin

            // LIR block: if_else_110

            // line 211: storeNode1(idx=u16_idx, node_i=u8_node)





            storeNode1_idx = u16_idx;

            storeNode1_node_i = u8_node;

            storeNode1_start = 1'b1;


            next_state = S_IF_ELSE_110_WAIT;

        end

        S_IF_ELSE_110_WAIT: begin

            // LIR block: if_else_110

            // line 211: storeNode1(idx=u16_idx, node_i=u8_node)

            // wait for blocking primitive: storeNode1






            if (storeNode1_done) begin

                next_state = S_AFTER_CALL_112;
            end else begin
                next_state = S_IF_ELSE_110_WAIT;
            end

        end

        S_AFTER_CALL_111: begin

            // LIR block: after_call_111

            // line 208: if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)






            next_state = S_IF_END_109;

        end

        S_AFTER_CALL_112: begin

            // LIR block: after_call_112

            // line 208: if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)






            next_state = S_IF_END_109;

        end

        S_AFTER_CALL_113: begin

            // LIR block: after_call_113

            // line 215: storeNode1(idx=u16_idx, node_i=u8_node)





            storeNode1_idx = u16_idx;

            storeNode1_node_i = u8_node;

            storeNode1_start = 1'b1;


            next_state = S_AFTER_CALL_113_WAIT;

        end

        S_AFTER_CALL_113_WAIT: begin

            // LIR block: after_call_113

            // line 215: storeNode1(idx=u16_idx, node_i=u8_node)

            // wait for blocking primitive: storeNode1






            if (storeNode1_done) begin

                next_state = S_AFTER_CALL_114;
            end else begin
                next_state = S_AFTER_CALL_113_WAIT;
            end

        end

        S_AFTER_CALL_114: begin

            // LIR block: after_call_114

            // line 91: if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_dir = fetchComponentRotation(idx=u16_idx)             u2_dir = rotation_to_dir_comb(rot=u2_dir)             u1_is_isrc = 0             if is_current_source_comb(t=u8_type):                 u1_is_isrc = 1              for u2_term in range(2):                 # u1_far: this terminal is the one beyond the partner half.                 if u2_term == 0:                     u1_far = u1_is_isrc                 else:                     u1_far = 1 - u1_is_isrc                 if u1_far:                     u2_out = u2_dir                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_term_x, d=u2_dir)                     u8_term_y = get_nxt_j_comb(j=u8_term_y, d=u2_dir)                 else:                     u2_out = get_opp_dir_comb(d=u2_dir)                     u8_term_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_out)                     u8_term_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_out)                  # Raw region through a facing port, or 0 (floating).                 u8_raw = 0                 if (                     u8_term_x >= 0                     and u8_term_y >= 0                     and u8_term_x < grid_width                     and u8_term_y < grid_height                 ):                     u16_cell = fetchCell(i=u8_term_x, j=u8_term_y)                     if cell_has_port_comb(cell=u16_cell, d=get_opp_dir_comb(d=u2_out)):                         u8_raw = fetchR(i=u8_term_x, j=u8_term_y)                  # Is the terminal's region grounded?                 u1_is_ground = 0                 if u8_raw != 0:                     for u8_ground_y in range(grid_height):                         for u8_ground_x in range(grid_width):                             u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                             if is_ground_cell_comb(cell=u16_cell):                                 u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                 if u8_ground_region == u8_raw:                                     u1_is_ground = 1                  u8_node = 255                 if not u1_is_ground:                     # Row of the terminal's region; the same scan counts all                     # region rows, which a floating terminal needs.                     if u8_raw != 0 or not u1_rows_known:                         u8_next_node = 0                         for u8_scan_y in range(grid_height):                             for u8_scan_x in range(grid_width):                                 u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                                 if u8_region != 0:                                     u1_seen = 0                                     for u8_prev_y in range(u8_scan_y + 1):                                         for u8_prev_x in range(grid_width):                                             if not u1_seen and (                                                 u8_prev_y < u8_scan_y                                                 or u8_prev_x < u8_scan_x                                             ):                                                 u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                                 if u8_prev_region == u8_region:                                                     u1_seen = 1                                     if not u1_seen:                                         u1_region_is_ground = 0                                         for u8_ground_y in range(grid_height):                                             for u8_ground_x in range(grid_width):                                                 u16_cell = fetchCell(i=u8_ground_x, j=u8_ground_y)                                                 if is_ground_cell_comb(cell=u16_cell):                                                     u8_ground_region = fetchR(i=u8_ground_x, j=u8_ground_y)                                                     if u8_ground_region == u8_region:                                                         u1_region_is_ground = 1                                         # D-023: wire islands have colours, but no solver row.                                         u1_touched = 0                                         for u16_touch_idx in range(par_elem_n):                                             u8_touch_type = fetchComponentType(idx=u16_touch_idx)                                             if is_two_terminal_component_comb(t=u8_touch_type):                                                 u8_touch_ax = fetchAnchorPositionX(idx=u16_touch_idx)                                                 u8_touch_ay = fetchAnchorPositionY(idx=u16_touch_idx)                                                 u2_touch_dir = fetchComponentRotation(idx=u16_touch_idx)                                                 u2_touch_dir = rotation_to_dir_comb(rot=u2_touch_dir)                                                 for u2_touch_term in range(2):                                                     if u2_touch_term == 0:                                                         u2_touch_out = get_opp_dir_comb(d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_out)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_out)                                                     else:                                                         u2_touch_out = u2_touch_dir                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_ax, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_ay, d=u2_touch_dir)                                                         u8_touch_x = get_nxt_i_comb(i=u8_touch_x, d=u2_touch_dir)                                                         u8_touch_y = get_nxt_j_comb(j=u8_touch_y, d=u2_touch_dir)                                                     if (                                                         u8_touch_x >= 0 and u8_touch_y >= 0                                                         and u8_touch_x < grid_width and u8_touch_y < grid_height                                                     ):                                                         u16_touch_cell = fetchCell(i=u8_touch_x, j=u8_touch_y)                                                         if cell_has_port_comb(cell=u16_touch_cell, d=get_opp_dir_comb(d=u2_touch_out)):                                                             u8_touch_region = fetchR(i=u8_touch_x, j=u8_touch_y)                                                             if u8_touch_region == u8_region:                                                                 u1_touched = 1                                         if not u1_region_is_ground and u1_touched:                                             if u8_region == u8_raw:                                                 u8_node = u8_next_node                                             u8_next_node = u8_next_node + 1                         u8_region_rows = u8_next_node                         u1_rows_known = 1                     if u8_raw == 0:                         u8_node = u8_region_rows + u8_next_float                         u8_next_float = u8_next_float + 1                  if u2_term == 0:                     storeNode0(idx=u16_idx, node_i=u8_node)                 else:                     storeNode1(idx=u16_idx, node_i=u8_node)         else:             u8_node = 255             storeNode0(idx=u16_idx, node_i=u8_node)             storeNode1(idx=u16_idx, node_i=u8_node)






            next_state = S_IF_END_5;

        end

        S_DONE: begin

            // FSM done state

            // Pulse done until start deasserts



            busy = 1'b0;
            done = 1'b1;




            if (!start) begin
                next_state = S_IDLE;
            end else begin
                next_state = S_DONE;
            end

        end

        default: begin
            next_state = S_IDLE;
        end
    endcase
end

endmodule