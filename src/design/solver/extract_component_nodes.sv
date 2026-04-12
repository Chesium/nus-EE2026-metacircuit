
// Generated from LIR for function extract_component_nodes

// Entry block: entry

// Blocking primitives: fetchComponentType(latency=1), fetchAnchorPositionX(latency=1), storeNode0(latency=1), fetchAnchorPositionY(latency=1), fetchComponentRotation(latency=1), fetchR(latency=1), fetchCell(latency=1), storeNode1(latency=1)

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

    output logic fetchR_start,

    output logic [7:0] fetchR_i,

    output logic [7:0] fetchR_j,

    input logic fetchR_done,

    input logic [7:0] fetchR_result,

    output logic fetchCell_start,

    output logic [7:0] fetchCell_i,

    output logic [7:0] fetchCell_j,

    input logic fetchCell_done,

    input logic [15:0] fetchCell_result,

    output logic storeNode1_start,

    output logic [15:0] storeNode1_idx,

    output logic [7:0] storeNode1_node_i,

    input logic storeNode1_done

);

import ExtractComponentNodesCombPkg::*;

typedef enum logic [6:0] {

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

    S_IF_END_5_WAIT,

    S_AFTER_CALL_6,

    S_AFTER_CALL_6_WAIT,

    S_AFTER_CALL_7,

    S_AFTER_CALL_7_WAIT,

    S_AFTER_CALL_8,

    S_IF_THEN_9,

    S_IF_THEN_9_WAIT,

    S_IF_END_10,

    S_AFTER_CALL_11,

    S_IF_THEN_12,

    S_IF_THEN_12_WAIT,

    S_IF_END_13,

    S_AFTER_CALL_14,

    S_IF_THEN_15,

    S_IF_END_16,

    S_FOR_HEADER_17,

    S_FOR_BODY_18,

    S_FOR_END_19,

    S_FOR_HEADER_20,

    S_FOR_BODY_21,

    S_FOR_BODY_21_WAIT,

    S_FOR_END_22,

    S_AFTER_CALL_23,

    S_IF_THEN_24,

    S_IF_END_25,

    S_IF_THEN_26,

    S_IF_THEN_26_WAIT,

    S_IF_END_27,

    S_AFTER_CALL_28,

    S_IF_THEN_29,

    S_IF_END_30,

    S_IF_THEN_31,

    S_IF_END_32,

    S_IF_ELSE_33,

    S_IF_THEN_34,

    S_IF_END_35,

    S_FOR_HEADER_36,

    S_FOR_BODY_37,

    S_FOR_END_38,

    S_FOR_HEADER_39,

    S_FOR_BODY_40,

    S_FOR_BODY_40_WAIT,

    S_FOR_END_41,

    S_AFTER_CALL_42,

    S_IF_THEN_43,

    S_IF_END_44,

    S_IF_THEN_45,

    S_IF_THEN_45_WAIT,

    S_IF_END_46,

    S_AFTER_CALL_47,

    S_IF_THEN_48,

    S_IF_END_49,

    S_IF_THEN_50,

    S_IF_END_51,

    S_IF_ELSE_52,

    S_IF_THEN_53,

    S_IF_END_54,

    S_FOR_HEADER_55,

    S_FOR_BODY_56,

    S_FOR_END_57,

    S_FOR_HEADER_58,

    S_FOR_BODY_59,

    S_FOR_BODY_59_WAIT,

    S_FOR_END_60,

    S_AFTER_CALL_61,

    S_IF_THEN_62,

    S_IF_END_63,

    S_FOR_HEADER_64,

    S_FOR_BODY_65,

    S_FOR_END_66,

    S_FOR_HEADER_67,

    S_FOR_BODY_68,

    S_FOR_BODY_68_WAIT,

    S_FOR_END_69,

    S_AFTER_CALL_70,

    S_IF_THEN_71,

    S_IF_END_72,

    S_IF_THEN_73,

    S_IF_THEN_73_WAIT,

    S_IF_END_74,

    S_AFTER_CALL_75,

    S_IF_THEN_76,

    S_IF_END_77,

    S_IF_THEN_78,

    S_IF_END_79,

    S_FOR_HEADER_80,

    S_FOR_BODY_81,

    S_FOR_END_82,

    S_FOR_HEADER_83,

    S_FOR_BODY_84,

    S_FOR_END_85,

    S_IF_THEN_86,

    S_IF_THEN_86_WAIT,

    S_IF_END_87,

    S_AFTER_CALL_88,

    S_IF_THEN_89,

    S_IF_END_90,

    S_IF_THEN_91,

    S_IF_END_92,

    S_IF_THEN_93,

    S_IF_END_94,

    S_IF_THEN_95,

    S_IF_END_96,

    S_AFTER_CALL_97,

    S_AFTER_CALL_97_WAIT,

    S_AFTER_CALL_98,

    S_DONE

} state_t;

state_t state;
state_t next_state;


logic [15:0] u16_idx;

logic [7:0] u8_type;

logic [7:0] u8_anchor_x;

logic [7:0] u8_anchor_y;

logic [1:0] u2_rot;

logic [1:0] u2_dir0;

logic [7:0] u8_term0_x;

logic [7:0] u8_term0_y;

logic [7:0] u8_term1_x;

logic [7:0] u8_term1_y;

logic [7:0] u8_raw0;

logic [7:0] u8_raw1;

logic [7:0] u8_node0;

logic [7:0] u8_node1;

logic [7:0] u8_next_node;

logic [7:0] u8_scan_x;

logic [7:0] u8_scan_y;

logic [7:0] u8_prev_x;

logic [7:0] u8_prev_y;

logic [7:0] u8_region;

logic [7:0] u8_prev_region;

logic [15:0] u16_ground_cell;

logic [1:0] u2_ground_rot;

logic [7:0] u8_ground_term_x;

logic [7:0] u8_ground_term_y;

logic [7:0] u8_ground_region;

logic u1_need0;

logic u1_need1;

logic u1_seen;

logic u1_raw0_is_ground;

logic u1_raw1_is_ground;

logic u1_region_is_ground;


logic [15:0] __for_idx_0;

logic [7:0] __for_idx_1;

logic [7:0] __for_idx_2;

logic [7:0] __for_idx_3;

logic [7:0] __for_idx_4;

logic [7:0] __for_idx_5;

logic [7:0] __for_idx_6;

logic [7:0] __for_idx_7;

logic [7:0] __for_idx_8;

logic [7:0] __for_idx_9;

logic [7:0] __for_idx_10;



logic [15:0] next_u16_idx;

