// Package containing all LUT for arithmetic decoder
`ifndef IVERILOG
package qdec_cabac_package;
`endif

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
parameter  SLICE_TYPE_I = 2;
parameter  SLICE_TYPE_P = 1;
parameter  SLICE_TYPE_B = 0;

// pred mode flag
parameter  PRED_MODE_FLAG_INTER = 0;
parameter  PRED_MODE_FLAG_INTRA = 1;

// part mode
parameter  PART_MODE_INTRA_PART_2Nx2N = 0;
parameter  PART_MODE_INTRA_PART_NxN   = 1;
parameter  PART_MODE_INTER_PART_2Nx2N = 0;
parameter  PART_MODE_INTER_PART_2NxN  = 1;
parameter  PART_MODE_INTER_PART_Nx2N  = 2;
parameter  PART_MODE_INTER_PART_NxN   = 3;
parameter  PART_MODE_INTER_PART_2NxnU = 4;
parameter  PART_MODE_INTER_PART_2NxnD = 5;
parameter  PART_MODE_INTER_PART_nLx2N = 6;
parameter  PART_MODE_INTER_PART_nRx2N = 7;

// chroma array type
parameter  CHROMA_FORMAT_MONOCHROME         = 0;
parameter  CHROMA_FORMAT_420                = 1;
parameter  CHROMA_FORMAT_422                = 2;
parameter  CHROMA_FORMAT_444                = 3;
parameter  CHROMA_FORMAT_444_SEPARATE_COLOR = 4;

`ifdef IVERILOG
// sig coeff flag ctx id map
parameter  logic [4*15-1:0] SIG_COEFF_FLAG_CTXIDX_MAP = {4'd0, 4'd1, 4'd4, 4'd5, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd6, 4'd8, 4'd8, 4'd7, 4'd7, 4'd8};

// scan order
// scanIdx 0, diagonal
// 0 2     0 1
// 1 3     2 3
parameter  logic [4*2-1:0]  REORDER_SCANIDX0_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h2, 2'h1, 2'h3};
parameter  logic [4*2-1:0]  REORDER_SCANIDX0_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h2, 2'h1, 2'h3};
// 0 2 5 9        0 1 4 5
// 1 4 8 c        2 3 6 7
// 3 7 b e        8 9 c d
// 6 a d f        a b e f
parameter  logic [4*16-1:0] REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h2, 4'h1, 4'h4, 4'h5, 4'h9, 4'h8, 4'hc, 4'h3, 4'h7, 4'h6, 4'ha, 4'hb, 4'he, 4'hd, 4'hf};
parameter  logic [4*16-1:0] REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h2, 4'h1, 4'h8, 4'h3, 4'h4, 4'ha, 4'h9, 4'h6, 4'h5, 4'hb, 4'hc, 4'h7, 4'he, 4'hd, 4'hf};
//  0  2  5  9  e 14 1b 23        0  1  4  5 10 11 14 15
//  1  4  8  d 13 1a 22 2a        2  3  6  7 12 13 16 17
//  3  7  c 12 19 21 29 30        8  9  c  d 18 19 1c 1d
//  6  b 11 18 20 28 2f 35        a  b  e  f 1a 1b 1e 1f
//  a 10 17 1f 27 2e 34 39       20 21 24 25 30 31 34 35
//  f 16 1e 26 2d 33 38 3c       22 23 26 27 32 33 36 37
// 15 1d 25 2c 32 37 3b 3e       28 29 2c 2d 38 39 3c 3d
// 1c 24 2b 31 36 3a 3d 3f       2a 2b 2e 2f 3a 3b 3e 3f
parameter  logic [6*64-1:0] REORDER_SCANIDX0_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h02, 6'h01, 6'h04, 6'h05, 6'h09, 6'h08, 6'h0d, 6'h03, 6'h07, 6'h06, 6'h0b, 6'h0c, 6'h12, 6'h11, 6'h18, 
                              6'h0e, 6'h14, 6'h13, 6'h1a, 6'h1b, 6'h23, 6'h22, 6'h2a, 6'h19, 6'h21, 6'h20, 6'h28, 6'h29, 6'h30, 6'h2f, 6'h35,
                              6'h0a, 6'h10, 6'h0f, 6'h16, 6'h17, 6'h1f, 6'h1e, 6'h26, 6'h15, 6'h1d, 6'h1c, 6'h24, 6'h25, 6'h2c, 6'h2b, 6'h31,
                              6'h27, 6'h2e, 6'h2d, 6'h33, 6'h34, 6'h39, 6'h38, 6'h3c, 6'h32, 6'h37, 6'h36, 6'h3a, 6'h3b, 6'h3e, 6'h3d, 6'h3f};
parameter  logic [6*64-1:0] REORDER_SCANIDX0_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h02, 6'h01, 6'h08, 6'h03, 6'h04, 6'h0a, 6'h09, 6'h06, 6'h05, 6'h20, 6'h0b, 6'h0c, 6'h07, 6'h10, 6'h22, 
                              6'h21, 6'h0e, 6'h0d, 6'h12, 6'h11, 6'h28, 6'h23, 6'h24, 6'h0f, 6'h18, 6'h13, 6'h14, 6'h2a, 6'h29, 6'h26, 6'h25,
                              6'h1a, 6'h19, 6'h16, 6'h15, 6'h2b, 6'h2c, 6'h27, 6'h30, 6'h1b, 6'h1c, 6'h17, 6'h2e, 6'h2d, 6'h32, 6'h31, 6'h1e,
                              6'h1d, 6'h2f, 6'h38, 6'h33, 6'h34, 6'h1f, 6'h3a, 6'h39, 6'h36, 6'h35, 6'h3b, 6'h3c, 6'h37, 6'h3e, 6'h3d, 6'h3f};
// scanIdx 1, horizontal
// 0 1     0 1
// 2 3     2 3
parameter  logic [4*2-1:0]  REORDER_SCANIDX1_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h1, 2'h2, 2'h3};
parameter  logic [4*2-1:0]  REORDER_SCANIDX1_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h1, 2'h2, 2'h3};
// 0 1 2 3        0 1 4 5
// 4 5 6 7        2 3 6 7
// 8 9 a b        8 9 c d
// c d e f        a b e f
parameter  logic [16*4-1:0] REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h1, 4'h4, 4'h5, 4'h2, 4'h3, 4'h6, 4'h7, 4'h8, 4'h9, 4'hc, 4'hd, 4'ha, 4'hb, 4'he, 4'hf};
parameter  logic [16*4-1:0] REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h1, 4'h4, 4'h5, 4'h2, 4'h3, 4'h6, 4'h7, 4'h8, 4'h9, 4'hc, 4'hd, 4'ha, 4'hb, 4'he, 4'hf};
//  0  1  2  3  4  5  6  7        0  1  4  5 10 11 14 15
//  8  9  a  b  c  d  e  f        2  3  6  7 12 13 16 17
// 10 11 12 13 14 15 16 17        8  9  c  d 18 19 1c 1d
// 18 19 1a 1b 1c 1d 1e 1f        a  b  e  f 1a 1b 1e 1f
// 20 21 22 23 24 25 26 27       20 21 24 25 30 31 34 35
// 28 29 2a 2b 2c 2d 2e 2f       22 23 26 27 32 33 36 37
// 30 31 32 33 34 35 36 37       28 29 2c 2d 38 39 3c 3d
// 38 39 3a 3b 3c 3d 3e 3f       2a 2b 2e 2f 3a 3b 3e 3f
parameter  logic [64*6-1:0] REORDER_SCANIDX1_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h01, 6'h08, 6'h09, 6'h02, 6'h03, 6'h0a, 6'h0b, 6'h10, 6'h11, 6'h18, 6'h19, 6'h12, 6'h13, 6'h1a, 6'h1b,
                              6'h04, 6'h05, 6'h0c, 6'h0d, 6'h06, 6'h07, 6'h0e, 6'h0f, 6'h14, 6'h15, 6'h1c, 6'h1d, 6'h16, 6'h17, 6'h1e, 6'h1f,
                              6'h20, 6'h21, 6'h28, 6'h29, 6'h22, 6'h23, 6'h2a, 6'h2b, 6'h30, 6'h31, 6'h38, 6'h39, 6'h32, 6'h33, 6'h3a, 6'h3b,
                              6'h24, 6'h25, 6'h2c, 6'h2d, 6'h26, 6'h27, 6'h2e, 6'h2f, 6'h34, 6'h35, 6'h3c, 6'h3d, 6'h36, 6'h37, 6'h3e, 6'h3f};
parameter  logic [64*6-1:0] REORDER_SCANIDX1_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h01, 6'h04, 6'h05, 6'h10, 6'h11, 6'h14, 6'h15, 6'h02, 6'h03, 6'h06, 6'h07, 6'h12, 6'h13, 6'h16, 6'h17,
                              6'h08, 6'h09, 6'h0c, 6'h0d, 6'h18, 6'h19, 6'h1c, 6'h1d, 6'h0a, 6'h0b, 6'h0e, 6'h0f, 6'h1a, 6'h1b, 6'h1e, 6'h1f,
                              6'h20, 6'h21, 6'h24, 6'h25, 6'h30, 6'h31, 6'h34, 6'h35, 6'h22, 6'h23, 6'h26, 6'h27, 6'h32, 6'h33, 6'h36, 6'h37,
                              6'h28, 6'h29, 6'h2c, 6'h2d, 6'h38, 6'h39, 6'h3c, 6'h3d, 6'h2a, 6'h2b, 6'h2e, 6'h2f, 6'h3a, 6'h3b, 6'h3e, 6'h3f};
// scanIdx 2, vertical
// 0 2     0 1
// 1 3     2 3
parameter  logic [4*2-1:0]  REORDER_SCANIDX2_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h2, 2'h1, 2'h3};
parameter  logic [4*2-1:0]  REORDER_SCANIDX2_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h2, 2'h1, 2'h3};
// 0 4 8 c        0 1 4 5
// 1 5 9 d        2 3 6 7
// 2 6 a e        8 9 c d
// 3 7 b f        a b e f
parameter  logic [16*4-1:0] REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h4, 4'h1, 4'h5, 4'h8, 4'hc, 4'h9, 4'hd, 4'h2, 4'h6, 4'h3, 4'h7, 4'ha, 4'he, 4'hb, 4'hf};
parameter  logic [16*4-1:0] REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h2, 4'h8, 4'ha, 4'h1, 4'h3, 4'h9, 4'hb, 4'h4, 4'h6, 4'hc, 4'he, 4'h5, 4'h7, 4'hd, 4'hf};
//  0  8 10 18 20 28 30 38        0  1  4  5 10 11 14 15
//  1  9 11 19 21 29 31 39        2  3  6  7 12 13 16 17
//  2  a 12 1a 22 2a 32 3a        8  9  c  d 18 19 1c 1d
//  3  b 13 1b 23 2b 33 3b        a  b  e  f 1a 1b 1e 1f
//  4  c 14 1c 24 2c 34 3c       20 21 24 25 30 31 34 35
//  5  d 15 1d 25 2d 35 3d       22 23 26 27 32 33 36 37
//  6  e 16 1e 26 2e 36 3e       28 29 2c 2d 38 39 3c 3d
//  7  f 17 1f 27 2f 37 3f       2a 2b 2e 2f 3a 3b 3e 3f
parameter  logic [64*6-1:0] REORDER_SCANIDX2_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h08, 6'h01, 6'h09, 6'h10, 6'h18, 6'h11, 6'h19, 6'h02, 6'h0a, 6'h03, 6'h0b, 6'h12, 6'h1a, 6'h13, 6'h1b, 
                              6'h20, 6'h28, 6'h21, 6'h29, 6'h30, 6'h38, 6'h31, 6'h39, 6'h22, 6'h2a, 6'h23, 6'h2b, 6'h32, 6'h3a, 6'h33, 6'h3b,
                              6'h04, 6'h0c, 6'h05, 6'h0d, 6'h14, 6'h1c, 6'h15, 6'h1d, 6'h06, 6'h0e, 6'h07, 6'h0f, 6'h16, 6'h1e, 6'h17, 6'h1f,
                              6'h24, 6'h2c, 6'h25, 6'h2d, 6'h34, 6'h3c, 6'h35, 6'h3d, 6'h26, 6'h2e, 6'h27, 6'h2f, 6'h36, 6'h3e, 6'h37, 6'h3f};
parameter  logic [64*6-1:0] REORDER_SCANIDX2_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h02, 6'h08, 6'h0a, 6'h20, 6'h22, 6'h28, 6'h2a, 6'h01, 6'h03, 6'h09, 6'h0b, 6'h21, 6'h23, 6'h29, 6'h2b,
                              6'h04, 6'h06, 6'h0c, 6'h0e, 6'h24, 6'h26, 6'h2c, 6'h2e, 6'h05, 6'h07, 6'h0d, 6'h0f, 6'h25, 6'h27, 6'h2d, 6'h2f,
                              6'h10, 6'h12, 6'h18, 6'h1a, 6'h30, 6'h32, 6'h38, 6'h3a, 6'h11, 6'h13, 6'h19, 6'h1b, 6'h31, 6'h33, 6'h39, 6'h3b,
                              6'h14, 6'h16, 6'h1c, 6'h1e, 6'h34, 6'h36, 6'h3c, 6'h3e, 6'h15, 6'h17, 6'h1d, 6'h1f, 6'h35, 6'h37, 6'h3d, 6'h3f};

// context index
parameter  logic [  3*10-1:0] CTXIDX_SAO_MERGE_LEFT_FLAG       = {   10'd0,   10'd1,  10'd2};
parameter  logic [  3*10-1:0] CTXIDX_SAO_MERGE_UP_FLAG         = {   10'd3,   10'd4,  10'd5};
parameter  logic [  3*10-1:0] CTXIDX_SAO_TYPE_IDX_LUMA         = {   10'd6,   10'd7,  10'd8};
parameter  logic [  3*10-1:0] CTXIDX_SAO_TYPE_IDX_CHROMA       = {   10'd9,  10'd10,  10'd11};
parameter  logic [  9*10-1:0] CTXIDX_SPLIT_CU_FLAG             = {  10'd12,  10'd13,  10'd14,  10'd15,  10'd16,  10'd17,  10'd18,  10'd19,  10'd20};
parameter  logic [  3*10-1:0] CTXIDX_CU_TRANSQUANT_BYPASS_FLAG = {  10'd21,  10'd22,  10'd23};
parameter  logic [  6*10-1:0] CTXIDX_CU_SKIP_FLAG              = {  10'd24,  10'd25,  10'd26,  10'd27,  10'd28,  10'd29};
parameter  logic [  2*10-1:0] CTXIDX_PRED_MODE_FLAG            = {  10'd30,  10'd31};
parameter  logic [  9*10-1:0] CTXIDX_PART_MODE                 = {  10'd32,  10'd33,  10'd34,  10'd35,  10'd36,  10'd37,  10'd38,  10'd39,  10'd40};
parameter  logic [  3*10-1:0] CTXIDX_PREV_INTRA_LUMA_PRED_FLAG = {  10'd41,  10'd42,  10'd43};
parameter  logic [  3*10-1:0] CTXIDX_INTRA_CHROMA_PRED_MODE    = {  10'd44,  10'd45,  10'd46};
parameter  logic [  2*10-1:0] CTXIDX_RQT_ROOT_CBF              = {  10'd47,  10'd48};
parameter  logic [  2*10-1:0] CTXIDX_MERGE_FLAG                = {  10'd49,  10'd50};
parameter  logic [  2*10-1:0] CTXIDX_MERGE_IDX                 = {  10'd51,  10'd52};
parameter  logic [ 10*10-1:0] CTXIDX_INTER_PRED_IDC            = {  10'd53,  10'd54,  10'd55,  10'd56,  10'd57,  10'd58,  10'd59,  10'd60,  10'd61,  10'd62};
parameter  logic [  4*10-1:0] CTXIDX_REF_IDX_L0                = {  10'd63,  10'd64,  10'd65,  10'd66};
parameter  logic [  4*10-1:0] CTXIDX_REF_IDX_L1                = {  10'd67,  10'd68,  10'd69,  10'd70};
parameter  logic [  2*10-1:0] CTXIDX_MVP_L0_FLAG               = {  10'd71,  10'd72};
parameter  logic [  2*10-1:0] CTXIDX_MVP_L1_FLAG               = {  10'd73,  10'd74};
parameter  logic [  9*10-1:0] CTXIDX_SPLIT_TRANSFORM_FLAG      = {  10'd75,  10'd76,  10'd77,  10'd78,  10'd79,  10'd80,  10'd81,  10'd82,  10'd83};
parameter  logic [  6*10-1:0] CTXIDX_CBF_LUMA                  = {  10'd84,  10'd85,  10'd86,  10'd87,  10'd88,  10'd89};
parameter  logic [ 15*10-1:0] CTXIDX_CBF_CB                    = {  10'd90,  10'd91,  10'd92,  10'd93,  10'd94,  10'd95,  10'd96, 10'd97,  
                                                                    10'd98,  10'd99, 10'd100, 10'd101, 10'd102, 10'd103, 10'd104};
parameter  logic [ 15*10-1:0] CTXIDX_CBF_CR                    = { 10'd105, 10'd106, 10'd107, 10'd108, 10'd109, 10'd110, 10'd111, 10'd112, 
                                                                   10'd113, 10'd114, 10'd115, 10'd116, 10'd117, 10'd118, 10'd119};
parameter  logic [  4*10-1:0] CTXIDX_ABS_MVD_GT0_FLAG          = { 10'd120, 10'd121, 10'd122, 10'd123};
parameter  logic [  4*10-1:0] CTXIDX_ABS_MVD_GT1_FLAG          = { 10'd124, 10'd125, 10'd126, 10'd127};
parameter  logic [  6*10-1:0] CTXIDX_CU_QP_DELTA_ABS           = { 10'd128, 10'd129, 10'd130, 10'd131, 10'd132, 10'd133};
parameter  logic [  6*10-1:0] CTXIDX_TRANSFORM_SKIP_FLAG       = { 10'd134, 10'd135, 10'd136, 10'd137, 10'd138, 10'd139};
parameter  logic [ 54*10-1:0] CTXIDX_LAST_SIG_COEFF_X_PREFIX   = { 10'd140, 10'd141, 10'd142, 10'd143, 10'd144, 10'd145, 10'd146, 10'd147, 
                                                                   10'd148, 10'd149, 10'd150, 10'd151, 10'd152, 10'd153, 10'd154, 10'd155, 
                                                                   10'd156, 10'd157, 10'd158, 10'd159, 10'd160, 10'd161, 10'd162, 10'd163, 
                                                                   10'd164, 10'd165, 10'd166, 10'd167, 10'd168, 10'd169, 10'd170, 10'd171, 
                                                                   10'd172, 10'd173, 10'd174, 10'd175, 10'd176, 10'd177, 10'd178, 10'd179, 
                                                                   10'd180, 10'd181, 10'd182, 10'd183, 10'd184, 10'd185, 10'd186, 10'd187, 
                                                                   10'd188, 10'd189, 10'd190, 10'd191, 10'd192, 10'd193}; 
parameter  logic [ 54*10-1:0] CTXIDX_LAST_SIG_COEFF_Y_PREFIX   = { 10'd194, 10'd195, 10'd196, 10'd197, 10'd198, 10'd199, 10'd200, 10'd201, 
                                                                   10'd202, 10'd203, 10'd204, 10'd205, 10'd206, 10'd207, 10'd208, 10'd209, 
                                                                   10'd210, 10'd211, 10'd212, 10'd213, 10'd214, 10'd215, 10'd216, 10'd217, 
                                                                   10'd218, 10'd219, 10'd220, 10'd221, 10'd222, 10'd223, 10'd224, 10'd225, 
                                                                   10'd226, 10'd227, 10'd228, 10'd229, 10'd230, 10'd231, 10'd232, 10'd233, 
                                                                   10'd234, 10'd235, 10'd236, 10'd237, 10'd238, 10'd239, 10'd240, 10'd241, 
                                                                   10'd242, 10'd243, 10'd244, 10'd245, 10'd246, 10'd247};
parameter  logic [ 12*10-1:0] CTXIDX_CODED_SUB_BLOCK_FLAG      = { 10'd248, 10'd249, 10'd250, 10'd251, 10'd252, 10'd253, 10'd254, 10'd255, 
                                                                   10'd256, 10'd257, 10'd258, 10'd259};
parameter  logic [132*10-1:0] CTXIDX_SIG_COEFF_FLAG            = { 10'd260, 10'd261, 10'd262, 10'd263, 10'd264, 10'd265, 10'd266, 10'd267, 
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
parameter  logic [ 72*10-1:0] CTXIDX_COEFF_ABS_LEVEL_GT1_FLAG  = { 10'd392, 10'd393, 10'd394, 10'd395, 10'd396, 10'd397, 10'd398, 10'd399, 
                                                                   10'd400, 10'd401, 10'd402, 10'd403, 10'd404, 10'd405, 10'd406, 10'd407, 
                                                                   10'd408, 10'd409, 10'd410, 10'd411, 10'd412, 10'd413, 10'd414, 10'd415, 
                                                                   10'd416, 10'd417, 10'd418, 10'd419, 10'd420, 10'd421, 10'd422, 10'd423, 
                                                                   10'd424, 10'd425, 10'd426, 10'd427, 10'd428, 10'd429, 10'd430, 10'd431, 
                                                                   10'd432, 10'd433, 10'd434, 10'd435, 10'd436, 10'd437, 10'd438, 10'd439, 
                                                                   10'd440, 10'd441, 10'd442, 10'd443, 10'd444, 10'd445, 10'd446, 10'd447, 
                                                                   10'd448, 10'd449, 10'd450, 10'd451, 10'd452, 10'd453, 10'd454, 10'd455, 
                                                                   10'd456, 10'd457, 10'd458, 10'd459, 10'd460, 10'd461, 10'd462, 10'd463};
parameter  logic [ 18*10-1:0] CTXIDX_COEFF_ABS_LEVEL_GT2_FLAG  = { 10'd464, 10'd465, 10'd466, 10'd467, 10'd468, 10'd469, 10'd470, 10'd471, 
                                                                   10'd472, 10'd473, 10'd474, 10'd475, 10'd476, 10'd477, 10'd478, 10'd479, 
                                                                   10'd480, 10'd481};
parameter  logic [  4*10-1:0] CTXIDX_EXPLICIT_RDPCM_FLAG       = { 10'd482, 10'd483, 10'd484, 10'd485};
parameter  logic [  4*10-1:0] CTXIDX_EXPLICIT_RDPCM_DIR_FLAG   = { 10'd486, 10'd487, 10'd488, 10'd489};
parameter  logic [  3*10-1:0] CTXIDX_CHROMA_QP_OFFSET_FLAG     = { 10'd490, 10'd491, 10'd492};
parameter  logic [  3*10-1:0] CTXIDX_CHROMA_QP_OFFSET_IDX      = { 10'd493, 10'd494, 10'd495};
parameter  logic [ 24*10-1:0] CTXIDX_LOG2_RES_SCALE_ABS_PLUS1  = { 10'd496, 10'd497, 10'd498, 10'd499, 10'd500, 10'd501, 10'd502, 10'd503, 
                                                                   10'd504, 10'd505, 10'd506, 10'd507, 10'd508, 10'd509, 10'd510, 10'd511, 
                                                                   10'd512, 10'd513, 10'd514, 10'd515, 10'd516, 10'd517, 10'd518, 10'd519};
parameter  logic [  6*10-1:0] CTXIDX_RES_SCALE_SIGN_FLAG       = { 10'd520, 10'd521, 10'd522, 10'd523, 10'd524, 10'd525};
parameter  logic [  3*10-1:0] CTXIDX_PALETTE_MODE_FLAG         = { 10'd526, 10'd527, 10'd528};
parameter  logic [  3*10-1:0] CTXIDX_TU_RESIDUAL_ACT_FLAG      = { 10'd529, 10'd530, 10'd531};
parameter  logic [ 24*10-1:0] CTXIDX_PALETTE_RUN_PREFIX        = { 10'd532, 10'd533, 10'd534, 10'd535, 10'd536, 10'd537, 10'd538, 10'd539, 
                                                                   10'd540, 10'd541, 10'd542, 10'd543, 10'd544, 10'd545, 10'd546, 10'd547, 
                                                                   10'd548, 10'd549, 10'd550, 10'd551, 10'd552, 10'd553, 10'd554, 10'd555};
parameter  logic [  3*10-1:0] CTXIDX_COPY_ABOVE_PALETTE_INDICES_FLAG = { 10'd556, 10'd557, 10'd558};
parameter  logic [  3*10-1:0] CTXIDX_COPY_ABOVE_INDICES_FOR_FINAL_RUN_FLAG = { 10'd559, 10'd560, 10'd561};
parameter  logic [  3*10-1:0] CTXIDX_PALETTE_TRANSPOSE_FLAG    = { 10'd562, 10'd563, 10'd564};
`else
// sig coeff flag ctx id map
parameter  logic [14:0][3:0] SIG_COEFF_FLAG_CTXIDX_MAP = {4'd0, 4'd1, 4'd4, 4'd5, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd6, 4'd8, 4'd8, 4'd7, 4'd7, 4'd8};

// scan order
// scanIdx 0, diagonal
// 0 2     0 1
// 1 3     2 3
parameter  logic [3:0][1:0]  REORDER_SCANIDX0_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h2, 2'h1, 2'h3};
parameter  logic [3:0][1:0]  REORDER_SCANIDX0_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h2, 2'h1, 2'h3};
// 0 2 5 9        0 1 4 5
// 1 4 8 c        2 3 6 7
// 3 7 b e        8 9 c d
// 6 a d f        a b e f
parameter  logic [15:0][3:0] REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h2, 4'h1, 4'h4, 4'h5, 4'h9, 4'h8, 4'hc, 4'h3, 4'h7, 4'h6, 4'ha, 4'hb, 4'he, 4'hd, 4'hf};
parameter  logic [15:0][3:0] REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h2, 4'h1, 4'h8, 4'h3, 4'h4, 4'ha, 4'h9, 4'h6, 4'h5, 4'hb, 4'hc, 4'h7, 4'he, 4'hd, 4'hf};
//  0  2  5  9  e 14 1b 23        0  1  4  5 10 11 14 15
//  1  4  8  d 13 1a 22 2a        2  3  6  7 12 13 16 17
//  3  7  c 12 19 21 29 30        8  9  c  d 18 19 1c 1d
//  6  b 11 18 20 28 2f 35        a  b  e  f 1a 1b 1e 1f
//  a 10 17 1f 27 2e 34 39       20 21 24 25 30 31 34 35
//  f 16 1e 26 2d 33 38 3c       22 23 26 27 32 33 36 37
// 15 1d 25 2c 32 37 3b 3e       28 29 2c 2d 38 39 3c 3d
// 1c 24 2b 31 36 3a 3d 3f       2a 2b 2e 2f 3a 3b 3e 3f
parameter  logic [63:0][5:0] REORDER_SCANIDX0_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h02, 6'h01, 6'h04, 6'h05, 6'h09, 6'h08, 6'h0d, 6'h03, 6'h07, 6'h06, 6'h0b, 6'h0c, 6'h12, 6'h11, 6'h18, 
                              6'h0e, 6'h14, 6'h13, 6'h1a, 6'h1b, 6'h23, 6'h22, 6'h2a, 6'h19, 6'h21, 6'h20, 6'h28, 6'h29, 6'h30, 6'h2f, 6'h35,
                              6'h0a, 6'h10, 6'h0f, 6'h16, 6'h17, 6'h1f, 6'h1e, 6'h26, 6'h15, 6'h1d, 6'h1c, 6'h24, 6'h25, 6'h2c, 6'h2b, 6'h31,
                              6'h27, 6'h2e, 6'h2d, 6'h33, 6'h34, 6'h39, 6'h38, 6'h3c, 6'h32, 6'h37, 6'h36, 6'h3a, 6'h3b, 6'h3e, 6'h3d, 6'h3f};
