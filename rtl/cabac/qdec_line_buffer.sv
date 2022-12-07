// Author: Qi Wang
// Line buffer module to store decoded syntax, and top-level parameter sets
// Data format is fixed length 2192 bytes for a CTU, all aligned with bytes
// Store in ping-pong buffer style, two CTUs in a row
// For those signal separeted in matrix format, only record the left-up corner
// e.x. split flag work until 8x8, so only record (64/8)^2=64 flags
//
// sao
// sao_merge_left_flag, sao_merge_up_flag, sao_type_idx_luma, sao_type_idx_chroma 1
// sao_offset_abs[4] 4
// sao_offset_luma_sign[4] 1
// sao_band_position_luma 1
// sao_offset_cb_sign[4] 1
// sao_band_position_cb 1
// sao_offset_cr_sign[4] 1
// sao_band_position_cr 1
// sao_eo_class_luma, sao_eo_class_chroma 1
// top
// end_of_slice_segment_flag 1
// align_reserved 3
// cqt
// split_cu_flag_min8x8[64] 8
// cu
// cu_transquant_bypass_flag_min4x4[256] 32
// cu_skip_flag_min4x4[256] 32
// pred_mode_flag_min4x4[256] 32
// part_mode_min8x8[64] 32
// prev_intra_luma_pred_flag_min4x4[256] 32
// mpm_idx_min4x4[256] 64
// rem_intra_luma_pred_mode_min4x4[256] 256
// intra_chroma_pred_mode_min4x4[64] 32
// rqt_root_cbf_min4x4[256] 32
// pu
// merge_flag_min4x4[256] 32
// merge_idx_min4x4[256] 64
// inter_pred_idc_min4x4[256] 64
// ref_idx_l0_min4x4[256] 64
// ref_idx_l1_min4x4[256] 64
// mvp_l0_flag_min4x4[256] 32
// mvp_l1_flag_min4x4[256] 32
// mvd
// mvd_l0_min4x4[256] 256
// mvd_l1_min4x4[256] 256
// trafo
// split_transform_flag_min8x8[64] 8
// cbf_cb_min4x4[64] 8
// cbf_cr_min4x4[64] 8
// cbf_luma_min4x4[256] 32
// dqp
// qp_delta_min4x4[256] 256
// cqp
// chroma_qp_offset_min4x4[64] 16
// res
// transform_skip_flag_y_min4x4[256] 32
// transform_skip_flag_cb_min4x4[64] 8
// transform_skip_flag_cr_min4x4[64] 8
// residual_y_min4x4[256] 256
// residual_cb_min4x4[64] 64
// residual_cr_min4x4[64] 64

module qdec_line_buffer(
    input clk,
    input rst_n,

    // Send a pulse to switch ping-pong buffer when a CTU is complete
    input  logic        lb_switch,
    input  logic [11:0] lb_waddr,
    input  logic [7:0]  lb_din,
    input  logic        lb_we,
    input  logic [11:0] lb_raddr,
    output logic [7:0]  lb_dout,
    input  logic        lb_re
);

// 0: mem0 for write, mem1 for read
// 1: mem1 for write, mem0 for read
logic        lb_pingpong;
logic [11:0] lb_mem0_waddr, lb_mem1_waddr;
logic [11:0] lb_mem0_raddr, lb_mem1_raddr;
logic [7:0]  lb_mem0_wdata, lb_mem1_wdata;
logic [7:0]  lb_mem0_rdata, lb_mem1_rdata;
logic        lb_mem0_we, lb_mem1_we;
logic        lb_mem0_re, lb_mem1_re;

always_ff @(posedge clk)
    if(!rst_n)
        lb_pingpong <= 0;
    else if(lb_switch)
        lb_pingpong <= ~lb_pingpong;
assign lb_mem0_waddr = lb_waddr;
assign lb_mem1_waddr = lb_waddr;
assign lb_mem0_raddr = lb_raddr;
assign lb_mem1_raddr = lb_raddr;
assign lb_mem0_wdata = lb_din;
assign lb_mem1_wdata = lb_din;
assign lb_dout = lb_pingpong ? lb_mem0_rdata : lb_mem1_rdata;
assign lb_mem0_we = lb_pingpong ? 0 : lb_we;
assign lb_mem1_we = lb_pingpong ? lb_we : 0;
assign lb_mem0_re = lb_pingpong ? lb_re : 0;
assign lb_mem1_re = lb_pingpong ? 0 : lb_re;

basic_ram #(
    .ADDR_SIZE(12),
    .DATA_SIZE(8)
) lb_mem0
(
    .clk,
    .wea   (lb_mem0_we),
    .reb   (lb_mem0_re),
    .addra (lb_mem0_waddr),
    .addrb (lb_mem0_raddr),
    .dina  (lb_mem0_wdata),
    .doutb (lb_mem0_rdata)
);

basic_ram #(
    .ADDR_SIZE(12),
    .DATA_SIZE(8)
) lb_mem1
(
    .clk,
    .wea   (lb_mem1_we),
    .reb   (lb_mem1_re),
    .addra (lb_mem1_waddr),
    .addrb (lb_mem1_raddr),
    .dina  (lb_mem1_wdata),
    .doutb (lb_mem1_rdata)
);

endmodule
