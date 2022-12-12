//
// Author : Qi Wang
// The sub-FSM to handle SAO part decoding
module qdec_sao_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       sao_start,
    input  logic [5:0] xCTB,
    input  logic [4:0] yCTB,
    input  logic [1:0] slice_type,
    input  logic       slice_sao_luma_flag,
    input  logic       slice_sao_chroma_flag,
    input  logic       cabac_init_flag,

    output logic [9:0] ctx_sao_addr,
    output logic       ctx_sao_addr_vld,
    output logic       dec_run_sao,
    input  logic       dec_rdy,
    output logic       EPMode_sao,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       sao_done_intr
);

logic left_CTU_exists, up_CTU_exists;
logic dec_done;
logic sao_merge_left_flag, sao_merge_up_flag;
logic [1:0] sao_type_luma, sao_type_chroma;
logic [2:0] sao_y_offset_abs[3:0], sao_cb_offset_abs[3:0], sao_cr_offset_abs[3:0]; // max offset abs is 7
logic [3:0] sao_y_offset_abs_gt0, sao_cb_offset_abs_gt0, sao_cr_offset_abs_gt0;
logic [2:0] sao_y_offset_abs_gt0_count, sao_cb_offset_abs_gt0_count, sao_cr_offset_abs_gt0_count;
logic [3:0] sao_y_offset_sign, sao_cb_offset_sign, sao_cr_offset_sign;
logic [4:0] sao_y_band_position, sao_cb_band_position, sao_cr_band_position;
logic [1:0] sao_luma_eo_class, sao_chroma_eo_class;
logic [1:0] counter_loop;
logic [7:0] ruiBin_delay;
logic [3:0] dec_count_type, dec_count_abs, dec_count_sign, dec_count_bo, dec_count_eo;
logic [3:0] counter_dec_run, counter_dec_run_d;
logic [2:0] ctx_sao_addr_vld_d; // no addr_vld in 4 clock cycles for normal mode

t_state_sao state, nxt_state;

