// 
// Author : Qi Wang
// The sub-FSM to handle CU part decoding
module qdec_trafo_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       trafo_start,
    input  logic [9:0] xCU,
    input  logic [8:0] yCU,
    input  logic       pred_mode,
    input  logic [2:0] log2TrafoSize,
    input  logic [2:0] maxTbLog2SizeY,
    input  logic [2:0] minTbLog2SizeY,
    input  logic [2:0] maxTrafoDepth,
    input  logic       intra_split_flag,
    input  logic [1:0] slice_type,
    input  logic       cabac_init_flag,

    output logic [9:0] ctx_trafo_addr,
    output logic       ctx_trafo_addr_vld,
    output logic       dec_run_trafo,
    input  logic       dec_rdy,
    output logic       EPMode_trafo,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       trafo_done_intr
);

logic       dec_done;
logic [2:0] ctx_trafo_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
logic [7:0] counter_coded_bin;
logic [7:0] ruiBin_delay;
// Max input size is 64x64, min is 4x4
// Must split if 64x64, and intra_split_flag will be on
logic [2:0] curr_depth, curr_log2Size;
logic       split_transform_flag_d0;
logic [3:0] split_transform_flag_d1;
logic [15:0]split_transform_flag_d2;
logic [63:0]split_transform_flag_d3;
logic       curr_split_transform_flag;
logic [1:0] counter_d1;
logic [3:0] counter_d2;
logic [5:0] counter_d3;
logic [7:0] counter_d4;
logic [7:0] curr_counter;
logic       cbf_cb_d0, cbf_cr_d0, cbf_luma_d0;
logic [3:0] cbf_cb_d1, cbf_cr_d1, cbf_luma_d1;
logic [15:0]cbf_cb_d2, cbf_cr_d2, cbf_luma_d2;
logic [63:0]cbf_cb_d3, cbf_cr_d3, cbf_luma_d3;
logic [255:0]cbf_luma_d4;
logic       parent_cbf_cb, parent_cbf_cr; // set to 1 if curr depth is 0
logic       curr_cbf_cb, curr_cbf_cr, curr_cbf_luma;
logic       end_of_cu;
logic       tu_start;
logic [9:0] ctx_tu_addr;
logic       ctx_tu_addr_vld;
logic       dec_run_tu;
logic       EPMode_tu;
logic       tu_done_intr;

t_state_trafo state, nxt_state;

