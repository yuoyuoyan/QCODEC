//
// Author : Qi Wang
// The main FSM to handle all non-context-adaptive decoding before CTU signal
// and fill the control reg with all the decoded info
module qdec_main_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    // main control
    input  logic       cabac_start,

    // interface to control reg
    output t_reg_req_s      reg_req,

    // decapsule flow
    input  logic [7:0] bitstreamFetch,
    input  logic       bitstreamFetch_vld,
    output logic       bitstreamFetch_rdy,
    output logic [7:0] bitstreamFetch_decap,
    output logic       bitstreamFetch_decap_vld,
    input  logic       bitstreamFetch_decap_rdy
);

// All signals controlling main fsm
logic [7:0] bitstreamFetch_tmp;
logic       bitstreamFetch_tmp_vld;
logic       bitstreamFetch_tmp_rdy;
logic       byte_fetch_00, byte_fetch_03;
t_state_del03 state_decap, nxt_state_decap;

always_comb
    case(state_decap)
    IDLE_DEL:        nxt_state_decap = DEL0;
    DEL0:            nxt_state_decap = (bitstreamFetch_vld & bitstreamFetch_rdy) ? (byte_fetch_00 ? DEL1 : DEL0) : DEL0;
    DEL1:            nxt_state_decap = (bitstreamFetch_vld & bitstreamFetch_rdy) ? (byte_fetch_00 ? DEL2 : DEL0) : DEL1;
    DEL2:            nxt_state_decap = (bitstreamFetch_vld & bitstreamFetch_rdy) ? DEL0 : DEL2;
    default:         nxt_state_decap = IDLE_DEL;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state_decap <= IDLE_DEL;
    else state_decap <= nxt_state_decap;

assign byte_fetch_00 = bitstreamFetch == 8'h00;
assign byte_fetch_03 = bitstreamFetch == 8'h03;

basic_fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(2),
    .DATA_DEPTH(4)
) bitstreamFetch_fifo
(
    .clk,
    .rst_n,

    .din     (bitstreamFetch),
    .din_vld (bitstreamFetch_vld & !(state_decap == DEL2 && byte_fetch_03)),
    .din_rdy (bitstreamFetch_rdy),

    .dout     (bitstreamFetch_tmp),
    .dout_vld (bitstreamFetch_tmp_vld),
    .dout_rdy (bitstreamFetch_tmp_rdy)
);

// Signal in main fsm
logic [5:0] nalu_header;
logic       vps_start, sps_start, pps_start, sei_start, aud_start, eos_start, eob_start, fd_start, slice_start;
logic       vps_done_intr, sps_done_intr, pps_done_intr, sei_done_intr, aud_done_intr, eos_done_intr, eob_done_intr, fd_done_intr, slice_done_intr;
logic       slice_header_done_intr;
logic [31:0]vps_reg_addr, sps_reg_addr, pps_reg_addr, sei_reg_addr, slice_header_reg_addr;
logic [31:0]vps_reg_data, sps_reg_data, pps_reg_data, sei_reg_data, slice_header_reg_data;
logic       vps_reg_we,   sps_reg_we,   pps_reg_we,   sei_reg_we,   slice_header_reg_we;

// typedef enum logic [7:0]  {IDLE_MAIN, CAPS1_MAIN, CAPS2_MAIN, CAPS3_MAIN, NALU_HEAD_MAIN, 
//                            VPS_MAIN, SPS_MAIN, PPS_MAIN, SEI_MAIN, AU_MAIN, EOS_MAIN, EOB_MAIN, FD_MAIN, SLICE_MAIN, ENDING_MAIN} t_state_main;
t_state_main state, nxt_state;