parameter  logic [63:0][5:0] REORDER_SCANIDX0_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h02, 6'h01, 6'h08, 6'h03, 6'h04, 6'h0a, 6'h09, 6'h06, 6'h05, 6'h20, 6'h0b, 6'h0c, 6'h07, 6'h10, 6'h22, 
                              6'h21, 6'h0e, 6'h0d, 6'h12, 6'h11, 6'h28, 6'h23, 6'h24, 6'h0f, 6'h18, 6'h13, 6'h14, 6'h2a, 6'h29, 6'h26, 6'h25,
                              6'h1a, 6'h19, 6'h16, 6'h15, 6'h2b, 6'h2c, 6'h27, 6'h30, 6'h1b, 6'h1c, 6'h17, 6'h2e, 6'h2d, 6'h32, 6'h31, 6'h1e,
                              6'h1d, 6'h2f, 6'h38, 6'h33, 6'h34, 6'h1f, 6'h3a, 6'h39, 6'h36, 6'h35, 6'h3b, 6'h3c, 6'h37, 6'h3e, 6'h3d, 6'h3f};
// scanIdx 1, horizontal
// 0 1     0 1
// 2 3     2 3
parameter  logic [3:0][1:0]  REORDER_SCANIDX1_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h1, 2'h2, 2'h3};
parameter  logic [3:0][1:0]  REORDER_SCANIDX1_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h1, 2'h2, 2'h3};
// 0 1 2 3        0 1 4 5
// 4 5 6 7        2 3 6 7
// 8 9 a b        8 9 c d
// c d e f        a b e f
parameter  logic [15:0][3:0] REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h1, 4'h4, 4'h5, 4'h2, 4'h3, 4'h6, 4'h7, 4'h8, 4'h9, 4'hc, 4'hd, 4'ha, 4'hb, 4'he, 4'hf};
parameter  logic [15:0][3:0] REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h1, 4'h4, 4'h5, 4'h2, 4'h3, 4'h6, 4'h7, 4'h8, 4'h9, 4'hc, 4'hd, 4'ha, 4'hb, 4'he, 4'hf};
//  0  1  2  3  4  5  6  7        0  1  4  5 10 11 14 15
//  8  9  a  b  c  d  e  f        2  3  6  7 12 13 16 17
// 10 11 12 13 14 15 16 17        8  9  c  d 18 19 1c 1d
// 18 19 1a 1b 1c 1d 1e 1f        a  b  e  f 1a 1b 1e 1f
// 20 21 22 23 24 25 26 27       20 21 24 25 30 31 34 35
// 28 29 2a 2b 2c 2d 2e 2f       22 23 26 27 32 33 36 37
// 30 31 32 33 34 35 36 37       28 29 2c 2d 38 39 3c 3d
// 38 39 3a 3b 3c 3d 3e 3f       2a 2b 2e 2f 3a 3b 3e 3f
parameter  logic [63:0][5:0] REORDER_SCANIDX1_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h01, 6'h08, 6'h09, 6'h02, 6'h03, 6'h0a, 6'h0b, 6'h10, 6'h11, 6'h18, 6'h19, 6'h12, 6'h13, 6'h1a, 6'h1b,
                              6'h04, 6'h05, 6'h0c, 6'h0d, 6'h06, 6'h07, 6'h0e, 6'h0f, 6'h14, 6'h15, 6'h1c, 6'h1d, 6'h16, 6'h17, 6'h1e, 6'h1f,
                              6'h20, 6'h21, 6'h28, 6'h29, 6'h22, 6'h23, 6'h2a, 6'h2b, 6'h30, 6'h31, 6'h38, 6'h39, 6'h32, 6'h33, 6'h3a, 6'h3b,
                              6'h24, 6'h25, 6'h2c, 6'h2d, 6'h26, 6'h27, 6'h2e, 6'h2f, 6'h34, 6'h35, 6'h3c, 6'h3d, 6'h36, 6'h37, 6'h3e, 6'h3f};
parameter  logic [63:0][5:0] REORDER_SCANIDX1_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h01, 6'h04, 6'h05, 6'h10, 6'h11, 6'h14, 6'h15, 6'h02, 6'h03, 6'h06, 6'h07, 6'h12, 6'h13, 6'h16, 6'h17,
                              6'h08, 6'h09, 6'h0c, 6'h0d, 6'h18, 6'h19, 6'h1c, 6'h1d, 6'h0a, 6'h0b, 6'h0e, 6'h0f, 6'h1a, 6'h1b, 6'h1e, 6'h1f,
                              6'h20, 6'h21, 6'h24, 6'h25, 6'h30, 6'h31, 6'h34, 6'h35, 6'h22, 6'h23, 6'h26, 6'h27, 6'h32, 6'h33, 6'h36, 6'h37,
                              6'h28, 6'h29, 6'h2c, 6'h2d, 6'h38, 6'h39, 6'h3c, 6'h3d, 6'h2a, 6'h2b, 6'h2e, 6'h2f, 6'h3a, 6'h3b, 6'h3e, 6'h3f};
