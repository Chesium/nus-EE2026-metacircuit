
// Generated from LIR for function solve_core_transient

// Entry block: entry

// Blocking primitives: fetchElemKind(latency=1), store_J(latency=1), store_Y(latency=1), store_X(latency=1), store_A(latency=1), store_LU(latency=1), fetchElemN0(latency=1), fetchElemN1(latency=1), fetchElemVal0(latency=1), fetchElemVal1(latency=1), fetchElemVal2(latency=1), fetchElemVal3(latency=1), div(latency=4), accumA(latency=1), accumJ(latency=1), fetch_prevX(latency=1), fma(latency=3), fetch_A(latency=1), fetch_LU(latency=1), fetch_J(latency=1), fetch_Y(latency=1), fetch_X(latency=1), store_prevX(latency=1)

module solve_core (

    input logic clk,

    input logic rst_n,

    input logic start,

    output logic busy,

    output logic done,

    input logic [31:0] par_elem_n,

    input logic [31:0] par_node_n,

    input logic [31:0] par_dt,

    input logic [31:0] par_time,

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

    input logic [15:0] fetchElemN0_result,

    output logic fetchElemN1_start,

    output logic [15:0] fetchElemN1_idx,

    input logic fetchElemN1_done,

    input logic [15:0] fetchElemN1_result,

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

    output logic fetchElemVal3_start,

    output logic [15:0] fetchElemVal3_idx,

    input logic fetchElemVal3_done,

    input logic [31:0] fetchElemVal3_result,

    output logic div_start,

    output logic [31:0] div_a,

    output logic [31:0] div_b,

    input logic div_done,

    input logic [31:0] div_result,

    output logic accumA_start,

    output logic [15:0] accumA_i,

    output logic [15:0] accumA_j,

    output logic [31:0] accumA_delta,

    input logic accumA_done,

    output logic accumJ_start,

    output logic [15:0] accumJ_i,

    output logic [31:0] accumJ_delta,

    input logic accumJ_done,

    output logic fetch_prevX_start,

    output logic [15:0] fetch_prevX_i,

    input logic fetch_prevX_done,

    input logic [31:0] fetch_prevX_result,

    output logic fma_start,

    output logic [31:0] fma_a,

    output logic [31:0] fma_b,

    output logic [31:0] fma_c,

    input logic fma_done,

    input logic [31:0] fma_result,

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

    input logic [31:0] fetch_X_result,

    output logic store_prevX_start,

    output logic [15:0] store_prevX_i,

    output logic [31:0] store_prevX_v,

    input logic store_prevX_done

);


import StampingCombPkg::*;


