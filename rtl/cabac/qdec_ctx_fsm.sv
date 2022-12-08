//
// Note that Tiles, subset, palette mode, tu_residual_act are not used
// Fix the ChromaArrayType to 420 for now
// Max supporting frame size is 4096x2048, which has 64x32 CTUs
module qdec_ctx_fsm import qdec_cabac_package::*;(
    input clk,
    input rst_n,

    // control register from top-level
    input  t_CUTREE_AO_s reg_all,
    input  logic       cabac_start_1frame,
    input  logic       cabac_init_ctx,
    input  logic       cabac_init_flag,
    input  logic       slice_sao_luma_flag,
    input  logic       slice_sao_chroma_flag,
    input  logic       transquant_bypass_enabled_flag,
    input  logic [1:0] slice_type,
    input  logic [5:0] qp,
    input  logic [11:0]widthByPix, // real value minus 1
    input  logic [10:0]heightByPix, // one CTU is 64x64

    // feedback to top level
    output logic       error_intr,
    output logic       done_intr,
    output logic       ctu_done_intr,

    // ctx memory interface
    output logic [9:0] ctx_addr,
    output logic [7:0] ctx_wdata,
    input  logic [7:0] ctx_rdata,
    output logic       ctx_we,
    output logic       ctx_re,

    // arith decoder interface, need to handle state R/W bypass
    output logic       EPMode,
    output logic       mps,
    output logic       arithInit,
    output logic [6:0] ctxState,
    output logic       ctxState_vld,
    input  logic       ctxState_rdy,
    input  logic [6:0] ctxStateUpdate,
    input  logic       ctxStateUpdate_vld,
    output logic       ctxStateUpdate_rdy,
    output logic       dec_run,
    input  logic       dec_rdy,

    // Arith decoder feedback to FSM, sometimes need to check the decode result
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    input  logic       ruiBin_bytealign
);

// All signals controlling main fsm
logic [11:0] CtbAddrInRs; // CTB index in raster order scan in a frame
logic [11:0] CtbAddrInTs; // CTB index in Tile scan
logic [5:0]  xCtb;
logic [4:0]  yCtb;
logic [9:0]  ctx_init_addr, ctx_sao_addr, ctx_cqt_addr;
logic [6:0]  ctx_init_wdata;
logic        ctx_init_we, ctx_sao_addr_vld, ctx_cqt_addr_vld;
logic        end_of_slice_segment_flag;
logic        ctx_init_start;
logic        sao_done_intr, cqt_done_intr, ctx_init_done_intr;
logic        sao_done, cqt_done, dec_done;
logic        dec_run_sao, dec_run_cqt;
logic        sao_start, cqt_start;
logic        EPMode_sao, EPMode_cqt;
logic        ctx_init_done;
logic        dec_result_correct;
logic [5:0]  xCTB;
logic [4:0]  yCTB;

t_state_main state, nxt_state;

always_comb
    case(state)
    IDLE_MAIN:                nxt_state = cabac_start_1frame ? CALC_COR_MAIN : (cabac_init_ctx ? CTX_INIT_MAIN : IDLE_MAIN);
    CTX_INIT_MAIN:            nxt_state = ctx_init_done ? ENDING_MAIN : CTX_INIT_MAIN;
    CALC_COR_MAIN:            nxt_state = (slice_sao_luma_flag | slice_sao_chroma_flag) ? SAO_MAIN : CQT_MAIN;
    SAO_MAIN:                 nxt_state = sao_done ? CQT_MAIN : SAO_MAIN;
    CQT_MAIN:                 nxt_state = cqt_done ? EOS_FLAG_MAIN : CQT_MAIN;
    EOS_FLAG_MAIN:            nxt_state = dec_done ? ADDR_INC_MAIN : EOS_FLAG_MAIN;
    ADDR_INC_MAIN:            nxt_state = end_of_slice_segment_flag ? RBSP_STOP_ONE_BIT_MAIN : CALC_COR_MAIN;
    RBSP_STOP_ONE_BIT_MAIN:   nxt_state = dec_done ? (dec_result_correct ? RBSP_ALIGNMENT_ZERO_BITS : ERROR_MAIN) : RBSP_STOP_ONE_BIT_MAIN;
    RBSP_ALIGNMENT_ZERO_BITS: nxt_state = dec_done ? (dec_result_correct ? ENDING_MAIN : ERROR_MAIN) : RBSP_ALIGNMENT_ZERO_BITS;
    ERROR_MAIN:               nxt_state = ERROR_MAIN;
    ENDING_MAIN:              nxt_state = IDLE_MAIN;
    default:                  nxt_state = IDLE_MAIN;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_MAIN;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) error_intr <= (state == ERROR_MAIN)  ? 1 : 0;
