// 
// Author : Qi Wang
// The sub-FSM to handle MVD part decoding
module qdec_mvd_fsm import qdec_cabac_package::*;(
    input clk,
    input rst_n,

    input  logic       mvd_start,
    input  logic [1:0] slice_type,
    input  logic       cabac_init_flag,

    output logic [9:0] ctx_mvd_addr,
    output logic       ctx_mvd_addr_vld,
    output logic       dec_run_mvd,
    input  logic       dec_rdy,
    output logic       EPMode_mvd,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       mvd_done_intr
);

logic       dec_done;
logic [7:0] counter_coded_bin;
logic [31:0]ruiBin_delay;
logic [7:0] target_bin;
logic       abs_mvd_greater0_flag0, abs_mvd_greater0_flag1;
logic       abs_mvd_greater1_flag0, abs_mvd_greater1_flag1;
logic [15:0]abs_mvd_minus2_0, abs_mvd_minus2_1;
logic       mvd_sign_flag0, mvd_sign_flag1;

t_state_mvd state, nxt_state;

always_comb
    case(state)
    IDLE_MVD:                  nxt_state = mvd_start ? ABS_MVD_GREATER0_FLAG0 : IDLE_MVD;
    ABS_MVD_GREATER0_FLAG0:    nxt_state = dec_done ? ABS_MVD_GREATER0_FLAG1 : ABS_MVD_GREATER0_FLAG0;
    ABS_MVD_GREATER0_FLAG1:    nxt_state = dec_done ? (abs_mvd_greater0_flag0 ? ABS_MVD_GREATER1_FLAG0 : 
                                                      (abs_mvd_greater0_flag1 ? ABS_MVD_GREATER1_FLAG1 : ENDING_MVD)) :
                                                      ABS_MVD_GREATER0_FLAG1;
    ABS_MVD_GREATER1_FLAG0:    nxt_state = dec_done ? (abs_mvd_greater0_flag1 ? ABS_MVD_GREATER1_FLAG1 : JUDGE_MVD_MINUS2_0) : ABS_MVD_GREATER1_FLAG0;
    ABS_MVD_GREATER1_FLAG1:    nxt_state = dec_done ? JUDGE_MVD_MINUS2_0 : ABS_MVD_GREATER1_FLAG1;
    JUDGE_MVD_MINUS2_0:        nxt_state = abs_mvd_greater0_flag0 ? (abs_mvd_greater1_flag0 ? ABS_MVD_MINUS2_0 : MVD_SIGN_FLAG0) : JUDGE_MVD_MINUS2_1;
    ABS_MVD_MINUS2_0:          nxt_state = dec_done ? MVD_SIGN_FLAG0 : ABS_MVD_MINUS2_0;
    MVD_SIGN_FLAG0:            nxt_state = dec_done ? JUDGE_MVD_MINUS2_1 : MVD_SIGN_FLAG0;
    JUDGE_MVD_MINUS2_1:        nxt_state = abs_mvd_greater0_flag1 ? (abs_mvd_greater1_flag1 ? ABS_MVD_MINUS2_1 : MVD_SIGN_FLAG1) : ENDING_MVD;
    ABS_MVD_MINUS2_1:          nxt_state = dec_done ? MVD_SIGN_FLAG1 : ABS_MVD_MINUS2_1;
    MVD_SIGN_FLAG1:            nxt_state = dec_done ? ENDING_MVD : MVD_SIGN_FLAG1;
    ENDING_MVD:                nxt_state = IDLE_MVD;
    default:                   nxt_state = IDLE_MVD;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_CU;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) mvd_done_intr <= (state == ENDING_MVD) ? 1 : 0;