typedef enum logic [8:0] {

    S_IDLE,

    S_ENTRY,

    S_FOR_HEADER_0,

    S_FOR_BODY_1,

    S_FOR_BODY_1_WAIT,

    S_FOR_END_2,

    S_AFTER_CALL_3,

    S_IF_THEN_4,

    S_IF_END_5,

    S_IF_THEN_6,

    S_IF_END_7,

    S_IF_THEN_8,

    S_IF_END_9,

    S_IF_THEN_10,

    S_IF_END_11,

    S_FOR_HEADER_12,

    S_FOR_BODY_13,

    S_FOR_BODY_13_WAIT,

    S_FOR_END_14,

    S_AFTER_CALL_15,

    S_AFTER_CALL_15_WAIT,

    S_AFTER_CALL_16,

    S_AFTER_CALL_16_WAIT,

    S_AFTER_CALL_17,

    S_FOR_HEADER_18,

    S_FOR_BODY_19,

    S_FOR_BODY_19_WAIT,

    S_FOR_END_20,

    S_AFTER_CALL_21,

    S_AFTER_CALL_21_WAIT,

    S_AFTER_CALL_22,

    S_FOR_HEADER_23,

    S_FOR_BODY_24,

    S_FOR_BODY_24_WAIT,

    S_FOR_END_25,

    S_AFTER_CALL_26,

    S_AFTER_CALL_26_WAIT,

    S_AFTER_CALL_27,

    S_AFTER_CALL_27_WAIT,

    S_AFTER_CALL_28,

    S_AFTER_CALL_28_WAIT,

    S_AFTER_CALL_29,

    S_AFTER_CALL_29_WAIT,

    S_AFTER_CALL_30,

    S_AFTER_CALL_30_WAIT,

    S_AFTER_CALL_31,

    S_AFTER_CALL_31_WAIT,

    S_AFTER_CALL_32,

    S_IF_THEN_33,

    S_IF_END_34,

    S_IF_ELSE_35,

    S_IF_THEN_36,

    S_IF_END_37,

    S_IF_ELSE_38,

    S_IF_THEN_39,

    S_IF_THEN_39_WAIT,

    S_IF_END_40,

    S_AFTER_CALL_41,

    S_IF_THEN_42,

    S_IF_THEN_42_WAIT,

    S_IF_END_43,

    S_AFTER_CALL_44,

    S_IF_THEN_45,

    S_IF_THEN_45_WAIT,

    S_IF_END_46,

    S_AFTER_CALL_47,

    S_AFTER_CALL_47_WAIT,

    S_AFTER_CALL_48,

    S_IF_THEN_49,

    S_IF_THEN_49_WAIT,

    S_IF_END_50,

    S_AFTER_CALL_51,

    S_IF_THEN_52,

    S_IF_END_53,

    S_IF_THEN_54,

    S_IF_THEN_54_WAIT,

    S_IF_END_55,

    S_AFTER_CALL_56,

    S_IF_THEN_57,

    S_IF_THEN_57_WAIT,

    S_IF_END_58,

    S_AFTER_CALL_59,

    S_IF_THEN_60,

    S_IF_END_61,

    S_IF_THEN_62,

    S_IF_THEN_62_WAIT,

    S_IF_END_63,

    S_AFTER_CALL_64,

    S_AFTER_CALL_64_WAIT,

    S_AFTER_CALL_65,

    S_IF_THEN_66,

    S_IF_THEN_66_WAIT,

    S_IF_END_67,

    S_IF_END_67_WAIT,

    S_AFTER_CALL_68,

    S_AFTER_CALL_68_WAIT,

    S_AFTER_CALL_69,

    S_AFTER_CALL_70,

    S_IF_THEN_71,

    S_IF_THEN_71_WAIT,

    S_IF_END_72,

    S_AFTER_CALL_73,

    S_IF_THEN_74,

    S_IF_THEN_74_WAIT,

    S_IF_END_75,

    S_AFTER_CALL_76,

    S_IF_THEN_77,

    S_IF_THEN_77_WAIT,

    S_IF_END_78,

    S_AFTER_CALL_79,

    S_AFTER_CALL_79_WAIT,

    S_AFTER_CALL_80,

    S_IF_THEN_81,

    S_IF_THEN_81_WAIT,

    S_IF_END_82,

    S_AFTER_CALL_83,

    S_IF_THEN_84,

    S_IF_THEN_84_WAIT,

    S_IF_END_85,

    S_AFTER_CALL_86,

    S_AFTER_CALL_86_WAIT,

    S_AFTER_CALL_87,

    S_IF_THEN_88,

    S_IF_THEN_88_WAIT,

    S_IF_END_89,

    S_IF_END_89_WAIT,

    S_AFTER_CALL_90,

    S_AFTER_CALL_91,

    S_IF_THEN_92,

    S_IF_THEN_92_WAIT,

    S_IF_END_93,

    S_AFTER_CALL_94,

    S_IF_THEN_95,

    S_IF_THEN_95_WAIT,

    S_IF_END_96,

    S_AFTER_CALL_97,

    S_IF_THEN_98,

    S_IF_THEN_98_WAIT,

    S_IF_END_99,

    S_AFTER_CALL_100,

    S_AFTER_CALL_100_WAIT,

    S_AFTER_CALL_101,

    S_IF_THEN_102,

    S_IF_THEN_102_WAIT,

    S_IF_END_103,

    S_AFTER_CALL_104,

    S_AFTER_CALL_104_WAIT,

    S_AFTER_CALL_105,

    S_IF_THEN_106,

    S_IF_THEN_106_WAIT,

    S_IF_END_107,

    S_IF_END_107_WAIT,

    S_AFTER_CALL_108,

    S_AFTER_CALL_108_WAIT,

    S_AFTER_CALL_109,

    S_AFTER_CALL_110,

    S_AFTER_CALL_110_WAIT,

    S_AFTER_CALL_111,

    S_AFTER_CALL_111_WAIT,

    S_AFTER_CALL_112,

    S_IF_THEN_113,

    S_IF_THEN_113_WAIT,

    S_IF_END_114,

    S_AFTER_CALL_115,

    S_AFTER_CALL_115_WAIT,

    S_AFTER_CALL_116,

    S_IF_THEN_117,

    S_IF_THEN_117_WAIT,

    S_IF_END_118,

    S_AFTER_CALL_119,

    S_AFTER_CALL_119_WAIT,

    S_AFTER_CALL_120,

    S_IF_THEN_121,

    S_IF_THEN_121_WAIT,

    S_IF_END_122,

    S_IF_END_122_WAIT,

    S_AFTER_CALL_123,

    S_AFTER_CALL_123_WAIT,

    S_AFTER_CALL_124,

    S_AFTER_CALL_125,

    S_IF_THEN_126,

    S_IF_THEN_126_WAIT,

    S_IF_END_127,

    S_AFTER_CALL_128,

    S_AFTER_CALL_128_WAIT,

    S_AFTER_CALL_129,

    S_IF_THEN_130,

    S_IF_THEN_130_WAIT,

    S_IF_END_131,

    S_AFTER_CALL_132,

    S_IF_THEN_133,

    S_IF_THEN_133_WAIT,

    S_IF_END_134,

    S_AFTER_CALL_135,

    S_IF_THEN_136,

    S_IF_END_137,

    S_IF_THEN_138,

    S_IF_END_139,

    S_IF_END_139_WAIT,

    S_AFTER_CALL_140,

    S_IF_THEN_141,

    S_IF_THEN_141_WAIT,

    S_IF_END_142,

    S_AFTER_CALL_143,

    S_IF_THEN_144,

    S_IF_THEN_144_WAIT,

    S_IF_END_145,

    S_AFTER_CALL_146,

    S_AFTER_CALL_146_WAIT,

    S_AFTER_CALL_147,

    S_IF_THEN_148,

    S_IF_THEN_148_WAIT,

    S_IF_END_149,

    S_AFTER_CALL_150,

    S_IF_THEN_151,

    S_IF_END_152,

    S_IF_THEN_153,

    S_IF_END_154,

    S_IF_THEN_155,

    S_IF_THEN_155_WAIT,

    S_IF_END_156,

    S_AFTER_CALL_157,

    S_AFTER_CALL_157_WAIT,

    S_AFTER_CALL_158,

    S_IF_THEN_159,

    S_IF_THEN_159_WAIT,

    S_IF_END_160,

    S_IF_END_160_WAIT,

    S_AFTER_CALL_161,

    S_AFTER_CALL_161_WAIT,

    S_AFTER_CALL_162,

    S_AFTER_CALL_163,

    S_FOR_HEADER_164,

    S_FOR_BODY_165,

    S_FOR_BODY_165_WAIT,

    S_FOR_END_166,

    S_AFTER_CALL_167,

    S_FOR_HEADER_168,

    S_FOR_BODY_169,

    S_FOR_BODY_169_WAIT,

    S_FOR_END_170,

    S_AFTER_CALL_171,

    S_AFTER_CALL_171_WAIT,

    S_AFTER_CALL_172,

    S_AFTER_CALL_172_WAIT,

    S_AFTER_CALL_173,

    S_WHILE_HEADER_174,

    S_WHILE_BODY_175,

    S_WHILE_BODY_175_WAIT,

    S_WHILE_END_176,

    S_AFTER_CALL_177,

    S_FOR_HEADER_178,

    S_FOR_BODY_179,

    S_FOR_BODY_179_WAIT,

    S_FOR_END_180,

    S_AFTER_CALL_181,

    S_AFTER_CALL_181_WAIT,

    S_AFTER_CALL_182,

    S_AFTER_CALL_182_WAIT,

    S_AFTER_CALL_183,

    S_IF_THEN_184,

    S_IF_END_185,

    S_IF_THEN_186,

    S_IF_END_187,

    S_FOR_HEADER_188,

    S_FOR_BODY_189,

    S_FOR_BODY_189_WAIT,

    S_FOR_END_190,

    S_AFTER_CALL_191,

    S_AFTER_CALL_191_WAIT,

    S_AFTER_CALL_192,

    S_AFTER_CALL_192_WAIT,

    S_AFTER_CALL_193,

    S_AFTER_CALL_193_WAIT,

    S_AFTER_CALL_194,

    S_FOR_HEADER_195,

    S_FOR_BODY_196,

    S_FOR_BODY_196_WAIT,

    S_FOR_END_197,

    S_FOR_END_197_WAIT,

    S_AFTER_CALL_198,

    S_AFTER_CALL_198_WAIT,

    S_AFTER_CALL_199,

    S_AFTER_CALL_199_WAIT,

    S_AFTER_CALL_200,

    S_AFTER_CALL_200_WAIT,

    S_AFTER_CALL_201,

    S_AFTER_CALL_202,

    S_AFTER_CALL_202_WAIT,

    S_AFTER_CALL_203,

    S_AFTER_CALL_203_WAIT,

    S_AFTER_CALL_204,

    S_AFTER_CALL_204_WAIT,

    S_AFTER_CALL_205,

    S_FOR_HEADER_206,

    S_FOR_BODY_207,

    S_FOR_BODY_207_WAIT,

    S_FOR_END_208,

    S_AFTER_CALL_209,

    S_FOR_HEADER_210,

    S_FOR_BODY_211,

    S_FOR_BODY_211_WAIT,

    S_FOR_END_212,

    S_AFTER_CALL_213,

    S_AFTER_CALL_213_WAIT,

    S_AFTER_CALL_214,

    S_AFTER_CALL_214_WAIT,

    S_AFTER_CALL_215,

    S_IF_THEN_216,

    S_IF_THEN_216_WAIT,

    S_IF_END_217,

    S_IF_END_217_WAIT,

    S_AFTER_CALL_218,

    S_AFTER_CALL_218_WAIT,

    S_AFTER_CALL_219,

    S_AFTER_CALL_220,

    S_FOR_HEADER_221,

    S_FOR_BODY_222,

    S_FOR_BODY_222_WAIT,

    S_FOR_END_223,

    S_AFTER_CALL_224,

    S_FOR_HEADER_225,

    S_FOR_BODY_226,

    S_FOR_BODY_226_WAIT,

    S_FOR_END_227,

    S_FOR_END_227_WAIT,

    S_AFTER_CALL_228,

    S_AFTER_CALL_228_WAIT,

    S_AFTER_CALL_229,

    S_AFTER_CALL_229_WAIT,

    S_AFTER_CALL_230,

    S_AFTER_CALL_231,

    S_WHILE_HEADER_232,

    S_WHILE_BODY_233,

    S_WHILE_BODY_233_WAIT,

    S_WHILE_END_234,

    S_AFTER_CALL_235,

    S_WHILE_HEADER_236,

    S_WHILE_BODY_237,

    S_WHILE_BODY_237_WAIT,

    S_WHILE_END_238,

    S_WHILE_END_238_WAIT,

    S_AFTER_CALL_239,

    S_AFTER_CALL_239_WAIT,

    S_AFTER_CALL_240,

    S_AFTER_CALL_240_WAIT,

    S_AFTER_CALL_241,

    S_AFTER_CALL_242,

    S_AFTER_CALL_242_WAIT,

    S_AFTER_CALL_243,

    S_AFTER_CALL_243_WAIT,

    S_AFTER_CALL_244,

    S_FOR_HEADER_245,

    S_FOR_BODY_246,

    S_FOR_BODY_246_WAIT,

    S_FOR_END_247,

    S_AFTER_CALL_248,

    S_AFTER_CALL_248_WAIT,

    S_AFTER_CALL_249,

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

logic [31:0] f32_6;

logic [31:0] f32_7;

logic [7:0] u8_kind;

logic [15:0] u16_aux;

logic [15:0] u16_dim;

logic [15:0] u16_e;

logic [15:0] u16_i;

logic [15:0] u16_j;

logic [15:0] u16_k;

logic [15:0] u16_m;

logic [15:0] u16_n0;

logic [15:0] u16_n1;

logic [15:0] u16_next_aux;

logic [15:0] u16_pivot;

logic [7:0] u8_gate;


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

logic [15:0] __for_idx_13;



logic [31:0] next_f32_0;

logic [31:0] next_f32_1;

logic [31:0] next_f32_2;

logic [31:0] next_f32_3;

logic [31:0] next_f32_4;

logic [31:0] next_f32_5;

logic [31:0] next_f32_6;

logic [31:0] next_f32_7;

logic [7:0] next_u8_kind;

logic [15:0] next_u16_aux;

logic [15:0] next_u16_dim;

logic [15:0] next_u16_e;

logic [15:0] next_u16_i;

logic [15:0] next_u16_j;

logic [15:0] next_u16_k;

logic [15:0] next_u16_m;

logic [15:0] next_u16_n0;

logic [15:0] next_u16_n1;

logic [15:0] next_u16_next_aux;

logic [15:0] next_u16_pivot;

logic [7:0] next_u8_gate;

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

logic [15:0] next___for_idx_13;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_IDLE;

        f32_0 <=0;

        f32_1 <=0;

        f32_2 <=0;

        f32_3 <=0;

        f32_4 <=0;

        f32_5 <=0;

        f32_6 <=0;

        f32_7 <=0;

        u8_kind <=0;

        u16_aux <=0;

        u16_dim <=0;

        u16_e <=0;

        u16_i <=0;

        u16_j <=0;

        u16_k <=0;

        u16_m <=0;

        u16_n0 <=0;

        u16_n1 <=0;

        u16_next_aux <=0;

        u16_pivot <=0;

        u8_gate <=0;


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

        __for_idx_13 <=0;


    end else begin
        state <= next_state;

        f32_0 <= next_f32_0;

        f32_1 <= next_f32_1;

        f32_2 <= next_f32_2;

        f32_3 <= next_f32_3;

        f32_4 <= next_f32_4;

        f32_5 <= next_f32_5;

        f32_6 <= next_f32_6;

        f32_7 <= next_f32_7;

        u8_kind <= next_u8_kind;

        u16_aux <= next_u16_aux;

        u16_dim <= next_u16_dim;

        u16_e <= next_u16_e;

        u16_i <= next_u16_i;

        u16_j <= next_u16_j;

        u16_k <= next_u16_k;

        u16_m <= next_u16_m;

        u16_n0 <= next_u16_n0;

        u16_n1 <= next_u16_n1;

        u16_next_aux <= next_u16_next_aux;

        u16_pivot <= next_u16_pivot;

        u8_gate <= next_u8_gate;


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

        __for_idx_13 <= next___for_idx_13;


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

    next_f32_6 = f32_6;

    next_f32_7 = f32_7;

    next_u8_kind = u8_kind;

    next_u16_aux = u16_aux;

    next_u16_dim = u16_dim;

    next_u16_e = u16_e;

    next_u16_i = u16_i;

    next_u16_j = u16_j;

    next_u16_k = u16_k;

    next_u16_m = u16_m;

    next_u16_n0 = u16_n0;

    next_u16_n1 = u16_n1;

    next_u16_next_aux = u16_next_aux;

    next_u16_pivot = u16_pivot;

    next_u8_gate = u8_gate;


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

    next___for_idx_13 = __for_idx_13;



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

    fetchElemVal1_start =0;

    fetchElemVal1_idx =0;

    fetchElemVal2_start =0;

    fetchElemVal2_idx =0;

    fetchElemVal3_start =0;

    fetchElemVal3_idx =0;

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

    fetch_prevX_start =0;

    fetch_prevX_i =0;

    fma_start =0;

    fma_a =0;

    fma_b =0;

    fma_c =0;

    fetch_A_start =0;

    fetch_A_i =0;

    fetch_A_j =0;

    fetch_LU_start =0;

    fetch_LU_i =0;

    fetch_LU_j =0;

    fetch_J_start =0;

    fetch_J_i =0;

    fetch_Y_start =0;

    fetch_Y_i =0;

    fetch_X_start =0;

    fetch_X_i =0;

    store_prevX_start =0;

    store_prevX_i =0;

    store_prevX_v =0;


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

            // line 57: f32_0 = 0




            next_f32_0 = 32'h00000000;

            next_f32_1 = 32'h00000000;

            next_f32_2 = 32'h00000000;

            next_f32_3 = 32'h00000000;

            next_f32_4 = 32'h00000000;

            next_f32_5 = 32'h3f800000;

            next_f32_6 = 32'h00000000;

            next_f32_7 = 32'h00000000;

            next_u8_kind = 8'd0;

            next_u16_aux = 16'd0;

            next_u16_dim = 16'd0;

            next_u16_e = 16'd0;

            next_u16_i = 16'd0;

            next_u16_j = 16'd0;

            next_u16_k = 16'd0;

            next_u16_m = 16'd0;

            next_u16_n0 = 16'd0;

            next_u16_n1 = 16'd0;

            next_u16_next_aux = 16'd0;

            next_u16_pivot = 16'd0;

            next_u8_gate = 8'd0;

            next_u16_dim = par_node_n;

            next___for_idx_0 = 16'd0;



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_0: begin

            // LIR block: for_header_0

            // line 81: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1         if u8_kind == 5:             u16_dim = u16_dim + 1         if u8_kind == 6:             u16_dim = u16_dim + 1         if u8_kind == 9:             u16_dim = u16_dim + 1






            if ((__for_idx_0 < par_elem_n)) begin
                next_state = S_FOR_BODY_1;
            end else begin
                next_state = S_FOR_END_2;
            end

        end

        S_FOR_BODY_1: begin

            // LIR block: for_body_1

            // line 81: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1         if u8_kind == 5:             u16_dim = u16_dim + 1         if u8_kind == 6:             u16_dim = u16_dim + 1         if u8_kind == 9:             u16_dim = u16_dim + 1




            next_u16_e = __for_idx_0;


            fetchElemKind_idx = __for_idx_0;

            fetchElemKind_start = 1'b1;


            next_state = S_FOR_BODY_1_WAIT;

        end

        S_FOR_BODY_1_WAIT: begin

            // LIR block: for_body_1

            // line 81: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1         if u8_kind == 5:             u16_dim = u16_dim + 1         if u8_kind == 6:             u16_dim = u16_dim + 1         if u8_kind == 9:             u16_dim = u16_dim + 1

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

            // line 94: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_1 = 16'd0;



            next_state = S_FOR_HEADER_12;

        end

        S_AFTER_CALL_3: begin

            // LIR block: after_call_3

            // line 83: if u8_kind == 3:             u16_dim = u16_dim + 1






            if ((u8_kind == 32'd3)) begin
                next_state = S_IF_THEN_4;
            end else begin
                next_state = S_IF_END_5;
            end

        end

        S_IF_THEN_4: begin

            // LIR block: if_then_4

            // line 84: u16_dim = u16_dim + 1




            next_u16_dim = (u16_dim + 16'd1);



            next_state = S_IF_END_5;

        end

        S_IF_END_5: begin

            // LIR block: if_end_5

            // line 85: if u8_kind == 5:             u16_dim = u16_dim + 1






            if ((u8_kind == 32'd5)) begin
                next_state = S_IF_THEN_6;
            end else begin
                next_state = S_IF_END_7;
            end

        end

        S_IF_THEN_6: begin

            // LIR block: if_then_6

            // line 86: u16_dim = u16_dim + 1




            next_u16_dim = (u16_dim + 16'd1);



            next_state = S_IF_END_7;

        end

        S_IF_END_7: begin

            // LIR block: if_end_7

            // line 87: if u8_kind == 6:             u16_dim = u16_dim + 1






            if ((u8_kind == 32'd6)) begin
                next_state = S_IF_THEN_8;
            end else begin
                next_state = S_IF_END_9;
            end

        end

        S_IF_THEN_8: begin

            // LIR block: if_then_8

            // line 88: u16_dim = u16_dim + 1




            next_u16_dim = (u16_dim + 16'd1);



            next_state = S_IF_END_9;

        end

        S_IF_END_9: begin

            // LIR block: if_end_9

            // line 89: if u8_kind == 9:             u16_dim = u16_dim + 1






            if ((u8_kind == 32'd9)) begin
                next_state = S_IF_THEN_10;
            end else begin
                next_state = S_IF_END_11;
            end

        end

        S_IF_THEN_10: begin

            // LIR block: if_then_10

            // line 90: u16_dim = u16_dim + 1




            next_u16_dim = (u16_dim + 16'd1);



            next_state = S_IF_END_11;

        end

        S_IF_END_11: begin

            // LIR block: if_end_11

            // line 81: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         if u8_kind == 3:             u16_dim = u16_dim + 1         if u8_kind == 5:             u16_dim = u16_dim + 1         if u8_kind == 6:             u16_dim = u16_dim + 1         if u8_kind == 9:             u16_dim = u16_dim + 1




            next___for_idx_0 = (__for_idx_0 + 16'd1);



            next_state = S_FOR_HEADER_0;

        end

        S_FOR_HEADER_12: begin

            // LIR block: for_header_12

            // line 94: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)






            if ((__for_idx_1 < u16_dim)) begin
                next_state = S_FOR_BODY_13;
            end else begin
                next_state = S_FOR_END_14;
            end

        end

        S_FOR_BODY_13: begin

            // LIR block: for_body_13

            // line 94: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next_u16_i = __for_idx_1;


            store_J_i = __for_idx_1;

            store_J_v = f32_0;

            store_J_start = 1'b1;


            next_state = S_FOR_BODY_13_WAIT;

        end

        S_FOR_BODY_13_WAIT: begin

            // LIR block: for_body_13

            // line 94: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_15;
            end else begin
                next_state = S_FOR_BODY_13_WAIT;
            end

        end

        S_FOR_END_14: begin

            // LIR block: for_end_14

            // line 103: u16_next_aux = par_node_n




            next_u16_next_aux = par_node_n;

            next___for_idx_3 = 16'd0;



            next_state = S_FOR_HEADER_23;

        end

        S_AFTER_CALL_15: begin

            // LIR block: after_call_15

            // line 96: store_Y(i=u16_i, v=f32_0)





            store_Y_i = u16_i;

            store_Y_v = f32_0;

            store_Y_start = 1'b1;


            next_state = S_AFTER_CALL_15_WAIT;

        end

        S_AFTER_CALL_15_WAIT: begin

            // LIR block: after_call_15

            // line 96: store_Y(i=u16_i, v=f32_0)

            // wait for blocking primitive: store_Y






            if (store_Y_done) begin

                next_state = S_AFTER_CALL_16;
            end else begin
                next_state = S_AFTER_CALL_15_WAIT;
            end

        end

        S_AFTER_CALL_16: begin

            // LIR block: after_call_16

            // line 97: store_X(i=u16_i, v=f32_0)





            store_X_i = u16_i;

            store_X_v = f32_0;

            store_X_start = 1'b1;


            next_state = S_AFTER_CALL_16_WAIT;

        end

        S_AFTER_CALL_16_WAIT: begin

            // LIR block: after_call_16

            // line 97: store_X(i=u16_i, v=f32_0)

            // wait for blocking primitive: store_X






            if (store_X_done) begin

                next_state = S_AFTER_CALL_17;
            end else begin
                next_state = S_AFTER_CALL_16_WAIT;
            end

        end

        S_AFTER_CALL_17: begin

            // LIR block: after_call_17

            // line 98: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_2 = 16'd0;



            next_state = S_FOR_HEADER_18;

        end

        S_FOR_HEADER_18: begin

            // LIR block: for_header_18

            // line 98: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)






            if ((__for_idx_2 < u16_dim)) begin
                next_state = S_FOR_BODY_19;
            end else begin
                next_state = S_FOR_END_20;
            end

        end

        S_FOR_BODY_19: begin

            // LIR block: for_body_19

            // line 98: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next_u16_j = __for_idx_2;


            store_A_i = u16_i;

            store_A_j = __for_idx_2;

            store_A_v = f32_0;

            store_A_start = 1'b1;


            next_state = S_FOR_BODY_19_WAIT;

        end

        S_FOR_BODY_19_WAIT: begin

            // LIR block: for_body_19

            // line 98: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_21;
            end else begin
                next_state = S_FOR_BODY_19_WAIT;
            end

        end

        S_FOR_END_20: begin

            // LIR block: for_end_20

            // line 94: for u16_i in range(u16_dim):         store_J(i=u16_i, v=f32_0)         store_Y(i=u16_i, v=f32_0)         store_X(i=u16_i, v=f32_0)         for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_1 = (__for_idx_1 + 16'd1);



            next_state = S_FOR_HEADER_12;

        end

        S_AFTER_CALL_21: begin

            // LIR block: after_call_21

            // line 100: store_LU(i=u16_i, j=u16_j, v=f32_0)





            store_LU_i = u16_i;

            store_LU_j = u16_j;

            store_LU_v = f32_0;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_21_WAIT;

        end

        S_AFTER_CALL_21_WAIT: begin

            // LIR block: after_call_21

            // line 100: store_LU(i=u16_i, j=u16_j, v=f32_0)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_22;
            end else begin
                next_state = S_AFTER_CALL_21_WAIT;
            end

        end

        S_AFTER_CALL_22: begin

            // LIR block: after_call_22

            // line 98: for u16_j in range(u16_dim):             store_A(i=u16_i, j=u16_j, v=f32_0)             store_LU(i=u16_i, j=u16_j, v=f32_0)




            next___for_idx_2 = (__for_idx_2 + 16'd1);



            next_state = S_FOR_HEADER_18;

        end

        S_FOR_HEADER_23: begin

            // LIR block: for_header_23

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u16_n0 = fetchElemN0(idx=u16_e)         u16_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u16_n0 != 0:             u16_n0 = u16_n0 - 1         else:             u16_n0 = 65535          if u16_n1 != 0:             u16_n1 = u16_n1 - 1         else:             u16_n1 = 65535          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          if u8_kind == 2:             if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)          if u8_kind == 3:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)             if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)             if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u16_aux)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)             if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u16_aux, j=u16_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u16_aux, delta=f32_2)          if u8_kind == 6:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)






            if ((__for_idx_3 < par_elem_n)) begin
                next_state = S_FOR_BODY_24;
            end else begin
                next_state = S_FOR_END_25;
            end

        end

        S_FOR_BODY_24: begin

            // LIR block: for_body_24

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u16_n0 = fetchElemN0(idx=u16_e)         u16_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u16_n0 != 0:             u16_n0 = u16_n0 - 1         else:             u16_n0 = 65535          if u16_n1 != 0:             u16_n1 = u16_n1 - 1         else:             u16_n1 = 65535          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          if u8_kind == 2:             if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)          if u8_kind == 3:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)             if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)             if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u16_aux)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)             if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u16_aux, j=u16_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u16_aux, delta=f32_2)          if u8_kind == 6:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)




            next_u16_e = __for_idx_3;


            fetchElemKind_idx = __for_idx_3;

            fetchElemKind_start = 1'b1;


            next_state = S_FOR_BODY_24_WAIT;

        end

        S_FOR_BODY_24_WAIT: begin

            // LIR block: for_body_24

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u16_n0 = fetchElemN0(idx=u16_e)         u16_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u16_n0 != 0:             u16_n0 = u16_n0 - 1         else:             u16_n0 = 65535          if u16_n1 != 0:             u16_n1 = u16_n1 - 1         else:             u16_n1 = 65535          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          if u8_kind == 2:             if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)          if u8_kind == 3:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)             if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)             if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u16_aux)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)             if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u16_aux, j=u16_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u16_aux, delta=f32_2)          if u8_kind == 6:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)

            // wait for blocking primitive: fetchElemKind






            if (fetchElemKind_done) begin

                next_u8_kind = fetchElemKind_result;

                next_state = S_AFTER_CALL_26;
            end else begin
                next_state = S_FOR_BODY_24_WAIT;
            end

        end

        S_FOR_END_25: begin

            // LIR block: for_end_25

            // line 266: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_4 = 16'd0;



            next_state = S_FOR_HEADER_164;

        end

        S_AFTER_CALL_26: begin

            // LIR block: after_call_26

            // line 106: u16_n0 = fetchElemN0(idx=u16_e)





            fetchElemN0_idx = u16_e;

            fetchElemN0_start = 1'b1;


            next_state = S_AFTER_CALL_26_WAIT;

        end

        S_AFTER_CALL_26_WAIT: begin

            // LIR block: after_call_26

            // line 106: u16_n0 = fetchElemN0(idx=u16_e)

            // wait for blocking primitive: fetchElemN0






            if (fetchElemN0_done) begin

                next_u16_n0 = fetchElemN0_result;

                next_state = S_AFTER_CALL_27;
            end else begin
                next_state = S_AFTER_CALL_26_WAIT;
            end

        end

        S_AFTER_CALL_27: begin

            // LIR block: after_call_27

            // line 107: u16_n1 = fetchElemN1(idx=u16_e)





            fetchElemN1_idx = u16_e;

            fetchElemN1_start = 1'b1;


            next_state = S_AFTER_CALL_27_WAIT;

        end

        S_AFTER_CALL_27_WAIT: begin

            // LIR block: after_call_27

            // line 107: u16_n1 = fetchElemN1(idx=u16_e)

            // wait for blocking primitive: fetchElemN1






            if (fetchElemN1_done) begin

                next_u16_n1 = fetchElemN1_result;

                next_state = S_AFTER_CALL_28;
            end else begin
                next_state = S_AFTER_CALL_27_WAIT;
            end

        end

        S_AFTER_CALL_28: begin

            // LIR block: after_call_28

            // line 108: f32_1 = fetchElemVal0(idx=u16_e)





            fetchElemVal0_idx = u16_e;

            fetchElemVal0_start = 1'b1;


            next_state = S_AFTER_CALL_28_WAIT;

        end

        S_AFTER_CALL_28_WAIT: begin

            // LIR block: after_call_28

            // line 108: f32_1 = fetchElemVal0(idx=u16_e)

            // wait for blocking primitive: fetchElemVal0






            if (fetchElemVal0_done) begin

                next_f32_1 = fetchElemVal0_result;

                next_state = S_AFTER_CALL_29;
            end else begin
                next_state = S_AFTER_CALL_28_WAIT;
            end

        end

        S_AFTER_CALL_29: begin

            // LIR block: after_call_29

            // line 109: f32_2 = fetchElemVal1(idx=u16_e)





            fetchElemVal1_idx = u16_e;

            fetchElemVal1_start = 1'b1;


            next_state = S_AFTER_CALL_29_WAIT;

        end

        S_AFTER_CALL_29_WAIT: begin

            // LIR block: after_call_29

            // line 109: f32_2 = fetchElemVal1(idx=u16_e)

            // wait for blocking primitive: fetchElemVal1






            if (fetchElemVal1_done) begin

                next_f32_2 = fetchElemVal1_result;

                next_state = S_AFTER_CALL_30;
            end else begin
                next_state = S_AFTER_CALL_29_WAIT;
            end

        end

        S_AFTER_CALL_30: begin

            // LIR block: after_call_30

            // line 110: f32_3 = fetchElemVal2(idx=u16_e)





            fetchElemVal2_idx = u16_e;

            fetchElemVal2_start = 1'b1;


            next_state = S_AFTER_CALL_30_WAIT;

        end

        S_AFTER_CALL_30_WAIT: begin

            // LIR block: after_call_30

            // line 110: f32_3 = fetchElemVal2(idx=u16_e)

            // wait for blocking primitive: fetchElemVal2






            if (fetchElemVal2_done) begin

                next_f32_3 = fetchElemVal2_result;

                next_state = S_AFTER_CALL_31;
            end else begin
                next_state = S_AFTER_CALL_30_WAIT;
            end

        end

        S_AFTER_CALL_31: begin

            // LIR block: after_call_31

            // line 111: f32_4 = fetchElemVal3(idx=u16_e)





            fetchElemVal3_idx = u16_e;

            fetchElemVal3_start = 1'b1;


            next_state = S_AFTER_CALL_31_WAIT;

        end

        S_AFTER_CALL_31_WAIT: begin

            // LIR block: after_call_31

            // line 111: f32_4 = fetchElemVal3(idx=u16_e)

            // wait for blocking primitive: fetchElemVal3






            if (fetchElemVal3_done) begin

                next_f32_4 = fetchElemVal3_result;

                next_state = S_AFTER_CALL_32;
            end else begin
                next_state = S_AFTER_CALL_31_WAIT;
            end

        end

        S_AFTER_CALL_32: begin

            // LIR block: after_call_32

            // line 113: if u16_n0 != 0:             u16_n0 = u16_n0 - 1         else:             u16_n0 = 65535






            if ((u16_n0 != 32'd0)) begin
                next_state = S_IF_THEN_33;
            end else begin
                next_state = S_IF_ELSE_35;
            end

        end

        S_IF_THEN_33: begin

            // LIR block: if_then_33

            // line 114: u16_n0 = u16_n0 - 1




            next_u16_n0 = (u16_n0 - 16'd1);



            next_state = S_IF_END_34;

        end

        S_IF_END_34: begin

            // LIR block: if_end_34

            // line 118: if u16_n1 != 0:             u16_n1 = u16_n1 - 1         else:             u16_n1 = 65535






            if ((u16_n1 != 32'd0)) begin
                next_state = S_IF_THEN_36;
            end else begin
                next_state = S_IF_ELSE_38;
            end

        end

        S_IF_ELSE_35: begin

            // LIR block: if_else_35

            // line 116: u16_n0 = 65535




            next_u16_n0 = 16'd65535;



            next_state = S_IF_END_34;

        end

        S_IF_THEN_36: begin

            // LIR block: if_then_36

            // line 119: u16_n1 = u16_n1 - 1




            next_u16_n1 = (u16_n1 - 16'd1);



            next_state = S_IF_END_37;

        end

        S_IF_END_37: begin

            // LIR block: if_end_37

            // line 123: if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            if ((u8_kind == 32'd1)) begin
                next_state = S_IF_THEN_39;
            end else begin
                next_state = S_IF_END_40;
            end

        end

        S_IF_ELSE_38: begin

            // LIR block: if_else_38

            // line 121: u16_n1 = 65535




            next_u16_n1 = 16'd65535;



            next_state = S_IF_END_37;

        end

        S_IF_THEN_39: begin

            // LIR block: if_then_39

            // line 124: f32_6 = div(a=f32_5, b=f32_1)





            div_a = f32_5;

            div_b = f32_1;

            div_start = 1'b1;


            next_state = S_IF_THEN_39_WAIT;

        end

        S_IF_THEN_39_WAIT: begin

            // LIR block: if_then_39

            // line 124: f32_6 = div(a=f32_5, b=f32_1)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_41;
            end else begin
                next_state = S_IF_THEN_39_WAIT;
            end

        end

        S_IF_END_40: begin

            // LIR block: if_end_40

            // line 134: if u8_kind == 2:             if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)






            if ((u8_kind == 32'd2)) begin
                next_state = S_IF_THEN_52;
            end else begin
                next_state = S_IF_END_53;
            end

        end

        S_AFTER_CALL_41: begin

            // LIR block: after_call_41

            // line 125: if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_42;
            end else begin
                next_state = S_IF_END_43;
            end

        end

        S_IF_THEN_42: begin

            // LIR block: if_then_42

            // line 126: accumA(i=u16_n0, j=u16_n0, delta=f32_6)





            accumA_i = u16_n0;

            accumA_j = u16_n0;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_42_WAIT;

        end

        S_IF_THEN_42_WAIT: begin

            // LIR block: if_then_42

            // line 126: accumA(i=u16_n0, j=u16_n0, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_44;
            end else begin
                next_state = S_IF_THEN_42_WAIT;
            end

        end

        S_IF_END_43: begin

            // LIR block: if_end_43

            // line 131: if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_49;
            end else begin
                next_state = S_IF_END_50;
            end

        end

        S_AFTER_CALL_44: begin

            // LIR block: after_call_44

            // line 127: if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_45;
            end else begin
                next_state = S_IF_END_46;
            end

        end

        S_IF_THEN_45: begin

            // LIR block: if_then_45

            // line 128: f32_7 = neg_comb(v=f32_6)




            next_f32_7 = neg_comb(f32_6);


            accumA_i = u16_n0;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_45_WAIT;

        end

        S_IF_THEN_45_WAIT: begin

            // LIR block: if_then_45

            // line 128: f32_7 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_47;
            end else begin
                next_state = S_IF_THEN_45_WAIT;
            end

        end

        S_IF_END_46: begin

            // LIR block: if_end_46

            // line 125: if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            next_state = S_IF_END_43;

        end

        S_AFTER_CALL_47: begin

            // LIR block: after_call_47

            // line 130: accumA(i=u16_n1, j=u16_n0, delta=f32_7)





            accumA_i = u16_n1;

            accumA_j = u16_n0;

            accumA_delta = f32_7;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_47_WAIT;

        end

        S_AFTER_CALL_47_WAIT: begin

            // LIR block: after_call_47

            // line 130: accumA(i=u16_n1, j=u16_n0, delta=f32_7)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_48;
            end else begin
                next_state = S_AFTER_CALL_47_WAIT;
            end

        end

        S_AFTER_CALL_48: begin

            // LIR block: after_call_48

            // line 127: if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            next_state = S_IF_END_46;

        end

        S_IF_THEN_49: begin

            // LIR block: if_then_49

            // line 132: accumA(i=u16_n1, j=u16_n1, delta=f32_6)





            accumA_i = u16_n1;

            accumA_j = u16_n1;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_49_WAIT;

        end

        S_IF_THEN_49_WAIT: begin

            // LIR block: if_then_49

            // line 132: accumA(i=u16_n1, j=u16_n1, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_51;
            end else begin
                next_state = S_IF_THEN_49_WAIT;
            end

        end

        S_IF_END_50: begin

            // LIR block: if_end_50

            // line 123: if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            next_state = S_IF_END_40;

        end

        S_AFTER_CALL_51: begin

            // LIR block: after_call_51

            // line 131: if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            next_state = S_IF_END_50;

        end

        S_IF_THEN_52: begin

            // LIR block: if_then_52

            // line 135: if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_54;
            end else begin
                next_state = S_IF_END_55;
            end

        end

        S_IF_END_53: begin

            // LIR block: if_end_53

            // line 141: if u8_kind == 3:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)             if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_1)






            if ((u8_kind == 32'd3)) begin
                next_state = S_IF_THEN_60;
            end else begin
                next_state = S_IF_END_61;
            end

        end

        S_IF_THEN_54: begin

            // LIR block: if_then_54

            // line 136: f32_6 = neg_comb(v=f32_1)




            next_f32_6 = neg_comb(f32_1);


            accumJ_i = u16_n0;

            accumJ_delta = neg_comb(f32_1);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_54_WAIT;

        end

        S_IF_THEN_54_WAIT: begin

            // LIR block: if_then_54

            // line 136: f32_6 = neg_comb(v=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_56;
            end else begin
                next_state = S_IF_THEN_54_WAIT;
            end

        end

        S_IF_END_55: begin

            // LIR block: if_end_55

            // line 138: if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_57;
            end else begin
                next_state = S_IF_END_58;
            end

        end

        S_AFTER_CALL_56: begin

            // LIR block: after_call_56

            // line 135: if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)






            next_state = S_IF_END_55;

        end

        S_IF_THEN_57: begin

            // LIR block: if_then_57

            // line 139: accumJ(i=u16_n1, delta=f32_1)





            accumJ_i = u16_n1;

            accumJ_delta = f32_1;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_57_WAIT;

        end

        S_IF_THEN_57_WAIT: begin

            // LIR block: if_then_57

            // line 139: accumJ(i=u16_n1, delta=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_59;
            end else begin
                next_state = S_IF_THEN_57_WAIT;
            end

        end

        S_IF_END_58: begin

            // LIR block: if_end_58

            // line 134: if u8_kind == 2:             if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)






            next_state = S_IF_END_53;

        end

        S_AFTER_CALL_59: begin

            // LIR block: after_call_59

            // line 138: if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)






            next_state = S_IF_END_58;

        end

        S_IF_THEN_60: begin

            // LIR block: if_then_60

            // line 142: u16_aux = u16_next_aux




            next_u16_aux = u16_next_aux;

            next_u16_next_aux = (u16_next_aux + 16'd1);



            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_62;
            end else begin
                next_state = S_IF_END_63;
            end

        end

        S_IF_END_61: begin

            // LIR block: if_end_61

            // line 158: if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)             if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)






            if ((u8_kind == 32'd4)) begin
                next_state = S_IF_THEN_71;
            end else begin
                next_state = S_IF_END_72;
            end

        end

        S_IF_THEN_62: begin

            // LIR block: if_then_62

            // line 145: accumA(i=u16_aux, j=u16_n0, delta=f32_5)





            accumA_i = u16_aux;

            accumA_j = u16_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_62_WAIT;

        end

        S_IF_THEN_62_WAIT: begin

            // LIR block: if_then_62

            // line 145: accumA(i=u16_aux, j=u16_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_64;
            end else begin
                next_state = S_IF_THEN_62_WAIT;
            end

        end

        S_IF_END_63: begin

            // LIR block: if_end_63

            // line 148: if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_66;
            end else begin
                next_state = S_IF_END_67;
            end

        end

        S_AFTER_CALL_64: begin

            // LIR block: after_call_64

            // line 146: f32_6 = neg_comb(v=f32_5)




            next_f32_6 = neg_comb(f32_5);


            accumA_i = u16_n0;

            accumA_j = u16_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_64_WAIT;

        end

        S_AFTER_CALL_64_WAIT: begin

            // LIR block: after_call_64

            // line 146: f32_6 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_65;
            end else begin
                next_state = S_AFTER_CALL_64_WAIT;
            end

        end

        S_AFTER_CALL_65: begin

            // LIR block: after_call_65

            // line 144: if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)






            next_state = S_IF_END_63;

        end

        S_IF_THEN_66: begin

            // LIR block: if_then_66

            // line 149: f32_6 = neg_comb(v=f32_5)




            next_f32_6 = neg_comb(f32_5);


            accumA_i = u16_aux;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_66_WAIT;

        end

        S_IF_THEN_66_WAIT: begin

            // LIR block: if_then_66

            // line 149: f32_6 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_68;
            end else begin
                next_state = S_IF_THEN_66_WAIT;
            end

        end

        S_IF_END_67: begin

            // LIR block: if_end_67

            // line 152: accumJ(i=u16_aux, delta=f32_1)





            accumJ_i = u16_aux;

            accumJ_delta = f32_1;

            accumJ_start = 1'b1;


            next_state = S_IF_END_67_WAIT;

        end

        S_IF_END_67_WAIT: begin

            // LIR block: if_end_67

            // line 152: accumJ(i=u16_aux, delta=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_70;
            end else begin
                next_state = S_IF_END_67_WAIT;
            end

        end

        S_AFTER_CALL_68: begin

            // LIR block: after_call_68

            // line 151: accumA(i=u16_n1, j=u16_aux, delta=f32_5)





            accumA_i = u16_n1;

            accumA_j = u16_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_68_WAIT;

        end

        S_AFTER_CALL_68_WAIT: begin

            // LIR block: after_call_68

            // line 151: accumA(i=u16_n1, j=u16_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_69;
            end else begin
                next_state = S_AFTER_CALL_68_WAIT;
            end

        end

        S_AFTER_CALL_69: begin

            // LIR block: after_call_69

            // line 148: if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            next_state = S_IF_END_67;

        end

        S_AFTER_CALL_70: begin

            // LIR block: after_call_70

            // line 141: if u8_kind == 3:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)             if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_1)






            next_state = S_IF_END_61;

        end

        S_IF_THEN_71: begin

            // LIR block: if_then_71

            // line 159: f32_6 = div(a=f32_1, b=par_dt)





            div_a = f32_1;

            div_b = par_dt;

            div_start = 1'b1;


            next_state = S_IF_THEN_71_WAIT;

        end

        S_IF_THEN_71_WAIT: begin

            // LIR block: if_then_71

            // line 159: f32_6 = div(a=f32_1, b=par_dt)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_73;
            end else begin
                next_state = S_IF_THEN_71_WAIT;
            end

        end

        S_IF_END_72: begin

            // LIR block: if_end_72

            // line 183: if u8_kind == 5:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u16_aux)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)             if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u16_aux, j=u16_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u16_aux, delta=f32_2)






            if ((u8_kind == 32'd5)) begin
                next_state = S_IF_THEN_98;
            end else begin
                next_state = S_IF_END_99;
            end

        end

        S_AFTER_CALL_73: begin

            // LIR block: after_call_73

            // line 160: f32_7 = f32_0




            next_f32_7 = f32_0;



            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_74;
            end else begin
                next_state = S_IF_END_75;
            end

        end

        S_IF_THEN_74: begin

            // LIR block: if_then_74

            // line 162: f32_7 = fetch_prevX(i=u16_n0)





            fetch_prevX_i = u16_n0;

            fetch_prevX_start = 1'b1;


            next_state = S_IF_THEN_74_WAIT;

        end

        S_IF_THEN_74_WAIT: begin

            // LIR block: if_then_74

            // line 162: f32_7 = fetch_prevX(i=u16_n0)

            // wait for blocking primitive: fetch_prevX






            if (fetch_prevX_done) begin

                next_f32_7 = fetch_prevX_result;

                next_state = S_AFTER_CALL_76;
            end else begin
                next_state = S_IF_THEN_74_WAIT;
            end

        end

        S_IF_END_75: begin

            // LIR block: if_end_75

            // line 163: if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_77;
            end else begin
                next_state = S_IF_END_78;
            end

        end

        S_AFTER_CALL_76: begin

            // LIR block: after_call_76

            // line 161: if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)






            next_state = S_IF_END_75;

        end

        S_IF_THEN_77: begin

            // LIR block: if_then_77

            // line 164: f32_2 = fetch_prevX(i=u16_n1)





            fetch_prevX_i = u16_n1;

            fetch_prevX_start = 1'b1;


            next_state = S_IF_THEN_77_WAIT;

        end

        S_IF_THEN_77_WAIT: begin

            // LIR block: if_then_77

            // line 164: f32_2 = fetch_prevX(i=u16_n1)

            // wait for blocking primitive: fetch_prevX






            if (fetch_prevX_done) begin

                next_f32_2 = fetch_prevX_result;

                next_state = S_AFTER_CALL_79;
            end else begin
                next_state = S_IF_THEN_77_WAIT;
            end

        end

        S_IF_END_78: begin

            // LIR block: if_end_78

            // line 167: if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_81;
            end else begin
                next_state = S_IF_END_82;
            end

        end

        S_AFTER_CALL_79: begin

            // LIR block: after_call_79

            // line 165: f32_2 = neg_comb(v=f32_2)




            next_f32_2 = neg_comb(f32_2);


            fma_a = f32_5;

            fma_b = neg_comb(f32_2);

            fma_c = f32_7;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_79_WAIT;

        end

        S_AFTER_CALL_79_WAIT: begin

            // LIR block: after_call_79

            // line 165: f32_2 = neg_comb(v=f32_2)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_7 = fma_result;

                next_state = S_AFTER_CALL_80;
            end else begin
                next_state = S_AFTER_CALL_79_WAIT;
            end

        end

        S_AFTER_CALL_80: begin

            // LIR block: after_call_80

            // line 163: if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)






            next_state = S_IF_END_78;

        end

        S_IF_THEN_81: begin

            // LIR block: if_then_81

            // line 168: accumA(i=u16_n0, j=u16_n0, delta=f32_6)





            accumA_i = u16_n0;

            accumA_j = u16_n0;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_81_WAIT;

        end

        S_IF_THEN_81_WAIT: begin

            // LIR block: if_then_81

            // line 168: accumA(i=u16_n0, j=u16_n0, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_83;
            end else begin
                next_state = S_IF_THEN_81_WAIT;
            end

        end

        S_IF_END_82: begin

            // LIR block: if_end_82

            // line 173: if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_88;
            end else begin
                next_state = S_IF_END_89;
            end

        end

        S_AFTER_CALL_83: begin

            // LIR block: after_call_83

            // line 169: if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_84;
            end else begin
                next_state = S_IF_END_85;
            end

        end

        S_IF_THEN_84: begin

            // LIR block: if_then_84

            // line 170: f32_2 = neg_comb(v=f32_6)




            next_f32_2 = neg_comb(f32_6);


            accumA_i = u16_n0;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_84_WAIT;

        end

        S_IF_THEN_84_WAIT: begin

            // LIR block: if_then_84

            // line 170: f32_2 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_86;
            end else begin
                next_state = S_IF_THEN_84_WAIT;
            end

        end

        S_IF_END_85: begin

            // LIR block: if_end_85

            // line 167: if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)






            next_state = S_IF_END_82;

        end

        S_AFTER_CALL_86: begin

            // LIR block: after_call_86

            // line 172: accumA(i=u16_n1, j=u16_n0, delta=f32_2)





            accumA_i = u16_n1;

            accumA_j = u16_n0;

            accumA_delta = f32_2;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_86_WAIT;

        end

        S_AFTER_CALL_86_WAIT: begin

            // LIR block: after_call_86

            // line 172: accumA(i=u16_n1, j=u16_n0, delta=f32_2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_87;
            end else begin
                next_state = S_AFTER_CALL_86_WAIT;
            end

        end

        S_AFTER_CALL_87: begin

            // LIR block: after_call_87

            // line 169: if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)






            next_state = S_IF_END_85;

        end

        S_IF_THEN_88: begin

            // LIR block: if_then_88

            // line 174: accumA(i=u16_n1, j=u16_n1, delta=f32_6)





            accumA_i = u16_n1;

            accumA_j = u16_n1;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_88_WAIT;

        end

        S_IF_THEN_88_WAIT: begin

            // LIR block: if_then_88

            // line 174: accumA(i=u16_n1, j=u16_n1, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_90;
            end else begin
                next_state = S_IF_THEN_88_WAIT;
            end

        end

        S_IF_END_89: begin

            // LIR block: if_end_89

            // line 175: f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)





            fma_a = f32_6;

            fma_b = f32_7;

            fma_c = f32_0;

            fma_start = 1'b1;


            next_state = S_IF_END_89_WAIT;

        end

        S_IF_END_89_WAIT: begin

            // LIR block: if_end_89

            // line 175: f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_2 = fma_result;

                next_state = S_AFTER_CALL_91;
            end else begin
                next_state = S_IF_END_89_WAIT;
            end

        end

        S_AFTER_CALL_90: begin

            // LIR block: after_call_90

            // line 173: if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            next_state = S_IF_END_89;

        end

        S_AFTER_CALL_91: begin

            // LIR block: after_call_91

            // line 176: if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_92;
            end else begin
                next_state = S_IF_END_93;
            end

        end

        S_IF_THEN_92: begin

            // LIR block: if_then_92

            // line 177: accumJ(i=u16_n0, delta=f32_2)





            accumJ_i = u16_n0;

            accumJ_delta = f32_2;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_92_WAIT;

        end

        S_IF_THEN_92_WAIT: begin

            // LIR block: if_then_92

            // line 177: accumJ(i=u16_n0, delta=f32_2)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_94;
            end else begin
                next_state = S_IF_THEN_92_WAIT;
            end

        end

        S_IF_END_93: begin

            // LIR block: if_end_93

            // line 178: if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_95;
            end else begin
                next_state = S_IF_END_96;
            end

        end

        S_AFTER_CALL_94: begin

            // LIR block: after_call_94

            // line 176: if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)






            next_state = S_IF_END_93;

        end

        S_IF_THEN_95: begin

            // LIR block: if_then_95

            // line 179: f32_3 = neg_comb(v=f32_2)




            next_f32_3 = neg_comb(f32_2);


            accumJ_i = u16_n1;

            accumJ_delta = neg_comb(f32_2);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_95_WAIT;

        end

        S_IF_THEN_95_WAIT: begin

            // LIR block: if_then_95

            // line 179: f32_3 = neg_comb(v=f32_2)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_97;
            end else begin
                next_state = S_IF_THEN_95_WAIT;
            end

        end

        S_IF_END_96: begin

            // LIR block: if_end_96

            // line 158: if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)             if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)






            next_state = S_IF_END_72;

        end

        S_AFTER_CALL_97: begin

            // LIR block: after_call_97

            // line 178: if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)






            next_state = S_IF_END_96;

        end

        S_IF_THEN_98: begin

            // LIR block: if_then_98

            // line 184: u16_aux = u16_next_aux




            next_u16_aux = u16_next_aux;

            next_u16_next_aux = (u16_next_aux + 16'd1);


            div_a = f32_1;

            div_b = par_dt;

            div_start = 1'b1;


            next_state = S_IF_THEN_98_WAIT;

        end

        S_IF_THEN_98_WAIT: begin

            // LIR block: if_then_98

            // line 184: u16_aux = u16_next_aux

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_100;
            end else begin
                next_state = S_IF_THEN_98_WAIT;
            end

        end

        S_IF_END_99: begin

            // LIR block: if_end_99

            // line 202: if u8_kind == 6:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)






            if ((u8_kind == 32'd6)) begin
                next_state = S_IF_THEN_113;
            end else begin
                next_state = S_IF_END_114;
            end

        end

        S_AFTER_CALL_100: begin

            // LIR block: after_call_100

            // line 187: f32_7 = fetch_prevX(i=u16_aux)





            fetch_prevX_i = u16_aux;

            fetch_prevX_start = 1'b1;


            next_state = S_AFTER_CALL_100_WAIT;

        end

        S_AFTER_CALL_100_WAIT: begin

            // LIR block: after_call_100

            // line 187: f32_7 = fetch_prevX(i=u16_aux)

            // wait for blocking primitive: fetch_prevX






            if (fetch_prevX_done) begin

                next_f32_7 = fetch_prevX_result;

                next_state = S_AFTER_CALL_101;
            end else begin
                next_state = S_AFTER_CALL_100_WAIT;
            end

        end

        S_AFTER_CALL_101: begin

            // LIR block: after_call_101

            // line 188: if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_102;
            end else begin
                next_state = S_IF_END_103;
            end

        end

        S_IF_THEN_102: begin

            // LIR block: if_then_102

            // line 189: accumA(i=u16_aux, j=u16_n0, delta=f32_5)





            accumA_i = u16_aux;

            accumA_j = u16_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_102_WAIT;

        end

        S_IF_THEN_102_WAIT: begin

            // LIR block: if_then_102

            // line 189: accumA(i=u16_aux, j=u16_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_104;
            end else begin
                next_state = S_IF_THEN_102_WAIT;
            end

        end

        S_IF_END_103: begin

            // LIR block: if_end_103

            // line 192: if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_106;
            end else begin
                next_state = S_IF_END_107;
            end

        end

        S_AFTER_CALL_104: begin

            // LIR block: after_call_104

            // line 190: f32_2 = neg_comb(v=f32_5)




            next_f32_2 = neg_comb(f32_5);


            accumA_i = u16_n0;

            accumA_j = u16_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_104_WAIT;

        end

        S_AFTER_CALL_104_WAIT: begin

            // LIR block: after_call_104

            // line 190: f32_2 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_105;
            end else begin
                next_state = S_AFTER_CALL_104_WAIT;
            end

        end

        S_AFTER_CALL_105: begin

            // LIR block: after_call_105

            // line 188: if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)






            next_state = S_IF_END_103;

        end

        S_IF_THEN_106: begin

            // LIR block: if_then_106

            // line 193: f32_2 = neg_comb(v=f32_5)




            next_f32_2 = neg_comb(f32_5);


            accumA_i = u16_aux;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_106_WAIT;

        end

        S_IF_THEN_106_WAIT: begin

            // LIR block: if_then_106

            // line 193: f32_2 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_108;
            end else begin
                next_state = S_IF_THEN_106_WAIT;
            end

        end

        S_IF_END_107: begin

            // LIR block: if_end_107

            // line 196: f32_2 = neg_comb(v=f32_6)




            next_f32_2 = neg_comb(f32_6);


            accumA_i = u16_aux;

            accumA_j = u16_aux;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_END_107_WAIT;

        end

        S_IF_END_107_WAIT: begin

            // LIR block: if_end_107

            // line 196: f32_2 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_110;
            end else begin
                next_state = S_IF_END_107_WAIT;
            end

        end

        S_AFTER_CALL_108: begin

            // LIR block: after_call_108

            // line 195: accumA(i=u16_n1, j=u16_aux, delta=f32_5)





            accumA_i = u16_n1;

            accumA_j = u16_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_108_WAIT;

        end

        S_AFTER_CALL_108_WAIT: begin

            // LIR block: after_call_108

            // line 195: accumA(i=u16_n1, j=u16_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_109;
            end else begin
                next_state = S_AFTER_CALL_108_WAIT;
            end

        end

        S_AFTER_CALL_109: begin

            // LIR block: after_call_109

            // line 192: if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            next_state = S_IF_END_107;

        end

        S_AFTER_CALL_110: begin

            // LIR block: after_call_110

            // line 198: f32_7 = neg_comb(v=f32_7)




            next_f32_7 = neg_comb(f32_7);


            fma_a = f32_6;

            fma_b = neg_comb(f32_7);

            fma_c = f32_0;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_110_WAIT;

        end

        S_AFTER_CALL_110_WAIT: begin

            // LIR block: after_call_110

            // line 198: f32_7 = neg_comb(v=f32_7)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_2 = fma_result;

                next_state = S_AFTER_CALL_111;
            end else begin
                next_state = S_AFTER_CALL_110_WAIT;
            end

        end

        S_AFTER_CALL_111: begin

            // LIR block: after_call_111

            // line 200: accumJ(i=u16_aux, delta=f32_2)





            accumJ_i = u16_aux;

            accumJ_delta = f32_2;

            accumJ_start = 1'b1;


            next_state = S_AFTER_CALL_111_WAIT;

        end

        S_AFTER_CALL_111_WAIT: begin

            // LIR block: after_call_111

            // line 200: accumJ(i=u16_aux, delta=f32_2)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_112;
            end else begin
                next_state = S_AFTER_CALL_111_WAIT;
            end

        end

        S_AFTER_CALL_112: begin

            // LIR block: after_call_112

            // line 183: if u8_kind == 5:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u16_aux)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)             if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u16_aux, j=u16_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u16_aux, delta=f32_2)






            next_state = S_IF_END_99;

        end

        S_IF_THEN_113: begin

            // LIR block: if_then_113

            // line 203: u16_aux = u16_next_aux




            next_u16_aux = u16_next_aux;

            next_u16_next_aux = (u16_next_aux + 16'd1);


            fma_a = f32_3;

            fma_b = par_time;

            fma_c = f32_4;

            fma_start = 1'b1;


            next_state = S_IF_THEN_113_WAIT;

        end

        S_IF_THEN_113_WAIT: begin

            // LIR block: if_then_113

            // line 203: u16_aux = u16_next_aux

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_115;
            end else begin
                next_state = S_IF_THEN_113_WAIT;
            end

        end

        S_IF_END_114: begin

            // LIR block: if_end_114

            // line 218: if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)






            if ((u8_kind == 32'd7)) begin
                next_state = S_IF_THEN_126;
            end else begin
                next_state = S_IF_END_127;
            end

        end

        S_AFTER_CALL_115: begin

            // LIR block: after_call_115

            // line 206: f32_6 = sin_comb(v=f32_6)




            next_f32_6 = sin_comb(f32_6);


            fma_a = f32_2;

            fma_b = sin_comb(f32_6);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_115_WAIT;

        end

        S_AFTER_CALL_115_WAIT: begin

            // LIR block: after_call_115

            // line 206: f32_6 = sin_comb(v=f32_6)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_116;
            end else begin
                next_state = S_AFTER_CALL_115_WAIT;
            end

        end

        S_AFTER_CALL_116: begin

            // LIR block: after_call_116

            // line 208: if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_117;
            end else begin
                next_state = S_IF_END_118;
            end

        end

        S_IF_THEN_117: begin

            // LIR block: if_then_117

            // line 209: accumA(i=u16_aux, j=u16_n0, delta=f32_5)





            accumA_i = u16_aux;

            accumA_j = u16_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_117_WAIT;

        end

        S_IF_THEN_117_WAIT: begin

            // LIR block: if_then_117

            // line 209: accumA(i=u16_aux, j=u16_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_119;
            end else begin
                next_state = S_IF_THEN_117_WAIT;
            end

        end

        S_IF_END_118: begin

            // LIR block: if_end_118

            // line 212: if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_121;
            end else begin
                next_state = S_IF_END_122;
            end

        end

        S_AFTER_CALL_119: begin

            // LIR block: after_call_119

            // line 210: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u16_n0;

            accumA_j = u16_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_119_WAIT;

        end

        S_AFTER_CALL_119_WAIT: begin

            // LIR block: after_call_119

            // line 210: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_120;
            end else begin
                next_state = S_AFTER_CALL_119_WAIT;
            end

        end

        S_AFTER_CALL_120: begin

            // LIR block: after_call_120

            // line 208: if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)






            next_state = S_IF_END_118;

        end

        S_IF_THEN_121: begin

            // LIR block: if_then_121

            // line 213: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u16_aux;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_121_WAIT;

        end

        S_IF_THEN_121_WAIT: begin

            // LIR block: if_then_121

            // line 213: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_123;
            end else begin
                next_state = S_IF_THEN_121_WAIT;
            end

        end

        S_IF_END_122: begin

            // LIR block: if_end_122

            // line 216: accumJ(i=u16_aux, delta=f32_6)





            accumJ_i = u16_aux;

            accumJ_delta = f32_6;

            accumJ_start = 1'b1;


            next_state = S_IF_END_122_WAIT;

        end

        S_IF_END_122_WAIT: begin

            // LIR block: if_end_122

            // line 216: accumJ(i=u16_aux, delta=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_125;
            end else begin
                next_state = S_IF_END_122_WAIT;
            end

        end

        S_AFTER_CALL_123: begin

            // LIR block: after_call_123

            // line 215: accumA(i=u16_n1, j=u16_aux, delta=f32_5)





            accumA_i = u16_n1;

            accumA_j = u16_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_123_WAIT;

        end

        S_AFTER_CALL_123_WAIT: begin

            // LIR block: after_call_123

            // line 215: accumA(i=u16_n1, j=u16_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_124;
            end else begin
                next_state = S_AFTER_CALL_123_WAIT;
            end

        end

        S_AFTER_CALL_124: begin

            // LIR block: after_call_124

            // line 212: if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            next_state = S_IF_END_122;

        end

        S_AFTER_CALL_125: begin

            // LIR block: after_call_125

            // line 202: if u8_kind == 6:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)






            next_state = S_IF_END_114;

        end

        S_IF_THEN_126: begin

            // LIR block: if_then_126

            // line 219: f32_6 = fma(a=f32_3, b=par_time, c=f32_4)





            fma_a = f32_3;

            fma_b = par_time;

            fma_c = f32_4;

            fma_start = 1'b1;


            next_state = S_IF_THEN_126_WAIT;

        end

        S_IF_THEN_126_WAIT: begin

            // LIR block: if_then_126

            // line 219: f32_6 = fma(a=f32_3, b=par_time, c=f32_4)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_128;
            end else begin
                next_state = S_IF_THEN_126_WAIT;
            end

        end

        S_IF_END_127: begin

            // LIR block: if_end_127

            // line 230: if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            if ((u8_kind == 32'd8)) begin
                next_state = S_IF_THEN_136;
            end else begin
                next_state = S_IF_END_137;
            end

        end

        S_AFTER_CALL_128: begin

            // LIR block: after_call_128

            // line 220: f32_6 = sin_comb(v=f32_6)




            next_f32_6 = sin_comb(f32_6);


            fma_a = f32_2;

            fma_b = sin_comb(f32_6);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_128_WAIT;

        end

        S_AFTER_CALL_128_WAIT: begin

            // LIR block: after_call_128

            // line 220: f32_6 = sin_comb(v=f32_6)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_129;
            end else begin
                next_state = S_AFTER_CALL_128_WAIT;
            end

        end

        S_AFTER_CALL_129: begin

            // LIR block: after_call_129

            // line 222: if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_130;
            end else begin
                next_state = S_IF_END_131;
            end

        end

        S_IF_THEN_130: begin

            // LIR block: if_then_130

            // line 223: f32_7 = neg_comb(v=f32_6)




            next_f32_7 = neg_comb(f32_6);


            accumJ_i = u16_n0;

            accumJ_delta = neg_comb(f32_6);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_130_WAIT;

        end

        S_IF_THEN_130_WAIT: begin

            // LIR block: if_then_130

            // line 223: f32_7 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_132;
            end else begin
                next_state = S_IF_THEN_130_WAIT;
            end

        end

        S_IF_END_131: begin

            // LIR block: if_end_131

            // line 225: if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_133;
            end else begin
                next_state = S_IF_END_134;
            end

        end

        S_AFTER_CALL_132: begin

            // LIR block: after_call_132

            // line 222: if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)






            next_state = S_IF_END_131;

        end

        S_IF_THEN_133: begin

            // LIR block: if_then_133

            // line 226: accumJ(i=u16_n1, delta=f32_6)





            accumJ_i = u16_n1;

            accumJ_delta = f32_6;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_133_WAIT;

        end

        S_IF_THEN_133_WAIT: begin

            // LIR block: if_then_133

            // line 226: accumJ(i=u16_n1, delta=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_135;
            end else begin
                next_state = S_IF_THEN_133_WAIT;
            end

        end

        S_IF_END_134: begin

            // LIR block: if_end_134

            // line 218: if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)






            next_state = S_IF_END_127;

        end

        S_AFTER_CALL_135: begin

            // LIR block: after_call_135

            // line 225: if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)






            next_state = S_IF_END_134;

        end

        S_IF_THEN_136: begin

            // LIR block: if_then_136

            // line 231: u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)




            next_u8_gate = pwm_gate_comb(par_time, f32_3, f32_4);

            next_f32_6 = f32_2;



            if ((pwm_gate_comb(par_time, f32_3, f32_4) != 32'd0)) begin
                next_state = S_IF_THEN_138;
            end else begin
                next_state = S_IF_END_139;
            end

        end

        S_IF_END_137: begin

            // LIR block: if_end_137

            // line 248: if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)






            if ((u8_kind == 32'd9)) begin
                next_state = S_IF_THEN_151;
            end else begin
                next_state = S_IF_END_152;
            end

        end

        S_IF_THEN_138: begin

            // LIR block: if_then_138

            // line 234: f32_6 = f32_1




            next_f32_6 = f32_1;



            next_state = S_IF_END_139;

        end

        S_IF_END_139: begin

            // LIR block: if_end_139

            // line 235: f32_6 = div(a=f32_5, b=f32_6)





            div_a = f32_5;

            div_b = f32_6;

            div_start = 1'b1;


            next_state = S_IF_END_139_WAIT;

        end

        S_IF_END_139_WAIT: begin

            // LIR block: if_end_139

            // line 235: f32_6 = div(a=f32_5, b=f32_6)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_140;
            end else begin
                next_state = S_IF_END_139_WAIT;
            end

        end

        S_AFTER_CALL_140: begin

            // LIR block: after_call_140

            // line 236: if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_141;
            end else begin
                next_state = S_IF_END_142;
            end

        end

        S_IF_THEN_141: begin

            // LIR block: if_then_141

            // line 237: accumA(i=u16_n0, j=u16_n0, delta=f32_6)





            accumA_i = u16_n0;

            accumA_j = u16_n0;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_141_WAIT;

        end

        S_IF_THEN_141_WAIT: begin

            // LIR block: if_then_141

            // line 237: accumA(i=u16_n0, j=u16_n0, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_143;
            end else begin
                next_state = S_IF_THEN_141_WAIT;
            end

        end

        S_IF_END_142: begin

            // LIR block: if_end_142

            // line 242: if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_148;
            end else begin
                next_state = S_IF_END_149;
            end

        end

        S_AFTER_CALL_143: begin

            // LIR block: after_call_143

            // line 238: if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_144;
            end else begin
                next_state = S_IF_END_145;
            end

        end

        S_IF_THEN_144: begin

            // LIR block: if_then_144

            // line 239: f32_7 = neg_comb(v=f32_6)




            next_f32_7 = neg_comb(f32_6);


            accumA_i = u16_n0;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_144_WAIT;

        end

        S_IF_THEN_144_WAIT: begin

            // LIR block: if_then_144

            // line 239: f32_7 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_146;
            end else begin
                next_state = S_IF_THEN_144_WAIT;
            end

        end

        S_IF_END_145: begin

            // LIR block: if_end_145

            // line 236: if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            next_state = S_IF_END_142;

        end

        S_AFTER_CALL_146: begin

            // LIR block: after_call_146

            // line 241: accumA(i=u16_n1, j=u16_n0, delta=f32_7)





            accumA_i = u16_n1;

            accumA_j = u16_n0;

            accumA_delta = f32_7;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_146_WAIT;

        end

        S_AFTER_CALL_146_WAIT: begin

            // LIR block: after_call_146

            // line 241: accumA(i=u16_n1, j=u16_n0, delta=f32_7)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_147;
            end else begin
                next_state = S_AFTER_CALL_146_WAIT;
            end

        end

        S_AFTER_CALL_147: begin

            // LIR block: after_call_147

            // line 238: if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)






            next_state = S_IF_END_145;

        end

        S_IF_THEN_148: begin

            // LIR block: if_then_148

            // line 243: accumA(i=u16_n1, j=u16_n1, delta=f32_6)





            accumA_i = u16_n1;

            accumA_j = u16_n1;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_148_WAIT;

        end

        S_IF_THEN_148_WAIT: begin

            // LIR block: if_then_148

            // line 243: accumA(i=u16_n1, j=u16_n1, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_150;
            end else begin
                next_state = S_IF_THEN_148_WAIT;
            end

        end

        S_IF_END_149: begin

            // LIR block: if_end_149

            // line 230: if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            next_state = S_IF_END_137;

        end

        S_AFTER_CALL_150: begin

            // LIR block: after_call_150

            // line 242: if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)






            next_state = S_IF_END_149;

        end

        S_IF_THEN_151: begin

            // LIR block: if_then_151

            // line 249: u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)




            next_u8_gate = pwm_gate_comb(par_time, f32_3, f32_4);

            next_f32_6 = f32_1;



            if ((pwm_gate_comb(par_time, f32_3, f32_4) != 32'd0)) begin
                next_state = S_IF_THEN_153;
            end else begin
                next_state = S_IF_END_154;
            end

        end

        S_IF_END_152: begin

            // LIR block: if_end_152

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u16_n0 = fetchElemN0(idx=u16_e)         u16_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u16_n0 != 0:             u16_n0 = u16_n0 - 1         else:             u16_n0 = 65535          if u16_n1 != 0:             u16_n1 = u16_n1 - 1         else:             u16_n1 = 65535          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          if u8_kind == 2:             if u16_n0 != 65535:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u16_n0, delta=f32_6)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_1)          if u8_kind == 3:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_6)             if u16_n1 != 65535:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_6)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u16_n0 != 65535:                 f32_7 = fetch_prevX(i=u16_n0)             if u16_n1 != 65535:                 f32_2 = fetch_prevX(i=u16_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_2)                     accumA(i=u16_n1, j=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u16_n0 != 65535:                 accumJ(i=u16_n0, delta=f32_2)             if u16_n1 != 65535:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u16_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u16_aux)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_2)             if u16_n1 != 65535:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_2)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u16_aux, j=u16_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u16_aux, delta=f32_2)          if u8_kind == 6:             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u16_n0 != 65535:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumJ(i=u16_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u16_n0 != 65535:                 accumA(i=u16_n0, j=u16_n0, delta=f32_6)                 if u16_n1 != 65535:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u16_n0, j=u16_n1, delta=f32_7)                     accumA(i=u16_n1, j=u16_n0, delta=f32_7)             if u16_n1 != 65535:                 accumA(i=u16_n1, j=u16_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)




            next___for_idx_3 = (__for_idx_3 + 16'd1);



            next_state = S_FOR_HEADER_23;

        end

        S_IF_THEN_153: begin

            // LIR block: if_then_153

            // line 252: f32_6 = f32_2




            next_f32_6 = f32_2;



            next_state = S_IF_END_154;

        end

        S_IF_END_154: begin

            // LIR block: if_end_154

            // line 253: u16_aux = u16_next_aux




            next_u16_aux = u16_next_aux;

            next_u16_next_aux = (u16_next_aux + 16'd1);



            if ((u16_n0 != 32'd65535)) begin
                next_state = S_IF_THEN_155;
            end else begin
                next_state = S_IF_END_156;
            end

        end

        S_IF_THEN_155: begin

            // LIR block: if_then_155

            // line 256: accumA(i=u16_aux, j=u16_n0, delta=f32_5)





            accumA_i = u16_aux;

            accumA_j = u16_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_155_WAIT;

        end

        S_IF_THEN_155_WAIT: begin

            // LIR block: if_then_155

            // line 256: accumA(i=u16_aux, j=u16_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_157;
            end else begin
                next_state = S_IF_THEN_155_WAIT;
            end

        end

        S_IF_END_156: begin

            // LIR block: if_end_156

            // line 259: if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            if ((u16_n1 != 32'd65535)) begin
                next_state = S_IF_THEN_159;
            end else begin
                next_state = S_IF_END_160;
            end

        end

        S_AFTER_CALL_157: begin

            // LIR block: after_call_157

            // line 257: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u16_n0;

            accumA_j = u16_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_157_WAIT;

        end

        S_AFTER_CALL_157_WAIT: begin

            // LIR block: after_call_157

            // line 257: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_158;
            end else begin
                next_state = S_AFTER_CALL_157_WAIT;
            end

        end

        S_AFTER_CALL_158: begin

            // LIR block: after_call_158

            // line 255: if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)






            next_state = S_IF_END_156;

        end

        S_IF_THEN_159: begin

            // LIR block: if_then_159

            // line 260: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u16_aux;

            accumA_j = u16_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_159_WAIT;

        end

        S_IF_THEN_159_WAIT: begin

            // LIR block: if_then_159

            // line 260: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_161;
            end else begin
                next_state = S_IF_THEN_159_WAIT;
            end

        end

        S_IF_END_160: begin

            // LIR block: if_end_160

            // line 263: accumJ(i=u16_aux, delta=f32_6)





            accumJ_i = u16_aux;

            accumJ_delta = f32_6;

            accumJ_start = 1'b1;


            next_state = S_IF_END_160_WAIT;

        end

        S_IF_END_160_WAIT: begin

            // LIR block: if_end_160

            // line 263: accumJ(i=u16_aux, delta=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_163;
            end else begin
                next_state = S_IF_END_160_WAIT;
            end

        end

        S_AFTER_CALL_161: begin

            // LIR block: after_call_161

            // line 262: accumA(i=u16_n1, j=u16_aux, delta=f32_5)





            accumA_i = u16_n1;

            accumA_j = u16_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_161_WAIT;

        end

        S_AFTER_CALL_161_WAIT: begin

            // LIR block: after_call_161

            // line 262: accumA(i=u16_n1, j=u16_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_162;
            end else begin
                next_state = S_AFTER_CALL_161_WAIT;
            end

        end

        S_AFTER_CALL_162: begin

            // LIR block: after_call_162

            // line 259: if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)






            next_state = S_IF_END_160;

        end

        S_AFTER_CALL_163: begin

            // LIR block: after_call_163

            // line 248: if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u16_aux = u16_next_aux             u16_next_aux = u16_next_aux + 1             if u16_n0 != 65535:                 accumA(i=u16_aux, j=u16_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_n0, j=u16_aux, delta=f32_7)             if u16_n1 != 65535:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u16_aux, j=u16_n1, delta=f32_7)                 accumA(i=u16_n1, j=u16_aux, delta=f32_5)             accumJ(i=u16_aux, delta=f32_6)






            next_state = S_IF_END_152;

        end

        S_FOR_HEADER_164: begin

            // LIR block: for_header_164

            // line 266: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)






            if ((__for_idx_4 < u16_dim)) begin
                next_state = S_FOR_BODY_165;
            end else begin
                next_state = S_FOR_END_166;
            end

        end

        S_FOR_BODY_165: begin

            // LIR block: for_body_165

            // line 266: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next_u16_j = __for_idx_4;

            next_u16_pivot = __for_idx_4;


            fetch_A_i = __for_idx_4;

            fetch_A_j = __for_idx_4;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_165_WAIT;

        end

        S_FOR_BODY_165_WAIT: begin

            // LIR block: for_body_165

            // line 266: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_167;
            end else begin
                next_state = S_FOR_BODY_165_WAIT;
            end

        end

        S_FOR_END_166: begin

            // LIR block: for_end_166

            // line 322: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next___for_idx_11 = 16'd0;



            next_state = S_FOR_HEADER_221;

        end

        S_AFTER_CALL_167: begin

            // LIR block: after_call_167

            // line 269: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next___for_idx_5 = 16'd0;



            next_state = S_FOR_HEADER_168;

        end

        S_FOR_HEADER_168: begin

            // LIR block: for_header_168

            // line 270: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_5 < u16_j)) begin
                next_state = S_FOR_BODY_169;
            end else begin
                next_state = S_FOR_END_170;
            end

        end

        S_FOR_BODY_169: begin

            // LIR block: for_body_169

            // line 270: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_5;


            fetch_LU_i = u16_j;

            fetch_LU_j = __for_idx_5;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_169_WAIT;

        end

        S_FOR_BODY_169_WAIT: begin

            // LIR block: for_body_169

            // line 270: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_171;
            end else begin
                next_state = S_FOR_BODY_169_WAIT;
            end

        end

        S_FOR_END_170: begin

            // LIR block: for_end_170

            // line 274: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_f32_4 = abs_comb(neg_comb(f32_1));

            next_u16_i = (u16_j + 16'd1);



            next_state = S_WHILE_HEADER_174;

        end

        S_AFTER_CALL_171: begin

            // LIR block: after_call_171

            // line 272: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_171_WAIT;

        end

        S_AFTER_CALL_171_WAIT: begin

            // LIR block: after_call_171

            // line 272: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_172;
            end else begin
                next_state = S_AFTER_CALL_171_WAIT;
            end

        end

        S_AFTER_CALL_172: begin

            // LIR block: after_call_172

            // line 273: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_172_WAIT;

        end

        S_AFTER_CALL_172_WAIT: begin

            // LIR block: after_call_172

            // line 273: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_173;
            end else begin
                next_state = S_AFTER_CALL_172_WAIT;
            end

        end

        S_AFTER_CALL_173: begin

            // LIR block: after_call_173

            // line 270: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_5 = (__for_idx_5 + 16'd1);



            next_state = S_FOR_HEADER_168;

        end

        S_WHILE_HEADER_174: begin

            // LIR block: while_header_174

            // line 277: while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1






            if ((u16_i < u16_dim)) begin
                next_state = S_WHILE_BODY_175;
            end else begin
                next_state = S_WHILE_END_176;
            end

        end

        S_WHILE_BODY_175: begin

            // LIR block: while_body_175

            // line 278: f32_1 = fetch_A(i=u16_i, j=u16_j)





            fetch_A_i = u16_i;

            fetch_A_j = u16_j;

            fetch_A_start = 1'b1;


            next_state = S_WHILE_BODY_175_WAIT;

        end

        S_WHILE_BODY_175_WAIT: begin

            // LIR block: while_body_175

            // line 278: f32_1 = fetch_A(i=u16_i, j=u16_j)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_177;
            end else begin
                next_state = S_WHILE_BODY_175_WAIT;
            end

        end

        S_WHILE_END_176: begin

            // LIR block: while_end_176

            // line 291: if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)






            if ((u16_pivot != u16_j)) begin
                next_state = S_IF_THEN_186;
            end else begin
                next_state = S_IF_END_187;
            end

        end

        S_AFTER_CALL_177: begin

            // LIR block: after_call_177

            // line 279: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next___for_idx_6 = 16'd0;



            next_state = S_FOR_HEADER_178;

        end

        S_FOR_HEADER_178: begin

            // LIR block: for_header_178

            // line 280: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_6 < u16_j)) begin
                next_state = S_FOR_BODY_179;
            end else begin
                next_state = S_FOR_END_180;
            end

        end

        S_FOR_BODY_179: begin

            // LIR block: for_body_179

            // line 280: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_6;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_6;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_179_WAIT;

        end

        S_FOR_BODY_179_WAIT: begin

            // LIR block: for_body_179

            // line 280: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_181;
            end else begin
                next_state = S_FOR_BODY_179_WAIT;
            end

        end

        S_FOR_END_180: begin

            // LIR block: for_end_180

            // line 284: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_f32_1 = abs_comb(neg_comb(f32_1));



            if (gt_comb(abs_comb(neg_comb(f32_1)), f32_4)) begin
                next_state = S_IF_THEN_184;
            end else begin
                next_state = S_IF_END_185;
            end

        end

        S_AFTER_CALL_181: begin

            // LIR block: after_call_181

            // line 282: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_181_WAIT;

        end

        S_AFTER_CALL_181_WAIT: begin

            // LIR block: after_call_181

            // line 282: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_182;
            end else begin
                next_state = S_AFTER_CALL_181_WAIT;
            end

        end

        S_AFTER_CALL_182: begin

            // LIR block: after_call_182

            // line 283: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_182_WAIT;

        end

        S_AFTER_CALL_182_WAIT: begin

            // LIR block: after_call_182

            // line 283: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_183;
            end else begin
                next_state = S_AFTER_CALL_182_WAIT;
            end

        end

        S_AFTER_CALL_183: begin

            // LIR block: after_call_183

            // line 280: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_6 = (__for_idx_6 + 16'd1);



            next_state = S_FOR_HEADER_178;

        end

        S_IF_THEN_184: begin

            // LIR block: if_then_184

            // line 287: f32_4 = f32_1




            next_f32_4 = f32_1;

            next_u16_pivot = u16_i;



            next_state = S_IF_END_185;

        end

        S_IF_END_185: begin

            // LIR block: if_end_185

            // line 289: u16_i = u16_i + 1




            next_u16_i = (u16_i + 16'd1);



            next_state = S_WHILE_HEADER_174;

        end

        S_IF_THEN_186: begin

            // LIR block: if_then_186

            // line 292: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_7 = 16'd0;



            next_state = S_FOR_HEADER_188;

        end

        S_IF_END_187: begin

            // LIR block: if_end_187

            // line 307: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_9 = 16'd0;



            next_state = S_FOR_HEADER_206;

        end

        S_FOR_HEADER_188: begin

            // LIR block: for_header_188

            // line 292: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)






            if ((__for_idx_7 < u16_dim)) begin
                next_state = S_FOR_BODY_189;
            end else begin
                next_state = S_FOR_END_190;
            end

        end

        S_FOR_BODY_189: begin

            // LIR block: for_body_189

            // line 292: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next_u16_k = __for_idx_7;


            fetch_A_i = u16_j;

            fetch_A_j = __for_idx_7;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_189_WAIT;

        end

        S_FOR_BODY_189_WAIT: begin

            // LIR block: for_body_189

            // line 292: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_191;
            end else begin
                next_state = S_FOR_BODY_189_WAIT;
            end

        end

        S_FOR_END_190: begin

            // LIR block: for_end_190

            // line 297: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_8 = 16'd0;



            next_state = S_FOR_HEADER_195;

        end

        S_AFTER_CALL_191: begin

            // LIR block: after_call_191

            // line 294: f32_2 = fetch_A(i=u16_pivot, j=u16_k)





            fetch_A_i = u16_pivot;

            fetch_A_j = u16_k;

            fetch_A_start = 1'b1;


            next_state = S_AFTER_CALL_191_WAIT;

        end

        S_AFTER_CALL_191_WAIT: begin

            // LIR block: after_call_191

            // line 294: f32_2 = fetch_A(i=u16_pivot, j=u16_k)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_2 = fetch_A_result;

                next_state = S_AFTER_CALL_192;
            end else begin
                next_state = S_AFTER_CALL_191_WAIT;
            end

        end

        S_AFTER_CALL_192: begin

            // LIR block: after_call_192

            // line 295: store_A(i=u16_j, j=u16_k, v=f32_2)





            store_A_i = u16_j;

            store_A_j = u16_k;

            store_A_v = f32_2;

            store_A_start = 1'b1;


            next_state = S_AFTER_CALL_192_WAIT;

        end

        S_AFTER_CALL_192_WAIT: begin

            // LIR block: after_call_192

            // line 295: store_A(i=u16_j, j=u16_k, v=f32_2)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_193;
            end else begin
                next_state = S_AFTER_CALL_192_WAIT;
            end

        end

        S_AFTER_CALL_193: begin

            // LIR block: after_call_193

            // line 296: store_A(i=u16_pivot, j=u16_k, v=f32_1)





            store_A_i = u16_pivot;

            store_A_j = u16_k;

            store_A_v = f32_1;

            store_A_start = 1'b1;


            next_state = S_AFTER_CALL_193_WAIT;

        end

        S_AFTER_CALL_193_WAIT: begin

            // LIR block: after_call_193

            // line 296: store_A(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_194;
            end else begin
                next_state = S_AFTER_CALL_193_WAIT;
            end

        end

        S_AFTER_CALL_194: begin

            // LIR block: after_call_194

            // line 292: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_7 = (__for_idx_7 + 16'd1);



            next_state = S_FOR_HEADER_188;

        end

        S_FOR_HEADER_195: begin

            // LIR block: for_header_195

            // line 297: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)






            if ((__for_idx_8 < u16_j)) begin
                next_state = S_FOR_BODY_196;
            end else begin
                next_state = S_FOR_END_197;
            end

        end

        S_FOR_BODY_196: begin

            // LIR block: for_body_196

            // line 297: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next_u16_k = __for_idx_8;


            fetch_LU_i = u16_j;

            fetch_LU_j = __for_idx_8;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_196_WAIT;

        end

        S_FOR_BODY_196_WAIT: begin

            // LIR block: for_body_196

            // line 297: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_1 = fetch_LU_result;

                next_state = S_AFTER_CALL_198;
            end else begin
                next_state = S_FOR_BODY_196_WAIT;
            end

        end

        S_FOR_END_197: begin

            // LIR block: for_end_197

            // line 302: f32_1 = fetch_J(i=u16_j)





            fetch_J_i = u16_j;

            fetch_J_start = 1'b1;


            next_state = S_FOR_END_197_WAIT;

        end

        S_FOR_END_197_WAIT: begin

            // LIR block: for_end_197

            // line 302: f32_1 = fetch_J(i=u16_j)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_1 = fetch_J_result;

                next_state = S_AFTER_CALL_202;
            end else begin
                next_state = S_FOR_END_197_WAIT;
            end

        end

        S_AFTER_CALL_198: begin

            // LIR block: after_call_198

            // line 299: f32_2 = fetch_LU(i=u16_pivot, j=u16_k)





            fetch_LU_i = u16_pivot;

            fetch_LU_j = u16_k;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_198_WAIT;

        end

        S_AFTER_CALL_198_WAIT: begin

            // LIR block: after_call_198

            // line 299: f32_2 = fetch_LU(i=u16_pivot, j=u16_k)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_199;
            end else begin
                next_state = S_AFTER_CALL_198_WAIT;
            end

        end

        S_AFTER_CALL_199: begin

            // LIR block: after_call_199

            // line 300: store_LU(i=u16_j, j=u16_k, v=f32_2)





            store_LU_i = u16_j;

            store_LU_j = u16_k;

            store_LU_v = f32_2;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_199_WAIT;

        end

        S_AFTER_CALL_199_WAIT: begin

            // LIR block: after_call_199

            // line 300: store_LU(i=u16_j, j=u16_k, v=f32_2)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_200;
            end else begin
                next_state = S_AFTER_CALL_199_WAIT;
            end

        end

        S_AFTER_CALL_200: begin

            // LIR block: after_call_200

            // line 301: store_LU(i=u16_pivot, j=u16_k, v=f32_1)





            store_LU_i = u16_pivot;

            store_LU_j = u16_k;

            store_LU_v = f32_1;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_200_WAIT;

        end

        S_AFTER_CALL_200_WAIT: begin

            // LIR block: after_call_200

            // line 301: store_LU(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_201;
            end else begin
                next_state = S_AFTER_CALL_200_WAIT;
            end

        end

        S_AFTER_CALL_201: begin

            // LIR block: after_call_201

            // line 297: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_8 = (__for_idx_8 + 16'd1);



            next_state = S_FOR_HEADER_195;

        end

        S_AFTER_CALL_202: begin

            // LIR block: after_call_202

            // line 303: f32_2 = fetch_J(i=u16_pivot)





            fetch_J_i = u16_pivot;

            fetch_J_start = 1'b1;


            next_state = S_AFTER_CALL_202_WAIT;

        end

        S_AFTER_CALL_202_WAIT: begin

            // LIR block: after_call_202

            // line 303: f32_2 = fetch_J(i=u16_pivot)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_2 = fetch_J_result;

                next_state = S_AFTER_CALL_203;
            end else begin
                next_state = S_AFTER_CALL_202_WAIT;
            end

        end

        S_AFTER_CALL_203: begin

            // LIR block: after_call_203

            // line 304: store_J(i=u16_j, v=f32_2)





            store_J_i = u16_j;

            store_J_v = f32_2;

            store_J_start = 1'b1;


            next_state = S_AFTER_CALL_203_WAIT;

        end

        S_AFTER_CALL_203_WAIT: begin

            // LIR block: after_call_203

            // line 304: store_J(i=u16_j, v=f32_2)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_204;
            end else begin
                next_state = S_AFTER_CALL_203_WAIT;
            end

        end

        S_AFTER_CALL_204: begin

            // LIR block: after_call_204

            // line 305: store_J(i=u16_pivot, v=f32_1)





            store_J_i = u16_pivot;

            store_J_v = f32_1;

            store_J_start = 1'b1;


            next_state = S_AFTER_CALL_204_WAIT;

        end

        S_AFTER_CALL_204_WAIT: begin

            // LIR block: after_call_204

            // line 305: store_J(i=u16_pivot, v=f32_1)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_205;
            end else begin
                next_state = S_AFTER_CALL_204_WAIT;
            end

        end

        S_AFTER_CALL_205: begin

            // LIR block: after_call_205

            // line 291: if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)






            next_state = S_IF_END_187;

        end

        S_FOR_HEADER_206: begin

            // LIR block: for_header_206

            // line 307: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)






            if ((__for_idx_9 < u16_dim)) begin
                next_state = S_FOR_BODY_207;
            end else begin
                next_state = S_FOR_END_208;
            end

        end

        S_FOR_BODY_207: begin

            // LIR block: for_body_207

            // line 307: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next_u16_i = __for_idx_9;


            fetch_A_i = __for_idx_9;

            fetch_A_j = u16_j;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_207_WAIT;

        end

        S_FOR_BODY_207_WAIT: begin

            // LIR block: for_body_207

            // line 307: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_209;
            end else begin
                next_state = S_FOR_BODY_207_WAIT;
            end

        end

        S_FOR_END_208: begin

            // LIR block: for_end_208

            // line 266: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_4 = (__for_idx_4 + 16'd1);



            next_state = S_FOR_HEADER_164;

        end

        S_AFTER_CALL_209: begin

            // LIR block: after_call_209

            // line 309: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_u16_m = ((u16_i > u16_j) ? u16_j : u16_i);

            next___for_idx_10 = 16'd0;



            next_state = S_FOR_HEADER_210;

        end

        S_FOR_HEADER_210: begin

            // LIR block: for_header_210

            // line 311: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_10 < u16_m)) begin
                next_state = S_FOR_BODY_211;
            end else begin
                next_state = S_FOR_END_212;
            end

        end

        S_FOR_BODY_211: begin

            // LIR block: for_body_211

            // line 311: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_10;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_10;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_211_WAIT;

        end

        S_FOR_BODY_211_WAIT: begin

            // LIR block: for_body_211

            // line 311: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_213;
            end else begin
                next_state = S_FOR_BODY_211_WAIT;
            end

        end

        S_FOR_END_212: begin

            // LIR block: for_end_212

            // line 315: if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)






            if ((u16_i > u16_j)) begin
                next_state = S_IF_THEN_216;
            end else begin
                next_state = S_IF_END_217;
            end

        end

        S_AFTER_CALL_213: begin

            // LIR block: after_call_213

            // line 313: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_213_WAIT;

        end

        S_AFTER_CALL_213_WAIT: begin

            // LIR block: after_call_213

            // line 313: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_214;
            end else begin
                next_state = S_AFTER_CALL_213_WAIT;
            end

        end

        S_AFTER_CALL_214: begin

            // LIR block: after_call_214

            // line 314: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_214_WAIT;

        end

        S_AFTER_CALL_214_WAIT: begin

            // LIR block: after_call_214

            // line 314: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_215;
            end else begin
                next_state = S_AFTER_CALL_214_WAIT;
            end

        end

        S_AFTER_CALL_215: begin

            // LIR block: after_call_215

            // line 311: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_10 = (__for_idx_10 + 16'd1);



            next_state = S_FOR_HEADER_210;

        end

        S_IF_THEN_216: begin

            // LIR block: if_then_216

            // line 316: f32_2 = fetch_LU(i=u16_j, j=u16_j)





            fetch_LU_i = u16_j;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_IF_THEN_216_WAIT;

        end

        S_IF_THEN_216_WAIT: begin

            // LIR block: if_then_216

            // line 316: f32_2 = fetch_LU(i=u16_j, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_218;
            end else begin
                next_state = S_IF_THEN_216_WAIT;
            end

        end

        S_IF_END_217: begin

            // LIR block: if_end_217

            // line 318: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);


            store_LU_i = u16_i;

            store_LU_j = u16_j;

            store_LU_v = neg_comb(f32_1);

            store_LU_start = 1'b1;


            next_state = S_IF_END_217_WAIT;

        end

        S_IF_END_217_WAIT: begin

            // LIR block: if_end_217

            // line 318: f32_1 = neg_comb(v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_220;
            end else begin
                next_state = S_IF_END_217_WAIT;
            end

        end

        S_AFTER_CALL_218: begin

            // LIR block: after_call_218

            // line 317: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_218_WAIT;

        end

        S_AFTER_CALL_218_WAIT: begin

            // LIR block: after_call_218

            // line 317: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_219;
            end else begin
                next_state = S_AFTER_CALL_218_WAIT;
            end

        end

        S_AFTER_CALL_219: begin

            // LIR block: after_call_219

            // line 315: if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)






            next_state = S_IF_END_217;

        end

        S_AFTER_CALL_220: begin

            // LIR block: after_call_220

            // line 307: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_9 = (__for_idx_9 + 16'd1);



            next_state = S_FOR_HEADER_206;

        end

        S_FOR_HEADER_221: begin

            // LIR block: for_header_221

            // line 322: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)






            if ((__for_idx_11 < u16_dim)) begin
                next_state = S_FOR_BODY_222;
            end else begin
                next_state = S_FOR_END_223;
            end

        end

        S_FOR_BODY_222: begin

            // LIR block: for_body_222

            // line 322: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next_u16_i = __for_idx_11;


            fetch_J_i = __for_idx_11;

            fetch_J_start = 1'b1;


            next_state = S_FOR_BODY_222_WAIT;

        end

        S_FOR_BODY_222_WAIT: begin

            // LIR block: for_body_222

            // line 322: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_1 = fetch_J_result;

                next_state = S_AFTER_CALL_224;
            end else begin
                next_state = S_FOR_BODY_222_WAIT;
            end

        end

        S_FOR_END_223: begin

            // LIR block: for_end_223

            // line 332: u16_i = u16_dim




            next_u16_i = u16_dim;



            next_state = S_WHILE_HEADER_232;

        end

        S_AFTER_CALL_224: begin

            // LIR block: after_call_224

            // line 324: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_12 = 16'd0;



            next_state = S_FOR_HEADER_225;

        end

        S_FOR_HEADER_225: begin

            // LIR block: for_header_225

            // line 324: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_12 < u16_i)) begin
                next_state = S_FOR_BODY_226;
            end else begin
                next_state = S_FOR_END_227;
            end

        end

        S_FOR_BODY_226: begin

            // LIR block: for_body_226

            // line 324: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_12;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_12;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_226_WAIT;

        end

        S_FOR_BODY_226_WAIT: begin

            // LIR block: for_body_226

            // line 324: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_228;
            end else begin
                next_state = S_FOR_BODY_226_WAIT;
            end

        end

        S_FOR_END_227: begin

            // LIR block: for_end_227

            // line 329: store_Y(i=u16_i, v=f32_1)





            store_Y_i = u16_i;

            store_Y_v = f32_1;

            store_Y_start = 1'b1;


            next_state = S_FOR_END_227_WAIT;

        end

        S_FOR_END_227_WAIT: begin

            // LIR block: for_end_227

            // line 329: store_Y(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_Y






            if (store_Y_done) begin

                next_state = S_AFTER_CALL_231;
            end else begin
                next_state = S_FOR_END_227_WAIT;
            end

        end

        S_AFTER_CALL_228: begin

            // LIR block: after_call_228

            // line 326: f32_3 = fetch_Y(i=u16_k)





            fetch_Y_i = u16_k;

            fetch_Y_start = 1'b1;


            next_state = S_AFTER_CALL_228_WAIT;

        end

        S_AFTER_CALL_228_WAIT: begin

            // LIR block: after_call_228

            // line 326: f32_3 = fetch_Y(i=u16_k)

            // wait for blocking primitive: fetch_Y






            if (fetch_Y_done) begin

                next_f32_3 = fetch_Y_result;

                next_state = S_AFTER_CALL_229;
            end else begin
                next_state = S_AFTER_CALL_228_WAIT;
            end

        end

        S_AFTER_CALL_229: begin

            // LIR block: after_call_229

            // line 327: f32_3 = neg_comb(v=f32_3)




            next_f32_3 = neg_comb(f32_3);


            fma_a = f32_2;

            fma_b = neg_comb(f32_3);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_229_WAIT;

        end

        S_AFTER_CALL_229_WAIT: begin

            // LIR block: after_call_229

            // line 327: f32_3 = neg_comb(v=f32_3)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_230;
            end else begin
                next_state = S_AFTER_CALL_229_WAIT;
            end

        end

        S_AFTER_CALL_230: begin

            // LIR block: after_call_230

            // line 324: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_12 = (__for_idx_12 + 16'd1);



            next_state = S_FOR_HEADER_225;

        end

        S_AFTER_CALL_231: begin

            // LIR block: after_call_231

            // line 322: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next___for_idx_11 = (__for_idx_11 + 16'd1);



            next_state = S_FOR_HEADER_221;

        end

        S_WHILE_HEADER_232: begin

            // LIR block: while_header_232

            // line 333: while u16_i > 0:         u16_i = u16_i - 1         f32_1 = fetch_Y(i=u16_i)         u16_k = u16_i + 1         while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1         f32_2 = fetch_LU(i=u16_i, j=u16_i)         f32_1 = div(a=f32_1, b=f32_2)         store_X(i=u16_i, v=f32_1)






            if ((u16_i > 32'd0)) begin
                next_state = S_WHILE_BODY_233;
            end else begin
                next_state = S_WHILE_END_234;
            end

        end

        S_WHILE_BODY_233: begin

            // LIR block: while_body_233

            // line 334: u16_i = u16_i - 1




            next_u16_i = (u16_i - 16'd1);


            fetch_Y_i = (u16_i - 16'd1);

            fetch_Y_start = 1'b1;


            next_state = S_WHILE_BODY_233_WAIT;

        end

        S_WHILE_BODY_233_WAIT: begin

            // LIR block: while_body_233

            // line 334: u16_i = u16_i - 1

            // wait for blocking primitive: fetch_Y






            if (fetch_Y_done) begin

                next_f32_1 = fetch_Y_result;

                next_state = S_AFTER_CALL_235;
            end else begin
                next_state = S_WHILE_BODY_233_WAIT;
            end

        end

        S_WHILE_END_234: begin

            // LIR block: while_end_234

            // line 348: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)




            next___for_idx_13 = 16'd0;



            next_state = S_FOR_HEADER_245;

        end

        S_AFTER_CALL_235: begin

            // LIR block: after_call_235

            // line 336: u16_k = u16_i + 1




            next_u16_k = (u16_i + 16'd1);



            next_state = S_WHILE_HEADER_236;

        end

        S_WHILE_HEADER_236: begin

            // LIR block: while_header_236

            // line 337: while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1






            if ((u16_k < u16_dim)) begin
                next_state = S_WHILE_BODY_237;
            end else begin
                next_state = S_WHILE_END_238;
            end

        end

        S_WHILE_BODY_237: begin

            // LIR block: while_body_237

            // line 338: f32_2 = fetch_LU(i=u16_i, j=u16_k)





            fetch_LU_i = u16_i;

            fetch_LU_j = u16_k;

            fetch_LU_start = 1'b1;


            next_state = S_WHILE_BODY_237_WAIT;

        end

        S_WHILE_BODY_237_WAIT: begin

            // LIR block: while_body_237

            // line 338: f32_2 = fetch_LU(i=u16_i, j=u16_k)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_239;
            end else begin
                next_state = S_WHILE_BODY_237_WAIT;
            end

        end

        S_WHILE_END_238: begin

            // LIR block: while_end_238

            // line 343: f32_2 = fetch_LU(i=u16_i, j=u16_i)





            fetch_LU_i = u16_i;

            fetch_LU_j = u16_i;

            fetch_LU_start = 1'b1;


            next_state = S_WHILE_END_238_WAIT;

        end

        S_WHILE_END_238_WAIT: begin

            // LIR block: while_end_238

            // line 343: f32_2 = fetch_LU(i=u16_i, j=u16_i)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_242;
            end else begin
                next_state = S_WHILE_END_238_WAIT;
            end

        end

        S_AFTER_CALL_239: begin

            // LIR block: after_call_239

            // line 339: f32_3 = fetch_X(i=u16_k)





            fetch_X_i = u16_k;

            fetch_X_start = 1'b1;


            next_state = S_AFTER_CALL_239_WAIT;

        end

        S_AFTER_CALL_239_WAIT: begin

            // LIR block: after_call_239

            // line 339: f32_3 = fetch_X(i=u16_k)

            // wait for blocking primitive: fetch_X






            if (fetch_X_done) begin

                next_f32_3 = fetch_X_result;

                next_state = S_AFTER_CALL_240;
            end else begin
                next_state = S_AFTER_CALL_239_WAIT;
            end

        end

        S_AFTER_CALL_240: begin

            // LIR block: after_call_240

            // line 340: f32_3 = neg_comb(v=f32_3)




            next_f32_3 = neg_comb(f32_3);


            fma_a = f32_2;

            fma_b = neg_comb(f32_3);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_240_WAIT;

        end

        S_AFTER_CALL_240_WAIT: begin

            // LIR block: after_call_240

            // line 340: f32_3 = neg_comb(v=f32_3)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_241;
            end else begin
                next_state = S_AFTER_CALL_240_WAIT;
            end

        end

        S_AFTER_CALL_241: begin

            // LIR block: after_call_241

            // line 342: u16_k = u16_k + 1




            next_u16_k = (u16_k + 16'd1);



            next_state = S_WHILE_HEADER_236;

        end

        S_AFTER_CALL_242: begin

            // LIR block: after_call_242

            // line 344: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_242_WAIT;

        end

        S_AFTER_CALL_242_WAIT: begin

            // LIR block: after_call_242

            // line 344: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_243;
            end else begin
                next_state = S_AFTER_CALL_242_WAIT;
            end

        end

        S_AFTER_CALL_243: begin

            // LIR block: after_call_243

            // line 345: store_X(i=u16_i, v=f32_1)





            store_X_i = u16_i;

            store_X_v = f32_1;

            store_X_start = 1'b1;


            next_state = S_AFTER_CALL_243_WAIT;

        end

        S_AFTER_CALL_243_WAIT: begin

            // LIR block: after_call_243

            // line 345: store_X(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_X






            if (store_X_done) begin

                next_state = S_AFTER_CALL_244;
            end else begin
                next_state = S_AFTER_CALL_243_WAIT;
            end

        end

        S_AFTER_CALL_244: begin

            // LIR block: after_call_244

            // line 333: while u16_i > 0:         u16_i = u16_i - 1         f32_1 = fetch_Y(i=u16_i)         u16_k = u16_i + 1         while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1         f32_2 = fetch_LU(i=u16_i, j=u16_i)         f32_1 = div(a=f32_1, b=f32_2)         store_X(i=u16_i, v=f32_1)






            next_state = S_WHILE_HEADER_232;

        end

        S_FOR_HEADER_245: begin

            // LIR block: for_header_245

            // line 348: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)






            if ((__for_idx_13 < u16_dim)) begin
                next_state = S_FOR_BODY_246;
            end else begin
                next_state = S_FOR_END_247;
            end

        end

        S_FOR_BODY_246: begin

            // LIR block: for_body_246

            // line 348: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)




            next_u16_i = __for_idx_13;


            fetch_X_i = __for_idx_13;

            fetch_X_start = 1'b1;


            next_state = S_FOR_BODY_246_WAIT;

        end

        S_FOR_BODY_246_WAIT: begin

            // LIR block: for_body_246

            // line 348: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)

            // wait for blocking primitive: fetch_X






            if (fetch_X_done) begin

                next_f32_1 = fetch_X_result;

                next_state = S_AFTER_CALL_248;
            end else begin
                next_state = S_FOR_BODY_246_WAIT;
            end

        end

        S_FOR_END_247: begin

            // LIR block: for_end_247







            next_state = S_DONE;

        end

        S_AFTER_CALL_248: begin

            // LIR block: after_call_248

            // line 350: store_prevX(i=u16_i, v=f32_1)





            store_prevX_i = u16_i;

            store_prevX_v = f32_1;

            store_prevX_start = 1'b1;


            next_state = S_AFTER_CALL_248_WAIT;

        end

        S_AFTER_CALL_248_WAIT: begin

            // LIR block: after_call_248

            // line 350: store_prevX(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_prevX






            if (store_prevX_done) begin

                next_state = S_AFTER_CALL_249;
            end else begin
                next_state = S_AFTER_CALL_248_WAIT;
            end

        end

        S_AFTER_CALL_249: begin

            // LIR block: after_call_249

            // line 348: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)




            next___for_idx_13 = (__for_idx_13 + 16'd1);



            next_state = S_FOR_HEADER_245;

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