always_ff @(posedge clk) done_intr  <= (state == ENDING_MAIN) ? 1 : 0;
always_ff @(posedge clk) ctu_done_intr  <= cqt_done_intr;

// Main FSM control signals
always_ff @(posedge clk)
    if(!rst_n) sao_done <= 0;
    else if(state == SAO_MAIN & sao_done_intr) sao_done <= 1;
    else if(state == CQT_MAIN) sao_done <= 0;

always_ff @(posedge clk)
    if(!rst_n) cqt_done <= 0;
    else if(state == CQT_MAIN & cqt_done_intr) cqt_done <= 1;
    else if(state == EOS_FLAG_MAIN) cqt_done <= 0;

always_ff @(posedge clk)
    if(state == EOS_FLAG_MAIN) dec_done <= ruiBin_vld;
    else if(state == RBSP_STOP_ONE_BIT_MAIN) dec_done <= ruiBin_vld;
    else if(state == RBSP_ALIGNMENT_ZERO_BITS) dec_done <= ruiBin_vld & ruiBin_bytealign;
    else dec_done <= 0;

always_ff @(posedge clk)
    if(state == RBSP_STOP_ONE_BIT_MAIN) dec_result_correct <= ruiBin_vld ? ruiBin : dec_result_correct; // flag 1 is correct
    else if(state == RBSP_ALIGNMENT_ZERO_BITS) dec_result_correct <= ruiBin_vld & ruiBin ? 0 : dec_result_correct; // keeps 0 is correct
    else dec_result_correct <= 1;

always_ff @(posedge clk)
    if(!rst_n) end_of_slice_segment_flag <= 0;
    else if(state == EOS_FLAG_MAIN) end_of_slice_segment_flag <= ruiBin_vld ? ruiBin : end_of_slice_segment_flag;

// context memory access control
always_ff @(posedge clk)
    case(state)
    CTX_INIT_MAIN: ctx_addr <= ctx_init_addr;
    SAO_MAIN:      ctx_addr <= ctx_sao_addr;
    CQT_MAIN:      ctx_addr <= ctx_cqt_addr;
    default:       ctx_addr <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    CTX_INIT_MAIN: ctx_wdata <= ctx_init_wdata;
    SAO_MAIN:      ctx_wdata <= ctxStateUpdate;
    CQT_MAIN:      ctx_wdata <= ctxStateUpdate;
    default:       ctx_wdata <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    CTX_INIT_MAIN: ctx_we <= ctx_init_we;
    SAO_MAIN:      ctx_we <= ctxStateUpdate_vld & ctxStateUpdate_rdy;
    CQT_MAIN:      ctx_we <= ctxStateUpdate_vld & ctxStateUpdate_rdy;
    default:       ctx_we <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    CTX_INIT_MAIN: ctx_re <= 0;
    SAO_MAIN:      ctx_re <= 1;
    CQT_MAIN:      ctx_re <= 1;
    default:       ctx_re <= 0;
    endcase

// Other output signal control
always_ff @(posedge clk)
    case(state)
    SAO_MAIN:      EPMode <= EPMode_sao;
    CQT_MAIN:      EPMode <= EPMode_cqt;
    EOS_FLAG_MAIN: EPMode <= 1;
    default:       EPMode <= 0;
    endcase

always_ff @(posedge clk)
    arithInit <= (state == CTX_INIT_MAIN) ? 1 : 0;