// scanIdx 2, vertical
// 0 2     0 1
// 1 3     2 3
parameter  logic [3:0][1:0]  REORDER_SCANIDX2_SIZE2X2_ZIGZAG_TO_SCAN = {2'h0, 2'h2, 2'h1, 2'h3};
parameter  logic [3:0][1:0]  REORDER_SCANIDX2_SIZE2X2_SCAN_TO_ZIGZAG = {2'h0, 2'h2, 2'h1, 2'h3};
// 0 4 8 c        0 1 4 5
// 1 5 9 d        2 3 6 7
// 2 6 a e        8 9 c d
// 3 7 b f        a b e f
parameter  logic [15:0][3:0] REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN = {4'h0, 4'h4, 4'h1, 4'h5, 4'h8, 4'hc, 4'h9, 4'hd, 4'h2, 4'h6, 4'h3, 4'h7, 4'ha, 4'he, 4'hb, 4'hf};
parameter  logic [15:0][3:0] REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG = {4'h0, 4'h2, 4'h8, 4'ha, 4'h1, 4'h3, 4'h9, 4'hb, 4'h4, 4'h6, 4'hc, 4'he, 4'h5, 4'h7, 4'hd, 4'hf};
//  0  8 10 18 20 28 30 38        0  1  4  5 10 11 14 15
//  1  9 11 19 21 29 31 39        2  3  6  7 12 13 16 17
//  2  a 12 1a 22 2a 32 3a        8  9  c  d 18 19 1c 1d
//  3  b 13 1b 23 2b 33 3b        a  b  e  f 1a 1b 1e 1f
//  4  c 14 1c 24 2c 34 3c       20 21 24 25 30 31 34 35
//  5  d 15 1d 25 2d 35 3d       22 23 26 27 32 33 36 37
//  6  e 16 1e 26 2e 36 3e       28 29 2c 2d 38 39 3c 3d
//  7  f 17 1f 27 2f 37 3f       2a 2b 2e 2f 3a 3b 3e 3f
parameter  logic [63:0][5:0] REORDER_SCANIDX2_SIZE8X8_ZIGZAG_TO_SCAN = 
                             {6'h00, 6'h08, 6'h01, 6'h09, 6'h10, 6'h18, 6'h11, 6'h19, 6'h02, 6'h0a, 6'h03, 6'h0b, 6'h12, 6'h1a, 6'h13, 6'h1b, 
                              6'h20, 6'h28, 6'h21, 6'h29, 6'h30, 6'h38, 6'h31, 6'h39, 6'h22, 6'h2a, 6'h23, 6'h2b, 6'h32, 6'h3a, 6'h33, 6'h3b,
                              6'h04, 6'h0c, 6'h05, 6'h0d, 6'h14, 6'h1c, 6'h15, 6'h1d, 6'h06, 6'h0e, 6'h07, 6'h0f, 6'h16, 6'h1e, 6'h17, 6'h1f,
                              6'h24, 6'h2c, 6'h25, 6'h2d, 6'h34, 6'h3c, 6'h35, 6'h3d, 6'h26, 6'h2e, 6'h27, 6'h2f, 6'h36, 6'h3e, 6'h37, 6'h3f};
parameter  logic [63:0][5:0] REORDER_SCANIDX2_SIZE8X8_SCAN_TO_ZIGZAG = 
                             {6'h00, 6'h02, 6'h08, 6'h0a, 6'h20, 6'h22, 6'h28, 6'h2a, 6'h01, 6'h03, 6'h09, 6'h0b, 6'h21, 6'h23, 6'h29, 6'h2b,
                              6'h04, 6'h06, 6'h0c, 6'h0e, 6'h24, 6'h26, 6'h2c, 6'h2e, 6'h05, 6'h07, 6'h0d, 6'h0f, 6'h25, 6'h27, 6'h2d, 6'h2f,
                              6'h10, 6'h12, 6'h18, 6'h1a, 6'h30, 6'h32, 6'h38, 6'h3a, 6'h11, 6'h13, 6'h19, 6'h1b, 6'h31, 6'h33, 6'h39, 6'h3b,
                              6'h14, 6'h16, 6'h1c, 6'h1e, 6'h34, 6'h36, 6'h3c, 6'h3e, 6'h15, 6'h17, 6'h1d, 6'h1f, 6'h35, 6'h37, 6'h3d, 6'h3f};

