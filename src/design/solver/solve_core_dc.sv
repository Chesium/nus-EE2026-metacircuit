
// Generated from LIR for function solve_core_dc

// Entry block: entry

// Blocking primitives: fetchElemKind(latency=1), store_J(latency=1), store_Y(latency=1), store_X(latency=1), store_A(latency=1), store_LU(latency=1), fetchElemN0(latency=1), fetchElemN1(latency=1), fetchElemVal0(latency=1), div(latency=4), accumA(latency=1), accumJ(latency=1), fetch_A(latency=1), fetch_LU(latency=1), fma(latency=3), fetch_J(latency=1), fetch_Y(latency=1), fetch_X(latency=1)

import StampingCombPkg::*;

module solve_core_dc (

    input logic clk,

    input logic rst_n,

    input logic start,

    output logic busy,

    output logic done,

    input logic [31:0] par_elem_n,

    input logic [31:0] par_node_n,

    output logic fetchElemKind_start,

    output logic [15:0] fetchElemKind_idx,

    input logic fetchElemKind_done,

    input logic [7:0] fetchElemKind_result,

    output logic store_J_start,

    output logic [15:0] store_J_i,

    output logic [31:0] store_J_v,

    input logic store_J_done,

    output logic store_Y_start,

    output logic [15:0] store_Y_i,

    output logic [31:0] store_Y_v,

    input logic store_Y_done,

    output logic store_X_start,

    output logic [15:0] store_X_i,

    output logic [31:0] store_X_v,

    input logic store_X_done,

    output logic store_A_start,

    output logic [15:0] store_A_i,

    output logic [15:0] store_A_j,

    output logic [31:0] store_A_v,

    input logic store_A_done,

    output logic store_LU_start,

    output logic [15:0] store_LU_i,

    output logic [15:0] store_LU_j,

    output logic [31:0] store_LU_v,

    input logic store_LU_done,

    output logic fetchElemN0_start,

    output logic [15:0] fetchElemN0_idx,

    input logic fetchElemN0_done,

    input logic [7:0] fetchElemN0_result,

    output logic fetchElemN1_start,

    output logic [15:0] fetchElemN1_idx,

    input logic fetchElemN1_done,

    input logic [7:0] fetchElemN1_result,

    output logic fetchElemVal0_start,

    output logic [15:0] fetchElemVal0_idx,

    input logic fetchElemVal0_done,

    input logic [31:0] fetchElemVal0_result,

    output logic div_start,

    output logic [31:0] div_a,

    output logic [31:0] div_b,

    input logic div_done,

    input logic [31:0] div_result,

    output logic accumA_start,

    output logic [7:0] accumA_i,

    output logic [7:0] accumA_j,

    output logic [31:0] accumA_delta,

    input logic accumA_done,

    output logic accumJ_start,

    output logic [7:0] accumJ_i,

    output logic [31:0] accumJ_delta,

    input logic accumJ_done,

    output logic fetch_A_start,

    output logic [15:0] fetch_A_i,

    output logic [15:0] fetch_A_j,

    input logic fetch_A_done,

    input logic [31:0] fetch_A_result,

    output logic fetch_LU_start,

    output logic [15:0] fetch_LU_i,

    output logic [15:0] fetch_LU_j,

    input logic fetch_LU_done,

    input logic [31:0] fetch_LU_result,

    output logic fma_start,

    output logic [31:0] fma_a,

    output logic [31:0] fma_b,

    output logic [31:0] fma_c,

    input logic fma_done,

    input logic [31:0] fma_result,

    output logic fetch_J_start,

    output logic [15:0] fetch_J_i,

    input logic fetch_J_done,

    input logic [31:0] fetch_J_result,

    output logic fetch_Y_start,

    output logic [15:0] fetch_Y_i,

    input logic fetch_Y_done,

    input logic [31:0] fetch_Y_result,

    output logic fetch_X_start,

    output logic [15:0] fetch_X_i,

    input logic fetch_X_done,

    input logic [31:0] fetch_X_result

);



import StampingCombPkg::*;

typedef enum logic [7:0] {

    S_IDLE,

    S_ENTRY,

    S_FOR_HEADER_0,

    S_FOR_BODY_1,

    S_FOR_BODY_1_WAIT,

    S_FOR_END_2,

    S_AFTER_CALL_3,

    S_IF_THEN_4,

    S_IF_END_5,

    S_FOR_HEADER_6,

    S_FOR_BODY_7,

    S_FOR_BODY_7_WAIT,

    S_FOR_END_8,

    S_AFTER_CALL_9,

    S_AFTER_CALL_9_WAIT,

    S_AFTER_CALL_10,

    S_AFTER_CALL_10_WAIT,

    S_AFTER_CALL_11,

    S_FOR_HEADER_12,

    S_FOR_BODY_13,

    S_FOR_BODY_13_WAIT,

    S_FOR_END_14,

    S_AFTER_CALL_15,

    S_AFTER_CALL_15_WAIT,

    S_AFTER_CALL_16,

    S_FOR_HEADER_17,

    S_FOR_BODY_18,

    S_FOR_BODY_18_WAIT,

    S_FOR_END_19,

    S_AFTER_CALL_20,

    S_AFTER_CALL_20_WAIT,

    S_AFTER_CALL_21,

    S_AFTER_CALL_21_WAIT,

    S_AFTER_CALL_22,

    S_AFTER_CALL_22_WAIT,

    S_AFTER_CALL_23,

    S_IF_THEN_24,

    S_IF_THEN_24_WAIT,

    S_IF_END_25,

    S_AFTER_CALL_26,

    S_IF_THEN_27,

    S_IF_THEN_27_WAIT,

    S_IF_END_28,

    S_AFTER_CALL_29,

    S_IF_THEN_30,

    S_IF_THEN_30_WAIT,

    S_IF_END_31,

    S_AFTER_CALL_32,

    S_AFTER_CALL_32_WAIT,

    S_AFTER_CALL_33,

    S_IF_THEN_34,

    S_IF_THEN_34_WAIT,

    S_IF_END_35,

    S_AFTER_CALL_36,

    S_IF_THEN_37,

    S_IF_END_38,

    S_IF_THEN_39,

    S_IF_THEN_39_WAIT,

    S_IF_END_40,

    S_AFTER_CALL_41,

    S_IF_THEN_42,

    S_IF_THEN_42_WAIT,

    S_IF_END_43,

    S_AFTER_CALL_44,

    S_IF_THEN_45,

    S_IF_END_46,

    S_IF_THEN_47,

    S_IF_THEN_47_WAIT,

    S_IF_END_48,

    S_AFTER_CALL_49,

    S_AFTER_CALL_49_WAIT,

    S_AFTER_CALL_50,

    S_IF_THEN_51,

    S_IF_THEN_51_WAIT,

    S_IF_END_52,

    S_IF_END_52_WAIT,

    S_AFTER_CALL_53,

    S_AFTER_CALL_53_WAIT,

    S_AFTER_CALL_54,

    S_AFTER_CALL_55,

    S_FOR_HEADER_56,

    S_FOR_BODY_57,

    S_FOR_BODY_57_WAIT,

    S_FOR_END_58,

    S_AFTER_CALL_59,

    S_FOR_HEADER_60,

    S_FOR_BODY_61,

    S_FOR_BODY_61_WAIT,

    S_FOR_END_62,

    S_AFTER_CALL_63,

    S_AFTER_CALL_63_WAIT,

    S_AFTER_CALL_64,

    S_AFTER_CALL_64_WAIT,

    S_AFTER_CALL_65,

    S_WHILE_HEADER_66,

    S_WHILE_BODY_67,

    S_WHILE_BODY_67_WAIT,

    S_WHILE_END_68,

    S_AFTER_CALL_69,

    S_FOR_HEADER_70,

    S_FOR_BODY_71,

    S_FOR_BODY_71_WAIT,

    S_FOR_END_72,

    S_AFTER_CALL_73,

    S_AFTER_CALL_73_WAIT,

    S_AFTER_CALL_74,

    S_AFTER_CALL_74_WAIT,

    S_AFTER_CALL_75,

    S_IF_THEN_76,

    S_IF_END_77,

    S_IF_THEN_78,

    S_IF_END_79,

    S_FOR_HEADER_80,

    S_FOR_BODY_81,

    S_FOR_BODY_81_WAIT,

    S_FOR_END_82,

    S_AFTER_CALL_83,

    S_AFTER_CALL_83_WAIT,

    S_AFTER_CALL_84,

    S_AFTER_CALL_84_WAIT,

    S_AFTER_CALL_85,

    S_AFTER_CALL_85_WAIT,

    S_AFTER_CALL_86,

    S_FOR_HEADER_87,

    S_FOR_BODY_88,

    S_FOR_BODY_88_WAIT,

    S_FOR_END_89,

    S_FOR_END_89_WAIT,

    S_AFTER_CALL_90,

    S_AFTER_CALL_90_WAIT,

    S_AFTER_CALL_91,

    S_AFTER_CALL_91_WAIT,

    S_AFTER_CALL_92,

    S_AFTER_CALL_92_WAIT,

    S_AFTER_CALL_93,

    S_AFTER_CALL_94,

    S_AFTER_CALL_94_WAIT,

    S_AFTER_CALL_95,

    S_AFTER_CALL_95_WAIT,

    S_AFTER_CALL_96,

    S_AFTER_CALL_96_WAIT,

    S_AFTER_CALL_97,

    S_FOR_HEADER_98,

    S_FOR_BODY_99,

    S_FOR_BODY_99_WAIT,

    S_FOR_END_100,

    S_AFTER_CALL_101,

    S_FOR_HEADER_102,

    S_FOR_BODY_103,

    S_FOR_BODY_103_WAIT,

    S_FOR_END_104,

    S_AFTER_CALL_105,

    S_AFTER_CALL_105_WAIT,

    S_AFTER_CALL_106,

    S_AFTER_CALL_106_WAIT,

    S_AFTER_CALL_107,

    S_IF_THEN_108,

    S_IF_THEN_108_WAIT,

    S_IF_END_109,

    S_IF_END_109_WAIT,

    S_AFTER_CALL_110,

    S_AFTER_CALL_110_WAIT,

    S_AFTER_CALL_111,

    S_AFTER_CALL_112,

    S_FOR_HEADER_113,

    S_FOR_BODY_114,

    S_FOR_BODY_114_WAIT,

    S_FOR_END_115,

    S_AFTER_CALL_116,

    S_FOR_HEADER_117,

    S_FOR_BODY_118,

    S_FOR_BODY_118_WAIT,

    S_FOR_END_119,

    S_FOR_END_119_WAIT,

    S_AFTER_CALL_120,

    S_AFTER_CALL_120_WAIT,

    S_AFTER_CALL_121,

    S_AFTER_CALL_121_WAIT,

    S_AFTER_CALL_122,

    S_AFTER_CALL_123,

    S_WHILE_HEADER_124,

    S_WHILE_BODY_125,

    S_WHILE_BODY_125_WAIT,

    S_WHILE_END_126,

    S_AFTER_CALL_127,

    S_WHILE_HEADER_128,

    S_WHILE_BODY_129,

    S_WHILE_BODY_129_WAIT,

    S_WHILE_END_130,

    S_WHILE_END_130_WAIT,

    S_AFTER_CALL_131,

    S_AFTER_CALL_131_WAIT,

    S_AFTER_CALL_132,

    S_AFTER_CALL_132_WAIT,

    S_AFTER_CALL_133,

    S_AFTER_CALL_134,

    S_AFTER_CALL_134_WAIT,

    S_AFTER_CALL_135,

    S_AFTER_CALL_135_WAIT,

    S_AFTER_CALL_136,

    S_DONE

} state_t;

