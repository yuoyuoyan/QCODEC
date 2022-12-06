// QDEC arithmetic decoder
// Author:      Qi Wang
// Description: For normal mode, takes 4 cycles to have updated state and one decoded bin
//              For bypass mode, takes 1 cycle to have one decoded bin, no updated state
//              To initialize it, wait for dec_rdy to fetch some data, and send a arithInit pulse
module qdec_Arith_decoder import qdec_cabac_package::*; (
    input clk,
    input rst_n,

    // Contex value interface with context memory or FSM
    input  logic        EPMode, // equal posibility, bypass mode
    input  logic        mps,
    input  logic        arithInit, // A pulse to initialize the arithmetic state
    input  logic [5:0]  ctxState,
    input  logic        ctxState_vld,
    output logic        ctxState_rdy,
    output logic [5:0]  ctxStateUpdate,
    output logic        ctxStateUpdate_vld,
    input  logic        ctxStateUpdate_rdy,
    input  logic        dec_run, // module above should pull up dec_run only when the dec_rdy is high
    output logic        dec_rdy, // indicate the ping-pong buffer have byte to decode

    // bitstream fetch interface
    input  logic [7:0]  bitstreamFetch,
    input  logic        bitstreamFetch_vld,
    output logic        bitstreamFetch_rdy,

    // decoded bin to de-binarization
    output logic        ruiBin,
    output logic        ruiBin_vld,
    input  logic        ruiBin_rdy,
    output logic        ruiBin_bytealign
);

// Key registers
// L0
logic [7:0]  uiLPS;
logic [5:0]  nxtState_mps;
logic [5:0]  nxtState_lps;
logic [2:0]  numBits_lps;
// L1
logic [15:0] scaledRange;
logic [3:0]  bitsNeeded_mps;
logic [3:0]  bitsNeeded_lps;
// L2
logic [15:0] uiValue_tmp;
logic [8:0]  uiRange_lps;
logic [8:0]  uiRange_mps;
// L3
logic [15:0] uiValue;
logic [8:0]  uiRange;
logic [3:0]  bitsNeeded_plus1;
logic [3:0]  bitsNeeded;

// A pulse to indicate a byte is decoded, get a new byte from ping pong buffer
logic        byteDecodeComplete;
logic [1:0]  numByteInDecoder;
// 0 is ping ready to fetch, pong ready to be decoded; 1 is pong ready to fetch, ping is ready to be decoded
logic        bitstreamFetch_pingpong_flag;
logic [7:0]  bitstreamFetch_ping, bitstreamFetch_pong;
logic [7:0]  byteBeDecode;

// Bitstream ping-pong buffer
// Fetch while available
// Not affected by init signal
always_ff @(posedge clk)
    if(!rst_n) bitstreamFetch_pingpong_flag <= 0;
    else bitstreamFetch_pingpong_flag <= (bitstreamFetch_vld & bitstreamFetch_rdy) ? !bitstreamFetch_pingpong_flag : bitstreamFetch_pingpong_flag;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        bitstreamFetch_ping <= 0;
        bitstreamFetch_pong <= 0;
    end
    else if(bitstreamFetch_vld & bitstreamFetch_rdy) begin
        bitstreamFetch_ping <= bitstreamFetch_pingpong_flag ? bitstreamFetch_ping : bitstreamFetch;
        bitstreamFetch_pong <= bitstreamFetch_pingpong_flag ? bitstreamFetch : bitstreamFetch_pong;
    end
end

always_ff @(posedge clk)
    if(!rst_n) numByteInDecoder <= 0; // ping pong empty after reset, not affected by init
    else if(bitstreamFetch_vld & bitstreamFetch_rdy & !(byteDecodeComplete)) // fetch one from bitstream
        numByteInDecoder <= numByteInDecoder + 2'b01;
    else if(byteDecodeComplete & !(bitstreamFetch_vld & bitstreamFetch_rdy)) // complete one
        numByteInDecoder <= numByteInDecoder + 2'b11;
    else numByteInDecoder <= numByteInDecoder;

