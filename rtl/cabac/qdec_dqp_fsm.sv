// 
// Author : Qi Wang
// The sub-FSM to handle Delta QP part decoding
module qdec_dqp_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       dqp_start,
    input  logic       cu_qp_delta_enabled_flag,
    input  logic [1:0] slice_type,
    input  logic       cabac_init_flag,

    output logic [9:0] ctx_dqp_addr,
    output logic       ctx_dqp_addr_vld,
    output logic       dec_run_dqp,
    input  logic       dec_rdy,
    output logic       EPMode_dqp,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       dqp_done_intr
);

logic       dec_done;
logic [7:0] counter_coded_bin;
logic [15:0]ruiBin_delay;
logic [2:0] ctx_dqp_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
logic [2:0] target_bin;
logic [7:0] cu_qp_delta_abs;
logic       cu_qp_delta_sign;

t_state_dqp state, nxt_state;

always_comb
    case(state)
    IDLE_DQP:                  nxt_state = dqp_start ? (cu_qp_delta_enabled_flag ? CU_QP_DELTA_ABS : ENDING_DQP) : IDLE_DQP;
    CU_QP_DELTA_ABS:           nxt_state = dec_done ? (cu_qp_delta_abs > 0 ? CU_QP_DELTA_SIGN_FLAG : ENDING_DQP) : CU_QP_DELTA_ABS;
    CU_QP_DELTA_SIGN_FLAG:     nxt_state = dec_done ? ENDING_DQP : CU_QP_DELTA_SIGN_FLAG;
    ENDING_DQP:                nxt_state = IDLE_DQP;
    default:                   nxt_state = IDLE_DQP;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_DQP;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) dqp_done_intr <= (state == ENDING_DQP) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_CU || dec_done) ? 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[6:0], ruiBin} : ruiBin_delay; // store the decoded bins

always_ff @(posedge clk) cu_skip_flag <= (state == CU_SKIP_FLAG && ruiBin_vld) ? ruiBin : cu_skip_flag;
always_ff @(posedge clk) pred_mode_flag <= (log2CUSize == minCbLog2CUSize) ? 0 : ((state == PRED_MODE_FLAG && ruiBin_vld) ? ruiBin : pred_mode_flag);

logic [7:0] first_zero_counter_ExG;
logic       first_zero_flag_ExG;
always_ff @(posedge clk) 
    if(state == IDLE_DQP) first_zero_counter_ExG <= 0;
    else if(state == CU_QP_DELTA_ABS && ruiBin_vld && !ruiBin) first_zero_counter_ExG <= counter_coded_bin - 5;
always_ff @(posedge clk) 
    if(state == IDLE_DQP) cu_qp_delta_abs <= 0;
    else if(state == CU_QP_DELTA_ABS & counter_coded_bin <= 5 & ruiBin_vld) cu_qp_delta_abs <= cu_qp_delta_abs + ruiBin;
    else if(state == CU_QP_DELTA_ABS & dec_done) // support ExG for 10 bits max
        case(first_zero_counter_ExG)
        8'd0: cu_qp_delta_abs <= 8'd5;
        8'd1: cu_qp_delta_abs <= 8'd5 + ruiBin_delay[0:0] + ruiBin_delay[2:1];
        8'd2: cu_qp_delta_abs <= 8'd5 + ruiBin_delay[1:0] + ruiBin_delay[4:2];
        8'd3: cu_qp_delta_abs <= 8'd5 + ruiBin_delay[2:0] + ruiBin_delay[6:3];
        8'd4: cu_qp_delta_abs <= 8'd5 + ruiBin_delay[3:0] + ruiBin_delay[8:4];
        8'd5: cu_qp_delta_abs <= 8'd5 + ruiBin_delay[4:0] + ruiBin_delay[10:5];
        default: cu_qp_delta_abs <= 8'd5;
        endcase
always_ff @(posedge clk)
    if(state == IDLE_DQP) cu_qp_delta_sign <= 0;
    else if(state == CU_QP_DELTA_SIGN_FLAG & dec_done) cu_qp_delta_sign <= ruiBin_delay[0];

always_ff @(posedge clk) 
    if(state == IDLE_DQP) first_zero_flag_ExG <= 0;
    else if(state == CU_QP_DELTA_ABS && ruiBin_vld && !ruiBin) first_zero_flag_ExG <= 1;
always_ff @(posedge clk)
    if(state == IDLE_DQP) target_bin <= 1;
    else if(state == CU_QP_DELTA_ABS) 
        target_bin <= (!first_zero_flag_ExG) ? target_bin + 1 : 4 + (first_zero_counter_ExG << 1);
    else target_bin <= 1;

always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   dec_done <= 0;
    CU_QP_DELTA_ABS:           dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;
    CU_QP_DELTA_SIGN_FLAG:     dec_done <= (counter_coded_bin == 1) ? 1 : 0;
    default: dec_done <= 0;
    endcase

// Other output signal control
always_ff @(posedge clk)
    case(state)
    CU_QP_DELTA_ABS:       ctx_dqp_addr <= (counter_coded_bin == 0) ? CTXIDX_CU_QP_DELTA_ABS[0] : CTXIDX_CU_QP_DELTA_ABS[1];
    endcase


always_ff @(posedge clk)
    if(state == IDLE_DQP) ctx_dqp_addr_vld_count <= 0;
    else if(dec_done) ctx_dqp_addr_vld_count <= 0;
    else if(ctx_dqp_addr_vld) ctx_dqp_addr_vld_count <= ctx_dqp_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_DQP) dec_phase <= 0;
    else if(ctx_dqp_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;
always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   ctx_dqp_addr_vld <= 0;
    CU_QP_DELTA_ABS:           ctx_dqp_addr_vld <= (ctx_dqp_addr_vld_count == target_bin) ? 0 : ((dec_phase==0 || ctx_dqp_addr_vld_count>5) ? 1 : 0);
    CU_QP_DELTA_SIGN_FLAG:     ctx_dqp_addr_vld <= (ctx_dqp_addr_vld_count == 1) ? 0 : 1;
    default:                   ctx_dqp_addr_vld <= 0;
    endcase

always_ff @(posedge clk)
    dec_run_dqp <= ctx_dqp_addr_vld;

always_ff @(posedge clk)
    case(state)
    IDLE_CU:                   EPMode_dqp <= 0;             
    CU_QP_DELTA_ABS:           EPMode_dqp <= (counter_coded_bin > 5) ? 1 : 0;
    CU_QP_DELTA_SIGN_FLAG:     EPMode_dqp <= 1;
    default :                  EPMode_dqp <= 0;
    endcase

// Sub FSMs

endmodule