always_comb
    case(state)
    IDLE_SAO:                 nxt_state = sao_start===1'b1 ? CALC_COR_SAO : IDLE_SAO;
    CALC_COR_SAO:             nxt_state = left_CTU_exists===1'b1 ? SAO_MERGE_LEFT_FLAG : 
                                          up_CTU_exists===1'b1 ? SAO_MERGE_UP_FLAG : SAO_TYPE_IDX_LUMA;
    SAO_MERGE_LEFT_FLAG:      nxt_state = dec_done===1'b1 ? (sao_merge_left_flag===1'b1 ? ENDING_SAO : 
                                                             slice_sao_luma_flag===1'b1 ? SAO_TYPE_IDX_LUMA :
                                                             slice_sao_chroma_flag===1'b1 ? SAO_TYPE_IDX_CHROMA : ENDING_SAO) :
                                          SAO_MERGE_LEFT_FLAG;
    SAO_MERGE_UP_FLAG:        nxt_state = dec_done===1'b1 ? (sao_merge_up_flag===1'b1 ? ENDING_SAO : 
                                                             slice_sao_luma_flag===1'b1 ? SAO_TYPE_IDX_LUMA :
                                                             slice_sao_chroma_flag===1'b1 ? SAO_TYPE_IDX_CHROMA : ENDING_SAO) :
                                          SAO_MERGE_UP_FLAG;
    SAO_TYPE_IDX_LUMA:        nxt_state = dec_done===1'b1 ? (sao_type_luma===2'h0 ? (slice_sao_chroma_flag===1'b1 ? SAO_TYPE_IDX_CHROMA : ENDING_SAO) : 
                                                             SAO_LUMA_OFFSET_ABS_4) :
                                          SAO_TYPE_IDX_LUMA;
    SAO_LUMA_OFFSET_ABS_4:    nxt_state = dec_done===1'b1 ? (sao_type_luma===2'h1 ? SAO_LUMA_OFFSET_SIGN_4 : SAO_EO_CLASS_LUMA) :
                                          SAO_LUMA_OFFSET_ABS_4;
    SAO_LUMA_OFFSET_SIGN_4:   nxt_state = dec_done===1'b1 ? SAO_LUMA_BAND_POS : SAO_LUMA_OFFSET_SIGN_4;
    SAO_LUMA_BAND_POS:        nxt_state = dec_done===1'b1 ? (slice_sao_chroma_flag===1'b1 ? SAO_TYPE_IDX_CHROMA : ENDING_SAO) :
                                          SAO_LUMA_BAND_POS;
    SAO_EO_CLASS_LUMA:        nxt_state = dec_done===1'b1 ? (slice_sao_chroma_flag===1'b1 ? SAO_TYPE_IDX_CHROMA : ENDING_SAO) : 
                                          SAO_EO_CLASS_LUMA;
    SAO_TYPE_IDX_CHROMA:      nxt_state = dec_done===1'b1 ? (sao_type_chroma===2'h0 ? ENDING_SAO : SAO_CB_OFFSET_ABS_4) :
                                          SAO_TYPE_IDX_CHROMA;
    SAO_CB_OFFSET_ABS_4:      nxt_state = dec_done===1'b1 ? (sao_type_chroma===2'h1 ? SAO_CB_OFFSET_SIGN_4 : SAO_EO_CLASS_CHROMA) :
                                          SAO_CB_OFFSET_ABS_4;
    SAO_CB_OFFSET_SIGN_4:     nxt_state = dec_done===1'b1 ? SAO_CB_BAND_POS : SAO_CB_OFFSET_SIGN_4;
    SAO_CB_BAND_POS:          nxt_state = dec_done===1'b1 ? SAO_CR_OFFSET_ABS_4 : SAO_CB_BAND_POS;
    SAO_EO_CLASS_CHROMA:      nxt_state = dec_done===1'b1 ? SAO_CR_OFFSET_ABS_4 : SAO_EO_CLASS_CHROMA;
    SAO_CR_OFFSET_ABS_4:      nxt_state = dec_done===1'b1 ? (sao_type_chroma===2'h1 ? SAO_CR_OFFSET_SIGN_4 : ENDING_SAO) :
                                          SAO_CR_OFFSET_ABS_4;
    SAO_CR_OFFSET_SIGN_4:     nxt_state = dec_done===1'b1 ? SAO_CR_BAND_POS : SAO_CR_OFFSET_SIGN_4;
    SAO_CR_BAND_POS:          nxt_state = dec_done===1'b1 ? ENDING_SAO : SAO_CR_BAND_POS;
    ENDING_SAO:               nxt_state = IDLE_SAO;
    default:                  nxt_state = IDLE_SAO;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_SAO;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) sao_done_intr <= (state == ENDING_SAO) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk)
    case(state)
    SAO_MERGE_LEFT_FLAG:   dec_done <= ruiBin_vld;
    SAO_MERGE_UP_FLAG:     dec_done <= ruiBin_vld;
    SAO_TYPE_IDX_LUMA:     dec_done <= ((dec_count_type == 1) & (ruiBin_delay[0] == 0)) | ((dec_count_type == 2) & (ruiBin_delay[1] == 1));
    SAO_LUMA_OFFSET_ABS_4: dec_done <= (dec_count_abs == 4) ? 1 : 0;
    SAO_LUMA_OFFSET_SIGN_4:dec_done <= (dec_count_sign == sao_y_offset_abs_gt0_count) ? 1 : 0;
    SAO_LUMA_BAND_POS:     dec_done <= (dec_count_bo == 5) ? 1 : 0;
    SAO_EO_CLASS_LUMA:     dec_done <= (dec_count_eo == 2) ? 1 : 0;
    SAO_TYPE_IDX_CHROMA:   dec_done <= ((dec_count_type == 1) & (ruiBin_delay[0] == 0)) | ((dec_count_type == 2) & (ruiBin_delay[1] == 1));
    SAO_CB_OFFSET_ABS_4:   dec_done <= (dec_count_abs == 4) ? 1 : 0;
    SAO_CB_OFFSET_SIGN_4:  dec_done <= (dec_count_sign == sao_cb_offset_abs_gt0_count) ? 1 : 0;
    SAO_CB_BAND_POS:       dec_done <= (dec_count_bo == 5) ? 1 : 0;
    SAO_EO_CLASS_CHROMA:   dec_done <= (dec_count_eo == 2) ? 1 : 0;
    SAO_CR_OFFSET_ABS_4:   dec_done <= (dec_count_abs == 4) ? 1 : 0;
    SAO_CR_OFFSET_SIGN_4:  dec_done <= (dec_count_sign == sao_cr_offset_abs_gt0_count) ? 1 : 0;
    SAO_CR_BAND_POS:       dec_done <= (dec_count_bo == 5) ? 1 : 0;
    default:               dec_done <= 0;
    endcase

always_ff @(posedge clk)
    if(state == SAO_TYPE_IDX_LUMA || state == SAO_TYPE_IDX_CHROMA) dec_count_type <= ruiBin_vld ? dec_count_type + 1 : dec_count_type; // 1'b0 or 2'b10 or 2'b11
    else dec_count_type <= 0;