// context index
parameter  logic [0:  2][9:0] CTXIDX_SAO_MERGE_LEFT_FLAG       = {   10'd0,   10'd1,  10'd2};
parameter  logic [0:  2][9:0] CTXIDX_SAO_MERGE_UP_FLAG         = {   10'd3,   10'd4,  10'd5};
parameter  logic [0:  2][9:0] CTXIDX_SAO_TYPE_IDX_LUMA         = {   10'd6,   10'd7,  10'd8};
parameter  logic [0:  2][9:0] CTXIDX_SAO_TYPE_IDX_CHROMA       = {   10'd9,  10'd10,  10'd11};
parameter  logic [0:  8][9:0] CTXIDX_SPLIT_CU_FLAG             = {  10'd12,  10'd13,  10'd14,  10'd15,  10'd16,  10'd17,  10'd18,  10'd19,  10'd20};
parameter  logic [0:  2][9:0] CTXIDX_CU_TRANSQUANT_BYPASS_FLAG = {  10'd21,  10'd22,  10'd23};
parameter  logic [0:  5][9:0] CTXIDX_CU_SKIP_FLAG              = {  10'd24,  10'd25,  10'd26,  10'd27,  10'd28,  10'd29};
parameter  logic [0:  1][9:0] CTXIDX_PRED_MODE_FLAG            = {  10'd30,  10'd31};
parameter  logic [0:  8][9:0] CTXIDX_PART_MODE                 = {  10'd32,  10'd33,  10'd34,  10'd35,  10'd36,  10'd37,  10'd38,  10'd39,  10'd40};
parameter  logic [0:  2][9:0] CTXIDX_PREV_INTRA_LUMA_PRED_FLAG = {  10'd41,  10'd42,  10'd43};
parameter  logic [0:  2][9:0] CTXIDX_INTRA_CHROMA_PRED_MODE    = {  10'd44,  10'd45,  10'd46};
parameter  logic [0:  1][9:0] CTXIDX_RQT_ROOT_CBF              = {  10'd47,  10'd48};
parameter  logic [0:  1][9:0] CTXIDX_MERGE_FLAG                = {  10'd49,  10'd50};
parameter  logic [0:  1][9:0] CTXIDX_MERGE_IDX                 = {  10'd51,  10'd52};
parameter  logic [0:  9][9:0] CTXIDX_INTER_PRED_IDC            = {  10'd53,  10'd54,  10'd55,  10'd56,  10'd57,  10'd58,  10'd59,  10'd60,  10'd61,  10'd62};
parameter  logic [0:  3][9:0] CTXIDX_REF_IDX_L0                = {  10'd63,  10'd64,  10'd65,  10'd66};
parameter  logic [0:  3][9:0] CTXIDX_REF_IDX_L1                = {  10'd67,  10'd68,  10'd69,  10'd70};
parameter  logic [0:  1][9:0] CTXIDX_MVP_L0_FLAG               = {  10'd71,  10'd72};
parameter  logic [0:  1][9:0] CTXIDX_MVP_L1_FLAG               = {  10'd73,  10'd74};
parameter  logic [0:  8][9:0] CTXIDX_SPLIT_TRANSFORM_FLAG      = {  10'd75,  10'd76,  10'd77,  10'd78,  10'd79,  10'd80,  10'd81,  10'd82,  10'd83};
parameter  logic [0:  5][9:0] CTXIDX_CBF_LUMA                  = {  10'd84,  10'd85,  10'd86,  10'd87,  10'd88,  10'd89};
parameter  logic [0: 14][9:0] CTXIDX_CBF_CB                    = {  10'd90,  10'd91,  10'd92,  10'd93,  10'd94,  10'd95,  10'd96, 10'd97,  
                                                                    10'd98,  10'd99, 10'd100, 10'd101, 10'd102, 10'd103, 10'd104};
parameter  logic [0: 14][9:0] CTXIDX_CBF_CR                    = { 10'd105, 10'd106, 10'd107, 10'd108, 10'd109, 10'd110, 10'd111, 10'd112, 
                                                                   10'd113, 10'd114, 10'd115, 10'd116, 10'd117, 10'd118, 10'd119};
parameter  logic [0:  3][9:0] CTXIDX_ABS_MVD_GT0_FLAG          = { 10'd120, 10'd121, 10'd122, 10'd123};
parameter  logic [0:  3][9:0] CTXIDX_ABS_MVD_GT1_FLAG          = { 10'd124, 10'd125, 10'd126, 10'd127};
parameter  logic [0:  5][9:0] CTXIDX_CU_QP_DELTA_ABS           = { 10'd128, 10'd129, 10'd130, 10'd131, 10'd132, 10'd133};
parameter  logic [0:  5][9:0] CTXIDX_TRANSFORM_SKIP_FLAG       = { 10'd134, 10'd135, 10'd136, 10'd137, 10'd138, 10'd139};
parameter  logic [0: 53][9:0] CTXIDX_LAST_SIG_COEFF_X_PREFIX   = { 10'd140, 10'd141, 10'd142, 10'd143, 10'd144, 10'd145, 10'd146, 10'd147, 
                                                                   10'd148, 10'd149, 10'd150, 10'd151, 10'd152, 10'd153, 10'd154, 10'd155, 
                                                                   10'd156, 10'd157, 10'd158, 10'd159, 10'd160, 10'd161, 10'd162, 10'd163, 
                                                                   10'd164, 10'd165, 10'd166, 10'd167, 10'd168, 10'd169, 10'd170, 10'd171, 
                                                                   10'd172, 10'd173, 10'd174, 10'd175, 10'd176, 10'd177, 10'd178, 10'd179, 
                                                                   10'd180, 10'd181, 10'd182, 10'd183, 10'd184, 10'd185, 10'd186, 10'd187, 
                                                                   10'd188, 10'd189, 10'd190, 10'd191, 10'd192, 10'd193}; 
parameter  logic [0: 53][9:0] CTXIDX_LAST_SIG_COEFF_Y_PREFIX   = { 10'd194, 10'd195, 10'd196, 10'd197, 10'd198, 10'd199, 10'd200, 10'd201, 
                                                                   10'd202, 10'd203, 10'd204, 10'd205, 10'd206, 10'd207, 10'd208, 10'd209, 
                                                                   10'd210, 10'd211, 10'd212, 10'd213, 10'd214, 10'd215, 10'd216, 10'd217, 
                                                                   10'd218, 10'd219, 10'd220, 10'd221, 10'd222, 10'd223, 10'd224, 10'd225, 
                                                                   10'd226, 10'd227, 10'd228, 10'd229, 10'd230, 10'd231, 10'd232, 10'd233, 
                                                                   10'd234, 10'd235, 10'd236, 10'd237, 10'd238, 10'd239, 10'd240, 10'd241, 
                                                                   10'd242, 10'd243, 10'd244, 10'd245, 10'd246, 10'd247};
parameter  logic [0: 11][9:0] CTXIDX_CODED_SUB_BLOCK_FLAG      = { 10'd248, 10'd249, 10'd250, 10'd251, 10'd252, 10'd253, 10'd254, 10'd255, 
                                                                   10'd256, 10'd257, 10'd258, 10'd259};
parameter  logic [0:131][9:0] CTXIDX_SIG_COEFF_FLAG            = { 10'd260, 10'd261, 10'd262, 10'd263, 10'd264, 10'd265, 10'd266, 10'd267, 
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
parameter  logic [0: 71][9:0] CTXIDX_COEFF_ABS_LEVEL_GT1_FLAG  = { 10'd392, 10'd393, 10'd394, 10'd395, 10'd396, 10'd397, 10'd398, 10'd399, 
                                                                   10'd400, 10'd401, 10'd402, 10'd403, 10'd404, 10'd405, 10'd406, 10'd407, 
                                                                   10'd408, 10'd409, 10'd410, 10'd411, 10'd412, 10'd413, 10'd414, 10'd415, 
                                                                   10'd416, 10'd417, 10'd418, 10'd419, 10'd420, 10'd421, 10'd422, 10'd423, 
                                                                   10'd424, 10'd425, 10'd426, 10'd427, 10'd428, 10'd429, 10'd430, 10'd431, 
                                                                   10'd432, 10'd433, 10'd434, 10'd435, 10'd436, 10'd437, 10'd438, 10'd439, 
                                                                   10'd440, 10'd441, 10'd442, 10'd443, 10'd444, 10'd445, 10'd446, 10'd447, 
                                                                   10'd448, 10'd449, 10'd450, 10'd451, 10'd452, 10'd453, 10'd454, 10'd455, 
                                                                   10'd456, 10'd457, 10'd458, 10'd459, 10'd460, 10'd461, 10'd462, 10'd463};
parameter  logic [0: 17][9:0] CTXIDX_COEFF_ABS_LEVEL_GT2_FLAG  = { 10'd464, 10'd465, 10'd466, 10'd467, 10'd468, 10'd469, 10'd470, 10'd471, 
                                                                   10'd472, 10'd473, 10'd474, 10'd475, 10'd476, 10'd477, 10'd478, 10'd479, 
                                                                   10'd480, 10'd481};
parameter  logic [0:  3][9:0] CTXIDX_EXPLICIT_RDPCM_FLAG       = { 10'd482, 10'd483, 10'd484, 10'd485};
parameter  logic [0:  3][9:0] CTXIDX_EXPLICIT_RDPCM_DIR_FLAG   = { 10'd486, 10'd487, 10'd488, 10'd489};
parameter  logic [0:  2][9:0] CTXIDX_CHROMA_QP_OFFSET_FLAG     = { 10'd490, 10'd491, 10'd492};
parameter  logic [0:  2][9:0] CTXIDX_CHROMA_QP_OFFSET_IDX      = { 10'd493, 10'd494, 10'd495};
parameter  logic [0: 23][9:0] CTXIDX_LOG2_RES_SCALE_ABS_PLUS1  = { 10'd496, 10'd497, 10'd498, 10'd499, 10'd500, 10'd501, 10'd502, 10'd503, 
                                                                   10'd504, 10'd505, 10'd506, 10'd507, 10'd508, 10'd509, 10'd510, 10'd511, 
                                                                   10'd512, 10'd513, 10'd514, 10'd515, 10'd516, 10'd517, 10'd518, 10'd519};
parameter  logic [0:  5][9:0] CTXIDX_RES_SCALE_SIGN_FLAG       = { 10'd520, 10'd521, 10'd522, 10'd523, 10'd524, 10'd525};
parameter  logic [0:  2][9:0] CTXIDX_PALETTE_MODE_FLAG         = { 10'd526, 10'd527, 10'd528};
parameter  logic [0:  2][9:0] CTXIDX_TU_RESIDUAL_ACT_FLAG      = { 10'd529, 10'd530, 10'd531};
parameter  logic [0: 23][9:0] CTXIDX_PALETTE_RUN_PREFIX        = { 10'd532, 10'd533, 10'd534, 10'd535, 10'd536, 10'd537, 10'd538, 10'd539, 
                                                                   10'd540, 10'd541, 10'd542, 10'd543, 10'd544, 10'd545, 10'd546, 10'd547, 
                                                                   10'd548, 10'd549, 10'd550, 10'd551, 10'd552, 10'd553, 10'd554, 10'd555};
parameter  logic [0:  2][9:0] CTXIDX_COPY_ABOVE_PALETTE_INDICES_FLAG = { 10'd556, 10'd557, 10'd558};
parameter  logic [0:  2][9:0] CTXIDX_COPY_ABOVE_INDICES_FOR_FINAL_RUN_FLAG = { 10'd559, 10'd560, 10'd561};
parameter  logic [0:  2][9:0] CTXIDX_PALETTE_TRANSPOSE_FLAG    = { 10'd562, 10'd563, 10'd564};
`endif

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
parameter  logic [11:0] LB_START_ADDR_SAO   = 12'd0;
parameter  logic [11:0] LB_START_ADDR_TOP   = 12'd12;
parameter  logic [11:0] LB_START_ADDR_CQT   = 12'd16;
parameter  logic [11:0] LB_START_ADDR_CU    = 12'd24;
parameter  logic [11:0] LB_START_ADDR_PU    = 12'd568;
parameter  logic [11:0] LB_START_ADDR_MVD   = 12'd920;
parameter  logic [11:0] LB_START_ADDR_TRAFO = 12'd1432;
parameter  logic [11:0] LB_START_ADDR_DQP   = 12'd1488;
parameter  logic [11:0] LB_START_ADDR_CQP   = 12'd1744;
parameter  logic [11:0] LB_START_ADDR_RES   = 12'd1760;

// control register from parameter sets
typedef enum logic [31:0] {
    ADDR_CABAC_START                          = 32'h000,
    ADDR_CABAC_VPS_0                          = 32'h004,
    ADDR_CABAC_SPS_0                          = 32'h008,
    ADDR_CABAC_SPS_1                          = 32'h00c,
    ADDR_CABAC_PPS_0                          = 32'h010,
    ADDR_CABAC_SLICE_HEADER_0                 = 32'h014
} t_CUTREE_ADDR_e;

parameter [31:0] reg_CABAC_START_MASK                           = 32'h00000001;
parameter [31:0] reg_CABAC_VPS_0_MASK                           = 32'h0000000f;
parameter [31:0] reg_CABAC_SPS_0_MASK                           = 32'h0fffffff;
parameter [31:0] reg_CABAC_SPS_1_MASK                           = 32'h07ffffff;
parameter [31:0] reg_CABAC_PPS_0_MASK                           = 32'h00ffffff;
parameter [31:0] reg_CABAC_SLICE_HEADER_0_MASK                  = 32'h0000ffff;

typedef struct packed {
    logic [30:0]   rsvd0;
    logic [0:0]    cabac_start;
} t_reg_CABAC_START_s;

typedef struct packed {
    logic [27:0]   rsvd0;
    logic [3:0]    vps_id;
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
    logic [7:0]    rsvd0;
    logic [7:0]    initQp;
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
    t_reg_CABAC_START_s                                          reg_CABAC_START;
    t_reg_CABAC_VPS_0_s                                          reg_CABAC_VPS_0;
    t_reg_CABAC_SPS_0_s                                          reg_CABAC_SPS_0;
    t_reg_CABAC_SPS_1_s                                          reg_CABAC_SPS_1;
    t_reg_CABAC_PPS_0_s                                          reg_CABAC_PPS_0;
    t_reg_CABAC_SLICE_HEADER_0_s                                 reg_CABAC_SLICE_HEADER_0;
} t_CABAC_AO_s;

`ifdef IVERILOG
// Context init value
parameter  logic [8*567-1:0] CTX_INIT_VALUE = {
  8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd200, 8'd185, 
  8'd160, 8'd200, 8'd185, 8'd160, 8'd139, 8'd141, 8'd157, 8'd107, 
  8'd139, 8'd126, 8'd107, 8'd139, 8'd126, 8'd154, 8'd154, 8'd154, 
  8'd197, 8'd185, 8'd201, 8'd197, 8'd185, 8'd201, 8'd149, 8'd134, 

  8'd184, 8'd154, 8'd139, 8'd154, 8'd154, 8'd154, 8'd139, 8'd154, 
  8'd154, 8'd184, 8'd154, 8'd183, 8'd 63, 8'd152, 8'd152, 8'd 79, 
  8'd 79, 8'd110, 8'd154, 8'd122, 8'd137, 8'd 95, 8'd 79, 8'd 63, 
  8'd 31, 8'd 31, 8'd 95, 8'd 79, 8'd 63, 8'd 31, 8'd 31, 8'd153, 
  
  8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd168, 
  8'd168, 8'd168, 8'd168, 8'd153, 8'd138, 8'd138, 8'd124, 8'd138, 
  8'd 94, 8'd224, 8'd167, 8'd122, 8'd111, 8'd141, 8'd153, 8'd111, 
  8'd153, 8'd111, 8'd 94, 8'd138, 8'd182, 8'd154, 8'd149, 8'd107, 
  
  8'd167, 8'd154, 8'd149, 8'd 92, 8'd167, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd 94, 8'd138, 8'd182, 8'd154, 8'd149, 8'd107, 8'd167, 
  8'd154, 8'd149, 8'd 92, 8'd167, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd140, 8'd198, 8'd169, 8'd198, 8'd140, 8'd198, 8'd169, 8'd198, 
  
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd139, 8'd139, 
  8'd139, 8'd139, 8'd139, 8'd139, 8'd110, 8'd110, 8'd124, 8'd125, 
  8'd140, 8'd153, 8'd125, 8'd127, 8'd140, 8'd109, 8'd111, 8'd143, 
  8'd127, 8'd111, 8'd 79, 8'd108, 8'd123, 8'd 63, 8'd125, 8'd110, 

  8'd 94, 8'd110, 8'd 95, 8'd 79, 8'd125, 8'd111, 8'd110, 8'd 78, 
  8'd110, 8'd111, 8'd111, 8'd 95, 8'd 94, 8'd108, 8'd123, 8'd108, 
  8'd125, 8'd110, 8'd124, 8'd110, 8'd 95, 8'd 94, 8'd125, 8'd111, 
  8'd111, 8'd 79, 8'd125, 8'd126, 8'd111, 8'd111, 8'd 79, 8'd108, 
  
  8'd123, 8'd 93, 8'd110, 8'd110, 8'd124, 8'd125, 8'd140, 8'd153, 
  8'd125, 8'd127, 8'd140, 8'd109, 8'd111, 8'd143, 8'd127, 8'd111, 
  8'd 79, 8'd108, 8'd123, 8'd 63, 8'd125, 8'd110, 8'd 94, 8'd110, 
  8'd 95, 8'd 79, 8'd125, 8'd111, 8'd110, 8'd 78, 8'd110, 8'd111, 
  
  8'd111, 8'd 95, 8'd 94, 8'd108, 8'd123, 8'd108, 8'd125, 8'd110, 
  8'd124, 8'd110, 8'd 95, 8'd 94, 8'd125, 8'd111, 8'd111, 8'd 79, 
  8'd125, 8'd126, 8'd111, 8'd111, 8'd 79, 8'd108, 8'd123, 8'd 93, 
  8'd 91, 8'd171, 8'd134, 8'd141, 8'd121, 8'd140, 8'd 61, 8'd154, 
  
  8'd121, 8'd140, 8'd 61, 8'd154, 8'd111, 8'd111, 8'd125, 8'd110, 
  8'd110, 8'd 94, 8'd124, 8'd108, 8'd124, 8'd107, 8'd125, 8'd141, 
  8'd179, 8'd153, 8'd125, 8'd107, 8'd125, 8'd141, 8'd179, 8'd153, 
  8'd125, 8'd107, 8'd125, 8'd141, 8'd179, 8'd153, 8'd125, 8'd140, 

  8'd139, 8'd182, 8'd182, 8'd152, 8'd136, 8'd152, 8'd136, 8'd153, 
  8'd136, 8'd139, 8'd111, 8'd136, 8'd139, 8'd111, 8'd155, 8'd154, 
  8'd139, 8'd153, 8'd139, 8'd123, 8'd123, 8'd 63, 8'd153, 8'd166, 
  8'd183, 8'd140, 8'd136, 8'd153, 8'd154, 8'd166, 8'd183, 8'd140, 
  
  8'd136, 8'd153, 8'd154, 8'd166, 8'd183, 8'd140, 8'd136, 8'd153, 
  8'd154, 8'd170, 8'd153, 8'd123, 8'd123, 8'd107, 8'd121, 8'd107, 
  8'd121, 8'd167, 8'd151, 8'd183, 8'd140, 8'd151, 8'd183, 8'd140, 
  8'd170, 8'd154, 8'd139, 8'd153, 8'd139, 8'd123, 8'd123, 8'd 63, 
  
  8'd124, 8'd166, 8'd183, 8'd140, 8'd136, 8'd153, 8'd154, 8'd166, 
  8'd183, 8'd140, 8'd136, 8'd153, 8'd154, 8'd166, 8'd183, 8'd140, 
  8'd136, 8'd153, 8'd154, 8'd170, 8'd153, 8'd138, 8'd138, 8'd122, 
  8'd121, 8'd122, 8'd121, 8'd167, 8'd151, 8'd183, 8'd140, 8'd151, 
  
  8'd183, 8'd140, 8'd141, 8'd111, 8'd140, 8'd140, 8'd140, 8'd140, 
  8'd140, 8'd 92, 8'd137, 8'd138, 8'd140, 8'd152, 8'd138, 8'd139, 
  8'd153, 8'd 74, 8'd149, 8'd 92, 8'd139, 8'd107, 8'd122, 8'd152, 
  8'd140, 8'd179, 8'd166, 8'd182, 8'd140, 8'd227, 8'd122, 8'd197, 

  8'd154, 8'd196, 8'd196, 8'd167, 8'd154, 8'd152, 8'd167, 8'd182, 
  8'd182, 8'd134, 8'd149, 8'd136, 8'd153, 8'd121, 8'd136, 8'd137, 
  8'd169, 8'd194, 8'd166, 8'd167, 8'd154, 8'd167, 8'd137, 8'd182, 
  8'd154, 8'd196, 8'd167, 8'd167, 8'd154, 8'd152, 8'd167, 8'd182, 
  
  8'd182, 8'd134, 8'd149, 8'd136, 8'd153, 8'd121, 8'd136, 8'd122, 
  8'd169, 8'd208, 8'd166, 8'd167, 8'd154, 8'd152, 8'd167, 8'd182, 
  8'd138, 8'd153, 8'd136, 8'd167, 8'd152, 8'd152, 8'd107, 8'd167, 
  8'd 91, 8'd122, 8'd107, 8'd167, 8'd107, 8'd167, 8'd 91, 8'd107, 
  
  8'd107, 8'd167, 8'd139, 8'd139, 8'd139, 8'd139, 8'd139, 8'd139, 
  8'd139, 8'd139, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 

  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154
};

parameter  logic [52*64*7-1:0] CTX_INIT_STATE_ROM = {
{
7'd 81, 7'd 49, 7'd 81, 7'd  1, 7'd 65, 7'd 81, 7'd 17, 7'd 33, 
7'd 49, 7'd 65, 7'd 81, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 7'd 81, 
7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 7'd 81, 7'd 62, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 81, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd110, 7'd 62, 7'd 46, 
7'd 30, 7'd 14, 7'd124, 7'd 94, 7'd 78, 7'd 62, 7'd 30, 7'd 14, 
7'd124, 7'd124, 7'd110, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 75, 7'd 45, 7'd 77, 7'd  2, 7'd 61, 7'd 77, 7'd 13, 7'd 29, 
7'd 45, 7'd 61, 7'd 77, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 79, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 79, 7'd 64, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 79, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd110, 7'd 62, 7'd 46, 
7'd 30, 7'd 14, 7'd124, 7'd 94, 7'd 78, 7'd 62, 7'd 30, 7'd 14, 
7'd124, 7'd124, 7'd108, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 71, 7'd 41, 7'd 73, 7'd  6, 7'd 57, 7'd 73, 7'd 11, 7'd 27, 
7'd 43, 7'd 59, 7'd 75, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 77, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 77, 7'd 64, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 79, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd108, 7'd 60, 7'd 44, 
7'd 28, 7'd 12, 7'd124, 7'd 92, 7'd 76, 7'd 60, 7'd 28, 7'd 12, 
7'd124, 7'd124, 7'd104, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 65, 7'd 37, 7'd 69, 7'd  8, 7'd 55, 7'd 71, 7'd  9, 7'd 25, 
7'd 41, 7'd 57, 7'd 73, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 7'd 75, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 77, 7'd 64, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 79, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd108, 7'd 60, 7'd 44, 
7'd 28, 7'd 12, 7'd122, 7'd 90, 7'd 74, 7'd 58, 7'd 26, 7'd 10, 
7'd124, 7'd124, 7'd102, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 61, 7'd 33, 7'd 65, 7'd 12, 7'd 51, 7'd 67, 7'd  7, 7'd 23, 
7'd 39, 7'd 55, 7'd 71, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 73, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 7'd 75, 7'd 66, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 77, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd106, 7'd 58, 7'd 42, 
7'd 26, 7'd 10, 7'd120, 7'd 88, 7'd 72, 7'd 56, 7'd 24, 7'd  8, 
7'd124, 7'd124, 7'd 98, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 55, 7'd 29, 7'd 61, 7'd 14, 7'd 49, 7'd 65, 7'd  3, 7'd 19, 
7'd 35, 7'd 51, 7'd 67, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 71, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 73, 7'd 66, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 77, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd104, 7'd 56, 7'd 40, 
7'd 24, 7'd  8, 7'd118, 7'd 86, 7'd 70, 7'd 54, 7'd 22, 7'd  6, 
7'd124, 7'd124, 7'd 96, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 51, 7'd 25, 7'd 57, 7'd 18, 7'd 45, 7'd 61, 7'd  1, 7'd 17, 
7'd 33, 7'd 49, 7'd 65, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 69, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 73, 7'd 66, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 77, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd104, 7'd 56, 7'd 40, 
7'd 24, 7'd  8, 7'd116, 7'd 84, 7'd 68, 7'd 52, 7'd 20, 7'd  4, 
7'd124, 7'd124, 7'd 92, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 45, 7'd 21, 7'd 53, 7'd 20, 7'd 43, 7'd 59, 7'd  0, 7'd 15, 
7'd 31, 7'd 47, 7'd 63, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 67, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 71, 7'd 68, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 75, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 58, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd102, 7'd 54, 7'd 38, 
7'd 22, 7'd  6, 7'd114, 7'd 82, 7'd 66, 7'd 50, 7'd 18, 7'd  2, 
7'd124, 7'd124, 7'd 90, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 41, 7'd 19, 7'd 51, 7'd 24, 7'd 39, 7'd 55, 7'd  2, 7'd 13, 
7'd 29, 7'd 45, 7'd 61, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 71, 7'd 68, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 75, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 58, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd100, 7'd 52, 7'd 36, 
7'd 20, 7'd  4, 7'd112, 7'd 80, 7'd 64, 7'd 48, 7'd 16, 7'd  0, 
7'd124, 7'd124, 7'd 86, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 35, 7'd 15, 7'd 47, 7'd 28, 7'd 35, 7'd 51, 7'd  6, 7'd  9, 
7'd 25, 7'd 41, 7'd 57, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 69, 7'd 68, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 75, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 58, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd100, 7'd 52, 7'd 36, 
7'd 20, 7'd  4, 7'd110, 7'd 78, 7'd 62, 7'd 46, 7'd 14, 7'd  1, 
7'd124, 7'd124, 7'd 82, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 31, 7'd 11, 7'd 43, 7'd 30, 7'd 33, 7'd 49, 7'd  8, 7'd  7, 
7'd 23, 7'd 39, 7'd 55, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 67, 7'd 70, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 73, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 98, 7'd 50, 7'd 34, 
7'd 18, 7'd  2, 7'd108, 7'd 76, 7'd 60, 7'd 44, 7'd 12, 7'd  3, 
7'd124, 7'd124, 7'd 80, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 25, 7'd  7, 7'd 39, 7'd 34, 7'd 29, 7'd 45, 7'd 10, 7'd  5, 
7'd 21, 7'd 37, 7'd 53, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 67, 7'd 70, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 73, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 98, 7'd 50, 7'd 34, 
7'd 18, 7'd  2, 7'd106, 7'd 74, 7'd 58, 7'd 42, 7'd 10, 7'd  5, 
7'd124, 7'd124, 7'd 76, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 21, 7'd  3, 7'd 35, 7'd 36, 7'd 27, 7'd 43, 7'd 12, 7'd  3, 
7'd 19, 7'd 35, 7'd 51, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 7'd 70, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 73, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 96, 7'd 48, 7'd 32, 
7'd 16, 7'd  0, 7'd104, 7'd 72, 7'd 56, 7'd 40, 7'd  8, 7'd  7, 
7'd124, 7'd122, 7'd 74, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 15, 7'd  0, 7'd 31, 7'd 40, 7'd 23, 7'd 39, 7'd 16, 7'd  0, 
7'd 15, 7'd 31, 7'd 47, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 94, 7'd 46, 7'd 30, 
7'd 14, 7'd  1, 7'd102, 7'd 70, 7'd 54, 7'd 38, 7'd  6, 7'd  9, 
7'd124, 7'd118, 7'd 70, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 11, 7'd  4, 7'd 27, 7'd 42, 7'd 21, 7'd 37, 7'd 18, 7'd  2, 
7'd 13, 7'd 29, 7'd 45, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 94, 7'd 46, 7'd 30, 
7'd 14, 7'd  1, 7'd100, 7'd 68, 7'd 52, 7'd 36, 7'd  4, 7'd 11, 
7'd124, 7'd116, 7'd 68, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  5, 7'd  8, 7'd 23, 7'd 46, 7'd 17, 7'd 33, 7'd 20, 7'd  4, 
7'd 11, 7'd 27, 7'd 43, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 92, 7'd 44, 7'd 28, 
7'd 12, 7'd  3, 7'd 98, 7'd 66, 7'd 50, 7'd 34, 7'd  2, 7'd 13, 
7'd122, 7'd112, 7'd 64, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  1, 7'd 10, 7'd 21, 7'd 48, 7'd 15, 7'd 31, 7'd 22, 7'd  6, 
7'd  9, 7'd 25, 7'd 41, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 7'd 42, 7'd 26, 
7'd 10, 7'd  5, 7'd 96, 7'd 64, 7'd 48, 7'd 32, 7'd  0, 7'd 15, 
7'd118, 7'd108, 7'd 60, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  4, 7'd 14, 7'd 17, 7'd 52, 7'd 11, 7'd 27, 7'd 26, 7'd 10, 
7'd  5, 7'd 21, 7'd 37, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 7'd 74, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 69, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 7'd 42, 7'd 26, 
7'd 10, 7'd  5, 7'd 96, 7'd 64, 7'd 48, 7'd 32, 7'd  0, 7'd 15, 
7'd116, 7'd106, 7'd 58, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  8, 7'd 18, 7'd 13, 7'd 56, 7'd  7, 7'd 23, 7'd 28, 7'd 12, 
7'd  3, 7'd 19, 7'd 35, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 74, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 69, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 88, 7'd 40, 7'd 24, 
7'd  8, 7'd  7, 7'd 94, 7'd 62, 7'd 46, 7'd 30, 7'd  1, 7'd 17, 
7'd114, 7'd102, 7'd 54, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 14, 7'd 22, 7'd  9, 7'd 58, 7'd  5, 7'd 21, 7'd 30, 7'd 14, 
7'd  1, 7'd 17, 7'd 33, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 74, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 69, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 88, 7'd 40, 7'd 24, 
7'd  8, 7'd  7, 7'd 92, 7'd 60, 7'd 44, 7'd 28, 7'd  3, 7'd 19, 
7'd112, 7'd100, 7'd 52, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 18, 7'd 26, 7'd  5, 7'd 62, 7'd  1, 7'd 17, 7'd 32, 7'd 16, 
7'd  0, 7'd 15, 7'd 31, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 76, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 67, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 86, 7'd 38, 7'd 22, 
7'd  6, 7'd  9, 7'd 90, 7'd 58, 7'd 42, 7'd 26, 7'd  5, 7'd 21, 
7'd108, 7'd 96, 7'd 48, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 24, 7'd 30, 7'd  1, 7'd 64, 7'd  0, 7'd 15, 7'd 36, 7'd 20, 
7'd  4, 7'd 11, 7'd 27, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 76, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 67, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 84, 7'd 36, 7'd 20, 
7'd  4, 7'd 11, 7'd 88, 7'd 56, 7'd 40, 7'd 24, 7'd  7, 7'd 23, 
7'd106, 7'd 94, 7'd 46, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 28, 7'd 34, 7'd  2, 7'd 68, 7'd  4, 7'd 11, 7'd 38, 7'd 22, 
7'd  6, 7'd  9, 7'd 25, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 76, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 67, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 84, 7'd 36, 7'd 20, 
7'd  4, 7'd 11, 7'd 86, 7'd 54, 7'd 38, 7'd 22, 7'd  9, 7'd 25, 
7'd104, 7'd 90, 7'd 42, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 34, 7'd 38, 7'd  6, 7'd 70, 7'd  6, 7'd  9, 7'd 40, 7'd 24, 
7'd  8, 7'd  7, 7'd 23, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 65, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 48, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 82, 7'd 34, 7'd 18, 
7'd  2, 7'd 13, 7'd 84, 7'd 52, 7'd 36, 7'd 20, 7'd 11, 7'd 27, 
7'd102, 7'd 88, 7'd 40, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 38, 7'd 40, 7'd  8, 7'd 74, 7'd 10, 7'd  5, 7'd 42, 7'd 26, 
7'd 10, 7'd  5, 7'd 21, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 65, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 48, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 80, 7'd 32, 7'd 16, 
7'd  0, 7'd 15, 7'd 82, 7'd 50, 7'd 34, 7'd 18, 7'd 13, 7'd 29, 
7'd 98, 7'd 84, 7'd 36, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 44, 7'd 44, 7'd 12, 7'd 78, 7'd 14, 7'd  1, 7'd 46, 7'd 30, 
7'd 14, 7'd  1, 7'd 17, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 65, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 48, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 80, 7'd 32, 7'd 16, 
7'd  0, 7'd 15, 7'd 80, 7'd 48, 7'd 32, 7'd 16, 7'd 15, 7'd 31, 
7'd 96, 7'd 80, 7'd 32, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 48, 7'd 48, 7'd 16, 7'd 80, 7'd 16, 7'd  0, 7'd 48, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 80, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 78, 7'd 30, 7'd 14, 
7'd  1, 7'd 17, 7'd 78, 7'd 46, 7'd 30, 7'd 14, 7'd 17, 7'd 33, 
7'd 94, 7'd 78, 7'd 30, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 54, 7'd 52, 7'd 20, 7'd 84, 7'd 20, 7'd  4, 7'd 50, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 80, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 78, 7'd 30, 7'd 14, 
7'd  1, 7'd 17, 7'd 76, 7'd 44, 7'd 28, 7'd 12, 7'd 19, 7'd 35, 
7'd 92, 7'd 74, 7'd 26, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 58, 7'd 56, 7'd 24, 7'd 86, 7'd 22, 7'd  6, 7'd 52, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 80, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 76, 7'd 28, 7'd 12, 
7'd  3, 7'd 19, 7'd 74, 7'd 42, 7'd 26, 7'd 10, 7'd 21, 7'd 37, 
7'd 88, 7'd 72, 7'd 24, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 64, 7'd 60, 7'd 28, 7'd 90, 7'd 26, 7'd 10, 7'd 56, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 74, 7'd 26, 7'd 10, 
7'd  5, 7'd 21, 7'd 72, 7'd 40, 7'd 24, 7'd  8, 7'd 23, 7'd 39, 
7'd 86, 7'd 68, 7'd 20, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 68, 7'd 64, 7'd 32, 7'd 92, 7'd 28, 7'd 12, 7'd 58, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 74, 7'd 26, 7'd 10, 
7'd  5, 7'd 21, 7'd 70, 7'd 38, 7'd 22, 7'd  6, 7'd 25, 7'd 41, 
7'd 84, 7'd 66, 7'd 18, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 74, 7'd 68, 7'd 36, 7'd 96, 7'd 32, 7'd 16, 7'd 60, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 72, 7'd 24, 7'd  8, 
7'd  7, 7'd 23, 7'd 68, 7'd 36, 7'd 20, 7'd  4, 7'd 27, 7'd 43, 
7'd 82, 7'd 62, 7'd 14, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 78, 7'd 70, 7'd 38, 7'd 98, 7'd 34, 7'd 18, 7'd 62, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 70, 7'd 22, 7'd  6, 
7'd  9, 7'd 25, 7'd 66, 7'd 34, 7'd 18, 7'd  2, 7'd 29, 7'd 45, 
7'd 78, 7'd 58, 7'd 10, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 84, 7'd 74, 7'd 42, 7'd102, 7'd 38, 7'd 22, 7'd 66, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 84, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 70, 7'd 22, 7'd  6, 
7'd  9, 7'd 25, 7'd 66, 7'd 34, 7'd 18, 7'd  2, 7'd 29, 7'd 45, 
7'd 76, 7'd 56, 7'd  8, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 88, 7'd 78, 7'd 46, 7'd106, 7'd 42, 7'd 26, 7'd 68, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 84, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 68, 7'd 20, 7'd  4, 
7'd 11, 7'd 27, 7'd 64, 7'd 32, 7'd 16, 7'd  0, 7'd 31, 7'd 47, 
7'd 74, 7'd 52, 7'd  4, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 94, 7'd 82, 7'd 50, 7'd108, 7'd 44, 7'd 28, 7'd 70, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 84, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 68, 7'd 20, 7'd  4, 
7'd 11, 7'd 27, 7'd 62, 7'd 30, 7'd 14, 7'd  1, 7'd 33, 7'd 49, 
7'd 72, 7'd 50, 7'd  2, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 98, 7'd 86, 7'd 54, 7'd112, 7'd 48, 7'd 32, 7'd 72, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 86, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 66, 7'd 18, 7'd  2, 
7'd 13, 7'd 29, 7'd 60, 7'd 28, 7'd 12, 7'd  3, 7'd 35, 7'd 51, 
7'd 68, 7'd 46, 7'd  1, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd104, 7'd 90, 7'd 58, 7'd114, 7'd 50, 7'd 34, 7'd 76, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 86, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 64, 7'd 16, 7'd  0, 
7'd 15, 7'd 31, 7'd 58, 7'd 26, 7'd 10, 7'd  5, 7'd 37, 7'd 53, 
7'd 66, 7'd 44, 7'd  3, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd108, 7'd 94, 7'd 62, 7'd118, 7'd 54, 7'd 38, 7'd 78, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 86, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 64, 7'd 16, 7'd  0, 
7'd 15, 7'd 31, 7'd 56, 7'd 24, 7'd  8, 7'd  7, 7'd 39, 7'd 55, 
7'd 64, 7'd 40, 7'd  7, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd114, 7'd 98, 7'd 66, 7'd120, 7'd 56, 7'd 40, 7'd 80, 7'd 64, 
7'd 48, 7'd 32, 7'd 16, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 
7'd 64, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 88, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 38, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 62, 7'd 14, 7'd  1, 
7'd 17, 7'd 33, 7'd 54, 7'd 22, 7'd  6, 7'd  9, 7'd 41, 7'd 57, 
7'd 62, 7'd 38, 7'd  9, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd118, 7'd100, 7'd 68, 7'd124, 7'd 60, 7'd 44, 7'd 82, 7'd 66, 
7'd 50, 7'd 34, 7'd 18, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 
7'd 64, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 88, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 38, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 60, 7'd 12, 7'd  3, 
7'd 19, 7'd 35, 7'd 52, 7'd 20, 7'd  4, 7'd 11, 7'd 43, 7'd 59, 
7'd 58, 7'd 34, 7'd 13, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd104, 7'd 72, 7'd124, 7'd 64, 7'd 48, 7'd 86, 7'd 70, 
7'd 54, 7'd 38, 7'd 22, 7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 
7'd 66, 7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 88, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 38, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 60, 7'd 12, 7'd  3, 
7'd 19, 7'd 35, 7'd 50, 7'd 18, 7'd  2, 7'd 13, 7'd 45, 7'd 61, 
7'd 56, 7'd 30, 7'd 17, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd108, 7'd 76, 7'd124, 7'd 66, 7'd 50, 7'd 88, 7'd 72, 
7'd 56, 7'd 40, 7'd 24, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 
7'd 68, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 58, 7'd 10, 7'd  5, 
7'd 21, 7'd 37, 7'd 48, 7'd 16, 7'd  0, 7'd 15, 7'd 47, 7'd 63, 
7'd 54, 7'd 28, 7'd 19, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd112, 7'd 80, 7'd124, 7'd 70, 7'd 54, 7'd 90, 7'd 74, 
7'd 58, 7'd 42, 7'd 26, 7'd 64, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 
7'd 68, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 58, 7'd 10, 7'd  5, 
7'd 21, 7'd 37, 7'd 46, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 65, 
7'd 52, 7'd 24, 7'd 23, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd116, 7'd 84, 7'd124, 7'd 72, 7'd 56, 7'd 92, 7'd 76, 
7'd 60, 7'd 44, 7'd 28, 7'd 66, 7'd 50, 7'd 34, 7'd 18, 7'd  2, 
7'd 70, 7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 90, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 56, 7'd  8, 7'd  7, 
7'd 23, 7'd 39, 7'd 44, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 67, 
7'd 48, 7'd 22, 7'd 25, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd120, 7'd 88, 7'd124, 7'd 76, 7'd 60, 7'd 96, 7'd 80, 
7'd 64, 7'd 48, 7'd 32, 7'd 68, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 
7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 54, 7'd  6, 7'd  9, 
7'd 25, 7'd 41, 7'd 42, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 69, 
7'd 46, 7'd 18, 7'd 29, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd 92, 7'd124, 7'd 78, 7'd 62, 7'd 98, 7'd 82, 
7'd 66, 7'd 50, 7'd 34, 7'd 70, 7'd 54, 7'd 38, 7'd 22, 7'd  6, 
7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 54, 7'd  6, 7'd  9, 
7'd 25, 7'd 41, 7'd 40, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 71, 
7'd 44, 7'd 16, 7'd 31, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd 96, 7'd124, 7'd 82, 7'd 66, 7'd100, 7'd 84, 
7'd 68, 7'd 52, 7'd 36, 7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 
7'd 74, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 52, 7'd  4, 7'd 11, 
7'd 27, 7'd 43, 7'd 38, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 73, 
7'd 42, 7'd 12, 7'd 35, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd 98, 7'd124, 7'd 84, 7'd 68, 7'd102, 7'd 86, 
7'd 70, 7'd 54, 7'd 38, 7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 
7'd 74, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 50, 7'd  2, 7'd 13, 
7'd 29, 7'd 45, 7'd 36, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 75, 
7'd 38, 7'd  8, 7'd 39, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd102, 7'd124, 7'd 88, 7'd 72, 7'd106, 7'd 90, 
7'd 74, 7'd 58, 7'd 42, 7'd 74, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 
7'd 76, 7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 94, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 50, 7'd  2, 7'd 13, 
7'd 29, 7'd 45, 7'd 36, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 75, 
7'd 36, 7'd  6, 7'd 41, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd106, 7'd124, 7'd 92, 7'd 76, 7'd108, 7'd 92, 
7'd 76, 7'd 60, 7'd 44, 7'd 76, 7'd 60, 7'd 44, 7'd 28, 7'd 12, 
7'd 78, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 94, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 48, 7'd  0, 7'd 15, 
7'd 31, 7'd 47, 7'd 34, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 77, 
7'd 34, 7'd  2, 7'd 45, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd110, 7'd124, 7'd 94, 7'd 78, 7'd110, 7'd 94, 
7'd 78, 7'd 62, 7'd 46, 7'd 78, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 
7'd 78, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 94, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 48, 7'd  0, 7'd 15, 
7'd 31, 7'd 47, 7'd 32, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 79, 
7'd 32, 7'd  0, 7'd 47, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
}
};

parameter  logic   [8*4*64-1:0]   AUC_LPS_TABLE= {
  { 8'd128, 8'd176, 8'd208, 8'd240},
  { 8'd128, 8'd167, 8'd197, 8'd227},
  { 8'd128, 8'd158, 8'd187, 8'd216},
  { 8'd123, 8'd150, 8'd178, 8'd205},
  { 8'd116, 8'd142, 8'd169, 8'd195},
  { 8'd111, 8'd135, 8'd160, 8'd185},
  { 8'd105, 8'd128, 8'd152, 8'd175},
  { 8'd100, 8'd122, 8'd144, 8'd166},
  {  8'd95, 8'd116, 8'd137, 8'd158},
  {  8'd90, 8'd110, 8'd130, 8'd150},
  {  8'd85, 8'd104, 8'd123, 8'd142},
  {  8'd81,  8'd99, 8'd117, 8'd135},
  {  8'd77,  8'd94, 8'd111, 8'd128},
  {  8'd73,  8'd89, 8'd105, 8'd122},
  {  8'd69,  8'd85, 8'd100, 8'd116},
  {  8'd66,  8'd80,  8'd95, 8'd110},
  {  8'd62,  8'd76,  8'd90, 8'd104},
  {  8'd59,  8'd72,  8'd86,  8'd99},
  {  8'd56,  8'd69,  8'd81,  8'd94},
  {  8'd53,  8'd65,  8'd77,  8'd89},
  {  8'd51,  8'd62,  8'd73,  8'd85},
  {  8'd48,  8'd59,  8'd69,  8'd80},
  {  8'd46,  8'd56,  8'd66,  8'd76},
  {  8'd43,  8'd53,  8'd63,  8'd72},
  {  8'd41,  8'd50,  8'd59,  8'd69},
  {  8'd39,  8'd48,  8'd56,  8'd65},
  {  8'd37,  8'd45,  8'd54,  8'd62},
  {  8'd35,  8'd43,  8'd51,  8'd59},
  {  8'd33,  8'd41,  8'd48,  8'd56},
  {  8'd32,  8'd39,  8'd46,  8'd53},
  {  8'd30,  8'd37,  8'd43,  8'd50},
  {  8'd29,  8'd35,  8'd41,  8'd48},
  {  8'd27,  8'd33,  8'd39,  8'd45},
  {  8'd26,  8'd31,  8'd37,  8'd43},
  {  8'd24,  8'd30,  8'd35,  8'd41},
  {  8'd23,  8'd28,  8'd33,  8'd39},
  {  8'd22,  8'd27,  8'd32,  8'd37},
  {  8'd21,  8'd26,  8'd30,  8'd35},
  {  8'd20,  8'd24,  8'd29,  8'd33},
  {  8'd19,  8'd23,  8'd27,  8'd31},
  {  8'd18,  8'd22,  8'd26,  8'd30},
  {  8'd17,  8'd21,  8'd25,  8'd28},
  {  8'd16,  8'd20,  8'd23,  8'd27},
  {  8'd15,  8'd19,  8'd22,  8'd25},
  {  8'd14,  8'd18,  8'd21,  8'd24},
  {  8'd14,  8'd17,  8'd20,  8'd23},
  {  8'd13,  8'd16,  8'd19,  8'd22},
  {  8'd12,  8'd15,  8'd18,  8'd21},
  {  8'd12,  8'd14,  8'd17,  8'd20},
  {  8'd11,  8'd14,  8'd16,  8'd19},
  {  8'd11,  8'd13,  8'd15,  8'd18},
  {  8'd10,  8'd12,  8'd15,  8'd17},
  {  8'd10,  8'd12,  8'd14,  8'd16},
  {  8'd 9,  8'd11,  8'd13,  8'd15},
  {  8'd 9,  8'd11,  8'd12,  8'd14},
  {  8'd 8,  8'd10,  8'd12,  8'd14},
  {  8'd 8,  8'd 9,  8'd11,  8'd13},
  {  8'd 7,  8'd 9,  8'd11,  8'd12},
  {  8'd 7,  8'd 9,  8'd10,  8'd12},
  {  8'd 7,  8'd 8,  8'd10,  8'd11},
  {  8'd 6,  8'd 8,  8'd 9,  8'd11},
  {  8'd 6,  8'd 7,  8'd 9,  8'd10},
  {  8'd 6,  8'd 7,  8'd 8,  8'd 9},
  {  8'd 2,  8'd 2,  8'd 2,  8'd 2}
};

parameter  logic   [3*4*64-1:0]   AUC_RENORM_TABLE= {
  {   3'h1,   3'h1,   3'h1,   3'h1},
  {   3'h1,   3'h1,   3'h1,   3'h1},
  {   3'h1,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h2},
  {   3'h2,   3'h2,   3'h2,   3'h2},
  {   3'h2,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h4,   3'h3},
  {   3'h4,   3'h4,   3'h4,   3'h3},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h6,   3'h5,   3'h5},
  {   3'h6,   3'h6,   3'h5,   3'h5},
  {   3'h6,   3'h6,   3'h6,   3'h6}
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

parameter  logic   [7*128-1:0]  AUC_NXT_STATE_MPS = {
  7'd2,   7'd3,   7'd4,   7'd5,   7'd6,   7'd7,   7'd8,   7'd9,   7'd10,  7'd11,  7'd12,  7'd13,  7'd14,  7'd15,  7'd16,  7'd17,
  7'd18,  7'd19,  7'd20,  7'd21,  7'd22,  7'd23,  7'd24,  7'd25,  7'd26,  7'd27,  7'd28,  7'd29,  7'd30,  7'd31,  7'd32,  7'd33,
  7'd34,  7'd35,  7'd36,  7'd37,  7'd38,  7'd39,  7'd40,  7'd41,  7'd42,  7'd43,  7'd44,  7'd45,  7'd46,  7'd47,  7'd48,  7'd49,
  7'd50,  7'd51,  7'd52,  7'd53,  7'd54,  7'd55,  7'd56,  7'd57,  7'd58,  7'd59,  7'd60,  7'd61,  7'd62,  7'd63,  7'd64,  7'd65,
  7'd66,  7'd67,  7'd68,  7'd69,  7'd70,  7'd71,  7'd72,  7'd73,  7'd74,  7'd75,  7'd76,  7'd77,  7'd78,  7'd79,  7'd80,  7'd81,
  7'd82,  7'd83,  7'd84,  7'd85,  7'd86,  7'd87,  7'd88,  7'd89,  7'd90,  7'd91,  7'd92,  7'd93,  7'd94,  7'd95,  7'd96,  7'd97,
  7'd98,  7'd99,  7'd100, 7'd101, 7'd102, 7'd103, 7'd104, 7'd105, 7'd106, 7'd107, 7'd108, 7'd109, 7'd110, 7'd111, 7'd112, 7'd113,
  7'd114, 7'd115, 7'd116, 7'd117, 7'd118, 7'd119, 7'd120, 7'd121, 7'd122, 7'd123, 7'd124, 7'd125, 7'd124, 7'd125, 7'd126, 7'd127
};

parameter  logic   [7*128-1:0]  AUC_NXT_STATE_LPS = {
  7'd1,   7'd0,   7'd0,   7'd1,   7'd2,   7'd3,   7'd4,   7'd5,   7'd4,   7'd5,   7'd8,   7'd9,   7'd8,   7'd9,   7'd10,  7'd11,
  7'd12,  7'd13,  7'd14,  7'd15,  7'd16,  7'd17,  7'd18,  7'd19,  7'd18,  7'd19,  7'd22,  7'd23,  7'd22,  7'd23,  7'd24,  7'd25,
  7'd26,  7'd27,  7'd26,  7'd27,  7'd30,  7'd31,  7'd30,  7'd31,  7'd32,  7'd33,  7'd32,  7'd33,  7'd36,  7'd37,  7'd36,  7'd37,
  7'd38,  7'd39,  7'd38,  7'd39,  7'd42,  7'd43,  7'd42,  7'd43,  7'd44,  7'd45,  7'd44,  7'd45,  7'd46,  7'd47,  7'd48,  7'd49,
  7'd48,  7'd49,  7'd50,  7'd51,  7'd52,  7'd53,  7'd52,  7'd53,  7'd54,  7'd55,  7'd54,  7'd55,  7'd56,  7'd57,  7'd58,  7'd59,
  7'd58,  7'd59,  7'd60,  7'd61,  7'd60,  7'd61,  7'd60,  7'd61,  7'd62,  7'd63,  7'd64,  7'd65,  7'd64,  7'd65,  7'd66,  7'd67,
  7'd66,  7'd67,  7'd66,  7'd67,  7'd68,  7'd69,  7'd68,  7'd69,  7'd70,  7'd71,  7'd70,  7'd71,  7'd70,  7'd71,  7'd72,  7'd73,
  7'd72,  7'd73,  7'd72,  7'd73,  7'd74,  7'd75,  7'd74,  7'd75,  7'd74,  7'd75,  7'd76,  7'd77,  7'd76,  7'd77,  7'd126, 7'd127
};
`else
// Context init value
parameter  logic [0:566][7:0] CTX_INIT_VALUE = {
  8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd200, 8'd185, 
  8'd160, 8'd200, 8'd185, 8'd160, 8'd139, 8'd141, 8'd157, 8'd107, 
  8'd139, 8'd126, 8'd107, 8'd139, 8'd126, 8'd154, 8'd154, 8'd154, 
  8'd197, 8'd185, 8'd201, 8'd197, 8'd185, 8'd201, 8'd149, 8'd134, 

  8'd184, 8'd154, 8'd139, 8'd154, 8'd154, 8'd154, 8'd139, 8'd154, 
  8'd154, 8'd184, 8'd154, 8'd183, 8'd 63, 8'd152, 8'd152, 8'd 79, 
  8'd 79, 8'd110, 8'd154, 8'd122, 8'd137, 8'd 95, 8'd 79, 8'd 63, 
  8'd 31, 8'd 31, 8'd 95, 8'd 79, 8'd 63, 8'd 31, 8'd 31, 8'd153, 
  
  8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd153, 8'd168, 
  8'd168, 8'd168, 8'd168, 8'd153, 8'd138, 8'd138, 8'd124, 8'd138, 
  8'd 94, 8'd224, 8'd167, 8'd122, 8'd111, 8'd141, 8'd153, 8'd111, 
  8'd153, 8'd111, 8'd 94, 8'd138, 8'd182, 8'd154, 8'd149, 8'd107, 
  
  8'd167, 8'd154, 8'd149, 8'd 92, 8'd167, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd 94, 8'd138, 8'd182, 8'd154, 8'd149, 8'd107, 8'd167, 
  8'd154, 8'd149, 8'd 92, 8'd167, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd140, 8'd198, 8'd169, 8'd198, 8'd140, 8'd198, 8'd169, 8'd198, 
  
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd139, 8'd139, 
  8'd139, 8'd139, 8'd139, 8'd139, 8'd110, 8'd110, 8'd124, 8'd125, 
  8'd140, 8'd153, 8'd125, 8'd127, 8'd140, 8'd109, 8'd111, 8'd143, 
  8'd127, 8'd111, 8'd 79, 8'd108, 8'd123, 8'd 63, 8'd125, 8'd110, 

  8'd 94, 8'd110, 8'd 95, 8'd 79, 8'd125, 8'd111, 8'd110, 8'd 78, 
  8'd110, 8'd111, 8'd111, 8'd 95, 8'd 94, 8'd108, 8'd123, 8'd108, 
  8'd125, 8'd110, 8'd124, 8'd110, 8'd 95, 8'd 94, 8'd125, 8'd111, 
  8'd111, 8'd 79, 8'd125, 8'd126, 8'd111, 8'd111, 8'd 79, 8'd108, 
  
  8'd123, 8'd 93, 8'd110, 8'd110, 8'd124, 8'd125, 8'd140, 8'd153, 
  8'd125, 8'd127, 8'd140, 8'd109, 8'd111, 8'd143, 8'd127, 8'd111, 
  8'd 79, 8'd108, 8'd123, 8'd 63, 8'd125, 8'd110, 8'd 94, 8'd110, 
  8'd 95, 8'd 79, 8'd125, 8'd111, 8'd110, 8'd 78, 8'd110, 8'd111, 
  
  8'd111, 8'd 95, 8'd 94, 8'd108, 8'd123, 8'd108, 8'd125, 8'd110, 
  8'd124, 8'd110, 8'd 95, 8'd 94, 8'd125, 8'd111, 8'd111, 8'd 79, 
  8'd125, 8'd126, 8'd111, 8'd111, 8'd 79, 8'd108, 8'd123, 8'd 93, 
  8'd 91, 8'd171, 8'd134, 8'd141, 8'd121, 8'd140, 8'd 61, 8'd154, 
  
  8'd121, 8'd140, 8'd 61, 8'd154, 8'd111, 8'd111, 8'd125, 8'd110, 
  8'd110, 8'd 94, 8'd124, 8'd108, 8'd124, 8'd107, 8'd125, 8'd141, 
  8'd179, 8'd153, 8'd125, 8'd107, 8'd125, 8'd141, 8'd179, 8'd153, 
  8'd125, 8'd107, 8'd125, 8'd141, 8'd179, 8'd153, 8'd125, 8'd140, 

  8'd139, 8'd182, 8'd182, 8'd152, 8'd136, 8'd152, 8'd136, 8'd153, 
  8'd136, 8'd139, 8'd111, 8'd136, 8'd139, 8'd111, 8'd155, 8'd154, 
  8'd139, 8'd153, 8'd139, 8'd123, 8'd123, 8'd 63, 8'd153, 8'd166, 
  8'd183, 8'd140, 8'd136, 8'd153, 8'd154, 8'd166, 8'd183, 8'd140, 
  
  8'd136, 8'd153, 8'd154, 8'd166, 8'd183, 8'd140, 8'd136, 8'd153, 
  8'd154, 8'd170, 8'd153, 8'd123, 8'd123, 8'd107, 8'd121, 8'd107, 
  8'd121, 8'd167, 8'd151, 8'd183, 8'd140, 8'd151, 8'd183, 8'd140, 
  8'd170, 8'd154, 8'd139, 8'd153, 8'd139, 8'd123, 8'd123, 8'd 63, 
  
  8'd124, 8'd166, 8'd183, 8'd140, 8'd136, 8'd153, 8'd154, 8'd166, 
  8'd183, 8'd140, 8'd136, 8'd153, 8'd154, 8'd166, 8'd183, 8'd140, 
  8'd136, 8'd153, 8'd154, 8'd170, 8'd153, 8'd138, 8'd138, 8'd122, 
  8'd121, 8'd122, 8'd121, 8'd167, 8'd151, 8'd183, 8'd140, 8'd151, 
  
  8'd183, 8'd140, 8'd141, 8'd111, 8'd140, 8'd140, 8'd140, 8'd140, 
  8'd140, 8'd 92, 8'd137, 8'd138, 8'd140, 8'd152, 8'd138, 8'd139, 
  8'd153, 8'd 74, 8'd149, 8'd 92, 8'd139, 8'd107, 8'd122, 8'd152, 
  8'd140, 8'd179, 8'd166, 8'd182, 8'd140, 8'd227, 8'd122, 8'd197, 

  8'd154, 8'd196, 8'd196, 8'd167, 8'd154, 8'd152, 8'd167, 8'd182, 
  8'd182, 8'd134, 8'd149, 8'd136, 8'd153, 8'd121, 8'd136, 8'd137, 
  8'd169, 8'd194, 8'd166, 8'd167, 8'd154, 8'd167, 8'd137, 8'd182, 
  8'd154, 8'd196, 8'd167, 8'd167, 8'd154, 8'd152, 8'd167, 8'd182, 
  
  8'd182, 8'd134, 8'd149, 8'd136, 8'd153, 8'd121, 8'd136, 8'd122, 
  8'd169, 8'd208, 8'd166, 8'd167, 8'd154, 8'd152, 8'd167, 8'd182, 
  8'd138, 8'd153, 8'd136, 8'd167, 8'd152, 8'd152, 8'd107, 8'd167, 
  8'd 91, 8'd122, 8'd107, 8'd167, 8'd107, 8'd167, 8'd 91, 8'd107, 
  
  8'd107, 8'd167, 8'd139, 8'd139, 8'd139, 8'd139, 8'd139, 8'd139, 
  8'd139, 8'd139, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 

  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 
  8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154, 8'd154
};

parameter  logic [0:51][0:63][6:0] CTX_INIT_STATE_ROM = {
{
7'd 81, 7'd 49, 7'd 81, 7'd  1, 7'd 65, 7'd 81, 7'd 17, 7'd 33, 
7'd 49, 7'd 65, 7'd 81, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 7'd 81, 
7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 7'd 81, 7'd 62, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 81, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd110, 7'd 62, 7'd 46, 
7'd 30, 7'd 14, 7'd124, 7'd 94, 7'd 78, 7'd 62, 7'd 30, 7'd 14, 
7'd124, 7'd124, 7'd110, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 75, 7'd 45, 7'd 77, 7'd  2, 7'd 61, 7'd 77, 7'd 13, 7'd 29, 
7'd 45, 7'd 61, 7'd 77, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 79, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 79, 7'd 64, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 79, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd110, 7'd 62, 7'd 46, 
7'd 30, 7'd 14, 7'd124, 7'd 94, 7'd 78, 7'd 62, 7'd 30, 7'd 14, 
7'd124, 7'd124, 7'd108, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 71, 7'd 41, 7'd 73, 7'd  6, 7'd 57, 7'd 73, 7'd 11, 7'd 27, 
7'd 43, 7'd 59, 7'd 75, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 77, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 77, 7'd 64, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 79, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd108, 7'd 60, 7'd 44, 
7'd 28, 7'd 12, 7'd124, 7'd 92, 7'd 76, 7'd 60, 7'd 28, 7'd 12, 
7'd124, 7'd124, 7'd104, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 65, 7'd 37, 7'd 69, 7'd  8, 7'd 55, 7'd 71, 7'd  9, 7'd 25, 
7'd 41, 7'd 57, 7'd 73, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 7'd 75, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 77, 7'd 64, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 79, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd108, 7'd 60, 7'd 44, 
7'd 28, 7'd 12, 7'd122, 7'd 90, 7'd 74, 7'd 58, 7'd 26, 7'd 10, 
7'd124, 7'd124, 7'd102, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 61, 7'd 33, 7'd 65, 7'd 12, 7'd 51, 7'd 67, 7'd  7, 7'd 23, 
7'd 39, 7'd 55, 7'd 71, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 73, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 7'd 75, 7'd 66, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 77, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd106, 7'd 58, 7'd 42, 
7'd 26, 7'd 10, 7'd120, 7'd 88, 7'd 72, 7'd 56, 7'd 24, 7'd  8, 
7'd124, 7'd124, 7'd 98, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 55, 7'd 29, 7'd 61, 7'd 14, 7'd 49, 7'd 65, 7'd  3, 7'd 19, 
7'd 35, 7'd 51, 7'd 67, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 71, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 73, 7'd 66, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 77, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd104, 7'd 56, 7'd 40, 
7'd 24, 7'd  8, 7'd118, 7'd 86, 7'd 70, 7'd 54, 7'd 22, 7'd  6, 
7'd124, 7'd124, 7'd 96, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 51, 7'd 25, 7'd 57, 7'd 18, 7'd 45, 7'd 61, 7'd  1, 7'd 17, 
7'd 33, 7'd 49, 7'd 65, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 69, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 73, 7'd 66, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 77, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd104, 7'd 56, 7'd 40, 
7'd 24, 7'd  8, 7'd116, 7'd 84, 7'd 68, 7'd 52, 7'd 20, 7'd  4, 
7'd124, 7'd124, 7'd 92, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 45, 7'd 21, 7'd 53, 7'd 20, 7'd 43, 7'd 59, 7'd  0, 7'd 15, 
7'd 31, 7'd 47, 7'd 63, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 67, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 71, 7'd 68, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 75, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 58, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd102, 7'd 54, 7'd 38, 
7'd 22, 7'd  6, 7'd114, 7'd 82, 7'd 66, 7'd 50, 7'd 18, 7'd  2, 
7'd124, 7'd124, 7'd 90, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 41, 7'd 19, 7'd 51, 7'd 24, 7'd 39, 7'd 55, 7'd  2, 7'd 13, 
7'd 29, 7'd 45, 7'd 61, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 71, 7'd 68, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 75, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 58, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd100, 7'd 52, 7'd 36, 
7'd 20, 7'd  4, 7'd112, 7'd 80, 7'd 64, 7'd 48, 7'd 16, 7'd  0, 
7'd124, 7'd124, 7'd 86, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 35, 7'd 15, 7'd 47, 7'd 28, 7'd 35, 7'd 51, 7'd  6, 7'd  9, 
7'd 25, 7'd 41, 7'd 57, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 69, 7'd 68, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 75, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 58, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd100, 7'd 52, 7'd 36, 
7'd 20, 7'd  4, 7'd110, 7'd 78, 7'd 62, 7'd 46, 7'd 14, 7'd  1, 
7'd124, 7'd124, 7'd 82, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 31, 7'd 11, 7'd 43, 7'd 30, 7'd 33, 7'd 49, 7'd  8, 7'd  7, 
7'd 23, 7'd 39, 7'd 55, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 67, 7'd 70, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 73, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 98, 7'd 50, 7'd 34, 
7'd 18, 7'd  2, 7'd108, 7'd 76, 7'd 60, 7'd 44, 7'd 12, 7'd  3, 
7'd124, 7'd124, 7'd 80, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 25, 7'd  7, 7'd 39, 7'd 34, 7'd 29, 7'd 45, 7'd 10, 7'd  5, 
7'd 21, 7'd 37, 7'd 53, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 67, 7'd 70, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 73, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 98, 7'd 50, 7'd 34, 
7'd 18, 7'd  2, 7'd106, 7'd 74, 7'd 58, 7'd 42, 7'd 10, 7'd  5, 
7'd124, 7'd124, 7'd 76, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 21, 7'd  3, 7'd 35, 7'd 36, 7'd 27, 7'd 43, 7'd 12, 7'd  3, 
7'd 19, 7'd 35, 7'd 51, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 65, 7'd 70, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 73, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 96, 7'd 48, 7'd 32, 
7'd 16, 7'd  0, 7'd104, 7'd 72, 7'd 56, 7'd 40, 7'd  8, 7'd  7, 
7'd124, 7'd122, 7'd 74, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 15, 7'd  0, 7'd 31, 7'd 40, 7'd 23, 7'd 39, 7'd 16, 7'd  0, 
7'd 15, 7'd 31, 7'd 47, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 94, 7'd 46, 7'd 30, 
7'd 14, 7'd  1, 7'd102, 7'd 70, 7'd 54, 7'd 38, 7'd  6, 7'd  9, 
7'd124, 7'd118, 7'd 70, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 11, 7'd  4, 7'd 27, 7'd 42, 7'd 21, 7'd 37, 7'd 18, 7'd  2, 
7'd 13, 7'd 29, 7'd 45, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 63, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 94, 7'd 46, 7'd 30, 
7'd 14, 7'd  1, 7'd100, 7'd 68, 7'd 52, 7'd 36, 7'd  4, 7'd 11, 
7'd124, 7'd116, 7'd 68, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  5, 7'd  8, 7'd 23, 7'd 46, 7'd 17, 7'd 33, 7'd 20, 7'd  4, 
7'd 11, 7'd 27, 7'd 43, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 92, 7'd 44, 7'd 28, 
7'd 12, 7'd  3, 7'd 98, 7'd 66, 7'd 50, 7'd 34, 7'd  2, 7'd 13, 
7'd122, 7'd112, 7'd 64, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  1, 7'd 10, 7'd 21, 7'd 48, 7'd 15, 7'd 31, 7'd 22, 7'd  6, 
7'd  9, 7'd 25, 7'd 41, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 61, 7'd 72, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 71, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 7'd 42, 7'd 26, 
7'd 10, 7'd  5, 7'd 96, 7'd 64, 7'd 48, 7'd 32, 7'd  0, 7'd 15, 
7'd118, 7'd108, 7'd 60, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  4, 7'd 14, 7'd 17, 7'd 52, 7'd 11, 7'd 27, 7'd 26, 7'd 10, 
7'd  5, 7'd 21, 7'd 37, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 59, 7'd 74, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 69, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 7'd 42, 7'd 26, 
7'd 10, 7'd  5, 7'd 96, 7'd 64, 7'd 48, 7'd 32, 7'd  0, 7'd 15, 
7'd116, 7'd106, 7'd 58, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd  8, 7'd 18, 7'd 13, 7'd 56, 7'd  7, 7'd 23, 7'd 28, 7'd 12, 
7'd  3, 7'd 19, 7'd 35, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 74, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 69, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 88, 7'd 40, 7'd 24, 
7'd  8, 7'd  7, 7'd 94, 7'd 62, 7'd 46, 7'd 30, 7'd  1, 7'd 17, 
7'd114, 7'd102, 7'd 54, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 14, 7'd 22, 7'd  9, 7'd 58, 7'd  5, 7'd 21, 7'd 30, 7'd 14, 
7'd  1, 7'd 17, 7'd 33, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 
7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 57, 7'd 74, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 69, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 88, 7'd 40, 7'd 24, 
7'd  8, 7'd  7, 7'd 92, 7'd 60, 7'd 44, 7'd 28, 7'd  3, 7'd 19, 
7'd112, 7'd100, 7'd 52, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 18, 7'd 26, 7'd  5, 7'd 62, 7'd  1, 7'd 17, 7'd 32, 7'd 16, 
7'd  0, 7'd 15, 7'd 31, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 
7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 55, 7'd 76, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 67, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 86, 7'd 38, 7'd 22, 
7'd  6, 7'd  9, 7'd 90, 7'd 58, 7'd 42, 7'd 26, 7'd  5, 7'd 21, 
7'd108, 7'd 96, 7'd 48, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 24, 7'd 30, 7'd  1, 7'd 64, 7'd  0, 7'd 15, 7'd 36, 7'd 20, 
7'd  4, 7'd 11, 7'd 27, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 76, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 67, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 84, 7'd 36, 7'd 20, 
7'd  4, 7'd 11, 7'd 88, 7'd 56, 7'd 40, 7'd 24, 7'd  7, 7'd 23, 
7'd106, 7'd 94, 7'd 46, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 28, 7'd 34, 7'd  2, 7'd 68, 7'd  4, 7'd 11, 7'd 38, 7'd 22, 
7'd  6, 7'd  9, 7'd 25, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 
7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 53, 7'd 76, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 67, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 84, 7'd 36, 7'd 20, 
7'd  4, 7'd 11, 7'd 86, 7'd 54, 7'd 38, 7'd 22, 7'd  9, 7'd 25, 
7'd104, 7'd 90, 7'd 42, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 34, 7'd 38, 7'd  6, 7'd 70, 7'd  6, 7'd  9, 7'd 40, 7'd 24, 
7'd  8, 7'd  7, 7'd 23, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 65, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 48, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 82, 7'd 34, 7'd 18, 
7'd  2, 7'd 13, 7'd 84, 7'd 52, 7'd 36, 7'd 20, 7'd 11, 7'd 27, 
7'd102, 7'd 88, 7'd 40, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 38, 7'd 40, 7'd  8, 7'd 74, 7'd 10, 7'd  5, 7'd 42, 7'd 26, 
7'd 10, 7'd  5, 7'd 21, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 
7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 65, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 48, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 80, 7'd 32, 7'd 16, 
7'd  0, 7'd 15, 7'd 82, 7'd 50, 7'd 34, 7'd 18, 7'd 13, 7'd 29, 
7'd 98, 7'd 84, 7'd 36, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 44, 7'd 44, 7'd 12, 7'd 78, 7'd 14, 7'd  1, 7'd 46, 7'd 30, 
7'd 14, 7'd  1, 7'd 17, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 65, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 48, 
7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 80, 7'd 32, 7'd 16, 
7'd  0, 7'd 15, 7'd 80, 7'd 48, 7'd 32, 7'd 16, 7'd 15, 7'd 31, 
7'd 96, 7'd 80, 7'd 32, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 48, 7'd 48, 7'd 16, 7'd 80, 7'd 16, 7'd  0, 7'd 48, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 80, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 78, 7'd 30, 7'd 14, 
7'd  1, 7'd 17, 7'd 78, 7'd 46, 7'd 30, 7'd 14, 7'd 17, 7'd 33, 
7'd 94, 7'd 78, 7'd 30, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 54, 7'd 52, 7'd 20, 7'd 84, 7'd 20, 7'd  4, 7'd 50, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 80, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 78, 7'd 30, 7'd 14, 
7'd  1, 7'd 17, 7'd 76, 7'd 44, 7'd 28, 7'd 12, 7'd 19, 7'd 35, 
7'd 92, 7'd 74, 7'd 26, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 58, 7'd 56, 7'd 24, 7'd 86, 7'd 22, 7'd  6, 7'd 52, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 80, 
7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 76, 7'd 28, 7'd 12, 
7'd  3, 7'd 19, 7'd 74, 7'd 42, 7'd 26, 7'd 10, 7'd 21, 7'd 37, 
7'd 88, 7'd 72, 7'd 24, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 64, 7'd 60, 7'd 28, 7'd 90, 7'd 26, 7'd 10, 7'd 56, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 74, 7'd 26, 7'd 10, 
7'd  5, 7'd 21, 7'd 72, 7'd 40, 7'd 24, 7'd  8, 7'd 23, 7'd 39, 
7'd 86, 7'd 68, 7'd 20, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 68, 7'd 64, 7'd 32, 7'd 92, 7'd 28, 7'd 12, 7'd 58, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 74, 7'd 26, 7'd 10, 
7'd  5, 7'd 21, 7'd 70, 7'd 38, 7'd 22, 7'd  6, 7'd 25, 7'd 41, 
7'd 84, 7'd 66, 7'd 18, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 74, 7'd 68, 7'd 36, 7'd 96, 7'd 32, 7'd 16, 7'd 60, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 44, 
7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 72, 7'd 24, 7'd  8, 
7'd  7, 7'd 23, 7'd 68, 7'd 36, 7'd 20, 7'd  4, 7'd 27, 7'd 43, 
7'd 82, 7'd 62, 7'd 14, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 78, 7'd 70, 7'd 38, 7'd 98, 7'd 34, 7'd 18, 7'd 62, 7'd 46, 
7'd 30, 7'd 14, 7'd  1, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 82, 
7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 70, 7'd 22, 7'd  6, 
7'd  9, 7'd 25, 7'd 66, 7'd 34, 7'd 18, 7'd  2, 7'd 29, 7'd 45, 
7'd 78, 7'd 58, 7'd 10, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 84, 7'd 74, 7'd 42, 7'd102, 7'd 38, 7'd 22, 7'd 66, 7'd 50, 
7'd 34, 7'd 18, 7'd  2, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 84, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 70, 7'd 22, 7'd  6, 
7'd  9, 7'd 25, 7'd 66, 7'd 34, 7'd 18, 7'd  2, 7'd 29, 7'd 45, 
7'd 76, 7'd 56, 7'd  8, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 88, 7'd 78, 7'd 46, 7'd106, 7'd 42, 7'd 26, 7'd 68, 7'd 52, 
7'd 36, 7'd 20, 7'd  4, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 84, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 68, 7'd 20, 7'd  4, 
7'd 11, 7'd 27, 7'd 64, 7'd 32, 7'd 16, 7'd  0, 7'd 31, 7'd 47, 
7'd 74, 7'd 52, 7'd  4, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 94, 7'd 82, 7'd 50, 7'd108, 7'd 44, 7'd 28, 7'd 70, 7'd 54, 
7'd 38, 7'd 22, 7'd  6, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 84, 
7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 42, 
7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 37, 7'd 68, 7'd 20, 7'd  4, 
7'd 11, 7'd 27, 7'd 62, 7'd 30, 7'd 14, 7'd  1, 7'd 33, 7'd 49, 
7'd 72, 7'd 50, 7'd  2, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd 98, 7'd 86, 7'd 54, 7'd112, 7'd 48, 7'd 32, 7'd 72, 7'd 56, 
7'd 40, 7'd 24, 7'd  8, 7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 35, 7'd 86, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 66, 7'd 18, 7'd  2, 
7'd 13, 7'd 29, 7'd 60, 7'd 28, 7'd 12, 7'd  3, 7'd 35, 7'd 51, 
7'd 68, 7'd 46, 7'd  1, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd104, 7'd 90, 7'd 58, 7'd114, 7'd 50, 7'd 34, 7'd 76, 7'd 60, 
7'd 44, 7'd 28, 7'd 12, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 86, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 64, 7'd 16, 7'd  0, 
7'd 15, 7'd 31, 7'd 58, 7'd 26, 7'd 10, 7'd  5, 7'd 37, 7'd 53, 
7'd 66, 7'd 44, 7'd  3, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd108, 7'd 94, 7'd 62, 7'd118, 7'd 54, 7'd 38, 7'd 78, 7'd 62, 
7'd 46, 7'd 30, 7'd 14, 7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 33, 7'd 86, 
7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 40, 
7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 39, 7'd 64, 7'd 16, 7'd  0, 
7'd 15, 7'd 31, 7'd 56, 7'd 24, 7'd  8, 7'd  7, 7'd 39, 7'd 55, 
7'd 64, 7'd 40, 7'd  7, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd114, 7'd 98, 7'd 66, 7'd120, 7'd 56, 7'd 40, 7'd 80, 7'd 64, 
7'd 48, 7'd 32, 7'd 16, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 
7'd 64, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 88, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 38, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 62, 7'd 14, 7'd  1, 
7'd 17, 7'd 33, 7'd 54, 7'd 22, 7'd  6, 7'd  9, 7'd 41, 7'd 57, 
7'd 62, 7'd 38, 7'd  9, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd118, 7'd100, 7'd 68, 7'd124, 7'd 60, 7'd 44, 7'd 82, 7'd 66, 
7'd 50, 7'd 34, 7'd 18, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 
7'd 64, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 88, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 38, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 60, 7'd 12, 7'd  3, 
7'd 19, 7'd 35, 7'd 52, 7'd 20, 7'd  4, 7'd 11, 7'd 43, 7'd 59, 
7'd 58, 7'd 34, 7'd 13, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd104, 7'd 72, 7'd124, 7'd 64, 7'd 48, 7'd 86, 7'd 70, 
7'd 54, 7'd 38, 7'd 22, 7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 
7'd 66, 7'd 50, 7'd 34, 7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 88, 
7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 38, 
7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 41, 7'd 60, 7'd 12, 7'd  3, 
7'd 19, 7'd 35, 7'd 50, 7'd 18, 7'd  2, 7'd 13, 7'd 45, 7'd 61, 
7'd 56, 7'd 30, 7'd 17, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd108, 7'd 76, 7'd124, 7'd 66, 7'd 50, 7'd 88, 7'd 72, 
7'd 56, 7'd 40, 7'd 24, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 
7'd 68, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 58, 7'd 10, 7'd  5, 
7'd 21, 7'd 37, 7'd 48, 7'd 16, 7'd  0, 7'd 15, 7'd 47, 7'd 63, 
7'd 54, 7'd 28, 7'd 19, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd112, 7'd 80, 7'd124, 7'd 70, 7'd 54, 7'd 90, 7'd 74, 
7'd 58, 7'd 42, 7'd 26, 7'd 64, 7'd 48, 7'd 32, 7'd 16, 7'd  0, 
7'd 68, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 90, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 58, 7'd 10, 7'd  5, 
7'd 21, 7'd 37, 7'd 46, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 65, 
7'd 52, 7'd 24, 7'd 23, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd116, 7'd 84, 7'd124, 7'd 72, 7'd 56, 7'd 92, 7'd 76, 
7'd 60, 7'd 44, 7'd 28, 7'd 66, 7'd 50, 7'd 34, 7'd 18, 7'd  2, 
7'd 70, 7'd 54, 7'd 38, 7'd 22, 7'd  6, 7'd  9, 7'd 25, 7'd 90, 
7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 36, 
7'd 20, 7'd  4, 7'd 11, 7'd 27, 7'd 43, 7'd 56, 7'd  8, 7'd  7, 
7'd 23, 7'd 39, 7'd 44, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 67, 
7'd 48, 7'd 22, 7'd 25, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd120, 7'd 88, 7'd124, 7'd 76, 7'd 60, 7'd 96, 7'd 80, 
7'd 64, 7'd 48, 7'd 32, 7'd 68, 7'd 52, 7'd 36, 7'd 20, 7'd  4, 
7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 54, 7'd  6, 7'd  9, 
7'd 25, 7'd 41, 7'd 42, 7'd 10, 7'd  5, 7'd 21, 7'd 53, 7'd 69, 
7'd 46, 7'd 18, 7'd 29, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd 92, 7'd124, 7'd 78, 7'd 62, 7'd 98, 7'd 82, 
7'd 66, 7'd 50, 7'd 34, 7'd 70, 7'd 54, 7'd 38, 7'd 22, 7'd  6, 
7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 7'd  7, 7'd 23, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 54, 7'd  6, 7'd  9, 
7'd 25, 7'd 41, 7'd 40, 7'd  8, 7'd  7, 7'd 23, 7'd 55, 7'd 71, 
7'd 44, 7'd 16, 7'd 31, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd 96, 7'd124, 7'd 82, 7'd 66, 7'd100, 7'd 84, 
7'd 68, 7'd 52, 7'd 36, 7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 
7'd 74, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 34, 
7'd 18, 7'd  2, 7'd 13, 7'd 29, 7'd 45, 7'd 52, 7'd  4, 7'd 11, 
7'd 27, 7'd 43, 7'd 38, 7'd  6, 7'd  9, 7'd 25, 7'd 57, 7'd 73, 
7'd 42, 7'd 12, 7'd 35, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd 98, 7'd124, 7'd 84, 7'd 68, 7'd102, 7'd 86, 
7'd 70, 7'd 54, 7'd 38, 7'd 72, 7'd 56, 7'd 40, 7'd 24, 7'd  8, 
7'd 74, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 7'd  5, 7'd 21, 7'd 92, 
7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 51, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 50, 7'd  2, 7'd 13, 
7'd 29, 7'd 45, 7'd 36, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 75, 
7'd 38, 7'd  8, 7'd 39, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd102, 7'd124, 7'd 88, 7'd 72, 7'd106, 7'd 90, 
7'd 74, 7'd 58, 7'd 42, 7'd 74, 7'd 58, 7'd 42, 7'd 26, 7'd 10, 
7'd 76, 7'd 60, 7'd 44, 7'd 28, 7'd 12, 7'd  3, 7'd 19, 7'd 94, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 50, 7'd  2, 7'd 13, 
7'd 29, 7'd 45, 7'd 36, 7'd  4, 7'd 11, 7'd 27, 7'd 59, 7'd 75, 
7'd 36, 7'd  6, 7'd 41, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd106, 7'd124, 7'd 92, 7'd 76, 7'd108, 7'd 92, 
7'd 76, 7'd 60, 7'd 44, 7'd 76, 7'd 60, 7'd 44, 7'd 28, 7'd 12, 
7'd 78, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 94, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 48, 7'd  0, 7'd 15, 
7'd 31, 7'd 47, 7'd 34, 7'd  2, 7'd 13, 7'd 29, 7'd 61, 7'd 77, 
7'd 34, 7'd  2, 7'd 45, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
},
{
7'd124, 7'd124, 7'd110, 7'd124, 7'd 94, 7'd 78, 7'd110, 7'd 94, 
7'd 78, 7'd 62, 7'd 46, 7'd 78, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 
7'd 78, 7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 94, 
7'd 62, 7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd 78, 
7'd 46, 7'd 30, 7'd 14, 7'd  1, 7'd 17, 7'd 49, 7'd124, 7'd 32, 
7'd 16, 7'd  0, 7'd 15, 7'd 31, 7'd 47, 7'd 48, 7'd  0, 7'd 15, 
7'd 31, 7'd 47, 7'd 32, 7'd  0, 7'd 15, 7'd 31, 7'd 63, 7'd 79, 
7'd 32, 7'd  0, 7'd 47, 7'd  0, 7'd  0, 7'd  0, 7'd  0, 7'd  0
}
};

parameter  logic   [0:63][0:3][7:0]   AUC_LPS_TABLE= {
  { 8'd128, 8'd176, 8'd208, 8'd240},
  { 8'd128, 8'd167, 8'd197, 8'd227},
  { 8'd128, 8'd158, 8'd187, 8'd216},
  { 8'd123, 8'd150, 8'd178, 8'd205},
  { 8'd116, 8'd142, 8'd169, 8'd195},
  { 8'd111, 8'd135, 8'd160, 8'd185},
  { 8'd105, 8'd128, 8'd152, 8'd175},
  { 8'd100, 8'd122, 8'd144, 8'd166},
  {  8'd95, 8'd116, 8'd137, 8'd158},
  {  8'd90, 8'd110, 8'd130, 8'd150},
  {  8'd85, 8'd104, 8'd123, 8'd142},
  {  8'd81,  8'd99, 8'd117, 8'd135},
  {  8'd77,  8'd94, 8'd111, 8'd128},
  {  8'd73,  8'd89, 8'd105, 8'd122},
  {  8'd69,  8'd85, 8'd100, 8'd116},
  {  8'd66,  8'd80,  8'd95, 8'd110},
  {  8'd62,  8'd76,  8'd90, 8'd104},
  {  8'd59,  8'd72,  8'd86,  8'd99},
  {  8'd56,  8'd69,  8'd81,  8'd94},
  {  8'd53,  8'd65,  8'd77,  8'd89},
  {  8'd51,  8'd62,  8'd73,  8'd85},
  {  8'd48,  8'd59,  8'd69,  8'd80},
  {  8'd46,  8'd56,  8'd66,  8'd76},
  {  8'd43,  8'd53,  8'd63,  8'd72},
  {  8'd41,  8'd50,  8'd59,  8'd69},
  {  8'd39,  8'd48,  8'd56,  8'd65},
  {  8'd37,  8'd45,  8'd54,  8'd62},
  {  8'd35,  8'd43,  8'd51,  8'd59},
  {  8'd33,  8'd41,  8'd48,  8'd56},
  {  8'd32,  8'd39,  8'd46,  8'd53},
  {  8'd30,  8'd37,  8'd43,  8'd50},
  {  8'd29,  8'd35,  8'd41,  8'd48},
  {  8'd27,  8'd33,  8'd39,  8'd45},
  {  8'd26,  8'd31,  8'd37,  8'd43},
  {  8'd24,  8'd30,  8'd35,  8'd41},
  {  8'd23,  8'd28,  8'd33,  8'd39},
  {  8'd22,  8'd27,  8'd32,  8'd37},
  {  8'd21,  8'd26,  8'd30,  8'd35},
  {  8'd20,  8'd24,  8'd29,  8'd33},
  {  8'd19,  8'd23,  8'd27,  8'd31},
  {  8'd18,  8'd22,  8'd26,  8'd30},
  {  8'd17,  8'd21,  8'd25,  8'd28},
  {  8'd16,  8'd20,  8'd23,  8'd27},
  {  8'd15,  8'd19,  8'd22,  8'd25},
  {  8'd14,  8'd18,  8'd21,  8'd24},
  {  8'd14,  8'd17,  8'd20,  8'd23},
  {  8'd13,  8'd16,  8'd19,  8'd22},
  {  8'd12,  8'd15,  8'd18,  8'd21},
  {  8'd12,  8'd14,  8'd17,  8'd20},
  {  8'd11,  8'd14,  8'd16,  8'd19},
  {  8'd11,  8'd13,  8'd15,  8'd18},
  {  8'd10,  8'd12,  8'd15,  8'd17},
  {  8'd10,  8'd12,  8'd14,  8'd16},
  {  8'd 9,  8'd11,  8'd13,  8'd15},
  {  8'd 9,  8'd11,  8'd12,  8'd14},
  {  8'd 8,  8'd10,  8'd12,  8'd14},
  {  8'd 8,  8'd 9,  8'd11,  8'd13},
  {  8'd 7,  8'd 9,  8'd11,  8'd12},
  {  8'd 7,  8'd 9,  8'd10,  8'd12},
  {  8'd 7,  8'd 8,  8'd10,  8'd11},
  {  8'd 6,  8'd 8,  8'd 9,  8'd11},
  {  8'd 6,  8'd 7,  8'd 9,  8'd10},
  {  8'd 6,  8'd 7,  8'd 8,  8'd 9},
  {  8'd 2,  8'd 2,  8'd 2,  8'd 2}
};

parameter  logic   [0:63][0:3][2:0]   AUC_RENORM_TABLE= {
  {   3'h1,   3'h1,   3'h1,   3'h1},
  {   3'h1,   3'h1,   3'h1,   3'h1},
  {   3'h1,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h1,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h1,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h1},
  {   3'h2,   3'h2,   3'h2,   3'h2},
  {   3'h2,   3'h2,   3'h2,   3'h2},
  {   3'h2,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h2,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h2,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h2},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h3,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h3,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h3,   3'h3},
  {   3'h4,   3'h4,   3'h4,   3'h3},
  {   3'h4,   3'h4,   3'h4,   3'h3},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h4,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h4,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h4,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h4},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h5,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h5,   3'h5,   3'h5},
  {   3'h6,   3'h6,   3'h5,   3'h5},
  {   3'h6,   3'h6,   3'h5,   3'h5},
  {   3'h6,   3'h6,   3'h6,   3'h6}
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
  7'd2,   7'd3,   7'd4,   7'd5,   7'd6,   7'd7,   7'd8,   7'd9,   7'd10,  7'd11,  7'd12,  7'd13,  7'd14,  7'd15,  7'd16,  7'd17,
  7'd18,  7'd19,  7'd20,  7'd21,  7'd22,  7'd23,  7'd24,  7'd25,  7'd26,  7'd27,  7'd28,  7'd29,  7'd30,  7'd31,  7'd32,  7'd33,
  7'd34,  7'd35,  7'd36,  7'd37,  7'd38,  7'd39,  7'd40,  7'd41,  7'd42,  7'd43,  7'd44,  7'd45,  7'd46,  7'd47,  7'd48,  7'd49,
  7'd50,  7'd51,  7'd52,  7'd53,  7'd54,  7'd55,  7'd56,  7'd57,  7'd58,  7'd59,  7'd60,  7'd61,  7'd62,  7'd63,  7'd64,  7'd65,
  7'd66,  7'd67,  7'd68,  7'd69,  7'd70,  7'd71,  7'd72,  7'd73,  7'd74,  7'd75,  7'd76,  7'd77,  7'd78,  7'd79,  7'd80,  7'd81,
  7'd82,  7'd83,  7'd84,  7'd85,  7'd86,  7'd87,  7'd88,  7'd89,  7'd90,  7'd91,  7'd92,  7'd93,  7'd94,  7'd95,  7'd96,  7'd97,
  7'd98,  7'd99,  7'd100, 7'd101, 7'd102, 7'd103, 7'd104, 7'd105, 7'd106, 7'd107, 7'd108, 7'd109, 7'd110, 7'd111, 7'd112, 7'd113,
  7'd114, 7'd115, 7'd116, 7'd117, 7'd118, 7'd119, 7'd120, 7'd121, 7'd122, 7'd123, 7'd124, 7'd125, 7'd124, 7'd125, 7'd126, 7'd127
};

parameter  logic   [0:127][6:0]  AUC_NXT_STATE_LPS = {
  7'd1,   7'd0,   7'd0,   7'd1,   7'd2,   7'd3,   7'd4,   7'd5,   7'd4,   7'd5,   7'd8,   7'd9,   7'd8,   7'd9,   7'd10,  7'd11,
  7'd12,  7'd13,  7'd14,  7'd15,  7'd16,  7'd17,  7'd18,  7'd19,  7'd18,  7'd19,  7'd22,  7'd23,  7'd22,  7'd23,  7'd24,  7'd25,
  7'd26,  7'd27,  7'd26,  7'd27,  7'd30,  7'd31,  7'd30,  7'd31,  7'd32,  7'd33,  7'd32,  7'd33,  7'd36,  7'd37,  7'd36,  7'd37,
  7'd38,  7'd39,  7'd38,  7'd39,  7'd42,  7'd43,  7'd42,  7'd43,  7'd44,  7'd45,  7'd44,  7'd45,  7'd46,  7'd47,  7'd48,  7'd49,
  7'd48,  7'd49,  7'd50,  7'd51,  7'd52,  7'd53,  7'd52,  7'd53,  7'd54,  7'd55,  7'd54,  7'd55,  7'd56,  7'd57,  7'd58,  7'd59,
  7'd58,  7'd59,  7'd60,  7'd61,  7'd60,  7'd61,  7'd60,  7'd61,  7'd62,  7'd63,  7'd64,  7'd65,  7'd64,  7'd65,  7'd66,  7'd67,
  7'd66,  7'd67,  7'd66,  7'd67,  7'd68,  7'd69,  7'd68,  7'd69,  7'd70,  7'd71,  7'd70,  7'd71,  7'd70,  7'd71,  7'd72,  7'd73,
  7'd72,  7'd73,  7'd72,  7'd73,  7'd74,  7'd75,  7'd74,  7'd75,  7'd74,  7'd75,  7'd76,  7'd77,  7'd76,  7'd77,  7'd126, 7'd127
};
`endif

`ifndef IVERILOG
endpackage
`endif