state_t state;
state_t next_state;


logic [31:0] f32_0;

logic [31:0] f32_1;

logic [31:0] f32_2;

logic [31:0] f32_3;

logic [31:0] f32_4;

logic [31:0] f32_5;

logic [7:0] u8_kind;

logic [7:0] u8_aux;

logic [15:0] u16_dim;

logic [15:0] u16_e;

logic [15:0] u16_i;

logic [15:0] u16_j;

logic [15:0] u16_k;

logic [15:0] u16_m;

logic [7:0] u8_n0;

logic [7:0] u8_n1;

logic [7:0] u8_next_aux;

logic [15:0] u16_pivot;


logic [15:0] __for_idx_0;

logic [15:0] __for_idx_1;

logic [15:0] __for_idx_2;

logic [15:0] __for_idx_3;

logic [15:0] __for_idx_4;

logic [15:0] __for_idx_5;

logic [15:0] __for_idx_6;

logic [15:0] __for_idx_7;

logic [15:0] __for_idx_8;

logic [15:0] __for_idx_9;

logic [15:0] __for_idx_10;

logic [15:0] __for_idx_11;

logic [15:0] __for_idx_12;



logic [31:0] next_f32_0;

logic [31:0] next_f32_1;

logic [31:0] next_f32_2;

logic [31:0] next_f32_3;

logic [31:0] next_f32_4;

logic [31:0] next_f32_5;

logic [7:0] next_u8_kind;

logic [7:0] next_u8_aux;

logic [15:0] next_u16_dim;

logic [15:0] next_u16_e;

logic [15:0] next_u16_i;

logic [15:0] next_u16_j;

logic [15:0] next_u16_k;

logic [15:0] next_u16_m;

logic [7:0] next_u8_n0;

logic [7:0] next_u8_n1;

logic [7:0] next_u8_next_aux;

logic [15:0] next_u16_pivot;

logic [15:0] next___for_idx_0;

logic [15:0] next___for_idx_1;

logic [15:0] next___for_idx_2;

logic [15:0] next___for_idx_3;

logic [15:0] next___for_idx_4;

logic [15:0] next___for_idx_5;

logic [15:0] next___for_idx_6;

logic [15:0] next___for_idx_7;

logic [15:0] next___for_idx_8;

logic [15:0] next___for_idx_9;

logic [15:0] next___for_idx_10;

logic [15:0] next___for_idx_11;

logic [15:0] next___for_idx_12;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        f32_0 <=0;

        f32_1 <=0;

        f32_2 <=0;

        f32_3 <=0;

        f32_4 <=0;

        f32_5 <=0;

        u8_kind <=0;

        u8_aux <=0;

        u16_dim <=0;

        u16_e <=0;

        u16_i <=0;

        u16_j <=0;

        u16_k <=0;

        u16_m <=0;

        u8_n0 <=0;

        u8_n1 <=0;

        u8_next_aux <=0;

        u16_pivot <=0;


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

        __for_idx_12 <=0;


    end else begin
        state <= next_state;

        f32_0 <= next_f32_0;

        f32_1 <= next_f32_1;

        f32_2 <= next_f32_2;

        f32_3 <= next_f32_3;

        f32_4 <= next_f32_4;

        f32_5 <= next_f32_5;

        u8_kind <= next_u8_kind;

        u8_aux <= next_u8_aux;

        u16_dim <= next_u16_dim;

        u16_e <= next_u16_e;

        u16_i <= next_u16_i;

        u16_j <= next_u16_j;

        u16_k <= next_u16_k;

        u16_m <= next_u16_m;

        u8_n0 <= next_u8_n0;

        u8_n1 <= next_u8_n1;

        u8_next_aux <= next_u8_next_aux;

        u16_pivot <= next_u16_pivot;


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

        __for_idx_12 <= next___for_idx_12;


    end
end