always_ff @(posedge clk)
    if(state == SAO_LUMA_OFFSET_ABS_4 || state == SAO_CB_OFFSET_ABS_4 || state == SAO_CR_OFFSET_ABS_4) 
        dec_count_abs <= ruiBin_vld & ((ruiBin == 0) | ({ruiBin_delay[5:0], ruiBin} == 7'h7F)) ? dec_count_abs + 1 : dec_count_abs; // trU_7, need 4
    else dec_count_abs <= 0;

always_ff @(posedge clk)
    if(state == SAO_LUMA_OFFSET_SIGN_4 || state == SAO_CB_OFFSET_SIGN_4 || state == SAO_CR_OFFSET_SIGN_4) 
        dec_count_sign <= ruiBin_vld ? dec_count_sign + 1 : dec_count_sign;
    else dec_count_sign <= 0;

always_ff @(posedge clk)
    if(state == SAO_LUMA_BAND_POS || state == SAO_CB_BAND_POS || state == SAO_CR_BAND_POS) dec_count_bo <= ruiBin_vld ? dec_count_bo + 1 : dec_count_bo; // uflc, fixed length 5
    else dec_count_bo <= 0;

always_ff @(posedge clk)
    if(state == SAO_EO_CLASS_LUMA || state == SAO_EO_CLASS_CHROMA) dec_count_eo <= ruiBin_vld ? dec_count_eo + 1 : dec_count_eo; // uflc, fixed length 2
    else dec_count_eo <= 0;

always_ff @(posedge clk) ruiBin_delay <= ruiBin_vld ? {ruiBin_delay[6:0], ruiBin} : ruiBin_delay; // Hold the history of ruiBin for a byte

always_ff @(posedge clk) sao_merge_left_flag <= (state == SAO_MERGE_LEFT_FLAG && ruiBin_vld) ? ruiBin : sao_merge_left_flag;
always_ff @(posedge clk) sao_merge_up_flag <= (state == SAO_MERGE_UP_FLAG && ruiBin_vld) ? ruiBin : sao_merge_up_flag;
always_ff @(posedge clk)
    if(state == SAO_TYPE_IDX_LUMA && ruiBin_vld)
        sao_type_luma <= ((dec_count_type == 0) & (ruiBin == 0)) ? 0 :
                         ((dec_count_type == 1) & ({ruiBin_delay[0], ruiBin} == 2'b10)) ? 1 :
                         ((dec_count_type == 1) & ({ruiBin_delay[0], ruiBin} == 2'b11)) ? 2 :
                         0;
always_ff @(posedge clk)
    if(state == SAO_TYPE_IDX_CHROMA && ruiBin_vld)
        sao_type_chroma <= ((dec_count_type == 0) & (ruiBin == 0)) ? 0 :
                           ((dec_count_type == 1) & ({ruiBin_delay[0], ruiBin} == 2'b10)) ? 1 :
                           ((dec_count_type == 1) & ({ruiBin_delay[0], ruiBin} == 2'b11)) ? 2 :
                           0;
always_ff @(posedge clk)
    if(state == SAO_LUMA_OFFSET_ABS_4 && ruiBin_vld) begin
        casex({{ruiBin_delay[5:0], ruiBin, dec_count_abs[1:0]}})
        9'b1111111_00: begin sao_y_offset_abs[0] <= 3'h7; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'b0111111_00: begin sao_y_offset_abs[0] <= 3'h6; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'bx011111_00: begin sao_y_offset_abs[0] <= 3'h5; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'bxx01111_00: begin sao_y_offset_abs[0] <= 3'h4; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'bxxx0111_00: begin sao_y_offset_abs[0] <= 3'h3; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxx011_00: begin sao_y_offset_abs[0] <= 3'h2; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxxx01_00: begin sao_y_offset_abs[0] <= 3'h1; sao_y_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxxxx0_00: begin sao_y_offset_abs[0] <= 3'h0; sao_y_offset_abs_gt0[0] <= 1'b0; end
        9'b1111111_01: begin sao_y_offset_abs[1] <= 3'h7; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'b0111111_01: begin sao_y_offset_abs[1] <= 3'h6; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'bx011111_01: begin sao_y_offset_abs[1] <= 3'h5; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'bxx01111_01: begin sao_y_offset_abs[1] <= 3'h4; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'bxxx0111_01: begin sao_y_offset_abs[1] <= 3'h3; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxx011_01: begin sao_y_offset_abs[1] <= 3'h2; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxxx01_01: begin sao_y_offset_abs[1] <= 3'h1; sao_y_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxxxx0_01: begin sao_y_offset_abs[1] <= 3'h0; sao_y_offset_abs_gt0[1] <= 1'b0; end
        9'b1111111_10: begin sao_y_offset_abs[2] <= 3'h7; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'b0111111_10: begin sao_y_offset_abs[2] <= 3'h6; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'bx011111_10: begin sao_y_offset_abs[2] <= 3'h5; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'bxx01111_10: begin sao_y_offset_abs[2] <= 3'h4; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'bxxx0111_10: begin sao_y_offset_abs[2] <= 3'h3; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxx011_10: begin sao_y_offset_abs[2] <= 3'h2; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxxx01_10: begin sao_y_offset_abs[2] <= 3'h1; sao_y_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxxxx0_10: begin sao_y_offset_abs[2] <= 3'h0; sao_y_offset_abs_gt0[2] <= 1'b0; end
        9'b1111111_11: begin sao_y_offset_abs[3] <= 3'h7; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'b0111111_11: begin sao_y_offset_abs[3] <= 3'h6; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'bx011111_11: begin sao_y_offset_abs[3] <= 3'h5; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'bxx01111_11: begin sao_y_offset_abs[3] <= 3'h4; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'bxxx0111_11: begin sao_y_offset_abs[3] <= 3'h3; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxx011_11: begin sao_y_offset_abs[3] <= 3'h2; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxxx01_11: begin sao_y_offset_abs[3] <= 3'h1; sao_y_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxxxx0_11: begin sao_y_offset_abs[3] <= 3'h0; sao_y_offset_abs_gt0[3] <= 1'b0; end
        default:       begin end
        endcase
    end

always_ff @(posedge clk)
    case(sao_y_offset_abs_gt0)
    4'b0000: sao_y_offset_abs_gt0_count <= 3'd0;
    4'b0001: sao_y_offset_abs_gt0_count <= 3'd1;
    4'b0010: sao_y_offset_abs_gt0_count <= 3'd1;
    4'b0011: sao_y_offset_abs_gt0_count <= 3'd2;
    4'b0100: sao_y_offset_abs_gt0_count <= 3'd1;
    4'b0101: sao_y_offset_abs_gt0_count <= 3'd2;
    4'b0110: sao_y_offset_abs_gt0_count <= 3'd2;
    4'b0111: sao_y_offset_abs_gt0_count <= 3'd3;
    4'b1000: sao_y_offset_abs_gt0_count <= 3'd1;
    4'b1001: sao_y_offset_abs_gt0_count <= 3'd2;
    4'b1010: sao_y_offset_abs_gt0_count <= 3'd2;
    4'b1011: sao_y_offset_abs_gt0_count <= 3'd3;
    4'b1100: sao_y_offset_abs_gt0_count <= 3'd2;
    4'b1101: sao_y_offset_abs_gt0_count <= 3'd3;
    4'b1110: sao_y_offset_abs_gt0_count <= 3'd3;
    4'b1111: sao_y_offset_abs_gt0_count <= 3'd4;
    default: sao_y_offset_abs_gt0_count <= 3'd0;
    endcase

always_ff @(posedge clk)
    if(state == SAO_CB_OFFSET_ABS_4 && ruiBin_vld) begin
        casex({{ruiBin_delay[5:0], ruiBin, dec_count_abs[1:0]}})
        9'b1111111_00: begin sao_cb_offset_abs[0] <= 3'h7; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'b0111111_00: begin sao_cb_offset_abs[0] <= 3'h6; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'bx011111_00: begin sao_cb_offset_abs[0] <= 3'h5; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'bxx01111_00: begin sao_cb_offset_abs[0] <= 3'h4; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'bxxx0111_00: begin sao_cb_offset_abs[0] <= 3'h3; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxx011_00: begin sao_cb_offset_abs[0] <= 3'h2; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxxx01_00: begin sao_cb_offset_abs[0] <= 3'h1; sao_cb_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxxxx0_00: begin sao_cb_offset_abs[0] <= 3'h0; sao_cb_offset_abs_gt0[0] <= 1'b0; end
        9'b1111111_01: begin sao_cb_offset_abs[1] <= 3'h7; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'b0111111_01: begin sao_cb_offset_abs[1] <= 3'h6; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'bx011111_01: begin sao_cb_offset_abs[1] <= 3'h5; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'bxx01111_01: begin sao_cb_offset_abs[1] <= 3'h4; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'bxxx0111_01: begin sao_cb_offset_abs[1] <= 3'h3; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxx011_01: begin sao_cb_offset_abs[1] <= 3'h2; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxxx01_01: begin sao_cb_offset_abs[1] <= 3'h1; sao_cb_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxxxx0_01: begin sao_cb_offset_abs[1] <= 3'h0; sao_cb_offset_abs_gt0[1] <= 1'b0; end
        9'b1111111_10: begin sao_cb_offset_abs[2] <= 3'h7; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'b0111111_10: begin sao_cb_offset_abs[2] <= 3'h6; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'bx011111_10: begin sao_cb_offset_abs[2] <= 3'h5; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'bxx01111_10: begin sao_cb_offset_abs[2] <= 3'h4; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'bxxx0111_10: begin sao_cb_offset_abs[2] <= 3'h3; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxx011_10: begin sao_cb_offset_abs[2] <= 3'h2; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxxx01_10: begin sao_cb_offset_abs[2] <= 3'h1; sao_cb_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxxxx0_10: begin sao_cb_offset_abs[2] <= 3'h0; sao_cb_offset_abs_gt0[2] <= 1'b0; end
        9'b1111111_11: begin sao_cb_offset_abs[3] <= 3'h7; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'b0111111_11: begin sao_cb_offset_abs[3] <= 3'h6; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'bx011111_11: begin sao_cb_offset_abs[3] <= 3'h5; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'bxx01111_11: begin sao_cb_offset_abs[3] <= 3'h4; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'bxxx0111_11: begin sao_cb_offset_abs[3] <= 3'h3; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxx011_11: begin sao_cb_offset_abs[3] <= 3'h2; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxxx01_11: begin sao_cb_offset_abs[3] <= 3'h1; sao_cb_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxxxx0_11: begin sao_cb_offset_abs[3] <= 3'h0; sao_cb_offset_abs_gt0[3] <= 1'b0; end
        default:       begin end
        endcase
    end

always_ff @(posedge clk)
    case(sao_cb_offset_abs_gt0)
    4'b0000: sao_cb_offset_abs_gt0_count <= 3'd0;
    4'b0001: sao_cb_offset_abs_gt0_count <= 3'd1;
    4'b0010: sao_cb_offset_abs_gt0_count <= 3'd1;
    4'b0011: sao_cb_offset_abs_gt0_count <= 3'd2;
    4'b0100: sao_cb_offset_abs_gt0_count <= 3'd1;
    4'b0101: sao_cb_offset_abs_gt0_count <= 3'd2;
    4'b0110: sao_cb_offset_abs_gt0_count <= 3'd2;
    4'b0111: sao_cb_offset_abs_gt0_count <= 3'd3;
    4'b1000: sao_cb_offset_abs_gt0_count <= 3'd1;
    4'b1001: sao_cb_offset_abs_gt0_count <= 3'd2;
    4'b1010: sao_cb_offset_abs_gt0_count <= 3'd2;
    4'b1011: sao_cb_offset_abs_gt0_count <= 3'd3;
    4'b1100: sao_cb_offset_abs_gt0_count <= 3'd2;
    4'b1101: sao_cb_offset_abs_gt0_count <= 3'd3;
    4'b1110: sao_cb_offset_abs_gt0_count <= 3'd3;
    4'b1111: sao_cb_offset_abs_gt0_count <= 3'd4;
    default: sao_cb_offset_abs_gt0_count <= 3'd0;
    endcase

always_ff @(posedge clk)
    if(state == SAO_CR_OFFSET_ABS_4 && ruiBin_vld) begin
        casex({{ruiBin_delay[5:0], ruiBin, dec_count_abs[1:0]}})
        9'b1111111_00: begin sao_cr_offset_abs[0] <= 3'h7; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'b0111111_00: begin sao_cr_offset_abs[0] <= 3'h6; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'bx011111_00: begin sao_cr_offset_abs[0] <= 3'h5; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'bxx01111_00: begin sao_cr_offset_abs[0] <= 3'h4; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'bxxx0111_00: begin sao_cr_offset_abs[0] <= 3'h3; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxx011_00: begin sao_cr_offset_abs[0] <= 3'h2; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxxx01_00: begin sao_cr_offset_abs[0] <= 3'h1; sao_cr_offset_abs_gt0[0] <= 1'b1; end
        9'bxxxxxx0_00: begin sao_cr_offset_abs[0] <= 3'h0; sao_cr_offset_abs_gt0[0] <= 1'b0; end
        9'b1111111_01: begin sao_cr_offset_abs[1] <= 3'h7; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'b0111111_01: begin sao_cr_offset_abs[1] <= 3'h6; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'bx011111_01: begin sao_cr_offset_abs[1] <= 3'h5; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'bxx01111_01: begin sao_cr_offset_abs[1] <= 3'h4; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'bxxx0111_01: begin sao_cr_offset_abs[1] <= 3'h3; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxx011_01: begin sao_cr_offset_abs[1] <= 3'h2; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxxx01_01: begin sao_cr_offset_abs[1] <= 3'h1; sao_cr_offset_abs_gt0[1] <= 1'b1; end
        9'bxxxxxx0_01: begin sao_cr_offset_abs[1] <= 3'h0; sao_cr_offset_abs_gt0[1] <= 1'b0; end
        9'b1111111_10: begin sao_cr_offset_abs[2] <= 3'h7; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'b0111111_10: begin sao_cr_offset_abs[2] <= 3'h6; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'bx011111_10: begin sao_cr_offset_abs[2] <= 3'h5; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'bxx01111_10: begin sao_cr_offset_abs[2] <= 3'h4; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'bxxx0111_10: begin sao_cr_offset_abs[2] <= 3'h3; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxx011_10: begin sao_cr_offset_abs[2] <= 3'h2; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxxx01_10: begin sao_cr_offset_abs[2] <= 3'h1; sao_cr_offset_abs_gt0[2] <= 1'b1; end
        9'bxxxxxx0_10: begin sao_cr_offset_abs[2] <= 3'h0; sao_cr_offset_abs_gt0[2] <= 1'b0; end
        9'b1111111_11: begin sao_cr_offset_abs[3] <= 3'h7; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'b0111111_11: begin sao_cr_offset_abs[3] <= 3'h6; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'bx011111_11: begin sao_cr_offset_abs[3] <= 3'h5; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'bxx01111_11: begin sao_cr_offset_abs[3] <= 3'h4; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'bxxx0111_11: begin sao_cr_offset_abs[3] <= 3'h3; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxx011_11: begin sao_cr_offset_abs[3] <= 3'h2; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxxx01_11: begin sao_cr_offset_abs[3] <= 3'h1; sao_cr_offset_abs_gt0[3] <= 1'b1; end
        9'bxxxxxx0_11: begin sao_cr_offset_abs[3] <= 3'h0; sao_cr_offset_abs_gt0[3] <= 1'b0; end
        default:       begin end
        endcase
    end

always_ff @(posedge clk)
    case(sao_cr_offset_abs_gt0)
    4'b0000: sao_cr_offset_abs_gt0_count <= 3'd0;
    4'b0001: sao_cr_offset_abs_gt0_count <= 3'd1;
    4'b0010: sao_cr_offset_abs_gt0_count <= 3'd1;
    4'b0011: sao_cr_offset_abs_gt0_count <= 3'd2;
    4'b0100: sao_cr_offset_abs_gt0_count <= 3'd1;
    4'b0101: sao_cr_offset_abs_gt0_count <= 3'd2;
    4'b0110: sao_cr_offset_abs_gt0_count <= 3'd2;
    4'b0111: sao_cr_offset_abs_gt0_count <= 3'd3;
    4'b1000: sao_cr_offset_abs_gt0_count <= 3'd1;
    4'b1001: sao_cr_offset_abs_gt0_count <= 3'd2;
    4'b1010: sao_cr_offset_abs_gt0_count <= 3'd2;
    4'b1011: sao_cr_offset_abs_gt0_count <= 3'd3;
    4'b1100: sao_cr_offset_abs_gt0_count <= 3'd2;
    4'b1101: sao_cr_offset_abs_gt0_count <= 3'd3;
    4'b1110: sao_cr_offset_abs_gt0_count <= 3'd3;
    4'b1111: sao_cr_offset_abs_gt0_count <= 3'd4;
    default: sao_cr_offset_abs_gt0_count <= 3'd0;
    endcase

always_ff @(posedge clk)
    if(state == SAO_LUMA_OFFSET_SIGN_4 && (dec_count_sign == sao_y_offset_abs_gt0_count))
        case(sao_y_offset_abs_gt0)
        4'b0000: sao_y_offset_sign <= {           1'b0,            1'b0,            1'b0,            1'b0};
        4'b0001: sao_y_offset_sign <= {           1'b0,            1'b0,            1'b0, ruiBin_delay[0]};
        4'b0010: sao_y_offset_sign <= {           1'b0,            1'b0, ruiBin_delay[0],            1'b0};
        4'b0011: sao_y_offset_sign <= {           1'b0,            1'b0, ruiBin_delay[0], ruiBin_delay[1]};
        4'b0100: sao_y_offset_sign <= {           1'b0, ruiBin_delay[0],            1'b0,            1'b0};
        4'b0101: sao_y_offset_sign <= {           1'b0, ruiBin_delay[0],            1'b0, ruiBin_delay[1]};
        4'b0110: sao_y_offset_sign <= {           1'b0, ruiBin_delay[0], ruiBin_delay[1],            1'b0};
        4'b0111: sao_y_offset_sign <= {           1'b0, ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2]};
        4'b1000: sao_y_offset_sign <= {ruiBin_delay[0],            1'b0,            1'b0,            1'b0};
        4'b1001: sao_y_offset_sign <= {ruiBin_delay[0],            1'b0,            1'b0, ruiBin_delay[1]};
        4'b1010: sao_y_offset_sign <= {ruiBin_delay[0],            1'b0, ruiBin_delay[1],            1'b0};
        4'b1011: sao_y_offset_sign <= {ruiBin_delay[0],            1'b0, ruiBin_delay[1], ruiBin_delay[2]};
        4'b1100: sao_y_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1],            1'b0,            1'b0};
        4'b1101: sao_y_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1],            1'b0, ruiBin_delay[2]};
        4'b1110: sao_y_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2],            1'b0};
        4'b1111: sao_y_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2], ruiBin_delay[3]};
        default: sao_y_offset_sign <= {           1'b0,            1'b0,            1'b0,            1'b0};
        endcase

always_ff @(posedge clk)
    if(state == SAO_CB_OFFSET_SIGN_4 && (dec_count_sign == sao_cb_offset_abs_gt0_count))
        case(sao_cb_offset_abs_gt0)
        4'b0000: sao_cb_offset_sign <= {           1'b0,            1'b0,            1'b0,            1'b0};
        4'b0001: sao_cb_offset_sign <= {           1'b0,            1'b0,            1'b0, ruiBin_delay[0]};
        4'b0010: sao_cb_offset_sign <= {           1'b0,            1'b0, ruiBin_delay[0],            1'b0};
        4'b0011: sao_cb_offset_sign <= {           1'b0,            1'b0, ruiBin_delay[0], ruiBin_delay[1]};
        4'b0100: sao_cb_offset_sign <= {           1'b0, ruiBin_delay[0],            1'b0,            1'b0};
        4'b0101: sao_cb_offset_sign <= {           1'b0, ruiBin_delay[0],            1'b0, ruiBin_delay[1]};
        4'b0110: sao_cb_offset_sign <= {           1'b0, ruiBin_delay[0], ruiBin_delay[1],            1'b0};
        4'b0111: sao_cb_offset_sign <= {           1'b0, ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2]};
        4'b1000: sao_cb_offset_sign <= {ruiBin_delay[0],            1'b0,            1'b0,            1'b0};
        4'b1001: sao_cb_offset_sign <= {ruiBin_delay[0],            1'b0,            1'b0, ruiBin_delay[1]};
        4'b1010: sao_cb_offset_sign <= {ruiBin_delay[0],            1'b0, ruiBin_delay[1],            1'b0};
        4'b1011: sao_cb_offset_sign <= {ruiBin_delay[0],            1'b0, ruiBin_delay[1], ruiBin_delay[2]};
        4'b1100: sao_cb_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1],            1'b0,            1'b0};
        4'b1101: sao_cb_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1],            1'b0, ruiBin_delay[2]};
        4'b1110: sao_cb_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2],            1'b0};
        4'b1111: sao_cb_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2], ruiBin_delay[3]};
        default: sao_cb_offset_sign <= {           1'b0,            1'b0,            1'b0,            1'b0};
        endcase

