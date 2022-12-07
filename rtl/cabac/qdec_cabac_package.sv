// Package containing all LUT for arithmetic decoder
package qdec_cabac_package;

// FSM state definition
typedef enum logic [7:0]  {IDLE_MAIN, CALC_COR_MAIN, CTX_INIT_MAIN, SAO_MAIN, 
                           CQT_MAIN, EOS_FLAG_MAIN, ADDR_INC_MAIN, RBSP_STOP_ONE_BIT_MAIN, 
                           RBSP_ALIGNMENT_ZERO_BITS, ERROR_MAIN, ENDING_MAIN} t_state_main;
typedef enum logic [7:0]  {IDLE_INIT, SCAN_INIT, ENDING_INIT} t_state_init;
typedef enum logic [7:0]  {IDLE_SAO, CALC_COR_SAO, SAO_MERGE_LEFT_FLAG, SAO_MERGE_UP_FLAG, 
                           SAO_TYPE_IDX_LUMA, SAO_LUMA_OFFSET_ABS_4, SAO_LUMA_OFFSET_SIGN_4, SAO_LUMA_BAND_POS, SAO_EO_CLASS_LUMA, 
                           SAO_TYPE_IDX_CHROMA, SAO_CB_OFFSET_ABS_4, SAO_CB_OFFSET_SIGN_4, SAO_CB_BAND_POS, SAO_EO_CLASS_CHROMA, 
                           SAO_CR_OFFSET_ABS_4, SAO_CR_OFFSET_SIGN_4, SAO_CR_BAND_POS, ENDING_SAO} t_state_sao;
typedef enum logic [7:0]  {IDLE_CQT, CALC_COR_CQT, SPLIT_CU_FLAG_CQT, OOB_FORCE_SPLIT_CQT, 
                           CU_CQT, JUDGE_CQT, ITERATION_CQT, ENDING_CQT} t_state_cqt;
typedef enum logic [7:0]  {IDLE_CU, JUDGE_FIRST_BIT_CU, CU_TRANSQUANT_BYPASS_FLAG, CU_SKIP_FLAG, PRED_MODE_FLAG, 
                           PART_MODE, PU_CU, RQT_ROOT_CBF, 
                           JUDGE_CB_SPLIT, PREV_INTRA_LUMA_PRED_FLAG, MPM_IDX0, MPM_IDX1, MPM_IDX2, MPM_IDX3, MPM_IDX,
                           REM_INTRA_LUMA_PRED_MODE0, REM_INTRA_LUMA_PRED_MODE1, REM_INTRA_LUMA_PRED_MODE2, REM_INTRA_LUMA_PRED_MODE3, REM_INTRA_LUMA_PRED_MODE,
                           INTRA_CHROMA_PRED_MODE0, INTRA_CHROMA_PRED_MODE1, INTRA_CHROMA_PRED_MODE2, INTRA_CHROMA_PRED_MODE3, INTRA_CHROMA_PRED_MODE,
                           TRAFO, ENDING_CU} t_state_cu;
typedef enum logic [7:0]  {IDLE_PU, MERGE_IDX, MERGE_FLAG, JUDGE_INTER_PRED_IDC, INTER_PRED_IDC,
                           REF_IDX_L0, MVD_CODING_0, MVP_L0_FLAG, REF_IDX_L1, MVD_CODING_1, MVP_L1_FLAG, ENDING_PU} t_state_pu;
typedef enum logic [7:0]  {IDLE_MVD, ABS_MVD_GREATER0_FLAG0, ABS_MVD_GREATER0_FLAG1, ABS_MVD_GREATER1_FLAG0, ABS_MVD_GREATER1_FLAG1, 
                           JUDGE_MVD_MINUS2_0, ABS_MVD_MINUS2_0, MVD_SIGN_FLAG0, JUDGE_MVD_MINUS2_1, ABS_MVD_MINUS2_1, MVD_SIGN_FLAG1, ENDING_MVD} t_state_mvd;
typedef enum logic [7:0]  {IDLE_TRAFO, JUDGE_SPLIT_TRAFO, SPLIT_TRANSFORM_FLAG, JUDGE_CBF_CHROMA, CBF_CB, CBF_CR, 
                           ITERATION_TRAFO, JUDGE_CBF_LUMA, CBF_LUMA, TU_CODING, ENDING_TRAFO} t_state_trafo;
typedef enum logic [7:0]  {IDLE_TU, CBF_TU, DELTA_QP, CHROMA_QP_OFFSET, RES_CODING_LUMA, JUDGE_RES_CHROMA, 
                           RES_CODING_CB, RES_CODING_CR, RES_CODING_PARENT_CB, RES_CODING_PARENT_CR, ENDING_TU} t_state_tu;
typedef enum logic [7:0]  {IDLE_DQP, CU_QP_DELTA_ABS, CU_QP_DELTA_SIGN_FLAG, ENDING_DQP} t_state_dqp;
typedef enum logic [7:0]  {IDLE_CQP, CU_CHROMA_QP_OFFSET_FLAG, CU_CHROMA_QP_OFFSET_IDX, ENDING_CQP} t_state_cqp;
typedef enum logic [7:0]  {IDLE_RES, JUDGE_TRAFO_SKIP, TRANSFORM_SKIP_FLAG, 
                           LAST_SIG_COEFF_X_PREFIX, LAST_SIG_COEFF_Y_PREFIX, LAST_SIG_COEFF_X_SUFFIX, LAST_SIG_COEFF_Y_SUFFIX, 
                           FIND_LAST_POS_0, FIND_LAST_POS_1, CALC_COR_RES, JUDGE_CSBF, CODED_SUB_BLOCK_FLAG, JUDGE_SIG_COEFF_FLAG, SIG_COEFF_FLAG, NXT_SIG_COEFF_FLAG, 
                           JUDGE_COEFF_ABS_GT1_FLAG, COEFF_ABS_LEVEL_GT1_FLAG, NXT_COEFF_ABS_GT1_FLAG, 
                           SIGN_HIDDEN, JUDGE_COEFF_ABS_GT2_FLAG, COEFF_ABS_LEVEL_GT2_FLAG, 
                           JUDGE_COEFF_SIGN_FLAG, COEFF_SIGN_FLAG_FIRST, COEFF_SIGN_FLAG, NXT_COEFF_SIGN_FLAG, 
                           JUDGE_COEFF_ABS_REM, COEFF_ABS_LEVEL_REM, NXT_COEFF_ABS_REM, ITERATION_RES, ENDING_RES} t_state_res;

// slice types
localparam SLICE_TYPE_I = 2;
localparam SLICE_TYPE_P = 1;
localparam SLICE_TYPE_B = 0;

// pred mode flag
localparam PRED_MODE_FLAG_INTER = 0;
localparam PRED_MODE_FLAG_INTRA = 1;

// part mode
localparam PART_MODE_INTRA_PART_2Nx2N = 0;
localparam PART_MODE_INTRA_PART_NxN   = 1;
localparam PART_MODE_INTER_PART_2Nx2N = 0;
localparam PART_MODE_INTER_PART_2NxN  = 1;
localparam PART_MODE_INTER_PART_Nx2N  = 2;
localparam PART_MODE_INTER_PART_NxN   = 3;
localparam PART_MODE_INTER_PART_2NxnU = 4;
localparam PART_MODE_INTER_PART_2NxnD = 5;
localparam PART_MODE_INTER_PART_nLx2N = 6;
localparam PART_MODE_INTER_PART_nRx2N = 7;

// chroma array type
localparam CHROMA_FORMAT_MONOCHROME         = 0;
localparam CHROMA_FORMAT_420                = 1;
localparam CHROMA_FORMAT_422                = 2;
localparam CHROMA_FORMAT_444                = 3;
localparam CHROMA_FORMAT_444_SEPARATE_COLOR = 4;

// sig coeff flag ctx id map
localparam logic [14:0][3:0] SIG_COEFF_FLAG_CTXIDX_MAP = {4'd0, 4'd1, 4'd4, 4'd5, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd6, 4'd8, 4'd8, 4'd7, 4'd7, 4'd8};

// scan order
// scanIdx 0, diagonal
// 0 2     0 1
// 1 3     2 3
localparam logic [3:0][1:0]  REORDER_SCANIDX0_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h2, 2'h1, 2'h3};
localparam logic [3:0][1:0]  REORDER_SCANIDX0_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h2, 2'h1, 2'h3};
// 0 2 5 9        0 1 4 5
// 1 4 8 c        2 3 6 7
// 3 7 b e        8 9 c d
// 6 a d f        a b e f
localparam logic [15:0][3:0] REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h2, 4'h1, 4'h4, 4'h5, 4'h9, 4'h8, 4'hc, 4'h3, 4'h7, 4'h6, 4'ha, 4'hb, 4'he, 4'hd, 4'hf};
localparam logic [15:0][3:0] REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h2, 4'h1, 4'h8, 4'h3, 4'h4, 4'ha, 4'h9, 4'h6, 4'h5, 4'hb, 4'hc, 4'h7, 4'he, 4'hd, 4'hf};
//  0  2  5  9  e 14 1b 23        0  1  4  5 10 11 14 15
//  1  4  8  d 13 1a 22 2a        2  3  6  7 12 13 16 17
//  3  7  c 12 19 21 29 30        8  9  c  d 18 19 1c 1d
//  6  b 11 18 20 28 2f 35        a  b  e  f 1a 1b 1e 1f
//  a 10 17 1f 27 2e 34 39       20 21 24 25 30 31 34 35
//  f 16 1e 26 2d 33 38 3c       22 23 26 27 32 33 36 37
// 15 1d 25 2c 32 37 3b 3e       28 29 2c 2d 38 39 3c 3d
// 1c 24 2b 31 36 3a 3d 3f       2a 2b 2e 2f 3a 3b 3e 3f
localparam logic [63:0][5:0] REORDER_SCANIDX0_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h02, 6'h01, 6'h04, 6'h05, 6'h09, 6'h08, 6'h0d, 6'h03, 6'h07, 6'h06, 6'h0b, 6'h0c, 6'h12, 6'h11, 6'h18, 
                              6'h0e, 6'h14, 6'h13, 6'h1a, 6'h1b, 6'h23, 6'h22, 6'h2a, 6'h19, 6'h21, 6'h20, 6'h28, 6'h29, 6'h30, 6'h2f, 6'h35,
                              6'h0a, 6'h10, 6'h0f, 6'h16, 6'h17, 6'h1f, 6'h1e, 6'h26, 6'h15, 6'h1d, 6'h1c, 6'h24, 6'h25, 6'h2c, 6'h2b, 6'h31,
                              6'h27, 6'h2e, 6'h2d, 6'h33, 6'h34, 6'h39, 6'h38, 6'h3c, 6'h32, 6'h37, 6'h36, 6'h3a, 6'h3b, 6'h3e, 6'h3d, 6'h3f};
