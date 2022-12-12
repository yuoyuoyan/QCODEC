// 
// Author : Qi Wang
// The sub-FSM to handle TU part decoding
module qdec_tu_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       tu_start,
    input  logic [2:0] log2TrafoSize,
    input  logic [2:0] trafoDepth,
    input  logic       cbf_luma,
    input  logic       cbf_cb,
    input  logic       cbf_cr,
    input  logic       parent_cbf_cb,
    input  logic       parent_cbf_cr,
    input  logic       cu_transquant_bypass_flag,
    input  logic [1:0] blkIdx,
    input  logic [1:0] slice_type,
    input  logic       amp_enabled_flag,
    input  logic       cabac_init_flag,

    output logic [9:0] ctx_tu_addr,
    output logic       ctx_tu_addr_vld,
    output logic       dec_run_tu,
    input  logic       dec_rdy,
    output logic       EPMode_tu,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       tu_done_intr
);

logic       res_start, dqp_start, cqp_start;
logic [9:0] ctx_res_addr, ctx_dqp_addr, ctx_cqp_addr;
logic       ctx_res_addr_vld, ctx_dqp_addr_vld, ctx_cqp_addr_vld;
logic       dec_run_res, dec_run_dqp, dec_run_cqp;
logic       EPMode_res, EPMode_dqp, EPMode_cqp;
logic       res_done_intr, dqp_done_intr, cqp_done_intr;
logic [2:0] log2TrafoSizeC, cbfDepthC;
logic [2:0] log2TrafoSize_res;
logic       cbf_chroma;

t_state_tu state, nxt_state;

always_comb
    case(state)
    IDLE_TU:                   nxt_state = tu_start===1'b1 ? CBF_TU : IDLE_TU;
    CBF_TU:                    nxt_state = (cbf_luma | cbf_chroma)===1'b1 ? DELTA_QP : ENDING_TU;
    DELTA_QP:                  nxt_state = dqp_done_intr===1'b1 ? ((cbf_chroma & !cu_transquant_bypass_flag)===1'b1 ? CHROMA_QP_OFFSET : 
                                                                                                                           (cbf_luma===1'b1 ? RES_CODING_LUMA : JUDGE_RES_CHROMA)) : 
                                                                       DELTA_QP;
    CHROMA_QP_OFFSET:          nxt_state = cqp_done_intr===1'b1 ? (cbf_luma===1'b1 ? RES_CODING_LUMA : JUDGE_RES_CHROMA) : CHROMA_QP_OFFSET;
    RES_CODING_LUMA:           nxt_state = res_done_intr===1'b1 ? JUDGE_RES_CHROMA : RES_CODING_LUMA;
    JUDGE_RES_CHROMA:          nxt_state = (log2TrafoSize > 2)===1'b1 ? (cbf_cb===1'b1 ? RES_CODING_CB : (cbf_cr===1'b1 ? RES_CODING_CR : ENDING_TU)) :
                                                                 (blkIdx===2'h3 ? (parent_cbf_cb===1'b1 ? RES_CODING_PARENT_CB : (parent_cbf_cr===1'b1 ? RES_CODING_PARENT_CR : ENDING_TU)) :
                                                                 ENDING_TU);
    RES_CODING_CB:             nxt_state = res_done_intr===1'b1 ? (cbf_cr===1'b1 ? RES_CODING_CR : ENDING_TU) : RES_CODING_CB;
    RES_CODING_CR:             nxt_state = res_done_intr===1'b1 ? ENDING_TU : RES_CODING_CR;
    RES_CODING_PARENT_CB:      nxt_state = res_done_intr===1'b1 ? (parent_cbf_cr===1'b1 ? RES_CODING_PARENT_CR : ENDING_TU) : RES_CODING_PARENT_CB;
    RES_CODING_PARENT_CR:      nxt_state = res_done_intr===1'b1 ? ENDING_TU : RES_CODING_PARENT_CR;
    ENDING_TU:                 nxt_state = IDLE_TU;
    default:                   nxt_state = IDLE_TU;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_TU;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) tu_done_intr <= (state == ENDING_TU) ? 1 : 0;

// Main FSM control signals

always_ff @(posedge clk) log2TrafoSizeC <= (state == CBF_TU) ? (log2TrafoSize > 3 ? log2TrafoSize-1 : 2) : log2TrafoSizeC;
always_ff @(posedge clk) cbfDepthC <= (state == CBF_TU) ? (log2TrafoSize == 2 ? trafoDepth-1 : trafoDepth) : cbfDepthC;
always_ff @(posedge clk) cbf_chroma <= (state == CBF_TU) ? (log2TrafoSize == 2 ? parent_cbf_cb|parent_cbf_cr : cbf_cb|cbf_cr) : cbf_chroma;

