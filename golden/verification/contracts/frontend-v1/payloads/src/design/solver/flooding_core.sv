
// Generated from LIR for function flooding_core

// Entry block: entry

// Blocking primitives: fetchP(latency=1), getVisited(latency=1), setVisited(latency=1), storeR(latency=1), addQueue(latency=1), getQueueLen(latency=1), popQueue(latency=1)

module flooding_core (

    input logic clk,

    input logic rst_n,

    input logic start,

    output logic busy,

    output logic done,

    input logic [31:0] grid_height,

    input logic [31:0] grid_width,

    output logic fetchP_start,

    output logic [7:0] fetchP_i,

    output logic [7:0] fetchP_j,

    input logic fetchP_done,

    input logic [3:0] fetchP_result,

    output logic getVisited_start,

    output logic [7:0] getVisited_i,

    output logic [7:0] getVisited_j,

    input logic getVisited_done,

    input logic getVisited_result,

    output logic setVisited_start,

    output logic [7:0] setVisited_i,

    output logic [7:0] setVisited_j,

    input logic setVisited_done,

    output logic storeR_start,

    output logic [7:0] storeR_i,

    output logic [7:0] storeR_j,

    output logic [7:0] storeR_v,

    input logic storeR_done,

    output logic addQueue_start,

    output logic [7:0] addQueue_i,

    output logic [7:0] addQueue_j,

    output logic [31:0] addQueue_d,

    input logic addQueue_done,

    output logic getQueueLen_start,

    input logic getQueueLen_done,

    input logic [15:0] getQueueLen_result,

    output logic popQueue_start,

    input logic popQueue_done,

    input logic [17:0] popQueue_result

);


import FloodingCombPkg::*;


typedef enum logic [6:0] {

    S_IDLE,

    S_ENTRY,

    S_FOR_HEADER_0,

    S_FOR_BODY_1,

    S_FOR_END_2,

    S_FOR_HEADER_3,

    S_FOR_BODY_4,

    S_FOR_BODY_4_WAIT,

    S_FOR_END_5,

    S_AFTER_CALL_6,

    S_AFTER_CALL_6_WAIT,

    S_AFTER_CALL_7,

    S_IF_THEN_8,

    S_IF_THEN_8_WAIT,

    S_IF_END_9,

    S_AFTER_CALL_10,

    S_AFTER_CALL_10_WAIT,

    S_AFTER_CALL_11,

    S_IF_THEN_12,

    S_IF_THEN_12_WAIT,

    S_IF_END_13,

    S_AFTER_CALL_14,

    S_IF_THEN_15,

    S_IF_THEN_15_WAIT,

    S_IF_END_16,

    S_AFTER_CALL_17,

    S_IF_THEN_18,

    S_IF_THEN_18_WAIT,

    S_IF_END_19,

    S_AFTER_CALL_20,

    S_IF_THEN_21,

    S_IF_THEN_21_WAIT,

    S_IF_END_22,

    S_IF_END_22_WAIT,

    S_AFTER_CALL_23,

    S_AFTER_CALL_24,

    S_WHILE_HEADER_25,

    S_WHILE_BODY_26,

    S_WHILE_BODY_26_WAIT,

    S_WHILE_END_27,

    S_AFTER_CALL_28,

    S_AFTER_CALL_28_WAIT,

    S_AFTER_CALL_29,

    S_IF_THEN_30,

    S_IF_THEN_30_WAIT,

    S_IF_END_31,

    S_IF_END_31_WAIT,

    S_AFTER_CALL_32,

    S_IF_THEN_33,

    S_IF_THEN_33_WAIT,

    S_IF_END_34,

    S_AFTER_CALL_35,

    S_AFTER_CALL_35_WAIT,

    S_AFTER_CALL_36,

    S_IF_THEN_37,

    S_IF_THEN_37_WAIT,

    S_IF_END_38,

    S_AFTER_CALL_39,

    S_IF_THEN_40,

    S_IF_THEN_40_WAIT,

    S_IF_END_41,

    S_AFTER_CALL_42,

    S_IF_THEN_43,

    S_IF_THEN_43_WAIT,

    S_IF_END_44,

    S_AFTER_CALL_45,

    S_IF_THEN_46,

    S_IF_THEN_46_WAIT,

    S_IF_END_47,

    S_AFTER_CALL_48,

    S_AFTER_CALL_49,

    S_DONE

} state_t;

