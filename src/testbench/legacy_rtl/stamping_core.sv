
// Generated from LIR for function stamping_core

// Entry block: entry

// Blocking primitives: fetchElemKind(latency=1), fetchElemN0(latency=1), fetchElemN1(latency=1), fetchElemN2(latency=1), fetchElemN3(latency=1), fetchElemAux(latency=1), fetchElemVal0(latency=1), fetchElemVal1(latency=1), fetchElemVal2(latency=1), accumA(latency=1), accumJ(latency=1)

import StampingLegacyCombPkg::*;

module stamping_core (

    input logic clk,

    input logic rst_n,

    input logic start,

    output logic busy,

    output logic done,

    input logic [31:0] par_elem_n,

    output logic fetchElemKind_start,

    output logic [15:0] fetchElemKind_idx,

    input logic fetchElemKind_done,

    input logic [7:0] fetchElemKind_result,

    output logic fetchElemN0_start,

    output logic [15:0] fetchElemN0_idx,

    input logic fetchElemN0_done,

    input logic [7:0] fetchElemN0_result,

    output logic fetchElemN1_start,

    output logic [15:0] fetchElemN1_idx,

    input logic fetchElemN1_done,

    input logic [7:0] fetchElemN1_result,

    output logic fetchElemN2_start,

    output logic [15:0] fetchElemN2_idx,

    input logic fetchElemN2_done,

    input logic [7:0] fetchElemN2_result,

    output logic fetchElemN3_start,

    output logic [15:0] fetchElemN3_idx,

    input logic fetchElemN3_done,

    input logic [7:0] fetchElemN3_result,

    output logic fetchElemAux_start,

    output logic [15:0] fetchElemAux_idx,

    input logic fetchElemAux_done,

    input logic [7:0] fetchElemAux_result,

    output logic fetchElemVal0_start,

    output logic [15:0] fetchElemVal0_idx,

    input logic fetchElemVal0_done,

    input logic [31:0] fetchElemVal0_result,

    output logic fetchElemVal1_start,

    output logic [15:0] fetchElemVal1_idx,

    input logic fetchElemVal1_done,

    input logic [31:0] fetchElemVal1_result,

    output logic fetchElemVal2_start,

    output logic [15:0] fetchElemVal2_idx,

    input logic fetchElemVal2_done,

    input logic [31:0] fetchElemVal2_result,

    output logic accumA_start,

    output logic [7:0] accumA_i,

    output logic [7:0] accumA_j,

    output logic [31:0] accumA_delta,

    input logic accumA_done,

    output logic accumJ_start,

    output logic [7:0] accumJ_i,

    output logic [31:0] accumJ_delta,

    input logic accumJ_done

);



import StampingLegacyCombPkg::*;

typedef enum logic [6:0] {

    S_IDLE,

    S_ENTRY,

    S_FOR_HEADER_0,

    S_FOR_BODY_1,

    S_FOR_BODY_1_WAIT,

    S_FOR_END_2,

    S_AFTER_CALL_3,

    S_AFTER_CALL_3_WAIT,

    S_AFTER_CALL_4,

    S_AFTER_CALL_4_WAIT,

    S_AFTER_CALL_5,

    S_AFTER_CALL_5_WAIT,

    S_AFTER_CALL_6,

    S_AFTER_CALL_6_WAIT,

    S_AFTER_CALL_7,

    S_AFTER_CALL_7_WAIT,

    S_AFTER_CALL_8,

    S_AFTER_CALL_8_WAIT,

    S_AFTER_CALL_9,

    S_AFTER_CALL_9_WAIT,

    S_AFTER_CALL_10,

    S_AFTER_CALL_10_WAIT,

    S_AFTER_CALL_11,

    S_IF_THEN_12,

    S_IF_END_13,

    S_IF_THEN_14,

    S_IF_THEN_14_WAIT,

    S_IF_END_15,

    S_AFTER_CALL_16,

    S_IF_THEN_17,

    S_IF_THEN_17_WAIT,

    S_IF_END_18,

    S_AFTER_CALL_19,

    S_AFTER_CALL_19_WAIT,

    S_AFTER_CALL_20,

    S_IF_THEN_21,

    S_IF_THEN_21_WAIT,

    S_IF_END_22,

    S_AFTER_CALL_23,

    S_IF_THEN_24,

    S_IF_END_25,

    S_IF_THEN_26,

    S_IF_THEN_26_WAIT,

    S_IF_END_27,

    S_AFTER_CALL_28,

    S_IF_THEN_29,

    S_IF_THEN_29_WAIT,

    S_IF_END_30,

    S_AFTER_CALL_31,

    S_IF_THEN_32,

    S_IF_END_33,

    S_IF_THEN_34,

    S_IF_END_35,

    S_IF_THEN_36,

    S_IF_THEN_36_WAIT,

    S_IF_END_37,

    S_AFTER_CALL_38,

    S_AFTER_CALL_38_WAIT,

    S_AFTER_CALL_39,

    S_IF_THEN_40,

    S_IF_THEN_40_WAIT,

    S_IF_END_41,

    S_IF_END_41_WAIT,

    S_AFTER_CALL_42,

    S_AFTER_CALL_42_WAIT,

    S_AFTER_CALL_43,

    S_AFTER_CALL_44,

    S_IF_THEN_45,

    S_IF_END_46,

    S_IF_THEN_47,

    S_IF_END_48,

    S_IF_THEN_49,

    S_IF_THEN_49_WAIT,

    S_IF_END_50,

    S_AFTER_CALL_51,

    S_AFTER_CALL_51_WAIT,

    S_AFTER_CALL_52,

    S_IF_THEN_53,

    S_IF_THEN_53_WAIT,

    S_IF_END_54,

    S_AFTER_CALL_55,

    S_AFTER_CALL_55_WAIT,

    S_AFTER_CALL_56,

    S_IF_THEN_57,

    S_IF_THEN_57_WAIT,

    S_IF_END_58,

    S_AFTER_CALL_59,

    S_IF_THEN_60,

    S_IF_THEN_60_WAIT,

    S_IF_END_61,

    S_AFTER_CALL_62,

    S_IF_THEN_63,

    S_IF_END_64,

    S_IF_THEN_65,

    S_IF_END_66,

    S_IF_THEN_67,

    S_IF_THEN_67_WAIT,

    S_IF_END_68,

    S_AFTER_CALL_69,

    S_AFTER_CALL_69_WAIT,

    S_AFTER_CALL_70,

    S_IF_THEN_71,

    S_IF_THEN_71_WAIT,

    S_IF_END_72,

    S_AFTER_CALL_73,

    S_AFTER_CALL_73_WAIT,

    S_AFTER_CALL_74,

    S_AFTER_CALL_74_WAIT,

    S_AFTER_CALL_75,

    S_IF_THEN_76,

    S_IF_THEN_76_WAIT,

    S_IF_END_77,

    S_IF_END_77_WAIT,

    S_AFTER_CALL_78,

    S_AFTER_CALL_79,

    S_DONE

} state_t;