logic [1:0] ctx_sao_addr_vld_d;
logic [1:0] ctx_cqt_addr_vld_d;
always_ff @(posedge clk) ctx_sao_addr_vld_d <= {ctx_sao_addr_vld_d[0], ctx_sao_addr_vld};
always_ff @(posedge clk) ctx_cqt_addr_vld_d <= {ctx_cqt_addr_vld_d[0], ctx_cqt_addr_vld};
always_ff @(posedge clk)
    if(!rst_n) ctxState_vld <= 0;
    else
        case(state)
        SAO_MAIN: ctxState_vld <= ctx_sao_addr_vld_d[1];
        CQT_MAIN: ctxState_vld <= ctx_cqt_addr_vld_d[1];
        default:  ctxState_vld <= 0;
        endcase

always_ff @(posedge clk)
    case(state)
    SAO_MAIN: {ctxState, mps} <= (ctx_sao_addr_vld_d[1]) ? ctx_rdata : {ctxState, mps};
    CQT_MAIN: {ctxState, mps} <= (ctx_cqt_addr_vld_d[1]) ? ctx_rdata : {ctxState, mps};
    default:  {ctxState, mps} <= 0;
    endcase

assign ctxStateUpdate_rdy = 1'b1;

always_ff @(posedge clk)
    if(!rst_n) dec_run <= 0;
    else
        case(state)
        SAO_MAIN:      dec_run <= dec_run_sao;
        CQT_MAIN:      dec_run <= dec_run_cqt;
        EOS_FLAG_MAIN: dec_run <= 1;
        default:       dec_run <= 0;
        endcase

always_ff @(posedge clk) sao_start <= (state == SAO_MAIN) ? 1 : 0;
always_ff @(posedge clk) cqt_start <= (state == CQT_MAIN) ? 1 : 0;

always_ff @(posedge clk)
    case(state)
    IDLE_MAIN:     xCTB <= 6'h0;
    ADDR_INC_MAIN: xCTB <= (xCTB == widthByPix[11:6]) ? 0 : xCTB + 6'h1;
    default:       xCTB <= xCTB;
    endcase

always_ff @(posedge clk)
    case(state)
    IDLE_MAIN:     yCTB <= 5'h0;
    ADDR_INC_MAIN: yCTB <= (xCTB == widthByPix[11:6]) ? yCTB + 5'h1 : yCTB;
    default:       yCTB <= yCTB;
    endcase

// basic_fifo #(
//     .DATA_WIDTH(8),
//     .ADDR_WIDTH(8),
//     .DATA_DEPTH(256)
// ) ctx_rdreq_fifo
// (
//     .clk,
//     .rst_n,

//     .din      (),
//     .din_vld  (),
//     .din_rdy  (),

//     .dout     (ctxState),
//     .dout_vld (ctx_we),
//     .dout_rdy (1'b1)
// );

// Sub FSMs
qdec_ctx_init ctx_init(
    .clk,
    .rst_n,

    .ctx_init_start,
    .qp,

    .ctx_init_addr,
    .ctx_init_wdata,
    .ctx_init_we,
    .ctx_init_done_intr
);

qdec_sao_fsm sao_fsm(
    .clk,
    .rst_n,

    .sao_start,
    .xCTB,
    .yCTB,
    .slice_sao_luma_flag,
    .slice_sao_chroma_flag,

    .ctx_sao_addr,
    .ctx_sao_addr_vld,
    .dec_run_sao,
    .dec_rdy,
    .EPMode_sao,
    .ruiBin,
    .ruiBin_vld,
    .sao_done_intr
);

qdec_cqt_fsm cqt_fsm(
    .clk,
    .rst_n,

    .cqt_start,
    .xCTB,
    .yCTB,
    .widthByPix,
    .heightByPix,
    .slice_type,
    .transquant_bypass_enabled_flag,

    .ctx_cqt_addr,
    .ctx_cqt_addr_vld,
    .dec_run_cqt,
    .dec_rdy,
    .EPMode_cqt,
    .ruiBin,
    .ruiBin_vld,
    .cqt_done_intr
);

endmodule
