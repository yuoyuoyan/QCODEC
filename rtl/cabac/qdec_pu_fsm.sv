// 
// Author : Qi Wang
// The sub-FSM to handle PU part decoding
module qdec_pu_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       pu_start,
    input  logic [5:0] nPbW,
    input  logic [5:0] nPbH,
    input  logic [2:0] split_depth,
    input  logic [1:0] slice_type,
    input  logic       cu_skip_flag,
    input  logic       cabac_init_flag,
    input  logic [2:0] maxNumMergeCand,

    output logic [9:0] ctx_pu_addr,
    output logic       ctx_pu_addr_vld,
    output logic       dec_run_pu,
    input  logic       dec_rdy,
    output logic       EPMode_pu,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       pu_done_intr
);

logic       dec_done;
logic [2:0] counter_coded_bin;
logic [7:0] ruiBin_delay;
logic [2:0] target_bin;
logic [2:0] merge_idx;
logic       merge_flag;
logic [1:0] inter_pred_idc;
logic [7:0] ref_idx_l0, ref_idx_l1;
logic       mvp_l0_flag, mvp_l1_flag;
logic       mvd_start;
logic [9:0] ctx_mvd_addr;
logic       ctx_mvd_addr_vld;
logic       dec_run_mvd;
logic       EPMode_mvd;
logic       mvd_done_intr;

t_state_pu state, nxt_state;

always_comb
    case(state)
    IDLE_PU:                   nxt_state = pu_start===1'b1 ? ((cu_skip_flag && maxNumMergeCand>1)===1'b1 ? MERGE_IDX : MERGE_FLAG) : IDLE_PU;
    MERGE_IDX:                 nxt_state = dec_done===1'b1 ? ENDING_PU : MERGE_IDX;
    MERGE_FLAG:                nxt_state = dec_done===1'b1 ? ((merge_flag && maxNumMergeCand>1)===1'b1 ? MERGE_IDX : JUDGE_INTER_PRED_IDC) : MERGE_FLAG;
    JUDGE_INTER_PRED_IDC:      nxt_state = (slice_type == SLICE_TYPE_B)===1'b1 ? INTER_PRED_IDC : REF_IDX_L0;
    INTER_PRED_IDC:            nxt_state = dec_done===1'b1 ? ((inter_pred_idc == PU_INTER_PRED_IDC_L1)===1'b1 ? REF_IDX_L1 : REF_IDX_L0) : INTER_PRED_IDC;
    REF_IDX_L0:                nxt_state = dec_done===1'b1 ? MVD_CODING_0 : REF_IDX_L0;
    MVD_CODING_0:              nxt_state = mvd_done_intr===1'b1 ? MVP_L0_FLAG : MVD_CODING_0;
    MVP_L0_FLAG:               nxt_state = dec_done===1'b1 ? ((inter_pred_idc == PU_INTER_PRED_IDC_L0)===1'b1 ? ENDING_PU : REF_IDX_L1) : MVP_L0_FLAG;
    REF_IDX_L1:                nxt_state = dec_done===1'b1 ? MVD_CODING_1 : REF_IDX_L1;
    MVD_CODING_1:              nxt_state = mvd_done_intr===1'b1 ? MVP_L1_FLAG : MVD_CODING_1;
    MVP_L1_FLAG:               nxt_state = dec_done===1'b1 ? ENDING_PU : MVP_L1_FLAG;
    ENDING_PU:                 nxt_state = IDLE_PU;
    default:                   nxt_state = IDLE_PU;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_PU;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) pu_done_intr <= (state == ENDING_PU) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_PU || dec_done) ? 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[6:0], ruiBin} : ruiBin_delay; // store the decoded bins
always_ff @(posedge clk)
    case(state)
    MERGE_IDX:      target_bin <= dec_done ? 1 : (ruiBin_vld ? (ruiBin ? target_bin + 1 : 1) : target_bin);
    INTER_PRED_IDC: target_bin <= dec_done ? 1 : (ruiBin_vld ? (ruiBin ? 1: 2) : target_bin);
    REF_IDX_L0:     target_bin <= dec_done ? 1 : (ruiBin_vld ? (ruiBin ? target_bin + 1 : 1) : target_bin);
    REF_IDX_L1:     target_bin <= dec_done ? 1 : (ruiBin_vld ? (ruiBin ? target_bin + 1 : 1) : target_bin);
    default:        target_bin <= 1;
    endcase

always_ff @(posedge clk)
    case(state)
    IDLE_PU:                   dec_done <= 0;
    MERGE_IDX:                 dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MERGE_FLAG:                dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    INTER_PRED_IDC:            dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    REF_IDX_L0:                dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MVP_L0_FLAG:               dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    REF_IDX_L1:                dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    MVP_L1_FLAG:               dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    default:                   dec_done <= 0;
    endcase

always_ff @(posedge clk) merge_idx <= (state == MERGE_IDX && ruiBin_vld && !ruiBin) ? counter_coded_bin : merge_idx;
always_ff @(posedge clk) merge_flag <= (state == MERGE_FLAG && ruiBin_vld) ? ruiBin : merge_flag;
always_ff @(posedge clk) inter_pred_idc <= (state == INTER_PRED_IDC && dec_done) ? (target_bin == 2 ? (ruiBin_delay[0] ? PU_INTER_PRED_IDC_L1 : PU_INTER_PRED_IDC_L0) : 
                                                                                                      PU_INTER_PRED_IDC_BI) : 
                                                                                   inter_pred_idc;