always_comb
    case(state)
    IDLE_TRAFO:                nxt_state = trafo_start===1'b1 ? JUDGE_SPLIT_TRAFO : IDLE_TRAFO;
    JUDGE_SPLIT_TRAFO:         nxt_state = (curr_log2Size <= maxTbLog2SizeY && curr_log2Size > minTbLog2SizeY && curr_depth < maxTrafoDepth && !(intra_split_flag && (curr_depth == 0)))===1'b1 ?
                                           SPLIT_TRANSFORM_FLAG : JUDGE_CBF_CHROMA;
    SPLIT_TRANSFORM_FLAG:      nxt_state = dec_done===1'b1 ? JUDGE_CBF_CHROMA : SPLIT_TRANSFORM_FLAG;
    JUDGE_CBF_CHROMA:          nxt_state = (curr_log2Size > 2)===1'b1 ? (parent_cbf_cb===1'b1 ? CBF_CB : (parent_cbf_cr===1'b1 ? CBF_CR : JUDGE_TU)) : JUDGE_TU;
    CBF_CB:                    nxt_state = dec_done===1'b1 ? (parent_cbf_cr===1'b1 ? CBF_CR : JUDGE_TU) : CBF_CB;
    CBF_CR:                    nxt_state = dec_done===1'b1 ? JUDGE_TU : CBF_CR;
    JUDGE_TU:                  nxt_state = curr_split_transform_flag===1'b1 ? ITERATION_TRAFO : JUDGE_CBF_LUMA;
    ITERATION_TRAFO:           nxt_state = JUDGE_SPLIT_TRAFO;
    JUDGE_CBF_LUMA:            nxt_state = (pred_mode == PRED_MODE_FLAG_INTRA || curr_depth != 0 || curr_cbf_cb || curr_cbf_cr)===1'b1 ? CBF_LUMA : TU_CODING;
    CBF_LUMA:                  nxt_state = dec_done===1'b1 ? TU_CODING : CBF_LUMA;
    TU_CODING:                 nxt_state = tu_done_intr===1'b1 ? (end_of_cu===1'b1 ? ENDING_TRAFO : ITERATION_TRAFO) : TU_CODING;
    ENDING_TRAFO:              nxt_state = IDLE_TRAFO;
    default:                   nxt_state = IDLE_TRAFO;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_TRAFO;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) trafo_done_intr <= (state == ENDING_TRAFO) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_TRAFO || dec_done) ? 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[6:0], ruiBin} : ruiBin_delay; // store the decoded bins

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) curr_depth <= 0;
    else if(state == ITERATION_TRAFO && curr_split_transform_flag)  curr_depth <= curr_depth + 1;
    else if(state == ITERATION_TRAFO && curr_counter[1:0] == 2'b11) curr_depth <= curr_depth - 1;

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) curr_log2Size <= log2TrafoSize;
    else if(state == ITERATION_TRAFO && curr_split_transform_flag)  curr_log2Size <= curr_log2Size - 1;
    else if(state == ITERATION_TRAFO && curr_counter[1:0] == 2'b11) curr_log2Size <= curr_log2Size + 1;

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) split_transform_flag_d0 <= 0;
    else if(state == SPLIT_TRANSFORM_FLAG && curr_log2Size != 6 && dec_done) split_transform_flag_d0 <= ruiBin_delay[0];
    else if(curr_log2Size == 6) split_transform_flag_d0 <= 1;
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) split_transform_flag_d1 <= 0;
    else if(state == SPLIT_TRANSFORM_FLAG && curr_depth == 1 && dec_done) split_transform_flag_d1[counter_d1] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) split_transform_flag_d2 <= 0;
    else if(state == SPLIT_TRANSFORM_FLAG && curr_depth == 2 && dec_done) split_transform_flag_d2[counter_d2] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) split_transform_flag_d3 <= 0;
    else if(state == SPLIT_TRANSFORM_FLAG && curr_depth == 3 && dec_done) split_transform_flag_d3[counter_d3] <= ruiBin_delay[0];
always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    curr_split_transform_flag <= split_transform_flag_d0;
    3'd1:    curr_split_transform_flag <= split_transform_flag_d1[counter_d1];
    3'd2:    curr_split_transform_flag <= split_transform_flag_d2[counter_d2];
    3'd3:    curr_split_transform_flag <= split_transform_flag_d3[counter_d3];
    default: curr_split_transform_flag <= 0;
    endcase
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) counter_d1 <= 0;
    else if(state == ITERATION_TRAFO && curr_depth == 1) counter_d1 <= counter_d1 + 1;
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) counter_d2 <= 0;
    else if(state == ITERATION_TRAFO && curr_depth == 2) counter_d2 <= counter_d2 + 1;
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) counter_d3 <= 0;
    else if(state == ITERATION_TRAFO && curr_depth == 3) counter_d3 <= counter_d3 + 1;
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) counter_d4 <= 0;
    else if(state == ITERATION_TRAFO && curr_depth == 4) counter_d4 <= counter_d4 + 1;
