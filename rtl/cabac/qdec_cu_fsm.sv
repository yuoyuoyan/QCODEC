// 
// Author : Qi Wang
// The sub-FSM to handle CU part decoding
module qdec_cu_fsm import qdec_cabac_package::*;(
    input clk,
    input rst_n,

    input  logic       cu_start,
    input  logic [9:0] xCU,
    input  logic [8:0] yCU,
    input  logic [2:0] log2CUSize,
    input  logic [2:0] minCbLog2CUSize,
    input  logic [2:0] log2DiffMaxMinCodingBlockSize,
    input  logic [1:0] slice_type,
    input  logic       amp_enabled_flag,
    input  logic       cabac_init_flag,
    input  logic       transquant_bypass_enabled_flag,
    input  logic       condL,
    input  logic       condA,

    output logic [9:0] ctx_cu_addr,
    output logic       ctx_cu_addr_vld,
    output logic       dec_run_cu,
    input  logic       dec_rdy,
    output logic       EPMode_cu,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       cu_done_intr
);

logic       cu_transquant_bypass_flag;
logic       cu_skip_flag;
logic       pred_mode_flag;
logic [3:0] part_mode;
logic       merge_flag;
logic [3:0] prev_intra_luma_pred_flag;
logic [1:0] mpm_idx[3:0];
logic [4:0] rem_intra_luma_pred_mode[3:0];
logic [1:0] intra_chroma_pred_mode[3:0];
logic [3:0] intra_chroma_dm_mode;
logic       rqt_root_cbf;
logic       intra_split_flag;
logic       dec_done;
logic [5:0] nPbW, nPbH;
logic       pu_start, trafo_start;
logic [9:0] ctx_pu_addr, ctx_trafo_addr;
logic       ctx_pu_addr_vld, ctx_trafo_addr_vld;
logic       dec_run_pu, dec_run_trafo;
logic       EPMode_pu, EPMode_trafo;
logic       pu_done_intr, trafo_done_intr;
logic [7:0] counter_coded_bin;
logic [7:0] ruiBin_delay;
logic [2:0] ctx_cu_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
logic [2:0] target_bin;

t_state_cu state, nxt_state;

