// 
// Author : Qi Wang
// The sub-FSM to handle residuel part decoding
module qdec_res_fsm import qdec_cabac_package::*; (
    input clk,
    input rst_n,

    input  logic       res_start,
    input  logic [1:0] slice_type,
    input  logic       cabac_init_flag,
    input  logic       transform_skip_enabled_flag,
    input  logic       cu_transquant_bypass_flag,
    input  logic       sign_data_hiding_enabled_flag,
    input  logic [2:0] log2TrafoSize,
    input  logic [2:0] Log2MaxTransformSkipSize,
    input  logic       intraPredVertical,
    input  logic       intraPredHorizontal,

    output logic [9:0] ctx_res_addr,
    output logic       ctx_res_addr_vld,
    output logic       dec_run_res,
    input  logic       dec_rdy,
    output logic       EPMode_res,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       res_done_intr
);

logic       dec_done;
logic [7:0] counter_coded_bin;
logic [31:0]ruiBin_delay;
logic [7:0] ctx_res_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
logic [7:0] target_bin;
logic       transform_skip_flag;
logic [3:0] last_sig_coeff_x_prefix, last_sig_coeff_y_prefix; // max 9
logic [3:0] last_sig_coeff_x_suffix, last_sig_coeff_y_suffix; // max 7
logic [4:0] last_sig_coeff_x,        last_sig_coeff_y;
// pointer to the current SB, and the last SB with non-zero elements, max SB 64
// zigzag order inside TU
logic [5:0] currSB_scan, lastSB_scan;
logic [5:0] currSB_zigzag, lastSB_zigzag;
// 0 is diagonal, 1 is horizontal, 2 is vertical, 3 is traverse
// If intra mode is 6 to 14, use vertical, 22 to 30 use horizontal, otherwise 0
logic [1:0] ScanOrderIdx;
// pointer to the pix inside SB
logic [3:0] currPix_scan, lastPix_scan;
logic [3:0] currPix_zigzag, lastPix_zigzag;
// all signal need to be re-ordered based ont he scan order, store to zig-zag order in later modules
logic [63:0]coded_sub_block_flag;
logic [15:0]sig_coeff_flag[63:0];
logic [15:0]curr_sig_coeff_flag_array;
logic       currCSBF, curr_sig_coeff_flag;
logic       inferSbDcSigCoeffFlag;
logic [15:0]coeff_abs_level_gt1_flag[63:0];
logic [15:0]curr_coeff_abs_level_gt1_flag_array;
logic       curr_coeff_abs_level_gt1_flag;
logic [3:0] numGt1Flag;
// corrdinate buffers to store the last pos of gt0 and gt1, to reduce looping time
logic [4:0] firstSigScanPos, lastSigScanPos, lastGt1ScanPos;
logic       escapeDataPresent;
logic       signHidden;
logic       coeff_abs_level_gt2_flag;
logic [15:0]coeff_sign_flag[63:0];
logic [15:0]curr_coeff_sign_flag_array;
logic [3:0] numSigCoeff;
logic [1:0] baseLevel;
// condition to decode remaining coeff abs in different conditions
logic       baseLevelMatching;
// used to assign last pos to the curr ptr
logic       first_iter;
logic [2:0] uiGoRiceParam;
logic [7:0] coeff_abs_level_remaining;
logic [7:0] coeff_abs_level_remaining_dec;
logic [3:0] coeff_abs_level_remaining_prefix;
logic [7:0] coeff_abs_level_remaining_tmp; // limit the range under 128
logic       coeff_abs_level_remaining_first_zero;
logic [7:0] sumAbsLevel;

t_state_res state, nxt_state;