always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    curr_counter <= 0;
    3'd1:    curr_counter <= counter_d1;
    3'd2:    curr_counter <= counter_d2;
    3'd3:    curr_counter <= counter_d3;
    3'd4:    curr_counter <= counter_d4;
    default: curr_counter <= 0;
    endcase

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cb_d0 <= 0;
    else if(state == CBF_CB && curr_depth == 0 && dec_done) cbf_cb_d0 <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cb_d1 <= 0;
    else if(state == CBF_CB && curr_depth == 1 && dec_done) cbf_cb_d1[counter_d1] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cb_d2 <= 0;
    else if(state == CBF_CB && curr_depth == 2 && dec_done) cbf_cb_d2[counter_d2] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cb_d3 <= 0;
    else if(state == CBF_CB && curr_depth == 3 && dec_done) cbf_cb_d3[counter_d3] <= ruiBin_delay[0];

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cr_d0 <= 0;
    else if(state == CBF_CR && curr_depth == 0 && dec_done) cbf_cr_d0 <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cr_d1 <= 0;
    else if(state == CBF_CR && curr_depth == 1 && dec_done) cbf_cr_d1[counter_d1] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cr_d2 <= 0;
    else if(state == CBF_CR && curr_depth == 2 && dec_done) cbf_cr_d2[counter_d2] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_cr_d3 <= 0;
    else if(state == CBF_CR && curr_depth == 3 && dec_done) cbf_cr_d3[counter_d3] <= ruiBin_delay[0];

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_luma_d0 <= 0;
    else if(state == CBF_LUMA && curr_depth == 0 && dec_done) cbf_luma_d0 <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_luma_d1 <= 0;
    else if(state == CBF_LUMA && curr_depth == 1 && dec_done) cbf_luma_d1[counter_d1] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_luma_d2 <= 0;
    else if(state == CBF_LUMA && curr_depth == 2 && dec_done) cbf_luma_d2[counter_d2] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_luma_d3 <= 0;
    else if(state == CBF_LUMA && curr_depth == 3 && dec_done) cbf_luma_d3[counter_d3] <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) cbf_luma_d4 <= 0;
    else if(state == CBF_LUMA && curr_depth == 4 && dec_done) cbf_luma_d4[counter_d4] <= ruiBin_delay[0];

always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    parent_cbf_cb <= 1;
    3'd1:    parent_cbf_cb <= cbf_cb_d0;
    3'd2:    parent_cbf_cb <= cbf_cb_d1[counter_d2[3:2]];
    3'd3:    parent_cbf_cb <= cbf_cb_d2[counter_d3[5:4]];
    3'd4:    parent_cbf_cb <= cbf_cb_d3[counter_d4[7:6]];
    default: parent_cbf_cb <= 1;
    endcase
always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    parent_cbf_cr <= 1;
    3'd1:    parent_cbf_cr <= cbf_cr_d0;
    3'd2:    parent_cbf_cr <= cbf_cr_d1[counter_d2[3:2]];
    3'd3:    parent_cbf_cr <= cbf_cr_d2[counter_d3[5:4]];
    3'd4:    parent_cbf_cr <= cbf_cr_d3[counter_d4[7:6]];
    default: parent_cbf_cr <= 1;
    endcase
always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    curr_cbf_cb <= cbf_cb_d0;
    3'd1:    curr_cbf_cb <= cbf_cb_d1[counter_d1];
    3'd2:    curr_cbf_cb <= cbf_cb_d2[counter_d2];
    3'd3:    curr_cbf_cb <= cbf_cb_d3[counter_d3];
    default: curr_cbf_cb <= 1;
    endcase
always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    curr_cbf_cr <= cbf_cr_d0;
    3'd1:    curr_cbf_cr <= cbf_cr_d1[counter_d1];
    3'd2:    curr_cbf_cr <= cbf_cr_d2[counter_d2];
    3'd3:    curr_cbf_cr <= cbf_cr_d3[counter_d3];
    default: curr_cbf_cr <= 1;
    endcase
always_ff @(posedge clk)
    case(curr_depth)
    3'd0:    curr_cbf_luma <= cbf_luma_d0;
    3'd1:    curr_cbf_luma <= cbf_luma_d1[counter_d1];
    3'd2:    curr_cbf_luma <= cbf_luma_d2[counter_d2];
    3'd3:    curr_cbf_luma <= cbf_luma_d3[counter_d3];
    3'd4:    curr_cbf_luma <= cbf_luma_d4[counter_d4];
    default: curr_cbf_luma <= 1;
    endcase