state_t state;
state_t next_state;


logic [7:0] u8_i;

logic [7:0] u8_j;

logic [3:0] u4_p;

logic u1_f;

logic [7:0] u8_node_idx;

logic [15:0] u16_t;

logic [17:0] u18_cur;

logic [7:0] u8_ni;

logic [7:0] u8_nj;

logic [1:0] u2_dir;


logic [7:0] __for_idx_0;

logic [7:0] __for_idx_1;



logic [7:0] next_u8_i;

logic [7:0] next_u8_j;

logic [3:0] next_u4_p;

logic next_u1_f;

logic [7:0] next_u8_node_idx;

logic [15:0] next_u16_t;

logic [17:0] next_u18_cur;

logic [7:0] next_u8_ni;

logic [7:0] next_u8_nj;

logic [1:0] next_u2_dir;

logic [7:0] next___for_idx_0;

logic [7:0] next___for_idx_1;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        u8_i <=0;

        u8_j <=0;

        u4_p <=0;

        u1_f <=0;

        u8_node_idx <=0;

        u16_t <=0;

        u18_cur <=0;

        u8_ni <=0;

        u8_nj <=0;

        u2_dir <=0;


        __for_idx_0 <=0;

        __for_idx_1 <=0;


    end else begin
        state <= next_state;

        u8_i <= next_u8_i;

        u8_j <= next_u8_j;

        u4_p <= next_u4_p;

        u1_f <= next_u1_f;

        u8_node_idx <= next_u8_node_idx;

        u16_t <= next_u16_t;

        u18_cur <= next_u18_cur;

        u8_ni <= next_u8_ni;

        u8_nj <= next_u8_nj;

        u2_dir <= next_u2_dir;


        __for_idx_0 <= next___for_idx_0;

        __for_idx_1 <= next___for_idx_1;


    end
end