always_comb begin
    next_state = state;
    busy = 1'b1;
    done = 1'b0;

    next_f32_0 = f32_0;

    next_f32_1 = f32_1;

    next_f32_2 = f32_2;

    next_f32_3 = f32_3;

    next_f32_4 = f32_4;

    next_f32_5 = f32_5;

    next_u8_kind = u8_kind;

    next_u8_aux = u8_aux;

    next_u16_dim = u16_dim;

    next_u16_e = u16_e;

    next_u16_i = u16_i;

    next_u16_j = u16_j;

    next_u16_k = u16_k;

    next_u16_m = u16_m;

    next_u8_n0 = u8_n0;

    next_u8_n1 = u8_n1;

    next_u8_next_aux = u8_next_aux;

    next_u16_pivot = u16_pivot;


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

    next___for_idx_12 = __for_idx_12;



    fetchElemKind_start =0;

    fetchElemKind_idx =0;

    store_J_start =0;

    store_J_i =0;

    store_J_v =0;

    store_Y_start =0;

    store_Y_i =0;

    store_Y_v =0;

    store_X_start =0;

    store_X_i =0;

    store_X_v =0;

    store_A_start =0;

    store_A_i =0;

    store_A_j =0;

    store_A_v =0;

    store_LU_start =0;

    store_LU_i =0;

    store_LU_j =0;

    store_LU_v =0;

    fetchElemN0_start =0;

    fetchElemN0_idx =0;

    fetchElemN1_start =0;

    fetchElemN1_idx =0;

    fetchElemVal0_start =0;

    fetchElemVal0_idx =0;

    div_start =0;

    div_a =0;

    div_b =0;

    accumA_start =0;

    accumA_i =0;

    accumA_j =0;

    accumA_delta =0;

    accumJ_start =0;

    accumJ_i =0;

    accumJ_delta =0;

    fetch_A_start =0;

    fetch_A_i =0;

    fetch_A_j =0;

    fetch_LU_start =0;

    fetch_LU_i =0;

    fetch_LU_j =0;

    fma_start =0;

    fma_a =0;

    fma_b =0;

    fma_c =0;

    fetch_J_start =0;

    fetch_J_i =0;

    fetch_Y_start =0;

    fetch_Y_i =0;

    fetch_X_start =0;

    fetch_X_i =0;


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

            // line 65: f32_0 = 0




            next_f32_0 = 32'h00000000;

            next_f32_1 = 32'h00000000;

            next_f32_2 = 32'h00000000;

            next_f32_3 = 32'h00000000;

            next_f32_4 = 32'h00000000;

            next_f32_5 = 32'h3f800000;

            next_u8_kind = 8'd0;

            next_u8_aux = 8'd0;

            next_u16_dim = 16'd0;

            next_u16_e = 16'd0;

            next_u16_i = 16'd0;

            next_u16_j = 16'd0;

            next_u16_k = 16'd0;

            next_u16_m = 16'd0;

            next_u8_n0 = 8'd0;

            next_u8_n1 = 8'd0;

            next_u8_next_aux = 8'd0;

            next_u16_pivot = 16'd0;

            next_u16_dim = par_node_n;

            next___for_idx_0 = 16'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 92: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1






            if ((__for_idx_0 < par_elem_n)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 92: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1




            next_u16_e = __for_idx_0;


            fetchElemKind_idx = __for_idx_0;

            fetchElemKind_start = 1'b1;


            next_state = S_FOR_BODY_1_WAIT;

        end

        S_FOR_BODY_1_WAIT: begin

            // LIR block: for_body_1

            // line 92: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1

            // wait for blocking primitive: fetchElemKind






            if (fetchElemKind_done) begin

                next_u8_kind = fetchElemKind_result;

                next_state = S_AFTER_CALL_3;
            end else begin
                next_state = S_FOR_BODY_1_WAIT;
            end

        end

        S_FOR_END_2: begin

            // LIR block: for_end_2

            // line 103: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_1 = 16'd0;



            next_state = S_FOR_HEADER_6;

        end

        S_AFTER_CALL_3: begin

            // LIR block: after_call_3

            // line 94: if u8_kind == 3:             u16_dim = u16_dim + 1






            if ((u8_kind == 32'd3)) begin
                next_state = S_IF_THEN_4;
            end else begin
                next_state = S_IF_END_5;
            end

        end

        S_IF_THEN_4: begin

            // LIR block: if_then_4

            // line 95: u16_dim = u16_dim + 1




            next_u16_dim = (u16_dim + 16'd1);



            next_state = S_IF_END_5;

        end

        S_IF_END_5: begin

            // LIR block: if_end_5

            // line 92: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1




            next___for_idx_0 = (__for_idx_0 + 16'd1);



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_6: begin

            // LIR block: for_header_6

            // line 103: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)






            if ((__for_idx_1 < u16_dim)) begin
                next_state = S_FOR_BODY_7;
            end else begin
                next_state = S_FOR_END_8;
            end

        end

        S_FOR_BODY_7: begin

            // LIR block: for_body_7

            // line 103: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next_u16_i = __for_idx_1;


            store_J_i = __for_idx_1;

            store_J_v = f32_0;

            store_J_start = 1'b1;


            next_state = S_FOR_BODY_7_WAIT;

        end

        S_FOR_BODY_7_WAIT: begin

            // LIR block: for_body_7

            // line 103: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_9;
            end else begin
                next_state = S_FOR_BODY_7_WAIT;
            end

        end

        S_FOR_END_8: begin

            // LIR block: for_end_8

            // line 119: u8_next_aux = par_node_n




            next_u8_next_aux = par_node_n;

            next___for_idx_3 = 16'd0;



            next_state = S_FOR_HEADER_17;

        end

        S_AFTER_CALL_9: begin

            // LIR block: after_call_9

            // line 105: store_Y(i=u16_i, v=f32_0)





            store_Y_i = u16_i;

            store_Y_v = f32_0;

            store_Y_start = 1'b1;


            next_state = S_AFTER_CALL_9_WAIT;

        end

        S_AFTER_CALL_9_WAIT: begin

            // LIR block: after_call_9

            // line 105: store_Y(i=u16_i, v=f32_0)

            // wait for blocking primitive: store_Y






            if (store_Y_done) begin

                next_state = S_AFTER_CALL_10;
            end else begin
                next_state = S_AFTER_CALL_9_WAIT;
            end

        end

        S_AFTER_CALL_10: begin

            // LIR block: after_call_10

            // line 106: store_X(i=u16_i, v=f32_0)





            store_X_i = u16_i;

            store_X_v = f32_0;

            store_X_start = 1'b1;


            next_state = S_AFTER_CALL_10_WAIT;

        end

        S_AFTER_CALL_10_WAIT: begin

            // LIR block: after_call_10

            // line 106: store_X(i=u16_i, v=f32_0)

            // wait for blocking primitive: store_X






            if (store_X_done) begin

                next_state = S_AFTER_CALL_11;
            end else begin
                next_state = S_AFTER_CALL_10_WAIT;
            end

        end

        S_AFTER_CALL_11: begin

            // LIR block: after_call_11

            // line 107: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_2 = 16'd0;



            next_state = S_FOR_HEADER_12;

        end

        S_FOR_HEADER_12: begin

            // LIR block: for_header_12

            // line 107: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)






            if ((__for_idx_2 < u16_dim)) begin
                next_state = S_FOR_BODY_13;
            end else begin
                next_state = S_FOR_END_14;
            end

        end

        S_FOR_BODY_13: begin

            // LIR block: for_body_13

            // line 107: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next_u16_j = __for_idx_2;


            store_A_i = u16_i;

            store_A_j = __for_idx_2;

            store_A_v = f32_0;

            store_A_start = 1'b1;


            next_state = S_FOR_BODY_13_WAIT;

        end

        S_FOR_BODY_13_WAIT: begin

            // LIR block: for_body_13

            // line 107: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_15;
            end else begin
                next_state = S_FOR_BODY_13_WAIT;
            end

        end

        S_FOR_END_14: begin

            // LIR block: for_end_14

            // line 103: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_1 = (__for_idx_1 + 16'd1);



            next_state = S_FOR_HEADER_6;

        end

        S_AFTER_CALL_15: begin

            // LIR block: after_call_15

            // line 109: store_LU(i=u16_i, j=u16_j, v=f32_0)





            store_LU_i = u16_i;

            store_LU_j = u16_j;

            store_LU_v = f32_0;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_15_WAIT;

        end

        S_AFTER_CALL_15_WAIT: begin

            // LIR block: after_call_15

            // line 109: store_LU(i=u16_i, j=u16_j, v=f32_0)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_16;
            end else begin
                next_state = S_AFTER_CALL_15_WAIT;
            end

        end

        S_AFTER_CALL_16: begin

            // LIR block: after_call_16

            // line 107: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_2 = (__for_idx_2 + 16'd1);



            next_state = S_FOR_HEADER_12;

        end

        S_FOR_HEADER_17: begin

            // LIR block: for_header_17

            // line 120: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)          # Resistor stamp:         #   g = 1 / R         #   [ +g  -g ]         #   [ -g  +g ]         if u8_kind == 1:             f32_2 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)          # Current source stamp:         # current is defined from n0 -> n1, so it subtracts from the n0 entry         # of J and adds to the n1 entry.         if u8_kind == 2:             if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          # Independent voltage source stamp:         # allocate a fresh branch-variable row/column and emit the standard         # MNA coupling terms plus the source value into J.         if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)






            if ((__for_idx_3 < par_elem_n)) begin
                next_state = S_FOR_BODY_18;
            end else begin
                next_state = S_FOR_END_19;
            end

        end

        S_FOR_BODY_18: begin

            // LIR block: for_body_18

            // line 120: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)          # Resistor stamp:         #   g = 1 / R         #   [ +g  -g ]         #   [ -g  +g ]         if u8_kind == 1:             f32_2 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)          # Current source stamp:         # current is defined from n0 -> n1, so it subtracts from the n0 entry         # of J and adds to the n1 entry.         if u8_kind == 2:             if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          # Independent voltage source stamp:         # allocate a fresh branch-variable row/column and emit the standard         # MNA coupling terms plus the source value into J.         if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)




            next_u16_e = __for_idx_3;


            fetchElemKind_idx = __for_idx_3;

            fetchElemKind_start = 1'b1;


            next_state = S_FOR_BODY_18_WAIT;

        end

        S_FOR_BODY_18_WAIT: begin

            // LIR block: for_body_18

            // line 120: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)          # Resistor stamp:         #   g = 1 / R         #   [ +g  -g ]         #   [ -g  +g ]         if u8_kind == 1:             f32_2 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)          # Current source stamp:         # current is defined from n0 -> n1, so it subtracts from the n0 entry         # of J and adds to the n1 entry.         if u8_kind == 2:             if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          # Independent voltage source stamp:         # allocate a fresh branch-variable row/column and emit the standard         # MNA coupling terms plus the source value into J.         if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)

            // wait for blocking primitive: fetchElemKind






            if (fetchElemKind_done) begin

                next_u8_kind = fetchElemKind_result;

                next_state = S_AFTER_CALL_20;
            end else begin
                next_state = S_FOR_BODY_18_WAIT;
            end

        end

        S_FOR_END_19: begin

            // LIR block: for_end_19

            // line 178: for u16_j in range(u16_dim):         # Search the best pivot row in the current column using the residual         # values that would become U(*, j) before division.         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          # Row swaps must keep A, the already materialized lower triangle in LU,         # and the RHS J consistent with each other.         if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          # Compute column j of packed LU.         # - when i <= j, we are producing U(i, j)         # - when i >  j, we are producing L(i, j) = residual / U(j, j)         for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_4 = 16'd0;



            next_state = S_FOR_HEADER_56;

        end

        S_AFTER_CALL_20: begin

            // LIR block: after_call_20

            // line 122: u8_n0 = fetchElemN0(idx=u16_e)





            fetchElemN0_idx = u16_e;

            fetchElemN0_start = 1'b1;


            next_state = S_AFTER_CALL_20_WAIT;

        end

        S_AFTER_CALL_20_WAIT: begin

            // LIR block: after_call_20

            // line 122: u8_n0 = fetchElemN0(idx=u16_e)

            // wait for blocking primitive: fetchElemN0






            if (fetchElemN0_done) begin

                next_u8_n0 = fetchElemN0_result;

                next_state = S_AFTER_CALL_21;
            end else begin
                next_state = S_AFTER_CALL_20_WAIT;
            end

        end

        S_AFTER_CALL_21: begin

            // LIR block: after_call_21

            // line 123: u8_n1 = fetchElemN1(idx=u16_e)





            fetchElemN1_idx = u16_e;

            fetchElemN1_start = 1'b1;


            next_state = S_AFTER_CALL_21_WAIT;

        end

        S_AFTER_CALL_21_WAIT: begin

            // LIR block: after_call_21

            // line 123: u8_n1 = fetchElemN1(idx=u16_e)

            // wait for blocking primitive: fetchElemN1






            if (fetchElemN1_done) begin

                next_u8_n1 = fetchElemN1_result;

                next_state = S_AFTER_CALL_22;
            end else begin
                next_state = S_AFTER_CALL_21_WAIT;
            end

        end

        S_AFTER_CALL_22: begin

            // LIR block: after_call_22

            // line 124: f32_1 = fetchElemVal0(idx=u16_e)





            fetchElemVal0_idx = u16_e;

            fetchElemVal0_start = 1'b1;


            next_state = S_AFTER_CALL_22_WAIT;

        end

        S_AFTER_CALL_22_WAIT: begin

            // LIR block: after_call_22

            // line 124: f32_1 = fetchElemVal0(idx=u16_e)

            // wait for blocking primitive: fetchElemVal0






            if (fetchElemVal0_done) begin

                next_f32_1 = fetchElemVal0_result;

                next_state = S_AFTER_CALL_23;
            end else begin
                next_state = S_AFTER_CALL_22_WAIT;
            end

        end

        S_AFTER_CALL_23: begin

            // LIR block: after_call_23

            // line 130: if u8_kind == 1:             f32_2 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)






            if ((u8_kind == 32'd1)) begin
                next_state = S_IF_THEN_24;
            end else begin
                next_state = S_IF_END_25;
            end

        end

        S_IF_THEN_24: begin

            // LIR block: if_then_24

            // line 131: f32_2 = div(a=f32_5, b=f32_1)





            div_a = f32_5;

            div_b = f32_1;

            div_start = 1'b1;


            next_state = S_IF_THEN_24_WAIT;

        end

        S_IF_THEN_24_WAIT: begin

            // LIR block: if_then_24

            // line 131: f32_2 = div(a=f32_5, b=f32_1)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_2 = div_result;

                next_state = S_AFTER_CALL_26;
            end else begin
                next_state = S_IF_THEN_24_WAIT;
            end

        end

        S_IF_END_25: begin

            // LIR block: if_end_25

            // line 144: if u8_kind == 2:             if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            if ((u8_kind == 32'd2)) begin
                next_state = S_IF_THEN_37;
            end else begin
                next_state = S_IF_END_38;
            end

        end

        S_AFTER_CALL_26: begin

            // LIR block: after_call_26

            // line 132: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_27;
            end else begin
                next_state = S_IF_END_28;
            end

        end

        S_IF_THEN_27: begin

            // LIR block: if_then_27

            // line 133: accumA(i=u8_n0, j=u8_n0, delta=f32_2)





            accumA_i = u8_n0;

            accumA_j = u8_n0;

            accumA_delta = f32_2;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_27_WAIT;

        end

        S_IF_THEN_27_WAIT: begin

            // LIR block: if_then_27

            // line 133: accumA(i=u8_n0, j=u8_n0, delta=f32_2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_29;
            end else begin
                next_state = S_IF_THEN_27_WAIT;
            end

        end

        S_IF_END_28: begin

            // LIR block: if_end_28

            // line 138: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_34;
            end else begin
                next_state = S_IF_END_35;
            end

        end

        S_AFTER_CALL_29: begin

            // LIR block: after_call_29

            // line 134: if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_30;
            end else begin
                next_state = S_IF_END_31;
            end

        end

        S_IF_THEN_30: begin

            // LIR block: if_then_30

            // line 135: f32_3 = neg_comb(v=f32_2)




            next_f32_3 = neg_comb(f32_2);


            accumA_i = u8_n0;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_2);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_30_WAIT;

        end

        S_IF_THEN_30_WAIT: begin

            // LIR block: if_then_30

            // line 135: f32_3 = neg_comb(v=f32_2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_32;
            end else begin
                next_state = S_IF_THEN_30_WAIT;
            end

        end

        S_IF_END_31: begin

            // LIR block: if_end_31

            // line 132: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)






            next_state = S_IF_END_28;

        end

        S_AFTER_CALL_32: begin

            // LIR block: after_call_32

            // line 137: accumA(i=u8_n1, j=u8_n0, delta=f32_3)





            accumA_i = u8_n1;

            accumA_j = u8_n0;

            accumA_delta = f32_3;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_32_WAIT;

        end

        S_AFTER_CALL_32_WAIT: begin

            // LIR block: after_call_32

            // line 137: accumA(i=u8_n1, j=u8_n0, delta=f32_3)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_33;
            end else begin
                next_state = S_AFTER_CALL_32_WAIT;
            end

        end

        S_AFTER_CALL_33: begin

            // LIR block: after_call_33

            // line 134: if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)






            next_state = S_IF_END_31;

        end

        S_IF_THEN_34: begin

            // LIR block: if_then_34

            // line 139: accumA(i=u8_n1, j=u8_n1, delta=f32_2)





            accumA_i = u8_n1;

            accumA_j = u8_n1;

            accumA_delta = f32_2;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_34_WAIT;

        end

        S_IF_THEN_34_WAIT: begin

            // LIR block: if_then_34

            // line 139: accumA(i=u8_n1, j=u8_n1, delta=f32_2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_36;
            end else begin
                next_state = S_IF_THEN_34_WAIT;
            end

        end

        S_IF_END_35: begin

            // LIR block: if_end_35

            // line 130: if u8_kind == 1:             f32_2 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)






            next_state = S_IF_END_25;

        end

        S_AFTER_CALL_36: begin

            // LIR block: after_call_36

            // line 138: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)






            next_state = S_IF_END_35;

        end

        S_IF_THEN_37: begin

            // LIR block: if_then_37

            // line 145: if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_39;
            end else begin
                next_state = S_IF_END_40;
            end

        end

        S_IF_END_38: begin

            // LIR block: if_end_38

            // line 154: if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)






            if ((u8_kind == 32'd3)) begin
                next_state = S_IF_THEN_45;
            end else begin
                next_state = S_IF_END_46;
            end

        end

        S_IF_THEN_39: begin

            // LIR block: if_then_39

            // line 146: f32_2 = neg_comb(v=f32_1)




            next_f32_2 = neg_comb(f32_1);


            accumJ_i = u8_n0;

            accumJ_delta = neg_comb(f32_1);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_39_WAIT;

        end

        S_IF_THEN_39_WAIT: begin

            // LIR block: if_then_39

            // line 146: f32_2 = neg_comb(v=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_41;
            end else begin
                next_state = S_IF_THEN_39_WAIT;
            end

        end

        S_IF_END_40: begin

            // LIR block: if_end_40

            // line 148: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_42;
            end else begin
                next_state = S_IF_END_43;
            end

        end

        S_AFTER_CALL_41: begin

            // LIR block: after_call_41

            // line 145: if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)






            next_state = S_IF_END_40;

        end

        S_IF_THEN_42: begin

            // LIR block: if_then_42

            // line 149: accumJ(i=u8_n1, delta=f32_1)





            accumJ_i = u8_n1;

            accumJ_delta = f32_1;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_42_WAIT;

        end

        S_IF_THEN_42_WAIT: begin

            // LIR block: if_then_42

            // line 149: accumJ(i=u8_n1, delta=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_44;
            end else begin
                next_state = S_IF_THEN_42_WAIT;
            end

        end

        S_IF_END_43: begin

            // LIR block: if_end_43

            // line 144: if u8_kind == 2:             if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            next_state = S_IF_END_38;

        end

        S_AFTER_CALL_44: begin

            // LIR block: after_call_44

            // line 148: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            next_state = S_IF_END_43;

        end

        S_IF_THEN_45: begin

            // LIR block: if_then_45

            // line 155: u8_aux = u8_next_aux




            next_u8_aux = u8_next_aux;

            next_u8_next_aux = (u8_next_aux + 8'd1);



            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_47;
            end else begin
                next_state = S_IF_END_48;
            end

        end

        S_IF_END_46: begin

            // LIR block: if_end_46

            // line 120: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)          # Resistor stamp:         #   g = 1 / R         #   [ +g  -g ]         #   [ -g  +g ]         if u8_kind == 1:             f32_2 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_2)                 if u8_n1 != 255:                     f32_3 = neg_comb(v=f32_2)                     accumA(i=u8_n0, j=u8_n1, delta=f32_3)                     accumA(i=u8_n1, j=u8_n0, delta=f32_3)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_2)          # Current source stamp:         # current is defined from n0 -> n1, so it subtracts from the n0 entry         # of J and adds to the n1 entry.         if u8_kind == 2:             if u8_n0 != 255:                 f32_2 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          # Independent voltage source stamp:         # allocate a fresh branch-variable row/column and emit the standard         # MNA coupling terms plus the source value into J.         if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)




            next___for_idx_3 = (__for_idx_3 + 16'd1);



            next_state = S_FOR_HEADER_17;

        end

        S_IF_THEN_47: begin

            // LIR block: if_then_47

            // line 158: accumA(i=u8_aux, j=u8_n0, delta=f32_5)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_47_WAIT;

        end

        S_IF_THEN_47_WAIT: begin

            // LIR block: if_then_47

            // line 158: accumA(i=u8_aux, j=u8_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_49;
            end else begin
                next_state = S_IF_THEN_47_WAIT;
            end

        end

        S_IF_END_48: begin

            // LIR block: if_end_48

            // line 161: if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_51;
            end else begin
                next_state = S_IF_END_52;
            end

        end

        S_AFTER_CALL_49: begin

            // LIR block: after_call_49

            // line 159: f32_2 = neg_comb(v=f32_5)




            next_f32_2 = neg_comb(f32_5);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_49_WAIT;

        end

        S_AFTER_CALL_49_WAIT: begin

            // LIR block: after_call_49

            // line 159: f32_2 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_50;
            end else begin
                next_state = S_AFTER_CALL_49_WAIT;
            end

        end

        S_AFTER_CALL_50: begin

            // LIR block: after_call_50

            // line 157: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)






            next_state = S_IF_END_48;

        end

        S_IF_THEN_51: begin

            // LIR block: if_then_51

            // line 162: f32_2 = neg_comb(v=f32_5)




            next_f32_2 = neg_comb(f32_5);


            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_51_WAIT;

        end

        S_IF_THEN_51_WAIT: begin

            // LIR block: if_then_51

            // line 162: f32_2 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_53;
            end else begin
                next_state = S_IF_THEN_51_WAIT;
            end

        end

        S_IF_END_52: begin

            // LIR block: if_end_52

            // line 165: accumJ(i=u8_aux, delta=f32_1)





            accumJ_i = u8_aux;

            accumJ_delta = f32_1;

            accumJ_start = 1'b1;


            next_state = S_IF_END_52_WAIT;

        end

        S_IF_END_52_WAIT: begin

            // LIR block: if_end_52

            // line 165: accumJ(i=u8_aux, delta=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_55;
            end else begin
                next_state = S_IF_END_52_WAIT;
            end

        end

        S_AFTER_CALL_53: begin

            // LIR block: after_call_53

            // line 164: accumA(i=u8_n1, j=u8_aux, delta=f32_5)





            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_53_WAIT;

        end

        S_AFTER_CALL_53_WAIT: begin

            // LIR block: after_call_53

            // line 164: accumA(i=u8_n1, j=u8_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_54;
            end else begin
                next_state = S_AFTER_CALL_53_WAIT;
            end

        end

        S_AFTER_CALL_54: begin

            // LIR block: after_call_54

            // line 161: if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            next_state = S_IF_END_52;

        end

        S_AFTER_CALL_55: begin

            // LIR block: after_call_55

            // line 154: if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)






            next_state = S_IF_END_46;

        end

        S_FOR_HEADER_56: begin

            // LIR block: for_header_56

            // line 178: for u16_j in range(u16_dim):         # Search the best pivot row in the current column using the residual         # values that would become U(*, j) before division.         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          # Row swaps must keep A, the already materialized lower triangle in LU,         # and the RHS J consistent with each other.         if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          # Compute column j of packed LU.         # - when i <= j, we are producing U(i, j)         # - when i >  j, we are producing L(i, j) = residual / U(j, j)         for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)






            if ((__for_idx_4 < u16_dim)) begin
                next_state = S_FOR_BODY_57;
            end else begin
                next_state = S_FOR_END_58;
            end

        end

        S_FOR_BODY_57: begin

            // LIR block: for_body_57

            // line 178: for u16_j in range(u16_dim):         # Search the best pivot row in the current column using the residual         # values that would become U(*, j) before division.         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          # Row swaps must keep A, the already materialized lower triangle in LU,         # and the RHS J consistent with each other.         if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          # Compute column j of packed LU.         # - when i <= j, we are producing U(i, j)         # - when i >  j, we are producing L(i, j) = residual / U(j, j)         for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next_u16_j = __for_idx_4;

            next_u16_pivot = __for_idx_4;


            fetch_A_i = __for_idx_4;

            fetch_A_j = __for_idx_4;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_57_WAIT;

        end

        S_FOR_BODY_57_WAIT: begin

            // LIR block: for_body_57

            // line 178: for u16_j in range(u16_dim):         # Search the best pivot row in the current column using the residual         # values that would become U(*, j) before division.         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          # Row swaps must keep A, the already materialized lower triangle in LU,         # and the RHS J consistent with each other.         if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          # Compute column j of packed LU.         # - when i <= j, we are producing U(i, j)         # - when i >  j, we are producing L(i, j) = residual / U(j, j)         for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_59;
            end else begin
                next_state = S_FOR_BODY_57_WAIT;
            end

        end

        S_FOR_END_58: begin

            // LIR block: for_end_58

            // line 246: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next___for_idx_11 = 16'd0;



            next_state = S_FOR_HEADER_113;

        end

        S_AFTER_CALL_59: begin

            // LIR block: after_call_59

            // line 183: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next___for_idx_5 = 16'd0;



            next_state = S_FOR_HEADER_60;

        end

        S_FOR_HEADER_60: begin

            // LIR block: for_header_60

            // line 184: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_5 < u16_j)) begin
                next_state = S_FOR_BODY_61;
            end else begin
                next_state = S_FOR_END_62;
            end

        end

        S_FOR_BODY_61: begin

            // LIR block: for_body_61

            // line 184: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_5;


            fetch_LU_i = u16_j;

            fetch_LU_j = __for_idx_5;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_61_WAIT;

        end

        S_FOR_BODY_61_WAIT: begin

            // LIR block: for_body_61

            // line 184: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_63;
            end else begin
                next_state = S_FOR_BODY_61_WAIT;
            end

        end

        S_FOR_END_62: begin

            // LIR block: for_end_62

            // line 188: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_f32_4 = abs_comb(neg_comb(f32_1));

            next_u16_i = (u16_j + 16'd1);



            next_state = S_WHILE_HEADER_66;

        end

        S_AFTER_CALL_63: begin

            // LIR block: after_call_63

            // line 186: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_63_WAIT;

        end

        S_AFTER_CALL_63_WAIT: begin

            // LIR block: after_call_63

            // line 186: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_64;
            end else begin
                next_state = S_AFTER_CALL_63_WAIT;
            end

        end

        S_AFTER_CALL_64: begin

            // LIR block: after_call_64

            // line 187: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_64_WAIT;

        end

        S_AFTER_CALL_64_WAIT: begin

            // LIR block: after_call_64

            // line 187: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_65;
            end else begin
                next_state = S_AFTER_CALL_64_WAIT;
            end

        end

        S_AFTER_CALL_65: begin

            // LIR block: after_call_65

            // line 184: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_5 = (__for_idx_5 + 16'd1);



            next_state = S_FOR_HEADER_60;

        end

        S_WHILE_HEADER_66: begin

            // LIR block: while_header_66

            // line 191: while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1






            if ((u16_i < u16_dim)) begin
                next_state = S_WHILE_BODY_67;
            end else begin
                next_state = S_WHILE_END_68;
            end

        end

        S_WHILE_BODY_67: begin

            // LIR block: while_body_67

            // line 192: f32_1 = fetch_A(i=u16_i, j=u16_j)





            fetch_A_i = u16_i;

            fetch_A_j = u16_j;

            fetch_A_start = 1'b1;


            next_state = S_WHILE_BODY_67_WAIT;

        end

        S_WHILE_BODY_67_WAIT: begin

            // LIR block: while_body_67

            // line 192: f32_1 = fetch_A(i=u16_i, j=u16_j)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_69;
            end else begin
                next_state = S_WHILE_BODY_67_WAIT;
            end

        end

        S_WHILE_END_68: begin

            // LIR block: while_end_68

            // line 207: if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)






            if ((u16_pivot != u16_j)) begin
                next_state = S_IF_THEN_78;
            end else begin
                next_state = S_IF_END_79;
            end

        end

        S_AFTER_CALL_69: begin

            // LIR block: after_call_69

            // line 193: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next___for_idx_6 = 16'd0;



            next_state = S_FOR_HEADER_70;

        end

        S_FOR_HEADER_70: begin

            // LIR block: for_header_70

            // line 194: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_6 < u16_j)) begin
                next_state = S_FOR_BODY_71;
            end else begin
                next_state = S_FOR_END_72;
            end

        end

        S_FOR_BODY_71: begin

            // LIR block: for_body_71

            // line 194: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_6;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_6;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_71_WAIT;

        end

        S_FOR_BODY_71_WAIT: begin

            // LIR block: for_body_71

            // line 194: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_73;
            end else begin
                next_state = S_FOR_BODY_71_WAIT;
            end

        end

        S_FOR_END_72: begin

            // LIR block: for_end_72

            // line 198: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_f32_1 = abs_comb(neg_comb(f32_1));



            if (gt_comb(abs_comb(neg_comb(f32_1)), f32_4)) begin
                next_state = S_IF_THEN_76;
            end else begin
                next_state = S_IF_END_77;
            end

        end

        S_AFTER_CALL_73: begin

            // LIR block: after_call_73

            // line 196: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_73_WAIT;

        end

        S_AFTER_CALL_73_WAIT: begin

            // LIR block: after_call_73

            // line 196: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_74;
            end else begin
                next_state = S_AFTER_CALL_73_WAIT;
            end

        end

        S_AFTER_CALL_74: begin

            // LIR block: after_call_74

            // line 197: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_74_WAIT;

        end

        S_AFTER_CALL_74_WAIT: begin

            // LIR block: after_call_74

            // line 197: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_75;
            end else begin
                next_state = S_AFTER_CALL_74_WAIT;
            end

        end

        S_AFTER_CALL_75: begin

            // LIR block: after_call_75

            // line 194: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_6 = (__for_idx_6 + 16'd1);



            next_state = S_FOR_HEADER_70;

        end

        S_IF_THEN_76: begin

            // LIR block: if_then_76

            // line 201: f32_4 = f32_1




            next_f32_4 = f32_1;

            next_u16_pivot = u16_i;



            next_state = S_IF_END_77;

        end

        S_IF_END_77: begin

            // LIR block: if_end_77

            // line 203: u16_i = u16_i + 1




            next_u16_i = (u16_i + 16'd1);



            next_state = S_WHILE_HEADER_66;

        end

        S_IF_THEN_78: begin

            // LIR block: if_then_78

            // line 208: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_7 = 16'd0;



            next_state = S_FOR_HEADER_80;

        end

        S_IF_END_79: begin

            // LIR block: if_end_79

            // line 226: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_9 = 16'd0;



            next_state = S_FOR_HEADER_98;

        end

        S_FOR_HEADER_80: begin

            // LIR block: for_header_80

            // line 208: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)






            if ((__for_idx_7 < u16_dim)) begin
                next_state = S_FOR_BODY_81;
            end else begin
                next_state = S_FOR_END_82;
            end

        end

        S_FOR_BODY_81: begin

            // LIR block: for_body_81

            // line 208: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next_u16_k = __for_idx_7;


            fetch_A_i = u16_j;

            fetch_A_j = __for_idx_7;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_81_WAIT;

        end

        S_FOR_BODY_81_WAIT: begin

            // LIR block: for_body_81

            // line 208: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_83;
            end else begin
                next_state = S_FOR_BODY_81_WAIT;
            end

        end

        S_FOR_END_82: begin

            // LIR block: for_end_82

            // line 213: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_8 = 16'd0;



            next_state = S_FOR_HEADER_87;

        end

        S_AFTER_CALL_83: begin

            // LIR block: after_call_83

            // line 210: f32_2 = fetch_A(i=u16_pivot, j=u16_k)





            fetch_A_i = u16_pivot;

            fetch_A_j = u16_k;

            fetch_A_start = 1'b1;


            next_state = S_AFTER_CALL_83_WAIT;

        end

        S_AFTER_CALL_83_WAIT: begin

            // LIR block: after_call_83

            // line 210: f32_2 = fetch_A(i=u16_pivot, j=u16_k)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_2 = fetch_A_result;

                next_state = S_AFTER_CALL_84;
            end else begin
                next_state = S_AFTER_CALL_83_WAIT;
            end

        end

        S_AFTER_CALL_84: begin

            // LIR block: after_call_84

            // line 211: store_A(i=u16_j, j=u16_k, v=f32_2)





            store_A_i = u16_j;

            store_A_j = u16_k;

            store_A_v = f32_2;

            store_A_start = 1'b1;


            next_state = S_AFTER_CALL_84_WAIT;

        end

        S_AFTER_CALL_84_WAIT: begin

            // LIR block: after_call_84

            // line 211: store_A(i=u16_j, j=u16_k, v=f32_2)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_85;
            end else begin
                next_state = S_AFTER_CALL_84_WAIT;
            end

        end

        S_AFTER_CALL_85: begin

            // LIR block: after_call_85

            // line 212: store_A(i=u16_pivot, j=u16_k, v=f32_1)





            store_A_i = u16_pivot;

            store_A_j = u16_k;

            store_A_v = f32_1;

            store_A_start = 1'b1;


            next_state = S_AFTER_CALL_85_WAIT;

        end

        S_AFTER_CALL_85_WAIT: begin

            // LIR block: after_call_85

            // line 212: store_A(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_86;
            end else begin
                next_state = S_AFTER_CALL_85_WAIT;
            end

        end

        S_AFTER_CALL_86: begin

            // LIR block: after_call_86

            // line 208: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_7 = (__for_idx_7 + 16'd1);



            next_state = S_FOR_HEADER_80;

        end

        S_FOR_HEADER_87: begin

            // LIR block: for_header_87

            // line 213: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)






            if ((__for_idx_8 < u16_j)) begin
                next_state = S_FOR_BODY_88;
            end else begin
                next_state = S_FOR_END_89;
            end

        end

        S_FOR_BODY_88: begin

            // LIR block: for_body_88

            // line 213: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next_u16_k = __for_idx_8;


            fetch_LU_i = u16_j;

            fetch_LU_j = __for_idx_8;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_88_WAIT;

        end

        S_FOR_BODY_88_WAIT: begin

            // LIR block: for_body_88

            // line 213: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_1 = fetch_LU_result;

                next_state = S_AFTER_CALL_90;
            end else begin
                next_state = S_FOR_BODY_88_WAIT;
            end

        end

        S_FOR_END_89: begin

            // LIR block: for_end_89

            // line 218: f32_1 = fetch_J(i=u16_j)





            fetch_J_i = u16_j;

            fetch_J_start = 1'b1;


            next_state = S_FOR_END_89_WAIT;

        end

        S_FOR_END_89_WAIT: begin

            // LIR block: for_end_89

            // line 218: f32_1 = fetch_J(i=u16_j)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_1 = fetch_J_result;

                next_state = S_AFTER_CALL_94;
            end else begin
                next_state = S_FOR_END_89_WAIT;
            end

        end

        S_AFTER_CALL_90: begin

            // LIR block: after_call_90

            // line 215: f32_2 = fetch_LU(i=u16_pivot, j=u16_k)





            fetch_LU_i = u16_pivot;

            fetch_LU_j = u16_k;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_90_WAIT;

        end

        S_AFTER_CALL_90_WAIT: begin

            // LIR block: after_call_90

            // line 215: f32_2 = fetch_LU(i=u16_pivot, j=u16_k)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_91;
            end else begin
                next_state = S_AFTER_CALL_90_WAIT;
            end

        end

        S_AFTER_CALL_91: begin

            // LIR block: after_call_91

            // line 216: store_LU(i=u16_j, j=u16_k, v=f32_2)





            store_LU_i = u16_j;

            store_LU_j = u16_k;

            store_LU_v = f32_2;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_91_WAIT;

        end

        S_AFTER_CALL_91_WAIT: begin

            // LIR block: after_call_91

            // line 216: store_LU(i=u16_j, j=u16_k, v=f32_2)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_92;
            end else begin
                next_state = S_AFTER_CALL_91_WAIT;
            end

        end

        S_AFTER_CALL_92: begin

            // LIR block: after_call_92

            // line 217: store_LU(i=u16_pivot, j=u16_k, v=f32_1)





            store_LU_i = u16_pivot;

            store_LU_j = u16_k;

            store_LU_v = f32_1;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_92_WAIT;

        end

        S_AFTER_CALL_92_WAIT: begin

            // LIR block: after_call_92

            // line 217: store_LU(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_93;
            end else begin
                next_state = S_AFTER_CALL_92_WAIT;
            end

        end

        S_AFTER_CALL_93: begin

            // LIR block: after_call_93

            // line 213: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_8 = (__for_idx_8 + 16'd1);



            next_state = S_FOR_HEADER_87;

        end

        S_AFTER_CALL_94: begin

            // LIR block: after_call_94

            // line 219: f32_2 = fetch_J(i=u16_pivot)





            fetch_J_i = u16_pivot;

            fetch_J_start = 1'b1;


            next_state = S_AFTER_CALL_94_WAIT;

        end

        S_AFTER_CALL_94_WAIT: begin

            // LIR block: after_call_94

            // line 219: f32_2 = fetch_J(i=u16_pivot)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_2 = fetch_J_result;

                next_state = S_AFTER_CALL_95;
            end else begin
                next_state = S_AFTER_CALL_94_WAIT;
            end

        end

        S_AFTER_CALL_95: begin

            // LIR block: after_call_95

            // line 220: store_J(i=u16_j, v=f32_2)





            store_J_i = u16_j;

            store_J_v = f32_2;

            store_J_start = 1'b1;


            next_state = S_AFTER_CALL_95_WAIT;

        end

        S_AFTER_CALL_95_WAIT: begin

            // LIR block: after_call_95

            // line 220: store_J(i=u16_j, v=f32_2)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_96;
            end else begin
                next_state = S_AFTER_CALL_95_WAIT;
            end

        end

        S_AFTER_CALL_96: begin

            // LIR block: after_call_96

            // line 221: store_J(i=u16_pivot, v=f32_1)





            store_J_i = u16_pivot;

            store_J_v = f32_1;

            store_J_start = 1'b1;


            next_state = S_AFTER_CALL_96_WAIT;

        end

        S_AFTER_CALL_96_WAIT: begin

            // LIR block: after_call_96

            // line 221: store_J(i=u16_pivot, v=f32_1)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_97;
            end else begin
                next_state = S_AFTER_CALL_96_WAIT;
            end

        end

        S_AFTER_CALL_97: begin

            // LIR block: after_call_97

            // line 207: if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)






            next_state = S_IF_END_79;

        end

        S_FOR_HEADER_98: begin

            // LIR block: for_header_98

            // line 226: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)






            if ((__for_idx_9 < u16_dim)) begin
                next_state = S_FOR_BODY_99;
            end else begin
                next_state = S_FOR_END_100;
            end

        end

        S_FOR_BODY_99: begin

            // LIR block: for_body_99

            // line 226: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next_u16_i = __for_idx_9;


            fetch_A_i = __for_idx_9;

            fetch_A_j = u16_j;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_99_WAIT;

        end

        S_FOR_BODY_99_WAIT: begin

            // LIR block: for_body_99

            // line 226: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_101;
            end else begin
                next_state = S_FOR_BODY_99_WAIT;
            end

        end

        S_FOR_END_100: begin

            // LIR block: for_end_100

            // line 178: for u16_j in range(u16_dim):         # Search the best pivot row in the current column using the residual         # values that would become U(*, j) before division.         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          # Row swaps must keep A, the already materialized lower triangle in LU,         # and the RHS J consistent with each other.         if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          # Compute column j of packed LU.         # - when i <= j, we are producing U(i, j)         # - when i >  j, we are producing L(i, j) = residual / U(j, j)         for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_4 = (__for_idx_4 + 16'd1);



            next_state = S_FOR_HEADER_56;

        end

        S_AFTER_CALL_101: begin

            // LIR block: after_call_101

            // line 228: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_u16_m = ((u16_i > u16_j) ? u16_j : u16_i);

            next___for_idx_10 = 16'd0;



            next_state = S_FOR_HEADER_102;

        end

        S_FOR_HEADER_102: begin

            // LIR block: for_header_102

            // line 230: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_10 < u16_m)) begin
                next_state = S_FOR_BODY_103;
            end else begin
                next_state = S_FOR_END_104;
            end

        end

        S_FOR_BODY_103: begin

            // LIR block: for_body_103

            // line 230: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_10;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_10;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_103_WAIT;

        end

        S_FOR_BODY_103_WAIT: begin

            // LIR block: for_body_103

            // line 230: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_105;
            end else begin
                next_state = S_FOR_BODY_103_WAIT;
            end

        end

        S_FOR_END_104: begin

            // LIR block: for_end_104

            // line 234: if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)






            if ((u16_i > u16_j)) begin
                next_state = S_IF_THEN_108;
            end else begin
                next_state = S_IF_END_109;
            end

        end

        S_AFTER_CALL_105: begin

            // LIR block: after_call_105

            // line 232: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_105_WAIT;

        end

        S_AFTER_CALL_105_WAIT: begin

            // LIR block: after_call_105

            // line 232: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_106;
            end else begin
                next_state = S_AFTER_CALL_105_WAIT;
            end

        end

        S_AFTER_CALL_106: begin

            // LIR block: after_call_106

            // line 233: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_106_WAIT;

        end

        S_AFTER_CALL_106_WAIT: begin

            // LIR block: after_call_106

            // line 233: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_107;
            end else begin
                next_state = S_AFTER_CALL_106_WAIT;
            end

        end

        S_AFTER_CALL_107: begin

            // LIR block: after_call_107

            // line 230: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_10 = (__for_idx_10 + 16'd1);



            next_state = S_FOR_HEADER_102;

        end

        S_IF_THEN_108: begin

            // LIR block: if_then_108

            // line 235: f32_2 = fetch_LU(i=u16_j, j=u16_j)





            fetch_LU_i = u16_j;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_IF_THEN_108_WAIT;

        end

        S_IF_THEN_108_WAIT: begin

            // LIR block: if_then_108

            // line 235: f32_2 = fetch_LU(i=u16_j, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_110;
            end else begin
                next_state = S_IF_THEN_108_WAIT;
            end

        end

        S_IF_END_109: begin

            // LIR block: if_end_109

            // line 237: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);


            store_LU_i = u16_i;

            store_LU_j = u16_j;

            store_LU_v = neg_comb(f32_1);

            store_LU_start = 1'b1;


            next_state = S_IF_END_109_WAIT;

        end

        S_IF_END_109_WAIT: begin

            // LIR block: if_end_109

            // line 237: f32_1 = neg_comb(v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_112;
            end else begin
                next_state = S_IF_END_109_WAIT;
            end

        end

        S_AFTER_CALL_110: begin

            // LIR block: after_call_110

            // line 236: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_110_WAIT;

        end

        S_AFTER_CALL_110_WAIT: begin

            // LIR block: after_call_110

            // line 236: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_111;
            end else begin
                next_state = S_AFTER_CALL_110_WAIT;
            end

        end

        S_AFTER_CALL_111: begin

            // LIR block: after_call_111

            // line 234: if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)






            next_state = S_IF_END_109;

        end

        S_AFTER_CALL_112: begin

            // LIR block: after_call_112

            // line 226: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_9 = (__for_idx_9 + 16'd1);



            next_state = S_FOR_HEADER_98;

        end

        S_FOR_HEADER_113: begin

            // LIR block: for_header_113

            // line 246: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)






            if ((__for_idx_11 < u16_dim)) begin
                next_state = S_FOR_BODY_114;
            end else begin
                next_state = S_FOR_END_115;
            end

        end

        S_FOR_BODY_114: begin

            // LIR block: for_body_114

            // line 246: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next_u16_i = __for_idx_11;


            fetch_J_i = __for_idx_11;

            fetch_J_start = 1'b1;


            next_state = S_FOR_BODY_114_WAIT;

        end

        S_FOR_BODY_114_WAIT: begin

            // LIR block: for_body_114

            // line 246: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_1 = fetch_J_result;

                next_state = S_AFTER_CALL_116;
            end else begin
                next_state = S_FOR_BODY_114_WAIT;
            end

        end

        S_FOR_END_115: begin

            // LIR block: for_end_115

            // line 260: u16_i = u16_dim




            next_u16_i = u16_dim;



            next_state = S_WHILE_HEADER_124;

        end

        S_AFTER_CALL_116: begin

            // LIR block: after_call_116

            // line 248: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_12 = 16'd0;



            next_state = S_FOR_HEADER_117;

        end

        S_FOR_HEADER_117: begin

            // LIR block: for_header_117

            // line 248: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_12 < u16_i)) begin
                next_state = S_FOR_BODY_118;
            end else begin
                next_state = S_FOR_END_119;
            end

        end

        S_FOR_BODY_118: begin

            // LIR block: for_body_118

            // line 248: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_12;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_12;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_118_WAIT;

        end

        S_FOR_BODY_118_WAIT: begin

            // LIR block: for_body_118

            // line 248: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_120;
            end else begin
                next_state = S_FOR_BODY_118_WAIT;
            end

        end

        S_FOR_END_119: begin

            // LIR block: for_end_119

            // line 253: store_Y(i=u16_i, v=f32_1)





            store_Y_i = u16_i;

            store_Y_v = f32_1;

            store_Y_start = 1'b1;


            next_state = S_FOR_END_119_WAIT;

        end

        S_FOR_END_119_WAIT: begin

            // LIR block: for_end_119

            // line 253: store_Y(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_Y






            if (store_Y_done) begin

                next_state = S_AFTER_CALL_123;
            end else begin
                next_state = S_FOR_END_119_WAIT;
            end

        end

        S_AFTER_CALL_120: begin

            // LIR block: after_call_120

            // line 250: f32_3 = fetch_Y(i=u16_k)





            fetch_Y_i = u16_k;

            fetch_Y_start = 1'b1;


            next_state = S_AFTER_CALL_120_WAIT;

        end

        S_AFTER_CALL_120_WAIT: begin

            // LIR block: after_call_120

            // line 250: f32_3 = fetch_Y(i=u16_k)

            // wait for blocking primitive: fetch_Y






            if (fetch_Y_done) begin

                next_f32_3 = fetch_Y_result;

                next_state = S_AFTER_CALL_121;
            end else begin
                next_state = S_AFTER_CALL_120_WAIT;
            end

        end

        S_AFTER_CALL_121: begin

            // LIR block: after_call_121

            // line 251: f32_3 = neg_comb(v=f32_3)




            next_f32_3 = neg_comb(f32_3);


            fma_a = f32_2;

            fma_b = neg_comb(f32_3);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_121_WAIT;

        end

        S_AFTER_CALL_121_WAIT: begin

            // LIR block: after_call_121

            // line 251: f32_3 = neg_comb(v=f32_3)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_122;
            end else begin
                next_state = S_AFTER_CALL_121_WAIT;
            end

        end

        S_AFTER_CALL_122: begin

            // LIR block: after_call_122

            // line 248: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_12 = (__for_idx_12 + 16'd1);



            next_state = S_FOR_HEADER_117;

        end

        S_AFTER_CALL_123: begin

            // LIR block: after_call_123

            // line 246: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next___for_idx_11 = (__for_idx_11 + 16'd1);



            next_state = S_FOR_HEADER_113;

        end

        S_WHILE_HEADER_124: begin

            // LIR block: while_header_124

            // line 261: while u16_i > 0:         u16_i = u16_i - 1         f32_1 = fetch_Y(i=u16_i)         u16_k = u16_i + 1         while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1         f32_2 = fetch_LU(i=u16_i, j=u16_i)         f32_1 = div(a=f32_1, b=f32_2)         store_X(i=u16_i, v=f32_1)






            if ((u16_i > 32'd0)) begin
                next_state = S_WHILE_BODY_125;
            end else begin
                next_state = S_WHILE_END_126;
            end

        end

        S_WHILE_BODY_125: begin

            // LIR block: while_body_125

            // line 262: u16_i = u16_i - 1




            next_u16_i = (u16_i - 16'd1);


            fetch_Y_i = (u16_i - 16'd1);

            fetch_Y_start = 1'b1;


            next_state = S_WHILE_BODY_125_WAIT;

        end

        S_WHILE_BODY_125_WAIT: begin

            // LIR block: while_body_125

            // line 262: u16_i = u16_i - 1

            // wait for blocking primitive: fetch_Y






            if (fetch_Y_done) begin

                next_f32_1 = fetch_Y_result;

                next_state = S_AFTER_CALL_127;
            end else begin
                next_state = S_WHILE_BODY_125_WAIT;
            end

        end

        S_WHILE_END_126: begin

            // LIR block: while_end_126







            next_state = S_DONE;

        end

        S_AFTER_CALL_127: begin

            // LIR block: after_call_127

            // line 264: u16_k = u16_i + 1




            next_u16_k = (u16_i + 16'd1);



            next_state = S_WHILE_HEADER_128;

        end

        S_WHILE_HEADER_128: begin

            // LIR block: while_header_128

            // line 265: while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1






            if ((u16_k < u16_dim)) begin
                next_state = S_WHILE_BODY_129;
            end else begin
                next_state = S_WHILE_END_130;
            end

        end

        S_WHILE_BODY_129: begin

            // LIR block: while_body_129

            // line 266: f32_2 = fetch_LU(i=u16_i, j=u16_k)





            fetch_LU_i = u16_i;

            fetch_LU_j = u16_k;

            fetch_LU_start = 1'b1;


            next_state = S_WHILE_BODY_129_WAIT;

        end

        S_WHILE_BODY_129_WAIT: begin

            // LIR block: while_body_129

            // line 266: f32_2 = fetch_LU(i=u16_i, j=u16_k)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_131;
            end else begin
                next_state = S_WHILE_BODY_129_WAIT;
            end

        end

        S_WHILE_END_130: begin

            // LIR block: while_end_130

            // line 271: f32_2 = fetch_LU(i=u16_i, j=u16_i)





            fetch_LU_i = u16_i;

            fetch_LU_j = u16_i;

            fetch_LU_start = 1'b1;


            next_state = S_WHILE_END_130_WAIT;

        end

        S_WHILE_END_130_WAIT: begin

            // LIR block: while_end_130

            // line 271: f32_2 = fetch_LU(i=u16_i, j=u16_i)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_134;
            end else begin
                next_state = S_WHILE_END_130_WAIT;
            end

        end

        S_AFTER_CALL_131: begin

            // LIR block: after_call_131

            // line 267: f32_3 = fetch_X(i=u16_k)





            fetch_X_i = u16_k;

            fetch_X_start = 1'b1;


            next_state = S_AFTER_CALL_131_WAIT;

        end

        S_AFTER_CALL_131_WAIT: begin

            // LIR block: after_call_131

            // line 267: f32_3 = fetch_X(i=u16_k)

            // wait for blocking primitive: fetch_X






            if (fetch_X_done) begin

                next_f32_3 = fetch_X_result;

                next_state = S_AFTER_CALL_132;
            end else begin
                next_state = S_AFTER_CALL_131_WAIT;
            end

        end

        S_AFTER_CALL_132: begin

            // LIR block: after_call_132

            // line 268: f32_3 = neg_comb(v=f32_3)




            next_f32_3 = neg_comb(f32_3);


            fma_a = f32_2;

            fma_b = neg_comb(f32_3);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_132_WAIT;

        end

        S_AFTER_CALL_132_WAIT: begin

            // LIR block: after_call_132

            // line 268: f32_3 = neg_comb(v=f32_3)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_133;
            end else begin
                next_state = S_AFTER_CALL_132_WAIT;
            end

        end

        S_AFTER_CALL_133: begin

            // LIR block: after_call_133

            // line 270: u16_k = u16_k + 1




            next_u16_k = (u16_k + 16'd1);



            next_state = S_WHILE_HEADER_128;

        end

        S_AFTER_CALL_134: begin

            // LIR block: after_call_134

            // line 272: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_134_WAIT;

        end

        S_AFTER_CALL_134_WAIT: begin

            // LIR block: after_call_134

            // line 272: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_135;
            end else begin
                next_state = S_AFTER_CALL_134_WAIT;
            end

        end

        S_AFTER_CALL_135: begin

            // LIR block: after_call_135

            // line 273: store_X(i=u16_i, v=f32_1)





            store_X_i = u16_i;

            store_X_v = f32_1;

            store_X_start = 1'b1;


            next_state = S_AFTER_CALL_135_WAIT;

        end

        S_AFTER_CALL_135_WAIT: begin

            // LIR block: after_call_135

            // line 273: store_X(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_X






            if (store_X_done) begin

                next_state = S_AFTER_CALL_136;
            end else begin
                next_state = S_AFTER_CALL_135_WAIT;
            end

        end

        S_AFTER_CALL_136: begin

            // LIR block: after_call_136

            // line 261: while u16_i > 0:         u16_i = u16_i - 1         f32_1 = fetch_Y(i=u16_i)         u16_k = u16_i + 1         while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1         f32_2 = fetch_LU(i=u16_i, j=u16_i)         f32_1 = div(a=f32_1, b=f32_2)         store_X(i=u16_i, v=f32_1)






            next_state = S_WHILE_HEADER_124;

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
