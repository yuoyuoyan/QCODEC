//
module qdec_cabac(
    input clk,
    input rst_n,

    // bitstream fetching interface to RAM from outside
    input  logic [7:0]  bitstreamFetch,
    input  logic        bitstreamFetch_vld,
    output logic        bitstreamFetch_rdy,
);

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
logic [7:0]  ctx_wdata,m ctx_rdata;
logic        ctx_we, ctx_re;

// core fsm to control cabac decoder
qdec_ctx_fsm ctx_fsm(
    .clk,
    .rst_n,

    // ctx memory interface
    .ctx_addr,
    .ctx_wdata,
    .ctx_rdata,
    .ctx_we,
    .ctx_re,

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
    .ctx_re,
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
    .bitstreamFetch,
    .bitstreamFetch_vld,
    .bitstreamFetch_rdy,

    // decoded bin to de-binarization
    .ruiBin,
    .ruiBin_vld,
    .ruiBin_rdy,
    .ruiBin_bytealign
);

// line buffer to store control info from outside, and the decoded syntax for outside to read
qdec_line_buffer line_buffer(
    .clk,
    .rst_n
);

endmodule