always_ff @(posedge clk)
    if(state == SAO_CR_OFFSET_SIGN_4 && (dec_count_sign == sao_cr_offset_abs_gt0_count))
        case(sao_cr_offset_abs_gt0)
        4'b0000: sao_cr_offset_sign <= {           1'b0,            1'b0,            1'b0,            1'b0};
        4'b0001: sao_cr_offset_sign <= {           1'b0,            1'b0,            1'b0, ruiBin_delay[0]};
        4'b0010: sao_cr_offset_sign <= {           1'b0,            1'b0, ruiBin_delay[0],            1'b0};
        4'b0011: sao_cr_offset_sign <= {           1'b0,            1'b0, ruiBin_delay[0], ruiBin_delay[1]};
        4'b0100: sao_cr_offset_sign <= {           1'b0, ruiBin_delay[0],            1'b0,            1'b0};
        4'b0101: sao_cr_offset_sign <= {           1'b0, ruiBin_delay[0],            1'b0, ruiBin_delay[1]};
        4'b0110: sao_cr_offset_sign <= {           1'b0, ruiBin_delay[0], ruiBin_delay[1],            1'b0};
        4'b0111: sao_cr_offset_sign <= {           1'b0, ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2]};
        4'b1000: sao_cr_offset_sign <= {ruiBin_delay[0],            1'b0,            1'b0,            1'b0};
        4'b1001: sao_cr_offset_sign <= {ruiBin_delay[0],            1'b0,            1'b0, ruiBin_delay[1]};
        4'b1010: sao_cr_offset_sign <= {ruiBin_delay[0],            1'b0, ruiBin_delay[1],            1'b0};
        4'b1011: sao_cr_offset_sign <= {ruiBin_delay[0],            1'b0, ruiBin_delay[1], ruiBin_delay[2]};
        4'b1100: sao_cr_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1],            1'b0,            1'b0};
        4'b1101: sao_cr_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1],            1'b0, ruiBin_delay[2]};
        4'b1110: sao_cr_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2],            1'b0};
        4'b1111: sao_cr_offset_sign <= {ruiBin_delay[0], ruiBin_delay[1], ruiBin_delay[2], ruiBin_delay[3]};
        default: sao_cr_offset_sign <= {           1'b0,            1'b0,            1'b0,            1'b0};
        endcase