state_t state;
state_t next_state;


logic [15:0] u16_e;

logic [7:0] u8_kind;

logic [7:0] u8_n0;

logic [7:0] u8_n1;

logic [7:0] u8_n2;

logic [7:0] u8_n3;

logic [7:0] u8_aux;

logic [31:0] f32_v0;

logic [31:0] f32_v1;

logic [31:0] f32_v2;

logic [31:0] f32_neg;


logic [15:0] __for_idx_0;



logic [15:0] next_u16_e;

logic [7:0] next_u8_kind;

logic [7:0] next_u8_n0;

logic [7:0] next_u8_n1;

logic [7:0] next_u8_n2;

logic [7:0] next_u8_n3;

logic [7:0] next_u8_aux;

logic [31:0] next_f32_v0;

logic [31:0] next_f32_v1;

logic [31:0] next_f32_v2;

logic [31:0] next_f32_neg;

logic [15:0] next___for_idx_0;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        u16_e <=0;

        u8_kind <=0;

        u8_n0 <=0;

        u8_n1 <=0;

        u8_n2 <=0;

        u8_n3 <=0;

        u8_aux <=0;

        f32_v0 <=0;

        f32_v1 <=0;

        f32_v2 <=0;

        f32_neg <=0;


        __for_idx_0 <=0;


    end else begin
        state <= next_state;

        u16_e <= next_u16_e;

        u8_kind <= next_u8_kind;

        u8_n0 <= next_u8_n0;

        u8_n1 <= next_u8_n1;

        u8_n2 <= next_u8_n2;

        u8_n3 <= next_u8_n3;

        u8_aux <= next_u8_aux;

        f32_v0 <= next_f32_v0;

        f32_v1 <= next_f32_v1;

        f32_v2 <= next_f32_v2;

        f32_neg <= next_f32_neg;


        __for_idx_0 <= next___for_idx_0;


    end
end