always_comb
    case(state)
    IDLE_CU:                   nxt_state = cu_start ? JUDGE_FIRST_BIT_CU : IDLE_CU;
    JUDGE_FIRST_BIT_CU:        nxt_state = transquant_bypass_enabled_flag ? CU_TRANSQUANT_BYPASS_FLAG : 
                                           (slice_type != SLICE_TYPE_I) ? CU_SKIP_FLAG : JUDGE_CB_SPLIT;
    CU_TRANSQUANT_BYPASS_FLAG: nxt_state = dec_done ? ((slice_type != SLICE_TYPE_I) ? CU_SKIP_FLAG : JUDGE_CB_SPLIT) : CU_TRANSQUANT_BYPASS_FLAG;
    CU_SKIP_FLAG:              nxt_state = dec_done ? (cu_skip_flag ? PU_CU : PRED_MODE_FLAG) : CU_SKIP_FLAG;
    PRED_MODE_FLAG:            nxt_state = dec_done ? ((pred_mode_flag == PRED_MODE_FLAG_INTER || log2CUSize == minCbLog2CUSize) ? PART_MODE : JUDGE_CB_SPLIT) : PRED_MODE_FLAG;
    // inter prediction part
    PART_MODE:                 nxt_state = dec_done ? PU_CU : PART_MODE;
    PU_CU:                     nxt_state = pu_done_intr ? ((part_mode != PART_MODE_INTER_PART_2Nx2N || merge_flag == 0) ? RQT_ROOT_CBF : trafo) : PU_CU;
    RQT_ROOT_CBF:              nxt_state = rqt_root_cbf ? trafo : ENDING_CU;
    // intra prediction part
    JUDGE_CB_SPLIT:            nxt_state = PREV_INTRA_LUMA_PRED_FLAG;
    PREV_INTRA_LUMA_PRED_FLAG: nxt_state = dec_done ? (intra_split_flag ? (prev_intra_luma_pred_flag[0] ? MPM_IDX0 : REM_INTRA_LUMA_PRED_MODE0) : 
                                                                          (prev_intra_luma_pred_flag[0] ? MPM_IDX : REM_INTRA_LUMA_PRED_MODE)) : 
                                           PREV_INTRA_LUMA_PRED_FLAG;
    MPM_IDX0:                  nxt_state = dec_done ? (prev_intra_luma_pred_flag[1] ? MPM_IDX1 : REM_INTRA_LUMA_PRED_MODE1) : MPM_IDX0;
    MPM_IDX1:                  nxt_state = dec_done ? (prev_intra_luma_pred_flag[2] ? MPM_IDX2 : REM_INTRA_LUMA_PRED_MODE2) : MPM_IDX1;
    MPM_IDX2:                  nxt_state = dec_done ? (prev_intra_luma_pred_flag[3] ? MPM_IDX3 : REM_INTRA_LUMA_PRED_MODE3) : MPM_IDX2;
    MPM_IDX3:                  nxt_state = dec_done ? (intra_split_flag ? INTRA_CHROMA_PRED_MODE0 : INTRA_CHROMA_PRED_MODE) : MPM_IDX3;
    MPM_IDX:                   nxt_state = dec_done ? (intra_split_flag ? INTRA_CHROMA_PRED_MODE0 : INTRA_CHROMA_PRED_MODE) : MPM_IDX;
    REM_INTRA_LUMA_PRED_MODE0: nxt_state = dec_done ? (prev_intra_luma_pred_flag[1] ? MPM_IDX1 : REM_INTRA_LUMA_PRED_MODE1) : REM_INTRA_LUMA_PRED_MODE0;
    REM_INTRA_LUMA_PRED_MODE1: nxt_state = dec_done ? (prev_intra_luma_pred_flag[2] ? MPM_IDX2 : REM_INTRA_LUMA_PRED_MODE2) : REM_INTRA_LUMA_PRED_MODE1;
    REM_INTRA_LUMA_PRED_MODE2: nxt_state = dec_done ? (prev_intra_luma_pred_flag[3] ? MPM_IDX3 : REM_INTRA_LUMA_PRED_MODE3) : REM_INTRA_LUMA_PRED_MODE2;
    REM_INTRA_LUMA_PRED_MODE3: nxt_state = dec_done ? (intra_split_flag ? INTRA_CHROMA_PRED_MODE0 : INTRA_CHROMA_PRED_MODE) : MPM_IDX;
    REM_INTRA_LUMA_PRED_MODE:  nxt_state = dec_done ? (intra_split_flag ? INTRA_CHROMA_PRED_MODE0 : INTRA_CHROMA_PRED_MODE) : MPM_IDX;
    INTRA_CHROMA_PRED_MODE0:   nxt_state = dec_done ? INTRA_CHROMA_PRED_MODE1 : INTRA_CHROMA_PRED_MODE0;
    INTRA_CHROMA_PRED_MODE1:   nxt_state = dec_done ? INTRA_CHROMA_PRED_MODE2 : INTRA_CHROMA_PRED_MODE1;
    INTRA_CHROMA_PRED_MODE2:   nxt_state = dec_done ? INTRA_CHROMA_PRED_MODE3 : INTRA_CHROMA_PRED_MODE2;
    INTRA_CHROMA_PRED_MODE3:   nxt_state = dec_done ? TRAFO : INTRA_CHROMA_PRED_MODE3;
    INTRA_CHROMA_PRED_MODE:    nxt_state = dec_done ? TRAFO : INTRA_CHROMA_PRED_MODE;
    // transform part
    TRAFO:                     nxt_state = trafo_done_intr ? ENDING_CU : TRAFO;
    ENDING_CU:                 nxt_state = IDLE_CU;
    default:                   nxt_state = IDLE_CU;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_CU;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) cu_done_intr <= (state == ENDING_CU) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_CU || dec_done) 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[6:0], ruiBin} : ruiBin_delay; // store the decoded bins