always_ff @(posedge clk) if(state == SAO_LUMA_BAND_POS && (dec_count_bo == 5)) sao_y_band_position <= ruiBin_delay[4:0];
always_ff @(posedge clk) if(state == SAO_CB_BAND_POS && (dec_count_bo == 5)) sao_cb_band_position <= ruiBin_delay[4:0];
always_ff @(posedge clk) if(state == SAO_CR_BAND_POS && (dec_count_bo == 5)) sao_cr_band_position <= ruiBin_delay[4:0];

always_ff @(posedge clk) if(state == SAO_EO_CLASS_LUMA && (dec_count_eo == 2)) sao_luma_eo_class <= ruiBin_delay[1:0];
always_ff @(posedge clk) if(state == SAO_EO_CLASS_CHROMA && (dec_count_eo == 2)) sao_chroma_eo_class <= ruiBin_delay[1:0];

// context memory access control
always_ff @(posedge clk)
    case(state)
    SAO_MERGE_LEFT_FLAG:   ctx_sao_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_SAO_MERGE_LEFT_FLAG[0] : 
                                           (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_SAO_MERGE_LEFT_FLAG[2] : CTXIDX_SAO_MERGE_LEFT_FLAG[1]) :
                                           (cabac_init_flag ? CTXIDX_SAO_MERGE_LEFT_FLAG[1] : CTXIDX_SAO_MERGE_LEFT_FLAG[2]);
    SAO_MERGE_UP_FLAG:     ctx_sao_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_SAO_MERGE_UP_FLAG[0] : 
                                           (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_SAO_MERGE_UP_FLAG[2] : CTXIDX_SAO_MERGE_UP_FLAG[1]) :
                                           (cabac_init_flag ? CTXIDX_SAO_MERGE_UP_FLAG[1] : CTXIDX_SAO_MERGE_UP_FLAG[2]);
    SAO_TYPE_IDX_LUMA:     ctx_sao_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_SAO_TYPE_IDX_LUMA[0] : 
                                           (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_SAO_TYPE_IDX_LUMA[2] : CTXIDX_SAO_TYPE_IDX_LUMA[1]) :
                                           (cabac_init_flag ? CTXIDX_SAO_TYPE_IDX_LUMA[1] : CTXIDX_SAO_TYPE_IDX_LUMA[2]);
    SAO_TYPE_IDX_CHROMA:   ctx_sao_addr <= (slice_type == SLICE_TYPE_I) ? CTXIDX_SAO_TYPE_IDX_CHROMA[0] : 
                                           (slice_type == SLICE_TYPE_P) ? (cabac_init_flag ? CTXIDX_SAO_TYPE_IDX_CHROMA[2] : CTXIDX_SAO_TYPE_IDX_CHROMA[1]) :
                                           (cabac_init_flag ? CTXIDX_SAO_TYPE_IDX_CHROMA[1] : CTXIDX_SAO_TYPE_IDX_CHROMA[2]);
    default:               ctx_sao_addr <= 0;
    endcase