always_comb
    case(state)
    IDLE_RES:                  nxt_state = res_start===1'b1 ? JUDGE_TRAFO_SKIP : IDLE_RES;
    JUDGE_TRAFO_SKIP:          nxt_state = (transform_skip_enabled_flag && !cu_transquant_bypass_flag && (log2TrafoSize <= Log2MaxTransformSkipSize))===1'b1 ? 
                                           TRANSFORM_SKIP_FLAG : LAST_SIG_COEFF_X_PREFIX;
    TRANSFORM_SKIP_FLAG:       nxt_state = dec_done===1'b1 ? LAST_SIG_COEFF_X_PREFIX : TRANSFORM_SKIP_FLAG;
    LAST_SIG_COEFF_X_PREFIX:   nxt_state = dec_done===1'b1 ? LAST_SIG_COEFF_Y_PREFIX : LAST_SIG_COEFF_X_PREFIX;
    LAST_SIG_COEFF_Y_PREFIX:   nxt_state = dec_done===1'b1 ? ((last_sig_coeff_x_prefix > 3)===1'b1 ? LAST_SIG_COEFF_X_SUFFIX : 
                                                             ((last_sig_coeff_y_prefix > 3)===1'b1 ? LAST_SIG_COEFF_Y_SUFFIX : FIND_LAST_POS_0)) 
                                           : LAST_SIG_COEFF_Y_PREFIX;
    LAST_SIG_COEFF_X_SUFFIX:   nxt_state = dec_done===1'b1 ? ((last_sig_coeff_y_prefix > 3)===1'b1 ? LAST_SIG_COEFF_Y_SUFFIX : FIND_LAST_POS_0) : LAST_SIG_COEFF_X_SUFFIX;
    LAST_SIG_COEFF_Y_SUFFIX:   nxt_state = dec_done===1'b1 ? FIND_LAST_POS_0 : LAST_SIG_COEFF_Y_SUFFIX;
    FIND_LAST_POS_0:           nxt_state = FIND_LAST_POS_1; // need two clock cycles to calculate
    FIND_LAST_POS_1:           nxt_state = CALC_COR_RES;
    CALC_COR_RES:              nxt_state = JUDGE_CSBF;
    JUDGE_CSBF:                nxt_state = (currSB_scan < lastSB_scan && currSB_scan > 0)===1'b1 ? CODED_SUB_BLOCK_FLAG : JUDGE_SIG_COEFF_FLAG;
    CODED_SUB_BLOCK_FLAG:      nxt_state = dec_done===1'b1 ? JUDGE_SIG_COEFF_FLAG : CODED_SUB_BLOCK_FLAG;
    JUDGE_SIG_COEFF_FLAG:      nxt_state = (currCSBF && (currPix_scan > 0 || !inferSbDcSigCoeffFlag))===1'b1 ? SIG_COEFF_FLAG : NXT_SIG_COEFF_FLAG;
    SIG_COEFF_FLAG:            nxt_state = dec_done===1'b1 ? NXT_SIG_COEFF_FLAG : SIG_COEFF_FLAG;
    NXT_SIG_COEFF_FLAG:        nxt_state = currPix_scan===4'h0 ? JUDGE_COEFF_ABS_GT1_FLAG : JUDGE_SIG_COEFF_FLAG;
    JUDGE_COEFF_ABS_GT1_FLAG:  nxt_state = (curr_sig_coeff_flag && (numGt1Flag < 8))===1'b1 ? COEFF_ABS_LEVEL_GT1_FLAG : NXT_COEFF_ABS_GT1_FLAG;
    COEFF_ABS_LEVEL_GT1_FLAG:  nxt_state = dec_done===1'b1 ? NXT_COEFF_ABS_GT1_FLAG : COEFF_ABS_LEVEL_GT1_FLAG;
    NXT_COEFF_ABS_GT1_FLAG:    nxt_state = currPix_scan===4'h0 ? SIGN_HIDDEN : JUDGE_COEFF_ABS_GT1_FLAG;
    SIGN_HIDDEN:               nxt_state = JUDGE_COEFF_ABS_GT2_FLAG;
    JUDGE_COEFF_ABS_GT2_FLAG:  nxt_state = (lastGt1ScanPos != 5'h1F)===1'b1 ? COEFF_ABS_LEVEL_GT2_FLAG : JUDGE_COEFF_SIGN_FLAG;
    COEFF_ABS_LEVEL_GT2_FLAG:  nxt_state = dec_done===1'b1 ? JUDGE_COEFF_SIGN_FLAG : COEFF_ABS_LEVEL_GT2_FLAG;
    JUDGE_COEFF_SIGN_FLAG:     nxt_state = (sign_data_hiding_enabled_flag && signHidden)===1'b1 ? (currCSBF===1'b1 ? COEFF_SIGN_FLAG_FIRST : JUDGE_COEFF_ABS_REM) :
                                           (curr_sig_coeff_flag && (currPix_scan!=firstSigScanPos))===1'b1 ?
                                           COEFF_SIGN_FLAG : NXT_COEFF_SIGN_FLAG;
    COEFF_SIGN_FLAG_FIRST:     nxt_state = dec_done===1'b1 ? JUDGE_COEFF_ABS_REM : COEFF_SIGN_FLAG_FIRST;
    COEFF_SIGN_FLAG:           nxt_state = dec_done===1'b1 ? NXT_COEFF_SIGN_FLAG : COEFF_SIGN_FLAG;
    NXT_COEFF_SIGN_FLAG:       nxt_state = currPix_scan===4'h0 ? JUDGE_COEFF_ABS_REM : JUDGE_COEFF_SIGN_FLAG;
    JUDGE_COEFF_ABS_REM:       nxt_state = baseLevelMatching===1'b1 ? COEFF_ABS_LEVEL_REM : NXT_COEFF_ABS_REM;
    COEFF_ABS_LEVEL_REM:       nxt_state = dec_done===1'b1 ? NXT_COEFF_ABS_REM : COEFF_ABS_LEVEL_REM;
    NXT_COEFF_ABS_REM:         nxt_state = currPix_scan===4'h0 ? ITERATION_RES : JUDGE_COEFF_ABS_REM;
    ITERATION_RES:             nxt_state = currSB_scan===4'h0 ? ENDING_RES : CALC_COR_RES;
    ENDING_RES:                nxt_state = IDLE_RES;
    default:                   nxt_state = IDLE_RES;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_RES;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) res_done_intr <= (state == ENDING_RES) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_RES || dec_done) ? 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[30:0], ruiBin} : ruiBin_delay; // store the decoded bins

always_ff @(posedge clk) transform_skip_flag <= (state == TRANSFORM_SKIP_FLAG && dec_done) ? ruiBin_delay[0] : transform_skip_flag;
always_ff @(posedge clk)
    if(state == IDLE_RES) last_sig_coeff_x_prefix <= 0;
    else if(state == LAST_SIG_COEFF_X_PREFIX && ruiBin_vld & ruiBin) last_sig_coeff_x_prefix <= last_sig_coeff_x_prefix + 1;
always_ff @(posedge clk)
    if(state == IDLE_RES) last_sig_coeff_y_prefix <= 0;
    else if(state == LAST_SIG_COEFF_Y_PREFIX && ruiBin_vld & ruiBin) last_sig_coeff_y_prefix <= last_sig_coeff_y_prefix + 1;
always_ff @(posedge clk)
    if(state == LAST_SIG_COEFF_X_SUFFIX && dec_done)
        case(target_bin)
        8'd1: last_sig_coeff_x_suffix <= ruiBin_delay[0];
        8'd2: last_sig_coeff_x_suffix <= ruiBin_delay[1:0];
        8'd3: last_sig_coeff_x_suffix <= ruiBin_delay[2:0];
        default: last_sig_coeff_x_suffix <= ruiBin_delay[0];
        endcase
always_ff @(posedge clk)
    if(state == LAST_SIG_COEFF_Y_SUFFIX && dec_done)
        case(target_bin)
        8'd1: last_sig_coeff_y_suffix <= ruiBin_delay[0];
        8'd2: last_sig_coeff_y_suffix <= ruiBin_delay[1:0];
        8'd3: last_sig_coeff_y_suffix <= ruiBin_delay[2:0];
        default: last_sig_coeff_y_suffix <= ruiBin_delay[0];
        endcase
always_ff @(posedge clk) ScanOrderIdx <= intraPredVertical ? 2 : (intraPredHorizontal ? 1 : 0);
// coeff_x>>2 is the x for SB, coeff_y>>2 is the y for SB
assign last_sig_coeff_x = {1'b0, last_sig_coeff_x_prefix} + {1'b0, last_sig_coeff_x_suffix};
assign last_sig_coeff_y = {1'b0, last_sig_coeff_y_prefix} + {1'b0, last_sig_coeff_y_suffix};
always_ff @(posedge clk)
    if(state == FIND_LAST_POS_0) begin
        lastSB_zigzag <= {last_sig_coeff_y[4], last_sig_coeff_x[4], last_sig_coeff_y[3], last_sig_coeff_x[3], last_sig_coeff_y[2], last_sig_coeff_x[2]};
        lastPix_zigzag <= {last_sig_coeff_y[1], last_sig_coeff_x[1], last_sig_coeff_y[0], last_sig_coeff_x[0]};
    end
