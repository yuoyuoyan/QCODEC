// 
// Author : Qi Wang
// The sub-FSM to handle Chroma QP offset part decoding
module qdec_cqp_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       cqp_start,
    input  logic [1:0] slice_type,
    input  logic       cabac_init_flag,
    input  logic       cu_chroma_qp_offset_enabled_flag,
    input  logic [2:0] chroma_qp_offset_list_len,

    output logic [9:0] ctx_cqp_addr,
    output logic       ctx_cqp_addr_vld,
    output logic       dec_run_cqp,
    input  logic       dec_rdy,
    output logic       EPMode_cqp,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       cqp_done_intr
);

logic       dec_done;
logic [7:0] counter_coded_bin;
logic [7:0] ruiBin_delay;
logic [2:0] ctx_cqp_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
logic [2:0] target_bin;
logic       cu_chroma_qpoffset_flag;
logic [2:0] cu_chroma_qp_offset_idx;

t_state_cqp state, nxt_state;

always_comb
    case(state)
    IDLE_CQP:                  nxt_state = cqp_start===1'b1 ? (cu_chroma_qp_offset_enabled_flag===1'b1 ? CU_CHROMA_QP_OFFSET_FLAG : ENDING_CQP) : IDLE_CQP;
    CU_CHROMA_QP_OFFSET_FLAG:  nxt_state = dec_done===1'b1 ? ((cu_chroma_qpoffset_flag && chroma_qp_offset_list_len > 0)===1'b1 ? CU_CHROMA_QP_OFFSET_IDX : ENDING_CQP) : CU_CHROMA_QP_OFFSET_FLAG;
    CU_CHROMA_QP_OFFSET_IDX:   nxt_state = dec_done===1'b1 ? ENDING_CQP : CU_CHROMA_QP_OFFSET_IDX;
    ENDING_CQP:                nxt_state = IDLE_CQP;
    default:                   nxt_state = IDLE_CQP;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_CQP;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) cqp_done_intr <= (state == ENDING_CQP) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_CU || dec_done) ? 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[6:0], ruiBin} : ruiBin_delay; // store the decoded bins

always_ff @(posedge clk) 
    if(state == CU_CHROMA_QP_OFFSET_FLAG && dec_done) cu_chroma_qpoffset_flag <= ruiBin_delay[0];
always_ff @(posedge clk)
    if(state == IDLE_CQP) cu_chroma_qp_offset_idx <= 0;
    else if(state == CU_CHROMA_QP_OFFSET_IDX && ruiBin_vld && ruiBin) cu_chroma_qp_offset_idx <= cu_chroma_qp_offset_idx + 1;

always_ff @(posedge clk)
    if(state == CU_CHROMA_QP_OFFSET_IDX)
        target_bin <= (counter_coded_bin < 5 & ruiBin_vld & ruiBin) ? target_bin + 1 : target_bin;
    else target_bin <= 1;

always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   dec_done <= 0;
    CU_CHROMA_QP_OFFSET_FLAG:  dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    CU_CHROMA_QP_OFFSET_IDX:   dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    default: dec_done <= 0;
    endcase

// Other output signal control
always_ff @(posedge clk)
    case(state)
    CU_CHROMA_QP_OFFSET_FLAG:  ctx_cqp_addr <= CTXIDX_CHROMA_QP_OFFSET_FLAG[0];
    CU_CHROMA_QP_OFFSET_IDX:   ctx_cqp_addr <= CTXIDX_CHROMA_QP_OFFSET_IDX[0];
    endcase

always_ff @(posedge clk)
    if(state == IDLE_CQP) ctx_cqp_addr_vld_count <= 0;
    else if(dec_done) ctx_cqp_addr_vld_count <= 0;
    else if(ctx_cqp_addr_vld) ctx_cqp_addr_vld_count <= ctx_cqp_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_CQP) dec_phase <= 0;
    else if(ctx_cqp_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;
always_ff @(posedge clk)
    case(state)
    IDLE_CQP:                  ctx_cqp_addr_vld <= 0;
    CU_CHROMA_QP_OFFSET_FLAG:  ctx_cqp_addr_vld <= (ctx_cqp_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    CU_CHROMA_QP_OFFSET_IDX:   ctx_cqp_addr_vld <= (ctx_cqp_addr_vld_count == target_bin) ? 0 : (dec_phase==0 ? 1 : 0);
    default:                   ctx_cqp_addr_vld <= 0;
    endcase

always_ff @(posedge clk)
    dec_run_cqp <= ctx_cqp_addr_vld;

always_ff @(posedge clk) EPMode_cqp <= 0;

// Sub FSMs

endmodule