always_ff @(posedge clk) ctx_sao_addr_vld_d <= {ctx_sao_addr_vld_d[1:0], ctx_sao_addr_vld};
always_ff @(posedge clk)
    case(state)
    SAO_MERGE_LEFT_FLAG:   ctx_sao_addr_vld <= dec_rdy & ({ctx_sao_addr_vld_d, ctx_sao_addr_vld} == 0) ? 1 : 0;
    SAO_MERGE_UP_FLAG:     ctx_sao_addr_vld <= dec_rdy & ({ctx_sao_addr_vld_d, ctx_sao_addr_vld} == 0) ? 1 : 0;
    SAO_TYPE_IDX_LUMA:     ctx_sao_addr_vld <= dec_rdy & ({ctx_sao_addr_vld_d, ctx_sao_addr_vld} == 0) ? 1 : 0;
    SAO_TYPE_IDX_CHROMA:   ctx_sao_addr_vld <= dec_rdy & ({ctx_sao_addr_vld_d, ctx_sao_addr_vld} == 0) ? 1 : 0;
    default:               ctx_sao_addr_vld <= 0;
    endcase

// Other output signal control
always_ff @(posedge clk)
    if(!rst_n) counter_dec_run <= 0;
    else
        case(state)
        SAO_MERGE_LEFT_FLAG:   counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_MERGE_UP_FLAG:     counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_TYPE_IDX_LUMA:     counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_LUMA_OFFSET_ABS_4: counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_LUMA_OFFSET_SIGN_4:counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_LUMA_BAND_POS:     counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_EO_CLASS_LUMA:     counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_TYPE_IDX_CHROMA:   counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_CB_OFFSET_ABS_4:   counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_CB_OFFSET_SIGN_4:  counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_CB_BAND_POS:       counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_EO_CLASS_CHROMA:   counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_CR_OFFSET_ABS_4:   counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_CR_OFFSET_SIGN_4:  counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        SAO_CR_BAND_POS:       counter_dec_run <= dec_done ? 0 : (dec_run_sao ? counter_dec_run + 1 : counter_dec_run);
        default:               counter_dec_run <= 0;
        endcase