always_ff @(posedge clk)
    if(state == FIND_LAST_POS_1) begin
        case({log2TrafoSize, ScanOrderIdx})
        // TU size 32x32
        5'b101_00:    begin lastSB_scan<=REORDER_SCANIDX0_SIZE8X8_ZIGZAG_TO_SCAN[lastSB_zigzag]; lastPix_scan<=REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b101_01:    begin lastSB_scan<=REORDER_SCANIDX1_SIZE8X8_ZIGZAG_TO_SCAN[lastSB_zigzag]; lastPix_scan<=REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b101_10:    begin lastSB_scan<=REORDER_SCANIDX2_SIZE8X8_ZIGZAG_TO_SCAN[lastSB_zigzag]; lastPix_scan<=REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        // TU size 16x16
        5'b100_00:    begin lastSB_scan<={2'h0, REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN[lastSB_zigzag[3:0]]}; lastPix_scan<=REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b100_01:    begin lastSB_scan<={2'h0, REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN[lastSB_zigzag[3:0]]}; lastPix_scan<=REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b100_10:    begin lastSB_scan<={2'h0, REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN[lastSB_zigzag[3:0]]}; lastPix_scan<=REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        // TU size 8x8
        5'b011_00:    begin lastSB_scan<={4'h0, REORDER_SCANIDX0_SIZE2X2_ZIGZAG_TO_SCAN[lastSB_zigzag[1:0]]}; lastPix_scan<=REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b011_01:    begin lastSB_scan<={4'h0, REORDER_SCANIDX1_SIZE2X2_ZIGZAG_TO_SCAN[lastSB_zigzag[1:0]]}; lastPix_scan<=REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b011_10:    begin lastSB_scan<={4'h0, REORDER_SCANIDX2_SIZE2X2_ZIGZAG_TO_SCAN[lastSB_zigzag[1:0]]}; lastPix_scan<=REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        // TU size 4x4
        5'b010_00:    begin lastSB_scan<=6'h0; lastPix_scan<=REORDER_SCANIDX0_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b010_01:    begin lastSB_scan<=6'h0; lastPix_scan<=REORDER_SCANIDX1_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        5'b010_10:    begin lastSB_scan<=6'h0; lastPix_scan<=REORDER_SCANIDX2_SIZE4X4_ZIGZAG_TO_SCAN[lastPix_zigzag]; end
        default:      begin lastSB_scan<=6'h0; lastPix_scan<=4'h0; end
        endcase
    end
always_ff @(posedge clk) first_iter <= state == IDLE_RES ? 1 : (state == ITERATION_RES ? 0 : first_iter);
always_ff @(posedge clk)
    if(state == IDLE_RES) currSB_scan <= 0;
    else if(state == CALC_COR_RES) currSB_scan <= first_iter ? lastSB_scan : currSB_scan - 1;
always_ff @(posedge clk)
    if(state == IDLE_RES) currPix_scan <= 4'hF;
    else if(state == CALC_COR_RES) currPix_scan <= first_iter ? lastPix_scan : 4'hF;
    else if(state == NXT_SIG_COEFF_FLAG || state == NXT_COEFF_ABS_GT1_FLAG || state == NXT_COEFF_SIGN_FLAG || state == NXT_COEFF_ABS_REM) 
        currPix_scan <= (currPix_scan == 0) ? currPix_scan - 1 : lastSigScanPos[3:0];
always_ff @(posedge clk)
    case({log2TrafoSize, ScanOrderIdx})
    // TU size 32x32
    5'b101_00:    begin currSB_zigzag<=REORDER_SCANIDX0_SIZE8X8_SCAN_TO_ZIGZAG[currSB_scan]; currPix_zigzag<=REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b101_01:    begin currSB_zigzag<=REORDER_SCANIDX1_SIZE8X8_SCAN_TO_ZIGZAG[currSB_scan]; currPix_zigzag<=REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b101_10:    begin currSB_zigzag<=REORDER_SCANIDX2_SIZE8X8_SCAN_TO_ZIGZAG[currSB_scan]; currPix_zigzag<=REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    // TU size 16x16
    5'b100_00:    begin currSB_zigzag<={2'h0, REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG[currSB_scan[3:0]]}; currPix_zigzag<=REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b100_01:    begin currSB_zigzag<={2'h0, REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG[currSB_scan[3:0]]}; currPix_zigzag<=REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b100_10:    begin currSB_zigzag<={2'h0, REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG[currSB_scan[3:0]]}; currPix_zigzag<=REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    // TU size 8x8
    5'b011_00:    begin currSB_zigzag<={4'h0, REORDER_SCANIDX0_SIZE2X2_SCAN_TO_ZIGZAG[currSB_scan[1:0]]}; currPix_zigzag<=REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b011_01:    begin currSB_zigzag<={4'h0, REORDER_SCANIDX1_SIZE2X2_SCAN_TO_ZIGZAG[currSB_scan[1:0]]}; currPix_zigzag<=REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b011_10:    begin currSB_zigzag<={4'h0, REORDER_SCANIDX2_SIZE2X2_SCAN_TO_ZIGZAG[currSB_scan[1:0]]}; currPix_zigzag<=REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    // TU size 4x4
    5'b010_00:    begin currSB_zigzag<=6'h0; currPix_zigzag<=REORDER_SCANIDX0_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b010_01:    begin currSB_zigzag<=6'h0; currPix_zigzag<=REORDER_SCANIDX1_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    5'b010_10:    begin currSB_zigzag<=6'h0; currPix_zigzag<=REORDER_SCANIDX2_SIZE4X4_SCAN_TO_ZIGZAG[currPix_scan]; end
    default:      begin currSB_zigzag<=6'h0; currPix_zigzag<=4'h0; end
    endcase
// CSBF related
always_ff @(posedge clk)
    if(state == IDLE_RES) coded_sub_block_flag <= 64'h1;
    else if(state == FIND_LAST_POS_1) coded_sub_block_flag[lastSB_zigzag] <= 1;
    else if(state == CODED_SUB_BLOCK_FLAG && dec_done) coded_sub_block_flag[currSB_zigzag] <= ruiBin_delay[0];