logic [7:0] next_u8_type;

logic [7:0] next_u8_anchor_x;

logic [7:0] next_u8_anchor_y;

logic [1:0] next_u2_rot;

logic [1:0] next_u2_dir0;

logic [7:0] next_u8_term0_x;

logic [7:0] next_u8_term0_y;

logic [7:0] next_u8_term1_x;

logic [7:0] next_u8_term1_y;

logic [7:0] next_u8_raw0;

logic [7:0] next_u8_raw1;

logic [7:0] next_u8_node0;

logic [7:0] next_u8_node1;

logic [7:0] next_u8_next_node;

logic [7:0] next_u8_scan_x;

logic [7:0] next_u8_scan_y;

logic [7:0] next_u8_prev_x;

logic [7:0] next_u8_prev_y;

logic [7:0] next_u8_region;

logic [7:0] next_u8_prev_region;

logic [15:0] next_u16_ground_cell;

logic [1:0] next_u2_ground_rot;

logic [7:0] next_u8_ground_term_x;

logic [7:0] next_u8_ground_term_y;

logic [7:0] next_u8_ground_region;

logic next_u1_need0;

logic next_u1_need1;

logic next_u1_seen;

logic next_u1_raw0_is_ground;

logic next_u1_raw1_is_ground;

logic next_u1_region_is_ground;

logic [15:0] next___for_idx_0;

logic [7:0] next___for_idx_1;

logic [7:0] next___for_idx_2;

logic [7:0] next___for_idx_3;

logic [7:0] next___for_idx_4;

logic [7:0] next___for_idx_5;

logic [7:0] next___for_idx_6;

logic [7:0] next___for_idx_7;

logic [7:0] next___for_idx_8;

logic [7:0] next___for_idx_9;