always_ff @(posedge clk) cu_skip_flag <= (state == CU_SKIP_FLAG && ruiBin_vld) ? ruiBin : cu_skip_flag;
always_ff @(posedge clk) pred_mode_flag <= (log2CUSize == minCbLog2CUSize) ? 0 : ((state == PRED_MODE_FLAG && ruiBin_vld) ? ruiBin : pred_mode_flag);
always_ff @(posedge clk) 
    if(state == PART_MODE && dec_done) 
        part_mode <= pred_mode_flag ? ((log2CUSize == minCbLog2CUSize) ? PART_MODE_INTRA_PART_2Nx2N : {3'h0, ruiBin_delay[0]}) :
                                      ((log2CUSize == minCbLog2CUSize) ? {1'b0, ruiBin_delay[2:0]} : 
                                       (amp_enabled_flag && (counter_coded_bin == 3) && ruiBin_delay[2:0] == {PART_MODE_INTRA_PART_2NxN, 1'b1}) ? {1'b0, ruiBin_delay[2:0]} :
                                       (amp_enabled_flag && (counter_coded_bin == 4) && ruiBin_delay[3:1] == {PART_MODE_INTRA_PART_2NxN, 1'b0}) ? ruiBin_delay[3:0] :
                                       (amp_enabled_flag && (counter_coded_bin == 3) && ruiBin_delay[2:0] == {PART_MODE_INTRA_PART_Nx2N, 1'b1}) ? {1'b0, ruiBin_delay[2:0]} :
                                       (amp_enabled_flag && (counter_coded_bin == 4) && ruiBin_delay[3:1] == {PART_MODE_INTRA_PART_Nx2N, 1'b0}) ? ruiBin_delay[3:0] : 
                                       {2'h0, ruiBin_delay[1:0]});
always_ff @(posedge clk) rqt_root_cbf <= (state == RQT_ROOT_CBF && dec_done) ? ruiBin : rqt_root_cbf;
always_ff @(posedge clk) intra_split_flag <= (pred_mode_flag == PRED_MODE_FLAG_INTRA && part_mode == PART_MODE_INTRA_PART_NxN) ? 1 : 0;
always_ff @(posedge clk) prev_intra_luma_pred_flag <= (state == PREV_INTRA_LUMA_PRED_FLAG && dec_done) ? (intra_split_flag ? ruiBin_delay[3:0] : {3'h0, ruiBin_delay[0]}) :
                                                      prev_intra_luma_pred_flag;
always_ff @(posedge clk) mpm_idx[0] <= (state == MPM_IDX && dec_done) ? ((counter_coded_bin == 2 && ruiBin_delay[1] == 1'b1) ? ruiBin_delay[1:0] : {1'b0, ruiBin_delay[0]}) :
                                       (state == MPM_IDX0 && dec_done) ? ((counter_coded_bin == 2 && ruiBin_delay[1] == 1'b1) ? ruiBin_delay[1:0] : {1'b0, ruiBin_delay[0]}) :
                                       mpm_idx[0];
always_ff @(posedge clk) mpm_idx[1] <= (state == MPM_IDX1 && dec_done) ? ((counter_coded_bin == 2 && ruiBin_delay[1] == 1'b1) ? ruiBin_delay[1:0] : {1'b0, ruiBin_delay[0]}) :
                                       mpm_idx[1];
always_ff @(posedge clk) mpm_idx[2] <= (state == MPM_IDX2 && dec_done) ? ((counter_coded_bin == 2 && ruiBin_delay[1] == 1'b1) ? ruiBin_delay[1:0] : {1'b0, ruiBin_delay[0]}) :
                                       mpm_idx[2];
always_ff @(posedge clk) mpm_idx[3] <= (state == MPM_IDX3 && dec_done) ? ((counter_coded_bin == 2 && ruiBin_delay[1] == 1'b1) ? ruiBin_delay[1:0] : {1'b0, ruiBin_delay[0]}) :
                                       mpm_idx[3];
always_ff @(posedge clk) rem_intra_luma_pred_mode[0] <= (state == REM_INTRA_LUMA_PRED_MODE && dec_done) ? ruiBin_delay[4:0] :
                                                        (state == REM_INTRA_LUMA_PRED_MODE0 && dec_done) ? ruiBin_delay[4:0] :
                                                        rem_intra_luma_pred_mode[0];
always_ff @(posedge clk) rem_intra_luma_pred_mode[1] <= (state == REM_INTRA_LUMA_PRED_MODE1 && dec_done) ? ruiBin_delay[4:0] :
                                                        rem_intra_luma_pred_mode[1];
always_ff @(posedge clk) rem_intra_luma_pred_mode[2] <= (state == REM_INTRA_LUMA_PRED_MODE2 && dec_done) ? ruiBin_delay[4:0] :
                                                        rem_intra_luma_pred_mode[2];
always_ff @(posedge clk) rem_intra_luma_pred_mode[3] <= (state == REM_INTRA_LUMA_PRED_MODE3 && dec_done) ? ruiBin_delay[4:0] :
                                                        rem_intra_luma_pred_mode[3];
always_ff @(posedge clk) intra_chroma_dm_mode[0] <= (state == INTRA_CHROMA_PRED_MODE && dec_done && counter_coded_bin == 1) ? 1 : 
                                                    (state == INTRA_CHROMA_PRED_MODE0 && dec_done && counter_coded_bin == 1) ? 1 : 0;
always_ff @(posedge clk) intra_chroma_dm_mode[1] <= (state == INTRA_CHROMA_PRED_MODE1 && dec_done && counter_coded_bin == 1) ? 1 : 0;
always_ff @(posedge clk) intra_chroma_dm_mode[2] <= (state == INTRA_CHROMA_PRED_MODE2 && dec_done && counter_coded_bin == 1) ? 1 : 0;
always_ff @(posedge clk) intra_chroma_dm_mode[3] <= (state == INTRA_CHROMA_PRED_MODE3 && dec_done && counter_coded_bin == 1) ? 1 : 0;
always_ff @(posedge clk) intra_chroma_pred_mode[0] <= (state == INTRA_CHROMA_PRED_MODE && dec_done && counter_coded_bin == 2) ? ruiBin_delay[1:0] :
                                                      (state == INTRA_CHROMA_PRED_MODE0 && dec_done && counter_coded_bin == 2) ? ruiBin_delay[1:0] :
                                                      intra_chroma_pred_mode[0];
always_ff @(posedge clk) intra_chroma_pred_mode[1] <= (state == INTRA_CHROMA_PRED_MODE1 && dec_done && counter_coded_bin == 2) ? ruiBin_delay[1:0] :
                                                      intra_chroma_pred_mode[1];
always_ff @(posedge clk) intra_chroma_pred_mode[2] <= (state == INTRA_CHROMA_PRED_MODE2 && dec_done && counter_coded_bin == 2) ? ruiBin_delay[1:0] :
                                                      intra_chroma_pred_mode[2];
always_ff @(posedge clk) intra_chroma_pred_mode[3] <= (state == INTRA_CHROMA_PRED_MODE3 && dec_done && counter_coded_bin == 2) ? ruiBin_delay[1:0] :
                                                      intra_chroma_pred_mode[3];

always_ff @(posedge clk)
    if(state == PART_MODE)
        target_bin <= pred_mode_flag ? ((log2CUSize == minCbLog2CUSize) ? 0 : 1) :
                                       ((log2CUSize == minCbLog2CUSize) ? 3 : 
                                        (amp_enabled_flag && (counter_coded_bin == 2) && ruiBin_delay[1:0] == PART_MODE_INTRA_PART_2NxN) ? 3 :
                                        (amp_enabled_flag && (counter_coded_bin == 3) && ruiBin_delay[2:0] == {PART_MODE_INTRA_PART_2NxN, 1'b0}) ? 4 :
                                        (amp_enabled_flag && (counter_coded_bin == 2) && ruiBin_delay[1:0] == PART_MODE_INTRA_PART_Nx2N) ? 3 :
                                        (amp_enabled_flag && (counter_coded_bin == 3) && ruiBin_delay[2:0] == {PART_MODE_INTRA_PART_Nx2N, 1'b0}) ? 4 : 
                                        2);
    else if(state == MPM_IDX0 || state == MPM_IDX1 || state == MPM_IDX2 || state == MPM_IDX3 || state == MPM_IDX)
        target_bin <= (counter_coded_bin == 1 && ruiBin_delay[0] == 1'b1) ? 2  : 1;

always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   dec_done <= 0;
    CU_TRANSQUANT_BYPASS_FLAG: dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    CU_SKIP_FLAG:              dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    PRED_MODE_FLAG:            dec_done <= (counter_coded_bin == 1 || log2CUSize == minCbLog2CUSize) ? 1 : 0;
    PART_MODE:                 dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    RQT_ROOT_CBF:              dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    PREV_INTRA_LUMA_PRED_FLAG: dec_done <= intra_split_flag ? (counter_coded_bin == 4 ? 1 : 0) : (counter_coded_bin == 1 ? 1 : 0);
    MPM_IDX0:                  dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MPM_IDX1:                  dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MPM_IDX2:                  dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MPM_IDX3:                  dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MPM_IDX:                   dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    REM_INTRA_LUMA_PRED_MODE0: dec_done <= (counter_coded_bin == 5) ? 1 : 0;
    REM_INTRA_LUMA_PRED_MODE1: dec_done <= (counter_coded_bin == 5) ? 1 : 0;
    REM_INTRA_LUMA_PRED_MODE2: dec_done <= (counter_coded_bin == 5) ? 1 : 0;
    REM_INTRA_LUMA_PRED_MODE3: dec_done <= (counter_coded_bin == 5) ? 1 : 0;
    REM_INTRA_LUMA_PRED_MODE:  dec_done <= (counter_coded_bin == 5) ? 1 : 0;
    INTRA_CHROMA_PRED_MODE0:   dec_done <= (counter_coded_bin == 2) ? 1 : 0;
    INTRA_CHROMA_PRED_MODE1:   dec_done <= (counter_coded_bin == 2) ? 1 : 0;
    INTRA_CHROMA_PRED_MODE2:   dec_done <= (counter_coded_bin == 2) ? 1 : 0;
    INTRA_CHROMA_PRED_MODE3:   dec_done <= (counter_coded_bin == 2) ? 1 : 0;
    INTRA_CHROMA_PRED_MODE:    dec_done <= (counter_coded_bin == 2) ? 1 : 0;
    default: dec_done <= 0;
    endcase

logic state_pu_cu_d, state_trafo_d;
always_ff @(posedge clk) state_pu_cu_d <= (state == PU_CU) ? 1 : 0;
always_ff @(posedge clk) state_trafo_d <= (state == TRAFO) ? 1 : 0;
assign pu_start = ({state_pu_cu_d, (state == PU_CU) ? 1'b1 : 1'b0} == 2'b01) ? 1 : 0;
assign trafo_start = ({state_trafo_d, (state == TRAFO) ? 1'b1 : 1'b0}) ? 1 : 0;

always_ff @(posedge clk) 
    casex({log2CUSize, part_mode})
    7'b110_0000: begin nPbW <= 63; nPbH <= 63; end
    7'b110_0001: begin nPbW <= 63; nPbH <= 31; end
    7'b110_0010: begin nPbW <= 31; nPbH <= 63; end
    7'b110_0011: begin nPbW <= 31; nPbH <= 31; end
    7'b110_0100: begin nPbW <= 63; nPbH <= 15; end
    7'b110_0101: begin nPbW <= 63; nPbH <= 47; end
    7'b110_0110: begin nPbW <= 15; nPbH <= 63; end
    7'b110_0111: begin nPbW <= 47; nPbH <= 63; end
    7'b101_0000: begin nPbW <= 31; nPbH <= 31; end
    7'b101_0001: begin nPbW <= 31; nPbH <= 15; end
    7'b101_0010: begin nPbW <= 15; nPbH <= 31; end
    7'b101_0011: begin nPbW <= 15; nPbH <= 15; end
    7'b101_0100: begin nPbW <= 31; nPbH <=  7; end
    7'b101_0101: begin nPbW <= 31; nPbH <= 23; end
    7'b101_0110: begin nPbW <=  7; nPbH <= 31; end
    7'b101_0111: begin nPbW <= 23; nPbH <= 31; end
    7'b100_0000: begin nPbW <= 15; nPbH <= 15; end
    7'b100_0001: begin nPbW <= 15; nPbH <=  7; end
    7'b100_0010: begin nPbW <=  7; nPbH <= 15; end
    7'b100_0011: begin nPbW <=  7; nPbH <=  7; end
    7'b100_0100: begin nPbW <= 15; nPbH <=  3; end
    7'b100_0101: begin nPbW <= 15; nPbH <= 11; end
    7'b100_0110: begin nPbW <=  3; nPbH <= 15; end
    7'b100_0111: begin nPbW <= 11; nPbH <= 15; end
    7'b011_0000: begin nPbW <=  7; nPbH <=  7; end
    7'b011_0001: begin nPbW <=  7; nPbH <=  3; end
    7'b011_0010: begin nPbW <=  3; nPbH <=  7; end
    default:     begin nPbW <= 63; nPbH <= 63; end
    endcase

// Other output signal control
always_ff @(posedge clk)
    case(state)
    CU_TRANSQUANT_BYPASS_FLAG: ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_CU_TRANSQUANT_BYPASS_FLAG[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_CU_TRANSQUANT_BYPASS_FLAG[2] : CTXIDX_CU_TRANSQUANT_BYPASS_FLAG[1]) :
                                              (cabac_init_flag ? CTXIDX_CU_TRANSQUANT_BYPASS_FLAG[1] : CTXIDX_CU_TRANSQUANT_BYPASS_FLAG[2]);
    CU_SKIP_FLAG:              ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? 
                                              condL? (condA ? CTXIDX_CU_SKIP_FLAG[2] : CTXIDX_CU_SKIP_FLAG[1]) : (conndA ? CTXIDX_CU_SKIP_FLAG[1] : CTXIDX_CU_SKIP_FLAG[0]) :
                                              condL? (condA ? CTXIDX_CU_SKIP_FLAG[5] : CTXIDX_CU_SKIP_FLAG[4]) : (conndA ? CTXIDX_CU_SKIP_FLAG[4] : CTXIDX_CU_SKIP_FLAG[3]);
    PRED_MODE_FLAG:            ctx_cu_addr <= (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_PRED_MODE_FLAG[1] : CTXIDX_PRED_MODE_FLAG[0]) :
                                              (cabac_init_flag ? CTXIDX_PRED_MODE_FLAG[0] : CTXIDX_PRED_MODE_FLAG[1]);
    PART_MODE:                 ctx_cu_addr <= log2CUSize == minCbLog2CUSize ? ((counter_coded_bin >= 3) ? CTXIDX_PART_MODE[2] : CTXIDX_PART_MODE[0 + counter_coded_bin]) : 
                                                                              ((counter_coded_bin >= 3) ? CTXIDX_PART_MODE[3] : CTXIDX_PART_MODE[0 + counter_coded_bin]);
    RQT_ROOT_CBF:              ctx_cu_addr <= (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_RQT_ROOT_CBF[1] : CTXIDX_RQT_ROOT_CBF[0]) :
                                              (cabac_init_flag ? CTXIDX_RQT_ROOT_CBF[0] : CTXIDX_RQT_ROOT_CBF[1]);
    PREV_INTRA_LUMA_PRED_FLAG: ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_PREV_INTRA_LUMA_PRED_FLAG[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_PREV_INTRA_LUMA_PRED_FLAG[2] : CTXIDX_PREV_INTRA_LUMA_PRED_FLAG[1]) :
                                              (cabac_init_flag ? CTXIDX_PREV_INTRA_LUMA_PRED_FLAG[1] : CTXIDX_PREV_INTRA_LUMA_PRED_FLAG[2]);
    INTRA_CHROMA_PRED_MODE0:   ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_INTRA_CHROMA_PRED_MODE[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[2] : CTXIDX_INTRA_CHROMA_PRED_MODE[1]) :
                                              (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[1] : CTXIDX_INTRA_CHROMA_PRED_MODE[2]);
    INTRA_CHROMA_PRED_MODE1:   ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_INTRA_CHROMA_PRED_MODE[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[2] : CTXIDX_INTRA_CHROMA_PRED_MODE[1]) :
                                              (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[1] : CTXIDX_INTRA_CHROMA_PRED_MODE[2]);
    INTRA_CHROMA_PRED_MODE2:   ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_INTRA_CHROMA_PRED_MODE[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[2] : CTXIDX_INTRA_CHROMA_PRED_MODE[1]) :
                                              (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[1] : CTXIDX_INTRA_CHROMA_PRED_MODE[2]);
    INTRA_CHROMA_PRED_MODE3:   ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_INTRA_CHROMA_PRED_MODE[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[2] : CTXIDX_INTRA_CHROMA_PRED_MODE[1]) :
                                              (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[1] : CTXIDX_INTRA_CHROMA_PRED_MODE[2]);
    INTRA_CHROMA_PRED_MODE:    ctx_cu_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_INTRA_CHROMA_PRED_MODE[0] : 
                                              (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[2] : CTXIDX_INTRA_CHROMA_PRED_MODE[1]) :
                                              (cabac_init_flag ? CTXIDX_INTRA_CHROMA_PRED_MODE[1] : CTXIDX_INTRA_CHROMA_PRED_MODE[2]);
    endcase


always_ff @(posedge clk)
    if(state == IDLE_CU) ctx_cu_addr_vld_count <= 0;
    else if(dec_done) ctx_cu_addr_vld_count <= 0;
    else if(ctx_cu_addr_vld) ctx_cu_addr_vld_count <= ctx_cu_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_CU) dec_phase <= 0;
    else if(ctx_cu_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;
always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   ctx_cu_addr_vld <= 0;
    CU_TRANSQUANT_BYPASS_FLAG: ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    CU_SKIP_FLAG:              ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    PRED_MODE_FLAG:            ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    PART_MODE:                 ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == target_bin) ? 0 : ((dec_phase==0 || ctx_cu_addr_vld_count==3) ? 1 : 0);
    RQT_ROOT_CBF:              ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    PREV_INTRA_LUMA_PRED_FLAG: ctx_cu_addr_vld <= intra_split_flag ? ((ctx_cu_addr_vld_count == 4) ? 0 : (dec_phase==0 ? 1 : 0)) : ((ctx_cu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0));
    MPM_IDX0:                  ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == target_bin) ? 0 : 1;
    MPM_IDX1:                  ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == target_bin) ? 0 : 1;
    MPM_IDX2:                  ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == target_bin) ? 0 : 1;
    MPM_IDX3:                  ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == target_bin) ? 0 : 1;
    MPM_IDX:                   ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == target_bin) ? 0 : 1;
    REM_INTRA_LUMA_PRED_MODE0: ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 5) ? 0 : 1;
    REM_INTRA_LUMA_PRED_MODE1: ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 5) ? 0 : 1;
    REM_INTRA_LUMA_PRED_MODE2: ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 5) ? 0 : 1;
    REM_INTRA_LUMA_PRED_MODE3: ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 5) ? 0 : 1;
    REM_INTRA_LUMA_PRED_MODE:  ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 5) ? 0 : 1;
    INTRA_CHROMA_PRED_MODE0:   ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 2) ? 0 : ((dec_phase==0 || ctx_cu_addr_vld_count==1) ? 1 : 0);
    INTRA_CHROMA_PRED_MODE1:   ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 2) ? 0 : ((dec_phase==0 || ctx_cu_addr_vld_count==1) ? 1 : 0);
    INTRA_CHROMA_PRED_MODE2:   ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 2) ? 0 : ((dec_phase==0 || ctx_cu_addr_vld_count==1) ? 1 : 0);
    INTRA_CHROMA_PRED_MODE3:   ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 2) ? 0 : ((dec_phase==0 || ctx_cu_addr_vld_count==1) ? 1 : 0);
    INTRA_CHROMA_PRED_MODE:    ctx_cu_addr_vld <= (ctx_cu_addr_vld_count == 2) ? 0 : ((dec_phase==0 || ctx_cu_addr_vld_count==1) ? 1 : 0);
    default:                   ctx_cu_addr_vld <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    PU_CU: dec_run_cu <= dec_run_pu;
    TRAFO: dec_run_cu <= dec_run_trafo;
    default: dec_run_cu <= ctx_cu_addr_vld;
    endcase

always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   EPMode_cu <= 0;             
    CU_TRANSQUANT_BYPASS_FLAG: EPMode_cu <= 0;
    CU_SKIP_FLAG:              EPMode_cu <= 0;
    PRED_MODE_FLAG:            EPMode_cu <= 0;
    PART_MODE:                 EPMode_cu <= (counter_coded_bin >=2) ? 0 : 1;
    RQT_ROOT_CBF:              EPMode_cu <= 0;
    PREV_INTRA_LUMA_PRED_FLAG: EPMode_cu <= 0;
    MPM_IDX0:                  EPMode_cu <= 1;
    MPM_IDX1:                  EPMode_cu <= 1;
    MPM_IDX2:                  EPMode_cu <= 1;
    MPM_IDX3:                  EPMode_cu <= 1;
    MPM_IDX:                   EPMode_cu <= 1;
    REM_INTRA_LUMA_PRED_MODE0: EPMode_cu <= 1;
    REM_INTRA_LUMA_PRED_MODE1: EPMode_cu <= 1;
    REM_INTRA_LUMA_PRED_MODE2: EPMode_cu <= 1;
    REM_INTRA_LUMA_PRED_MODE3: EPMode_cu <= 1;
    REM_INTRA_LUMA_PRED_MODE:  EPMode_cu <= 1;
    INTRA_CHROMA_PRED_MODE0:   EPMode_cu <= (counter_coded_bin >= 1) ? 0 : 1;
    INTRA_CHROMA_PRED_MODE1:   EPMode_cu <= (counter_coded_bin >= 1) ? 0 : 1;
    INTRA_CHROMA_PRED_MODE2:   EPMode_cu <= (counter_coded_bin >= 1) ? 0 : 1;
    INTRA_CHROMA_PRED_MODE3:   EPMode_cu <= (counter_coded_bin >= 1) ? 0 : 1;
    INTRA_CHROMA_PRED_MODE:    EPMode_cu <= (counter_coded_bin >= 1) ? 0 : 1;
    default : EPMode_cu <= 0;
    endcase

// Sub FSMs
qdec_pu_fsm pu_fsm(
    .clk,
    .rst_n,

    .pu_start,
    .slice_type,
    .cu_skip_flag,
    .nPbW,
    .nPbH,
    .cabac_init_flag,

    .ctx_pu_addr,
    .ctx_pu_addr_vld,
    .dec_run_pu,
    .dec_rdy,
    .EPMode_pu,
    .ruiBin,
    .ruiBin_vld,
    .pu_done_intr
);

qdec_trafo_fsm trafo_fsm(
    .clk,
    .rst_n,

    .trafo_start,
    .slice_type,
    .cabac_init_flag,

    .ctx_trafo_addr,
    .ctx_trafo_addr_vld,
    .dec_run_trafo,
    .dec_rdy,
    .EPMode_trafo
    .ruiBin,
    .ruiBin_vld,
    .trafo_done_intr
);

endmodule