always_comb begin
    next_state = state;
    busy = 1'b1;
    done = 1'b0;

    next_u8_i = u8_i;

    next_u8_j = u8_j;

    next_u4_p = u4_p;

    next_u1_f = u1_f;

    next_u8_node_idx = u8_node_idx;

    next_u16_t = u16_t;

    next_u18_cur = u18_cur;

    next_u8_ni = u8_ni;

    next_u8_nj = u8_nj;

    next_u2_dir = u2_dir;


    next___for_idx_0 = __for_idx_0;

    next___for_idx_1 = __for_idx_1;



    fetchP_start =0;

    fetchP_i =0;

    fetchP_j =0;

    getVisited_start =0;

    getVisited_i =0;

    getVisited_j =0;

    setVisited_start =0;

    setVisited_i =0;

    setVisited_j =0;

    storeR_start =0;

    storeR_i =0;

    storeR_j =0;

    storeR_v =0;

    addQueue_start =0;

    addQueue_i =0;

    addQueue_j =0;

    addQueue_d =0;

    getQueueLen_start =0;

    popQueue_start =0;


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

            // line 2: u8_i = 0




            next_u8_i = 8'd0;

            next_u8_j = 8'd0;

            next_u4_p = 4'd0;

            next_u1_f = 1'd0;

            next_u8_node_idx = 8'd0;

            next_u16_t = 16'd0;

            next_u18_cur = 18'd0;

            next_u8_ni = 8'd0;

            next_u8_nj = 8'd0;

            next_u2_dir = 2'd0;

            next___for_idx_0 = 8'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 12: for u8_j in range(grid_height):         for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            if ((__for_idx_0 < grid_height)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 12: for u8_j in range(grid_height):         for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()




            next_u8_j = __for_idx_0;

            next___for_idx_1 = 8'd0;



            next_state = S_FOR_HEADER_3;

        end

        S_FOR_END_2: begin

            // LIR block: for_end_2







            next_state = S_DONE;

        end

        S_FOR_HEADER_3: begin

            // LIR block: for_header_3

            // line 13: for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            if ((__for_idx_1 < grid_width)) begin
                next_state = S_FOR_BODY_4;
            end else begin
                next_state = S_FOR_END_5;
            end

        end

        S_FOR_BODY_4: begin

            // LIR block: for_body_4

            // line 13: for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()




            next_u8_i = __for_idx_1;


            fetchP_i = __for_idx_1;

            fetchP_j = u8_j;

            fetchP_start = 1'b1;


            next_state = S_FOR_BODY_4_WAIT;

        end

        S_FOR_BODY_4_WAIT: begin

            // LIR block: for_body_4

            // line 13: for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()

            // wait for blocking primitive: fetchP






            if (fetchP_done) begin

                next_u4_p = fetchP_result;

                next_state = S_AFTER_CALL_6;
            end else begin
                next_state = S_FOR_BODY_4_WAIT;
            end

        end

        S_FOR_END_5: begin

            // LIR block: for_end_5

            // line 12: for u8_j in range(grid_height):         for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()




            next___for_idx_0 = (__for_idx_0 + 8'd1);



            next_state = S_FOR_HEADER_0;

        end

        S_AFTER_CALL_6: begin

            // LIR block: after_call_6

            // line 15: u1_f = getVisited(i=u8_i, j=u8_j)





            getVisited_i = u8_i;

            getVisited_j = u8_j;

            getVisited_start = 1'b1;


            next_state = S_AFTER_CALL_6_WAIT;

        end

        S_AFTER_CALL_6_WAIT: begin

            // LIR block: after_call_6

            // line 15: u1_f = getVisited(i=u8_i, j=u8_j)

            // wait for blocking primitive: getVisited






            if (getVisited_done) begin

                next_u1_f = getVisited_result;

                next_state = S_AFTER_CALL_7;
            end else begin
                next_state = S_AFTER_CALL_6_WAIT;
            end

        end

        S_AFTER_CALL_7: begin

            // LIR block: after_call_7

            // line 16: if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            if (((! u1_f) && decode_iswire_comb(u4_p))) begin
                next_state = S_IF_THEN_8;
            end else begin
                next_state = S_IF_END_9;
            end

        end

        S_IF_THEN_8: begin

            // LIR block: if_then_8

            // line 17: u8_node_idx = u8_node_idx + 1




            next_u8_node_idx = (u8_node_idx + 8'd1);


            setVisited_i = u8_i;

            setVisited_j = u8_j;

            setVisited_start = 1'b1;


            next_state = S_IF_THEN_8_WAIT;

        end

        S_IF_THEN_8_WAIT: begin

            // LIR block: if_then_8

            // line 17: u8_node_idx = u8_node_idx + 1

            // wait for blocking primitive: setVisited






            if (setVisited_done) begin

                next_state = S_AFTER_CALL_10;
            end else begin
                next_state = S_IF_THEN_8_WAIT;
            end

        end

        S_IF_END_9: begin

            // LIR block: if_end_9

            // line 13: for u8_i in range(grid_width):             u4_p = fetchP(i=u8_i, j=u8_j)             u1_f = getVisited(i=u8_i, j=u8_j)             if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()




            next___for_idx_1 = (__for_idx_1 + 8'd1);



            next_state = S_FOR_HEADER_3;

        end

        S_AFTER_CALL_10: begin

            // LIR block: after_call_10

            // line 19: storeR(i=u8_i, j=u8_j, v=u8_node_idx)





            storeR_i = u8_i;

            storeR_j = u8_j;

            storeR_v = u8_node_idx;

            storeR_start = 1'b1;


            next_state = S_AFTER_CALL_10_WAIT;

        end

        S_AFTER_CALL_10_WAIT: begin

            // LIR block: after_call_10

            // line 19: storeR(i=u8_i, j=u8_j, v=u8_node_idx)

            // wait for blocking primitive: storeR






            if (storeR_done) begin

                next_state = S_AFTER_CALL_11;
            end else begin
                next_state = S_AFTER_CALL_10_WAIT;
            end

        end

        S_AFTER_CALL_11: begin

            // LIR block: after_call_11

            // line 20: if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)






            if (getport_comb(u4_p, 32'd0)) begin
                next_state = S_IF_THEN_12;
            end else begin
                next_state = S_IF_END_13;
            end

        end

        S_IF_THEN_12: begin

            // LIR block: if_then_12

            // line 21: addQueue(i=u8_i, j=u8_j, d=0)





            addQueue_i = u8_i;

            addQueue_j = u8_j;

            addQueue_d = 32'd0;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_12_WAIT;

        end

        S_IF_THEN_12_WAIT: begin

            // LIR block: if_then_12

            // line 21: addQueue(i=u8_i, j=u8_j, d=0)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_14;
            end else begin
                next_state = S_IF_THEN_12_WAIT;
            end

        end

        S_IF_END_13: begin

            // LIR block: if_end_13

            // line 22: if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)






            if (getport_comb(u4_p, 32'd1)) begin
                next_state = S_IF_THEN_15;
            end else begin
                next_state = S_IF_END_16;
            end

        end

        S_AFTER_CALL_14: begin

            // LIR block: after_call_14

            // line 20: if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)






            next_state = S_IF_END_13;

        end

        S_IF_THEN_15: begin

            // LIR block: if_then_15

            // line 23: addQueue(i=u8_i, j=u8_j, d=1)





            addQueue_i = u8_i;

            addQueue_j = u8_j;

            addQueue_d = 32'd1;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_15_WAIT;

        end

        S_IF_THEN_15_WAIT: begin

            // LIR block: if_then_15

            // line 23: addQueue(i=u8_i, j=u8_j, d=1)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_17;
            end else begin
                next_state = S_IF_THEN_15_WAIT;
            end

        end

        S_IF_END_16: begin

            // LIR block: if_end_16

            // line 24: if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)






            if (getport_comb(u4_p, 32'd2)) begin
                next_state = S_IF_THEN_18;
            end else begin
                next_state = S_IF_END_19;
            end

        end

        S_AFTER_CALL_17: begin

            // LIR block: after_call_17

            // line 22: if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)






            next_state = S_IF_END_16;

        end

        S_IF_THEN_18: begin

            // LIR block: if_then_18

            // line 25: addQueue(i=u8_i, j=u8_j, d=2)





            addQueue_i = u8_i;

            addQueue_j = u8_j;

            addQueue_d = 32'd2;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_18_WAIT;

        end

        S_IF_THEN_18_WAIT: begin

            // LIR block: if_then_18

            // line 25: addQueue(i=u8_i, j=u8_j, d=2)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_20;
            end else begin
                next_state = S_IF_THEN_18_WAIT;
            end

        end

        S_IF_END_19: begin

            // LIR block: if_end_19

            // line 26: if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)






            if (getport_comb(u4_p, 32'd3)) begin
                next_state = S_IF_THEN_21;
            end else begin
                next_state = S_IF_END_22;
            end

        end

        S_AFTER_CALL_20: begin

            // LIR block: after_call_20

            // line 24: if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)






            next_state = S_IF_END_19;

        end

        S_IF_THEN_21: begin

            // LIR block: if_then_21

            // line 27: addQueue(i=u8_i, j=u8_j, d=3)





            addQueue_i = u8_i;

            addQueue_j = u8_j;

            addQueue_d = 32'd3;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_21_WAIT;

        end

        S_IF_THEN_21_WAIT: begin

            // LIR block: if_then_21

            // line 27: addQueue(i=u8_i, j=u8_j, d=3)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_23;
            end else begin
                next_state = S_IF_THEN_21_WAIT;
            end

        end

        S_IF_END_22: begin

            // LIR block: if_end_22

            // line 28: u16_t = getQueueLen()





            getQueueLen_start = 1'b1;


            next_state = S_IF_END_22_WAIT;

        end

        S_IF_END_22_WAIT: begin

            // LIR block: if_end_22

            // line 28: u16_t = getQueueLen()

            // wait for blocking primitive: getQueueLen






            if (getQueueLen_done) begin

                next_u16_t = getQueueLen_result;

                next_state = S_AFTER_CALL_24;
            end else begin
                next_state = S_IF_END_22_WAIT;
            end

        end

        S_AFTER_CALL_23: begin

            // LIR block: after_call_23

            // line 26: if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)






            next_state = S_IF_END_22;

        end

        S_AFTER_CALL_24: begin

            // LIR block: after_call_24

            // line 29: while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            next_state = S_WHILE_HEADER_25;

        end

        S_WHILE_HEADER_25: begin

            // LIR block: while_header_25

            // line 29: while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            if ((u16_t > 32'd0)) begin
                next_state = S_WHILE_BODY_26;
            end else begin
                next_state = S_WHILE_END_27;
            end

        end

        S_WHILE_BODY_26: begin

            // LIR block: while_body_26

            // line 30: u18_cur = popQueue()





            popQueue_start = 1'b1;


            next_state = S_WHILE_BODY_26_WAIT;

        end

        S_WHILE_BODY_26_WAIT: begin

            // LIR block: while_body_26

            // line 30: u18_cur = popQueue()

            // wait for blocking primitive: popQueue






            if (popQueue_done) begin

                next_u18_cur = popQueue_result;

                next_state = S_AFTER_CALL_28;
            end else begin
                next_state = S_WHILE_BODY_26_WAIT;
            end

        end

        S_WHILE_END_27: begin

            // LIR block: while_end_27

            // line 16: if not u1_f and decode_iswire_comb(p=u4_p):                 u8_node_idx = u8_node_idx + 1                 setVisited(i=u8_i, j=u8_j)                 storeR(i=u8_i, j=u8_j, v=u8_node_idx)                 if getport_comb(p=u4_p, i=0):                     addQueue(i=u8_i, j=u8_j, d=0)                 if getport_comb(p=u4_p, i=1):                     addQueue(i=u8_i, j=u8_j, d=1)                 if getport_comb(p=u4_p, i=2):                     addQueue(i=u8_i, j=u8_j, d=2)                 if getport_comb(p=u4_p, i=3):                     addQueue(i=u8_i, j=u8_j, d=3)                 u16_t = getQueueLen()                 while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            next_state = S_IF_END_9;

        end

        S_AFTER_CALL_28: begin

            // LIR block: after_call_28

            // line 31: u8_ni = decode_i_comb(q_item=u18_cur)




            next_u8_ni = decode_i_comb(u18_cur);

            next_u8_nj = decode_j_comb(u18_cur);

            next_u2_dir = decode_d_comb(u18_cur);

            next_u8_ni = get_nxt_i_comb(decode_i_comb(u18_cur), decode_d_comb(u18_cur));

            next_u8_nj = get_nxt_j_comb(decode_j_comb(u18_cur), decode_d_comb(u18_cur));


            getVisited_i = get_nxt_i_comb(decode_i_comb(u18_cur), decode_d_comb(u18_cur));

            getVisited_j = get_nxt_j_comb(decode_j_comb(u18_cur), decode_d_comb(u18_cur));

            getVisited_start = 1'b1;


            next_state = S_AFTER_CALL_28_WAIT;

        end

        S_AFTER_CALL_28_WAIT: begin

            // LIR block: after_call_28

            // line 31: u8_ni = decode_i_comb(q_item=u18_cur)

            // wait for blocking primitive: getVisited






            if (getVisited_done) begin

                next_u1_f = getVisited_result;

                next_state = S_AFTER_CALL_29;
            end else begin
                next_state = S_AFTER_CALL_28_WAIT;
            end

        end

        S_AFTER_CALL_29: begin

            // LIR block: after_call_29

            // line 37: if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)






            if ((((((! u1_f) && (u8_ni >= 32'd0)) && (u8_nj >= 32'd0)) && (u8_ni < grid_width)) && (u8_nj < grid_height))) begin
                next_state = S_IF_THEN_30;
            end else begin
                next_state = S_IF_END_31;
            end

        end

        S_IF_THEN_30: begin

            // LIR block: if_then_30

            // line 44: u4_p = fetchP(i=u8_ni, j=u8_nj)





            fetchP_i = u8_ni;

            fetchP_j = u8_nj;

            fetchP_start = 1'b1;


            next_state = S_IF_THEN_30_WAIT;

        end

        S_IF_THEN_30_WAIT: begin

            // LIR block: if_then_30

            // line 44: u4_p = fetchP(i=u8_ni, j=u8_nj)

            // wait for blocking primitive: fetchP






            if (fetchP_done) begin

                next_u4_p = fetchP_result;

                next_state = S_AFTER_CALL_32;
            end else begin
                next_state = S_IF_THEN_30_WAIT;
            end

        end

        S_IF_END_31: begin

            // LIR block: if_end_31

            // line 56: u16_t = getQueueLen()





            getQueueLen_start = 1'b1;


            next_state = S_IF_END_31_WAIT;

        end

        S_IF_END_31_WAIT: begin

            // LIR block: if_end_31

            // line 56: u16_t = getQueueLen()

            // wait for blocking primitive: getQueueLen






            if (getQueueLen_done) begin

                next_u16_t = getQueueLen_result;

                next_state = S_AFTER_CALL_49;
            end else begin
                next_state = S_IF_END_31_WAIT;
            end

        end

        S_AFTER_CALL_32: begin

            // LIR block: after_call_32

            // line 45: if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)






            if (getport_comb(u4_p, get_opp_dir_comb(u2_dir))) begin
                next_state = S_IF_THEN_33;
            end else begin
                next_state = S_IF_END_34;
            end

        end

        S_IF_THEN_33: begin

            // LIR block: if_then_33

            // line 46: setVisited(i=u8_ni, j=u8_nj)





            setVisited_i = u8_ni;

            setVisited_j = u8_nj;

            setVisited_start = 1'b1;


            next_state = S_IF_THEN_33_WAIT;

        end

        S_IF_THEN_33_WAIT: begin

            // LIR block: if_then_33

            // line 46: setVisited(i=u8_ni, j=u8_nj)

            // wait for blocking primitive: setVisited






            if (setVisited_done) begin

                next_state = S_AFTER_CALL_35;
            end else begin
                next_state = S_IF_THEN_33_WAIT;
            end

        end

        S_IF_END_34: begin

            // LIR block: if_end_34

            // line 37: if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)






            next_state = S_IF_END_31;

        end

        S_AFTER_CALL_35: begin

            // LIR block: after_call_35

            // line 47: storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)





            storeR_i = u8_ni;

            storeR_j = u8_nj;

            storeR_v = u8_node_idx;

            storeR_start = 1'b1;


            next_state = S_AFTER_CALL_35_WAIT;

        end

        S_AFTER_CALL_35_WAIT: begin

            // LIR block: after_call_35

            // line 47: storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)

            // wait for blocking primitive: storeR






            if (storeR_done) begin

                next_state = S_AFTER_CALL_36;
            end else begin
                next_state = S_AFTER_CALL_35_WAIT;
            end

        end

        S_AFTER_CALL_36: begin

            // LIR block: after_call_36

            // line 48: if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)






            if (getport_comb(u4_p, 32'd0)) begin
                next_state = S_IF_THEN_37;
            end else begin
                next_state = S_IF_END_38;
            end

        end

        S_IF_THEN_37: begin

            // LIR block: if_then_37

            // line 49: addQueue(i=u8_ni, j=u8_nj, d=0)





            addQueue_i = u8_ni;

            addQueue_j = u8_nj;

            addQueue_d = 32'd0;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_37_WAIT;

        end

        S_IF_THEN_37_WAIT: begin

            // LIR block: if_then_37

            // line 49: addQueue(i=u8_ni, j=u8_nj, d=0)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_39;
            end else begin
                next_state = S_IF_THEN_37_WAIT;
            end

        end

        S_IF_END_38: begin

            // LIR block: if_end_38

            // line 50: if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)






            if (getport_comb(u4_p, 32'd1)) begin
                next_state = S_IF_THEN_40;
            end else begin
                next_state = S_IF_END_41;
            end

        end

        S_AFTER_CALL_39: begin

            // LIR block: after_call_39

            // line 48: if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)






            next_state = S_IF_END_38;

        end

        S_IF_THEN_40: begin

            // LIR block: if_then_40

            // line 51: addQueue(i=u8_ni, j=u8_nj, d=1)





            addQueue_i = u8_ni;

            addQueue_j = u8_nj;

            addQueue_d = 32'd1;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_40_WAIT;

        end

        S_IF_THEN_40_WAIT: begin

            // LIR block: if_then_40

            // line 51: addQueue(i=u8_ni, j=u8_nj, d=1)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_42;
            end else begin
                next_state = S_IF_THEN_40_WAIT;
            end

        end

        S_IF_END_41: begin

            // LIR block: if_end_41

            // line 52: if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)






            if (getport_comb(u4_p, 32'd2)) begin
                next_state = S_IF_THEN_43;
            end else begin
                next_state = S_IF_END_44;
            end

        end

        S_AFTER_CALL_42: begin

            // LIR block: after_call_42

            // line 50: if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)






            next_state = S_IF_END_41;

        end

        S_IF_THEN_43: begin

            // LIR block: if_then_43

            // line 53: addQueue(i=u8_ni, j=u8_nj, d=2)





            addQueue_i = u8_ni;

            addQueue_j = u8_nj;

            addQueue_d = 32'd2;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_43_WAIT;

        end

        S_IF_THEN_43_WAIT: begin

            // LIR block: if_then_43

            // line 53: addQueue(i=u8_ni, j=u8_nj, d=2)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_45;
            end else begin
                next_state = S_IF_THEN_43_WAIT;
            end

        end

        S_IF_END_44: begin

            // LIR block: if_end_44

            // line 54: if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)






            if (getport_comb(u4_p, 32'd3)) begin
                next_state = S_IF_THEN_46;
            end else begin
                next_state = S_IF_END_47;
            end

        end

        S_AFTER_CALL_45: begin

            // LIR block: after_call_45

            // line 52: if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)






            next_state = S_IF_END_44;

        end

        S_IF_THEN_46: begin

            // LIR block: if_then_46

            // line 55: addQueue(i=u8_ni, j=u8_nj, d=3)





            addQueue_i = u8_ni;

            addQueue_j = u8_nj;

            addQueue_d = 32'd3;

            addQueue_start = 1'b1;


            next_state = S_IF_THEN_46_WAIT;

        end

        S_IF_THEN_46_WAIT: begin

            // LIR block: if_then_46

            // line 55: addQueue(i=u8_ni, j=u8_nj, d=3)

            // wait for blocking primitive: addQueue






            if (addQueue_done) begin

                next_state = S_AFTER_CALL_48;
            end else begin
                next_state = S_IF_THEN_46_WAIT;
            end

        end

        S_IF_END_47: begin

            // LIR block: if_end_47

            // line 45: if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)






            next_state = S_IF_END_34;

        end

        S_AFTER_CALL_48: begin

            // LIR block: after_call_48

            // line 54: if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)






            next_state = S_IF_END_47;

        end

        S_AFTER_CALL_49: begin

            // LIR block: after_call_49

            // line 29: while u16_t > 0:                     u18_cur = popQueue()                     u8_ni = decode_i_comb(q_item=u18_cur)                     u8_nj = decode_j_comb(q_item=u18_cur)                     u2_dir = decode_d_comb(q_item=u18_cur)                     u8_ni = get_nxt_i_comb(i=u8_ni, d=u2_dir)                     u8_nj = get_nxt_j_comb(j=u8_nj, d=u2_dir)                     u1_f = getVisited(i=u8_ni, j=u8_nj)                     if (                         not u1_f                         and u8_ni >= 0                         and u8_nj >= 0                         and u8_ni < grid_width                         and u8_nj < grid_height                     ):                         u4_p = fetchP(i=u8_ni, j=u8_nj)                         if getport_comb(p=u4_p, i=get_opp_dir_comb(d=u2_dir)):                             setVisited(i=u8_ni, j=u8_nj)                             storeR(i=u8_ni, j=u8_nj, v=u8_node_idx)                             if getport_comb(p=u4_p, i=0):                                 addQueue(i=u8_ni, j=u8_nj, d=0)                             if getport_comb(p=u4_p, i=1):                                 addQueue(i=u8_ni, j=u8_nj, d=1)                             if getport_comb(p=u4_p, i=2):                                 addQueue(i=u8_ni, j=u8_nj, d=2)                             if getport_comb(p=u4_p, i=3):                                 addQueue(i=u8_ni, j=u8_nj, d=3)                     u16_t = getQueueLen()






            next_state = S_WHILE_HEADER_25;

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