logic [7:0] next___for_idx_10;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        u16_idx <=0;

        u8_type <=0;

        u8_anchor_x <=0;

        u8_anchor_y <=0;

        u2_rot <=0;

        u2_dir0 <=0;

        u8_term0_x <=0;

        u8_term0_y <=0;

        u8_term1_x <=0;

        u8_term1_y <=0;

        u8_raw0 <=0;

        u8_raw1 <=0;

        u8_node0 <=0;

        u8_node1 <=0;

        u8_next_node <=0;

        u8_scan_x <=0;

        u8_scan_y <=0;

        u8_prev_x <=0;

        u8_prev_y <=0;

        u8_region <=0;

        u8_prev_region <=0;

        u16_ground_cell <=0;

        u2_ground_rot <=0;

        u8_ground_term_x <=0;

        u8_ground_term_y <=0;

        u8_ground_region <=0;

        u1_need0 <=0;

        u1_need1 <=0;

        u1_seen <=0;

        u1_raw0_is_ground <=0;

        u1_raw1_is_ground <=0;

        u1_region_is_ground <=0;


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


    end else begin
        state <= next_state;

        u16_idx <= next_u16_idx;

        u8_type <= next_u8_type;

        u8_anchor_x <= next_u8_anchor_x;

        u8_anchor_y <= next_u8_anchor_y;

        u2_rot <= next_u2_rot;

        u2_dir0 <= next_u2_dir0;

        u8_term0_x <= next_u8_term0_x;

        u8_term0_y <= next_u8_term0_y;

        u8_term1_x <= next_u8_term1_x;

        u8_term1_y <= next_u8_term1_y;

        u8_raw0 <= next_u8_raw0;

        u8_raw1 <= next_u8_raw1;

        u8_node0 <= next_u8_node0;

        u8_node1 <= next_u8_node1;

        u8_next_node <= next_u8_next_node;

        u8_scan_x <= next_u8_scan_x;

        u8_scan_y <= next_u8_scan_y;

        u8_prev_x <= next_u8_prev_x;

        u8_prev_y <= next_u8_prev_y;

        u8_region <= next_u8_region;

        u8_prev_region <= next_u8_prev_region;

        u16_ground_cell <= next_u16_ground_cell;

        u2_ground_rot <= next_u2_ground_rot;

        u8_ground_term_x <= next_u8_ground_term_x;

        u8_ground_term_y <= next_u8_ground_term_y;

        u8_ground_region <= next_u8_ground_region;

        u1_need0 <= next_u1_need0;

        u1_need1 <= next_u1_need1;

        u1_seen <= next_u1_seen;

        u1_raw0_is_ground <= next_u1_raw0_is_ground;

        u1_raw1_is_ground <= next_u1_raw1_is_ground;

        u1_region_is_ground <= next_u1_region_is_ground;


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

    next_u2_rot = u2_rot;

    next_u2_dir0 = u2_dir0;

    next_u8_term0_x = u8_term0_x;

    next_u8_term0_y = u8_term0_y;

    next_u8_term1_x = u8_term1_x;

    next_u8_term1_y = u8_term1_y;

    next_u8_raw0 = u8_raw0;

    next_u8_raw1 = u8_raw1;

    next_u8_node0 = u8_node0;

    next_u8_node1 = u8_node1;

    next_u8_next_node = u8_next_node;

    next_u8_scan_x = u8_scan_x;

    next_u8_scan_y = u8_scan_y;

    next_u8_prev_x = u8_prev_x;

    next_u8_prev_y = u8_prev_y;

    next_u8_region = u8_region;

    next_u8_prev_region = u8_prev_region;

    next_u16_ground_cell = u16_ground_cell;

    next_u2_ground_rot = u2_ground_rot;

    next_u8_ground_term_x = u8_ground_term_x;

    next_u8_ground_term_y = u8_ground_term_y;

    next_u8_ground_region = u8_ground_region;

    next_u1_need0 = u1_need0;

    next_u1_need1 = u1_need1;

    next_u1_seen = u1_seen;

    next_u1_raw0_is_ground = u1_raw0_is_ground;

    next_u1_raw1_is_ground = u1_raw1_is_ground;

    next_u1_region_is_ground = u1_region_is_ground;


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

    fetchR_start =0;

    fetchR_i =0;

    fetchR_j =0;

    fetchCell_start =0;

    fetchCell_i =0;

    fetchCell_j =0;

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

            // line 22: u16_idx = 0




            next_u16_idx = 16'd0;

            next_u8_type = 8'd0;

            next_u8_anchor_x = 8'd0;

            next_u8_anchor_y = 8'd0;

            next_u2_rot = 2'd0;

            next_u2_dir0 = 2'd0;

            next_u8_term0_x = 8'd0;

            next_u8_term0_y = 8'd0;

            next_u8_term1_x = 8'd0;

            next_u8_term1_y = 8'd0;

            next_u8_raw0 = 8'd0;

            next_u8_raw1 = 8'd0;

            next_u8_node0 = 8'd255;

            next_u8_node1 = 8'd255;

            next_u8_next_node = 8'd0;

            next_u8_scan_x = 8'd0;

            next_u8_scan_y = 8'd0;

            next_u8_prev_x = 8'd0;

            next_u8_prev_y = 8'd0;

            next_u8_region = 8'd0;

            next_u8_prev_region = 8'd0;

            next_u16_ground_cell = 16'd0;

            next_u2_ground_rot = 2'd0;

            next_u8_ground_term_x = 8'd0;

            next_u8_ground_term_y = 8'd0;

            next_u8_ground_region = 8'd0;

            next_u1_need0 = 1'd0;

            next_u1_need1 = 1'd0;

            next_u1_seen = 1'd0;

            next_u1_raw0_is_ground = 1'd0;

            next_u1_raw1_is_ground = 1'd0;

            next_u1_region_is_ground = 1'd0;

            next___for_idx_0 = 16'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 55: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)         u8_node0 = 255         u8_node1 = 255         u8_raw0 = 0         u8_raw1 = 0         u1_need0 = 0         u1_need1 = 0         u1_raw0_is_ground = 0         u1_raw1_is_ground = 0          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_rot = fetchComponentRotation(idx=u16_idx)              u2_dir0 = get_opp_dir_comb(d=u2_rot)             u8_term0_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir0)             u8_term0_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir0)             if u8_term0_x < grid_width and u8_term0_y < grid_height:                 u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)              u8_term1_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_rot)             u8_term1_x = get_nxt_i_comb(i=u8_term1_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_term1_y, d=u2_rot)             if u8_term1_x < grid_width and u8_term1_y < grid_height:                 u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)              if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1              if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1              if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1          storeNode0(idx=u16_idx, node_i=u8_node0)         storeNode1(idx=u16_idx, node_i=u8_node1)






            if ((__for_idx_0 < par_elem_n)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 55: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)         u8_node0 = 255         u8_node1 = 255         u8_raw0 = 0         u8_raw1 = 0         u1_need0 = 0         u1_need1 = 0         u1_raw0_is_ground = 0         u1_raw1_is_ground = 0          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_rot = fetchComponentRotation(idx=u16_idx)              u2_dir0 = get_opp_dir_comb(d=u2_rot)             u8_term0_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir0)             u8_term0_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir0)             if u8_term0_x < grid_width and u8_term0_y < grid_height:                 u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)              u8_term1_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_rot)             u8_term1_x = get_nxt_i_comb(i=u8_term1_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_term1_y, d=u2_rot)             if u8_term1_x < grid_width and u8_term1_y < grid_height:                 u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)              if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1              if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1              if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1          storeNode0(idx=u16_idx, node_i=u8_node0)         storeNode1(idx=u16_idx, node_i=u8_node1)




            next_u16_idx = __for_idx_0;


            fetchComponentType_idx = __for_idx_0;

            fetchComponentType_start = 1'b1;


            next_state = S_FOR_BODY_1_WAIT;

        end

        S_FOR_BODY_1_WAIT: begin

            // LIR block: for_body_1

            // line 55: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)         u8_node0 = 255         u8_node1 = 255         u8_raw0 = 0         u8_raw1 = 0         u1_need0 = 0         u1_need1 = 0         u1_raw0_is_ground = 0         u1_raw1_is_ground = 0          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_rot = fetchComponentRotation(idx=u16_idx)              u2_dir0 = get_opp_dir_comb(d=u2_rot)             u8_term0_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir0)             u8_term0_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir0)             if u8_term0_x < grid_width and u8_term0_y < grid_height:                 u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)              u8_term1_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_rot)             u8_term1_x = get_nxt_i_comb(i=u8_term1_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_term1_y, d=u2_rot)             if u8_term1_x < grid_width and u8_term1_y < grid_height:                 u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)              if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1              if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1              if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1          storeNode0(idx=u16_idx, node_i=u8_node0)         storeNode1(idx=u16_idx, node_i=u8_node1)

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

            // line 57: u8_node0 = 255




            next_u8_node0 = 8'd255;

            next_u8_node1 = 8'd255;

            next_u8_raw0 = 8'd0;

            next_u8_raw1 = 8'd0;

            next_u1_need0 = 1'd0;

            next_u1_need1 = 1'd0;

            next_u1_raw0_is_ground = 1'd0;

            next_u1_raw1_is_ground = 1'd0;



            if (is_two_terminal_component_comb(u8_type)) begin
                next_state = S_IF_THEN_4;
            end else begin
                next_state = S_IF_END_5;
            end

        end

        S_IF_THEN_4: begin

            // LIR block: if_then_4

            // line 67: u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)





            fetchAnchorPositionX_idx = u16_idx;

            fetchAnchorPositionX_start = 1'b1;


            next_state = S_IF_THEN_4_WAIT;

        end

        S_IF_THEN_4_WAIT: begin

            // LIR block: if_then_4

            // line 67: u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)

            // wait for blocking primitive: fetchAnchorPositionX






            if (fetchAnchorPositionX_done) begin

                next_u8_anchor_x = fetchAnchorPositionX_result;

                next_state = S_AFTER_CALL_6;
            end else begin
                next_state = S_IF_THEN_4_WAIT;
            end

        end

        S_IF_END_5: begin

            // LIR block: if_end_5

            // line 159: storeNode0(idx=u16_idx, node_i=u8_node0)





            storeNode0_idx = u16_idx;

            storeNode0_node_i = u8_node0;

            storeNode0_start = 1'b1;


            next_state = S_IF_END_5_WAIT;

        end

        S_IF_END_5_WAIT: begin

            // LIR block: if_end_5

            // line 159: storeNode0(idx=u16_idx, node_i=u8_node0)

            // wait for blocking primitive: storeNode0






            if (storeNode0_done) begin

                next_state = S_AFTER_CALL_97;
            end else begin
                next_state = S_IF_END_5_WAIT;
            end

        end

        S_AFTER_CALL_6: begin

            // LIR block: after_call_6

            // line 68: u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)





            fetchAnchorPositionY_idx = u16_idx;

            fetchAnchorPositionY_start = 1'b1;


            next_state = S_AFTER_CALL_6_WAIT;

        end

        S_AFTER_CALL_6_WAIT: begin

            // LIR block: after_call_6

            // line 68: u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)

            // wait for blocking primitive: fetchAnchorPositionY






            if (fetchAnchorPositionY_done) begin

                next_u8_anchor_y = fetchAnchorPositionY_result;

                next_state = S_AFTER_CALL_7;
            end else begin
                next_state = S_AFTER_CALL_6_WAIT;
            end

        end

        S_AFTER_CALL_7: begin

            // LIR block: after_call_7

            // line 69: u2_rot = fetchComponentRotation(idx=u16_idx)





            fetchComponentRotation_idx = u16_idx;

            fetchComponentRotation_start = 1'b1;


            next_state = S_AFTER_CALL_7_WAIT;

        end

        S_AFTER_CALL_7_WAIT: begin

            // LIR block: after_call_7

            // line 69: u2_rot = fetchComponentRotation(idx=u16_idx)

            // wait for blocking primitive: fetchComponentRotation






            if (fetchComponentRotation_done) begin

                next_u2_rot = fetchComponentRotation_result;

                next_state = S_AFTER_CALL_8;
            end else begin
                next_state = S_AFTER_CALL_7_WAIT;
            end

        end

        S_AFTER_CALL_8: begin

            // LIR block: after_call_8

            // line 71: u2_dir0 = get_opp_dir_comb(d=u2_rot)




            next_u2_dir0 = get_opp_dir_comb(u2_rot);

            next_u8_term0_x = get_nxt_i_comb(u8_anchor_x, get_opp_dir_comb(u2_rot));

            next_u8_term0_y = get_nxt_j_comb(u8_anchor_y, get_opp_dir_comb(u2_rot));



            if (((get_nxt_i_comb(u8_anchor_x, get_opp_dir_comb(u2_rot)) < grid_width) && (get_nxt_j_comb(u8_anchor_y, get_opp_dir_comb(u2_rot)) < grid_height))) begin
                next_state = S_IF_THEN_9;
            end else begin
                next_state = S_IF_END_10;
            end

        end

        S_IF_THEN_9: begin

            // LIR block: if_then_9

            // line 75: u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)





            fetchR_i = u8_term0_x;

            fetchR_j = u8_term0_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_9_WAIT;

        end

        S_IF_THEN_9_WAIT: begin

            // LIR block: if_then_9

            // line 75: u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_raw0 = fetchR_result;

                next_state = S_AFTER_CALL_11;
            end else begin
                next_state = S_IF_THEN_9_WAIT;
            end

        end

        S_IF_END_10: begin

            // LIR block: if_end_10

            // line 77: u8_term1_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_rot)




            next_u8_term1_x = get_nxt_i_comb(u8_anchor_x, u2_rot);

            next_u8_term1_y = get_nxt_j_comb(u8_anchor_y, u2_rot);

            next_u8_term1_x = get_nxt_i_comb(get_nxt_i_comb(u8_anchor_x, u2_rot), u2_rot);

            next_u8_term1_y = get_nxt_j_comb(get_nxt_j_comb(u8_anchor_y, u2_rot), u2_rot);



            if (((get_nxt_i_comb(get_nxt_i_comb(u8_anchor_x, u2_rot), u2_rot) < grid_width) && (get_nxt_j_comb(get_nxt_j_comb(u8_anchor_y, u2_rot), u2_rot) < grid_height))) begin
                next_state = S_IF_THEN_12;
            end else begin
                next_state = S_IF_END_13;
            end

        end

        S_AFTER_CALL_11: begin

            // LIR block: after_call_11

            // line 74: if u8_term0_x < grid_width and u8_term0_y < grid_height:                 u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)






            next_state = S_IF_END_10;

        end

        S_IF_THEN_12: begin

            // LIR block: if_then_12

            // line 82: u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)





            fetchR_i = u8_term1_x;

            fetchR_j = u8_term1_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_12_WAIT;

        end

        S_IF_THEN_12_WAIT: begin

            // LIR block: if_then_12

            // line 82: u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_raw1 = fetchR_result;

                next_state = S_AFTER_CALL_14;
            end else begin
                next_state = S_IF_THEN_12_WAIT;
            end

        end

        S_IF_END_13: begin

            // LIR block: if_end_13

            // line 84: if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1






            if ((u8_raw0 != 32'd0)) begin
                next_state = S_IF_THEN_15;
            end else begin
                next_state = S_IF_END_16;
            end

        end

        S_AFTER_CALL_14: begin

            // LIR block: after_call_14

            // line 81: if u8_term1_x < grid_width and u8_term1_y < grid_height:                 u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)






            next_state = S_IF_END_13;

        end

        S_IF_THEN_15: begin

            // LIR block: if_then_15

            // line 85: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1




            next___for_idx_1 = 8'd0;



            next_state = S_FOR_HEADER_17;

        end

        S_IF_END_16: begin

            // LIR block: if_end_16

            // line 101: if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1






            if ((u8_raw1 != 32'd0)) begin
                next_state = S_IF_THEN_34;
            end else begin
                next_state = S_IF_END_35;
            end

        end

        S_FOR_HEADER_17: begin

            // LIR block: for_header_17

            // line 85: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1






            if ((__for_idx_1 < grid_height)) begin
                next_state = S_FOR_BODY_18;
            end else begin
                next_state = S_FOR_END_19;
            end

        end

        S_FOR_BODY_18: begin

            // LIR block: for_body_18

            // line 85: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1




            next_u8_scan_y = __for_idx_1;

            next___for_idx_2 = 8'd0;



            next_state = S_FOR_HEADER_20;

        end

        S_FOR_END_19: begin

            // LIR block: for_end_19

            // line 96: if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1






            if (u1_raw0_is_ground) begin
                next_state = S_IF_THEN_31;
            end else begin
                next_state = S_IF_ELSE_33;
            end

        end

        S_FOR_HEADER_20: begin

            // LIR block: for_header_20

            // line 86: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1






            if ((__for_idx_2 < grid_width)) begin
                next_state = S_FOR_BODY_21;
            end else begin
                next_state = S_FOR_END_22;
            end

        end

        S_FOR_BODY_21: begin

            // LIR block: for_body_21

            // line 86: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1




            next_u8_scan_x = __for_idx_2;


            fetchCell_i = __for_idx_2;

            fetchCell_j = u8_scan_y;

            fetchCell_start = 1'b1;


            next_state = S_FOR_BODY_21_WAIT;

        end

        S_FOR_BODY_21_WAIT: begin

            // LIR block: for_body_21

            // line 86: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_ground_cell = fetchCell_result;

                next_state = S_AFTER_CALL_23;
            end else begin
                next_state = S_FOR_BODY_21_WAIT;
            end

        end

        S_FOR_END_22: begin

            // LIR block: for_end_22

            // line 85: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1




            next___for_idx_1 = (__for_idx_1 + 8'd1);



            next_state = S_FOR_HEADER_17;

        end

        S_AFTER_CALL_23: begin

            // LIR block: after_call_23

            // line 88: if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1






            if (is_ground_cell_comb(u16_ground_cell)) begin
                next_state = S_IF_THEN_24;
            end else begin
                next_state = S_IF_END_25;
            end

        end

        S_IF_THEN_24: begin

            // LIR block: if_then_24

            // line 89: u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)




            next_u2_ground_rot = get_cell_rotation_comb(u16_ground_cell);

            next_u8_ground_term_x = get_nxt_i_comb(u8_scan_x, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell)));

            next_u8_ground_term_y = get_nxt_j_comb(u8_scan_y, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell)));



            if (((get_nxt_i_comb(u8_scan_x, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell))) < grid_width) && (get_nxt_j_comb(u8_scan_y, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell))) < grid_height))) begin
                next_state = S_IF_THEN_26;
            end else begin
                next_state = S_IF_END_27;
            end

        end

        S_IF_END_25: begin

            // LIR block: if_end_25

            // line 86: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1




            next___for_idx_2 = (__for_idx_2 + 8'd1);



            next_state = S_FOR_HEADER_20;

        end

        S_IF_THEN_26: begin

            // LIR block: if_then_26

            // line 93: u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)





            fetchR_i = u8_ground_term_x;

            fetchR_j = u8_ground_term_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_26_WAIT;

        end

        S_IF_THEN_26_WAIT: begin

            // LIR block: if_then_26

            // line 93: u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_ground_region = fetchR_result;

                next_state = S_AFTER_CALL_28;
            end else begin
                next_state = S_IF_THEN_26_WAIT;
            end

        end

        S_IF_END_27: begin

            // LIR block: if_end_27

            // line 88: if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1






            next_state = S_IF_END_25;

        end

        S_AFTER_CALL_28: begin

            // LIR block: after_call_28

            // line 94: if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1






            if ((u8_ground_region == u8_raw0)) begin
                next_state = S_IF_THEN_29;
            end else begin
                next_state = S_IF_END_30;
            end

        end

        S_IF_THEN_29: begin

            // LIR block: if_then_29

            // line 95: u1_raw0_is_ground = 1




            next_u1_raw0_is_ground = 1'd1;



            next_state = S_IF_END_30;

        end

        S_IF_END_30: begin

            // LIR block: if_end_30

            // line 92: if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1






            next_state = S_IF_END_27;

        end

        S_IF_THEN_31: begin

            // LIR block: if_then_31

            // line 97: u8_node0 = 255




            next_u8_node0 = 8'd255;



            next_state = S_IF_END_32;

        end

        S_IF_END_32: begin

            // LIR block: if_end_32

            // line 84: if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1






            next_state = S_IF_END_16;

        end

        S_IF_ELSE_33: begin

            // LIR block: if_else_33

            // line 99: u1_need0 = 1




            next_u1_need0 = 1'd1;



            next_state = S_IF_END_32;

        end

        S_IF_THEN_34: begin

            // LIR block: if_then_34

            // line 102: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1




            next___for_idx_3 = 8'd0;



            next_state = S_FOR_HEADER_36;

        end

        S_IF_END_35: begin

            // LIR block: if_end_35

            // line 118: if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            if ((u1_need0 || u1_need1)) begin
                next_state = S_IF_THEN_53;
            end else begin
                next_state = S_IF_END_54;
            end

        end

        S_FOR_HEADER_36: begin

            // LIR block: for_header_36

            // line 102: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1






            if ((__for_idx_3 < grid_height)) begin
                next_state = S_FOR_BODY_37;
            end else begin
                next_state = S_FOR_END_38;
            end

        end

        S_FOR_BODY_37: begin

            // LIR block: for_body_37

            // line 102: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1




            next_u8_scan_y = __for_idx_3;

            next___for_idx_4 = 8'd0;



            next_state = S_FOR_HEADER_39;

        end

        S_FOR_END_38: begin

            // LIR block: for_end_38

            // line 113: if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1






            if (u1_raw1_is_ground) begin
                next_state = S_IF_THEN_50;
            end else begin
                next_state = S_IF_ELSE_52;
            end

        end

        S_FOR_HEADER_39: begin

            // LIR block: for_header_39

            // line 103: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1






            if ((__for_idx_4 < grid_width)) begin
                next_state = S_FOR_BODY_40;
            end else begin
                next_state = S_FOR_END_41;
            end

        end

        S_FOR_BODY_40: begin

            // LIR block: for_body_40

            // line 103: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1




            next_u8_scan_x = __for_idx_4;


            fetchCell_i = __for_idx_4;

            fetchCell_j = u8_scan_y;

            fetchCell_start = 1'b1;


            next_state = S_FOR_BODY_40_WAIT;

        end

        S_FOR_BODY_40_WAIT: begin

            // LIR block: for_body_40

            // line 103: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_ground_cell = fetchCell_result;

                next_state = S_AFTER_CALL_42;
            end else begin
                next_state = S_FOR_BODY_40_WAIT;
            end

        end

        S_FOR_END_41: begin

            // LIR block: for_end_41

            // line 102: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1




            next___for_idx_3 = (__for_idx_3 + 8'd1);



            next_state = S_FOR_HEADER_36;

        end

        S_AFTER_CALL_42: begin

            // LIR block: after_call_42

            // line 105: if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1






            if (is_ground_cell_comb(u16_ground_cell)) begin
                next_state = S_IF_THEN_43;
            end else begin
                next_state = S_IF_END_44;
            end

        end

        S_IF_THEN_43: begin

            // LIR block: if_then_43

            // line 106: u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)




            next_u2_ground_rot = get_cell_rotation_comb(u16_ground_cell);

            next_u8_ground_term_x = get_nxt_i_comb(u8_scan_x, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell)));

            next_u8_ground_term_y = get_nxt_j_comb(u8_scan_y, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell)));



            if (((get_nxt_i_comb(u8_scan_x, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell))) < grid_width) && (get_nxt_j_comb(u8_scan_y, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell))) < grid_height))) begin
                next_state = S_IF_THEN_45;
            end else begin
                next_state = S_IF_END_46;
            end

        end

        S_IF_END_44: begin

            // LIR block: if_end_44

            // line 103: for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1




            next___for_idx_4 = (__for_idx_4 + 8'd1);



            next_state = S_FOR_HEADER_39;

        end

        S_IF_THEN_45: begin

            // LIR block: if_then_45

            // line 110: u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)





            fetchR_i = u8_ground_term_x;

            fetchR_j = u8_ground_term_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_45_WAIT;

        end

        S_IF_THEN_45_WAIT: begin

            // LIR block: if_then_45

            // line 110: u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_ground_region = fetchR_result;

                next_state = S_AFTER_CALL_47;
            end else begin
                next_state = S_IF_THEN_45_WAIT;
            end

        end

        S_IF_END_46: begin

            // LIR block: if_end_46

            // line 105: if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1






            next_state = S_IF_END_44;

        end

        S_AFTER_CALL_47: begin

            // LIR block: after_call_47

            // line 111: if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1






            if ((u8_ground_region == u8_raw1)) begin
                next_state = S_IF_THEN_48;
            end else begin
                next_state = S_IF_END_49;
            end

        end

        S_IF_THEN_48: begin

            // LIR block: if_then_48

            // line 112: u1_raw1_is_ground = 1




            next_u1_raw1_is_ground = 1'd1;



            next_state = S_IF_END_49;

        end

        S_IF_END_49: begin

            // LIR block: if_end_49

            // line 109: if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1






            next_state = S_IF_END_46;

        end

        S_IF_THEN_50: begin

            // LIR block: if_then_50

            // line 114: u8_node1 = 255




            next_u8_node1 = 8'd255;



            next_state = S_IF_END_51;

        end

        S_IF_END_51: begin

            // LIR block: if_end_51

            // line 101: if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1






            next_state = S_IF_END_35;

        end

        S_IF_ELSE_52: begin

            // LIR block: if_else_52

            // line 116: u1_need1 = 1




            next_u1_need1 = 1'd1;



            next_state = S_IF_END_51;

        end

        S_IF_THEN_53: begin

            // LIR block: if_then_53

            // line 119: u8_next_node = 0




            next_u8_next_node = 8'd0;

            next___for_idx_5 = 8'd0;



            next_state = S_FOR_HEADER_55;

        end

        S_IF_END_54: begin

            // LIR block: if_end_54

            // line 66: if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_rot = fetchComponentRotation(idx=u16_idx)              u2_dir0 = get_opp_dir_comb(d=u2_rot)             u8_term0_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir0)             u8_term0_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir0)             if u8_term0_x < grid_width and u8_term0_y < grid_height:                 u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)              u8_term1_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_rot)             u8_term1_x = get_nxt_i_comb(i=u8_term1_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_term1_y, d=u2_rot)             if u8_term1_x < grid_width and u8_term1_y < grid_height:                 u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)              if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1              if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1              if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            next_state = S_IF_END_5;

        end

        S_FOR_HEADER_55: begin

            // LIR block: for_header_55

            // line 120: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            if ((__for_idx_5 < grid_height)) begin
                next_state = S_FOR_BODY_56;
            end else begin
                next_state = S_FOR_END_57;
            end

        end

        S_FOR_BODY_56: begin

            // LIR block: for_body_56

            // line 120: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1




            next_u8_scan_y = __for_idx_5;

            next___for_idx_6 = 8'd0;



            next_state = S_FOR_HEADER_58;

        end

        S_FOR_END_57: begin

            // LIR block: for_end_57

            // line 118: if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            next_state = S_IF_END_54;

        end

        S_FOR_HEADER_58: begin

            // LIR block: for_header_58

            // line 121: for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            if ((__for_idx_6 < grid_width)) begin
                next_state = S_FOR_BODY_59;
            end else begin
                next_state = S_FOR_END_60;
            end

        end

        S_FOR_BODY_59: begin

            // LIR block: for_body_59

            // line 121: for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1




            next_u8_scan_x = __for_idx_6;


            fetchR_i = __for_idx_6;

            fetchR_j = u8_scan_y;

            fetchR_start = 1'b1;


            next_state = S_FOR_BODY_59_WAIT;

        end

        S_FOR_BODY_59_WAIT: begin

            // LIR block: for_body_59

            // line 121: for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_region = fetchR_result;

                next_state = S_AFTER_CALL_61;
            end else begin
                next_state = S_FOR_BODY_59_WAIT;
            end

        end

        S_FOR_END_60: begin

            // LIR block: for_end_60

            // line 120: for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1




            next___for_idx_5 = (__for_idx_5 + 8'd1);



            next_state = S_FOR_HEADER_55;

        end

        S_AFTER_CALL_61: begin

            // LIR block: after_call_61

            // line 123: u1_region_is_ground = 0




            next_u1_region_is_ground = 1'd0;



            if ((u8_region != 32'd0)) begin
                next_state = S_IF_THEN_62;
            end else begin
                next_state = S_IF_END_63;
            end

        end

        S_IF_THEN_62: begin

            // LIR block: if_then_62

            // line 125: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1




            next___for_idx_7 = 8'd0;



            next_state = S_FOR_HEADER_64;

        end

        S_IF_END_63: begin

            // LIR block: if_end_63

            // line 136: if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            if (((u8_region != 32'd0) && (! u1_region_is_ground))) begin
                next_state = S_IF_THEN_78;
            end else begin
                next_state = S_IF_END_79;
            end

        end

        S_FOR_HEADER_64: begin

            // LIR block: for_header_64

            // line 125: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            if ((__for_idx_7 < grid_height)) begin
                next_state = S_FOR_BODY_65;
            end else begin
                next_state = S_FOR_END_66;
            end

        end

        S_FOR_BODY_65: begin

            // LIR block: for_body_65

            // line 125: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1




            next_u8_prev_y = __for_idx_7;

            next___for_idx_8 = 8'd0;



            next_state = S_FOR_HEADER_67;

        end

        S_FOR_END_66: begin

            // LIR block: for_end_66

            // line 124: if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            next_state = S_IF_END_63;

        end

        S_FOR_HEADER_67: begin

            // LIR block: for_header_67

            // line 126: for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            if ((__for_idx_8 < grid_width)) begin
                next_state = S_FOR_BODY_68;
            end else begin
                next_state = S_FOR_END_69;
            end

        end

        S_FOR_BODY_68: begin

            // LIR block: for_body_68

            // line 126: for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1




            next_u8_prev_x = __for_idx_8;


            fetchCell_i = __for_idx_8;

            fetchCell_j = u8_prev_y;

            fetchCell_start = 1'b1;


            next_state = S_FOR_BODY_68_WAIT;

        end

        S_FOR_BODY_68_WAIT: begin

            // LIR block: for_body_68

            // line 126: for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1

            // wait for blocking primitive: fetchCell






            if (fetchCell_done) begin

                next_u16_ground_cell = fetchCell_result;

                next_state = S_AFTER_CALL_70;
            end else begin
                next_state = S_FOR_BODY_68_WAIT;
            end

        end

        S_FOR_END_69: begin

            // LIR block: for_end_69

            // line 125: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1




            next___for_idx_7 = (__for_idx_7 + 8'd1);



            next_state = S_FOR_HEADER_64;

        end

        S_AFTER_CALL_70: begin

            // LIR block: after_call_70

            // line 128: if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            if (is_ground_cell_comb(u16_ground_cell)) begin
                next_state = S_IF_THEN_71;
            end else begin
                next_state = S_IF_END_72;
            end

        end

        S_IF_THEN_71: begin

            // LIR block: if_then_71

            // line 129: u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)




            next_u2_ground_rot = get_cell_rotation_comb(u16_ground_cell);

            next_u8_ground_term_x = get_nxt_i_comb(u8_prev_x, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell)));

            next_u8_ground_term_y = get_nxt_j_comb(u8_prev_y, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell)));



            if (((get_nxt_i_comb(u8_prev_x, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell))) < grid_width) && (get_nxt_j_comb(u8_prev_y, get_opp_dir_comb(get_cell_rotation_comb(u16_ground_cell))) < grid_height))) begin
                next_state = S_IF_THEN_73;
            end else begin
                next_state = S_IF_END_74;
            end

        end

        S_IF_END_72: begin

            // LIR block: if_end_72

            // line 126: for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1




            next___for_idx_8 = (__for_idx_8 + 8'd1);



            next_state = S_FOR_HEADER_67;

        end

        S_IF_THEN_73: begin

            // LIR block: if_then_73

            // line 133: u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)





            fetchR_i = u8_ground_term_x;

            fetchR_j = u8_ground_term_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_73_WAIT;

        end

        S_IF_THEN_73_WAIT: begin

            // LIR block: if_then_73

            // line 133: u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_ground_region = fetchR_result;

                next_state = S_AFTER_CALL_75;
            end else begin
                next_state = S_IF_THEN_73_WAIT;
            end

        end

        S_IF_END_74: begin

            // LIR block: if_end_74

            // line 128: if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            next_state = S_IF_END_72;

        end

        S_AFTER_CALL_75: begin

            // LIR block: after_call_75

            // line 134: if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            if ((u8_ground_region == u8_region)) begin
                next_state = S_IF_THEN_76;
            end else begin
                next_state = S_IF_END_77;
            end

        end

        S_IF_THEN_76: begin

            // LIR block: if_then_76

            // line 135: u1_region_is_ground = 1




            next_u1_region_is_ground = 1'd1;



            next_state = S_IF_END_77;

        end

        S_IF_END_77: begin

            // LIR block: if_end_77

            // line 132: if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1






            next_state = S_IF_END_74;

        end

        S_IF_THEN_78: begin

            // LIR block: if_then_78

            // line 137: u1_seen = 0




            next_u1_seen = 1'd0;

            next___for_idx_9 = 8'd0;



            next_state = S_FOR_HEADER_80;

        end

        S_IF_END_79: begin

            // LIR block: if_end_79

            // line 121: for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1




            next___for_idx_6 = (__for_idx_6 + 8'd1);



            next_state = S_FOR_HEADER_58;

        end

        S_FOR_HEADER_80: begin

            // LIR block: for_header_80

            // line 138: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1






            if ((__for_idx_9 < grid_height)) begin
                next_state = S_FOR_BODY_81;
            end else begin
                next_state = S_FOR_END_82;
            end

        end

        S_FOR_BODY_81: begin

            // LIR block: for_body_81

            // line 138: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1




            next_u8_prev_y = __for_idx_9;

            next___for_idx_10 = 8'd0;



            next_state = S_FOR_HEADER_83;

        end

        S_FOR_END_82: begin

            // LIR block: for_end_82

            // line 150: if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            if ((! u1_seen)) begin
                next_state = S_IF_THEN_91;
            end else begin
                next_state = S_IF_END_92;
            end

        end

        S_FOR_HEADER_83: begin

            // LIR block: for_header_83

            // line 139: for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1






            if ((__for_idx_10 < grid_width)) begin
                next_state = S_FOR_BODY_84;
            end else begin
                next_state = S_FOR_END_85;
            end

        end

        S_FOR_BODY_84: begin

            // LIR block: for_body_84

            // line 139: for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1




            next_u8_prev_x = __for_idx_10;



            if (((u8_prev_y < u8_scan_y) || ((u8_prev_y == u8_scan_y) && (__for_idx_10 < u8_scan_x)))) begin
                next_state = S_IF_THEN_86;
            end else begin
                next_state = S_IF_END_87;
            end

        end

        S_FOR_END_85: begin

            // LIR block: for_end_85

            // line 138: for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1




            next___for_idx_9 = (__for_idx_9 + 8'd1);



            next_state = S_FOR_HEADER_80;

        end

        S_IF_THEN_86: begin

            // LIR block: if_then_86

            // line 147: u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)





            fetchR_i = u8_prev_x;

            fetchR_j = u8_prev_y;

            fetchR_start = 1'b1;


            next_state = S_IF_THEN_86_WAIT;

        end

        S_IF_THEN_86_WAIT: begin

            // LIR block: if_then_86

            // line 147: u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)

            // wait for blocking primitive: fetchR






            if (fetchR_done) begin

                next_u8_prev_region = fetchR_result;

                next_state = S_AFTER_CALL_88;
            end else begin
                next_state = S_IF_THEN_86_WAIT;
            end

        end

        S_IF_END_87: begin

            // LIR block: if_end_87

            // line 139: for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1




            next___for_idx_10 = (__for_idx_10 + 8'd1);



            next_state = S_FOR_HEADER_83;

        end

        S_AFTER_CALL_88: begin

            // LIR block: after_call_88

            // line 148: if u8_prev_region == u8_region:                                             u1_seen = 1






            if ((u8_prev_region == u8_region)) begin
                next_state = S_IF_THEN_89;
            end else begin
                next_state = S_IF_END_90;
            end

        end

        S_IF_THEN_89: begin

            // LIR block: if_then_89

            // line 149: u1_seen = 1




            next_u1_seen = 1'd1;



            next_state = S_IF_END_90;

        end

        S_IF_END_90: begin

            // LIR block: if_end_90

            // line 140: if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1






            next_state = S_IF_END_87;

        end

        S_IF_THEN_91: begin

            // LIR block: if_then_91

            // line 151: if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0






            if ((u1_need0 && (u8_region == u8_raw0))) begin
                next_state = S_IF_THEN_93;
            end else begin
                next_state = S_IF_END_94;
            end

        end

        S_IF_END_92: begin

            // LIR block: if_end_92

            // line 136: if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1






            next_state = S_IF_END_79;

        end

        S_IF_THEN_93: begin

            // LIR block: if_then_93

            // line 152: u8_node0 = u8_next_node




            next_u8_node0 = u8_next_node;

            next_u1_need0 = 1'd0;



            next_state = S_IF_END_94;

        end

        S_IF_END_94: begin

            // LIR block: if_end_94

            // line 154: if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0






            if ((u1_need1 && (u8_region == u8_raw1))) begin
                next_state = S_IF_THEN_95;
            end else begin
                next_state = S_IF_END_96;
            end

        end

        S_IF_THEN_95: begin

            // LIR block: if_then_95

            // line 155: u8_node1 = u8_next_node




            next_u8_node1 = u8_next_node;

            next_u1_need1 = 1'd0;



            next_state = S_IF_END_96;

        end

        S_IF_END_96: begin

            // LIR block: if_end_96

            // line 157: u8_next_node = u8_next_node + 1




            next_u8_next_node = (u8_next_node + 8'd1);



            next_state = S_IF_END_92;

        end

        S_AFTER_CALL_97: begin

            // LIR block: after_call_97

            // line 160: storeNode1(idx=u16_idx, node_i=u8_node1)





            storeNode1_idx = u16_idx;

            storeNode1_node_i = u8_node1;

            storeNode1_start = 1'b1;


            next_state = S_AFTER_CALL_97_WAIT;

        end

        S_AFTER_CALL_97_WAIT: begin

            // LIR block: after_call_97

            // line 160: storeNode1(idx=u16_idx, node_i=u8_node1)

            // wait for blocking primitive: storeNode1






            if (storeNode1_done) begin

                next_state = S_AFTER_CALL_98;
            end else begin
                next_state = S_AFTER_CALL_97_WAIT;
            end

        end

        S_AFTER_CALL_98: begin

            // LIR block: after_call_98

            // line 55: for u16_idx in range(par_elem_n):         u8_type = fetchComponentType(idx=u16_idx)         u8_node0 = 255         u8_node1 = 255         u8_raw0 = 0         u8_raw1 = 0         u1_need0 = 0         u1_need1 = 0         u1_raw0_is_ground = 0         u1_raw1_is_ground = 0          if is_two_terminal_component_comb(t=u8_type):             u8_anchor_x = fetchAnchorPositionX(idx=u16_idx)             u8_anchor_y = fetchAnchorPositionY(idx=u16_idx)             u2_rot = fetchComponentRotation(idx=u16_idx)              u2_dir0 = get_opp_dir_comb(d=u2_rot)             u8_term0_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_dir0)             u8_term0_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_dir0)             if u8_term0_x < grid_width and u8_term0_y < grid_height:                 u8_raw0 = fetchR(i=u8_term0_x, j=u8_term0_y)              u8_term1_x = get_nxt_i_comb(i=u8_anchor_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_anchor_y, d=u2_rot)             u8_term1_x = get_nxt_i_comb(i=u8_term1_x, d=u2_rot)             u8_term1_y = get_nxt_j_comb(j=u8_term1_y, d=u2_rot)             if u8_term1_x < grid_width and u8_term1_y < grid_height:                 u8_raw1 = fetchR(i=u8_term1_x, j=u8_term1_y)              if u8_raw0 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw0:                                     u1_raw0_is_ground = 1                 if u1_raw0_is_ground:                     u8_node0 = 255                 else:                     u1_need0 = 1              if u8_raw1 != 0:                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u16_ground_cell = fetchCell(i=u8_scan_x, j=u8_scan_y)                         if is_ground_cell_comb(cell=u16_ground_cell):                             u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                             u8_ground_term_x = get_nxt_i_comb(i=u8_scan_x, d=get_opp_dir_comb(d=u2_ground_rot))                             u8_ground_term_y = get_nxt_j_comb(j=u8_scan_y, d=get_opp_dir_comb(d=u2_ground_rot))                             if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                 u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                 if u8_ground_region == u8_raw1:                                     u1_raw1_is_ground = 1                 if u1_raw1_is_ground:                     u8_node1 = 255                 else:                     u1_need1 = 1              if u1_need0 or u1_need1:                 u8_next_node = 0                 for u8_scan_y in range(grid_height):                     for u8_scan_x in range(grid_width):                         u8_region = fetchR(i=u8_scan_x, j=u8_scan_y)                         u1_region_is_ground = 0                         if u8_region != 0:                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     u16_ground_cell = fetchCell(i=u8_prev_x, j=u8_prev_y)                                     if is_ground_cell_comb(cell=u16_ground_cell):                                         u2_ground_rot = get_cell_rotation_comb(cell=u16_ground_cell)                                         u8_ground_term_x = get_nxt_i_comb(i=u8_prev_x, d=get_opp_dir_comb(d=u2_ground_rot))                                         u8_ground_term_y = get_nxt_j_comb(j=u8_prev_y, d=get_opp_dir_comb(d=u2_ground_rot))                                         if u8_ground_term_x < grid_width and u8_ground_term_y < grid_height:                                             u8_ground_region = fetchR(i=u8_ground_term_x, j=u8_ground_term_y)                                             if u8_ground_region == u8_region:                                                 u1_region_is_ground = 1                         if u8_region != 0 and not u1_region_is_ground:                             u1_seen = 0                             for u8_prev_y in range(grid_height):                                 for u8_prev_x in range(grid_width):                                     if (                                         u8_prev_y < u8_scan_y                                         or (                                             u8_prev_y == u8_scan_y                                             and u8_prev_x < u8_scan_x                                         )                                     ):                                         u8_prev_region = fetchR(i=u8_prev_x, j=u8_prev_y)                                         if u8_prev_region == u8_region:                                             u1_seen = 1                             if not u1_seen:                                 if u1_need0 and u8_region == u8_raw0:                                     u8_node0 = u8_next_node                                     u1_need0 = 0                                 if u1_need1 and u8_region == u8_raw1:                                     u8_node1 = u8_next_node                                     u1_need1 = 0                                 u8_next_node = u8_next_node + 1          storeNode0(idx=u16_idx, node_i=u8_node0)         storeNode1(idx=u16_idx, node_i=u8_node1)




            next___for_idx_0 = (__for_idx_0 + 16'd1);



            next_state = S_FOR_HEADER_0;

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