always_ff @(posedge clk) currCSBF <= coded_sub_block_flag[currSB_zigzag];
always_ff @(posedge clk) 
    if(state == JUDGE_CSBF) inferSbDcSigCoeffFlag <= (currSB_scan < lastSB_scan && currSB_scan > 0) ? 1 : 0;
    else if(state == SIG_COEFF_FLAG && dec_done && ruiBin_delay[0]) inferSbDcSigCoeffFlag <= 0;
always_ff @(posedge clk)
    if(state == IDLE_RES || state == CALC_COR_RES) curr_sig_coeff_flag_array <= 0;
    else if(state == SIG_COEFF_FLAG && dec_done) curr_sig_coeff_flag_array[currPix_zigzag] <= ruiBin_delay[0];
    else if(state == NXT_SIG_COEFF_FLAG && currPix_scan == 0 && currCSBF && inferSbDcSigCoeffFlag) curr_sig_coeff_flag_array[0] <= 1;
always_ff @(posedge clk)
    if(state == ITERATION_RES) sig_coeff_flag[currSB_zigzag] <= curr_sig_coeff_flag_array;
assign curr_sig_coeff_flag = curr_sig_coeff_flag_array[currPix_zigzag];
// GT0 related
always_ff @(posedge clk)
    if(state == CALC_COR_RES) lastSigScanPos <= 5'h1f;
    else if(state == SIG_COEFF_FLAG && dec_done && ruiBin_delay[0]) 
        lastSigScanPos <= (lastSigScanPos == 5'h1f) ? currPix_scan : lastSigScanPos;
    else if(state == NXT_SIG_COEFF_FLAG && currPix_scan == 0 && currCSBF && inferSbDcSigCoeffFlag)
        lastSigScanPos <= (lastSigScanPos == 5'h1f) ? 1 : lastSigScanPos;
always_ff @(posedge clk)
    if(state == CALC_COR_RES) firstSigScanPos <= 5'h10;
    else if(state == SIG_COEFF_FLAG && dec_done && ruiBin_delay[0]) 
        firstSigScanPos <= currPix_scan;
    else if(state == NXT_SIG_COEFF_FLAG && currPix_scan == 0 && currCSBF && inferSbDcSigCoeffFlag)
        firstSigScanPos <= 1;
// GT1 related
always_ff @(posedge clk)
    if(state == CALC_COR_RES) curr_coeff_abs_level_gt1_flag_array <= 0;
    else if(state == COEFF_ABS_LEVEL_GT1_FLAG && dec_done) curr_coeff_abs_level_gt1_flag_array[currPix_zigzag] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == ITERATION_RES) coeff_abs_level_gt1_flag[currSB_zigzag] <= curr_coeff_abs_level_gt1_flag_array;
always_ff @(posedge clk)
    if(state == CALC_COR_RES) numGt1Flag <= 0;
    else if(state == COEFF_ABS_LEVEL_GT1_FLAG && dec_done & ruiBin_delay[0]) numGt1Flag <= numGt1Flag + 1;
always_ff @(posedge clk)
    if(state == CALC_COR_RES) lastGt1ScanPos <= 5'h1f;
    else if(state == COEFF_ABS_LEVEL_GT1_FLAG && dec_done & ruiBin_delay[0]) lastGt1ScanPos <= (lastGt1ScanPos == 5'h1f) ? currPix_scan : lastGt1ScanPos;
assign curr_coeff_abs_level_gt1_flag = curr_coeff_abs_level_gt1_flag_array[currPix_zigzag];
// SignHidden
always_ff @(posedge clk)
    signHidden <= cu_transquant_bypass_flag ? 0 : (((lastSigScanPos - firstSigScanPos) > 3) ? 1 : 0);
// GT2 related
always_ff @(posedge clk)
    if(state == JUDGE_COEFF_ABS_GT2_FLAG) coeff_abs_level_gt2_flag <= 0;
    else if(state == COEFF_ABS_LEVEL_GT2_FLAG && dec_done) coeff_abs_level_gt2_flag <= ruiBin_delay[0];
// Sign related
always_ff @(posedge clk)
    if(state == CALC_COR_RES) curr_coeff_sign_flag_array <= 0;
    else if(state == COEFF_SIGN_FLAG && dec_done) curr_coeff_sign_flag_array[currPix_zigzag] <= ruiBin_delay[0];
    else if(state == COEFF_SIGN_FLAG_FIRST && dec_done) curr_coeff_sign_flag_array[firstSigScanPos] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == ITERATION_RES) coeff_sign_flag[currSB_zigzag] <= curr_coeff_sign_flag_array;
// Remaining related
always_ff @(posedge clk)
    if(state == CALC_COR_RES) numSigCoeff <= 0;
    else if(state == JUDGE_COEFF_ABS_REM && curr_sig_coeff_flag) numSigCoeff <= numSigCoeff + 1;
always_ff @(posedge clk) 
    baseLevel <= (curr_sig_coeff_flag) ? (curr_coeff_abs_level_gt1_flag ? ((coeff_abs_level_gt2_flag && (currPix_scan == lastGt1ScanPos)) ? 3 : 2) 
                                          : 1) 
                 : 0;
always_ff @(posedge clk)
    baseLevelMatching <= (numSigCoeff < 8) ? ((currPix_scan == lastGt1ScanPos) ? (baseLevel == 3) : (baseLevel == 2))
                         : (baseLevel == 1);
always_ff @(posedge clk)
    if(state == CALC_COR_RES) uiGoRiceParam <= 0;
    else if(state == COEFF_ABS_LEVEL_REM && dec_done)
        case(uiGoRiceParam)
        3'd0: uiGoRiceParam <= (coeff_abs_level_remaining >  3) ? 3'd1 : 3'd0;
        3'd1: uiGoRiceParam <= (coeff_abs_level_remaining >  6) ? 3'd2 : 3'd1;
        3'd2: uiGoRiceParam <= (coeff_abs_level_remaining > 12) ? 3'd3 : 3'd2;
        3'd3: uiGoRiceParam <= (coeff_abs_level_remaining > 24) ? 3'd4 : 3'd3;
        3'd4: uiGoRiceParam <= (coeff_abs_level_remaining > 48) ? 3'd4 : 3'd4;
        default: uiGoRiceParam <= 0;
        endcase
always_ff @(posedge clk)
    if(state == JUDGE_COEFF_ABS_REM) coeff_abs_level_remaining_first_zero <= 0;
    else if(state == COEFF_ABS_LEVEL_REM && ruiBin_vld && !ruiBin) coeff_abs_level_remaining_first_zero <= 1;
always_ff @(posedge clk)
    if(state == COEFF_ABS_LEVEL_REM && ruiBin_vld && ruiBin & !coeff_abs_level_remaining_first_zero) 
        coeff_abs_level_remaining_prefix <= coeff_abs_level_remaining_prefix + 1;
always_ff @(posedge clk)
    if(state == COEFF_ABS_LEVEL_REM & dec_done)
        case({coeff_abs_level_remaining_prefix, uiGoRiceParam})
        // prefix < 3
        7'b0000_000: coeff_abs_level_remaining_dec <= 8'd0 ;
        7'b0001_000: coeff_abs_level_remaining_dec <= 8'd1 ;
        7'b0010_000: coeff_abs_level_remaining_dec <= 8'd2 ;
        7'b0000_001: coeff_abs_level_remaining_dec <= 8'd0 + ruiBin_delay[0];
        7'b0001_001: coeff_abs_level_remaining_dec <= 8'd2 + ruiBin_delay[0];
        7'b0010_001: coeff_abs_level_remaining_dec <= 8'd4 + ruiBin_delay[0];
        7'b0000_010: coeff_abs_level_remaining_dec <= 8'd0 + ruiBin_delay[1:0];
        7'b0001_010: coeff_abs_level_remaining_dec <= 8'd4 + ruiBin_delay[1:0];
        7'b0010_010: coeff_abs_level_remaining_dec <= 8'd8 + ruiBin_delay[1:0];
        7'b0000_011: coeff_abs_level_remaining_dec <= 8'd0 + ruiBin_delay[2:0];
        7'b0001_011: coeff_abs_level_remaining_dec <= 8'd8 + ruiBin_delay[2:0];
        7'b0010_011: coeff_abs_level_remaining_dec <= 8'd16+ ruiBin_delay[2:0];
        7'b0000_100: coeff_abs_level_remaining_dec <= 8'd0 + ruiBin_delay[3:0];
        7'b0001_100: coeff_abs_level_remaining_dec <= 8'd16+ ruiBin_delay[3:0];
        7'b0010_100: coeff_abs_level_remaining_dec <= 8'd32+ ruiBin_delay[3:0];
        // prefix >= 3
        7'b0011_000: coeff_abs_level_remaining_dec <= 8'd3  ;
        7'b0100_000: coeff_abs_level_remaining_dec <= 8'd4  + ruiBin_delay[0];
        7'b0101_000: coeff_abs_level_remaining_dec <= 8'd6  + ruiBin_delay[1:0];
        7'b0110_000: coeff_abs_level_remaining_dec <= 8'd10 + ruiBin_delay[2:0];
        7'b0111_000: coeff_abs_level_remaining_dec <= 8'd18 + ruiBin_delay[3:0];
        7'b1000_000: coeff_abs_level_remaining_dec <= 8'd34 + ruiBin_delay[4:0];
        7'b1001_000: coeff_abs_level_remaining_dec <= 8'd66 + ruiBin_delay[5:0];

        7'b0011_001: coeff_abs_level_remaining_dec <= 8'd6  + ruiBin_delay[0];
        7'b0100_001: coeff_abs_level_remaining_dec <= 8'd8  + ruiBin_delay[1:0];
        7'b0101_001: coeff_abs_level_remaining_dec <= 8'd12 + ruiBin_delay[2:0];
        7'b0110_001: coeff_abs_level_remaining_dec <= 8'd20 + ruiBin_delay[3:0];
        7'b0111_001: coeff_abs_level_remaining_dec <= 8'd36 + ruiBin_delay[4:0];
        7'b1000_001: coeff_abs_level_remaining_dec <= 8'd68 + ruiBin_delay[5:0];

        7'b0011_010: coeff_abs_level_remaining_dec <= 8'd12 + ruiBin_delay[1:0];
        7'b0100_010: coeff_abs_level_remaining_dec <= 8'd16 + ruiBin_delay[2:0];
        7'b0101_010: coeff_abs_level_remaining_dec <= 8'd24 + ruiBin_delay[3:0];
        7'b0110_010: coeff_abs_level_remaining_dec <= 8'd40 + ruiBin_delay[4:0];
        7'b0111_010: coeff_abs_level_remaining_dec <= 8'd72 + ruiBin_delay[5:0];

        7'b0011_011: coeff_abs_level_remaining_dec <= 8'd24 + ruiBin_delay[2:0];
        7'b0100_011: coeff_abs_level_remaining_dec <= 8'd32 + ruiBin_delay[3:0];
        7'b0101_011: coeff_abs_level_remaining_dec <= 8'd48 + ruiBin_delay[4:0];
        7'b0110_011: coeff_abs_level_remaining_dec <= 8'd80 + ruiBin_delay[5:0];

        7'b0011_100: coeff_abs_level_remaining_dec <= 8'd48 + ruiBin_delay[3:0];
        7'b0100_100: coeff_abs_level_remaining_dec <= 8'd64 + ruiBin_delay[4:0];
        7'b0101_100: coeff_abs_level_remaining_dec <= 8'd96 + ruiBin_delay[5:0];

        default: coeff_abs_level_remaining_dec <= 0;
        endcase
assign coeff_abs_level_remaining_tmp = coeff_abs_level_remaining_dec + {6'h0, baseLevel};
always_ff @(posedge clk) // consider the sign to get final result
    if(state == NXT_COEFF_ABS_REM) coeff_abs_level_remaining <= curr_coeff_sign_flag_array[currPix_zigzag] ? (8'd0-coeff_abs_level_remaining_tmp) : coeff_abs_level_remaining_tmp;
always_ff @(posedge clk)
    if(state == CALC_COR_RES) sumAbsLevel <= 0;
    else if(state == NXT_COEFF_ABS_REM) sumAbsLevel <= sumAbsLevel + coeff_abs_level_remaining_tmp;

// const UInt g_uiGroupIdx[ MAX_TU_SIZE ]   = {0,1,2,3,4,4,5,5,6,6,6,6,7,7,7,7,8,8,8,8,8,8,8,8,9,9,9,9,9,9,9,9};
always_ff @(posedge clk)
    if(state == LAST_SIG_COEFF_X_PREFIX || state == LAST_SIG_COEFF_Y_PREFIX)
        case(log2TrafoSize)
        3'h5: target_bin <= 9;
        3'h4: target_bin <= 7;
        3'h3: target_bin <= 5;
        3'h2: target_bin <= 3;
        default: target_bin <= 1;
        endcase
    else if(state == LAST_SIG_COEFF_X_SUFFIX)
    // UInt uiCount = ( uiPosLastX - 2 ) >> 1;
        case(last_sig_coeff_x_prefix)
        4'h4: target_bin <= 1;
        4'h5: target_bin <= 1;
        4'h6: target_bin <= 2;
        4'h7: target_bin <= 2;
        4'h8: target_bin <= 3;
        4'h9: target_bin <= 3;
        endcase
    else if(state == LAST_SIG_COEFF_Y_SUFFIX)
    // UInt uiCount = ( uiPosLastX - 2 ) >> 1;
        case(last_sig_coeff_y_prefix)
        4'h4: target_bin <= 1;
        4'h5: target_bin <= 1;
        4'h6: target_bin <= 2;
        4'h7: target_bin <= 2;
        4'h8: target_bin <= 3;
        4'h9: target_bin <= 3;
        endcase
    else if(state == COEFF_ABS_LEVEL_REM)
        case({coeff_abs_level_remaining_prefix, uiGoRiceParam})
        // prefix < 3
        7'b0000_000: target_bin <= coeff_abs_level_remaining_first_zero ? 1 : 15;
        7'b0001_000: target_bin <= coeff_abs_level_remaining_first_zero ? 2 : 15;
        7'b0010_000: target_bin <= coeff_abs_level_remaining_first_zero ? 3 : 15;
        7'b0000_001: target_bin <= coeff_abs_level_remaining_first_zero ? 2 : 15;
        7'b0001_001: target_bin <= coeff_abs_level_remaining_first_zero ? 3 : 15;
        7'b0010_001: target_bin <= coeff_abs_level_remaining_first_zero ? 4 : 15;
        7'b0000_010: target_bin <= coeff_abs_level_remaining_first_zero ? 3 : 15;
        7'b0001_010: target_bin <= coeff_abs_level_remaining_first_zero ? 4 : 15;
        7'b0010_010: target_bin <= coeff_abs_level_remaining_first_zero ? 5 : 15;
        7'b0000_011: target_bin <= coeff_abs_level_remaining_first_zero ? 4 : 15;
        7'b0001_011: target_bin <= coeff_abs_level_remaining_first_zero ? 5 : 15;
        7'b0010_011: target_bin <= coeff_abs_level_remaining_first_zero ? 6 : 15;
        7'b0000_100: target_bin <= coeff_abs_level_remaining_first_zero ? 5 : 15;
        7'b0001_100: target_bin <= coeff_abs_level_remaining_first_zero ? 6 : 15;
        7'b0010_100: target_bin <= coeff_abs_level_remaining_first_zero ? 7 : 15;
        // prefix >= 3
        7'b0011_000: target_bin <= coeff_abs_level_remaining_first_zero ? 4 : 15;
        7'b0100_000: target_bin <= coeff_abs_level_remaining_first_zero ? 6 : 15;
        7'b0101_000: target_bin <= coeff_abs_level_remaining_first_zero ? 8 : 15;
        7'b0110_000: target_bin <= coeff_abs_level_remaining_first_zero ? 10: 15;
        7'b0111_000: target_bin <= coeff_abs_level_remaining_first_zero ? 12: 15;
        7'b1000_000: target_bin <= coeff_abs_level_remaining_first_zero ? 14: 15;
        7'b1001_000: target_bin <= coeff_abs_level_remaining_first_zero ? 16: 15;
        7'b0011_001: target_bin <= coeff_abs_level_remaining_first_zero ? 5 : 15;
        7'b0100_001: target_bin <= coeff_abs_level_remaining_first_zero ? 7 : 15;
        7'b0101_001: target_bin <= coeff_abs_level_remaining_first_zero ? 9 : 15;
        7'b0110_001: target_bin <= coeff_abs_level_remaining_first_zero ? 11: 15;
        7'b0111_001: target_bin <= coeff_abs_level_remaining_first_zero ? 13: 15;
        7'b1000_001: target_bin <= coeff_abs_level_remaining_first_zero ? 15: 15;
        7'b0011_010: target_bin <= coeff_abs_level_remaining_first_zero ? 6 : 15;
        7'b0100_010: target_bin <= coeff_abs_level_remaining_first_zero ? 8 : 15;
        7'b0101_010: target_bin <= coeff_abs_level_remaining_first_zero ? 10: 15;
        7'b0110_010: target_bin <= coeff_abs_level_remaining_first_zero ? 12: 15;
        7'b0111_010: target_bin <= coeff_abs_level_remaining_first_zero ? 14: 15;
        7'b0011_011: target_bin <= coeff_abs_level_remaining_first_zero ? 7 : 15;
        7'b0100_011: target_bin <= coeff_abs_level_remaining_first_zero ? 9 : 15;
        7'b0101_011: target_bin <= coeff_abs_level_remaining_first_zero ? 11: 15;
        7'b0110_011: target_bin <= coeff_abs_level_remaining_first_zero ? 13: 15;
        7'b0011_100: target_bin <= coeff_abs_level_remaining_first_zero ? 8 : 15;
        7'b0100_100: target_bin <= coeff_abs_level_remaining_first_zero ? 10: 15;
        7'b0101_100: target_bin <= coeff_abs_level_remaining_first_zero ? 12: 15;
        default:     target_bin <= coeff_abs_level_remaining_first_zero ? 1 : 15;
        endcase
    else target_bin <= 1;

always_ff @(posedge clk)
    case(state)
    IDLE_RES:                  dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    TRANSFORM_SKIP_FLAG:       dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    LAST_SIG_COEFF_X_PREFIX:   dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    LAST_SIG_COEFF_Y_PREFIX:   dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    LAST_SIG_COEFF_X_SUFFIX:   dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    LAST_SIG_COEFF_Y_SUFFIX:   dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    CODED_SUB_BLOCK_FLAG:      dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    SIG_COEFF_FLAG:            dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    COEFF_ABS_LEVEL_GT1_FLAG:  dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    COEFF_ABS_LEVEL_GT2_FLAG:  dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    COEFF_SIGN_FLAG_FIRST:     dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    COEFF_SIGN_FLAG:           dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    COEFF_ABS_LEVEL_REM:       dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    default:                   dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    endcase

// Other output signal control
logic [2:0] currSB_zigzag_x, currSB_zigzag_y;
logic [3:0] currSB_zigzag_xplusy;
logic [2:0] currSB_zigzag_xplus1, currSB_zigzag_yplus1;
logic [5:0] currSB_xplus1_zigzag, currSB_yplus1_zigzag;
logic       CSBF_xplus1_zigzag, CSBF_yplus1_zigzag;
logic [1:0] currPix_zigzag_x, currPix_zigzag_y;
logic [2:0] currPix_zigzag_xplusy;
logic [7:0] sigCtx_4x4, sigCtx_4x4_plus27;
logic [7:0] sigCtx_l0, sigCtx_l1;
logic [1:0] ctxSet;
logic [1:0] lastGt1Ctx;
logic       lastGt1Flag;
logic [7:0] ctxInc_gt1, ctxInc_gt2;
assign currSB_zigzag_y = {currSB_zigzag[5], currSB_zigzag[3], currSB_zigzag[1]};
assign currSB_zigzag_x = {currSB_zigzag[4], currSB_zigzag[2], currSB_zigzag[0]};
assign currPix_zigzag_y = {currPix_zigzag[3], currPix_zigzag[1]};
assign currPix_zigzag_x = {currPix_zigzag[2], currPix_zigzag[0]};
always_ff @(posedge clk) currSB_zigzag_xplus1 <= currSB_zigzag_x + 1;
always_ff @(posedge clk) currSB_zigzag_yplus1 <= currSB_zigzag_y + 1;
always_ff @(posedge clk) currSB_zigzag_xplusy <= currSB_zigzag_x + currSB_zigzag_y;
always_ff @(posedge clk) currSB_xplus1_zigzag <= {currSB_zigzag_y[2], currSB_zigzag_xplus1[2], currSB_zigzag_y[1], currSB_zigzag_xplus1[1], currSB_zigzag_y[0], currSB_zigzag_xplus1[0]};
always_ff @(posedge clk) currSB_yplus1_zigzag <= {currSB_zigzag_yplus1[2], currSB_zigzag_x[2], currSB_zigzag_yplus1[1], currSB_zigzag_x[1], currSB_zigzag_yplus1[0], currSB_zigzag_x[0]};
always_ff @(posedge clk) currPix_zigzag_xplusy <= {1'b0, currPix_zigzag_x} + {1'b0, currPix_zigzag_y};
always_ff @(posedge clk) CSBF_xplus1_zigzag <= coded_sub_block_flag[currSB_xplus1_zigzag];
always_ff @(posedge clk) CSBF_yplus1_zigzag <= coded_sub_block_flag[currSB_yplus1_zigzag];
always_ff @(posedge clk) sigCtx_4x4 <= {4'h0, SIG_COEFF_FLAG_CTXIDX_MAP[{currPix_zigzag_y, currPix_zigzag_x}]};
always_ff @(posedge clk) sigCtx_4x4_plus27 <= sigCtx_4x4 + 8'd27;
always_ff @(posedge clk) sigCtx_l0 <= CSBF_xplus1_zigzag ? (CSBF_yplus1_zigzag ? 2 : 
                                                                                 (currPix_zigzag_y == 0 ? 2 : (currPix_zigzag_y == 2'h1 ? 1 : 0))) :
                                                           (CSBF_yplus1_zigzag ? (currPix_zigzag_x == 0 ? 2 : (currPix_zigzag_x == 2'h1 ? 1 : 0)) : 
                                                                                 (currPix_zigzag == 0 ? 2 : (currPix_zigzag_xplusy < 3 ? 1 : 0)));
always_ff @(posedge clk) sigCtx_l1 <= (slice_type == SLICE_TYPE_I) ? (currSB_zigzag == 0 ? (log2TrafoSize == 3 ? (ScanOrderIdx == 0 ? sigCtx_l0 + 9 :
                                                                                                                                 sigCtx_l0 + 15) : 
                                                                                                                  sigCtx_l0 + 21) : 
                                                                                           (log2TrafoSize == 3 ? (ScanOrderIdx == 0 ? sigCtx_l0 + 12 :
                                                                                                                                 sigCtx_l0 + 18) : 
                                                                                                                  sigCtx_l0 + 24) ) :
                                                                     (log2TrafoSize == 3 ? sigCtx_l0 + 33 : 
                                                                                           sigCtx_l0 + 36);
always_ff @(posedge clk)
    if(state == CALC_COR_RES) ctxSet <= (slice_type == SLICE_TYPE_I && currSB_zigzag != 0) ? (lastGt1Flag ? 3 : 2) : (lastGt1Flag ? 1 : 0);
always_ff @(posedge clk)
    if(state == IDLE_RES) lastGt1Ctx <= 1;
    else if(state == COEFF_ABS_LEVEL_GT1_FLAG && dec_done) lastGt1Ctx <= ruiBin_delay[0] ? 0 : (lastGt1Ctx == 3 ? 3 : lastGt1Ctx + 1);
always_ff @(posedge clk)
    if(state == COEFF_ABS_LEVEL_GT1_FLAG && dec_done) lastGt1Flag <= ruiBin_delay[0];
always_ff @(posedge clk) ctxInc_gt1 <= (slice_type == SLICE_TYPE_I) ? {4'h0, ctxSet, 2'h0} + {6'h0, lastGt1Ctx} :
                                                                      {4'h1, ctxSet, 2'h0} + {6'h0, lastGt1Ctx};
always_ff @(posedge clk) ctxInc_gt2 <= (slice_type == SLICE_TYPE_I) ? {6'h0, ctxSet} :
                                                                      {6'h1, ctxSet};
always_ff @(posedge clk)
    case(state)
    TRANSFORM_SKIP_FLAG:       ctx_res_addr <= CTXIDX_TRANSFORM_SKIP_FLAG[0];
    LAST_SIG_COEFF_X_PREFIX:   ctx_res_addr <= (slice_type == SLICE_TYPE_I) ? (log2TrafoSize == 2 ? CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin] :
                                                                               log2TrafoSize == 3 ? CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin[7:1] + 3] :
                                                                               log2TrafoSize == 4 ? CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin[7:1] + 6] :
                                                                               CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin[7:1] + 10]) :
                                                                              (log2TrafoSize == 2 ? CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin + 15] :
                                                                               log2TrafoSize == 3 ? CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin[7:1] + 15] :
                                                                               log2TrafoSize == 4 ? CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin[7:2] + 15] :
                                                                               CTXIDX_LAST_SIG_COEFF_X_PREFIX[counter_coded_bin[7:3] + 15]);
    LAST_SIG_COEFF_Y_PREFIX:   ctx_res_addr <= (slice_type == SLICE_TYPE_I) ? (log2TrafoSize == 2 ? CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin] :
                                                                               log2TrafoSize == 3 ? CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin[7:1] + 3] :
                                                                               log2TrafoSize == 4 ? CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin[7:1] + 6] :
                                                                               CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin[7:1] + 10]) :
                                                                              (log2TrafoSize == 2 ? CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin + 15] :
                                                                               log2TrafoSize == 3 ? CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin[7:1] + 15] :
                                                                               log2TrafoSize == 4 ? CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin[7:2] + 15] :
                                                                               CTXIDX_LAST_SIG_COEFF_Y_PREFIX[counter_coded_bin[7:3] + 15]);
    CODED_SUB_BLOCK_FLAG:      ctx_res_addr <= (slice_type == SLICE_TYPE_I) ? ((CSBF_xplus1_zigzag || CSBF_yplus1_zigzag) ? CTXIDX_CODED_SUB_BLOCK_FLAG[1] : CTXIDX_CODED_SUB_BLOCK_FLAG[0])
                                                                            : ((CSBF_xplus1_zigzag || CSBF_yplus1_zigzag) ? CTXIDX_CODED_SUB_BLOCK_FLAG[3] : CTXIDX_CODED_SUB_BLOCK_FLAG[2]);
    SIG_COEFF_FLAG:            ctx_res_addr <= (slice_type == SLICE_TYPE_I) ? (transform_skip_enabled_flag ? CTXIDX_SIG_COEFF_FLAG[42] : 
                                                                               log2TrafoSize == 2 ? CTXIDX_SIG_COEFF_FLAG[sigCtx_4x4] :
                                                                               currPix_zigzag == 0 && currSB_zigzag == 0 ? CTXIDX_SIG_COEFF_FLAG[0] :
                                                                               CTXIDX_SIG_COEFF_FLAG[sigCtx_l1]) :
                                                                              (transform_skip_enabled_flag ? CTXIDX_SIG_COEFF_FLAG[43] : 
                                                                               log2TrafoSize == 2 ? CTXIDX_SIG_COEFF_FLAG[sigCtx_4x4_plus27] :
                                                                               currPix_zigzag == 0 && currSB_zigzag == 0 ? CTXIDX_SIG_COEFF_FLAG[27] :
                                                                               CTXIDX_SIG_COEFF_FLAG[sigCtx_l1]);
    COEFF_ABS_LEVEL_GT1_FLAG:  ctx_res_addr <= CTXIDX_COEFF_ABS_LEVEL_GT1_FLAG[ctxInc_gt1];
    COEFF_ABS_LEVEL_GT2_FLAG:  ctx_res_addr <= CTXIDX_COEFF_ABS_LEVEL_GT2_FLAG[ctxInc_gt2];
    default:                   ctx_res_addr <= 0;
    endcase