always_comb
    case(state)
    IDLE_MAIN:                nxt_state = cabac_start ? CAPS1_MAIN : IDLE_MAIN;
    CAPS1_MAIN:               nxt_state = (bitstreamFetch_tmp_vld & bitstreamFetch_tmp_rdy) ? (bitstreamFetch_tmp == 8'h00 ? CAPS2_MAIN : CAPS1_MAIN) : CAPS1_MAIN;
    CAPS2_MAIN:               nxt_state = (bitstreamFetch_tmp_vld & bitstreamFetch_tmp_rdy) ? (bitstreamFetch_tmp == 8'h00 ? CAPS3_MAIN : CAPS1_MAIN) : CAPS2_MAIN;
    CAPS3_MAIN:               nxt_state = (bitstreamFetch_tmp_vld & bitstreamFetch_tmp_rdy) ? ( (bitstreamFetch_tmp == 8'h01 || bitstreamFetch_tmp == 8'h02) ? 
                                                                                              NALU_HEAD_MAIN : (bitstreamFetch_tmp == 8'h00 ? CAPS3_MAIN : CAPS1_MAIN)) 
                                          : CAPS3_MAIN;
    NALU_HEAD1_MAIN:          nxt_state = (bitstreamFetch_tmp_vld & bitstreamFetch_tmp_rdy) ? NALU_HEAD2_MAIN : NALU_HEAD1_MAIN;
    NALU_HEAD2_MAIN:          nxt_state = (bitstreamFetch_tmp_vld & bitstreamFetch_tmp_rdy) ? (nalu_header == NALU_VPS_NUT ? VPS_MAIN :
                                                                                               nalu_header == NALU_SPS_NUT ? SPS_MAIN :
                                                                                               nalu_header == NALU_PPS_NUT ? PPS_MAIN :
                                                                                               nalu_header == NALU_SEI_NUT ? SEI_MAIN :
                                                                                               nalu_header == NALU_AUD_NUT ? AUD_MAIN :
                                                                                               nalu_header == NALU_EOS_NUT ? EOS_MAIN :
                                                                                               nalu_header == NALU_EOB_NUT ? EOB_MAIN :
                                                                                               nalu_header == NALU_FD_NUT  ? FD_MAIN :
                                                                                               SLICE_MAIN)
                                          : NALU_HEAD2_MAIN;
    VPS_MAIN:                 nxt_state = vps_done_intr ? CAPS1_MAIN : VPS_MAIN;
    SPS_MAIN:                 nxt_state = sps_done_intr ? CAPS1_MAIN : SPS_MAIN;
    PPS_MAIN:                 nxt_state = pps_done_intr ? CAPS1_MAIN : PPS_MAIN;
    SEI_MAIN:                 nxt_state = sei_done_intr ? CAPS1_MAIN : SEI_MAIN;
    AUD_MAIN:                 nxt_state = aud_done_intr ? CAPS1_MAIN : AU_MAIN;
    EOS_MAIN:                 nxt_state = eos_done_intr ? CAPS1_MAIN : EOS_MAIN;
    EOB_MAIN:                 nxt_state = eob_done_intr ? CAPS1_MAIN : EOB_MAIN;
    FD_MAIN:                  nxt_state = fd_done_intr ? CAPS1_MAIN : FD_MAIN;
    SLICE_MAIN:               nxt_state = slice_done_intr ? CAPS1_MAIN : SLICE_MAIN;
    ENDING_MAIN:              nxt_state = IDLE_MAIN;
    default:                  nxt_state = IDLE_MAIN;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_MAIN;
    else state <= nxt_state;

// Sub FSMs
qdec_vps_fsm vps_fsm(
    .clk,
    .rst_n,

    .vps_start,
    .vps_done_intr,

    .reg_addr (vps_reg_addr),
    .reg_data (vps_reg_data),
    .reg_we   (vps_reg_we)
);

qdec_sps_fsm sps_fsm(
    .clk,
    .rst_n,

    .sps_start,
    .sps_done_intr,

    .reg_addr (sps_reg_addr),
    .reg_data (sps_reg_data),
    .reg_we   (sps_reg_we)
);

qdec_pps_fsm pps_fsm(
    .clk,
    .rst_n,

    .pps_start,
    .pps_done_intr,

    .reg_addr (pps_reg_addr),
    .reg_data (pps_reg_data),
    .reg_we   (pps_reg_we)
);

qdec_sei_fsm sei_fsm(
    .clk,
    .rst_n,

    .sei_start,
    .sei_done_intr,

    .reg_addr (sei_reg_addr),
    .reg_data (sei_reg_data),
    .reg_we   (sei_reg_we)
);

qdec_aud_fsm aud_fsm(
    .clk,
    .rst_n,

    .aud_start,
    .aud_done_intr
);

qdec_eos_fsm eos_fsm(
    .clk,
    .rst_n,

    .eos_start,
    .eos_done_intr
);

qdec_eob_fsm eob_fsm(
    .clk,
    .rst_n,

    .eob_start,
    .eob_done_intr
);

qdec_fd_fsm fd_fsm(
    .clk,
    .rst_n,

    .fd_start,
    .fd_done_intr
);

qdec_slice_fsm slice_fsm(
    .clk,
    .rst_n,

    .slice_start,
    .slice_done_intr,

    .reg_addr (slice_header_reg_addr),
    .reg_data (slice_header_reg_data),
    .reg_we   (slice_header_reg_we)
);

endmodule