logic state_dqp_d, state_cqp_d, state_res_luma_d, state_res_cb_d, state_res_cr_d, state_res_parent_cb_d, state_res_parent_cr_d;
always_ff @(posedge clk) state_dqp_d <= (state == DELTA_QP) ? 1 : 0;
always_ff @(posedge clk) state_cqp_d <= (state == CHROMA_QP_OFFSET) ? 1 : 0;
always_ff @(posedge clk) state_res_luma_d <= (state == RES_CODING_LUMA) ? 1 : 0;
always_ff @(posedge clk) state_res_cb_d <= (state == RES_CODING_CB) ? 1 : 0;
always_ff @(posedge clk) state_res_cr_d <= (state == RES_CODING_CR) ? 1 : 0;
always_ff @(posedge clk) state_res_parent_cb_d <= (state == RES_CODING_PARENT_CB) ? 1 : 0;
always_ff @(posedge clk) state_res_parent_cr_d <= (state == RES_CODING_PARENT_CR) ? 1 : 0;
assign dqp_start = ({state_dqp_d, (state == DELTA_QP) ? 1'b1 : 1'b0} == 2'b01) ? 1 : 0;
assign cqp_start = ({state_cqp_d, (state == CHROMA_QP_OFFSET) ? 1'b1 : 1'b0}) ? 1 : 0;
assign res_start = ({state_res_luma_d, (state == RES_CODING_LUMA) ? 1'b1 : 1'b0} == 2'b01 ||
                    {state_res_cb_d, (state == RES_CODING_CB) ? 1'b1 : 1'b0} == 2'b01 ||
                    {state_res_cr_d, (state == RES_CODING_CR) ? 1'b1 : 1'b0} == 2'b01 ||
                    {state_res_parent_cb_d, (state == RES_CODING_PARENT_CB) ? 1'b1 : 1'b0} == 2'b01 ||
                    {state_res_parent_cr_d, (state == RES_CODING_PARENT_CR) ? 1'b1 : 1'b0} == 2'b01) ? 1 : 0;

// Other output signal control
always_ff @(posedge clk) ctx_tu_addr <= (state == DELTA_QP) ? ctx_dqp_addr : ((state == CHROMA_QP_OFFSET) ? ctx_cqp_addr : ctx_res_addr);
always_ff @(posedge clk) ctx_tu_addr_vld <= (state == DELTA_QP) ? ctx_dqp_addr_vld : ((state == CHROMA_QP_OFFSET) ? ctx_cqp_addr_vld : ctx_res_addr_vld);
always_ff @(posedge clk) dec_run_tu <= (state == DELTA_QP) ? dec_run_dqp : ((state == CHROMA_QP_OFFSET) ? dec_run_cqp : dec_run_res);
always_ff @(posedge clk) EPMode_tu <= (state == DELTA_QP) ? EPMode_dqp : ((state == CHROMA_QP_OFFSET) ? EPMode_cqp : EPMode_res);

// Sub FSMs
qdec_dqp_fsm dqp_fsm(
    .clk,
    .rst_n,

    .dqp_start,
    .slice_type,
    .cabac_init_flag,

    .ctx_dqp_addr,
    .ctx_dqp_addr_vld,
    .dec_run_dqp,
    .dec_rdy,
    .EPMode_dqp,
    .ruiBin,
    .ruiBin_vld,
    .dqp_done_intr
);

qdec_cqp_fsm cqp_fsm(
    .clk,
    .rst_n,

    .cqp_start,
    .slice_type,
    .cabac_init_flag,

    .ctx_cqp_addr,
    .ctx_cqp_addr_vld,
    .dec_run_cqp,
    .dec_rdy,
    .EPMode_cqp,
    .ruiBin,
    .ruiBin_vld,
    .cqp_done_intr
);

qdec_res_fsm res_fsm(
    .clk,
    .rst_n,

    .res_start,
    .slice_type,
    .cabac_init_flag,

    .ctx_res_addr,
    .ctx_res_addr_vld,
    .dec_run_res,
    .dec_rdy,
    .EPMode_res,
    .ruiBin,
    .ruiBin_vld,
    .res_done_intr
);

endmodule