always_ff @(posedge clk)
    if(!rst_n) bitstreamFetch_rdy <= 0;
    else bitstreamFetch_rdy <= (numByteInDecoder == 2'b10) ? 0 : 1; // stop fetching only when ping pong buffer are not empty

always_ff @(posedge clk) dec_rdy <= (numByteInDecoder == 0) ? 0 : 1;
assign byteBeDecode = bitstreamFetch_pingpong_flag ? bitstreamFetch_ping : bitstreamFetch_pong;

// Phase control counter, totally 4 phases
logic [1:0]  phase_control;
always_ff @(posedge clk)
    if(!rst_n) phase_control <= 2'b00;
    else if(phase_control != 2'b00) phase_control <= phase_control + 2'b01;
    else phase_control <= (dec_run & (!EPMode) & ruiBin_rdy) ? 2'b01 : 2'b00;

always_ff @(posedge clk)
    if(!rst_n) ctxState_rdy <= 0;
    else if((phase_control == 2'b11) | arithInit) ctxState_rdy <= 1;
    else if((phase_control == 2'b00) & dec_run & ruiBin_rdy) ctxState_rdy <= 0;

// L0, calculate uiLPS, numBits_lps, nxtState_mps and nxtState_lps
// uiLPS = AUC_LPS_TABLE[state][uiRange[7:6]]
// numBits_lps = AUC_RENORM_TABLE[state][uiRange[7:6]]
// nxtState_mps = NXT_STATE_MPS[state]
// nxtState_lps = NXT_STATE_LPS[state]
always_ff @(posedge clk) uiLPS        <= (dec_run & ctxState_vld && phase_control == 2'b00) ? AUC_LPS_TABLE[ctxState][uiRange[7:6]] : uiLPS;
always_ff @(posedge clk) numBits_lps  <= (dec_run & ctxState_vld && phase_control == 2'b00) ? AUC_RENORM_TABLE[ctxState][uiRange[7:6]] : numBits_lps;
always_ff @(posedge clk) nxtState_mps <= (dec_run & ctxState_vld && phase_control == 2'b00) ? AUC_NXT_STATE_MPS[ctxState] : nxtState_mps;
always_ff @(posedge clk) nxtState_lps <= (dec_run & ctxState_vld && phase_control == 2'b00) ? AUC_NXT_STATE_LPS[ctxState] : nxtState_lps;

// L1, calculate scaledRange, bitsNeeded_lps and bitsNeeded_mps
// scaledRange = (uiRange-uiLPS) << 7
// bitsNeeded_mps = bitsNeeded + 1
// bitsNeeded_lps = bitsNeeded + numBits_lps
always_ff @(posedge clk) scaledRange    <= (phase_control == 2'b01) ? {(uiRange - uiLPS), 7'h0} : scaledRange;
always_ff @(posedge clk) bitsNeeded_mps <= (phase_control == 2'b01) ? bitsNeeded + 1 : bitsNeeded_lps;
always_ff @(posedge clk) bitsNeeded_lps <= (phase_control == 2'b01) ? bitsNeeded + numBits_lps : bitsNeeded_lps;

// L2, calculate uiValue_tmp, uiRange_lps and uiRange_mps
// uiValue_tmp = uiValue - scaledRange
// uiRange_lps = uiLPS << numBits_lps
// uiRange_mps = scaledRange >> 6
always_ff @(posedge clk) uiValue_tmp <= (phase_control == 2'b10) ? uiValue - scaledRange : uiValue_tmp;
always_ff @(posedge clk)
    if(phase_control == 2'b10)
        case(numBits_lps)
        3'h1    : uiRange_lps <= {uiLPS[7:0], 1'h0};
        3'h2    : uiRange_lps <= {uiLPS[6:0], 2'h0};
        3'h3    : uiRange_lps <= {uiLPS[5:0], 3'h0};
        3'h4    : uiRange_lps <= {uiLPS[4:0], 4'h0};
        3'h5    : uiRange_lps <= {uiLPS[3:0], 5'h0};
        3'h6    : uiRange_lps <= {uiLPS[2:0], 6'h0};
        default : uiRange_lps <= {uiLPS[7:0], 1'h0};
        endcase
    else uiRange_lps <= uiRange_lps;
always_ff @(posedge clk) uiRange_mps <= (phase_control == 2'b10) ? scaledRange[14:6];

// L3, calculate uiValue, uiRange, bitsNeeded, ruiBin, ruiBin_vld, ctxStateUpdate, ctxStateUpdate_vld, byteDecodeComplete
// Noted that uiRange, uiValue and bitsNeeded need to be initialized based on control
// uiValue            = uiValue_tmp[15] ? (bitsNeeded_mps[3] ? uiValue << 1 + byteBeDecode : (scaledRange[15] ? uiValue : uiValue << 1)) : 
//                                        (bitsNeeded_lps[3] ? uiValue_tmp << numBits_lps + byteBeDecode : uiValue_tmp << numBits_lps)
// uiRange            = uiValue_tmp[15] ? (scaledRange[15] ? uiRange : uiRange_mps) : uiRange_lps
// bitsNeeded         = uiValue_tmp[15] ? (scaledRange[15] ? bitsNeeded : {1'b0, bitsNeeded_mps[2:0]}) : {1'b0, bitsNeeded_lps[2:0]}
// ruiBin             = uiValue_tmp[15] ? mps : !mps;
// ruiBin_vld         = 1
// ctxStateUpdate     = uiValue_tmp[15] ? nxtState_mps : nxtState_lps
// ctxStateUpdate_vld = 1
// byteDecodeComplete = uiValue_tmp[15] ? (scaledRange[15] ? 0 : bitsNeeded_mps[3]) : bitsNeeded_lps[3]
//
// EP mode calculation are all done in this level, including uiValue, bitsNeeded, ruiBin and byteDecodeComplete
// uiValue            = ((uiValue<<1) < (uiRange<<7)) ? (uiVlue<<1) : (uiValue<<1) - (uiRange<<7)
// bitsNeeded         = (bitsNeeded+1)%8
// ruiBin             = (uiValue < (uiRange<<7)) ? 0 : 1
// byteDecodeComplete = (bitsNeeded+1)/8
always_ff @(posedge clk)
    if(!rst_n) uiValue <= 0;
    else if(arithInit) uiValue <= {byteBeDecode, byteBeDecode};
    else if(dec_run & EPMode)
        uiValue <= ({uiValue[14:0], 1'b0} < {uiRange, 7'h0}) ? {uiValue[14:0], 1'b0} : ({uiValue[14:0], 1'b0} - {uiRange, 7'h0});
    else if(phase_control == 2'b11) begin
        if(uiValue_tmp[15]) uiValue <= (bitsNeeded_mps[3] ? ({uiValue[14:0], 1'b0} + byteBeDecode) : (scaledRange[15] ? uiValue : {uiValue[14:0], 1'b0}) );
        else begin
            if(bitsNeeded_lps[3]) begin
                case(numBits_lps)
                3'h1    : uiValue <= {uiValue_tmp[14:0], 1'h0} + byteBeDecode;
                3'h2    : uiValue <= {uiValue_tmp[13:0], 2'h0} + byteBeDecode;
                3'h3    : uiValue <= {uiValue_tmp[12:0], 3'h0} + byteBeDecode;
                3'h4    : uiValue <= {uiValue_tmp[11:0], 4'h0} + byteBeDecode;
                3'h5    : uiValue <= {uiValue_tmp[10:0], 5'h0} + byteBeDecode;
                3'h6    : uiValue <= {uiValue_tmp[9:0],  6'h0} + byteBeDecode;
                default : uiValue <= {uiValue_tmp[14:0], 1'h0} + byteBeDecode;
                endcase
            end
            else begin
                case(numBits_lps)
                3'h1    : uiValue <= {uiValue_tmp[14:0], 1'h0};
                3'h2    : uiValue <= {uiValue_tmp[13:0], 2'h0};
                3'h3    : uiValue <= {uiValue_tmp[12:0], 3'h0};
                3'h4    : uiValue <= {uiValue_tmp[11:0], 4'h0};
                3'h5    : uiValue <= {uiValue_tmp[10:0], 5'h0};
                3'h6    : uiValue <= {uiValue_tmp[9:0],  6'h0};
                default : uiValue <= {uiValue_tmp[14:0], 1'h0};
                endcase
            end
        end
    end
    else uiValue <= uiValue;

always_ff @(posedge clk)
    if(!rst_n) uiRange <= 0;
    else if(arithInit) uiRange <= 9'd510;
    else if(phase_control == 2'b11) uiRange <= uiValue_tmp[15] ? (scaledRange[15] ? uiRange : uiRange_mps) : uiRange_lps;
    else uiRange <= uiRange;

assign bitsNeeded_plus1 = bitsNeeded + 1;
always_ff @(posedge clk)
    if(!rst_n) bitsNeeded <= 0;
    else if(arithInit) bitsNeeded <= 0;
    else if(dec_run & EPMode) bitsNeeded <= {1'b0, bitsNeeded_plus1[2:0]};
    else if(phase_control == 2'b11) bitsNeeded <= uiValue_tmp[15] ? (scaledRange[15] ? bitsNeeded : {1'b0, bitsNeeded_mps[2:0]}) : {1'b0, bitsNeeded_lps[2:0]};
    else bitsNeeded <= bitsNeeded;

always_ff @(posedge clk)
    if(arithInit) ruiBin_bytealign <= 1;
    else if(dec_run & EPMode) ruiBin_bytealign <= (bitsNeeded_plus1[2:0] == 0) ? 1 : 0;
    else if(phase_control == 2'b11) ruiBin_bytealign <= uiValue_tmp[15] ? (scaledRange[15] ? ruiBin_bytealign : (bitsNeeded_mps[2:0]==0) ) : (bitsNeeded_lps[2:0]==0);
    else ruiBin_bytealign <= (bitsNeeded == 0) ? 1 : 0;
always_ff @(posedge clk) 
    if(dec_run & EPMode) ruiBin <= ({uiValue[14:0], 1'b0} < {uiRange, 7'h0}) ? 0 : 1;
    else ruiBin <= (phase_control == 2'b11) ? (uiValue_tmp[15] ? mps : !mps) : ruiBin;
always_ff @(posedge clk) ruiBin_vld <= (phase_control == 2'b11) ? 1 : (dec_run & EPMode);
always_ff @(posedge clk) ctxStateUpdate <= (phase_control == 2'b11) ? (uiValue_tmp[15] ? nxtState_mps : nxtState_lps) : ctxStateUpdate;
always_ff @(posedge clk) ctxStateUpdate_vld <= (phase_control == 2'b11) ? 1 : 0;
always_ff @(posedge clk) 
    if(phase_control == 2'b11) byteDecodeComplete <= uiValue_tmp[15] ? (scaledRange[15] ? 0 : bitsNeeded_mps[3]) : bitsNeeded_lps[3];
    else if(dec_run & EPMode) byteDecodeComplete <= bitsNeeded_plus1[3];
    else byteDecodeComplete <= 0;


endmodule