always_ff @(posedge clk)
    if(state == IDLE_RES) ctx_res_addr_vld_count <= 0;
    else if(dec_done) ctx_res_addr_vld_count <= 0;
    else if(ctx_res_addr_vld) ctx_res_addr_vld_count <= ctx_res_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_RES) dec_phase <= 0;
    else if(ctx_res_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;
always_ff @(posedge clk)
    case(state)
    IDLE_RES:                  ctx_res_addr_vld <= 0;
    TRANSFORM_SKIP_FLAG:       ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    LAST_SIG_COEFF_X_PREFIX:   ctx_res_addr_vld <= (ctx_res_addr_vld_count == target_bin) ? 0 : (dec_phase==0 ? 1 : 0);
    LAST_SIG_COEFF_Y_PREFIX:   ctx_res_addr_vld <= (ctx_res_addr_vld_count == target_bin) ? 0 : (dec_phase==0 ? 1 : 0);
    LAST_SIG_COEFF_X_SUFFIX:   ctx_res_addr_vld <= (ctx_res_addr_vld_count == target_bin) ? 0 : 1;
    LAST_SIG_COEFF_Y_SUFFIX:   ctx_res_addr_vld <= (ctx_res_addr_vld_count == target_bin) ? 0 : 1;
    CODED_SUB_BLOCK_FLAG:      ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    SIG_COEFF_FLAG:            ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    COEFF_ABS_LEVEL_GT1_FLAG:  ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    COEFF_ABS_LEVEL_GT2_FLAG:  ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    COEFF_SIGN_FLAG_FIRST:     ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : 1;
    COEFF_SIGN_FLAG:           ctx_res_addr_vld <= (ctx_res_addr_vld_count == 1) ? 0 : 1;
    COEFF_ABS_LEVEL_REM:       ctx_res_addr_vld <= (ctx_res_addr_vld_count == target_bin) ? 0 : 1;
    default:                   ctx_res_addr_vld <= 0;
    endcase

always_ff @(posedge clk)
    dec_run_res <= ctx_res_addr_vld;

always_ff @(posedge clk)
    case(state)
    IDLE_RES:                  EPMode_res <= 0;
    TRANSFORM_SKIP_FLAG:       EPMode_res <= 0;
    LAST_SIG_COEFF_X_PREFIX:   EPMode_res <= 0;
    LAST_SIG_COEFF_Y_PREFIX:   EPMode_res <= 0;
    LAST_SIG_COEFF_X_SUFFIX:   EPMode_res <= 1;
    LAST_SIG_COEFF_Y_SUFFIX:   EPMode_res <= 1;
    CODED_SUB_BLOCK_FLAG:      EPMode_res <= 1;
    SIG_COEFF_FLAG:            EPMode_res <= 1;
    COEFF_ABS_LEVEL_GT1_FLAG:  EPMode_res <= 1;
    COEFF_ABS_LEVEL_GT2_FLAG:  EPMode_res <= 1;
    COEFF_SIGN_FLAG_FIRST:     EPMode_res <= 0;
    COEFF_SIGN_FLAG:           EPMode_res <= 0;
    COEFF_ABS_LEVEL_REM:       EPMode_res <= 0;
    default:                   EPMode_res <= 0;
    endcase

// Sub FSMs

endmodule