localparam logic [63:0][5:0] REORDER_SCANIDX0_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h02, 6'h01, 6'h08, 6'h03, 6'h04, 6'h0a, 6'h09, 6'h06, 6'h05, 6'h20, 6'h0b, 6'h0c, 6'h07, 6'h10, 6'h22, 
                              6'h21, 6'h0e, 6'h0d, 6'h12, 6'h11, 6'h28, 6'h23, 6'h24, 6'h0f, 6'h18, 6'h13, 6'h14, 6'h2a, 6'h29, 6'h26, 6'h25,
                              6'h1a, 6'h19, 6'h16, 6'h15, 6'h2b, 6'h2c, 6'h27, 6'h30, 6'h1b, 6'h1c, 6'h17, 6'h2e, 6'h2d, 6'h32, 6'h31, 6'h1e,
                              6'h1d, 6'h2f, 6'h38, 6'h33, 6'h34, 6'h1f, 6'h3a, 6'h39, 6'h36, 6'h35, 6'h3b, 6'h3c, 6'h37, 6'h3e, 6'h3d, 6'h3f};
// scanIdx 1, horizontal
// 0 1     0 1
// 2 3     2 3
localparam logic [3:0][1:0]  REORDER_SCANIDX1_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h1, 2'h2, 2'h3};
localparam logic [3:0][1:0]  REORDER_SCANIDX1_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h1, 2'h2, 2'h3};
// 0 1 2 3        0 1 4 5
// 4 5 6 7        2 3 6 7
// 8 9 a b        8 9 c d
// c d e f        a b e f
localparam logic [15:0][3:0] REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h1, 4'h4, 4'h5, 4'h2, 4'h3, 4'h6, 4'h7, 4'h8, 4'h9, 4'hc, 4'hd, 4'ha, 4'hb, 4'he, 4'hf};
localparam logic [15:0][3:0] REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h1, 4'h4, 4'h5, 4'h2, 4'h3, 4'h6, 4'h7, 4'h8, 4'h9, 4'hc, 4'hd, 4'ha, 4'hb, 4'he, 4'hf};
//  0  1  2  3  4  5  6  7        0  1  4  5 10 11 14 15
//  8  9  a  b  c  d  e  f        2  3  6  7 12 13 16 17
// 10 11 12 13 14 15 16 17        8  9  c  d 18 19 1c 1d
// 18 19 1a 1b 1c 1d 1e 1f        a  b  e  f 1a 1b 1e 1f
// 20 21 22 23 24 25 26 27       20 21 24 25 30 31 34 35
// 28 29 2a 2b 2c 2d 2e 2f       22 23 26 27 32 33 36 37
// 30 31 32 33 34 35 36 37       28 29 2c 2d 38 39 3c 3d
// 38 39 3a 3b 3c 3d 3e 3f       2a 2b 2e 2f 3a 3b 3e 3f
localparam logic [63:0][5:0] REORDER_SCANIDX1_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h01, 6'h08, 6'h09, 6'h02, 6'h03, 6'h0a, 6'h0b, 6'h10, 6'h11, 6'h18, 6'h19, 6'h12, 6'h13, 6'h1a, 6'h1b,
                              6'h04, 6'h05, 6'h0c, 6'h0d, 6'h06, 6'h07, 6'h0e, 6'h0f, 6'h14, 6'h15, 6'h1c, 6'h1d, 6'h16, 6'h17, 6'h1e, 6'h1f,
                              6'h20, 6'h21, 6'h28, 6'h29, 6'h22, 6'h23, 6'h2a, 6'h2b, 6'h30, 6'h31, 6'h38, 6'h39, 6'h32, 6'h33, 6'h3a, 6'h3b,
                              6'h24, 6'h25, 6'h2c, 6'h2d, 6'h26, 6'h27, 6'h2e, 6'h2f, 6'h34, 6'h35, 6'h3c, 6'h3d, 6'h36, 6'h37, 6'h3e, 6'h3f};
localparam logic [63:0][5:0] REORDER_SCANIDX1_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h01, 6'h04, 6'h05, 6'h10, 6'h11, 6'h14, 6'h15, 6'h02, 6'h03, 6'h06, 6'h07, 6'h12, 6'h13, 6'h16, 6'h17,
                              6'h08, 6'h09, 6'h0c, 6'h0d, 6'h18, 6'h19, 6'h1c, 6'h1d, 6'h0a, 6'h0b, 6'h0e, 6'h0f, 6'h1a, 6'h1b, 6'h1e, 6'h1f,
                              6'h20, 6'h21, 6'h24, 6'h25, 6'h30, 6'h31, 6'h34, 6'h35, 6'h22, 6'h23, 6'h26, 6'h27, 6'h32, 6'h33, 6'h36, 6'h37,
                              6'h28, 6'h29, 6'h2c, 6'h2d, 6'h38, 6'h39, 6'h3c, 6'h3d, 6'h2a, 6'h2b, 6'h2e, 6'h2f, 6'h3a, 6'h3b, 6'h3e, 6'h3f};
// scanIdx 2, vertical
// 0 2     0 1
// 1 3     2 3
localparam logic [3:0][1:0]  REORDER_SCANIDX2_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h2, 2'h1, 2'h3};
localparam logic [3:0][1:0]  REORDER_SCANIDX2_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h2, 2'h1, 2'h3};
// 0 4 8 c        0 1 4 5
// 1 5 9 d        2 3 6 7
// 2 6 a e        8 9 c d
// 3 7 b f        a b e f
localparam logic [15:0][3:0] REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h4, 4'h1, 4'h5, 4'h8, 4'hc, 4'h9, 4'hd, 4'h2, 4'h6, 4'h3, 4'h7, 4'ha, 4'he, 4'hb, 4'hf};
localparam logic [15:0][3:0] REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h2, 4'h8, 4'ha, 4'h1, 4'h3, 4'h9, 4'hb, 4'h4, 4'h6, 4'hc, 4'he, 4'h5, 4'h7, 4'hd, 4'hf};
//  0  8 10 18 20 28 30 38        0  1  4  5 10 11 14 15
//  1  9 11 19 21 29 31 39        2  3  6  7 12 13 16 17
//  2  a 12 1a 22 2a 32 3a        8  9  c  d 18 19 1c 1d
//  3  b 13 1b 23 2b 33 3b        a  b  e  f 1a 1b 1e 1f
//  4  c 14 1c 24 2c 34 3c       20 21 24 25 30 31 34 35
//  5  d 15 1d 25 2d 35 3d       22 23 26 27 32 33 36 37
//  6  e 16 1e 26 2e 36 3e       28 29 2c 2d 38 39 3c 3d
//  7  f 17 1f 27 2f 37 3f       2a 2b 2e 2f 3a 3b 3e 3f
localparam logic [63:0][5:0] REORDER_SCANIDX2_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h08, 6'h01, 6'h09, 6'h10, 6'h18, 6'h11, 6'h19, 6'h02, 6'h0a, 6'h03, 6'h0b, 6'h12, 6'h1a, 6'h13, 6'h1b, 
                              6'h20, 6'h28, 6'h21, 6'h29, 6'h30, 6'h38, 6'h31, 6'h39, 6'h22, 6'h2a, 6'h23, 6'h2b, 6'h32, 6'h3a, 6'h33, 6'h3b,
                              6'h04, 6'h0c, 6'h05, 6'h0d, 6'h14, 6'h1c, 6'h15, 6'h1d, 6'h06, 6'h0e, 6'h07, 6'h0f, 6'h16, 6'h1e, 6'h17, 6'h1f,
                              6'h24, 6'h2c, 6'h25, 6'h2d, 6'h34, 6'h3c, 6'h35, 6'h3d, 6'h26, 6'h2e, 6'h27, 6'h2f, 6'h36, 6'h3e, 6'h37, 6'h3f};
localparam logic [63:0][5:0] REORDER_SCANIDX2_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h02, 6'h08, 6'h0a, 6'h20, 6'h22, 6'h28, 6'h2a, 6'h01, 6'h03, 6'h09, 6'h0b, 6'h21, 6'h23, 6'h29, 6'h2b,
                              6'h04, 6'h06, 6'h0c, 6'h0e, 6'h24, 6'h26, 6'h2c, 6'h2e, 6'h05, 6'h07, 6'h0d, 6'h0f, 6'h25, 6'h27, 6'h2d, 6'h2f,
                              6'h10, 6'h12, 6'h18, 6'h1a, 6'h30, 6'h32, 6'h38, 6'h3a, 6'h11, 6'h13, 6'h19, 6'h1b, 6'h31, 6'h33, 6'h39, 6'h3b,
                              6'h14, 6'h16, 6'h1c, 6'h1e, 6'h34, 6'h36, 6'h3c, 6'h3e, 6'h15, 6'h17, 6'h1d, 6'h1f, 6'h35, 6'h37, 6'h3d, 6'h3f};

