
// Generated from LIR for function lu_core

// Entry block: entry

// Blocking primitives: fetch_A(latency=2), fetch_LU(latency=2), fma(latency=3), store_LU(latency=1), div(latency=4)

module lu_core (

    input logic clk,

    input logic rst_n,

    input logic start,

    output logic busy,

    output logic done,

    input logic [31:0] par_n,

    output logic fetch_A_start,

    output logic [7:0] fetch_A_i,

    output logic [7:0] fetch_A_j,

    input logic fetch_A_done,

    input logic [31:0] fetch_A_result,

    output logic fetch_LU_start,

    output logic [7:0] fetch_LU_i,

    output logic [7:0] fetch_LU_j,

    input logic fetch_LU_done,

    input logic [31:0] fetch_LU_result,

    output logic fma_start,

    output logic [31:0] fma_a,

    output logic [31:0] fma_b,

    output logic [31:0] fma_c,

    input logic fma_done,

    input logic [31:0] fma_result,

    output logic store_LU_start,

    output logic [7:0] store_LU_i,

    output logic [7:0] store_LU_j,

    output logic [31:0] store_LU_v,

    input logic store_LU_done,

    output logic div_start,

    output logic [31:0] div_a,

    output logic [31:0] div_b,

    input logic div_done,

    input logic [31:0] div_result

);

  function [31:0] neg_comb;
    input logic [31:0] in;
    begin
      neg_comb = {~in[31],in[30:0]};
    end
  endfunction

typedef enum logic [4:0] {

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

    S_FOR_HEADER_7,

    S_FOR_BODY_8,

    S_FOR_BODY_8_WAIT,

    S_FOR_END_9,

    S_AFTER_CALL_10,

    S_AFTER_CALL_10_WAIT,

    S_AFTER_CALL_11,

    S_AFTER_CALL_11_WAIT,

    S_AFTER_CALL_12,

    S_IF_THEN_13,

    S_IF_THEN_13_WAIT,

    S_IF_END_14,

    S_IF_END_14_WAIT,

    S_AFTER_CALL_15,

    S_AFTER_CALL_15_WAIT,

    S_AFTER_CALL_16,

    S_AFTER_CALL_17,

    S_DONE

} state_t;

state_t state;
state_t next_state;


logic [31:0] f32_1;

logic [31:0] f32_2;

logic [31:0] f32_3;

logic [7:0] u8_i;

logic [7:0] u8_j;

logic [7:0] u8_k;

logic [7:0] u8_m;


logic [7:0] __for_idx_0;

logic [7:0] __for_idx_1;

logic [7:0] __for_idx_2;



logic [31:0] next_f32_1;

logic [31:0] next_f32_2;

logic [31:0] next_f32_3;

logic [7:0] next_u8_i;

logic [7:0] next_u8_j;

logic [7:0] next_u8_k;

logic [7:0] next_u8_m;

logic [7:0] next___for_idx_0;

logic [7:0] next___for_idx_1;

logic [7:0] next___for_idx_2;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        f32_1 <=0;

        f32_2 <=0;

        f32_3 <=0;

        u8_i <=0;

        u8_j <=0;

        u8_k <=0;

        u8_m <=0;


        __for_idx_0 <=0;

        __for_idx_1 <=0;

        __for_idx_2 <=0;


    end else begin
        state <= next_state;

        f32_1 <= next_f32_1;

        f32_2 <= next_f32_2;

        f32_3 <= next_f32_3;

        u8_i <= next_u8_i;

        u8_j <= next_u8_j;

        u8_k <= next_u8_k;

        u8_m <= next_u8_m;


        __for_idx_0 <= next___for_idx_0;

        __for_idx_1 <= next___for_idx_1;

        __for_idx_2 <= next___for_idx_2;


    end
end

