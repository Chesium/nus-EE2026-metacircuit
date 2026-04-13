
// Generated from LIR for function solve_core_transient

// Entry block: entry

// Blocking primitives: fetchElemKind(latency=1), store_J(latency=1), store_Y(latency=1), store_X(latency=1), store_A(latency=1), store_LU(latency=1), fetchElemN0(latency=1), fetchElemN1(latency=1), fetchElemVal0(latency=1), fetchElemVal1(latency=1), fetchElemVal2(latency=1), fetchElemVal3(latency=1), div(latency=4), accumA(latency=1), accumJ(latency=1), fetch_prevX(latency=1), fma(latency=3), fetch_A(latency=1), fetch_LU(latency=1), fetch_J(latency=1), fetch_Y(latency=1), fetch_X(latency=1), store_prevX(latency=1)

import StampingLegacyCombPkg::*;

module solve_core_transient (

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

    input logic [7:0] fetchElemN0_result,

    output logic fetchElemN1_start,

    output logic [15:0] fetchElemN1_idx,

    input logic fetchElemN1_done,

    input logic [7:0] fetchElemN1_result,

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

    output logic [7:0] accumA_i,

    output logic [7:0] accumA_j,

    output logic [31:0] accumA_delta,

    input logic accumA_done,

    output logic accumJ_start,

    output logic [7:0] accumJ_i,

    output logic [31:0] accumJ_delta,

    input logic accumJ_done,

    output logic fetch_prevX_start,

    output logic [7:0] fetch_prevX_i,

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



import StampingLegacyCombPkg::*;

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

    S_IF_THEN_33_WAIT,

    S_IF_END_34,

    S_AFTER_CALL_35,

    S_IF_THEN_36,

    S_IF_THEN_36_WAIT,

    S_IF_END_37,

    S_AFTER_CALL_38,

    S_IF_THEN_39,

    S_IF_THEN_39_WAIT,

    S_IF_END_40,

    S_AFTER_CALL_41,

    S_AFTER_CALL_41_WAIT,

    S_AFTER_CALL_42,

    S_IF_THEN_43,

    S_IF_THEN_43_WAIT,

    S_IF_END_44,

    S_AFTER_CALL_45,

    S_IF_THEN_46,

    S_IF_END_47,

    S_IF_THEN_48,

    S_IF_THEN_48_WAIT,

    S_IF_END_49,

    S_AFTER_CALL_50,

    S_IF_THEN_51,

    S_IF_THEN_51_WAIT,

    S_IF_END_52,

    S_AFTER_CALL_53,

    S_IF_THEN_54,

    S_IF_END_55,

    S_IF_THEN_56,

    S_IF_THEN_56_WAIT,

    S_IF_END_57,

    S_AFTER_CALL_58,

    S_AFTER_CALL_58_WAIT,

    S_AFTER_CALL_59,

    S_IF_THEN_60,

    S_IF_THEN_60_WAIT,

    S_IF_END_61,

    S_IF_END_61_WAIT,

    S_AFTER_CALL_62,

    S_AFTER_CALL_62_WAIT,

    S_AFTER_CALL_63,

    S_AFTER_CALL_64,

    S_IF_THEN_65,

    S_IF_THEN_65_WAIT,

    S_IF_END_66,

    S_AFTER_CALL_67,

    S_IF_THEN_68,

    S_IF_THEN_68_WAIT,

    S_IF_END_69,

    S_AFTER_CALL_70,

    S_IF_THEN_71,

    S_IF_THEN_71_WAIT,

    S_IF_END_72,

    S_AFTER_CALL_73,

    S_AFTER_CALL_73_WAIT,

    S_AFTER_CALL_74,

    S_IF_THEN_75,

    S_IF_THEN_75_WAIT,

    S_IF_END_76,

    S_AFTER_CALL_77,

    S_IF_THEN_78,

    S_IF_THEN_78_WAIT,

    S_IF_END_79,

    S_AFTER_CALL_80,

    S_AFTER_CALL_80_WAIT,

    S_AFTER_CALL_81,

    S_IF_THEN_82,

    S_IF_THEN_82_WAIT,

    S_IF_END_83,

    S_IF_END_83_WAIT,

    S_AFTER_CALL_84,

    S_AFTER_CALL_85,

    S_IF_THEN_86,

    S_IF_THEN_86_WAIT,

    S_IF_END_87,

    S_AFTER_CALL_88,

    S_IF_THEN_89,

    S_IF_THEN_89_WAIT,

    S_IF_END_90,

    S_AFTER_CALL_91,

    S_IF_THEN_92,

    S_IF_THEN_92_WAIT,

    S_IF_END_93,

    S_AFTER_CALL_94,

    S_AFTER_CALL_94_WAIT,

    S_AFTER_CALL_95,

    S_IF_THEN_96,

    S_IF_THEN_96_WAIT,

    S_IF_END_97,

    S_AFTER_CALL_98,

    S_AFTER_CALL_98_WAIT,

    S_AFTER_CALL_99,

    S_IF_THEN_100,

    S_IF_THEN_100_WAIT,

    S_IF_END_101,

    S_IF_END_101_WAIT,

    S_AFTER_CALL_102,

    S_AFTER_CALL_102_WAIT,

    S_AFTER_CALL_103,

    S_AFTER_CALL_104,

    S_AFTER_CALL_104_WAIT,

    S_AFTER_CALL_105,

    S_AFTER_CALL_105_WAIT,

    S_AFTER_CALL_106,

    S_IF_THEN_107,

    S_IF_THEN_107_WAIT,

    S_IF_END_108,

    S_AFTER_CALL_109,

    S_AFTER_CALL_109_WAIT,

    S_AFTER_CALL_110,

    S_IF_THEN_111,

    S_IF_THEN_111_WAIT,

    S_IF_END_112,

    S_AFTER_CALL_113,

    S_AFTER_CALL_113_WAIT,

    S_AFTER_CALL_114,

    S_IF_THEN_115,

    S_IF_THEN_115_WAIT,

    S_IF_END_116,

    S_IF_END_116_WAIT,

    S_AFTER_CALL_117,

    S_AFTER_CALL_117_WAIT,

    S_AFTER_CALL_118,

    S_AFTER_CALL_119,

    S_IF_THEN_120,

    S_IF_THEN_120_WAIT,

    S_IF_END_121,

    S_AFTER_CALL_122,

    S_AFTER_CALL_122_WAIT,

    S_AFTER_CALL_123,

    S_IF_THEN_124,

    S_IF_THEN_124_WAIT,

    S_IF_END_125,

    S_AFTER_CALL_126,

    S_IF_THEN_127,

    S_IF_THEN_127_WAIT,

    S_IF_END_128,

    S_AFTER_CALL_129,

    S_IF_THEN_130,

    S_IF_END_131,

    S_IF_THEN_132,

    S_IF_END_133,

    S_IF_END_133_WAIT,

    S_AFTER_CALL_134,

    S_IF_THEN_135,

    S_IF_THEN_135_WAIT,

    S_IF_END_136,

    S_AFTER_CALL_137,

    S_IF_THEN_138,

    S_IF_THEN_138_WAIT,

    S_IF_END_139,

    S_AFTER_CALL_140,

    S_AFTER_CALL_140_WAIT,

    S_AFTER_CALL_141,

    S_IF_THEN_142,

    S_IF_THEN_142_WAIT,

    S_IF_END_143,

    S_AFTER_CALL_144,

    S_IF_THEN_145,

    S_IF_END_146,

    S_IF_THEN_147,

    S_IF_END_148,

    S_IF_THEN_149,

    S_IF_THEN_149_WAIT,

    S_IF_END_150,

    S_AFTER_CALL_151,

    S_AFTER_CALL_151_WAIT,

    S_AFTER_CALL_152,

    S_IF_THEN_153,

    S_IF_THEN_153_WAIT,

    S_IF_END_154,

    S_IF_END_154_WAIT,

    S_AFTER_CALL_155,

    S_AFTER_CALL_155_WAIT,

    S_AFTER_CALL_156,

    S_AFTER_CALL_157,

    S_FOR_HEADER_158,

    S_FOR_BODY_159,

    S_FOR_BODY_159_WAIT,

    S_FOR_END_160,

    S_AFTER_CALL_161,

    S_FOR_HEADER_162,

    S_FOR_BODY_163,

    S_FOR_BODY_163_WAIT,

    S_FOR_END_164,

    S_AFTER_CALL_165,

    S_AFTER_CALL_165_WAIT,

    S_AFTER_CALL_166,

    S_AFTER_CALL_166_WAIT,

    S_AFTER_CALL_167,

    S_WHILE_HEADER_168,

    S_WHILE_BODY_169,

    S_WHILE_BODY_169_WAIT,

    S_WHILE_END_170,

    S_AFTER_CALL_171,

    S_FOR_HEADER_172,

    S_FOR_BODY_173,

    S_FOR_BODY_173_WAIT,

    S_FOR_END_174,

    S_AFTER_CALL_175,

    S_AFTER_CALL_175_WAIT,

    S_AFTER_CALL_176,

    S_AFTER_CALL_176_WAIT,

    S_AFTER_CALL_177,

    S_IF_THEN_178,

    S_IF_END_179,

    S_IF_THEN_180,

    S_IF_END_181,

    S_FOR_HEADER_182,

    S_FOR_BODY_183,

    S_FOR_BODY_183_WAIT,

    S_FOR_END_184,

    S_AFTER_CALL_185,

    S_AFTER_CALL_185_WAIT,

    S_AFTER_CALL_186,

    S_AFTER_CALL_186_WAIT,

    S_AFTER_CALL_187,

    S_AFTER_CALL_187_WAIT,

    S_AFTER_CALL_188,

    S_FOR_HEADER_189,

    S_FOR_BODY_190,

    S_FOR_BODY_190_WAIT,

    S_FOR_END_191,

    S_FOR_END_191_WAIT,

    S_AFTER_CALL_192,

    S_AFTER_CALL_192_WAIT,

    S_AFTER_CALL_193,

    S_AFTER_CALL_193_WAIT,

    S_AFTER_CALL_194,

    S_AFTER_CALL_194_WAIT,

    S_AFTER_CALL_195,

    S_AFTER_CALL_196,

    S_AFTER_CALL_196_WAIT,

    S_AFTER_CALL_197,

    S_AFTER_CALL_197_WAIT,

    S_AFTER_CALL_198,

    S_AFTER_CALL_198_WAIT,

    S_AFTER_CALL_199,

    S_FOR_HEADER_200,

    S_FOR_BODY_201,

    S_FOR_BODY_201_WAIT,

    S_FOR_END_202,

    S_AFTER_CALL_203,

    S_FOR_HEADER_204,

    S_FOR_BODY_205,

    S_FOR_BODY_205_WAIT,

    S_FOR_END_206,

    S_AFTER_CALL_207,

    S_AFTER_CALL_207_WAIT,

    S_AFTER_CALL_208,

    S_AFTER_CALL_208_WAIT,

    S_AFTER_CALL_209,

    S_IF_THEN_210,

    S_IF_THEN_210_WAIT,

    S_IF_END_211,

    S_IF_END_211_WAIT,

    S_AFTER_CALL_212,

    S_AFTER_CALL_212_WAIT,

    S_AFTER_CALL_213,

    S_AFTER_CALL_214,

    S_FOR_HEADER_215,

    S_FOR_BODY_216,

    S_FOR_BODY_216_WAIT,

    S_FOR_END_217,

    S_AFTER_CALL_218,

    S_FOR_HEADER_219,

    S_FOR_BODY_220,

    S_FOR_BODY_220_WAIT,

    S_FOR_END_221,

    S_FOR_END_221_WAIT,

    S_AFTER_CALL_222,

    S_AFTER_CALL_222_WAIT,

    S_AFTER_CALL_223,

    S_AFTER_CALL_223_WAIT,

    S_AFTER_CALL_224,

    S_AFTER_CALL_225,

    S_WHILE_HEADER_226,

    S_WHILE_BODY_227,

    S_WHILE_BODY_227_WAIT,

    S_WHILE_END_228,

    S_AFTER_CALL_229,

    S_WHILE_HEADER_230,

    S_WHILE_BODY_231,

    S_WHILE_BODY_231_WAIT,

    S_WHILE_END_232,

    S_WHILE_END_232_WAIT,

    S_AFTER_CALL_233,

    S_AFTER_CALL_233_WAIT,

    S_AFTER_CALL_234,

    S_AFTER_CALL_234_WAIT,

    S_AFTER_CALL_235,

    S_AFTER_CALL_236,

    S_AFTER_CALL_236_WAIT,

    S_AFTER_CALL_237,

    S_AFTER_CALL_237_WAIT,

    S_AFTER_CALL_238,

    S_FOR_HEADER_239,

    S_FOR_BODY_240,

    S_FOR_BODY_240_WAIT,

    S_FOR_END_241,

    S_AFTER_CALL_242,

    S_AFTER_CALL_242_WAIT,

    S_AFTER_CALL_243,

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

            // line 103: u8_next_aux = par_node_n




            next_u8_next_aux = par_node_n;

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

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          if u8_kind == 2:             if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)             if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)             if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u8_aux)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u8_aux, j=u8_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u8_aux, delta=f32_2)          if u8_kind == 6:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)






            if ((__for_idx_3 < par_elem_n)) begin
                next_state = S_FOR_BODY_24;
            end else begin
                next_state = S_FOR_END_25;
            end

        end

        S_FOR_BODY_24: begin

            // LIR block: for_body_24

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          if u8_kind == 2:             if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)             if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)             if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u8_aux)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u8_aux, j=u8_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u8_aux, delta=f32_2)          if u8_kind == 6:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)




            next_u16_e = __for_idx_3;


            fetchElemKind_idx = __for_idx_3;

            fetchElemKind_start = 1'b1;


            next_state = S_FOR_BODY_24_WAIT;

        end

        S_FOR_BODY_24_WAIT: begin

            // LIR block: for_body_24

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          if u8_kind == 2:             if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)             if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)             if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u8_aux)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u8_aux, j=u8_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u8_aux, delta=f32_2)          if u8_kind == 6:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)

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

            // line 256: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_4 = 16'd0;



            next_state = S_FOR_HEADER_158;

        end

        S_AFTER_CALL_26: begin

            // LIR block: after_call_26

            // line 106: u8_n0 = fetchElemN0(idx=u16_e)





            fetchElemN0_idx = u16_e;

            fetchElemN0_start = 1'b1;


            next_state = S_AFTER_CALL_26_WAIT;

        end

        S_AFTER_CALL_26_WAIT: begin

            // LIR block: after_call_26

            // line 106: u8_n0 = fetchElemN0(idx=u16_e)

            // wait for blocking primitive: fetchElemN0






            if (fetchElemN0_done) begin

                next_u8_n0 = fetchElemN0_result;

                next_state = S_AFTER_CALL_27;
            end else begin
                next_state = S_AFTER_CALL_26_WAIT;
            end

        end

        S_AFTER_CALL_27: begin

            // LIR block: after_call_27

            // line 107: u8_n1 = fetchElemN1(idx=u16_e)





            fetchElemN1_idx = u16_e;

            fetchElemN1_start = 1'b1;


            next_state = S_AFTER_CALL_27_WAIT;

        end

        S_AFTER_CALL_27_WAIT: begin

            // LIR block: after_call_27

            // line 107: u8_n1 = fetchElemN1(idx=u16_e)

            // wait for blocking primitive: fetchElemN1






            if (fetchElemN1_done) begin

                next_u8_n1 = fetchElemN1_result;

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

            // line 113: if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            if ((u8_kind == 32'd1)) begin
                next_state = S_IF_THEN_33;
            end else begin
                next_state = S_IF_END_34;
            end

        end

        S_IF_THEN_33: begin

            // LIR block: if_then_33

            // line 114: f32_6 = div(a=f32_5, b=f32_1)





            div_a = f32_5;

            div_b = f32_1;

            div_start = 1'b1;


            next_state = S_IF_THEN_33_WAIT;

        end

        S_IF_THEN_33_WAIT: begin

            // LIR block: if_then_33

            // line 114: f32_6 = div(a=f32_5, b=f32_1)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_35;
            end else begin
                next_state = S_IF_THEN_33_WAIT;
            end

        end

        S_IF_END_34: begin

            // LIR block: if_end_34

            // line 124: if u8_kind == 2:             if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            if ((u8_kind == 32'd2)) begin
                next_state = S_IF_THEN_46;
            end else begin
                next_state = S_IF_END_47;
            end

        end

        S_AFTER_CALL_35: begin

            // LIR block: after_call_35

            // line 115: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_36;
            end else begin
                next_state = S_IF_END_37;
            end

        end

        S_IF_THEN_36: begin

            // LIR block: if_then_36

            // line 116: accumA(i=u8_n0, j=u8_n0, delta=f32_6)





            accumA_i = u8_n0;

            accumA_j = u8_n0;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_36_WAIT;

        end

        S_IF_THEN_36_WAIT: begin

            // LIR block: if_then_36

            // line 116: accumA(i=u8_n0, j=u8_n0, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_38;
            end else begin
                next_state = S_IF_THEN_36_WAIT;
            end

        end

        S_IF_END_37: begin

            // LIR block: if_end_37

            // line 121: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_43;
            end else begin
                next_state = S_IF_END_44;
            end

        end

        S_AFTER_CALL_38: begin

            // LIR block: after_call_38

            // line 117: if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_39;
            end else begin
                next_state = S_IF_END_40;
            end

        end

        S_IF_THEN_39: begin

            // LIR block: if_then_39

            // line 118: f32_7 = neg_comb(v=f32_6)




            next_f32_7 = neg_comb(f32_6);


            accumA_i = u8_n0;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_39_WAIT;

        end

        S_IF_THEN_39_WAIT: begin

            // LIR block: if_then_39

            // line 118: f32_7 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_41;
            end else begin
                next_state = S_IF_THEN_39_WAIT;
            end

        end

        S_IF_END_40: begin

            // LIR block: if_end_40

            // line 115: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            next_state = S_IF_END_37;

        end

        S_AFTER_CALL_41: begin

            // LIR block: after_call_41

            // line 120: accumA(i=u8_n1, j=u8_n0, delta=f32_7)





            accumA_i = u8_n1;

            accumA_j = u8_n0;

            accumA_delta = f32_7;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_41_WAIT;

        end

        S_AFTER_CALL_41_WAIT: begin

            // LIR block: after_call_41

            // line 120: accumA(i=u8_n1, j=u8_n0, delta=f32_7)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_42;
            end else begin
                next_state = S_AFTER_CALL_41_WAIT;
            end

        end

        S_AFTER_CALL_42: begin

            // LIR block: after_call_42

            // line 117: if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            next_state = S_IF_END_40;

        end

        S_IF_THEN_43: begin

            // LIR block: if_then_43

            // line 122: accumA(i=u8_n1, j=u8_n1, delta=f32_6)





            accumA_i = u8_n1;

            accumA_j = u8_n1;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_43_WAIT;

        end

        S_IF_THEN_43_WAIT: begin

            // LIR block: if_then_43

            // line 122: accumA(i=u8_n1, j=u8_n1, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_45;
            end else begin
                next_state = S_IF_THEN_43_WAIT;
            end

        end

        S_IF_END_44: begin

            // LIR block: if_end_44

            // line 113: if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            next_state = S_IF_END_34;

        end

        S_AFTER_CALL_45: begin

            // LIR block: after_call_45

            // line 121: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            next_state = S_IF_END_44;

        end

        S_IF_THEN_46: begin

            // LIR block: if_then_46

            // line 125: if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_48;
            end else begin
                next_state = S_IF_END_49;
            end

        end

        S_IF_END_47: begin

            // LIR block: if_end_47

            // line 131: if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)             if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)






            if ((u8_kind == 32'd3)) begin
                next_state = S_IF_THEN_54;
            end else begin
                next_state = S_IF_END_55;
            end

        end

        S_IF_THEN_48: begin

            // LIR block: if_then_48

            // line 126: f32_6 = neg_comb(v=f32_1)




            next_f32_6 = neg_comb(f32_1);


            accumJ_i = u8_n0;

            accumJ_delta = neg_comb(f32_1);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_48_WAIT;

        end

        S_IF_THEN_48_WAIT: begin

            // LIR block: if_then_48

            // line 126: f32_6 = neg_comb(v=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_50;
            end else begin
                next_state = S_IF_THEN_48_WAIT;
            end

        end

        S_IF_END_49: begin

            // LIR block: if_end_49

            // line 128: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_51;
            end else begin
                next_state = S_IF_END_52;
            end

        end

        S_AFTER_CALL_50: begin

            // LIR block: after_call_50

            // line 125: if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)






            next_state = S_IF_END_49;

        end

        S_IF_THEN_51: begin

            // LIR block: if_then_51

            // line 129: accumJ(i=u8_n1, delta=f32_1)





            accumJ_i = u8_n1;

            accumJ_delta = f32_1;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_51_WAIT;

        end

        S_IF_THEN_51_WAIT: begin

            // LIR block: if_then_51

            // line 129: accumJ(i=u8_n1, delta=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_53;
            end else begin
                next_state = S_IF_THEN_51_WAIT;
            end

        end

        S_IF_END_52: begin

            // LIR block: if_end_52

            // line 124: if u8_kind == 2:             if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            next_state = S_IF_END_47;

        end

        S_AFTER_CALL_53: begin

            // LIR block: after_call_53

            // line 128: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)






            next_state = S_IF_END_52;

        end

        S_IF_THEN_54: begin

            // LIR block: if_then_54

            // line 132: u8_aux = u8_next_aux




            next_u8_aux = u8_next_aux;

            next_u8_next_aux = (u8_next_aux + 8'd1);



            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_56;
            end else begin
                next_state = S_IF_END_57;
            end

        end

        S_IF_END_55: begin

            // LIR block: if_end_55

            // line 148: if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)             if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)






            if ((u8_kind == 32'd4)) begin
                next_state = S_IF_THEN_65;
            end else begin
                next_state = S_IF_END_66;
            end

        end

        S_IF_THEN_56: begin

            // LIR block: if_then_56

            // line 135: accumA(i=u8_aux, j=u8_n0, delta=f32_5)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_56_WAIT;

        end

        S_IF_THEN_56_WAIT: begin

            // LIR block: if_then_56

            // line 135: accumA(i=u8_aux, j=u8_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_58;
            end else begin
                next_state = S_IF_THEN_56_WAIT;
            end

        end

        S_IF_END_57: begin

            // LIR block: if_end_57

            // line 138: if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_60;
            end else begin
                next_state = S_IF_END_61;
            end

        end

        S_AFTER_CALL_58: begin

            // LIR block: after_call_58

            // line 136: f32_6 = neg_comb(v=f32_5)




            next_f32_6 = neg_comb(f32_5);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_58_WAIT;

        end

        S_AFTER_CALL_58_WAIT: begin

            // LIR block: after_call_58

            // line 136: f32_6 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_59;
            end else begin
                next_state = S_AFTER_CALL_58_WAIT;
            end

        end

        S_AFTER_CALL_59: begin

            // LIR block: after_call_59

            // line 134: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)






            next_state = S_IF_END_57;

        end

        S_IF_THEN_60: begin

            // LIR block: if_then_60

            // line 139: f32_6 = neg_comb(v=f32_5)




            next_f32_6 = neg_comb(f32_5);


            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_60_WAIT;

        end

        S_IF_THEN_60_WAIT: begin

            // LIR block: if_then_60

            // line 139: f32_6 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_62;
            end else begin
                next_state = S_IF_THEN_60_WAIT;
            end

        end

        S_IF_END_61: begin

            // LIR block: if_end_61

            // line 142: accumJ(i=u8_aux, delta=f32_1)





            accumJ_i = u8_aux;

            accumJ_delta = f32_1;

            accumJ_start = 1'b1;


            next_state = S_IF_END_61_WAIT;

        end

        S_IF_END_61_WAIT: begin

            // LIR block: if_end_61

            // line 142: accumJ(i=u8_aux, delta=f32_1)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_64;
            end else begin
                next_state = S_IF_END_61_WAIT;
            end

        end

        S_AFTER_CALL_62: begin

            // LIR block: after_call_62

            // line 141: accumA(i=u8_n1, j=u8_aux, delta=f32_5)





            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_62_WAIT;

        end

        S_AFTER_CALL_62_WAIT: begin

            // LIR block: after_call_62

            // line 141: accumA(i=u8_n1, j=u8_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_63;
            end else begin
                next_state = S_AFTER_CALL_62_WAIT;
            end

        end

        S_AFTER_CALL_63: begin

            // LIR block: after_call_63

            // line 138: if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            next_state = S_IF_END_61;

        end

        S_AFTER_CALL_64: begin

            // LIR block: after_call_64

            // line 131: if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)             if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)






            next_state = S_IF_END_55;

        end

        S_IF_THEN_65: begin

            // LIR block: if_then_65

            // line 149: f32_6 = div(a=f32_1, b=par_dt)





            div_a = f32_1;

            div_b = par_dt;

            div_start = 1'b1;


            next_state = S_IF_THEN_65_WAIT;

        end

        S_IF_THEN_65_WAIT: begin

            // LIR block: if_then_65

            // line 149: f32_6 = div(a=f32_1, b=par_dt)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_67;
            end else begin
                next_state = S_IF_THEN_65_WAIT;
            end

        end

        S_IF_END_66: begin

            // LIR block: if_end_66

            // line 173: if u8_kind == 5:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u8_aux)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u8_aux, j=u8_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u8_aux, delta=f32_2)






            if ((u8_kind == 32'd5)) begin
                next_state = S_IF_THEN_92;
            end else begin
                next_state = S_IF_END_93;
            end

        end

        S_AFTER_CALL_67: begin

            // LIR block: after_call_67

            // line 150: f32_7 = f32_0




            next_f32_7 = f32_0;



            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_68;
            end else begin
                next_state = S_IF_END_69;
            end

        end

        S_IF_THEN_68: begin

            // LIR block: if_then_68

            // line 152: f32_7 = fetch_prevX(i=u8_n0)





            fetch_prevX_i = u8_n0;

            fetch_prevX_start = 1'b1;


            next_state = S_IF_THEN_68_WAIT;

        end

        S_IF_THEN_68_WAIT: begin

            // LIR block: if_then_68

            // line 152: f32_7 = fetch_prevX(i=u8_n0)

            // wait for blocking primitive: fetch_prevX






            if (fetch_prevX_done) begin

                next_f32_7 = fetch_prevX_result;

                next_state = S_AFTER_CALL_70;
            end else begin
                next_state = S_IF_THEN_68_WAIT;
            end

        end

        S_IF_END_69: begin

            // LIR block: if_end_69

            // line 153: if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_71;
            end else begin
                next_state = S_IF_END_72;
            end

        end

        S_AFTER_CALL_70: begin

            // LIR block: after_call_70

            // line 151: if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)






            next_state = S_IF_END_69;

        end

        S_IF_THEN_71: begin

            // LIR block: if_then_71

            // line 154: f32_2 = fetch_prevX(i=u8_n1)





            fetch_prevX_i = u8_n1;

            fetch_prevX_start = 1'b1;


            next_state = S_IF_THEN_71_WAIT;

        end

        S_IF_THEN_71_WAIT: begin

            // LIR block: if_then_71

            // line 154: f32_2 = fetch_prevX(i=u8_n1)

            // wait for blocking primitive: fetch_prevX






            if (fetch_prevX_done) begin

                next_f32_2 = fetch_prevX_result;

                next_state = S_AFTER_CALL_73;
            end else begin
                next_state = S_IF_THEN_71_WAIT;
            end

        end

        S_IF_END_72: begin

            // LIR block: if_end_72

            // line 157: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_75;
            end else begin
                next_state = S_IF_END_76;
            end

        end

        S_AFTER_CALL_73: begin

            // LIR block: after_call_73

            // line 155: f32_2 = neg_comb(v=f32_2)




            next_f32_2 = neg_comb(f32_2);


            fma_a = f32_5;

            fma_b = neg_comb(f32_2);

            fma_c = f32_7;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_73_WAIT;

        end

        S_AFTER_CALL_73_WAIT: begin

            // LIR block: after_call_73

            // line 155: f32_2 = neg_comb(v=f32_2)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_7 = fma_result;

                next_state = S_AFTER_CALL_74;
            end else begin
                next_state = S_AFTER_CALL_73_WAIT;
            end

        end

        S_AFTER_CALL_74: begin

            // LIR block: after_call_74

            // line 153: if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)






            next_state = S_IF_END_72;

        end

        S_IF_THEN_75: begin

            // LIR block: if_then_75

            // line 158: accumA(i=u8_n0, j=u8_n0, delta=f32_6)





            accumA_i = u8_n0;

            accumA_j = u8_n0;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_75_WAIT;

        end

        S_IF_THEN_75_WAIT: begin

            // LIR block: if_then_75

            // line 158: accumA(i=u8_n0, j=u8_n0, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_77;
            end else begin
                next_state = S_IF_THEN_75_WAIT;
            end

        end

        S_IF_END_76: begin

            // LIR block: if_end_76

            // line 163: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_82;
            end else begin
                next_state = S_IF_END_83;
            end

        end

        S_AFTER_CALL_77: begin

            // LIR block: after_call_77

            // line 159: if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_78;
            end else begin
                next_state = S_IF_END_79;
            end

        end

        S_IF_THEN_78: begin

            // LIR block: if_then_78

            // line 160: f32_2 = neg_comb(v=f32_6)




            next_f32_2 = neg_comb(f32_6);


            accumA_i = u8_n0;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_78_WAIT;

        end

        S_IF_THEN_78_WAIT: begin

            // LIR block: if_then_78

            // line 160: f32_2 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_80;
            end else begin
                next_state = S_IF_THEN_78_WAIT;
            end

        end

        S_IF_END_79: begin

            // LIR block: if_end_79

            // line 157: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)






            next_state = S_IF_END_76;

        end

        S_AFTER_CALL_80: begin

            // LIR block: after_call_80

            // line 162: accumA(i=u8_n1, j=u8_n0, delta=f32_2)





            accumA_i = u8_n1;

            accumA_j = u8_n0;

            accumA_delta = f32_2;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_80_WAIT;

        end

        S_AFTER_CALL_80_WAIT: begin

            // LIR block: after_call_80

            // line 162: accumA(i=u8_n1, j=u8_n0, delta=f32_2)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_81;
            end else begin
                next_state = S_AFTER_CALL_80_WAIT;
            end

        end

        S_AFTER_CALL_81: begin

            // LIR block: after_call_81

            // line 159: if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)






            next_state = S_IF_END_79;

        end

        S_IF_THEN_82: begin

            // LIR block: if_then_82

            // line 164: accumA(i=u8_n1, j=u8_n1, delta=f32_6)





            accumA_i = u8_n1;

            accumA_j = u8_n1;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_82_WAIT;

        end

        S_IF_THEN_82_WAIT: begin

            // LIR block: if_then_82

            // line 164: accumA(i=u8_n1, j=u8_n1, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_84;
            end else begin
                next_state = S_IF_THEN_82_WAIT;
            end

        end

        S_IF_END_83: begin

            // LIR block: if_end_83

            // line 165: f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)





            fma_a = f32_6;

            fma_b = f32_7;

            fma_c = f32_0;

            fma_start = 1'b1;


            next_state = S_IF_END_83_WAIT;

        end

        S_IF_END_83_WAIT: begin

            // LIR block: if_end_83

            // line 165: f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_2 = fma_result;

                next_state = S_AFTER_CALL_85;
            end else begin
                next_state = S_IF_END_83_WAIT;
            end

        end

        S_AFTER_CALL_84: begin

            // LIR block: after_call_84

            // line 163: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            next_state = S_IF_END_83;

        end

        S_AFTER_CALL_85: begin

            // LIR block: after_call_85

            // line 166: if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_86;
            end else begin
                next_state = S_IF_END_87;
            end

        end

        S_IF_THEN_86: begin

            // LIR block: if_then_86

            // line 167: accumJ(i=u8_n0, delta=f32_2)





            accumJ_i = u8_n0;

            accumJ_delta = f32_2;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_86_WAIT;

        end

        S_IF_THEN_86_WAIT: begin

            // LIR block: if_then_86

            // line 167: accumJ(i=u8_n0, delta=f32_2)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_88;
            end else begin
                next_state = S_IF_THEN_86_WAIT;
            end

        end

        S_IF_END_87: begin

            // LIR block: if_end_87

            // line 168: if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_89;
            end else begin
                next_state = S_IF_END_90;
            end

        end

        S_AFTER_CALL_88: begin

            // LIR block: after_call_88

            // line 166: if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)






            next_state = S_IF_END_87;

        end

        S_IF_THEN_89: begin

            // LIR block: if_then_89

            // line 169: f32_3 = neg_comb(v=f32_2)




            next_f32_3 = neg_comb(f32_2);


            accumJ_i = u8_n1;

            accumJ_delta = neg_comb(f32_2);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_89_WAIT;

        end

        S_IF_THEN_89_WAIT: begin

            // LIR block: if_then_89

            // line 169: f32_3 = neg_comb(v=f32_2)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_91;
            end else begin
                next_state = S_IF_THEN_89_WAIT;
            end

        end

        S_IF_END_90: begin

            // LIR block: if_end_90

            // line 148: if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)             if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)






            next_state = S_IF_END_66;

        end

        S_AFTER_CALL_91: begin

            // LIR block: after_call_91

            // line 168: if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)






            next_state = S_IF_END_90;

        end

        S_IF_THEN_92: begin

            // LIR block: if_then_92

            // line 174: u8_aux = u8_next_aux




            next_u8_aux = u8_next_aux;

            next_u8_next_aux = (u8_next_aux + 8'd1);


            div_a = f32_1;

            div_b = par_dt;

            div_start = 1'b1;


            next_state = S_IF_THEN_92_WAIT;

        end

        S_IF_THEN_92_WAIT: begin

            // LIR block: if_then_92

            // line 174: u8_aux = u8_next_aux

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_94;
            end else begin
                next_state = S_IF_THEN_92_WAIT;
            end

        end

        S_IF_END_93: begin

            // LIR block: if_end_93

            // line 192: if u8_kind == 6:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)






            if ((u8_kind == 32'd6)) begin
                next_state = S_IF_THEN_107;
            end else begin
                next_state = S_IF_END_108;
            end

        end

        S_AFTER_CALL_94: begin

            // LIR block: after_call_94

            // line 177: f32_7 = fetch_prevX(i=u8_aux)





            fetch_prevX_i = u8_aux;

            fetch_prevX_start = 1'b1;


            next_state = S_AFTER_CALL_94_WAIT;

        end

        S_AFTER_CALL_94_WAIT: begin

            // LIR block: after_call_94

            // line 177: f32_7 = fetch_prevX(i=u8_aux)

            // wait for blocking primitive: fetch_prevX






            if (fetch_prevX_done) begin

                next_f32_7 = fetch_prevX_result;

                next_state = S_AFTER_CALL_95;
            end else begin
                next_state = S_AFTER_CALL_94_WAIT;
            end

        end

        S_AFTER_CALL_95: begin

            // LIR block: after_call_95

            // line 178: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_96;
            end else begin
                next_state = S_IF_END_97;
            end

        end

        S_IF_THEN_96: begin

            // LIR block: if_then_96

            // line 179: accumA(i=u8_aux, j=u8_n0, delta=f32_5)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_96_WAIT;

        end

        S_IF_THEN_96_WAIT: begin

            // LIR block: if_then_96

            // line 179: accumA(i=u8_aux, j=u8_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_98;
            end else begin
                next_state = S_IF_THEN_96_WAIT;
            end

        end

        S_IF_END_97: begin

            // LIR block: if_end_97

            // line 182: if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_100;
            end else begin
                next_state = S_IF_END_101;
            end

        end

        S_AFTER_CALL_98: begin

            // LIR block: after_call_98

            // line 180: f32_2 = neg_comb(v=f32_5)




            next_f32_2 = neg_comb(f32_5);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_98_WAIT;

        end

        S_AFTER_CALL_98_WAIT: begin

            // LIR block: after_call_98

            // line 180: f32_2 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_99;
            end else begin
                next_state = S_AFTER_CALL_98_WAIT;
            end

        end

        S_AFTER_CALL_99: begin

            // LIR block: after_call_99

            // line 178: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)






            next_state = S_IF_END_97;

        end

        S_IF_THEN_100: begin

            // LIR block: if_then_100

            // line 183: f32_2 = neg_comb(v=f32_5)




            next_f32_2 = neg_comb(f32_5);


            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_100_WAIT;

        end

        S_IF_THEN_100_WAIT: begin

            // LIR block: if_then_100

            // line 183: f32_2 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_102;
            end else begin
                next_state = S_IF_THEN_100_WAIT;
            end

        end

        S_IF_END_101: begin

            // LIR block: if_end_101

            // line 186: f32_2 = neg_comb(v=f32_6)




            next_f32_2 = neg_comb(f32_6);


            accumA_i = u8_aux;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_END_101_WAIT;

        end

        S_IF_END_101_WAIT: begin

            // LIR block: if_end_101

            // line 186: f32_2 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_104;
            end else begin
                next_state = S_IF_END_101_WAIT;
            end

        end

        S_AFTER_CALL_102: begin

            // LIR block: after_call_102

            // line 185: accumA(i=u8_n1, j=u8_aux, delta=f32_5)





            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_102_WAIT;

        end

        S_AFTER_CALL_102_WAIT: begin

            // LIR block: after_call_102

            // line 185: accumA(i=u8_n1, j=u8_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_103;
            end else begin
                next_state = S_AFTER_CALL_102_WAIT;
            end

        end

        S_AFTER_CALL_103: begin

            // LIR block: after_call_103

            // line 182: if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            next_state = S_IF_END_101;

        end

        S_AFTER_CALL_104: begin

            // LIR block: after_call_104

            // line 188: f32_7 = neg_comb(v=f32_7)




            next_f32_7 = neg_comb(f32_7);


            fma_a = f32_6;

            fma_b = neg_comb(f32_7);

            fma_c = f32_0;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_104_WAIT;

        end

        S_AFTER_CALL_104_WAIT: begin

            // LIR block: after_call_104

            // line 188: f32_7 = neg_comb(v=f32_7)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_2 = fma_result;

                next_state = S_AFTER_CALL_105;
            end else begin
                next_state = S_AFTER_CALL_104_WAIT;
            end

        end

        S_AFTER_CALL_105: begin

            // LIR block: after_call_105

            // line 190: accumJ(i=u8_aux, delta=f32_2)





            accumJ_i = u8_aux;

            accumJ_delta = f32_2;

            accumJ_start = 1'b1;


            next_state = S_AFTER_CALL_105_WAIT;

        end

        S_AFTER_CALL_105_WAIT: begin

            // LIR block: after_call_105

            // line 190: accumJ(i=u8_aux, delta=f32_2)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_106;
            end else begin
                next_state = S_AFTER_CALL_105_WAIT;
            end

        end

        S_AFTER_CALL_106: begin

            // LIR block: after_call_106

            // line 173: if u8_kind == 5:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u8_aux)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u8_aux, j=u8_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u8_aux, delta=f32_2)






            next_state = S_IF_END_93;

        end

        S_IF_THEN_107: begin

            // LIR block: if_then_107

            // line 193: u8_aux = u8_next_aux




            next_u8_aux = u8_next_aux;

            next_u8_next_aux = (u8_next_aux + 8'd1);


            fma_a = f32_3;

            fma_b = par_time;

            fma_c = f32_4;

            fma_start = 1'b1;


            next_state = S_IF_THEN_107_WAIT;

        end

        S_IF_THEN_107_WAIT: begin

            // LIR block: if_then_107

            // line 193: u8_aux = u8_next_aux

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_109;
            end else begin
                next_state = S_IF_THEN_107_WAIT;
            end

        end

        S_IF_END_108: begin

            // LIR block: if_end_108

            // line 208: if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)






            if ((u8_kind == 32'd7)) begin
                next_state = S_IF_THEN_120;
            end else begin
                next_state = S_IF_END_121;
            end

        end

        S_AFTER_CALL_109: begin

            // LIR block: after_call_109

            // line 196: f32_6 = sin_comb(v=f32_6)




            next_f32_6 = sin_comb(f32_6);


            fma_a = f32_2;

            fma_b = sin_comb(f32_6);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_109_WAIT;

        end

        S_AFTER_CALL_109_WAIT: begin

            // LIR block: after_call_109

            // line 196: f32_6 = sin_comb(v=f32_6)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_110;
            end else begin
                next_state = S_AFTER_CALL_109_WAIT;
            end

        end

        S_AFTER_CALL_110: begin

            // LIR block: after_call_110

            // line 198: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_111;
            end else begin
                next_state = S_IF_END_112;
            end

        end

        S_IF_THEN_111: begin

            // LIR block: if_then_111

            // line 199: accumA(i=u8_aux, j=u8_n0, delta=f32_5)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_111_WAIT;

        end

        S_IF_THEN_111_WAIT: begin

            // LIR block: if_then_111

            // line 199: accumA(i=u8_aux, j=u8_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_113;
            end else begin
                next_state = S_IF_THEN_111_WAIT;
            end

        end

        S_IF_END_112: begin

            // LIR block: if_end_112

            // line 202: if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_115;
            end else begin
                next_state = S_IF_END_116;
            end

        end

        S_AFTER_CALL_113: begin

            // LIR block: after_call_113

            // line 200: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_113_WAIT;

        end

        S_AFTER_CALL_113_WAIT: begin

            // LIR block: after_call_113

            // line 200: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_114;
            end else begin
                next_state = S_AFTER_CALL_113_WAIT;
            end

        end

        S_AFTER_CALL_114: begin

            // LIR block: after_call_114

            // line 198: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)






            next_state = S_IF_END_112;

        end

        S_IF_THEN_115: begin

            // LIR block: if_then_115

            // line 203: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_115_WAIT;

        end

        S_IF_THEN_115_WAIT: begin

            // LIR block: if_then_115

            // line 203: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_117;
            end else begin
                next_state = S_IF_THEN_115_WAIT;
            end

        end

        S_IF_END_116: begin

            // LIR block: if_end_116

            // line 206: accumJ(i=u8_aux, delta=f32_6)





            accumJ_i = u8_aux;

            accumJ_delta = f32_6;

            accumJ_start = 1'b1;


            next_state = S_IF_END_116_WAIT;

        end

        S_IF_END_116_WAIT: begin

            // LIR block: if_end_116

            // line 206: accumJ(i=u8_aux, delta=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_119;
            end else begin
                next_state = S_IF_END_116_WAIT;
            end

        end

        S_AFTER_CALL_117: begin

            // LIR block: after_call_117

            // line 205: accumA(i=u8_n1, j=u8_aux, delta=f32_5)





            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_117_WAIT;

        end

        S_AFTER_CALL_117_WAIT: begin

            // LIR block: after_call_117

            // line 205: accumA(i=u8_n1, j=u8_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_118;
            end else begin
                next_state = S_AFTER_CALL_117_WAIT;
            end

        end

        S_AFTER_CALL_118: begin

            // LIR block: after_call_118

            // line 202: if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            next_state = S_IF_END_116;

        end

        S_AFTER_CALL_119: begin

            // LIR block: after_call_119

            // line 192: if u8_kind == 6:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)






            next_state = S_IF_END_108;

        end

        S_IF_THEN_120: begin

            // LIR block: if_then_120

            // line 209: f32_6 = fma(a=f32_3, b=par_time, c=f32_4)





            fma_a = f32_3;

            fma_b = par_time;

            fma_c = f32_4;

            fma_start = 1'b1;


            next_state = S_IF_THEN_120_WAIT;

        end

        S_IF_THEN_120_WAIT: begin

            // LIR block: if_then_120

            // line 209: f32_6 = fma(a=f32_3, b=par_time, c=f32_4)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_122;
            end else begin
                next_state = S_IF_THEN_120_WAIT;
            end

        end

        S_IF_END_121: begin

            // LIR block: if_end_121

            // line 220: if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            if ((u8_kind == 32'd8)) begin
                next_state = S_IF_THEN_130;
            end else begin
                next_state = S_IF_END_131;
            end

        end

        S_AFTER_CALL_122: begin

            // LIR block: after_call_122

            // line 210: f32_6 = sin_comb(v=f32_6)




            next_f32_6 = sin_comb(f32_6);


            fma_a = f32_2;

            fma_b = sin_comb(f32_6);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_122_WAIT;

        end

        S_AFTER_CALL_122_WAIT: begin

            // LIR block: after_call_122

            // line 210: f32_6 = sin_comb(v=f32_6)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_6 = fma_result;

                next_state = S_AFTER_CALL_123;
            end else begin
                next_state = S_AFTER_CALL_122_WAIT;
            end

        end

        S_AFTER_CALL_123: begin

            // LIR block: after_call_123

            // line 212: if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_124;
            end else begin
                next_state = S_IF_END_125;
            end

        end

        S_IF_THEN_124: begin

            // LIR block: if_then_124

            // line 213: f32_7 = neg_comb(v=f32_6)




            next_f32_7 = neg_comb(f32_6);


            accumJ_i = u8_n0;

            accumJ_delta = neg_comb(f32_6);

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_124_WAIT;

        end

        S_IF_THEN_124_WAIT: begin

            // LIR block: if_then_124

            // line 213: f32_7 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_126;
            end else begin
                next_state = S_IF_THEN_124_WAIT;
            end

        end

        S_IF_END_125: begin

            // LIR block: if_end_125

            // line 215: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_127;
            end else begin
                next_state = S_IF_END_128;
            end

        end

        S_AFTER_CALL_126: begin

            // LIR block: after_call_126

            // line 212: if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)






            next_state = S_IF_END_125;

        end

        S_IF_THEN_127: begin

            // LIR block: if_then_127

            // line 216: accumJ(i=u8_n1, delta=f32_6)





            accumJ_i = u8_n1;

            accumJ_delta = f32_6;

            accumJ_start = 1'b1;


            next_state = S_IF_THEN_127_WAIT;

        end

        S_IF_THEN_127_WAIT: begin

            // LIR block: if_then_127

            // line 216: accumJ(i=u8_n1, delta=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_129;
            end else begin
                next_state = S_IF_THEN_127_WAIT;
            end

        end

        S_IF_END_128: begin

            // LIR block: if_end_128

            // line 208: if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)






            next_state = S_IF_END_121;

        end

        S_AFTER_CALL_129: begin

            // LIR block: after_call_129

            // line 215: if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)






            next_state = S_IF_END_128;

        end

        S_IF_THEN_130: begin

            // LIR block: if_then_130

            // line 221: u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)




            next_u8_gate = pwm_gate_comb(par_time, f32_3, f32_4);

            next_f32_6 = f32_2;



            if ((pwm_gate_comb(par_time, f32_3, f32_4) != 32'd0)) begin
                next_state = S_IF_THEN_132;
            end else begin
                next_state = S_IF_END_133;
            end

        end

        S_IF_END_131: begin

            // LIR block: if_end_131

            // line 238: if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)






            if ((u8_kind == 32'd9)) begin
                next_state = S_IF_THEN_145;
            end else begin
                next_state = S_IF_END_146;
            end

        end

        S_IF_THEN_132: begin

            // LIR block: if_then_132

            // line 224: f32_6 = f32_1




            next_f32_6 = f32_1;



            next_state = S_IF_END_133;

        end

        S_IF_END_133: begin

            // LIR block: if_end_133

            // line 225: f32_6 = div(a=f32_5, b=f32_6)





            div_a = f32_5;

            div_b = f32_6;

            div_start = 1'b1;


            next_state = S_IF_END_133_WAIT;

        end

        S_IF_END_133_WAIT: begin

            // LIR block: if_end_133

            // line 225: f32_6 = div(a=f32_5, b=f32_6)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_6 = div_result;

                next_state = S_AFTER_CALL_134;
            end else begin
                next_state = S_IF_END_133_WAIT;
            end

        end

        S_AFTER_CALL_134: begin

            // LIR block: after_call_134

            // line 226: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_135;
            end else begin
                next_state = S_IF_END_136;
            end

        end

        S_IF_THEN_135: begin

            // LIR block: if_then_135

            // line 227: accumA(i=u8_n0, j=u8_n0, delta=f32_6)





            accumA_i = u8_n0;

            accumA_j = u8_n0;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_135_WAIT;

        end

        S_IF_THEN_135_WAIT: begin

            // LIR block: if_then_135

            // line 227: accumA(i=u8_n0, j=u8_n0, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_137;
            end else begin
                next_state = S_IF_THEN_135_WAIT;
            end

        end

        S_IF_END_136: begin

            // LIR block: if_end_136

            // line 232: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_142;
            end else begin
                next_state = S_IF_END_143;
            end

        end

        S_AFTER_CALL_137: begin

            // LIR block: after_call_137

            // line 228: if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_138;
            end else begin
                next_state = S_IF_END_139;
            end

        end

        S_IF_THEN_138: begin

            // LIR block: if_then_138

            // line 229: f32_7 = neg_comb(v=f32_6)




            next_f32_7 = neg_comb(f32_6);


            accumA_i = u8_n0;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_6);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_138_WAIT;

        end

        S_IF_THEN_138_WAIT: begin

            // LIR block: if_then_138

            // line 229: f32_7 = neg_comb(v=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_140;
            end else begin
                next_state = S_IF_THEN_138_WAIT;
            end

        end

        S_IF_END_139: begin

            // LIR block: if_end_139

            // line 226: if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            next_state = S_IF_END_136;

        end

        S_AFTER_CALL_140: begin

            // LIR block: after_call_140

            // line 231: accumA(i=u8_n1, j=u8_n0, delta=f32_7)





            accumA_i = u8_n1;

            accumA_j = u8_n0;

            accumA_delta = f32_7;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_140_WAIT;

        end

        S_AFTER_CALL_140_WAIT: begin

            // LIR block: after_call_140

            // line 231: accumA(i=u8_n1, j=u8_n0, delta=f32_7)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_141;
            end else begin
                next_state = S_AFTER_CALL_140_WAIT;
            end

        end

        S_AFTER_CALL_141: begin

            // LIR block: after_call_141

            // line 228: if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)






            next_state = S_IF_END_139;

        end

        S_IF_THEN_142: begin

            // LIR block: if_then_142

            // line 233: accumA(i=u8_n1, j=u8_n1, delta=f32_6)





            accumA_i = u8_n1;

            accumA_j = u8_n1;

            accumA_delta = f32_6;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_142_WAIT;

        end

        S_IF_THEN_142_WAIT: begin

            // LIR block: if_then_142

            // line 233: accumA(i=u8_n1, j=u8_n1, delta=f32_6)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_144;
            end else begin
                next_state = S_IF_THEN_142_WAIT;
            end

        end

        S_IF_END_143: begin

            // LIR block: if_end_143

            // line 220: if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            next_state = S_IF_END_131;

        end

        S_AFTER_CALL_144: begin

            // LIR block: after_call_144

            // line 232: if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)






            next_state = S_IF_END_143;

        end

        S_IF_THEN_145: begin

            // LIR block: if_then_145

            // line 239: u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)




            next_u8_gate = pwm_gate_comb(par_time, f32_3, f32_4);

            next_f32_6 = f32_1;



            if ((pwm_gate_comb(par_time, f32_3, f32_4) != 32'd0)) begin
                next_state = S_IF_THEN_147;
            end else begin
                next_state = S_IF_END_148;
            end

        end

        S_IF_END_146: begin

            // LIR block: if_end_146

            // line 104: for u16_e in range(par_elem_n):         u8_kind = fetchElemKind(idx=u16_e)         u8_n0 = fetchElemN0(idx=u16_e)         u8_n1 = fetchElemN1(idx=u16_e)         f32_1 = fetchElemVal0(idx=u16_e)         f32_2 = fetchElemVal1(idx=u16_e)         f32_3 = fetchElemVal2(idx=u16_e)         f32_4 = fetchElemVal3(idx=u16_e)          if u8_kind == 1:             f32_6 = div(a=f32_5, b=f32_1)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          if u8_kind == 2:             if u8_n0 != 255:                 f32_6 = neg_comb(v=f32_1)                 accumJ(i=u8_n0, delta=f32_6)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_1)          if u8_kind == 3:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_6)             if u8_n1 != 255:                 f32_6 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_6)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_1)          # Capacitor backward-Euler companion:         #   g = C / dt         #   i_hist = g * v_prev         # which becomes a resistor-like stamp plus an equivalent RHS term.         if u8_kind == 4:             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = f32_0             if u8_n0 != 255:                 f32_7 = fetch_prevX(i=u8_n0)             if u8_n1 != 255:                 f32_2 = fetch_prevX(i=u8_n1)                 f32_2 = neg_comb(v=f32_2)                 f32_7 = fma(a=f32_5, b=f32_2, c=f32_7)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_2 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_2)                     accumA(i=u8_n1, j=u8_n0, delta=f32_2)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             if u8_n0 != 255:                 accumJ(i=u8_n0, delta=f32_2)             if u8_n1 != 255:                 f32_3 = neg_comb(v=f32_2)                 accumJ(i=u8_n1, delta=f32_3)          # Inductor backward-Euler companion with a branch-current unknown.         if u8_kind == 5:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = div(a=f32_1, b=par_dt)             f32_7 = fetch_prevX(i=u8_aux)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_2)             if u8_n1 != 255:                 f32_2 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_2)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             f32_2 = neg_comb(v=f32_6)             accumA(i=u8_aux, j=u8_aux, delta=f32_2)             f32_7 = neg_comb(v=f32_7)             f32_2 = fma(a=f32_6, b=f32_7, c=f32_0)             accumJ(i=u8_aux, delta=f32_2)          if u8_kind == 6:             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)          if u8_kind == 7:             f32_6 = fma(a=f32_3, b=par_time, c=f32_4)             f32_6 = sin_comb(v=f32_6)             f32_6 = fma(a=f32_2, b=f32_6, c=f32_1)             if u8_n0 != 255:                 f32_7 = neg_comb(v=f32_6)                 accumJ(i=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumJ(i=u8_n1, delta=f32_6)          # PWM-gated ideal switch. This is stamped as a resistor whose value         # toggles between ron and roff according to the current PWM phase.         if u8_kind == 8:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_2             if u8_gate != 0:                 f32_6 = f32_1             f32_6 = div(a=f32_5, b=f32_6)             if u8_n0 != 255:                 accumA(i=u8_n0, j=u8_n0, delta=f32_6)                 if u8_n1 != 255:                     f32_7 = neg_comb(v=f32_6)                     accumA(i=u8_n0, j=u8_n1, delta=f32_7)                     accumA(i=u8_n1, j=u8_n0, delta=f32_7)             if u8_n1 != 255:                 accumA(i=u8_n1, j=u8_n1, delta=f32_6)          # PWM square-wave voltage source. The branch-variable structure matches         # the ordinary V / VSIN source, but the source value is piecewise         # constant over each PWM period.         if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)




            next___for_idx_3 = (__for_idx_3 + 16'd1);



            next_state = S_FOR_HEADER_23;

        end

        S_IF_THEN_147: begin

            // LIR block: if_then_147

            // line 242: f32_6 = f32_2




            next_f32_6 = f32_2;



            next_state = S_IF_END_148;

        end

        S_IF_END_148: begin

            // LIR block: if_end_148

            // line 243: u8_aux = u8_next_aux




            next_u8_aux = u8_next_aux;

            next_u8_next_aux = (u8_next_aux + 8'd1);



            if ((u8_n0 != 32'd255)) begin
                next_state = S_IF_THEN_149;
            end else begin
                next_state = S_IF_END_150;
            end

        end

        S_IF_THEN_149: begin

            // LIR block: if_then_149

            // line 246: accumA(i=u8_aux, j=u8_n0, delta=f32_5)





            accumA_i = u8_aux;

            accumA_j = u8_n0;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_IF_THEN_149_WAIT;

        end

        S_IF_THEN_149_WAIT: begin

            // LIR block: if_then_149

            // line 246: accumA(i=u8_aux, j=u8_n0, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_151;
            end else begin
                next_state = S_IF_THEN_149_WAIT;
            end

        end

        S_IF_END_150: begin

            // LIR block: if_end_150

            // line 249: if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            if ((u8_n1 != 32'd255)) begin
                next_state = S_IF_THEN_153;
            end else begin
                next_state = S_IF_END_154;
            end

        end

        S_AFTER_CALL_151: begin

            // LIR block: after_call_151

            // line 247: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u8_n0;

            accumA_j = u8_aux;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_151_WAIT;

        end

        S_AFTER_CALL_151_WAIT: begin

            // LIR block: after_call_151

            // line 247: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_152;
            end else begin
                next_state = S_AFTER_CALL_151_WAIT;
            end

        end

        S_AFTER_CALL_152: begin

            // LIR block: after_call_152

            // line 245: if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)






            next_state = S_IF_END_150;

        end

        S_IF_THEN_153: begin

            // LIR block: if_then_153

            // line 250: f32_7 = neg_comb(v=f32_5)




            next_f32_7 = neg_comb(f32_5);


            accumA_i = u8_aux;

            accumA_j = u8_n1;

            accumA_delta = neg_comb(f32_5);

            accumA_start = 1'b1;


            next_state = S_IF_THEN_153_WAIT;

        end

        S_IF_THEN_153_WAIT: begin

            // LIR block: if_then_153

            // line 250: f32_7 = neg_comb(v=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_155;
            end else begin
                next_state = S_IF_THEN_153_WAIT;
            end

        end

        S_IF_END_154: begin

            // LIR block: if_end_154

            // line 253: accumJ(i=u8_aux, delta=f32_6)





            accumJ_i = u8_aux;

            accumJ_delta = f32_6;

            accumJ_start = 1'b1;


            next_state = S_IF_END_154_WAIT;

        end

        S_IF_END_154_WAIT: begin

            // LIR block: if_end_154

            // line 253: accumJ(i=u8_aux, delta=f32_6)

            // wait for blocking primitive: accumJ






            if (accumJ_done) begin

                next_state = S_AFTER_CALL_157;
            end else begin
                next_state = S_IF_END_154_WAIT;
            end

        end

        S_AFTER_CALL_155: begin

            // LIR block: after_call_155

            // line 252: accumA(i=u8_n1, j=u8_aux, delta=f32_5)





            accumA_i = u8_n1;

            accumA_j = u8_aux;

            accumA_delta = f32_5;

            accumA_start = 1'b1;


            next_state = S_AFTER_CALL_155_WAIT;

        end

        S_AFTER_CALL_155_WAIT: begin

            // LIR block: after_call_155

            // line 252: accumA(i=u8_n1, j=u8_aux, delta=f32_5)

            // wait for blocking primitive: accumA






            if (accumA_done) begin

                next_state = S_AFTER_CALL_156;
            end else begin
                next_state = S_AFTER_CALL_155_WAIT;
            end

        end

        S_AFTER_CALL_156: begin

            // LIR block: after_call_156

            // line 249: if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)






            next_state = S_IF_END_154;

        end

        S_AFTER_CALL_157: begin

            // LIR block: after_call_157

            // line 238: if u8_kind == 9:             u8_gate = pwm_gate_comb(time=par_time, period=f32_3, duty=f32_4)             f32_6 = f32_1             if u8_gate != 0:                 f32_6 = f32_2             u8_aux = u8_next_aux             u8_next_aux = u8_next_aux + 1             if u8_n0 != 255:                 accumA(i=u8_aux, j=u8_n0, delta=f32_5)                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_n0, j=u8_aux, delta=f32_7)             if u8_n1 != 255:                 f32_7 = neg_comb(v=f32_5)                 accumA(i=u8_aux, j=u8_n1, delta=f32_7)                 accumA(i=u8_n1, j=u8_aux, delta=f32_5)             accumJ(i=u8_aux, delta=f32_6)






            next_state = S_IF_END_146;

        end

        S_FOR_HEADER_158: begin

            // LIR block: for_header_158

            // line 256: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)






            if ((__for_idx_4 < u16_dim)) begin
                next_state = S_FOR_BODY_159;
            end else begin
                next_state = S_FOR_END_160;
            end

        end

        S_FOR_BODY_159: begin

            // LIR block: for_body_159

            // line 256: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next_u16_j = __for_idx_4;

            next_u16_pivot = __for_idx_4;


            fetch_A_i = __for_idx_4;

            fetch_A_j = __for_idx_4;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_159_WAIT;

        end

        S_FOR_BODY_159_WAIT: begin

            // LIR block: for_body_159

            // line 256: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_161;
            end else begin
                next_state = S_FOR_BODY_159_WAIT;
            end

        end

        S_FOR_END_160: begin

            // LIR block: for_end_160

            // line 312: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next___for_idx_11 = 16'd0;



            next_state = S_FOR_HEADER_215;

        end

        S_AFTER_CALL_161: begin

            // LIR block: after_call_161

            // line 259: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next___for_idx_5 = 16'd0;



            next_state = S_FOR_HEADER_162;

        end

        S_FOR_HEADER_162: begin

            // LIR block: for_header_162

            // line 260: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_5 < u16_j)) begin
                next_state = S_FOR_BODY_163;
            end else begin
                next_state = S_FOR_END_164;
            end

        end

        S_FOR_BODY_163: begin

            // LIR block: for_body_163

            // line 260: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_5;


            fetch_LU_i = u16_j;

            fetch_LU_j = __for_idx_5;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_163_WAIT;

        end

        S_FOR_BODY_163_WAIT: begin

            // LIR block: for_body_163

            // line 260: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_165;
            end else begin
                next_state = S_FOR_BODY_163_WAIT;
            end

        end

        S_FOR_END_164: begin

            // LIR block: for_end_164

            // line 264: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_f32_4 = abs_comb(neg_comb(f32_1));

            next_u16_i = (u16_j + 16'd1);



            next_state = S_WHILE_HEADER_168;

        end

        S_AFTER_CALL_165: begin

            // LIR block: after_call_165

            // line 262: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_165_WAIT;

        end

        S_AFTER_CALL_165_WAIT: begin

            // LIR block: after_call_165

            // line 262: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_166;
            end else begin
                next_state = S_AFTER_CALL_165_WAIT;
            end

        end

        S_AFTER_CALL_166: begin

            // LIR block: after_call_166

            // line 263: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_166_WAIT;

        end

        S_AFTER_CALL_166_WAIT: begin

            // LIR block: after_call_166

            // line 263: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_167;
            end else begin
                next_state = S_AFTER_CALL_166_WAIT;
            end

        end

        S_AFTER_CALL_167: begin

            // LIR block: after_call_167

            // line 260: for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_5 = (__for_idx_5 + 16'd1);



            next_state = S_FOR_HEADER_162;

        end

        S_WHILE_HEADER_168: begin

            // LIR block: while_header_168

            // line 267: while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1






            if ((u16_i < u16_dim)) begin
                next_state = S_WHILE_BODY_169;
            end else begin
                next_state = S_WHILE_END_170;
            end

        end

        S_WHILE_BODY_169: begin

            // LIR block: while_body_169

            // line 268: f32_1 = fetch_A(i=u16_i, j=u16_j)





            fetch_A_i = u16_i;

            fetch_A_j = u16_j;

            fetch_A_start = 1'b1;


            next_state = S_WHILE_BODY_169_WAIT;

        end

        S_WHILE_BODY_169_WAIT: begin

            // LIR block: while_body_169

            // line 268: f32_1 = fetch_A(i=u16_i, j=u16_j)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_171;
            end else begin
                next_state = S_WHILE_BODY_169_WAIT;
            end

        end

        S_WHILE_END_170: begin

            // LIR block: while_end_170

            // line 281: if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)






            if ((u16_pivot != u16_j)) begin
                next_state = S_IF_THEN_180;
            end else begin
                next_state = S_IF_END_181;
            end

        end

        S_AFTER_CALL_171: begin

            // LIR block: after_call_171

            // line 269: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next___for_idx_6 = 16'd0;



            next_state = S_FOR_HEADER_172;

        end

        S_FOR_HEADER_172: begin

            // LIR block: for_header_172

            // line 270: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_6 < u16_j)) begin
                next_state = S_FOR_BODY_173;
            end else begin
                next_state = S_FOR_END_174;
            end

        end

        S_FOR_BODY_173: begin

            // LIR block: for_body_173

            // line 270: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_6;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_6;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_173_WAIT;

        end

        S_FOR_BODY_173_WAIT: begin

            // LIR block: for_body_173

            // line 270: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_175;
            end else begin
                next_state = S_FOR_BODY_173_WAIT;
            end

        end

        S_FOR_END_174: begin

            // LIR block: for_end_174

            // line 274: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_f32_1 = abs_comb(neg_comb(f32_1));



            if (gt_comb(abs_comb(neg_comb(f32_1)), f32_4)) begin
                next_state = S_IF_THEN_178;
            end else begin
                next_state = S_IF_END_179;
            end

        end

        S_AFTER_CALL_175: begin

            // LIR block: after_call_175

            // line 272: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_175_WAIT;

        end

        S_AFTER_CALL_175_WAIT: begin

            // LIR block: after_call_175

            // line 272: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_176;
            end else begin
                next_state = S_AFTER_CALL_175_WAIT;
            end

        end

        S_AFTER_CALL_176: begin

            // LIR block: after_call_176

            // line 273: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_176_WAIT;

        end

        S_AFTER_CALL_176_WAIT: begin

            // LIR block: after_call_176

            // line 273: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_177;
            end else begin
                next_state = S_AFTER_CALL_176_WAIT;
            end

        end

        S_AFTER_CALL_177: begin

            // LIR block: after_call_177

            // line 270: for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_6 = (__for_idx_6 + 16'd1);



            next_state = S_FOR_HEADER_172;

        end

        S_IF_THEN_178: begin

            // LIR block: if_then_178

            // line 277: f32_4 = f32_1




            next_f32_4 = f32_1;

            next_u16_pivot = u16_i;



            next_state = S_IF_END_179;

        end

        S_IF_END_179: begin

            // LIR block: if_end_179

            // line 279: u16_i = u16_i + 1




            next_u16_i = (u16_i + 16'd1);



            next_state = S_WHILE_HEADER_168;

        end

        S_IF_THEN_180: begin

            // LIR block: if_then_180

            // line 282: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_7 = 16'd0;



            next_state = S_FOR_HEADER_182;

        end

        S_IF_END_181: begin

            // LIR block: if_end_181

            // line 297: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_9 = 16'd0;



            next_state = S_FOR_HEADER_200;

        end

        S_FOR_HEADER_182: begin

            // LIR block: for_header_182

            // line 282: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)






            if ((__for_idx_7 < u16_dim)) begin
                next_state = S_FOR_BODY_183;
            end else begin
                next_state = S_FOR_END_184;
            end

        end

        S_FOR_BODY_183: begin

            // LIR block: for_body_183

            // line 282: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next_u16_k = __for_idx_7;


            fetch_A_i = u16_j;

            fetch_A_j = __for_idx_7;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_183_WAIT;

        end

        S_FOR_BODY_183_WAIT: begin

            // LIR block: for_body_183

            // line 282: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_185;
            end else begin
                next_state = S_FOR_BODY_183_WAIT;
            end

        end

        S_FOR_END_184: begin

            // LIR block: for_end_184

            // line 287: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_8 = 16'd0;



            next_state = S_FOR_HEADER_189;

        end

        S_AFTER_CALL_185: begin

            // LIR block: after_call_185

            // line 284: f32_2 = fetch_A(i=u16_pivot, j=u16_k)





            fetch_A_i = u16_pivot;

            fetch_A_j = u16_k;

            fetch_A_start = 1'b1;


            next_state = S_AFTER_CALL_185_WAIT;

        end

        S_AFTER_CALL_185_WAIT: begin

            // LIR block: after_call_185

            // line 284: f32_2 = fetch_A(i=u16_pivot, j=u16_k)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_2 = fetch_A_result;

                next_state = S_AFTER_CALL_186;
            end else begin
                next_state = S_AFTER_CALL_185_WAIT;
            end

        end

        S_AFTER_CALL_186: begin

            // LIR block: after_call_186

            // line 285: store_A(i=u16_j, j=u16_k, v=f32_2)





            store_A_i = u16_j;

            store_A_j = u16_k;

            store_A_v = f32_2;

            store_A_start = 1'b1;


            next_state = S_AFTER_CALL_186_WAIT;

        end

        S_AFTER_CALL_186_WAIT: begin

            // LIR block: after_call_186

            // line 285: store_A(i=u16_j, j=u16_k, v=f32_2)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_187;
            end else begin
                next_state = S_AFTER_CALL_186_WAIT;
            end

        end

        S_AFTER_CALL_187: begin

            // LIR block: after_call_187

            // line 286: store_A(i=u16_pivot, j=u16_k, v=f32_1)





            store_A_i = u16_pivot;

            store_A_j = u16_k;

            store_A_v = f32_1;

            store_A_start = 1'b1;


            next_state = S_AFTER_CALL_187_WAIT;

        end

        S_AFTER_CALL_187_WAIT: begin

            // LIR block: after_call_187

            // line 286: store_A(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: store_A






            if (store_A_done) begin

                next_state = S_AFTER_CALL_188;
            end else begin
                next_state = S_AFTER_CALL_187_WAIT;
            end

        end

        S_AFTER_CALL_188: begin

            // LIR block: after_call_188

            // line 282: for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_7 = (__for_idx_7 + 16'd1);



            next_state = S_FOR_HEADER_182;

        end

        S_FOR_HEADER_189: begin

            // LIR block: for_header_189

            // line 287: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)






            if ((__for_idx_8 < u16_j)) begin
                next_state = S_FOR_BODY_190;
            end else begin
                next_state = S_FOR_END_191;
            end

        end

        S_FOR_BODY_190: begin

            // LIR block: for_body_190

            // line 287: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next_u16_k = __for_idx_8;


            fetch_LU_i = u16_j;

            fetch_LU_j = __for_idx_8;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_190_WAIT;

        end

        S_FOR_BODY_190_WAIT: begin

            // LIR block: for_body_190

            // line 287: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_1 = fetch_LU_result;

                next_state = S_AFTER_CALL_192;
            end else begin
                next_state = S_FOR_BODY_190_WAIT;
            end

        end

        S_FOR_END_191: begin

            // LIR block: for_end_191

            // line 292: f32_1 = fetch_J(i=u16_j)





            fetch_J_i = u16_j;

            fetch_J_start = 1'b1;


            next_state = S_FOR_END_191_WAIT;

        end

        S_FOR_END_191_WAIT: begin

            // LIR block: for_end_191

            // line 292: f32_1 = fetch_J(i=u16_j)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_1 = fetch_J_result;

                next_state = S_AFTER_CALL_196;
            end else begin
                next_state = S_FOR_END_191_WAIT;
            end

        end

        S_AFTER_CALL_192: begin

            // LIR block: after_call_192

            // line 289: f32_2 = fetch_LU(i=u16_pivot, j=u16_k)





            fetch_LU_i = u16_pivot;

            fetch_LU_j = u16_k;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_192_WAIT;

        end

        S_AFTER_CALL_192_WAIT: begin

            // LIR block: after_call_192

            // line 289: f32_2 = fetch_LU(i=u16_pivot, j=u16_k)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_193;
            end else begin
                next_state = S_AFTER_CALL_192_WAIT;
            end

        end

        S_AFTER_CALL_193: begin

            // LIR block: after_call_193

            // line 290: store_LU(i=u16_j, j=u16_k, v=f32_2)





            store_LU_i = u16_j;

            store_LU_j = u16_k;

            store_LU_v = f32_2;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_193_WAIT;

        end

        S_AFTER_CALL_193_WAIT: begin

            // LIR block: after_call_193

            // line 290: store_LU(i=u16_j, j=u16_k, v=f32_2)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_194;
            end else begin
                next_state = S_AFTER_CALL_193_WAIT;
            end

        end

        S_AFTER_CALL_194: begin

            // LIR block: after_call_194

            // line 291: store_LU(i=u16_pivot, j=u16_k, v=f32_1)





            store_LU_i = u16_pivot;

            store_LU_j = u16_k;

            store_LU_v = f32_1;

            store_LU_start = 1'b1;


            next_state = S_AFTER_CALL_194_WAIT;

        end

        S_AFTER_CALL_194_WAIT: begin

            // LIR block: after_call_194

            // line 291: store_LU(i=u16_pivot, j=u16_k, v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_195;
            end else begin
                next_state = S_AFTER_CALL_194_WAIT;
            end

        end

        S_AFTER_CALL_195: begin

            // LIR block: after_call_195

            // line 287: for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)




            next___for_idx_8 = (__for_idx_8 + 16'd1);



            next_state = S_FOR_HEADER_189;

        end

        S_AFTER_CALL_196: begin

            // LIR block: after_call_196

            // line 293: f32_2 = fetch_J(i=u16_pivot)





            fetch_J_i = u16_pivot;

            fetch_J_start = 1'b1;


            next_state = S_AFTER_CALL_196_WAIT;

        end

        S_AFTER_CALL_196_WAIT: begin

            // LIR block: after_call_196

            // line 293: f32_2 = fetch_J(i=u16_pivot)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_2 = fetch_J_result;

                next_state = S_AFTER_CALL_197;
            end else begin
                next_state = S_AFTER_CALL_196_WAIT;
            end

        end

        S_AFTER_CALL_197: begin

            // LIR block: after_call_197

            // line 294: store_J(i=u16_j, v=f32_2)





            store_J_i = u16_j;

            store_J_v = f32_2;

            store_J_start = 1'b1;


            next_state = S_AFTER_CALL_197_WAIT;

        end

        S_AFTER_CALL_197_WAIT: begin

            // LIR block: after_call_197

            // line 294: store_J(i=u16_j, v=f32_2)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_198;
            end else begin
                next_state = S_AFTER_CALL_197_WAIT;
            end

        end

        S_AFTER_CALL_198: begin

            // LIR block: after_call_198

            // line 295: store_J(i=u16_pivot, v=f32_1)





            store_J_i = u16_pivot;

            store_J_v = f32_1;

            store_J_start = 1'b1;


            next_state = S_AFTER_CALL_198_WAIT;

        end

        S_AFTER_CALL_198_WAIT: begin

            // LIR block: after_call_198

            // line 295: store_J(i=u16_pivot, v=f32_1)

            // wait for blocking primitive: store_J






            if (store_J_done) begin

                next_state = S_AFTER_CALL_199;
            end else begin
                next_state = S_AFTER_CALL_198_WAIT;
            end

        end

        S_AFTER_CALL_199: begin

            // LIR block: after_call_199

            // line 281: if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)






            next_state = S_IF_END_181;

        end

        S_FOR_HEADER_200: begin

            // LIR block: for_header_200

            // line 297: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)






            if ((__for_idx_9 < u16_dim)) begin
                next_state = S_FOR_BODY_201;
            end else begin
                next_state = S_FOR_END_202;
            end

        end

        S_FOR_BODY_201: begin

            // LIR block: for_body_201

            // line 297: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next_u16_i = __for_idx_9;


            fetch_A_i = __for_idx_9;

            fetch_A_j = u16_j;

            fetch_A_start = 1'b1;


            next_state = S_FOR_BODY_201_WAIT;

        end

        S_FOR_BODY_201_WAIT: begin

            // LIR block: for_body_201

            // line 297: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)

            // wait for blocking primitive: fetch_A






            if (fetch_A_done) begin

                next_f32_1 = fetch_A_result;

                next_state = S_AFTER_CALL_203;
            end else begin
                next_state = S_FOR_BODY_201_WAIT;
            end

        end

        S_FOR_END_202: begin

            // LIR block: for_end_202

            // line 256: for u16_j in range(u16_dim):         u16_pivot = u16_j         f32_1 = fetch_A(i=u16_j, j=u16_j)         f32_1 = neg_comb(v=f32_1)         for u16_k in range(u16_j):             f32_2 = fetch_LU(i=u16_j, j=u16_k)             f32_3 = fetch_LU(i=u16_k, j=u16_j)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         f32_1 = neg_comb(v=f32_1)         f32_4 = abs_comb(v=f32_1)         u16_i = u16_j + 1         while u16_i < u16_dim:             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             for u16_k in range(u16_j):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             f32_1 = neg_comb(v=f32_1)             f32_1 = abs_comb(v=f32_1)             if gt_comb(a=f32_1, b=f32_4):                 f32_4 = f32_1                 u16_pivot = u16_i             u16_i = u16_i + 1          if u16_pivot != u16_j:             for u16_k in range(u16_dim):                 f32_1 = fetch_A(i=u16_j, j=u16_k)                 f32_2 = fetch_A(i=u16_pivot, j=u16_k)                 store_A(i=u16_j, j=u16_k, v=f32_2)                 store_A(i=u16_pivot, j=u16_k, v=f32_1)             for u16_k in range(u16_j):                 f32_1 = fetch_LU(i=u16_j, j=u16_k)                 f32_2 = fetch_LU(i=u16_pivot, j=u16_k)                 store_LU(i=u16_j, j=u16_k, v=f32_2)                 store_LU(i=u16_pivot, j=u16_k, v=f32_1)             f32_1 = fetch_J(i=u16_j)             f32_2 = fetch_J(i=u16_pivot)             store_J(i=u16_j, v=f32_2)             store_J(i=u16_pivot, v=f32_1)          for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_4 = (__for_idx_4 + 16'd1);



            next_state = S_FOR_HEADER_158;

        end

        S_AFTER_CALL_203: begin

            // LIR block: after_call_203

            // line 299: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);

            next_u16_m = ((u16_i > u16_j) ? u16_j : u16_i);

            next___for_idx_10 = 16'd0;



            next_state = S_FOR_HEADER_204;

        end

        S_FOR_HEADER_204: begin

            // LIR block: for_header_204

            // line 301: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_10 < u16_m)) begin
                next_state = S_FOR_BODY_205;
            end else begin
                next_state = S_FOR_END_206;
            end

        end

        S_FOR_BODY_205: begin

            // LIR block: for_body_205

            // line 301: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_10;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_10;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_205_WAIT;

        end

        S_FOR_BODY_205_WAIT: begin

            // LIR block: for_body_205

            // line 301: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_207;
            end else begin
                next_state = S_FOR_BODY_205_WAIT;
            end

        end

        S_FOR_END_206: begin

            // LIR block: for_end_206

            // line 305: if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)






            if ((u16_i > u16_j)) begin
                next_state = S_IF_THEN_210;
            end else begin
                next_state = S_IF_END_211;
            end

        end

        S_AFTER_CALL_207: begin

            // LIR block: after_call_207

            // line 303: f32_3 = fetch_LU(i=u16_k, j=u16_j)





            fetch_LU_i = u16_k;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_AFTER_CALL_207_WAIT;

        end

        S_AFTER_CALL_207_WAIT: begin

            // LIR block: after_call_207

            // line 303: f32_3 = fetch_LU(i=u16_k, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_3 = fetch_LU_result;

                next_state = S_AFTER_CALL_208;
            end else begin
                next_state = S_AFTER_CALL_207_WAIT;
            end

        end

        S_AFTER_CALL_208: begin

            // LIR block: after_call_208

            // line 304: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)





            fma_a = f32_2;

            fma_b = f32_3;

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_208_WAIT;

        end

        S_AFTER_CALL_208_WAIT: begin

            // LIR block: after_call_208

            // line 304: f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_209;
            end else begin
                next_state = S_AFTER_CALL_208_WAIT;
            end

        end

        S_AFTER_CALL_209: begin

            // LIR block: after_call_209

            // line 301: for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_10 = (__for_idx_10 + 16'd1);



            next_state = S_FOR_HEADER_204;

        end

        S_IF_THEN_210: begin

            // LIR block: if_then_210

            // line 306: f32_2 = fetch_LU(i=u16_j, j=u16_j)





            fetch_LU_i = u16_j;

            fetch_LU_j = u16_j;

            fetch_LU_start = 1'b1;


            next_state = S_IF_THEN_210_WAIT;

        end

        S_IF_THEN_210_WAIT: begin

            // LIR block: if_then_210

            // line 306: f32_2 = fetch_LU(i=u16_j, j=u16_j)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_212;
            end else begin
                next_state = S_IF_THEN_210_WAIT;
            end

        end

        S_IF_END_211: begin

            // LIR block: if_end_211

            // line 308: f32_1 = neg_comb(v=f32_1)




            next_f32_1 = neg_comb(f32_1);


            store_LU_i = u16_i;

            store_LU_j = u16_j;

            store_LU_v = neg_comb(f32_1);

            store_LU_start = 1'b1;


            next_state = S_IF_END_211_WAIT;

        end

        S_IF_END_211_WAIT: begin

            // LIR block: if_end_211

            // line 308: f32_1 = neg_comb(v=f32_1)

            // wait for blocking primitive: store_LU






            if (store_LU_done) begin

                next_state = S_AFTER_CALL_214;
            end else begin
                next_state = S_IF_END_211_WAIT;
            end

        end

        S_AFTER_CALL_212: begin

            // LIR block: after_call_212

            // line 307: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_212_WAIT;

        end

        S_AFTER_CALL_212_WAIT: begin

            // LIR block: after_call_212

            // line 307: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_213;
            end else begin
                next_state = S_AFTER_CALL_212_WAIT;
            end

        end

        S_AFTER_CALL_213: begin

            // LIR block: after_call_213

            // line 305: if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)






            next_state = S_IF_END_211;

        end

        S_AFTER_CALL_214: begin

            // LIR block: after_call_214

            // line 297: for u16_i in range(u16_dim):             f32_1 = fetch_A(i=u16_i, j=u16_j)             f32_1 = neg_comb(v=f32_1)             u16_m = u16_j if u16_i > u16_j else u16_i             for u16_k in range(u16_m):                 f32_2 = fetch_LU(i=u16_i, j=u16_k)                 f32_3 = fetch_LU(i=u16_k, j=u16_j)                 f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             if u16_i > u16_j:                 f32_2 = fetch_LU(i=u16_j, j=u16_j)                 f32_1 = div(a=f32_1, b=f32_2)             f32_1 = neg_comb(v=f32_1)             store_LU(i=u16_i, j=u16_j, v=f32_1)




            next___for_idx_9 = (__for_idx_9 + 16'd1);



            next_state = S_FOR_HEADER_200;

        end

        S_FOR_HEADER_215: begin

            // LIR block: for_header_215

            // line 312: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)






            if ((__for_idx_11 < u16_dim)) begin
                next_state = S_FOR_BODY_216;
            end else begin
                next_state = S_FOR_END_217;
            end

        end

        S_FOR_BODY_216: begin

            // LIR block: for_body_216

            // line 312: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next_u16_i = __for_idx_11;


            fetch_J_i = __for_idx_11;

            fetch_J_start = 1'b1;


            next_state = S_FOR_BODY_216_WAIT;

        end

        S_FOR_BODY_216_WAIT: begin

            // LIR block: for_body_216

            // line 312: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)

            // wait for blocking primitive: fetch_J






            if (fetch_J_done) begin

                next_f32_1 = fetch_J_result;

                next_state = S_AFTER_CALL_218;
            end else begin
                next_state = S_FOR_BODY_216_WAIT;
            end

        end

        S_FOR_END_217: begin

            // LIR block: for_end_217

            // line 322: u16_i = u16_dim




            next_u16_i = u16_dim;



            next_state = S_WHILE_HEADER_226;

        end

        S_AFTER_CALL_218: begin

            // LIR block: after_call_218

            // line 314: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_12 = 16'd0;



            next_state = S_FOR_HEADER_219;

        end

        S_FOR_HEADER_219: begin

            // LIR block: for_header_219

            // line 314: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)






            if ((__for_idx_12 < u16_i)) begin
                next_state = S_FOR_BODY_220;
            end else begin
                next_state = S_FOR_END_221;
            end

        end

        S_FOR_BODY_220: begin

            // LIR block: for_body_220

            // line 314: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next_u16_k = __for_idx_12;


            fetch_LU_i = u16_i;

            fetch_LU_j = __for_idx_12;

            fetch_LU_start = 1'b1;


            next_state = S_FOR_BODY_220_WAIT;

        end

        S_FOR_BODY_220_WAIT: begin

            // LIR block: for_body_220

            // line 314: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_222;
            end else begin
                next_state = S_FOR_BODY_220_WAIT;
            end

        end

        S_FOR_END_221: begin

            // LIR block: for_end_221

            // line 319: store_Y(i=u16_i, v=f32_1)





            store_Y_i = u16_i;

            store_Y_v = f32_1;

            store_Y_start = 1'b1;


            next_state = S_FOR_END_221_WAIT;

        end

        S_FOR_END_221_WAIT: begin

            // LIR block: for_end_221

            // line 319: store_Y(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_Y






            if (store_Y_done) begin

                next_state = S_AFTER_CALL_225;
            end else begin
                next_state = S_FOR_END_221_WAIT;
            end

        end

        S_AFTER_CALL_222: begin

            // LIR block: after_call_222

            // line 316: f32_3 = fetch_Y(i=u16_k)





            fetch_Y_i = u16_k;

            fetch_Y_start = 1'b1;


            next_state = S_AFTER_CALL_222_WAIT;

        end

        S_AFTER_CALL_222_WAIT: begin

            // LIR block: after_call_222

            // line 316: f32_3 = fetch_Y(i=u16_k)

            // wait for blocking primitive: fetch_Y






            if (fetch_Y_done) begin

                next_f32_3 = fetch_Y_result;

                next_state = S_AFTER_CALL_223;
            end else begin
                next_state = S_AFTER_CALL_222_WAIT;
            end

        end

        S_AFTER_CALL_223: begin

            // LIR block: after_call_223

            // line 317: f32_3 = neg_comb(v=f32_3)




            next_f32_3 = neg_comb(f32_3);


            fma_a = f32_2;

            fma_b = neg_comb(f32_3);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_223_WAIT;

        end

        S_AFTER_CALL_223_WAIT: begin

            // LIR block: after_call_223

            // line 317: f32_3 = neg_comb(v=f32_3)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_224;
            end else begin
                next_state = S_AFTER_CALL_223_WAIT;
            end

        end

        S_AFTER_CALL_224: begin

            // LIR block: after_call_224

            // line 314: for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)




            next___for_idx_12 = (__for_idx_12 + 16'd1);



            next_state = S_FOR_HEADER_219;

        end

        S_AFTER_CALL_225: begin

            // LIR block: after_call_225

            // line 312: for u16_i in range(u16_dim):         f32_1 = fetch_J(i=u16_i)         for u16_k in range(u16_i):             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_Y(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)         store_Y(i=u16_i, v=f32_1)




            next___for_idx_11 = (__for_idx_11 + 16'd1);



            next_state = S_FOR_HEADER_215;

        end

        S_WHILE_HEADER_226: begin

            // LIR block: while_header_226

            // line 323: while u16_i > 0:         u16_i = u16_i - 1         f32_1 = fetch_Y(i=u16_i)         u16_k = u16_i + 1         while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1         f32_2 = fetch_LU(i=u16_i, j=u16_i)         f32_1 = div(a=f32_1, b=f32_2)         store_X(i=u16_i, v=f32_1)






            if ((u16_i > 32'd0)) begin
                next_state = S_WHILE_BODY_227;
            end else begin
                next_state = S_WHILE_END_228;
            end

        end

        S_WHILE_BODY_227: begin

            // LIR block: while_body_227

            // line 324: u16_i = u16_i - 1




            next_u16_i = (u16_i - 16'd1);


            fetch_Y_i = (u16_i - 16'd1);

            fetch_Y_start = 1'b1;


            next_state = S_WHILE_BODY_227_WAIT;

        end

        S_WHILE_BODY_227_WAIT: begin

            // LIR block: while_body_227

            // line 324: u16_i = u16_i - 1

            // wait for blocking primitive: fetch_Y






            if (fetch_Y_done) begin

                next_f32_1 = fetch_Y_result;

                next_state = S_AFTER_CALL_229;
            end else begin
                next_state = S_WHILE_BODY_227_WAIT;
            end

        end

        S_WHILE_END_228: begin

            // LIR block: while_end_228

            // line 338: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)




            next___for_idx_13 = 16'd0;



            next_state = S_FOR_HEADER_239;

        end

        S_AFTER_CALL_229: begin

            // LIR block: after_call_229

            // line 326: u16_k = u16_i + 1




            next_u16_k = (u16_i + 16'd1);



            next_state = S_WHILE_HEADER_230;

        end

        S_WHILE_HEADER_230: begin

            // LIR block: while_header_230

            // line 327: while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1






            if ((u16_k < u16_dim)) begin
                next_state = S_WHILE_BODY_231;
            end else begin
                next_state = S_WHILE_END_232;
            end

        end

        S_WHILE_BODY_231: begin

            // LIR block: while_body_231

            // line 328: f32_2 = fetch_LU(i=u16_i, j=u16_k)





            fetch_LU_i = u16_i;

            fetch_LU_j = u16_k;

            fetch_LU_start = 1'b1;


            next_state = S_WHILE_BODY_231_WAIT;

        end

        S_WHILE_BODY_231_WAIT: begin

            // LIR block: while_body_231

            // line 328: f32_2 = fetch_LU(i=u16_i, j=u16_k)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_233;
            end else begin
                next_state = S_WHILE_BODY_231_WAIT;
            end

        end

        S_WHILE_END_232: begin

            // LIR block: while_end_232

            // line 333: f32_2 = fetch_LU(i=u16_i, j=u16_i)





            fetch_LU_i = u16_i;

            fetch_LU_j = u16_i;

            fetch_LU_start = 1'b1;


            next_state = S_WHILE_END_232_WAIT;

        end

        S_WHILE_END_232_WAIT: begin

            // LIR block: while_end_232

            // line 333: f32_2 = fetch_LU(i=u16_i, j=u16_i)

            // wait for blocking primitive: fetch_LU






            if (fetch_LU_done) begin

                next_f32_2 = fetch_LU_result;

                next_state = S_AFTER_CALL_236;
            end else begin
                next_state = S_WHILE_END_232_WAIT;
            end

        end

        S_AFTER_CALL_233: begin

            // LIR block: after_call_233

            // line 329: f32_3 = fetch_X(i=u16_k)





            fetch_X_i = u16_k;

            fetch_X_start = 1'b1;


            next_state = S_AFTER_CALL_233_WAIT;

        end

        S_AFTER_CALL_233_WAIT: begin

            // LIR block: after_call_233

            // line 329: f32_3 = fetch_X(i=u16_k)

            // wait for blocking primitive: fetch_X






            if (fetch_X_done) begin

                next_f32_3 = fetch_X_result;

                next_state = S_AFTER_CALL_234;
            end else begin
                next_state = S_AFTER_CALL_233_WAIT;
            end

        end

        S_AFTER_CALL_234: begin

            // LIR block: after_call_234

            // line 330: f32_3 = neg_comb(v=f32_3)




            next_f32_3 = neg_comb(f32_3);


            fma_a = f32_2;

            fma_b = neg_comb(f32_3);

            fma_c = f32_1;

            fma_start = 1'b1;


            next_state = S_AFTER_CALL_234_WAIT;

        end

        S_AFTER_CALL_234_WAIT: begin

            // LIR block: after_call_234

            // line 330: f32_3 = neg_comb(v=f32_3)

            // wait for blocking primitive: fma






            if (fma_done) begin

                next_f32_1 = fma_result;

                next_state = S_AFTER_CALL_235;
            end else begin
                next_state = S_AFTER_CALL_234_WAIT;
            end

        end

        S_AFTER_CALL_235: begin

            // LIR block: after_call_235

            // line 332: u16_k = u16_k + 1




            next_u16_k = (u16_k + 16'd1);



            next_state = S_WHILE_HEADER_230;

        end

        S_AFTER_CALL_236: begin

            // LIR block: after_call_236

            // line 334: f32_1 = div(a=f32_1, b=f32_2)





            div_a = f32_1;

            div_b = f32_2;

            div_start = 1'b1;


            next_state = S_AFTER_CALL_236_WAIT;

        end

        S_AFTER_CALL_236_WAIT: begin

            // LIR block: after_call_236

            // line 334: f32_1 = div(a=f32_1, b=f32_2)

            // wait for blocking primitive: div






            if (div_done) begin

                next_f32_1 = div_result;

                next_state = S_AFTER_CALL_237;
            end else begin
                next_state = S_AFTER_CALL_236_WAIT;
            end

        end

        S_AFTER_CALL_237: begin

            // LIR block: after_call_237

            // line 335: store_X(i=u16_i, v=f32_1)





            store_X_i = u16_i;

            store_X_v = f32_1;

            store_X_start = 1'b1;


            next_state = S_AFTER_CALL_237_WAIT;

        end

        S_AFTER_CALL_237_WAIT: begin

            // LIR block: after_call_237

            // line 335: store_X(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_X






            if (store_X_done) begin

                next_state = S_AFTER_CALL_238;
            end else begin
                next_state = S_AFTER_CALL_237_WAIT;
            end

        end

        S_AFTER_CALL_238: begin

            // LIR block: after_call_238

            // line 323: while u16_i > 0:         u16_i = u16_i - 1         f32_1 = fetch_Y(i=u16_i)         u16_k = u16_i + 1         while u16_k < u16_dim:             f32_2 = fetch_LU(i=u16_i, j=u16_k)             f32_3 = fetch_X(i=u16_k)             f32_3 = neg_comb(v=f32_3)             f32_1 = fma(a=f32_2, b=f32_3, c=f32_1)             u16_k = u16_k + 1         f32_2 = fetch_LU(i=u16_i, j=u16_i)         f32_1 = div(a=f32_1, b=f32_2)         store_X(i=u16_i, v=f32_1)






            next_state = S_WHILE_HEADER_226;

        end

        S_FOR_HEADER_239: begin

            // LIR block: for_header_239

            // line 338: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)






            if ((__for_idx_13 < u16_dim)) begin
                next_state = S_FOR_BODY_240;
            end else begin
                next_state = S_FOR_END_241;
            end

        end

        S_FOR_BODY_240: begin

            // LIR block: for_body_240

            // line 338: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)




            next_u16_i = __for_idx_13;


            fetch_X_i = __for_idx_13;

            fetch_X_start = 1'b1;


            next_state = S_FOR_BODY_240_WAIT;

        end

        S_FOR_BODY_240_WAIT: begin

            // LIR block: for_body_240

            // line 338: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)

            // wait for blocking primitive: fetch_X






            if (fetch_X_done) begin

                next_f32_1 = fetch_X_result;

                next_state = S_AFTER_CALL_242;
            end else begin
                next_state = S_FOR_BODY_240_WAIT;
            end

        end

        S_FOR_END_241: begin

            // LIR block: for_end_241







            next_state = S_DONE;

        end

        S_AFTER_CALL_242: begin

            // LIR block: after_call_242

            // line 340: store_prevX(i=u16_i, v=f32_1)





            store_prevX_i = u16_i;

            store_prevX_v = f32_1;

            store_prevX_start = 1'b1;


            next_state = S_AFTER_CALL_242_WAIT;

        end

        S_AFTER_CALL_242_WAIT: begin

            // LIR block: after_call_242

            // line 340: store_prevX(i=u16_i, v=f32_1)

            // wait for blocking primitive: store_prevX






            if (store_prevX_done) begin

                next_state = S_AFTER_CALL_243;
            end else begin
                next_state = S_AFTER_CALL_242_WAIT;
            end

        end

        S_AFTER_CALL_243: begin

            // LIR block: after_call_243

            // line 338: for u16_i in range(u16_dim):         f32_1 = fetch_X(i=u16_i)         store_prevX(i=u16_i, v=f32_1)




            next___for_idx_13 = (__for_idx_13 + 16'd1);



            next_state = S_FOR_HEADER_239;

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
