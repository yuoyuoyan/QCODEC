//
// Note that Tiles, subset, palette mode, tu_residual_act are not used
// Fix the ChromaArrayType to 420 for now
// Max supporting frame size is 4096x2048, which has 64x32 CTUs
module qdec_ctx_fsm 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    // control register from top-level
    input  logic       cabac_start,
    input  t_CABAC_AO_s reg_allout,

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

    // line buffer interface
    output logic [11:0]lb_waddr,
    output logic [7:0] lb_din,
    output logic       lb_we,

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
// control register details
logic       slice_sao_luma_flag;
logic       slice_sao_chroma_flag;
logic       transquant_bypass_enabled_flag;
logic [1:0] slice_type;
logic [5:0] qp;
logic [11:0]widthByPix; // real value minus 1
logic [10:0]heightByPix; // one CTU is 64x64

t_state_ctx state, nxt_state;

assign slice_sao_luma_flag = reg_allout.reg_CABAC_SLICE_HEADER_0.slice_sao_luma_flag;
assign slice_sao_chroma_flag = reg_allout.reg_CABAC_SLICE_HEADER_0.slice_sao_chroma_flag;
assign transquant_bypass_enabled_flag = reg_allout.reg_CABAC_PPS_0.transformSkipEnabledFlag;
assign slice_type = reg_allout.reg_CABAC_SLICE_HEADER_0.slice_type;
assign qp = reg_allout.reg_CABAC_PPS_0.initQp + reg_allout.reg_CABAC_SLICE_HEADER_0.slice_qp_delta;
assign widthByPix = reg_allout.reg_CABAC_SPS_0.widthByPix;
assign heightByPix = reg_allout.reg_CABAC_SPS_0.heightByPix;

always_comb
    case(state)
    IDLE_CTX:                nxt_state = cabac_start===1'b1 ? CTX_INIT_CTX : IDLE_CTX;
    CTX_INIT_CTX:            nxt_state = ctx_init_done===1'b1 ? CALC_COR_CTX : CTX_INIT_CTX;
    CALC_COR_CTX:            nxt_state = (slice_sao_luma_flag | slice_sao_chroma_flag)===1'b1 ? SAO_CTX : CQT_CTX;
    SAO_CTX:                 nxt_state = sao_done===1'b1 ? CQT_CTX : SAO_CTX;
    CQT_CTX:                 nxt_state = cqt_done===1'b1 ? EOS_FLAG_CTX : CQT_CTX;
    EOS_FLAG_CTX:            nxt_state = dec_done===1'b1 ? ADDR_INC_CTX : EOS_FLAG_CTX;
    ADDR_INC_CTX:            nxt_state = end_of_slice_segment_flag===1'b1 ? RBSP_STOP_ONE_BIT_CTX : CALC_COR_CTX;
    RBSP_STOP_ONE_BIT_CTX:   nxt_state = dec_done===1'b1 ? (dec_result_correct===1'b1 ? RBSP_ALIGNMENT_ZERO_BITS : ERROR_CTX) : RBSP_STOP_ONE_BIT_CTX;
    RBSP_ALIGNMENT_ZERO_BITS: nxt_state = dec_done===1'b1 ? (dec_result_correct===1'b1 ? ENDING_CTX : ERROR_CTX) : RBSP_ALIGNMENT_ZERO_BITS;
    ERROR_CTX:               nxt_state = ERROR_CTX;
    ENDING_CTX:              nxt_state = IDLE_CTX;
    default:                  nxt_state = IDLE_CTX;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_CTX;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) error_intr <= (state == ERROR_CTX)  ? 1 : 0;
always_ff @(posedge clk) done_intr  <= (state == ENDING_CTX) ? 1 : 0;
always_ff @(posedge clk) ctu_done_intr  <= cqt_done_intr;

// Main FSM control signals
always_ff @(posedge clk)
    if(!rst_n) sao_done <= 0;
    else if(state == SAO_CTX & sao_done_intr) sao_done <= 1;
    else if(state == CQT_CTX) sao_done <= 0;

always_ff @(posedge clk)
    if(!rst_n) cqt_done <= 0;
    else if(state == CQT_CTX & cqt_done_intr) cqt_done <= 1;
    else if(state == EOS_FLAG_CTX) cqt_done <= 0;

always_ff @(posedge clk)
    if(state == EOS_FLAG_CTX) dec_done <= ruiBin_vld;
    else if(state == RBSP_STOP_ONE_BIT_CTX) dec_done <= ruiBin_vld;
    else if(state == RBSP_ALIGNMENT_ZERO_BITS) dec_done <= ruiBin_vld & ruiBin_bytealign;
    else dec_done <= 0;