always_comb begin
    next_state = state;
    busy = 1'b1;
    done = 1'b0;

    next_f32_1 = f32_1;

    next_f32_2 = f32_2;

    next_f32_3 = f32_3;

    next_u8_i = u8_i;

    next_u8_j = u8_j;

    next_u8_k = u8_k;

    next_u8_m = u8_m;


    next___for_idx_0 = __for_idx_0;

    next___for_idx_1 = __for_idx_1;

    next___for_idx_2 = __for_idx_2;



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

    store_LU_start =0;

    store_LU_i =0;

    store_LU_j =0;

    store_LU_v =0;

    div_start =0;

    div_a =0;

    div_b =0;


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

            // line 2: f32_1 = 0




            next_f32_1 = 32'd0;

            next_f32_2 = 32'd0;

            next_f32_3 = 32'd0;

            next_u8_i = 8'd0;

            next_u8_j = 8'd0;

            next_u8_k = 8'd0;

            next_u8_m = 8'd0;

            next___for_idx_0 = 8'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 9: for u8_j in range(par_n):         for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)






            if ((__for_idx_0 < par_n)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 9: for u8_j in range(par_n):         for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)




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

            // line 10: for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)






            if ((__for_idx_1 < par_n)) begin
                next_state = S_FOR_BODY_4;
            end else begin
                next_state = S_FOR_END_5;
            end

        end

        S_FOR_BODY_4: begin

            // LIR block: for_body_4

            // line 10: for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)




            next_u8_i = __for_idx_1;


            fetch_A_i = __for_idx_1;

            fetch_A_j = u8_j;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_4_WAIT;

        end

        S_FOR_BODY_4_WAIT: begin

            // LIR block: for_body_4

            // line 10: for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_6;
            end else begin
                next_state = S_FOR_BODY_4_WAIT;
            end

        end

        S_FOR_END_5: begin

            // LIR block: for_end_5

            // line 9: for u8_j in range(par_n):         for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)




            next___for_idx_0 = (__for_idx_0 + 8'd1);



            next_state = S_FOR_HEADER_0;

        end

        S_AFTER_CALL_6: begin

            // LIR block: after_call_6

            // line 12: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_u8_m = ((u8_i > u8_j) ? u8_j : u8_i);

            next___for_idx_2 = 8'd0;



            next_state = S_FOR_HEADER_7;

        end

        S_FOR_HEADER_7: begin

            // LIR block: for_header_7

            // line 14: for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_2 < u8_m)) begin
                next_state = S_FOR_BODY_8;
            end else begin
                next_state = S_FOR_END_9;
            end

        end

        S_FOR_BODY_8: begin

            // LIR block: for_body_8

            // line 14: for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u8_k = __for_idx_2;


            fetch_LU_i = u8_i;

            fetch_LU_j = __for_idx_2;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_8_WAIT;

        end

        S_FOR_BODY_8_WAIT: begin

            // LIR block: for_body_8

            // line 14: for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_10;
            end else begin
                next_state = S_FOR_BODY_8_WAIT;
            end

        end

        S_FOR_END_9: begin

            // LIR block: for_end_9

            // line 18: if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)






            if ((u8_i > u8_j)) begin
                next_state = S_IF_THEN_13;
            end else begin
                next_state = S_IF_END_14;
            end

        end

        S_AFTER_CALL_10: begin

            // LIR block: after_call_10

            // line 16: f32_3 = fetch_LU(i=u8_k, j=u8_j)





            fetch_LU_i = u8_k;

            fetch_LU_j = u8_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_10_WAIT;

        end

        S_AFTER_CALL_10_WAIT: begin

            // LIR block: after_call_10

            // line 16: f32_3 = fetch_LU(i=u8_k, j=u8_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_11;
            end else begin
                next_state = S_AFTER_CALL_10_WAIT;
            end

        end

        S_AFTER_CALL_11: begin

            // LIR block: after_call_11

            // line 17: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_11_WAIT;

        end

        S_AFTER_CALL_11_WAIT: begin

            // LIR block: after_call_11

            // line 17: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_12;
            end else begin
                next_state = S_AFTER_CALL_11_WAIT;
            end

        end

        S_AFTER_CALL_12: begin

            // LIR block: after_call_12

            // line 14: for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_2 = (__for_idx_2 + 8'd1);



            next_state = S_FOR_HEADER_7;

        end

        S_IF_THEN_13: begin

            // LIR block: if_then_13

            // line 19: f32_2 = fetch_LU(i=u8_j, j=u8_j)





            fetch_LU_i = u8_j;

            fetch_LU_j = u8_j;

            fetch_LU_start = 1'b1;


            next_state = S_IF_THEN_13_WAIT;

        end

        S_IF_THEN_13_WAIT: begin

            // LIR block: if_then_13

            // line 19: f32_2 = fetch_LU(i=u8_j, j=u8_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_15;
            end else begin
                next_state = S_IF_THEN_13_WAIT;
            end

        end

        S_IF_END_14: begin

            // LIR block: if_end_14

            // line 21: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);


            store_LU_i = u8_i;

            store_LU_j = u8_j;

            store_LU_v = neg_comb(f32_1);

            store_LU_start = 1'b1;


            next_state = S_IF_END_14_WAIT;

        end

        S_IF_END_14_WAIT: begin

            // LIR block: if_end_14

            // line 21: f32_1 = neg_comb(v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_17;
            end else begin
                next_state = S_IF_END_14_WAIT;
            end

        end

        S_AFTER_CALL_15: begin

            // LIR block: after_call_15

            // line 20: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_15_WAIT;

        end

        S_AFTER_CALL_15_WAIT: begin

            // LIR block: after_call_15

            // line 20: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_16;
            end else begin
                next_state = S_AFTER_CALL_15_WAIT;
            end

        end

        S_AFTER_CALL_16: begin

            // LIR block: after_call_16

            // line 18: if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)






            next_state = S_IF_END_14;

        end

        S_AFTER_CALL_17: begin

            // LIR block: after_call_17

            // line 10: for u8_i in range(par_n):             f32_1 = fetch_A(i=u8_i, j=u8_j)             f32_1 = neg_comb(v=f32_1)             u8_m = u8_j if u8_i > u8_j else u8_i             for u8_k in range(u8_m):                 f32_2 = fetch_LU(i=u8_i, j=u8_k)                 f32_3 = fetch_LU(i=u8_k, j=u8_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u8_i > u8_j:                 f32_2 = fetch_LU(i=u8_j, j=u8_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u8_i, j=u8_j, v=f32_1)




            next___for_idx_1 = (__for_idx_1 + 8'd1);



            next_state = S_FOR_HEADER_3;

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