always_ff @(posedge clk)
    if(state == IDLE_TRAFO) end_of_cu <= 0;
    else
        case(curr_depth)
        3'd0:    end_of_cu <= 1;
        3'd1:    end_of_cu <= counter_d1 == 2'h3 ? 1 : 0;
        3'd2:    end_of_cu <= counter_d2 == 4'hf ? 1 : 0;
        3'd3:    end_of_cu <= counter_d3 == 6'h3f ? 1 : 0;
        3'd4:    end_of_cu <= counter_d4 == 8'hff ? 1 : 0;
        default: end_of_cu <= 0;
        endcase

always_ff @(posedge clk)
    case(state)
    IDLE_TRAFO:                dec_done <= 0;
    SPLIT_TRANSFORM_FLAG:      dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    CBF_CB:                    dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    CBF_CR:                    dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    CBF_LUMA:                  dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    default:                   dec_done <= 0;
    endcase

logic state_tu_coding_d;
always_ff @(posedge clk) state_tu_coding_d <= (state == TU_CODING) ? 1 : 0;
assign tu_start = ({state_tu_coding_d, (state == TU_CODING) ? 1'b1 : 1'b0} == 2'b01) ? 1 : 0;

// Other output signal control
always_ff @(posedge clk)
    case(state)
    SPLIT_TRANSFORM_FLAG:      ctx_trafo_addr <= CTXIDX_SPLIT_TRANSFORM_FLAG[3'd5-curr_log2Size];
    CBF_CB:                    ctx_trafo_addr <= CTXIDX_CBF_CB[curr_depth];
    CBF_CR:                    ctx_trafo_addr <= CTXIDX_CBF_CR[curr_depth];
    CBF_LUMA:                  ctx_trafo_addr <= CTXIDX_CBF_LUMA[(curr_depth == 0 ? 1 : 0)];
    endcase


always_ff @(posedge clk)
    if(state == IDLE_TRAFO) ctx_trafo_addr_vld_count <= 0;
    else if(dec_done) ctx_trafo_addr_vld_count <= 0;
    else if(ctx_trafo_addr_vld) ctx_trafo_addr_vld_count <= ctx_trafo_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_TRAFO) dec_phase <= 0;
    else if(ctx_trafo_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;
always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   ctx_trafo_addr_vld <= 0;
    SPLIT_TRANSFORM_FLAG:      ctx_trafo_addr_vld <= (ctx_trafo_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    CBF_CB:                    ctx_trafo_addr_vld <= (ctx_trafo_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    CBF_CR:                    ctx_trafo_addr_vld <= (ctx_trafo_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    CBF_LUMA:                  ctx_trafo_addr_vld <= (ctx_trafo_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    default:                   ctx_trafo_addr_vld <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    TU_CODING: dec_run_trafo <= dec_run_tu;
    default:   dec_run_trafo <= ctx_trafo_addr_vld;
    endcase

always_ff @(posedge clk) EPMode_trafo <= 0;

// Sub FSMs
qdec_tu_fsm tu_fsm(
    .clk,
    .rst_n,

    .tu_start,
    .slice_type,
    .cabac_init_flag,

    .ctx_tu_addr,
    .ctx_tu_addr_vld,
    .dec_run_tu,
    .dec_rdy,
    .EPMode_tu,
    .ruiBin,
    .ruiBin_vld,
    .tu_done_intr
);

/*
module qdec_tu_fsm import qdec_cabac_package::*; (
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
    input  logic       amp_enabled_flag,
    input  logic       transform_skip_enabled_flag,
    input  logic       sign_data_hiding_enabled_flag,
    input  logic [2:0] Log2MaxTransformSkipSize,
    input  logic       intraPredVertical,
    input  logic       intraPredHorizontal,
    input  logic       cu_qp_delta_enabled_flag,
    input  logic       cu_chroma_qp_offset_enabled_flag,
    input  logic [2:0] chroma_qp_offset_list_len,

    output logic [9:0] ctx_tu_addr,
    output logic       ctx_tu_addr_vld,
    output logic       dec_run_tu,
    input  logic       dec_rdy,
    output logic       EPMode_tu,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       tu_done_intr
);
*/

endmodule