always_ff @(posedge clk) counter_dec_run_d <= counter_dec_run;

always_ff @(posedge clk)
    case(state)
    SAO_MERGE_LEFT_FLAG:   dec_run_sao <= (counter_dec_run < 1) ? ctx_sao_addr_vld_d[2] & (counter_dec_run < 1) : 0;
    SAO_MERGE_UP_FLAG:     dec_run_sao <= (counter_dec_run < 1) ? ctx_sao_addr_vld_d[2] & (counter_dec_run < 1) : 0;
    SAO_TYPE_IDX_LUMA:     dec_run_sao <= (counter_dec_run < 1) ? ctx_sao_addr_vld_d[2] & (counter_dec_run < 1) : 0;
    SAO_LUMA_OFFSET_ABS_4: dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_LUMA_OFFSET_SIGN_4:dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_LUMA_BAND_POS:     dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_EO_CLASS_LUMA:     dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_TYPE_IDX_CHROMA:   dec_run_sao <= (counter_dec_run < 1) ? ctx_sao_addr_vld_d[2] & (counter_dec_run < 1) : 0;
    SAO_CB_OFFSET_ABS_4:   dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_CB_OFFSET_SIGN_4:  dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_CB_BAND_POS:       dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_EO_CLASS_CHROMA:   dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_CR_OFFSET_ABS_4:   dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_CR_OFFSET_SIGN_4:  dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    SAO_CR_BAND_POS:       dec_run_sao <= (counter_dec_run < 1) ? 1 : 0;
    default:               dec_run_sao <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    SAO_MERGE_LEFT_FLAG:   EPMode_sao <= 1;
    SAO_MERGE_UP_FLAG:     EPMode_sao <= 1;
    SAO_TYPE_IDX_LUMA:     EPMode_sao <= 1;
    SAO_TYPE_IDX_CHROMA:   EPMode_sao <= 1;
    default:               EPMode_sao <= 0;
    endcase

// Sub FSMs

endmodule