always_ff @(posedge clk)
    if(state == RBSP_STOP_ONE_BIT_CTX) dec_result_correct <= ruiBin_vld ? ruiBin : dec_result_correct; // flag 1 is correct
    else if(state == RBSP_ALIGNMENT_ZERO_BITS) dec_result_correct <= ruiBin_vld & ruiBin ? 0 : dec_result_correct; // keeps 0 is correct
    else dec_result_correct <= 1;

always_ff @(posedge clk)
    if(!rst_n) end_of_slice_segment_flag <= 0;
    else if(state == EOS_FLAG_CTX) end_of_slice_segment_flag <= ruiBin_vld ? ruiBin : end_of_slice_segment_flag;

logic state_init_d;
always_ff @(posedge clk) state_init_d <= (state == CTX_INIT_CTX) ? 1'b1 : 1'b0;
always_ff @(posedge clk) ctx_init_start <= (state == CTX_INIT_CTX && !state_init_d) ? 1'b1 : 1'b0;

// context memory access control
always_ff @(posedge clk)
    case(state)
    CTX_INIT_CTX: ctx_addr <= ctx_init_addr;
    SAO_CTX:      ctx_addr <= ctx_sao_addr;
    CQT_CTX:      ctx_addr <= ctx_cqt_addr;
    default:       ctx_addr <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    CTX_INIT_CTX: ctx_wdata <= ctx_init_wdata;
    SAO_CTX:      ctx_wdata <= ctxStateUpdate;
    CQT_CTX:      ctx_wdata <= ctxStateUpdate;
    default:       ctx_wdata <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    CTX_INIT_CTX: ctx_we <= ctx_init_we;
    SAO_CTX:      ctx_we <= ctxStateUpdate_vld & ctxStateUpdate_rdy;
    CQT_CTX:      ctx_we <= ctxStateUpdate_vld & ctxStateUpdate_rdy;
    default:       ctx_we <= 0;
    endcase

always_ff @(posedge clk)
    case(state)
    CTX_INIT_CTX: ctx_re <= 0;
    SAO_CTX:      ctx_re <= 1;
    CQT_CTX:      ctx_re <= 1;
    default:       ctx_re <= 0;
    endcase

// Other output signal control
always_ff @(posedge clk)
    case(state)
    SAO_CTX:      EPMode <= EPMode_sao;
    CQT_CTX:      EPMode <= EPMode_cqt;
    EOS_FLAG_CTX: EPMode <= 1;
    default:       EPMode <= 0;
    endcase

always_ff @(posedge clk)
    arithInit <= (state == CTX_INIT_CTX) ? 1 : 0;

logic [1:0] ctx_sao_addr_vld_d;
logic [1:0] ctx_cqt_addr_vld_d;
always_ff @(posedge clk) ctx_sao_addr_vld_d <= {ctx_sao_addr_vld_d[0], ctx_sao_addr_vld};
always_ff @(posedge clk) ctx_cqt_addr_vld_d <= {ctx_cqt_addr_vld_d[0], ctx_cqt_addr_vld};
always_ff @(posedge clk)
    if(!rst_n) ctxState_vld <= 0;
    else
        case(state)
        SAO_CTX: ctxState_vld <= ctx_sao_addr_vld_d[1];
        CQT_CTX: ctxState_vld <= ctx_cqt_addr_vld_d[1];
        default:  ctxState_vld <= 0;
        endcase

always_ff @(posedge clk)
    case(state)
    SAO_CTX: {ctxState, mps} <= (ctx_sao_addr_vld_d[1]) ? ctx_rdata : {ctxState, mps};
    CQT_CTX: {ctxState, mps} <= (ctx_cqt_addr_vld_d[1]) ? ctx_rdata : {ctxState, mps};
    default:  {ctxState, mps} <= 0;
    endcase

assign ctxStateUpdate_rdy = 1'b1;

always_ff @(posedge clk)
    if(!rst_n) dec_run <= 0;
    else
        case(state)
        SAO_CTX:      dec_run <= dec_run_sao;
        CQT_CTX:      dec_run <= dec_run_cqt;
        EOS_FLAG_CTX: dec_run <= 1;
        default:       dec_run <= 0;
        endcase

always_ff @(posedge clk) sao_start <= (state == SAO_CTX) ? 1 : 0;
always_ff @(posedge clk) cqt_start <= (state == CQT_CTX) ? 1 : 0;

always_ff @(posedge clk)
    case(state)
    IDLE_CTX:     xCTB <= 6'h0;
    ADDR_INC_CTX: xCTB <= (xCTB == widthByPix[11:6]) ? 0 : xCTB + 6'h1;
    default:       xCTB <= xCTB;
    endcase

always_ff @(posedge clk)
    case(state)
    IDLE_CTX:     yCTB <= 5'h0;
    ADDR_INC_CTX: yCTB <= (xCTB == widthByPix[11:6]) ? yCTB + 5'h1 : yCTB;
    default:       yCTB <= yCTB;
    endcase

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