// Main FSM control signals
logic first_zero_in_bins, first_zero_in_bins_d;
always_ff @(posedge clk) first_zero_in_bins <= dec_done ? 0 : (ruiBin_vld & !ruiBin & (state == ABS_MVD_MINUS2_0 || state == ABS_MVD_MINUS2_1) ? 1 : first_zero_in_bins);
always_ff @(posedge clk) first_zero_in_bins_d <= first_zero_in_bins;
always_ff @(posedge clk) counter_coded_bin <= (state == IDLE_MVD || dec_done) 0 : (ruiBin_vld ? counter_coded_bin + 1 : counter_coded_bin); // record the decoded bin at current state
always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[30:0], ruiBin} : ruiBin_delay; // store the decoded bins
always_ff @(posedge clk)
    case(state)
    ABS_MVD_MINUS2_0: target_bin <= dec_done ? 1 : (first_zero_in_bins_d ? target_bin : ({first_zero_in_bins_d, first_zero_in_bins} == 2'b01 ? 
                                                                                        {counter_coded_bin, 1'b0} : 8'hFF));
    ABS_MVD_MINUS2_1: target_bin <= dec_done ? 1 : (first_zero_in_bins_d ? target_bin : ({first_zero_in_bins_d, first_zero_in_bins} == 2'b01 ? 
                                                                                        {counter_coded_bin, 1'b0} : 8'hFF));
    default:        target_bin <= 1;
    endcase

always_ff @(posedge clk)
    case(state)
    IDLE_MVD:                  dec_done <= 0;
    ABS_MVD_GREATER0_FLAG0:    dec_done <= (counter_coded_bin == 1) ? 1 : 0;;
    ABS_MVD_GREATER0_FLAG1:    dec_done <= (counter_coded_bin == 1) ? 1 : 0;;                   
    ABS_MVD_GREATER1_FLAG0:    dec_done <= (counter_coded_bin == 1) ? 1 : 0;;
    ABS_MVD_GREATER1_FLAG1:    dec_done <= (counter_coded_bin == 1) ? 1 : 0;;
    ABS_MVD_MINUS2_0:          dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;;
    MVD_SIGN_FLAG0:            dec_done <= (counter_coded_bin == 1) ? 1 : 0;;
    ABS_MVD_MINUS2_1:          dec_done <= (counter_coded_bin == target_bin) ? 1 : 0;;
    MVD_SIGN_FLAG1:            dec_done <= (counter_coded_bin == 1) ? 1 : 0;;
    default:                   dec_done <= 0;
    endcase

always_ff @(posedge clk) abs_mvd_greater0_flag0 <= (state == ABS_MVD_GREATER0_FLAG0 && ruiBin_vld) ? ruiBin : abs_mvd_greater0_flag0;
always_ff @(posedge clk) abs_mvd_greater0_flag1 <= (state == ABS_MVD_GREATER0_FLAG1 && ruiBin_vld) ? ruiBin : abs_mvd_greater0_flag1;
always_ff @(posedge clk) abs_mvd_greater1_flag0 <= (state == ABS_MVD_GREATER1_FLAG0 && ruiBin_vld) ? ruiBin : abs_mvd_greater1_flag0;
always_ff @(posedge clk) abs_mvd_greater1_flag1 <= (state == ABS_MVD_GREATER1_FLAG1 && ruiBin_vld) ? ruiBin : abs_mvd_greater1_flag1;
always_ff @(posedge clk) // support EpExGolomb until 16 lenth prefix
    if(state == ABS_MVD_MINUS2_0 & dec_done)
        case(counter_coded_bin[7:1])
        7'd1:  abs_mvd_minus2_0 <= ruiBin_delay[ 0:0];
        7'd2:  abs_mvd_minus2_0 <= ruiBin_delay[ 1:0] + 2'h2;
        7'd3:  abs_mvd_minus2_0 <= ruiBin_delay[ 2:0] + 3'h6;
        7'd4:  abs_mvd_minus2_0 <= ruiBin_delay[ 3:0] + 4'he;
        7'd5:  abs_mvd_minus2_0 <= ruiBin_delay[ 4:0] + 5'h1e;
        7'd6:  abs_mvd_minus2_0 <= ruiBin_delay[ 5:0] + 6'h3e;
        7'd7:  abs_mvd_minus2_0 <= ruiBin_delay[ 6:0] + 7'h7e;
        7'd8:  abs_mvd_minus2_0 <= ruiBin_delay[ 7:0] + 8'hfe;
        7'd9:  abs_mvd_minus2_0 <= ruiBin_delay[ 8:0] + 9'h1fe;
        7'd10: abs_mvd_minus2_0 <= ruiBin_delay[ 9:0] + 10'h3fe;
        7'd11: abs_mvd_minus2_0 <= ruiBin_delay[10:0] + 11'h7fe;
        7'd12: abs_mvd_minus2_0 <= ruiBin_delay[11:0] + 12'hffe;
        7'd13: abs_mvd_minus2_0 <= ruiBin_delay[12:0] + 13'h1ffe;
        7'd14: abs_mvd_minus2_0 <= ruiBin_delay[13:0] + 14'h3ffe;
        7'd15: abs_mvd_minus2_0 <= ruiBin_delay[14:0] + 15'h7ffe;
        7'd16: abs_mvd_minus2_0 <= ruiBin_delay[15:0] + 16'hfffe;
        default: abs_mvd_minus2_0 <= 10'h3FF;
        endcase
always_ff @(posedge clk) // support EpExGolomb until 16 lenth prefix
    if(state == ABS_MVD_MINUS2_1 & dec_done)
        case(counter_coded_bin[7:1])
        7'd1:  abs_mvd_minus2_1 <= ruiBin_delay[ 0:0];
        7'd2:  abs_mvd_minus2_1 <= ruiBin_delay[ 1:0] + 2'h2;
        7'd3:  abs_mvd_minus2_1 <= ruiBin_delay[ 2:0] + 3'h6;
        7'd4:  abs_mvd_minus2_1 <= ruiBin_delay[ 3:0] + 4'he;
        7'd5:  abs_mvd_minus2_1 <= ruiBin_delay[ 4:0] + 5'h1e;
        7'd6:  abs_mvd_minus2_1 <= ruiBin_delay[ 5:0] + 6'h3e;
        7'd7:  abs_mvd_minus2_1 <= ruiBin_delay[ 6:0] + 7'h7e;
        7'd8:  abs_mvd_minus2_1 <= ruiBin_delay[ 7:0] + 8'hfe;
        7'd9:  abs_mvd_minus2_1 <= ruiBin_delay[ 8:0] + 9'h1fe;
        7'd10: abs_mvd_minus2_1 <= ruiBin_delay[ 9:0] + 10'h3fe;
        7'd11: abs_mvd_minus2_1 <= ruiBin_delay[10:0] + 11'h7fe;
        7'd12: abs_mvd_minus2_1 <= ruiBin_delay[11:0] + 12'hffe;
        7'd13: abs_mvd_minus2_1 <= ruiBin_delay[12:0] + 13'h1ffe;
        7'd14: abs_mvd_minus2_1 <= ruiBin_delay[13:0] + 14'h3ffe;
        7'd15: abs_mvd_minus2_1 <= ruiBin_delay[14:0] + 15'h7ffe;
        7'd16: abs_mvd_minus2_1 <= ruiBin_delay[15:0] + 16'hfffe;
        default: abs_mvd_minus2_1 <= 10'h3FF;
        endcase
always_ff @(posedge clk) mvd_sign_flag0 <= (state == MVD_SIGN_FLAG0 && ruiBin_vld) ? ruiBin : mvd_sign_flag0;
always_ff @(posedge clk) mvd_sign_flag1 <= (state == MVD_SIGN_FLAG1 && ruiBin_vld) ? ruiBin : mvd_sign_flag1;

// Other output signal control
logic [7:0] ctx_mvd_addr_vld_count;
logic [1:0] dec_phase; // count 4 clock cycles for normal-mode decoding
always_ff @(posedge clk)
    if(state == IDLE_CU) ctx_mvd_addr_vld_count <= 0;
    else if(dec_done) ctx_mvd_addr_vld_count <= 0;
    else if(ctx_cu_addr_vld) ctx_mvd_addr_vld_count <= ctx_mvd_addr_vld_count + 1;
always_ff @(posedge clk)
    if(state == IDLE_CU) dec_phase <= 0;
    else if(ctx_cu_addr_vld) dec_phase <= 1;
    else dec_phase <= (dec_phase == 0) ? 0 : dec_phase + 1;

always_ff @(posedge clk)
    case(state)
    ABS_MVD_GREATER0_FLAG0:    ctx_mvd_addr <= CTXIDX_ABS_MVD_GT0_FLAG[0];
    ABS_MVD_GREATER0_FLAG1:    ctx_mvd_addr <= CTXIDX_ABS_MVD_GT0_FLAG[0];
    ABS_MVD_GREATER1_FLAG0:    ctx_mvd_addr <= CTXIDX_ABS_MVD_GT1_FLAG[0];
    ABS_MVD_GREATER1_FLAG1:    ctx_mvd_addr <= CTXIDX_ABS_MVD_GT1_FLAG[0];
    endcase
always_ff @(posedge clk)
    case(state)
    IDLE_MVD:                  ctx_mvd_addr_vld <= 0;
    ABS_MVD_GREATER0_FLAG0:    ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    ABS_MVD_GREATER0_FLAG1:    ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    ABS_MVD_GREATER1_FLAG0:    ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    ABS_MVD_GREATER1_FLAG1:    ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == 1) ? 0 : (dec_phase==0 ? 1 : 0);
    ABS_MVD_MINUS2_0:          ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == target_bin) ? 0 : 1;
    MVD_SIGN_FLAG0:            ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == 1) ? 0 : 1;
    ABS_MVD_MINUS2_1:          ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == target_bin) ? 0 : 1;
    MVD_SIGN_FLAG1:            ctx_mvd_addr_vld <= (ctx_mvd_addr_vld_count == 1) ? 0 : 1;
    default:                   ctx_mvd_addr_vld <= 0;
    endcase
always_ff @(posedge clk) dec_run_mvd <= ctx_mvd_addr_vld;
always_ff @(posedge clk)
    case(state)
    IDLE_MVD:                  EPMode_mvd <= 0;
    ABS_MVD_GREATER0_FLAG0:    EPMode_mvd <= 0;
    ABS_MVD_GREATER0_FLAG1:    EPMode_mvd <= 0;
    ABS_MVD_GREATER1_FLAG0:    EPMode_mvd <= 0;
    ABS_MVD_GREATER1_FLAG1:    EPMode_mvd <= 0;
    ABS_MVD_MINUS2_0:          EPMode_mvd <= 1;
    MVD_SIGN_FLAG0:            EPMode_mvd <= 1;
    ABS_MVD_MINUS2_1:          EPMode_mvd <= 1;
    MVD_SIGN_FLAG1:            EPMode_mvd <= 1;
    default:                   EPMode_mvd <= 0;
    endcase

// Sub FSMs

endmodule