always_comb begin
    next_state = state;
    busy = 1'b1;
    done = 1'b0;

    next_u16_e = u16_e;

    next_u8_kind = u8_kind;

    next_u8_n0 = u8_n0;

    next_u8_n1 = u8_n1;

    next_u8_n2 = u8_n2;

    next_u8_n3 = u8_n3;

    next_u8_aux = u8_aux;

    next_f32_v0 = f32_v0;

    next_f32_v1 = f32_v1;

    next_f32_v2 = f32_v2;

    next_f32_neg = f32_neg;


    next___for_idx_0 = __for_idx_0;



    fetchElemKind_start =0;

    fetchElemKind_idx =0;

    fetchElemN0_start =0;

    fetchElemN0_idx =0;

    fetchElemN1_start =0;

    fetchElemN1_idx =0;

    fetchElemN2_start =0;

    fetchElemN2_idx =0;

    fetchElemN3_start =0;

    fetchElemN3_idx =0;

    fetchElemAux_start =0;

    fetchElemAux_idx =0;

    fetchElemVal0_start =0;

    fetchElemVal0_idx =0;

    fetchElemVal1_start =0;

    fetchElemVal1_idx =0;

    fetchElemVal2_start =0;

    fetchElemVal2_idx =0;

    accumA_start =0;

    accumA_i =0;

    accumA_j =0;

    accumA_delta =0;

    accumJ_start =0;

    accumJ_i =0;

    accumJ_delta =0;


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

            // line 2: u16_e = 0




            next_u16_e = 16'd0;

            next_u8_kind = 8'd0;

            next_u8_n0 = 8'd0;

            next_u8_n1 = 8'd0;

            next_u8_n2 = 8'd0;

            next_u8_n3 = 8'd0;

            next_u8_aux = 8'd0;

            next_f32_v0 = 32'h00000000;

            next_f32_v1 = 32'h00000000;

            next_f32_v2 = 32'h00000000;

            next_f32_neg = 32'h00000000;

            next___for_idx_0 = 16'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 13: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         u8_n2 = fetchElemN2(idx=u16_e)         u8_n3 = fetchElemN3(idx=u16_e)         u8_aux = fetchElemAux(idx=u16_e)         f32_v0 = fetchElemVal0(idx=u16_e)         f32_v1 = fetchElemVal1(idx=u16_e)         f32_v2 = fetchElemVal2(idx=u16_e)          if u8_kind == 1:             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)          if u8_kind == 2:             if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)          if u8_kind == 3:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)          if u8_kind == 4:             if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)          if u8_kind == 5:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)






            if ((__for_idx_0 < par_elem_n)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 13: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         u8_n2 = fetchElemN2(idx=u16_e)         u8_n3 = fetchElemN3(idx=u16_e)         u8_aux = fetchElemAux(idx=u16_e)         f32_v0 = fetchElemVal0(idx=u16_e)         f32_v1 = fetchElemVal1(idx=u16_e)         f32_v2 = fetchElemVal2(idx=u16_e)          if u8_kind == 1:             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)          if u8_kind == 2:             if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)          if u8_kind == 3:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)          if u8_kind == 4:             if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)          if u8_kind == 5:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)




            next_u16_e = __for_idx_0;


            fetchElemKind_idx = __for_idx_0;

            fetchElemKind_start = 1'b1;


            next_state = S_FOR_BODY_1_WAIT;

        end

        S_FOR_BODY_1_WAIT: begin

            // LIR block: for_body_1

            // line 13: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         u8_n2 = fetchElemN2(idx=u16_e)         u8_n3 = fetchElemN3(idx=u16_e)         u8_aux = fetchElemAux(idx=u16_e)         f32_v0 = fetchElemVal0(idx=u16_e)         f32_v1 = fetchElemVal1(idx=u16_e)         f32_v2 = fetchElemVal2(idx=u16_e)          if u8_kind == 1:             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)          if u8_kind == 2:             if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)          if u8_kind == 3:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)          if u8_kind == 4:             if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)          if u8_kind == 5:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)

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







            next_state = S_DONE;

        end

        S_AFTER_CALL_3: begin

            // LIR block: after_call_3

            // line 15: u8_n0 = fetchElemN0(idx=u16_e)





            fetchElemN0_idx = u16_e;

            fetchElemN0_start = 1'b1;


            next_state = S_AFTER_CALL_3_WAIT;

        end

        S_AFTER_CALL_3_WAIT: begin

            // LIR block: after_call_3

            // line 15: u8_n0 = fetchElemN0(idx=u16_e)

            // wait for blocking primitive: fetchElemN0






            if (fetchElemN0_done) begin

                next_u8_n0 = fetchElemN0_result;

                next_state = S_AFTER_CALL_4;
            end else begin
                next_state = S_AFTER_CALL_3_WAIT;
            end

        end

        S_AFTER_CALL_4: begin

            // LIR block: after_call_4

            // line 16: u8_n1 = fetchElemN1(idx=u16_e)





            fetchElemN1_idx = u16_e;

            fetchElemN1_start = 1'b1;


            next_state = S_AFTER_CALL_4_WAIT;

        end

        S_AFTER_CALL_4_WAIT: begin

            // LIR block: after_call_4

            // line 16: u8_n1 = fetchElemN1(idx=u16_e)

            // wait for blocking primitive: fetchElemN1






            if (fetchElemN1_done) begin

                next_u8_n1 = fetchElemN1_result;

                next_state = S_AFTER_CALL_5;
            end else begin
                next_state = S_AFTER_CALL_4_WAIT;
            end

        end

        S_AFTER_CALL_5: begin

            // LIR block: after_call_5

            // line 17: u8_n2 = fetchElemN2(idx=u16_e)





            fetchElemN2_idx = u16_e;

            fetchElemN2_start = 1'b1;


            next_state = S_AFTER_CALL_5_WAIT;

        end

        S_AFTER_CALL_5_WAIT: begin

            // LIR block: after_call_5

            // line 17: u8_n2 = fetchElemN2(idx=u16_e)

            // wait for blocking primitive: fetchElemN2






            if (fetchElemN2_done) begin

                next_u8_n2 = fetchElemN2_result;

                next_state = S_AFTER_CALL_6;
            end else begin
                next_state = S_AFTER_CALL_5_WAIT;
            end

        end

        S_AFTER_CALL_6: begin

            // LIR block: after_call_6

            // line 18: u8_n3 = fetchElemN3(idx=u16_e)





            fetchElemN3_idx = u16_e;

            fetchElemN3_start = 1'b1;


            next_state = S_AFTER_CALL_6_WAIT;

        end

        S_AFTER_CALL_6_WAIT: begin

            // LIR block: after_call_6

            // line 18: u8_n3 = fetchElemN3(idx=u16_e)

            // wait for blocking primitive: fetchElemN3






            if (fetchElemN3_done) begin

                next_u8_n3 = fetchElemN3_result;

                next_state = S_AFTER_CALL_7;
            end else begin
                next_state = S_AFTER_CALL_6_WAIT;
            end

        end

        S_AFTER_CALL_7: begin

            // LIR block: after_call_7

            // line 19: u8_aux = fetchElemAux(idx=u16_e)





            fetchElemAux_idx = u16_e;

            fetchElemAux_start = 1'b1;


            next_state = S_AFTER_CALL_7_WAIT;

        end

        S_AFTER_CALL_7_WAIT: begin

            // LIR block: after_call_7

            // line 19: u8_aux = fetchElemAux(idx=u16_e)

            // wait for blocking primitive: fetchElemAux






            if (fetchElemAux_done) begin

                next_u8_aux = fetchElemAux_result;

                next_state = S_AFTER_CALL_8;
            end else begin
                next_state = S_AFTER_CALL_7_WAIT;
            end

        end

        S_AFTER_CALL_8: begin

            // LIR block: after_call_8

            // line 20: f32_v0 = fetchElemVal0(idx=u16_e)





            fetchElemVal0_idx = u16_e;

            fetchElemVal0_start = 1'b1;


            next_state = S_AFTER_CALL_8_WAIT;

        end

        S_AFTER_CALL_8_WAIT: begin

            // LIR block: after_call_8

            // line 20: f32_v0 = fetchElemVal0(idx=u16_e)

            // wait for blocking primitive: fetchElemVal0






            if (fetchElemVal0_done) begin

                next_f32_v0 = fetchElemVal0_result;

                next_state = S_AFTER_CALL_9;
            end else begin
                next_state = S_AFTER_CALL_8_WAIT;
            end

        end

        S_AFTER_CALL_9: begin

            // LIR block: after_call_9

            // line 21: f32_v1 = fetchElemVal1(idx=u16_e)





            fetchElemVal1_idx = u16_e;

            fetchElemVal1_start = 1'b1;


            next_state = S_AFTER_CALL_9_WAIT;

        end

        S_AFTER_CALL_9_WAIT: begin

            // LIR block: after_call_9

            // line 21: f32_v1 = fetchElemVal1(idx=u16_e)

            // wait for blocking primitive: fetchElemVal1






            if (fetchElemVal1_done) begin

                next_f32_v1 = fetchElemVal1_result;

                next_state = S_AFTER_CALL_10;
            end else begin
                next_state = S_AFTER_CALL_9_WAIT;
            end

        end

        S_AFTER_CALL_10: begin

            // LIR block: after_call_10

            // line 22: f32_v2 = fetchElemVal2(idx=u16_e)





            fetchElemVal2_idx = u16_e;

            fetchElemVal2_start = 1'b1;


            next_state = S_AFTER_CALL_10_WAIT;

        end

        S_AFTER_CALL_10_WAIT: begin

            // LIR block: after_call_10

            // line 22: f32_v2 = fetchElemVal2(idx=u16_e)

            // wait for blocking primitive: fetchElemVal2






            if (fetchElemVal2_done) begin

                next_f32_v2 = fetchElemVal2_result;

                next_state = S_AFTER_CALL_11;
            end else begin
                next_state = S_AFTER_CALL_10_WAIT;
            end

        end

        S_AFTER_CALL_11: begin

            // LIR block: after_call_11

            // line 24: if u8_kind == 1:             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)






            if ((u8_kind == 32'd1)) begin
                next_state = S_IF_THEN_12;
            end else begin
                next_state = S_IF_END_13;
            end

        end

        S_IF_THEN_12: begin

            // LIR block: if_then_12

            // line 25: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_14;
            end else begin
                next_state = S_IF_END_15;
            end

        end

        S_IF_END_13: begin

            // LIR block: if_end_13

            // line 34: if u8_kind == 2:             if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)






            if ((u8_kind == 32'd2)) begin
                next_state = S_IF_THEN_24;
            end else begin
                next_state = S_IF_END_25;
            end

        end

        S_IF_THEN_14: begin

            // LIR block: if_then_14

            // line 26: accumA(i=u8_n0, j=u8_n0, delta=f32_v0)





            accumA_i = u8_n0;

            accumA_j = u8_n0;

            accumA_delta = f32_v0;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_14_WAIT;

        end

        S_IF_THEN_14_WAIT: begin

            // LIR block: if_then_14

            // line 26: accumA(i=u8_n0, j=u8_n0, delta=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_16;
            end else begin
                next_state = S_IF_THEN_14_WAIT;
            end

        end

        S_IF_END_15: begin

            // LIR block: if_end_15

            // line 31: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_21;
            end else begin
                next_state = S_IF_END_22;
            end

        end

        S_AFTER_CALL_16: begin

            // LIR block: after_call_16

            // line 27: if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_17;
            end else begin
                next_state = S_IF_END_18;
            end

        end

        S_IF_THEN_17: begin

            // LIR block: if_then_17

            // line 28: f32_neg = neg_comb(v=f32_v0)




            next_f32_neg = neg_comb(f32_v0);


            accumA_i = u8_n0;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_v0);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_17_WAIT;

        end

        S_IF_THEN_17_WAIT: begin

            // LIR block: if_then_17

            // line 28: f32_neg = neg_comb(v=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_19;
            end else begin
                next_state = S_IF_THEN_17_WAIT;
            end

        end

        S_IF_END_18: begin

            // LIR block: if_end_18

            // line 25: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)






            next_state = S_IF_END_15;

        end

        S_AFTER_CALL_19: begin

            // LIR block: after_call_19

            // line 30: accumA(i=u8_n1, j=u8_n0, delta=f32_neg)





            accumA_i = u8_n1;

            accumA_j = u8_n0;

            accumA_delta = f32_neg;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_19_WAIT;

        end

        S_AFTER_CALL_19_WAIT: begin

            // LIR block: after_call_19

            // line 30: accumA(i=u8_n1, j=u8_n0, delta=f32_neg)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_20;
            end else begin
                next_state = S_AFTER_CALL_19_WAIT;
            end

        end

        S_AFTER_CALL_20: begin

            // LIR block: after_call_20

            // line 27: if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)






            next_state = S_IF_END_18;

        end

        S_IF_THEN_21: begin

            // LIR block: if_then_21

            // line 32: accumA(i=u8_n1, j=u8_n1, delta=f32_v0)





            accumA_i = u8_n1;

            accumA_j = u8_n1;

            accumA_delta = f32_v0;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_21_WAIT;

        end

        S_IF_THEN_21_WAIT: begin

            // LIR block: if_then_21

            // line 32: accumA(i=u8_n1, j=u8_n1, delta=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_23;
            end else begin
                next_state = S_IF_THEN_21_WAIT;
            end

        end

        S_IF_END_22: begin

            // LIR block: if_end_22

            // line 24: if u8_kind == 1:             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)






            next_state = S_IF_END_13;

        end

        S_AFTER_CALL_23: begin

            // LIR block: after_call_23

            // line 31: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)






            next_state = S_IF_END_22;

        end

        S_IF_THEN_24: begin

            // LIR block: if_then_24

            // line 35: if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_26;
            end else begin
                next_state = S_IF_END_27;
            end

        end

        S_IF_END_25: begin

            // LIR block: if_end_25

            // line 41: if u8_kind == 3:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)






            if ((u8_kind == 32'd3)) begin
                next_state = S_IF_THEN_32;
            end else begin
                next_state = S_IF_END_33;
            end

        end

        S_IF_THEN_26: begin

            // LIR block: if_then_26

            // line 36: f32_neg = neg_comb(v=f32_v0)




            next_f32_neg = neg_comb(f32_v0);


            accumJ_i = u8_n0;

            accumJ_delta = neg_comb(f32_v0);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_26_WAIT;

        end

        S_IF_THEN_26_WAIT: begin

            // LIR block: if_then_26

            // line 36: f32_neg = neg_comb(v=f32_v0)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_28;
            end else begin
                next_state = S_IF_THEN_26_WAIT;
            end

        end

        S_IF_END_27: begin

            // LIR block: if_end_27

            // line 38: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_29;
            end else begin
                next_state = S_IF_END_30;
            end

        end

        S_AFTER_CALL_28: begin

            // LIR block: after_call_28

            // line 35: if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)






            next_state = S_IF_END_27;

        end

        S_IF_THEN_29: begin

            // LIR block: if_then_29

            // line 39: accumJ(i=u8_n1, delta=f32_v0)





            accumJ_i = u8_n1;

            accumJ_delta = f32_v0;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_29_WAIT;

        end

        S_IF_THEN_29_WAIT: begin

            // LIR block: if_then_29

            // line 39: accumJ(i=u8_n1, delta=f32_v0)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_31;
            end else begin
                next_state = S_IF_THEN_29_WAIT;
            end

        end

        S_IF_END_30: begin

            // LIR block: if_end_30

            // line 34: if u8_kind == 2:             if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)






            next_state = S_IF_END_25;

        end

        S_AFTER_CALL_31: begin

            // LIR block: after_call_31

            // line 38: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)






            next_state = S_IF_END_30;

        end

        S_IF_THEN_32: begin

            // LIR block: if_then_32

            // line 42: if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)






            if ((u8_aux != 32'd255)) begin
                next_state = S_IF_THEN_34;
            end else begin
                next_state = S_IF_END_35;
            end

        end

        S_IF_END_33: begin

            // LIR block: if_end_33

            // line 53: if u8_kind == 4:             if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)






            if ((u8_kind == 32'd4)) begin
                next_state = S_IF_THEN_45;
            end else begin
                next_state = S_IF_END_46;
            end

        end

        S_IF_THEN_34: begin

            // LIR block: if_then_34

            // line 43: if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_36;
            end else begin
                next_state = S_IF_END_37;
            end

        end

        S_IF_END_35: begin

            // LIR block: if_end_35

            // line 41: if u8_kind == 3:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)






            next_state = S_IF_END_33;

        end

        S_IF_THEN_36: begin

            // LIR block: if_then_36

            // line 44: accumA(i=u8_aux, j=u8_n0, delta=f32_v2)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_v2;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_36_WAIT;

        end

        S_IF_THEN_36_WAIT: begin

            // LIR block: if_then_36

            // line 44: accumA(i=u8_aux, j=u8_n0, delta=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_38;
            end else begin
                next_state = S_IF_THEN_36_WAIT;
            end

        end

        S_IF_END_37: begin

            // LIR block: if_end_37

            // line 47: if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_40;
            end else begin
                next_state = S_IF_END_41;
            end

        end

        S_AFTER_CALL_38: begin

            // LIR block: after_call_38

            // line 45: f32_neg = neg_comb(v=f32_v2)




            next_f32_neg = neg_comb(f32_v2);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_v2);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_38_WAIT;

        end

        S_AFTER_CALL_38_WAIT: begin

            // LIR block: after_call_38

            // line 45: f32_neg = neg_comb(v=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_39;
            end else begin
                next_state = S_AFTER_CALL_38_WAIT;
            end

        end

        S_AFTER_CALL_39: begin

            // LIR block: after_call_39

            // line 43: if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)






            next_state = S_IF_END_37;

        end

        S_IF_THEN_40: begin

            // LIR block: if_then_40

            // line 48: f32_neg = neg_comb(v=f32_v2)




            next_f32_neg = neg_comb(f32_v2);


            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_v2);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_40_WAIT;

        end

        S_IF_THEN_40_WAIT: begin

            // LIR block: if_then_40

            // line 48: f32_neg = neg_comb(v=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_42;
            end else begin
                next_state = S_IF_THEN_40_WAIT;
            end

        end

        S_IF_END_41: begin

            // LIR block: if_end_41

            // line 51: accumJ(i=u8_aux, delta=f32_v0)





            accumJ_i = u8_aux;

            accumJ_delta = f32_v0;

            accumJ_start = 1'b1;


            next_state = S_IF_END_41_WAIT;

        end

        S_IF_END_41_WAIT: begin

            // LIR block: if_end_41

            // line 51: accumJ(i=u8_aux, delta=f32_v0)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_44;
            end else begin
                next_state = S_IF_END_41_WAIT;
            end

        end

        S_AFTER_CALL_42: begin

            // LIR block: after_call_42

            // line 50: accumA(i=u8_n1, j=u8_aux, delta=f32_v2)





            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = f32_v2;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_42_WAIT;

        end

        S_AFTER_CALL_42_WAIT: begin

            // LIR block: after_call_42

            // line 50: accumA(i=u8_n1, j=u8_aux, delta=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_43;
            end else begin
                next_state = S_AFTER_CALL_42_WAIT;
            end

        end

        S_AFTER_CALL_43: begin

            // LIR block: after_call_43

            // line 47: if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)






            next_state = S_IF_END_41;

        end

        S_AFTER_CALL_44: begin

            // LIR block: after_call_44

            // line 42: if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)






            next_state = S_IF_END_35;

        end

        S_IF_THEN_45: begin

            // LIR block: if_then_45

            // line 54: if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)






            if ((u8_aux != 32'd255)) begin
                next_state = S_IF_THEN_47;
            end else begin
                next_state = S_IF_END_48;
            end

        end

        S_IF_END_46: begin

            // LIR block: if_end_46

            // line 69: if u8_kind == 5:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)






            if ((u8_kind == 32'd5)) begin
                next_state = S_IF_THEN_63;
            end else begin
                next_state = S_IF_END_64;
            end

        end

        S_IF_THEN_47: begin

            // LIR block: if_then_47

            // line 55: if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)






            if ((u8_n2 != 32'd255)) begin
                next_state = S_IF_THEN_49;
            end else begin
                next_state = S_IF_END_50;
            end

        end

        S_IF_END_48: begin

            // LIR block: if_end_48

            // line 53: if u8_kind == 4:             if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)






            next_state = S_IF_END_46;

        end

        S_IF_THEN_49: begin

            // LIR block: if_then_49

            // line 56: accumA(i=u8_aux, j=u8_n2, delta=f32_v2)





            accumA_i = u8_aux;

            accumA_j = u8_n2;

            accumA_delta = f32_v2;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_49_WAIT;

        end

        S_IF_THEN_49_WAIT: begin

            // LIR block: if_then_49

            // line 56: accumA(i=u8_aux, j=u8_n2, delta=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_51;
            end else begin
                next_state = S_IF_THEN_49_WAIT;
            end

        end

        S_IF_END_50: begin

            // LIR block: if_end_50

            // line 59: if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)






            if ((u8_n3 != 32'd255)) begin
                next_state = S_IF_THEN_53;
            end else begin
                next_state = S_IF_END_54;
            end

        end

        S_AFTER_CALL_51: begin

            // LIR block: after_call_51

            // line 57: f32_neg = neg_comb(v=f32_v2)




            next_f32_neg = neg_comb(f32_v2);


            accumA_i = u8_n2;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_v2);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_51_WAIT;

        end

        S_AFTER_CALL_51_WAIT: begin

            // LIR block: after_call_51

            // line 57: f32_neg = neg_comb(v=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_52;
            end else begin
                next_state = S_AFTER_CALL_51_WAIT;
            end

        end

        S_AFTER_CALL_52: begin

            // LIR block: after_call_52

            // line 55: if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)






            next_state = S_IF_END_50;

        end

        S_IF_THEN_53: begin

            // LIR block: if_then_53

            // line 60: f32_neg = neg_comb(v=f32_v2)




            next_f32_neg = neg_comb(f32_v2);


            accumA_i = u8_aux;

            accumA_j = u8_n3;

            accumA_delta = neg_comb(f32_v2);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_53_WAIT;

        end

        S_IF_THEN_53_WAIT: begin

            // LIR block: if_then_53

            // line 60: f32_neg = neg_comb(v=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_55;
            end else begin
                next_state = S_IF_THEN_53_WAIT;
            end

        end

        S_IF_END_54: begin

            // LIR block: if_end_54

            // line 63: if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_57;
            end else begin
                next_state = S_IF_END_58;
            end

        end

        S_AFTER_CALL_55: begin

            // LIR block: after_call_55

            // line 62: accumA(i=u8_n3, j=u8_aux, delta=f32_v2)





            accumA_i = u8_n3;

            accumA_j = u8_aux;

            accumA_delta = f32_v2;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_55_WAIT;

        end

        S_AFTER_CALL_55_WAIT: begin

            // LIR block: after_call_55

            // line 62: accumA(i=u8_n3, j=u8_aux, delta=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_56;
            end else begin
                next_state = S_AFTER_CALL_55_WAIT;
            end

        end

        S_AFTER_CALL_56: begin

            // LIR block: after_call_56

            // line 59: if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)






            next_state = S_IF_END_54;

        end

        S_IF_THEN_57: begin

            // LIR block: if_then_57

            // line 64: f32_neg = neg_comb(v=f32_v0)




            next_f32_neg = neg_comb(f32_v0);


            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = neg_comb(f32_v0);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_57_WAIT;

        end

        S_IF_THEN_57_WAIT: begin

            // LIR block: if_then_57

            // line 64: f32_neg = neg_comb(v=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_59;
            end else begin
                next_state = S_IF_THEN_57_WAIT;
            end

        end

        S_IF_END_58: begin

            // LIR block: if_end_58

            // line 66: if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_60;
            end else begin
                next_state = S_IF_END_61;
            end

        end

        S_AFTER_CALL_59: begin

            // LIR block: after_call_59

            // line 63: if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)






            next_state = S_IF_END_58;

        end

        S_IF_THEN_60: begin

            // LIR block: if_then_60

            // line 67: accumA(i=u8_aux, j=u8_n1, delta=f32_v0)





            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = f32_v0;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_60_WAIT;

        end

        S_IF_THEN_60_WAIT: begin

            // LIR block: if_then_60

            // line 67: accumA(i=u8_aux, j=u8_n1, delta=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_62;
            end else begin
                next_state = S_IF_THEN_60_WAIT;
            end

        end

        S_IF_END_61: begin

            // LIR block: if_end_61

            // line 54: if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)






            next_state = S_IF_END_48;

        end

        S_AFTER_CALL_62: begin

            // LIR block: after_call_62

            // line 66: if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)






            next_state = S_IF_END_61;

        end

        S_IF_THEN_63: begin

            // LIR block: if_then_63

            // line 70: if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)






            if ((u8_aux != 32'd255)) begin
                next_state = S_IF_THEN_65;
            end else begin
                next_state = S_IF_END_66;
            end

        end

        S_IF_END_64: begin

            // LIR block: if_end_64

            // line 13: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         u8_n2 = fetchElemN2(idx=u16_e)         u8_n3 = fetchElemN3(idx=u16_e)         u8_aux = fetchElemAux(idx=u16_e)         f32_v0 = fetchElemVal0(idx=u16_e)         f32_v1 = fetchElemVal1(idx=u16_e)         f32_v2 = fetchElemVal2(idx=u16_e)          if u8_kind == 1:             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n0, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_v0)          if u8_kind == 2:             if u8_n0 != 255:                 f32_neg = neg_comb(v=f32_v0)                 accumJ(i=u8_n0, delta=f32_neg)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_v0)          if u8_kind == 3:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n1, delta=f32_neg)                     accumA(i=u8_n1, j=u8_aux, delta=f32_v2)                 accumJ(i=u8_aux, delta=f32_v0)          if u8_kind == 4:             if u8_aux != 255:                 if u8_n2 != 255:                     accumA(i=u8_aux, j=u8_n2, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_neg)                 if u8_n3 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n3, delta=f32_neg)                     accumA(i=u8_n3, j=u8_aux, delta=f32_v2)                 if u8_n0 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_aux, j=u8_n0, delta=f32_neg)                 if u8_n1 != 255:                     accumA(i=u8_aux, j=u8_n1, delta=f32_v0)          if u8_kind == 5:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)




            next___for_idx_0 = (__for_idx_0 + 16'd1);



            next_state = S_FOR_HEADER_0;

        end

        S_IF_THEN_65: begin

            // LIR block: if_then_65

            // line 71: if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_67;
            end else begin
                next_state = S_IF_END_68;
            end

        end

        S_IF_END_66: begin

            // LIR block: if_end_66

            // line 69: if u8_kind == 5:             if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)






            next_state = S_IF_END_64;

        end

        S_IF_THEN_67: begin

            // LIR block: if_then_67

            // line 72: accumA(i=u8_aux, j=u8_n0, delta=f32_v2)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_v2;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_67_WAIT;

        end

        S_IF_THEN_67_WAIT: begin

            // LIR block: if_then_67

            // line 72: accumA(i=u8_aux, j=u8_n0, delta=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_69;
            end else begin
                next_state = S_IF_THEN_67_WAIT;
            end

        end

        S_IF_END_68: begin

            // LIR block: if_end_68

            // line 75: if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)






            if ((u8_n2 != 32'd255)) begin
                next_state = S_IF_THEN_71;
            end else begin
                next_state = S_IF_END_72;
            end

        end

        S_AFTER_CALL_69: begin

            // LIR block: after_call_69

            // line 73: f32_neg = neg_comb(v=f32_v2)




            next_f32_neg = neg_comb(f32_v2);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_v2);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_69_WAIT;

        end

        S_AFTER_CALL_69_WAIT: begin

            // LIR block: after_call_69

            // line 73: f32_neg = neg_comb(v=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_70;
            end else begin
                next_state = S_AFTER_CALL_69_WAIT;
            end

        end

        S_AFTER_CALL_70: begin

            // LIR block: after_call_70

            // line 71: if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)






            next_state = S_IF_END_68;

        end

        S_IF_THEN_71: begin

            // LIR block: if_then_71

            // line 76: f32_neg = neg_comb(v=f32_v2)




            next_f32_neg = neg_comb(f32_v2);


            accumA_i = u8_aux;

            accumA_j = u8_n2;

            accumA_delta = neg_comb(f32_v2);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_71_WAIT;

        end

        S_IF_THEN_71_WAIT: begin

            // LIR block: if_then_71

            // line 76: f32_neg = neg_comb(v=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_73;
            end else begin
                next_state = S_IF_THEN_71_WAIT;
            end

        end

        S_IF_END_72: begin

            // LIR block: if_end_72

            // line 80: if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_76;
            end else begin
                next_state = S_IF_END_77;
            end

        end

        S_AFTER_CALL_73: begin

            // LIR block: after_call_73

            // line 78: accumA(i=u8_n2, j=u8_aux, delta=f32_v2)





            accumA_i = u8_n2;

            accumA_j = u8_aux;

            accumA_delta = f32_v2;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_73_WAIT;

        end

        S_AFTER_CALL_73_WAIT: begin

            // LIR block: after_call_73

            // line 78: accumA(i=u8_n2, j=u8_aux, delta=f32_v2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_74;
            end else begin
                next_state = S_AFTER_CALL_73_WAIT;
            end

        end

        S_AFTER_CALL_74: begin

            // LIR block: after_call_74

            // line 79: accumA(i=u8_n2, j=u8_aux, delta=f32_v0)





            accumA_i = u8_n2;

            accumA_j = u8_aux;

            accumA_delta = f32_v0;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_74_WAIT;

        end

        S_AFTER_CALL_74_WAIT: begin

            // LIR block: after_call_74

            // line 79: accumA(i=u8_n2, j=u8_aux, delta=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_75;
            end else begin
                next_state = S_AFTER_CALL_74_WAIT;
            end

        end

        S_AFTER_CALL_75: begin

            // LIR block: after_call_75

            // line 75: if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)






            next_state = S_IF_END_72;

        end

        S_IF_THEN_76: begin

            // LIR block: if_then_76

            // line 81: f32_neg = neg_comb(v=f32_v0)




            next_f32_neg = neg_comb(f32_v0);


            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_v0);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_76_WAIT;

        end

        S_IF_THEN_76_WAIT: begin

            // LIR block: if_then_76

            // line 81: f32_neg = neg_comb(v=f32_v0)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_78;
            end else begin
                next_state = S_IF_THEN_76_WAIT;
            end

        end

        S_IF_END_77: begin

            // LIR block: if_end_77

            // line 83: accumJ(i=u8_aux, delta=f32_v1)





            accumJ_i = u8_aux;

            accumJ_delta = f32_v1;

            accumJ_start = 1'b1;


            next_state = S_IF_END_77_WAIT;

        end

        S_IF_END_77_WAIT: begin

            // LIR block: if_end_77

            // line 83: accumJ(i=u8_aux, delta=f32_v1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_79;
            end else begin
                next_state = S_IF_END_77_WAIT;
            end

        end

        S_AFTER_CALL_78: begin

            // LIR block: after_call_78

            // line 80: if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)






            next_state = S_IF_END_77;

        end

        S_AFTER_CALL_79: begin

            // LIR block: after_call_79

            // line 70: if u8_aux != 255:                 if u8_n0 != 255:                     accumA(i=u8_aux, j=u8_n0, delta=f32_v2)                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_n0, j=u8_aux, delta=f32_neg)                 if u8_n2 != 255:                     f32_neg = neg_comb(v=f32_v2)                     accumA(i=u8_aux, j=u8_n2, delta=f32_neg)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v2)                     accumA(i=u8_n2, j=u8_aux, delta=f32_v0)                 if u8_n1 != 255:                     f32_neg = neg_comb(v=f32_v0)                     accumA(i=u8_n1, j=u8_aux, delta=f32_neg)                 accumJ(i=u8_aux, delta=f32_v1)






            next_state = S_IF_END_66;

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
