// Author: Qi Wang
// Top level of CABAC

module qdec_cabac 
`ifndef IVERILOG
import qdec_cabac_package::*; import qdec_axi_pkg::*; 
`endif
(
    input clk,
    input rst_n,

    // control register interface
    input  t_reg_req_s      reg_req,
    output t_reg_resp_s     reg_resp,

    // bitstream fetching interface to RAM from outside
    input  logic [7:0]  bitstreamFetch,
    input  logic        bitstreamFetch_vld,
    output logic        bitstreamFetch_rdy,

    // feedback to top level
    output logic       error_intr,
    output logic       done_intr,
    output logic       ctu_done_intr,

    // Decoded CTU syntax for later modules to read
    input  logic [11:0] lb_raddr,
    output logic [7:0]  lb_dout,
    input  logic        lb_re
);

logic        cabac_start;
t_CABAC_AO_s  reg_allout;
// decapsule flow and all param set decoding
t_reg_req_s      reg_req_merge, reg_req_main;
logic [7:0]  bitstreamFetch_decap;
logic        bitstreamFetch_decap_vld;
logic        bitstreamFetch_decap_rdy;
// decoded Bins from arith_dec to debin
logic        ruiBin;
logic        ruiBin_vld;
logic        ruiBin_rdy;
logic        ruiBin_bytealign;
// arith decoder interface between FSM and arith_dec, need to handle state R/W bypass
logic        EPMode;
logic        mps;
logic        arithInit;
logic [6:0]  ctxState;
logic        ctxState_vld;
logic        ctxState_rdy;
logic [6:0]  ctxStateUpdate;
logic        ctxStateUpdate_vld;
logic        ctxStateUpdate_rdy;
logic        dec_run;
logic        dec_rdy;
// ctx state RAM interface between FSM and ctx_mem
logic [9:0]  ctx_addr;
logic [7:0]  ctx_wdata, ctx_rdata;
logic        ctx_we, ctx_re;
logic [11:0] lb_waddr;
logic [7:0]  lb_din;
logic        lb_we;

// control register
qdec_cabac_register cabac_reg(
    .clk,
    .rst_n,

    .cabac_start,
    .reg_allout,

    .reg_req (reg_req_merge),
    .reg_resp
);

// AXIs merging
axi_merge axi_merge(
    .clk,
    .rst_n,

    .reg_req_out(reg_req_merge),
    .reg_req_in1(reg_req),
    .reg_req_in2(reg_req_main)
);

// core fsm to decap and read all params
qdec_main_fsm main_fsm(
    .clk,
    .rst_n,

    // interface to control reg
    .reg_req (reg_req_main),

    // decapsule flow
    .bitstreamFetch,
    .bitstreamFetch_vld,
    .bitstreamFetch_rdy,
    .bitstreamFetch_decap,
    .bitstreamFetch_decap_vld,
    .bitstreamFetch_decap_rdy,
);

// ctx fsm to control arithmatic decoder
qdec_ctx_fsm ctx_fsm(
    .clk,
    .rst_n,

    // feedback to top level
    .error_intr,
    .done_intr,
    .ctu_done_intr,

    // control registers
    .cabac_start,
    .reg_allout,

    // ctx memory interface
    .ctx_addr,
    .ctx_wdata,
    .ctx_rdata,
    .ctx_we,
    .ctx_re,

    // line buffer interface
    .lb_waddr,
    .lb_din,
    .lb_we,

    // arith decoder interface, need to handle state R/W bypass
    .EPMode,
    .mps,
    .arithInit,
    .ctxState,
    .ctxState_vld,
    .ctxState_rdy,
    .ctxStateUpdate,
    .ctxStateUpdate_vld,
    .ctxStateUpdate_rdy,
    .dec_run,
    .dec_rdy,

    // Arith decoder feedback to FSM, sometimes need to check the decode result
    .ruiBin,
    .ruiBin_vld,
    .ruiBin_bytealign
);

// context memory, store all the arithemetic model probability
// input:  updated probability from arithmetic decoder
//         initialized probability from context fsm
// output: propability to arithmetic decoder
qdec_ctx_mem ctx_mem(
    .clk,

    // ctx memory interface
    .ctx_addr,
    .ctx_wdata,
    .ctx_rdata,
    .ctx_we,
    .ctx_re
);

// arithmetic decoder, decode bitstream basec on arithemetic model
// input:  bitstream from outside
//         probability from context memory
// output: bin to de-binarization
//         updated probability to context memory
qdec_Arith_decoder Arith_decoder(
    .clk,
    .rst_n,

    // Contex value interface with context memory or FSM
    .EPMode, // equal posibility, bypass mode
    .mps,
    .arithInit, // A pulse to initialize the arithmetic state
    .ctxState,
    .ctxState_vld,
    .ctxState_rdy,
    .ctxStateUpdate,
    .ctxStateUpdate_vld,
    .ctxStateUpdate_rdy,
    .dec_run, // module above should pull up dec_run only when the dec_rdy is high
    .dec_rdy, // indicate the ping-pong buffer have byte to decode

    // bitstream fetch interface
    .bitstreamFetch     (bitstreamFetch_decap    ),
    .bitstreamFetch_vld (bitstreamFetch_decap_vld),
    .bitstreamFetch_rdy (bitstreamFetch_decap_rdy),

    // decoded bin to de-binarization
    .ruiBin,
    .ruiBin_vld,
    .ruiBin_rdy,
    .ruiBin_bytealign
);

// line buffer to store control info from outside, and the decoded syntax for outside to read
qdec_line_buffer line_buffer(
    .clk,
    .rst_n,

    // Send a pulse to switch ping-pong buffer when a CTU is complete
    .lb_switch (ctu_done_intr),
    .lb_waddr,
    .lb_din,
    .lb_we,
    .lb_raddr,
    .lb_dout,
    .lb_re
);

endmodule