always_ff @(posedge clk) ref_idx_l0 <= (state == REF_IDX_L0 && ruiBin_vld && !ruiBin) ? counter_coded_bin : ref_idx_l0;
always_ff @(posedge clk) mvp_l0_flag <= (state == MVP_L0_FLAG && ruiBin_vld) ? ruiBin : mvp_l0_flag;
always_ff @(posedge clk) ref_idx_l1 <= (state == REF_IDX_L1 && ruiBin_vld && !ruiBin) ? counter_coded_bin : ref_idx_l1;
always_ff @(posedge clk) mvp_l1_flag <= (state == MVP_L1_FLAG && ruiBin_vld) ? ruiBin : mvp_l1_flag;

logic       state_mvd_coding_d, state_mvd_coding_start;
always_ff @(posedge clk) state_mvd_coding_d <= (state == MVD_CODING_0 || state == MVD_CODING_1) ? 1'b1 : 1'b0;
always_ff @(posedge clk) state_mvd_coding_start <= ({state_mvd_coding_d, (state == MVD_CODING_0 || state == MVD_CODING_1) ? 1'b1 : 1'b0} == 2'b01) ? 1 : 0;
assign mvd_start = state_mvd_coding_start;

// Other output signal control
logic [2:0] ctx_pu_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
always_ff @(posedge clk)
    if(state == IDLE_PU) ctx_pu_addr_vld_count <= 0;
    else if(dec_done) ctx_pu_addr_vld_count <= 0;
    else if(ctx_pu_addr_vld) ctx_pu_addr_vld_count <= ctx_pu_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_PU) dec_phase <= 0;
    else if(ctx_pu_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;

always_ff @(posedge clk)
    case(state)
    MERGE_IDX:                 ctx_pu_addr <= CTXIDX_MERGE_IDX[0];
    MERGE_FLAG:                ctx_pu_addr <= CTXIDX_MERGE_FLAG[0];
    INTER_PRED_IDC:            ctx_pu_addr <= (ctx_pu_addr_vld_count == 0) ? ((nPbH + nPbW) == 6'd10 ? CTXIDX_INTER_PRED_IDC[4] : CTXIDX_INTER_PRED_IDC[split_depth]) : CTXIDX_INTER_PRED_IDC[4];
    REF_IDX_L0:                ctx_pu_addr <= (ctx_pu_addr_vld_count == 0) ? CTXIDX_REF_IDX_L0[0] : CTXIDX_REF_IDX_L0[1];
    MVD_CODING_0:              ctx_pu_addr <= ctx_mvd_addr;
    MVP_L0_FLAG:               ctx_pu_addr <= CTXIDX_MVP_L0_FLAG[0];
    REF_IDX_L1:                ctx_pu_addr <= (ctx_pu_addr_vld_count == 0) ? CTXIDX_REF_IDX_L0[0] : CTXIDX_REF_IDX_L0[1];
    MVD_CODING_1:              ctx_pu_addr <= ctx_mvd_addr;
    MVP_L1_FLAG:               ctx_pu_addr <= CTXIDX_MVP_L1_FLAG[0];
    endcase
always_ff @(posedge clk)
    case(state)
    IDLE_PU:                   ctx_pu_addr_vld <= 0;
    MERGE_IDX:                 ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == target_bin) ? 0 : ((dec_phase==0 || ctx_pu_addr_vld_count>0) ? 1 : 0);
    MERGE_FLAG:                ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    INTER_PRED_IDC:            ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == target_bin) ? 0 : (dec_phase==0 ? 1 : 0);
    REF_IDX_L0:                ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == target_bin) ? 0 : ((dec_phase==0 || ctx_pu_addr_vld_count>1) ? 1 : 0);
    MVD_CODING_0:              ctx_pu_addr_vld <= ctx_mvd_addr_vld;
    MVP_L0_FLAG:               ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    REF_IDX_L1:                ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == target_bin) ? 0 : ((dec_phase==0 || ctx_pu_addr_vld_count>1) ? 1 : 0);
    MVD_CODING_1:              ctx_pu_addr_vld <= ctx_mvd_addr_vld;
    MVP_L1_FLAG:               ctx_pu_addr_vld <= (ctx_pu_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    default:                   ctx_pu_addr_vld <= 0;
    endcase
always_ff @(posedge clk) dec_run_pu <= (state == MVD_CODING_0 || state == MVD_CODING_1) ? dec_run_mvd : ctx_pu_addr_vld;
always_ff @(posedge clk)
    case(state)
    IDLE_PU:                   EPMode_pu <= 0;
    MERGE_IDX:                 EPMode_pu <= (counter_coded_bin == 0) ? 0 : 1;
    MERGE_FLAG:                EPMode_pu <= 0;
    INTER_PRED_IDC:            EPMode_pu <= 0;
    REF_IDX_L0:                EPMode_pu <= (counter_coded_bin <= 2) ? 0 : 1;
    MVD_CODING_0:              EPMode_pu <= EPMode_mvd;
    MVP_L0_FLAG:               EPMode_pu <= 0;
    REF_IDX_L1:                EPMode_pu <= (counter_coded_bin <= 2) ? 0 : 1;
    MVD_CODING_1:              EPMode_pu <= EPMode_mvd;
    MVP_L1_FLAG:               EPMode_pu <= 0;
    ENDING_PU:                 EPMode_pu <= 0;
    default:                   EPMode_pu <= 0;
    endcase

// Sub FSMs
qdec_mvd_fsm mvd_fsm(
    .clk,
    .rst_n,

    .mvd_start,
    .slice_type,
    .cabac_init_flag,

    .ctx_mvd_addr,
    .ctx_mvd_addr_vld,
    .dec_run_mvd,
    .dec_rdy,
    .EPMode_mvd,
    .ruiBin,
    .ruiBin_vld,
    .mvd_done_intr
);

endmodule
