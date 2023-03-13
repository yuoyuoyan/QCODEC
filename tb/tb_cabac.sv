`timescale 1ns/1ns

module tb_cabac;

`ifndef IVERILOG
import qdec_axi_pkg::*;
import qdec_cabac_package::*;
`endif

logic clk, rst_n;
t_reg_req_s      reg_req;
t_reg_resp_s     reg_resp;
logic [7:0]  bitstreamFetch;
logic        bitstreamFetch_vld;
logic        bitstreamFetch_rdy;
logic [7:0]  din;
logic        din_vld;
logic        error_intr;
logic        done_intr;
logic        ctu_done_intr;
logic [11:0] lb_raddr;
logic [7:0]  lb_dout;
logic        lb_re;
logic        data_init_done, frame_started;

`include "mem_load.sv"
`include "reg_rw.sv"

// clock, reset, finish and waveform dumping
initial begin
    // $vcdplusfile("./vcdplus.vpd");
    // $vcdpluson();
    // $vcdplusmemon();
`ifdef IVERILOG
    $dumpfile("cabac_waveform.vcd");
    $dumpvars(0, cabac);
`endif
    clk = 1'b0;
    rst_n = 1'b1;
    
    // Reset for 1us
    #100 
    rst_n = 1'b0;
    #1000
    rst_n = 1'b1;
    // $vcdplusoff();
    @(posedge frame_started);
    #100000
    $finish();
end

// Generate 100MHz clock signal
always #5 clk <= ~clk;

// control register writing
logic [3:0]    vps_id;
logic [11:0]   widthByPix;
logic [11:0]   heightByPix;
logic [3:0]    sps_id;
logic [0:0]    PcmEnabledFlag;
logic [0:0]    SaoEnabledFlag;
logic [0:0]    ampEnabledFlag;
logic [3:0]    MaxTrafoDepthIntra;
logic [3:0]    MaxTrafoDepthInter;
logic [3:0]    log2DiffMaxMinTbSize;
logic [3:0]    log2MinTbSize;
logic [3:0]    log2DiffMaxMinLumaCbSize;
logic [3:0]    log2MinCbSize;
logic [7:0]    initQp;
logic [3:0]    numRefL0;
logic [3:0]    numRefL1;
logic [0:0]    cuQpDeltaEnabledFlag;
logic [0:0]    transformSkipEnabledFlag;
logic [0:0]    cabacInitPresentFlag;
logic [0:0]    signDataHidingFlag;
logic [3:0]    pps_id;
logic [7:0]    slice_qp_delta;
logic [0:0]    rsvd1;
logic [2:0]    max_num_merge_cand;
logic [0:0]    slice_sao_luma_flag;
logic [0:0]    slice_sao_chroma_flag;
logic [1:0]    slice_type;
logic [31:0]   rdata;
initial begin
    @(posedge rst_n);
    @(posedge clk);
    @(posedge frame_started);
    vps_id = 0;
    widthByPix = 831;
    heightByPix = 479;
    sps_id = 0;
    PcmEnabledFlag = 0;
    SaoEnabledFlag = 1;
    ampEnabledFlag = 0;
    MaxTrafoDepthIntra = 0;
    MaxTrafoDepthInter = 0;
    log2DiffMaxMinTbSize = 3;
    log2MinTbSize = 2;
    log2DiffMaxMinLumaCbSize = 3;
    log2MinCbSize = 3;
    initQp = 26;
    numRefL0 = 4;
    numRefL1 = 2;
    cuQpDeltaEnabledFlag = 1;
    transformSkipEnabledFlag = 0;
    cabacInitPresentFlag = 0;
    signDataHidingFlag = 1;
    pps_id = 0;
    slice_qp_delta = 25;
    max_num_merge_cand = 4;
    slice_sao_luma_flag = 1;
    slice_sao_chroma_flag = 1;
    slice_type = 2;
    reg_write(ADDR_CABAC_VPS_0, {28'h0, vps_id});
    reg_write(ADDR_CABAC_SPS_0, {4'h0, widthByPix, heightByPix, sps_id});
    reg_write(ADDR_CABAC_SPS_1, {5'h0, PcmEnabledFlag, SaoEnabledFlag, ampEnabledFlag, 
                                                    MaxTrafoDepthIntra, MaxTrafoDepthInter, log2DiffMaxMinTbSize, 
                                                    log2MinTbSize, log2DiffMaxMinLumaCbSize, log2MinCbSize});
    reg_write(ADDR_CABAC_PPS_0, {8'h0, initQp, numRefL0, numRefL1, cuQpDeltaEnabledFlag, 
                                                    transformSkipEnabledFlag, cabacInitPresentFlag, signDataHidingFlag, pps_id});
    reg_write(ADDR_CABAC_SLICE_HEADER_0, {16'h0, slice_qp_delta, 1'b0, max_num_merge_cand, slice_sao_luma_flag, 
                                                             slice_sao_chroma_flag, slice_type});
    reg_read(ADDR_CABAC_VPS_0, rdata);
    reg_read(ADDR_CABAC_SPS_0, rdata);
    reg_read(ADDR_CABAC_SPS_1, rdata);
    reg_read(ADDR_CABAC_PPS_0, rdata);
    reg_read(ADDR_CABAC_SLICE_HEADER_0, rdata);
    // write hw start to cabac
    reg_write(ADDR_CABAC_START, 32'h1);
    $display("CABAC started\n");
end

// bitstream loading
initial begin
    @(posedge rst_n);
    @(posedge clk);
    mem_load(din, din_vld);
end

basic_fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(16),
    .DATA_DEPTH(65536)
) bitstream_fifo
(
    .clk,
    .rst_n,

    .din     (din),
    .din_vld (din_vld),
    .din_rdy (),

    .dout     (bitstreamFetch),
    .dout_vld (bitstreamFetch_vld),
    .dout_rdy (bitstreamFetch_rdy)
);

// module instant
qdec_cabac cabac(
    .clk,
    .rst_n,

    // control register interface
    .reg_req, 
    .reg_resp,

    // bitstream fetching interface to RAM from outside
    .bitstreamFetch,
    .bitstreamFetch_vld,
    .bitstreamFetch_rdy,

    // feedback to top level
    .error_intr,
    .done_intr,
    .ctu_done_intr,

    // Decoded CTU syntax for later modules to read
    .lb_raddr,
    .lb_dout,
    .lb_re
);

endmodule