// context index
localparam logic [0:  2][9:0] CTXIDX_SAO_MERGE_LEFT_FLAG       = {   10'd0,   10'd1,  10'd2};
localparam logic [0:  2][9:0] CTXIDX_SAO_MERGE_UP_FLAG         = {   10'd3,   10'd4,  10'd5};
localparam logic [0:  2][9:0] CTXIDX_SAO_TYPE_IDX_LUMA         = {   10'd6,   10'd7,  10'd8};
localparam logic [0:  2][9:0] CTXIDX_SAO_TYPE_IDX_CHROMA       = {   10'd9,  10'd10,  10'd11};
localparam logic [0:  8][9:0] CTXIDX_SPLIT_CU_FLAG             = {  10'd12,  10'd13,  10'd14,  10'd15,  10'd16,  10'd17,  10'd18,  10'd19,  10'd20};
localparam logic [0:  2][9:0] CTXIDX_CU_TRANSQUANT_BYPASS_FLAG = {  10'd21,  10'd22,  10'd23};
localparam logic [0:  5][9:0] CTXIDX_CU_SKIP_FLAG              = {  10'd24,  10'd25,  10'd26,  10'd27,  10'd28,  10'd29};
localparam logic [0:  1][9:0] CTXIDX_PRED_MODE_FLAG            = {  10'd30,  10'd31};
localparam logic [0:  8][9:0] CTXIDX_PART_MODE                 = {  10'd32,  10'd33,  10'd34,  10'd35,  10'd36,  10'd37,  10'd38,  10'd39,  10'd40};
localparam logic [0:  2][9:0] CTXIDX_PREV_INTRA_LUMA_PRED_FLAG = {  10'd41,  10'd42,  10'd43};
localparam logic [0:  2][9:0] CTXIDX_INTRA_CHROMA_PRED_MODE    = {  10'd44,  10'd45,  10'd46};
localparam logic [0:  1][9:0] CTXIDX_RQT_ROOT_CBF              = {  10'd47,  10'd48};
localparam logic [0:  1][9:0] CTXIDX_MERGE_FLAG                = {  10'd49,  10'd50};
localparam logic [0:  1][9:0] CTXIDX_MERGE_IDX                 = {  10'd51,  10'd52};
localparam logic [0:  9][9:0] CTXIDX_INTER_PRED_IDC            = {  10'd53,  10'd54,  10'd55,  10'd56,  10'd57,  10'd58,  10'd59,  10'd60,  10'd61,  10'd62};
localparam logic [0:  3][9:0] CTXIDX_REF_IDX_L0                = {  10'd63,  10'd64,  10'd65,  10'd66};
localparam logic [0:  3][9:0] CTXIDX_REF_IDX_L1                = {  10'd67,  10'd68,  10'd69,  10'd70};
localparam logic [0:  1][9:0] CTXIDX_MVP_L0_FLAG               = {  10'd71,  10'd72};
localparam logic [0:  1][9:0] CTXIDX_MVP_L1_FLAG               = {  10'd73,  10'd74};
localparam logic [0:  8][9:0] CTXIDX_SPLIT_TRANSFORM_FLAG      = {  10'd75,  10'd76,  10'd77,  10'd78,  10'd79,  10'd80,  10'd81,  10'd82,  10'd83};
localparam logic [0:  5][9:0] CTXIDX_CBF_LUMA                  = {  10'd84,  10'd85,  10'd86,  10'd87,  10'd88,  10'd89};
localparam logic [0: 14][9:0] CTXIDX_CBF_CB                    = {  10'd90,  10'd91,  10'd92,  10'd93,  10'd94,  10'd95,  10'd96, 10'd97,  
                                                                    10'd98,  10'd99, 10'd100, 10'd101, 10'd102, 10'd103, 10'd104};
localparam logic [0: 14][9:0] CTXIDX_CBF_CR                    = { 10'd105, 10'd106, 10'd107, 10'd108, 10'd109, 10'd110, 10'd111, 10'd112, 
                                                                   10'd113, 10'd114, 10'd115, 10'd116, 10'd117, 10'd118, 10'd119};
localparam logic [0:  3][9:0] CTXIDX_ABS_MVD_GT0_FLAG          = { 10'd120, 10'd121, 10'd122, 10'd123}
localparam logic [0:  3][9:0] CTXIDX_ABS_MVD_GT1_FLAG          = { 10'd124, 10'd125, 10'd126, 10'd127};
localparam logic [0:  5][9:0] CTXIDX_CU_QP_DELTA_ABS           = { 10'd128, 10'd129, 10'd130, 10'd131, 10'd132, 10'd133};
localparam logic [0:  5][9:0] CTXIDX_TRANSFORM_SKIP_FLAG       = { 10'd134, 10'd135  10'd136, 10'd137, 10'd138, 10'd139};
localparam logic [0: 53][9:0] CTXIDX_LAST_SIG_COEFF_X_PREFIX   = { 10'd140, 10'd141, 10'd142, 10'd143, 10'd144, 10'd145, 10'd146, 10'd147, 
                                                                   10'd148, 10'd149, 10'd150, 10'd151, 10'd152, 10'd153, 10'd154, 10'd155, 
                                                                   10'd156, 10'd157, 10'd158, 10'd159, 10'd160, 10'd161, 10'd162, 10'd163, 
                                                                   10'd164, 10'd165, 10'd166, 10'd167, 10'd168, 10'd169, 10'd170, 10'd171, 
                                                                   10'd172, 10'd173, 10'd174, 10'd175, 10'd176, 10'd177, 10'd178, 10'd179, 
                                                                   10'd180, 10'd181, 10'd182, 10'd183, 10'd184, 10'd185, 10'd186, 10'd187, 
                                                                   10'd188, 10'd189, 10'd190, 10'd191, 10'd192, 10'd193}; 
localparam logic [0: 53][9:0] CTXIDX_LAST_SIG_COEFF_Y_PREFIX   = { 10'd194, 10'd195, 10'd196, 10'd197, 10'd198, 10'd199, 10'd200, 10'd201, 
                                                                   10'd202, 10'd203, 10'd204, 10'd205, 10'd206, 10'd207, 10'd208, 10'd209, 
                                                                   10'd210, 10'd211, 10'd212, 10'd213, 10'd214, 10'd215, 10'd216, 10'd217, 
                                                                   10'd218, 10'd219, 10'd220, 10'd221, 10'd222, 10'd223, 10'd224, 10'd225, 
                                                                   10'd226, 10'd227, 10'd228, 10'd229, 10'd230, 10'd231, 10'd232, 10'd233, 
                                                                   10'd234, 10'd235, 10'd236, 10'd237, 10'd238, 10'd239, 10'd240, 10'd241, 
                                                                   10'd242, 10'd243, 10'd244, 10'd245, 10'd246, 10'd247};
localparam logic [0: 11][9:0] CTXIDX_CODED_SUB_BLOCK_FLAG      = { 10'd248, 10'd249, 10'd250, 10'd251, 10'd252, 10'd253, 10'd254, 10'd255, 
                                                                   10'd256, 10'd257, 10'd258, 10'd259};
localparam logic [0:131][9:0] CTXIDX_SIG_COEFF_FLAG            = { 10'd260, 10'd261, 10'd262, 10'd263, 10'd264, 10'd265, 10'd266, 10'd267, 
                                                                   10'd268, 10'd269, 10'd270, 10'd271, 10'd272, 10'd273, 10'd274, 10'd275, 
                                                                   10'd276, 10'd277, 10'd278, 10'd279, 10'd280, 10'd281, 10'd282, 10'd283, 
                                                                   10'd284, 10'd285, 10'd286, 10'd287, 10'd288, 10'd289, 10'd290, 10'd291, 
                                                                   10'd292, 10'd293, 10'd294, 10'd295, 10'd296, 10'd297, 10'd298, 10'd299, 
                                                                   10'd300, 10'd301, 10'd302, 10'd303, 10'd304, 10'd305, 10'd306, 10'd307, 
                                                                   10'd308, 10'd309, 10'd310, 10'd311, 10'd312, 10'd313, 10'd314, 10'd315, 
                                                                   10'd316, 10'd317, 10'd318, 10'd319, 10'd320, 10'd321, 10'd322, 10'd323, 
                                                                   10'd324, 10'd325, 10'd326, 10'd327, 10'd328, 10'd329, 10'd330, 10'd331, 
                                                                   10'd332, 10'd333, 10'd334, 10'd335, 10'd336, 10'd337, 10'd338, 10'd339, 
                                                                   10'd340, 10'd341, 10'd342, 10'd343, 10'd344, 10'd345, 10'd346, 10'd347, 
                                                                   10'd348, 10'd349, 10'd350, 10'd351, 10'd352, 10'd353, 10'd354, 10'd355, 
                                                                   10'd356, 10'd357, 10'd358, 10'd359, 10'd360, 10'd361, 10'd362, 10'd363, 
                                                                   10'd364, 10'd365, 10'd366, 10'd367, 10'd368, 10'd369, 10'd370, 10'd371, 
                                                                   10'd372, 10'd373, 10'd374, 10'd375, 10'd376, 10'd377, 10'd378, 10'd379, 
                                                                   10'd380, 10'd381, 10'd382, 10'd383, 10'd384, 10'd385, 10'd386, 10'd387, 
                                                                   10'd388, 10'd389, 10'd390, 10'd391};
localparam logic [0: 71][9:0] CTXIDX_COEFF_ABS_LEVEL_GT1_FLAG  = { 10'd392, 10'd393, 10'd394, 10'd395, 10'd396, 10'd397, 10'd398, 10'd399, 
                                                                   10'd400, 10'd401, 10'd402, 10'd403, 10'd404, 10'd405, 10'd406, 10'd407, 
                                                                   10'd408, 10'd409, 10'd410, 10'd411, 10'd412, 10'd413, 10'd414, 10'd415, 
                                                                   10'd416, 10'd417, 10'd418, 10'd419, 10'd420, 10'd421, 10'd422, 10'd423, 
                                                                   10'd424, 10'd425, 10'd426, 10'd427, 10'd428, 10'd429, 10'd430, 10'd431, 
                                                                   10'd432, 10'd433, 10'd434, 10'd435, 10'd436, 10'd437, 10'd438, 10'd439, 
                                                                   10'd440, 10'd441, 10'd442, 10'd443, 10'd444, 10'd445, 10'd446, 10'd447, 
                                                                   10'd448, 10'd449, 10'd450, 10'd451, 10'd452, 10'd453, 10'd454, 10'd455, 
                                                                   10'd456, 10'd457, 10'd458, 10'd459, 10'd460, 10'd461, 10'd462, 10'd463};
localparam logic [0: 17][9:0] CTXIDX_COEFF_ABS_LEVEL_GT1_FLAG  = { 10'd464, 10'd465, 10'd466, 10'd467, 10'd468, 10'd469, 10'd470, 10'd471, 
                                                                   10'd472, 10'd473, 10'd474, 10'd475, 10'd476, 10'd477, 10'd478, 10'd479, 
                                                                   10'd480, 10'd481};
localparam logic [0:  3][9:0] CTXIDX_EXPLICIT_RDPCM_FLAG       = { 10'd482, 10'd483, 10'd484, 10'd485};
localparam logic [0:  3][9:0] CTXIDX_EXPLICIT_RDPCM_DIR_FLAG   = { 10'd486, 10'd487, 10'd488, 10'd489};
localparam logic [0:  2][9:0] CTXIDX_CHROMA_QP_OFFSET_FLAG     = { 10'd490, 10'd491, 10'd492};
localparam logic [0:  2][9:0] CTXIDX_CHROMA_QP_OFFSET_IDX      = { 10'd493, 10'd494, 10'd495};
localparam logic [0: 23][9:0] CTXIDX_LOG2_RES_SCALE_ABS_PLUS1  = { 10'd496, 10'd497, 10'd498, 10'd499, 10'd500, 10'd501, 10'd502, 10'd503, 
                                                                   10'd504, 10'd505, 10'd506, 10'd507, 10'd508, 10'd509, 10'd510, 10'd511, 
                                                                   10'd512, 10'd513, 10'd514, 10'd515, 10'd516, 10'd517, 10'd518, 10'd519};
localparam logic [0:  5][9:0] CTXIDX_RES_SCALE_SIGN_FLAG       = { 10'd520, 10'd521, 10'd522, 10'd523, 10'd524, 10'd525};
localparam logic [0:  2][9:0] CTXIDX_PALETTE_MODE_FLAG         = { 10'd526, 10'd527, 10'd528};
localparam logic [0:  2][9:0] CTXIDX_TU_RESIDUAL_ACT_FLAG      = { 10'd529, 10'd530, 10'd531};
localparam logic [0: 23][9:0] CTXIDX_PALETTE_RUN_PREFIX        = { 10'd532, 10'd533, 10'd534, 10'd535, 10'd536, 10'd537, 10'd538, 10'd539, 
                                                                   10'd540, 10'd541, 10'd542, 10'd543, 10'd544, 10'd545, 10'd546, 10'd547, 
                                                                   10'd548, 10'd549, 10'd550, 10'd551, 10'd552, 10'd553, 10'd554, 10'd555};
localparam logic [0:  2][9:0] CTXIDX_COPY_ABOVE_PALETTE_INDICES_FLAG = { 10'd556, 10'd557, 10'd558};
localparam logic [0:  2][9:0] CTXIDX_COPY_ABOVE_INDICES_FOR_FINAL_RUN_FLAG = { 10'd559, 10'd560, 10'd561};
localparam logic [0:  2][9:0] CTXIDX_PALETTE_TRANSPOSE_FLAG    = { 10'd562, 10'd563, 10'd564};

// Data format inside Line buffer
//
// Data format is fixed length 2200 bytes for a CTU, all aligned with bytes
// Store in ping-pong buffer style, two CTUs in a row
// For those signal separeted in matrix format, only record the left-up corner
// e.x. split flag work until 8x8, so only record (64/8)^2=64 flags
// sao
// sao_merge_left_flag, sao_merge_up_flag, sao_type_idx_luma, sao_type_idx_chroma 1
// sao_offset_luma[4] 4
// sao_offset_cb[4] 4
// sao_offset_cr[4] 4
// sao_band_position_luma 1
// sao_band_position_cb 1
// sao_band_position_cr 1
// sao_eo_class_luma, sao_eo_class_chroma 1
// top
// end_of_slice_segment_flag 1
// align_reserved 6
// cqt
// split_cu_flag_min8x8[64] 8
// cu
// cu_transquant_bypass_flag_min4x4[256] 32
// cu_skip_flag_min4x4[256] 32
// pred_mode_flag_min4x4[256] 32
// part_mode_min8x8[64] 32
// prev_intra_luma_pred_flag_min4x4[256] 32
// mpm_idx_min4x4[256] 64
// rem_intra_luma_pred_mode_min4x4[256] 256
// intra_chroma_pred_mode_min4x4[64] 32
// rqt_root_cbf_min4x4[256] 32
// pu
// merge_flag_min4x4[256] 32
// merge_idx_min4x4[256] 64
// inter_pred_idc_min4x4[256] 64
// ref_idx_l0_min4x4[256] 64
// ref_idx_l1_min4x4[256] 64
// mvp_l0_flag_min4x4[256] 32
// mvp_l1_flag_min4x4[256] 32
// mvd
// mvd_l0_min4x4[256] 256
// mvd_l1_min4x4[256] 256
// trafo
// split_transform_flag_min8x8[64] 8
// cbf_cb_min4x4[64] 8
// cbf_cr_min4x4[64] 8
// cbf_luma_min4x4[256] 32
// dqp
// qp_delta_min4x4[256] 256
// cqp
// chroma_qp_offset_min4x4[64] 16
// res
// transform_skip_flag_y_min4x4[256] 32
// transform_skip_flag_cb_min4x4[64] 8
// transform_skip_flag_cr_min4x4[64] 8
// residual_y_min4x4[256] 256
// residual_cb_min4x4[64] 64
// residual_cr_min4x4[64] 64
localparam logic [11:0] LB_START_ADDR_SAO   = 0;
localparam logic [11:0] LB_START_ADDR_TOP   = 12;
localparam logic [11:0] LB_START_ADDR_CQT   = 16;
localparam logic [11:0] LB_START_ADDR_CU    = 24;
localparam logic [11:0] LB_START_ADDR_PU    = 568;
localparam logic [11:0] LB_START_ADDR_MVD   = 920;
localparam logic [11:0] LB_START_ADDR_TRAFO = 1432;
localparam logic [11:0] LB_START_ADDR_DQP   = 1488;
localparam logic [11:0] LB_START_ADDR_CQP   = 1744;
localparam logic [11:0] LB_START_ADDR_RES   = 1760;

// control register from parameter sets
typedef enum logic [31:0] {
    ADDR_CABAC_VPS_0                          = 32'h000,
    ADDR_CABAC_SPS_0                          = 32'h004,
    ADDR_CABAC_SPS_1                          = 32'h008,
    ADDR_CABAC_PPS_0                          = 32'h00c,
    ADDR_CABAC_SLICE_HEADER_0                 = 32'h010,
} t_CUTREE_ADDR_e;

parameter [31:0] reg_CABAC_VPS_0_MASK                           = 32'h0000000f;
parameter [31:0] reg_CABAC_SPS_0_MASK                           = 32'h0fffffff;
parameter [31:0] reg_CABAC_SPS_1_MASK                           = 32'h07ffffff;
parameter [31:0] reg_CABAC_PPS_0_MASK                           = 32'h0000ffff;
parameter [31:0] reg_CABAC_SLICE_HEADER_0_MASK                  = 32'h0000ffff;

typedef struct packed {
    logic [27:0]   rsvd0;
    logic [3:0]   vps_id;
} t_reg_CABAC_VPS_0_s;

typedef struct packed {
    logic [3:0]    rsvd0;
    logic [11:0]   widthByPix;
    logic [11:0]   heightByPix;
    logic [3:0]    sps_id;
} t_reg_CABAC_SPS_0_s;

typedef struct packed {
    logic [4:0]    rsvd0;
    logic [0:0]    PcmEnabledFlag;
    logic [0:0]    SaoEnabledFlag;
    logic [0:0]    ampEnabledFlag;
    logic [3:0]    MaxTrafoDepthIntra;
    logic [3:0]    MaxTrafoDepthInter;
    logic [3:0]    log2DiffMaxMinTbSize;
    logic [3:0]    log2MinTbSize;
    logic [3:0]    log2DiffMaxMinLumaCbSize;
    logic [3:0]    log2MinCbSize;
} t_reg_CABAC_SPS_1_s;

typedef struct packed {
    logic [15:0]   rsvd0;
    logic [3:0]    numRefL0;
    logic [3:0]    numRefL1;
    logic [0:0]    cuQpDeltaEnabledFlag;
    logic [0:0]    transformSkipEnabledFlag;
    logic [0:0]    cabacInitPresentFlag;
    logic [0:0]    signDataHidingFlag;
    logic [3:0]    pps_id;
} t_reg_CABAC_PPS_0_s;

typedef struct packed {
    logic [15:0]   rsvd0;
    logic [7:0]    slice_qp_delta;
    logic [0:0]    rsvd1;
    logic [2:0]    max_num_merge_cand;
    logic [0:0]    slice_sao_luma_flag;
    logic [0:0]    slice_sao_chroma_flag;
    logic [1:0]    slice_type;
} t_reg_CABAC_SLICE_HEADER_0_s;

typedef struct packed {
    t_reg_CABAC_VPS_0_s                                          reg_CABAC_VPS_0;
    t_reg_CABAC_SPS_0_s                                          reg_CABAC_SPS_0;
    t_reg_CABAC_SPS_1_s                                          reg_CABAC_SPS_1;
    t_reg_CABAC_PPS_0_s                                          reg_CABAC_PPS_0;
    t_reg_CABAC_SLICE_HEADER_0_s                                 reg_CABAC_SLICE_HEADER_0;
} t_CABAC_AO_s;

// Context init value
localparam logic [0:566][7:0] CTX_INIT_VALUE = {
  153, 153, 153, 153, 153, 153, 200, 185, 
  160, 200, 185, 160, 139, 141, 157, 107, 
  139, 126, 107, 139, 126, 154, 154, 154, 
  197, 185, 201, 197, 185, 201, 149, 134, 

  184, 154, 139, 154, 154, 154, 139, 154, 
  154, 184, 154, 183,  63, 152, 152,  79, 
   79, 110, 154, 122, 137,  95,  79,  63, 
   31,  31,  95,  79,  63,  31,  31, 153, 
  
  153, 153, 153, 153, 153, 153, 153, 168, 
  168, 168, 168, 153, 138, 138, 124, 138, 
   94, 224, 167, 122, 111, 141, 153, 111, 
  153, 111,  94, 138, 182, 154, 149, 107, 
  
  167, 154, 149,  92, 167, 154, 154, 154, 
  154,  94, 138, 182, 154, 149, 107, 167, 
  154, 149,  92, 167, 154, 154, 154, 154, 
  140, 198, 169, 198, 140, 198, 169, 198, 
  
  154, 154, 154, 154, 154, 154, 139, 139, 
  139, 139, 139, 139, 110, 110, 124, 125, 
  140, 153, 125, 127, 140, 109, 111, 143, 
  127, 111,  79, 108, 123,  63, 125, 110, 

   94, 110,  95,  79, 125, 111, 110,  78, 
  110, 111, 111,  95,  94, 108, 123, 108, 
  125, 110, 124, 110,  95,  94, 125, 111, 
  111,  79, 125, 126, 111, 111,  79, 108, 
  
  123,  93, 110, 110, 124, 125, 140, 153, 
  125, 127, 140, 109, 111, 143, 127, 111, 
   79, 108, 123,  63, 125, 110,  94, 110, 
   95,  79, 125, 111, 110,  78, 110, 111, 
  
  111,  95,  94, 108, 123, 108, 125, 110, 
  124, 110,  95,  94, 125, 111, 111,  79, 
  125, 126, 111, 111,  79, 108, 123,  93, 
   91, 171, 134, 141, 121, 140,  61, 154, 
  
  121, 140,  61, 154, 111, 111, 125, 110, 
  110,  94, 124, 108, 124, 107, 125, 141, 
  179, 153, 125, 107, 125, 141, 179, 153, 
  125, 107, 125, 141, 179, 153, 125, 140, 

  139, 182, 182, 152, 136, 152, 136, 153, 
  136, 139, 111, 136, 139, 111, 155, 154, 
  139, 153, 139, 123, 123,  63, 153, 166, 
  183, 140, 136, 153, 154, 166, 183, 140, 
  
  136, 153, 154, 166, 183, 140, 136, 153, 
  154, 170, 153, 123, 123, 107, 121, 107, 
  121, 167, 151, 183, 140, 151, 183, 140, 
  170, 154, 139, 153, 139, 123, 123,  63, 
  
  124, 166, 183, 140, 136, 153, 154, 166, 
  183, 140, 136, 153, 154, 166, 183, 140, 
  136, 153, 154, 170, 153, 138, 138, 122, 
  121, 122, 121, 167, 151, 183, 140, 151, 
  
  183, 140, 141, 111, 140, 140, 140, 140, 
  140,  92, 137, 138, 140, 152, 138, 139, 
  153,  74, 149,  92, 139, 107, 122, 152, 
  140, 179, 166, 182, 140, 227, 122, 197, 

  154, 196, 196, 167, 154, 152, 167, 182, 
  182, 134, 149, 136, 153, 121, 136, 137, 
  169, 194, 166, 167, 154, 167, 137, 182, 
  154, 196, 167, 167, 154, 152, 167, 182, 
  
  182, 134, 149, 136, 153, 121, 136, 122, 
  169, 208, 166, 167, 154, 152, 167, 182, 
  138, 153, 136, 167, 152, 152, 107, 167, 
   91, 122, 107, 167, 107, 167,  91, 107, 
  
  107, 167, 139, 139, 139, 139, 139, 139, 
  139, 139, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 

  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154, 154, 
  154, 154, 154, 154, 154, 154, 154
};

localparam logic [0:51][0:63][6:0] CTX_INIT_STATE_ROM = {
{
 81,  49,  81,   1,  65,  81,  17,  33, 
 49,  65,  81,  17,  33,  49,  65,  81, 
 14,   1,  17,  33,  49,  65,  81,  62, 
 30,  14,   1,  17,  33,  49,  81,  78, 
 46,  30,  14,   1,  17,  49, 124,  62, 
 46,  30,  14,   1,  17, 110,  62,  46, 
 30,  14, 124,  94,  78,  62,  30,  14, 
124, 124, 110,   0,   0,   0,   0,   0
},
{
 75,  45,  77,   2,  61,  77,  13,  29, 
 45,  61,  77,  15,  31,  47,  63,  79, 
 16,   0,  15,  31,  47,  63,  79,  64, 
 32,  16,   0,  15,  31,  47,  79,  78, 
 46,  30,  14,   1,  17,  49, 124,  62, 
 46,  30,  14,   1,  17, 110,  62,  46, 
 30,  14, 124,  94,  78,  62,  30,  14, 
124, 124, 108,   0,   0,   0,   0,   0
},
{
 71,  41,  73,   6,  57,  73,  11,  27, 
 43,  59,  75,  13,  29,  45,  61,  77, 
 18,   2,  13,  29,  45,  61,  77,  64, 
 32,  16,   0,  15,  31,  47,  79,  78, 
 46,  30,  14,   1,  17,  49, 124,  62, 
 46,  30,  14,   1,  17, 108,  60,  44, 
 28,  12, 124,  92,  76,  60,  28,  12, 
124, 124, 104,   0,   0,   0,   0,   0
},
{
 65,  37,  69,   8,  55,  71,   9,  25, 
 41,  57,  73,  11,  27,  43,  59,  75, 
 18,   2,  13,  29,  45,  61,  77,  64, 
 32,  16,   0,  15,  31,  47,  79,  78, 
 46,  30,  14,   1,  17,  49, 124,  62, 
 46,  30,  14,   1,  17, 108,  60,  44, 
 28,  12, 122,  90,  74,  58,  26,  10, 
124, 124, 102,   0,   0,   0,   0,   0
},
{
 61,  33,  65,  12,  51,  67,   7,  23, 
 39,  55,  71,   9,  25,  41,  57,  73, 
 20,   4,  11,  27,  43,  59,  75,  66, 
 34,  18,   2,  13,  29,  45,  77,  78, 
 46,  30,  14,   1,  17,  49, 124,  60, 
 44,  28,  12,   3,  19, 106,  58,  42, 
 26,  10, 120,  88,  72,  56,  24,   8, 
124, 124,  98,   0,   0,   0,   0,   0
},
{
 55,  29,  61,  14,  49,  65,   3,  19, 
 35,  51,  67,   7,  23,  39,  55,  71, 
 22,   6,   9,  25,  41,  57,  73,  66, 
 34,  18,   2,  13,  29,  45,  77,  78, 
 46,  30,  14,   1,  17,  49, 124,  60, 
 44,  28,  12,   3,  19, 104,  56,  40, 
 24,   8, 118,  86,  70,  54,  22,   6, 
124, 124,  96,   0,   0,   0,   0,   0
},
{
 51,  25,  57,  18,  45,  61,   1,  17, 
 33,  49,  65,   5,  21,  37,  53,  69, 
 22,   6,   9,  25,  41,  57,  73,  66, 
 34,  18,   2,  13,  29,  45,  77,  78, 
 46,  30,  14,   1,  17,  49, 124,  60, 
 44,  28,  12,   3,  19, 104,  56,  40, 
 24,   8, 116,  84,  68,  52,  20,   4, 
124, 124,  92,   0,   0,   0,   0,   0
},
{
 45,  21,  53,  20,  43,  59,   0,  15, 
 31,  47,  63,   3,  19,  35,  51,  67, 
 24,   8,   7,  23,  39,  55,  71,  68, 
 36,  20,   4,  11,  27,  43,  75,  78, 
 46,  30,  14,   1,  17,  49, 124,  58, 
 42,  26,  10,   5,  21, 102,  54,  38, 
 22,   6, 114,  82,  66,  50,  18,   2, 
124, 124,  90,   0,   0,   0,   0,   0
},
{
 41,  19,  51,  24,  39,  55,   2,  13, 
 29,  45,  61,   1,  17,  33,  49,  65, 
 24,   8,   7,  23,  39,  55,  71,  68, 
 36,  20,   4,  11,  27,  43,  75,  78, 
 46,  30,  14,   1,  17,  49, 124,  58, 
 42,  26,  10,   5,  21, 100,  52,  36, 
 20,   4, 112,  80,  64,  48,  16,   0, 
124, 124,  86,   0,   0,   0,   0,   0
},
{
 35,  15,  47,  28,  35,  51,   6,   9, 
 25,  41,  57,   0,  15,  31,  47,  63, 
 26,  10,   5,  21,  37,  53,  69,  68, 
 36,  20,   4,  11,  27,  43,  75,  78, 
 46,  30,  14,   1,  17,  49, 124,  58, 
 42,  26,  10,   5,  21, 100,  52,  36, 
 20,   4, 110,  78,  62,  46,  14,   1, 
124, 124,  82,   0,   0,   0,   0,   0
},
{
 31,  11,  43,  30,  33,  49,   8,   7, 
 23,  39,  55,   2,  13,  29,  45,  61, 
 28,  12,   3,  19,  35,  51,  67,  70, 
 38,  22,   6,   9,  25,  41,  73,  78, 
 46,  30,  14,   1,  17,  49, 124,  56, 
 40,  24,   8,   7,  23,  98,  50,  34, 
 18,   2, 108,  76,  60,  44,  12,   3, 
124, 124,  80,   0,   0,   0,   0,   0
},
{
 25,   7,  39,  34,  29,  45,  10,   5, 
 21,  37,  53,   4,  11,  27,  43,  59, 
 28,  12,   3,  19,  35,  51,  67,  70, 
 38,  22,   6,   9,  25,  41,  73,  78, 
 46,  30,  14,   1,  17,  49, 124,  56, 
 40,  24,   8,   7,  23,  98,  50,  34, 
 18,   2, 106,  74,  58,  42,  10,   5, 
124, 124,  76,   0,   0,   0,   0,   0
},
{
 21,   3,  35,  36,  27,  43,  12,   3, 
 19,  35,  51,   6,   9,  25,  41,  57, 
 30,  14,   1,  17,  33,  49,  65,  70, 
 38,  22,   6,   9,  25,  41,  73,  78, 
 46,  30,  14,   1,  17,  49, 124,  56, 
 40,  24,   8,   7,  23,  96,  48,  32, 
 16,   0, 104,  72,  56,  40,   8,   7, 
124, 122,  74,   0,   0,   0,   0,   0
},
{
 15,   0,  31,  40,  23,  39,  16,   0, 
 15,  31,  47,   8,   7,  23,  39,  55, 
 32,  16,   0,  15,  31,  47,  63,  72, 
 40,  24,   8,   7,  23,  39,  71,  78, 
 46,  30,  14,   1,  17,  49, 124,  54, 
 38,  22,   6,   9,  25,  94,  46,  30, 
 14,   1, 102,  70,  54,  38,   6,   9, 
124, 118,  70,   0,   0,   0,   0,   0
},
{
 11,   4,  27,  42,  21,  37,  18,   2, 
 13,  29,  45,  10,   5,  21,  37,  53, 
 32,  16,   0,  15,  31,  47,  63,  72, 
 40,  24,   8,   7,  23,  39,  71,  78, 
 46,  30,  14,   1,  17,  49, 124,  54, 
 38,  22,   6,   9,  25,  94,  46,  30, 
 14,   1, 100,  68,  52,  36,   4,  11, 
124, 116,  68,   0,   0,   0,   0,   0
},
{
  5,   8,  23,  46,  17,  33,  20,   4, 
 11,  27,  43,  12,   3,  19,  35,  51, 
 34,  18,   2,  13,  29,  45,  61,  72, 
 40,  24,   8,   7,  23,  39,  71,  78, 
 46,  30,  14,   1,  17,  49, 124,  54, 
 38,  22,   6,   9,  25,  92,  44,  28, 
 12,   3,  98,  66,  50,  34,   2,  13, 
122, 112,  64,   0,   0,   0,   0,   0
},
{
  1,  10,  21,  48,  15,  31,  22,   6, 
  9,  25,  41,  12,   3,  19,  35,  51, 
 34,  18,   2,  13,  29,  45,  61,  72, 
 40,  24,   8,   7,  23,  39,  71,  78, 
 46,  30,  14,   1,  17,  49, 124,  52, 
 36,  20,   4,  11,  27,  90,  42,  26, 
 10,   5,  96,  64,  48,  32,   0,  15, 
118, 108,  60,   0,   0,   0,   0,   0
},
{
  4,  14,  17,  52,  11,  27,  26,  10, 
  5,  21,  37,  14,   1,  17,  33,  49, 
 36,  20,   4,  11,  27,  43,  59,  74, 
 42,  26,  10,   5,  21,  37,  69,  78, 
 46,  30,  14,   1,  17,  49, 124,  52, 
 36,  20,   4,  11,  27,  90,  42,  26, 
 10,   5,  96,  64,  48,  32,   0,  15, 
116, 106,  58,   0,   0,   0,   0,   0
},
{
  8,  18,  13,  56,   7,  23,  28,  12, 
  3,  19,  35,  16,   0,  15,  31,  47, 
 38,  22,   6,   9,  25,  41,  57,  74, 
 42,  26,  10,   5,  21,  37,  69,  78, 
 46,  30,  14,   1,  17,  49, 124,  52, 
 36,  20,   4,  11,  27,  88,  40,  24, 
  8,   7,  94,  62,  46,  30,   1,  17, 
114, 102,  54,   0,   0,   0,   0,   0
},
{
 14,  22,   9,  58,   5,  21,  30,  14, 
  1,  17,  33,  18,   2,  13,  29,  45, 
 38,  22,   6,   9,  25,  41,  57,  74, 
 42,  26,  10,   5,  21,  37,  69,  78, 
 46,  30,  14,   1,  17,  49, 124,  52, 
 36,  20,   4,  11,  27,  88,  40,  24, 
  8,   7,  92,  60,  44,  28,   3,  19, 
112, 100,  52,   0,   0,   0,   0,   0
},
{
 18,  26,   5,  62,   1,  17,  32,  16, 
  0,  15,  31,  20,   4,  11,  27,  43, 
 40,  24,   8,   7,  23,  39,  55,  76, 
 44,  28,  12,   3,  19,  35,  67,  78, 
 46,  30,  14,   1,  17,  49, 124,  50, 
 34,  18,   2,  13,  29,  86,  38,  22, 
  6,   9,  90,  58,  42,  26,   5,  21, 
108,  96,  48,   0,   0,   0,   0,   0
},
{
 24,  30,   1,  64,   0,  15,  36,  20, 
  4,  11,  27,  22,   6,   9,  25,  41, 
 42,  26,  10,   5,  21,  37,  53,  76, 
 44,  28,  12,   3,  19,  35,  67,  78, 
 46,  30,  14,   1,  17,  49, 124,  50, 
 34,  18,   2,  13,  29,  84,  36,  20, 
  4,  11,  88,  56,  40,  24,   7,  23, 
106,  94,  46,   0,   0,   0,   0,   0
},
{
 28,  34,   2,  68,   4,  11,  38,  22, 
  6,   9,  25,  24,   8,   7,  23,  39, 
 42,  26,  10,   5,  21,  37,  53,  76, 
 44,  28,  12,   3,  19,  35,  67,  78, 
 46,  30,  14,   1,  17,  49, 124,  50, 
 34,  18,   2,  13,  29,  84,  36,  20, 
  4,  11,  86,  54,  38,  22,   9,  25, 
104,  90,  42,   0,   0,   0,   0,   0
},
{
 34,  38,   6,  70,   6,   9,  40,  24, 
  8,   7,  23,  26,  10,   5,  21,  37, 
 44,  28,  12,   3,  19,  35,  51,  78, 
 46,  30,  14,   1,  17,  33,  65,  78, 
 46,  30,  14,   1,  17,  49, 124,  48, 
 32,  16,   0,  15,  31,  82,  34,  18, 
  2,  13,  84,  52,  36,  20,  11,  27, 
102,  88,  40,   0,   0,   0,   0,   0
},
{
 38,  40,   8,  74,  10,   5,  42,  26, 
 10,   5,  21,  28,  12,   3,  19,  35, 
 44,  28,  12,   3,  19,  35,  51,  78, 
 46,  30,  14,   1,  17,  33,  65,  78, 
 46,  30,  14,   1,  17,  49, 124,  48, 
 32,  16,   0,  15,  31,  80,  32,  16, 
  0,  15,  82,  50,  34,  18,  13,  29, 
 98,  84,  36,   0,   0,   0,   0,   0
},
{
 44,  44,  12,  78,  14,   1,  46,  30, 
 14,   1,  17,  30,  14,   1,  17,  33, 
 46,  30,  14,   1,  17,  33,  49,  78, 
 46,  30,  14,   1,  17,  33,  65,  78, 
 46,  30,  14,   1,  17,  49, 124,  48, 
 32,  16,   0,  15,  31,  80,  32,  16, 
  0,  15,  80,  48,  32,  16,  15,  31, 
 96,  80,  32,   0,   0,   0,   0,   0
},
{
 48,  48,  16,  80,  16,   0,  48,  32, 
 16,   0,  15,  32,  16,   0,  15,  31, 
 48,  32,  16,   0,  15,  31,  47,  80, 
 48,  32,  16,   0,  15,  31,  63,  78, 
 46,  30,  14,   1,  17,  49, 124,  46, 
 30,  14,   1,  17,  33,  78,  30,  14, 
  1,  17,  78,  46,  30,  14,  17,  33, 
 94,  78,  30,   0,   0,   0,   0,   0
},
{
 54,  52,  20,  84,  20,   4,  50,  34, 
 18,   2,  13,  34,  18,   2,  13,  29, 
 48,  32,  16,   0,  15,  31,  47,  80, 
 48,  32,  16,   0,  15,  31,  63,  78, 
 46,  30,  14,   1,  17,  49, 124,  46, 
 30,  14,   1,  17,  33,  78,  30,  14, 
  1,  17,  76,  44,  28,  12,  19,  35, 
 92,  74,  26,   0,   0,   0,   0,   0
},
{
 58,  56,  24,  86,  22,   6,  52,  36, 
 20,   4,  11,  36,  20,   4,  11,  27, 
 50,  34,  18,   2,  13,  29,  45,  80, 
 48,  32,  16,   0,  15,  31,  63,  78, 
 46,  30,  14,   1,  17,  49, 124,  46, 
 30,  14,   1,  17,  33,  76,  28,  12, 
  3,  19,  74,  42,  26,  10,  21,  37, 
 88,  72,  24,   0,   0,   0,   0,   0
},
{
 64,  60,  28,  90,  26,  10,  56,  40, 
 24,   8,   7,  38,  22,   6,   9,  25, 
 52,  36,  20,   4,  11,  27,  43,  82, 
 50,  34,  18,   2,  13,  29,  61,  78, 
 46,  30,  14,   1,  17,  49, 124,  44, 
 28,  12,   3,  19,  35,  74,  26,  10, 
  5,  21,  72,  40,  24,   8,  23,  39, 
 86,  68,  20,   0,   0,   0,   0,   0
},
{
 68,  64,  32,  92,  28,  12,  58,  42, 
 26,  10,   5,  40,  24,   8,   7,  23, 
 52,  36,  20,   4,  11,  27,  43,  82, 
 50,  34,  18,   2,  13,  29,  61,  78, 
 46,  30,  14,   1,  17,  49, 124,  44, 
 28,  12,   3,  19,  35,  74,  26,  10, 
  5,  21,  70,  38,  22,   6,  25,  41, 
 84,  66,  18,   0,   0,   0,   0,   0
},
{
 74,  68,  36,  96,  32,  16,  60,  44, 
 28,  12,   3,  42,  26,  10,   5,  21, 
 54,  38,  22,   6,   9,  25,  41,  82, 
 50,  34,  18,   2,  13,  29,  61,  78, 
 46,  30,  14,   1,  17,  49, 124,  44, 
 28,  12,   3,  19,  35,  72,  24,   8, 
  7,  23,  68,  36,  20,   4,  27,  43, 
 82,  62,  14,   0,   0,   0,   0,   0
},
{
 78,  70,  38,  98,  34,  18,  62,  46, 
 30,  14,   1,  42,  26,  10,   5,  21, 
 54,  38,  22,   6,   9,  25,  41,  82, 
 50,  34,  18,   2,  13,  29,  61,  78, 
 46,  30,  14,   1,  17,  49, 124,  42, 
 26,  10,   5,  21,  37,  70,  22,   6, 
  9,  25,  66,  34,  18,   2,  29,  45, 
 78,  58,  10,   0,   0,   0,   0,   0
},
{
 84,  74,  42, 102,  38,  22,  66,  50, 
 34,  18,   2,  44,  28,  12,   3,  19, 
 56,  40,  24,   8,   7,  23,  39,  84, 
 52,  36,  20,   4,  11,  27,  59,  78, 
 46,  30,  14,   1,  17,  49, 124,  42, 
 26,  10,   5,  21,  37,  70,  22,   6, 
  9,  25,  66,  34,  18,   2,  29,  45, 
 76,  56,   8,   0,   0,   0,   0,   0
},
{
 88,  78,  46, 106,  42,  26,  68,  52, 
 36,  20,   4,  46,  30,  14,   1,  17, 
 58,  42,  26,  10,   5,  21,  37,  84, 
 52,  36,  20,   4,  11,  27,  59,  78, 
 46,  30,  14,   1,  17,  49, 124,  42, 
 26,  10,   5,  21,  37,  68,  20,   4, 
 11,  27,  64,  32,  16,   0,  31,  47, 
 74,  52,   4,   0,   0,   0,   0,   0
},
{
 94,  82,  50, 108,  44,  28,  70,  54, 
 38,  22,   6,  48,  32,  16,   0,  15, 
 58,  42,  26,  10,   5,  21,  37,  84, 
 52,  36,  20,   4,  11,  27,  59,  78, 
 46,  30,  14,   1,  17,  49, 124,  42, 
 26,  10,   5,  21,  37,  68,  20,   4, 
 11,  27,  62,  30,  14,   1,  33,  49, 
 72,  50,   2,   0,   0,   0,   0,   0
},
{
 98,  86,  54, 112,  48,  32,  72,  56, 
 40,  24,   8,  50,  34,  18,   2,  13, 
 60,  44,  28,  12,   3,  19,  35,  86, 
 54,  38,  22,   6,   9,  25,  57,  78, 
 46,  30,  14,   1,  17,  49, 124,  40, 
 24,   8,   7,  23,  39,  66,  18,   2, 
 13,  29,  60,  28,  12,   3,  35,  51, 
 68,  46,   1,   0,   0,   0,   0,   0
},
{
104,  90,  58, 114,  50,  34,  76,  60, 
 44,  28,  12,  52,  36,  20,   4,  11, 
 62,  46,  30,  14,   1,  17,  33,  86, 
 54,  38,  22,   6,   9,  25,  57,  78, 
 46,  30,  14,   1,  17,  49, 124,  40, 
 24,   8,   7,  23,  39,  64,  16,   0, 
 15,  31,  58,  26,  10,   5,  37,  53, 
 66,  44,   3,   0,   0,   0,   0,   0
},
{
108,  94,  62, 118,  54,  38,  78,  62, 
 46,  30,  14,  54,  38,  22,   6,   9, 
 62,  46,  30,  14,   1,  17,  33,  86, 
 54,  38,  22,   6,   9,  25,  57,  78, 
 46,  30,  14,   1,  17,  49, 124,  40, 
 24,   8,   7,  23,  39,  64,  16,   0, 
 15,  31,  56,  24,   8,   7,  39,  55, 
 64,  40,   7,   0,   0,   0,   0,   0
},
{
114,  98,  66, 120,  56,  40,  80,  64, 
 48,  32,  16,  56,  40,  24,   8,   7, 
 64,  48,  32,  16,   0,  15,  31,  88, 
 56,  40,  24,   8,   7,  23,  55,  78, 
 46,  30,  14,   1,  17,  49, 124,  38, 
 22,   6,   9,  25,  41,  62,  14,   1, 
 17,  33,  54,  22,   6,   9,  41,  57, 
 62,  38,   9,   0,   0,   0,   0,   0
},
{
118, 100,  68, 124,  60,  44,  82,  66, 
 50,  34,  18,  58,  42,  26,  10,   5, 
 64,  48,  32,  16,   0,  15,  31,  88, 
 56,  40,  24,   8,   7,  23,  55,  78, 
 46,  30,  14,   1,  17,  49, 124,  38, 
 22,   6,   9,  25,  41,  60,  12,   3, 
 19,  35,  52,  20,   4,  11,  43,  59, 
 58,  34,  13,   0,   0,   0,   0,   0
},
{
124, 104,  72, 124,  64,  48,  86,  70, 
 54,  38,  22,  60,  44,  28,  12,   3, 
 66,  50,  34,  18,   2,  13,  29,  88, 
 56,  40,  24,   8,   7,  23,  55,  78, 
 46,  30,  14,   1,  17,  49, 124,  38, 
 22,   6,   9,  25,  41,  60,  12,   3, 
 19,  35,  50,  18,   2,  13,  45,  61, 
 56,  30,  17,   0,   0,   0,   0,   0
},
{
124, 108,  76, 124,  66,  50,  88,  72, 
 56,  40,  24,  62,  46,  30,  14,   1, 
 68,  52,  36,  20,   4,  11,  27,  90, 
 58,  42,  26,  10,   5,  21,  53,  78, 
 46,  30,  14,   1,  17,  49, 124,  36, 
 20,   4,  11,  27,  43,  58,  10,   5, 
 21,  37,  48,  16,   0,  15,  47,  63, 
 54,  28,  19,   0,   0,   0,   0,   0
},
{
124, 112,  80, 124,  70,  54,  90,  74, 
 58,  42,  26,  64,  48,  32,  16,   0, 
 68,  52,  36,  20,   4,  11,  27,  90, 
 58,  42,  26,  10,   5,  21,  53,  78, 
 46,  30,  14,   1,  17,  49, 124,  36, 
 20,   4,  11,  27,  43,  58,  10,   5, 
 21,  37,  46,  14,   1,  17,  49,  65, 
 52,  24,  23,   0,   0,   0,   0,   0
},
{
124, 116,  84, 124,  72,  56,  92,  76, 
 60,  44,  28,  66,  50,  34,  18,   2, 
 70,  54,  38,  22,   6,   9,  25,  90, 
 58,  42,  26,  10,   5,  21,  53,  78, 
 46,  30,  14,   1,  17,  49, 124,  36, 
 20,   4,  11,  27,  43,  56,   8,   7, 
 23,  39,  44,  12,   3,  19,  51,  67, 
 48,  22,  25,   0,   0,   0,   0,   0
},
{
124, 120,  88, 124,  76,  60,  96,  80, 
 64,  48,  32,  68,  52,  36,  20,   4, 
 72,  56,  40,  24,   8,   7,  23,  92, 
 60,  44,  28,  12,   3,  19,  51,  78, 
 46,  30,  14,   1,  17,  49, 124,  34, 
 18,   2,  13,  29,  45,  54,   6,   9, 
 25,  41,  42,  10,   5,  21,  53,  69, 
 46,  18,  29,   0,   0,   0,   0,   0
},
{
124, 124,  92, 124,  78,  62,  98,  82, 
 66,  50,  34,  70,  54,  38,  22,   6, 
 72,  56,  40,  24,   8,   7,  23,  92, 
 60,  44,  28,  12,   3,  19,  51,  78, 
 46,  30,  14,   1,  17,  49, 124,  34, 
 18,   2,  13,  29,  45,  54,   6,   9, 
 25,  41,  40,   8,   7,  23,  55,  71, 
 44,  16,  31,   0,   0,   0,   0,   0
},
{
124, 124,  96, 124,  82,  66, 100,  84, 
 68,  52,  36,  72,  56,  40,  24,   8, 
 74,  58,  42,  26,  10,   5,  21,  92, 
 60,  44,  28,  12,   3,  19,  51,  78, 
 46,  30,  14,   1,  17,  49, 124,  34, 
 18,   2,  13,  29,  45,  52,   4,  11, 
 27,  43,  38,   6,   9,  25,  57,  73, 
 42,  12,  35,   0,   0,   0,   0,   0
},
{
124, 124,  98, 124,  84,  68, 102,  86, 
 70,  54,  38,  72,  56,  40,  24,   8, 
 74,  58,  42,  26,  10,   5,  21,  92, 
 60,  44,  28,  12,   3,  19,  51,  78, 
 46,  30,  14,   1,  17,  49, 124,  32, 
 16,   0,  15,  31,  47,  50,   2,  13, 
 29,  45,  36,   4,  11,  27,  59,  75, 
 38,   8,  39,   0,   0,   0,   0,   0
},
{
124, 124, 102, 124,  88,  72, 106,  90, 
 74,  58,  42,  74,  58,  42,  26,  10, 
 76,  60,  44,  28,  12,   3,  19,  94, 
 62,  46,  30,  14,   1,  17,  49,  78, 
 46,  30,  14,   1,  17,  49, 124,  32, 
 16,   0,  15,  31,  47,  50,   2,  13, 
 29,  45,  36,   4,  11,  27,  59,  75, 
 36,   6,  41,   0,   0,   0,   0,   0
},
{
124, 124, 106, 124,  92,  76, 108,  92, 
 76,  60,  44,  76,  60,  44,  28,  12, 
 78,  62,  46,  30,  14,   1,  17,  94, 
 62,  46,  30,  14,   1,  17,  49,  78, 
 46,  30,  14,   1,  17,  49, 124,  32, 
 16,   0,  15,  31,  47,  48,   0,  15, 
 31,  47,  34,   2,  13,  29,  61,  77, 
 34,   2,  45,   0,   0,   0,   0,   0
},
{
124, 124, 110, 124,  94,  78, 110,  94, 
 78,  62,  46,  78,  62,  46,  30,  14, 
 78,  62,  46,  30,  14,   1,  17,  94, 
 62,  46,  30,  14,   1,  17,  49,  78, 
 46,  30,  14,   1,  17,  49, 124,  32, 
 16,   0,  15,  31,  47,  48,   0,  15, 
 31,  47,  32,   0,  15,  31,  63,  79, 
 32,   0,  47,   0,   0,   0,   0,   0
}
};

parameter  logic   [0:63][0:3][7:0]   AUC_LPS_TABLE= {
  { 128, 176, 208, 240},
  { 128, 167, 197, 227},
  { 128, 158, 187, 216},
  { 123, 150, 178, 205},
  { 116, 142, 169, 195},
  { 111, 135, 160, 185},
  { 105, 128, 152, 175},
  { 100, 122, 144, 166},
  {  95, 116, 137, 158},
  {  90, 110, 130, 150},
  {  85, 104, 123, 142},
  {  81,  99, 117, 135},
  {  77,  94, 111, 128},
  {  73,  89, 105, 122},
  {  69,  85, 100, 116},
  {  66,  80,  95, 110},
  {  62,  76,  90, 104},
  {  59,  72,  86,  99},
  {  56,  69,  81,  94},
  {  53,  65,  77,  89},
  {  51,  62,  73,  85},
  {  48,  59,  69,  80},
  {  46,  56,  66,  76},
  {  43,  53,  63,  72},
  {  41,  50,  59,  69},
  {  39,  48,  56,  65},
  {  37,  45,  54,  62},
  {  35,  43,  51,  59},
  {  33,  41,  48,  56},
  {  32,  39,  46,  53},
  {  30,  37,  43,  50},
  {  29,  35,  41,  48},
  {  27,  33,  39,  45},
  {  26,  31,  37,  43},
  {  24,  30,  35,  41},
  {  23,  28,  33,  39},
  {  22,  27,  32,  37},
  {  21,  26,  30,  35},
  {  20,  24,  29,  33},
  {  19,  23,  27,  31},
  {  18,  22,  26,  30},
  {  17,  21,  25,  28},
  {  16,  20,  23,  27},
  {  15,  19,  22,  25},
  {  14,  18,  21,  24},
  {  14,  17,  20,  23},
  {  13,  16,  19,  22},
  {  12,  15,  18,  21},
  {  12,  14,  17,  20},
  {  11,  14,  16,  19},
  {  11,  13,  15,  18},
  {  10,  12,  15,  17},
  {  10,  12,  14,  16},
  {   9,  11,  13,  15},
  {   9,  11,  12,  14},
  {   8,  10,  12,  14},
  {   8,   9,  11,  13},
  {   7,   9,  11,  12},
  {   7,   9,  10,  12},
  {   7,   8,  10,  11},
  {   6,   8,   9,  11},
  {   6,   7,   9,  10},
  {   6,   7,   8,   9},
  {   2,   2,   2,   2}
};

parameter  logic   [0:63][0:3][2:0]   AUC_RENORM_TABLE= {
  {   1,   1,   1,   1},
  {   1,   1,   1,   1},
  {   1,   1,   1,   1},
  {   2,   1,   1,   1},
  {   2,   1,   1,   1},
  {   2,   1,   1,   1},
  {   2,   1,   1,   1},
  {   2,   2,   1,   1},
  {   2,   2,   1,   1},
  {   2,   2,   1,   1},
  {   2,   2,   2,   1},
  {   2,   2,   2,   1},
  {   2,   2,   2,   1},
  {   2,   2,   2,   2},
  {   2,   2,   2,   2},
  {   2,   2,   2,   2},
  {   3,   2,   2,   2},
  {   3,   2,   2,   2},
  {   3,   2,   2,   2},
  {   3,   2,   2,   2},
  {   3,   3,   2,   2},
  {   3,   3,   2,   2},
  {   3,   3,   2,   2},
  {   3,   3,   3,   2},
  {   3,   3,   3,   2},
  {   3,   3,   3,   2},
  {   3,   3,   3,   3},
  {   3,   3,   3,   3},
  {   3,   3,   3,   3},
  {   3,   3,   3,   3},
  {   4,   3,   3,   3},
  {   4,   3,   3,   3},
  {   4,   3,   3,   3},
  {   4,   4,   3,   3},
  {   4,   4,   3,   3},
  {   4,   4,   3,   3},
  {   4,   4,   3,   3},
  {   4,   4,   4,   3},
  {   4,   4,   4,   3},
  {   4,   4,   4,   4},
  {   4,   4,   4,   4},
  {   4,   4,   4,   4},
  {   4,   4,   4,   4},
  {   5,   4,   4,   4},
  {   5,   4,   4,   4},
  {   5,   4,   4,   4},
  {   5,   4,   4,   4},
  {   5,   5,   4,   4},
  {   5,   5,   4,   4},
  {   5,   5,   4,   4},
  {   5,   5,   5,   4},
  {   5,   5,   5,   4},
  {   5,   5,   5,   4},
  {   5,   5,   5,   5},
  {   5,   5,   5,   5},
  {   5,   5,   5,   5},
  {   5,   5,   5,   5},
  {   6,   5,   5,   5},
  {   6,   5,   5,   5},
  {   6,   5,   5,   5},
  {   6,   5,   5,   5},
  {   6,   6,   5,   5},
  {   6,   6,   5,   5},
  {   6,   6,   6,   6}
};


// // After analyzing
// // numBits_lps = 1, uiLPS >= 128
// //               2, 64 <= uiLPS < 128
// //               3, 32 <= uiLPS < 64
// //               4, 16 <= uiLPS < 32
// //               5, 8  <= uiLPS < 16
// //               6, 0  <= uiLPS < 8
// // So directly transform this table to be based on state and uiRange
// parameter  logic   [0:31][2:0]   AUC_RENORM_TABLE= {
//   6,  5,  4,  4,
//   3,  3,  3,  3,
//   2,  2,  2,  2,
//   2,  2,  2,  2,
//   1,  1,  1,  1,
//   1,  1,  1,  1,
//   1,  1,  1,  1,
//   1,  1,  1,  1
// };

parameter  logic   [0:127][6:0]  AUC_NXT_STATE_MPS = {
  2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,  15,  16,  17,
  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,  32,  33,
  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,  48,  49,
  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,  63,  64,  65,
  66,  67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,  80,  81,
  82,  83,  84,  85,  86,  87,  88,  89,  90,  91,  92,  93,  94,  95,  96,  97,
  98,  99,  100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113,
  114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 124, 125, 126, 127
};

parameter  logic   [0:127][6:0]  AUC_NXT_STATE_LPS = {
  1,   0,   0,   1,   2,   3,   4,   5,   4,   5,   8,   9,   8,   9,   10,  11,
  12,  13,  14,  15,  16,  17,  18,  19,  18,  19,  22,  23,  22,  23,  24,  25,
  26,  27,  26,  27,  30,  31,  30,  31,  32,  33,  32,  33,  36,  37,  36,  37,
  38,  39,  38,  39,  42,  43,  42,  43,  44,  45,  44,  45,  46,  47,  48,  49,
  48,  49,  50,  51,  52,  53,  52,  53,  54,  55,  54,  55,  56,  57,  58,  59,
  58,  59,  60,  61,  60,  61,  60,  61,  62,  63,  64,  65,  64,  65,  66,  67,
  66,  67,  66,  67,  68,  69,  68,  69,  70,  71,  70,  71,  70,  71,  72,  73,
  72,  73,  72,  73,  74,  75,  74,  75,  74,  75,  76,  77,  76,  77,  126, 127
};

endpackage