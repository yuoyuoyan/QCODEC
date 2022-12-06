//
// Author : Qi Wang
// The sub-FSM to handle CQT part decoding
module qdec_sao_fsm import qdec_cabac_package::*;(
    input clk,
    input rst_n,

    input  logic       cqt_start,
    input  logic [5:0] xCTB,
    input  logic [4:0] yCTB,
    input  logic [11:0]widthByPix,
    input  logic [10:0]heightByPix,
    input  logic [1:0] slice_type,
    input  logic       transquant_bypass_enabled_flag,

    output logic [9:0] ctx_cqt_addr,
    output logic       ctx_cqt_addr_vld,
    output logic       dec_run_cqt,
    input  logic       dec_rdy,
    output logic       EPMode_cqt,
    input  logic       ruiBin,
    input  logic       ruiBin_vld,
    output logic       cqt_done_intr
);

logic [0:0] split_flag_depth0; // split to 32x32
logic [3:0] split_flag_depth1; // split to 16x16
logic [15:0]split_flag_depth2; // split to 8x8
logic [63:0]split_flag_depth3; // split to 4x4
logic [2:0] split_depth; // pointer to the split depth from 0 to 4
logic [1:0] counter_split_flag_depth1; // pointer to the 32x32 CU, zigzag order inside CTU, same later
logic [3:0] counter_split_flag_depth2; // pointer to the 16x16 CU
logic [5:0] counter_split_flag_depth3; // pointer to the 8x8 CU
logic [7:0] counter_split_flag_depth4; // pointer to the 4x4 CU, although no split flag
logic       split_point_oob;
logic       split_flag_curr;
logic [9:0] widthBy4x4CU;
logic [8:0] heightBy4x4CU;
logic [9:0] xSplitPoint4x4CU;
logic [8:0] ySplitPoint4x4CU;
logic       lastCUinCTU;
logic       ruiBin_r;
logic       dec_done;
logic       cu_start;
logic [9:0] xCU;
logic [8:0] yCU;
logic [2:0] log2CUSize;
logic [9:0] ctx_cu_addr;
logic       ctx_cu_addr_vld;
logic       dec_run_cu;
logic       cu_done_intr;
logic       CU_CQT_start;
logic        availableL, availableA; // indicate the availablity of the CU at the left or top of current CU
logic        condL, condA; // condL = depth[xNbL][yNbL] > currDepth; condA = depth[xNbA][yNbA] > currDepth;
logic [15:0] split_last_row_above_buf[63:0]; // Need 16 bits to describe the split case of a row or a col, and max 64 CTU in a row
logic [15:0] split_last_col_left_buf; // Buffer the result at the end of the FSM, no need to flush because of the availableL and availableA
logic [0:0]  split_flag_depth0_L, split_flag_depth0_A;
logic [3:0]  split_flag_depth1_L, split_flag_depth1_A;
logic [15:0] split_flag_depth2_L, split_flag_depth2_A;
logic [63:0] split_flag_depth3_L, split_flag_depth3_A;

t_state_cqt state, nxt_state;

always_comb
    case(state)
    IDLE_CQT:                 nxt_state = cqt_start ? CALC_COR_SAO : IDLE_SAO;
    CALC_COR_CQT:             nxt_state = (!split_point_oob & (split_depth != 3'd4)) ? SPLIT_CU_FLAG_CQT : OOB_FORCE_SPLIT_CQT;
    SPLIT_CU_FLAG_CQT:        nxt_state = dec_done? (ruiBin_r? JUDGE_CQT : CU_CQT) : SPLIT_CU_FLAG_CQT;
    OOB_FORCE_SPLIT_CQT:      nxt_state = JUDGE_CQT;
    CU_CQT:                   nxt_state = cu_done_intr ? JUDGE_CQT : CU_CQT;
    JUDGE_CQT:                nxt_state = (lastCUinCTU & (!split_flag_curr)) ? ENDING_CQT : ITERATION_CQT;
    ITERATION_CQT:            nxt_state = CALC_COR_CQT;
    ENDING_CQT:               nxt_state = IDLE_CQT;
    default:                  nxt_state = IDLE_CQT;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_CQT;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) cqt_done_intr <= (state == ENDING_CQT) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk)
    if(state == IDLE_CQT) split_depth <= 0;
    else if(state == ITERATION_CQT) 
        casex({split_flag_curr, split_depth})
        4'b1_xxx: split_depth <= split_depth + 1;
        4'b0_001: split_depth <= (counter_split_flag_depth1 == 2'h3) ? 0 : 1;
        4'b0_010: split_depth <= (counter_split_flag_depth2[1:0] == 2'h3) ? 1 : 2;
        4'b0_011: split_depth <= (counter_split_flag_depth3[1:0] == 2'h3) ? 2 : 3;
        4'b0_100: split_depth <= (counter_split_flag_depth4[1:0] == 2'h3) ? 3 : 4;
        default:  split_depth <= split_depth;
        endcase

always_ff @(posedge clk)
    if(state == IDLE_CQT) counter_split_flag_depth1 <= 0;
    else if(state == ITERATION_CQT)
        counter_split_flag_depth1 <= (split_depth == 1) ? counter_split_flag_depth1 + 1 : counter_split_flag_depth1;
always_ff @(posedge clk)
    if(state == IDLE_CQT) counter_split_flag_depth2 <= 0;
    else if(state == ITERATION_CQT)
        counter_split_flag_depth2 <= (split_depth == 2) ? counter_split_flag_depth2 + 1 : counter_split_flag_depth2;
always_ff @(posedge clk)
    if(state == IDLE_CQT) counter_split_flag_depth3 <= 0;
    else if(state == ITERATION_CQT)
        counter_split_flag_depth3 <= (split_depth == 3) ? counter_split_flag_depth3 + 1 : counter_split_flag_depth3;
always_ff @(posedge clk)
    if(state == IDLE_CQT) counter_split_flag_depth4 <= 0;
    else if(state == ITERATION_CQT)
        counter_split_flag_depth4 <= (split_depth == 4) ? counter_split_flag_depth4 + 1 : counter_split_flag_depth4;

always_ff @(posedge clk)
    if(state == IDLE_CQT) begin
        split_flag_depth0 <= 0;
        split_flag_depth1 <= 0;
        split_flag_depth2 <= 0;
        split_flag_depth3 <= 0;
    end
    else if(state == OOB_FORCE_SPLIT_CQT && split_depth != 4) begin
        case(split_depth)
        3'd0: split_flag_depth0 <= 1;
        3'd1: split_flag_depth1[counter_split_flag_depth1] <= 1;
        3'd2: split_flag_depth2[counter_split_flag_depth2] <= 1;
        3'd3: split_flag_depth3[counter_split_flag_depth3] <= 1;
        default: ;
        endcase
    end
    else if(state == SPLIT_CU_FLAG_CQT && ruiBin_vld) begin
        case(split_depth)
        3'd0: split_flag_depth0 <= ruiBin;
        3'd1: split_flag_depth1[counter_split_flag_depth1] <= ruiBin;
        3'd2: split_flag_depth2[counter_split_flag_depth2] <= ruiBin;
        3'd3: split_flag_depth3[counter_split_flag_depth3] <= ruiBin;
        default: ;
        endcase
    end

always_ff @(posedge clk)
    if(state == IDLE_CQT) xSplitPoint4x4CU <= {xCTB, 4'h8};
    else
        case(split_depth)
        3'd0:    xSplitPoint4x4CU <= {xCTB, 4'h8};
        3'd1:    xSplitPoint4x4CU <= {xCTB, counter_split_flag_depth1[0], 3'h4};
        3'd2:    xSplitPoint4x4CU <= {xCTB, counter_split_flag_depth2[2], counter_split_flag_depth2[0], 2'h2};
        3'd3:    xSplitPoint4x4CU <= {xCTB, counter_split_flag_depth3[4], counter_split_flag_depth3[2], counter_split_flag_depth3[0], 1'h1};
        3'd4:    xSplitPoint4x4CU <= {xCTB, counter_split_flag_depth4[6], counter_split_flag_depth4[4], counter_split_flag_depth4[2], counter_split_flag_depth4[0]};
        default: xSplitPoint4x4CU <= {xCTB, 4'h8};
        endcase
        
always_ff @(posedge clk)
    if(state == IDLE_CQT) ySplitPoint4x4CU <= {yCTB, 4'h8};
    else
        case(split_depth)
        3'd0:    ySplitPoint4x4CU <= {yCTB, 4'h8};
        3'd1:    ySplitPoint4x4CU <= {yCTB, counter_split_flag_depth1[1], 3'h4};
        3'd2:    ySplitPoint4x4CU <= {yCTB, counter_split_flag_depth2[3], counter_split_flag_depth2[1], 2'h2};
        3'd3:    ySplitPoint4x4CU <= {yCTB, counter_split_flag_depth3[5], counter_split_flag_depth3[3], counter_split_flag_depth3[1], 1'h1};
        3'd4:    ySplitPoint4x4CU <= {yCTB, counter_split_flag_depth4[7], counter_split_flag_depth4[5], counter_split_flag_depth4[3], counter_split_flag_depth4[1]};
        default: ySplitPoint4x4CU <= {yCTB, 4'h8};
        endcase

assign widthBy4x4CU = widthByPix[11:2];
assign heightBy4x4CU = heightByPix[10:2];
always_ff @(posedge clk) split_point_oob <= ((xSplitPoint4x4CU > widthBy4x4CU) || (ySplitPoint4x4CU > heightBy4x4CU)) ? 1 : 0;

always_ff @(posedge clk) dec_done <= (state == CALC_COR_CQT) ? 0 : ruiBin_vld ? 1 : dec_done;

always_ff @(posedge clk)
    case(split_depth)
    3'h0: split_flag_curr <= split_flag_depth0[0];
    3'h1: split_flag_curr <= split_flag_depth1[counter_split_flag_depth1];
    3'h2: split_flag_curr <= split_flag_depth2[counter_split_flag_depth2];
    3'h3: split_flag_curr <= split_flag_depth3[counter_split_flag_depth3];
    3'h4: split_flag_curr <= 0;
    default: split_flag_curr <= split_flag_depth0[0];
    endcase

always_ff @(posedge clk)
    if(state == IDLE_CQT)
        lastCUinCTU <= 0;
    else if(state == CU_CQT)
        case(split_depth)
        3'h0: lastCUinCTU <= 1;
        3'h1: lastCUinCTU <= (counter_split_flag_depth1[1:0] == 2'h3) ? 1 : 0;
        3'h2: lastCUinCTU <= (counter_split_flag_depth2[1:0] == 2'h3) ? 1 : 0;
        3'h3: lastCUinCTU <= (counter_split_flag_depth3[1:0] == 2'h3) ? 1 : 0;
        3'h4: lastCUinCTU <= (counter_split_flag_depth4[1:0] == 2'h3) ? 1 : 0;
        default: lastCUinCTU <= 0;
        endcase

always_ff @(posedge clk) ruiBin_r <= (ruiBin_vld) ? ruiBin : ruiBin_r;

always_ff @(posedge clk) CU_CQT_start <= (state == CU_CQT) ? 1 : 0;
always_ff @(posedge clk) 
    if(!rst_n) cu_start <= 0;
    else if(state == CU_CQT && !CU_CQT_start) cu_start <= 1;
    else cu_start <= 0;

always_ff @(posedge clk)
    if(state == IDLE_CQT) xCU <= {xCTB, 4'h0};
    else
        case(split_depth)
        3'd0:    xCU <= {xCTB, 4'h0};
        3'd1:    xCU <= {xCTB, counter_split_flag_depth1[0], 3'h0};
        3'd2:    xCU <= {xCTB, counter_split_flag_depth2[2], counter_split_flag_depth2[0], 2'h0};
        3'd3:    xCU <= {xCTB, counter_split_flag_depth3[4], counter_split_flag_depth3[2], counter_split_flag_depth3[0], 1'h0};
        3'd4:    xCU <= {xCTB, counter_split_flag_depth4[6], counter_split_flag_depth4[4], counter_split_flag_depth4[2], counter_split_flag_depth4[0]};
        default: xCU <= {xCTB, 4'h0};
        endcase
        
always_ff @(posedge clk)
    if(state == IDLE_CQT) yCU <= {yCTB, 4'h0};
    else
        case(split_depth)
        3'd0:    yCU <= {yCTB, 4'h0};
        3'd1:    yCU <= {yCTB, counter_split_flag_depth1[1], 3'h0};
        3'd2:    yCU <= {yCTB, counter_split_flag_depth2[3], counter_split_flag_depth2[1], 2'h0};
        3'd3:    yCU <= {yCTB, counter_split_flag_depth3[5], counter_split_flag_depth3[3], counter_split_flag_depth3[1], 1'h0};
        3'd4:    yCU <= {yCTB, counter_split_flag_depth4[7], counter_split_flag_depth4[5], counter_split_flag_depth4[3], counter_split_flag_depth4[1]};
        default: yCU <= {yCTB, 4'h0};
        endcase

always_ff @(posedge clk) log2CUSize <= 3'h6 - split_depth;

// Other output signal control

// 00 01
// 10 11
// 0000 0001 0100 0101
// 0010 0011 0110 0111
// 1000 1001 1100 1101
// 1010 1011 1110 1111
always_ff @(posedge clk)
    if(state == IDLE_CQT) availableL <= 0;
    else if(xCTB == 0)
        case(split_depth)
        3'd0: availableL <= 0;
        3'd1: availableL <= (counter_split_flag_depth1[0] == 0) ? 0 : 1;
        3'd2: availableL <= ({counter_split_flag_depth2[2], counter_split_flag_depth2[0]} == 0) ? 0 : 1;
        3'd3: availableL <= ({counter_split_flag_depth3[4], counter_split_flag_depth3[2], counter_split_flag_depth3[0]} == 0) ? 0 : 1;
        3'd4: availableL <= ({counter_split_flag_depth4[6], counter_split_flag_depth4[4], counter_split_flag_depth4[2], counter_split_flag_depth4[0]} == 0) ? 0 : 1;
        default: availableL <= 0;
        endcase
    else availableL <= 1;

always_ff @(posedge clk)
    if(state == IDLE_CQT) availableA <= 0;
    else if(yCTB == 0)
        case(split_depth)
        3'd0: availableA <= 0;
        3'd1: availableA <= (counter_split_flag_depth1[1] == 0) ? 0 : 1;
        3'd2: availableA <= ({counter_split_flag_depth2[3], counter_split_flag_depth2[1]} == 0) ? 0 : 1;
        3'd3: availableA <= ({counter_split_flag_depth3[5], counter_split_flag_depth3[3], counter_split_flag_depth3[1]} == 0) ? 0 : 1;
        3'd4: availableA <= ({counter_split_flag_depth4[7], counter_split_flag_depth4[5], counter_split_flag_depth4[3], counter_split_flag_depth4[1]} == 0) ? 0 : 1;
        default: availableA <= 0;
        endcase
    else availableA <= 1;

always_ff @(posedge clk)
    if(state == ENDING_CQT)
        split_last_col_left_buf <= {1'b1,              split_flag_depth3[21], split_flag_depth2[ 5], split_flag_depth3[23], split_flag_depth1[ 1], split_flag_depth3[29], split_flag_depth2[ 7], split_flag_depth3[31],
                                    split_flag_depth0, split_flag_depth3[53], split_flag_depth2[13], split_flag_depth3[55], split_flag_depth1[ 3], split_flag_depth3[61], split_flag_depth2[15], split_flag_depth3[63]};

always_ff @(posedge clk)
    if(state == ENDING_CQT)
        split_last_row_above_buf[xCTB] <= {1'b1,              split_flag_depth3[42], split_flag_depth2[10], split_flag_depth3[43], split_flag_depth1[ 2], split_flag_depth3[46], split_flag_depth2[11], split_flag_depth3[47], 
                                           split_flag_depth0, split_flag_depth3[58], split_flag_depth2[14], split_flag_depth3[59], split_flag_depth1[ 3], split_flag_depth3[62], split_flag_depth2[15], split_flag_depth3[63]};

// 00 01
// 10 11
// 0000 0001 0100 0101
// 0010 0011 0110 0111
// 1000 1001 1100 1101
// 1010 1011 1110 1111
//  0  1  4  5 16 17 20 21 
//  2  3  6  7 18 19 22 23
//  8  9 12 13 24 25 28 29
// 10 11 14 15 26 27 30 31
// 32 33 36 37 48 49 52 53 
// 34 35 38 39 50 51 54 55
// 40 41 44 45 56 57 60 61
// 42 43 46 47 58 59 62 63
always_ff @(posedge clk) split_flag_depth0_L <= split_last_col_left_buf[8];
always_ff @(posedge clk) split_flag_depth1_L <= {split_last_col_left_buf[4],  split_flag_depth1[0], 
                                                 split_last_col_left_buf[12], split_flag_depth1[2]};
always_ff @(posedge clk) split_flag_depth2_L <= {split_last_col_left_buf[2],  split_flag_depth2[0],  split_last_col_left_buf[6],  split_flag_depth2[2],  
                                                 split_flag_depth2[1],        split_flag_depth2[4],  split_flag_depth2[3],        split_flag_depth2[6], 
                                                 split_last_col_left_buf[10], split_flag_depth2[8],  split_last_col_left_buf[14], split_flag_depth2[10], 
                                                 split_flag_depth2[9],        split_flag_depth2[12], split_flag_depth2[11],       split_flag_depth2[14]};
always_ff @(posedge clk) split_flag_depth3_L <= {split_last_col_left_buf[1],  split_flag_depth3[0],  split_last_col_left_buf[3],  split_flag_depth3[2],  split_flag_depth3[1],  split_flag_depth3[4],  split_flag_depth3[3],  split_flag_depth3[6],  
                                                 split_last_col_left_buf[5],  split_flag_depth3[8],  split_last_col_left_buf[7],  split_flag_depth3[10], split_flag_depth3[9],  split_flag_depth3[12], split_flag_depth3[11], split_flag_depth3[14], 
                                                 split_flag_depth3[5],        split_flag_depth3[16], split_flag_depth3[7],        split_flag_depth3[18], split_flag_depth3[17], split_flag_depth3[20], split_flag_depth3[19], split_flag_depth3[22], 
                                                 split_flag_depth3[13],       split_flag_depth3[24], split_flag_depth3[15],       split_flag_depth3[26], split_flag_depth3[25], split_flag_depth3[28], split_flag_depth3[27], split_flag_depth3[30], 
                                                 split_last_col_left_buf[9],  split_flag_depth3[32], split_last_col_left_buf[11], split_flag_depth3[34], split_flag_depth3[33], split_flag_depth3[36], split_flag_depth3[35], split_flag_depth3[38], 
                                                 split_last_col_left_buf[13], split_flag_depth3[40], split_last_col_left_buf[15], split_flag_depth3[42], split_flag_depth3[41], split_flag_depth3[44], split_flag_depth3[43], split_flag_depth3[46], 
                                                 split_flag_depth3[37],       split_flag_depth3[48], split_flag_depth3[39],       split_flag_depth3[50], split_flag_depth3[49], split_flag_depth3[52], split_flag_depth3[51], split_flag_depth3[54], 
                                                 split_flag_depth3[45],       split_flag_depth3[56], split_flag_depth3[47],       split_flag_depth3[58], split_flag_depth3[57], split_flag_depth3[60], split_flag_depth3[59], split_flag_depth3[62]};
always_ff @(posedge clk) split_flag_depth0_A <= split_last_row_above_buf[xCTB][8];
always_ff @(posedge clk) split_flag_depth1_A <= {split_last_row_above_buf[xCTB][4],  split_last_row_above_buf[xCTB][12], 
                                                 split_flag_depth1[0], split_flag_depth1[1]};
always_ff @(posedge clk) split_flag_depth2_A <= {split_last_row_above_buf[xCTB][2],  split_last_row_above_buf[xCTB][6],   split_flag_depth2[0],  split_flag_depth2[1],  
                                                 split_last_row_above_buf[xCTB][10], split_last_row_above_buf[xCTB][14],  split_flag_depth2[4],  split_flag_depth2[5],  
                                                 split_flag_depth2[2],               split_flag_depth2[3],                split_flag_depth2[8],  split_flag_depth2[9],  
                                                 split_flag_depth2[6],               split_flag_depth2[7],                split_flag_depth2[12], split_flag_depth2[13]};
always_ff @(posedge clk) split_flag_depth3_A <= {split_last_row_above_buf[xCTB][1],  split_last_row_above_buf[xCTB][3],   split_flag_depth3[0],  split_flag_depth3[1],  split_last_row_above_buf[xCTB][5],  split_last_row_above_buf[xCTB][7],   split_flag_depth3[4],  split_flag_depth3[5],  
                                                 split_flag_depth3[2],  split_flag_depth3[3], split_flag_depth3[8],  split_flag_depth3[9],  split_flag_depth3[6],  split_flag_depth3[7], split_flag_depth3[12],  split_flag_depth3[13],  
                                                 split_last_row_above_buf[xCTB][9],  split_last_row_above_buf[xCTB][11],  split_flag_depth3[16], split_flag_depth3[17], split_last_row_above_buf[xCTB][13], split_last_row_above_buf[xCTB][15],  split_flag_depth3[20], split_flag_depth3[21], 
                                                 split_flag_depth3[18], split_flag_depth3[19], split_flag_depth3[24], split_flag_depth3[25], split_flag_depth3[22], split_flag_depth3[23], split_flag_depth3[28],  split_flag_depth3[29],  
                                                 split_flag_depth3[10], split_flag_depth3[11], split_flag_depth3[32], split_flag_depth3[33], split_flag_depth3[14], split_flag_depth3[15], split_flag_depth3[36],  split_flag_depth3[37],  
                                                 split_flag_depth3[34], split_flag_depth3[35], split_flag_depth3[40], split_flag_depth3[41], split_flag_depth3[38], split_flag_depth3[39], split_flag_depth3[44],  split_flag_depth3[45],  
                                                 split_flag_depth3[26], split_flag_depth3[27], split_flag_depth3[48], split_flag_depth3[49], split_flag_depth3[30], split_flag_depth3[31], split_flag_depth3[52],  split_flag_depth3[53],  
                                                 split_flag_depth3[50], split_flag_depth3[51], split_flag_depth3[56], split_flag_depth3[57], split_flag_depth3[54], split_flag_depth3[55], split_flag_depth3[60],  split_flag_depth3[61]};

always_ff @(posedge clk)
    if(state == CALC_COR_CQT)
        case(split_depth)
        3'd0: condL <= availableL & split_flag_depth0_L;
        3'd1: condL <= availableL & split_flag_depth1_L[counter_split_flag_depth1];
        3'd2: condL <= availableL & split_flag_depth2_L[counter_split_flag_depth2];
        3'd3: condL <= availableL & split_flag_depth3_L[counter_split_flag_depth3];
        default: condL <= 0;
        endcase

always_ff @(posedge clk)
    if(state == CALC_COR_CQT)
        case(split_depth)
        3'd0: condA <= availableA & split_flag_depth0_A;
        3'd1: condA <= availableA & split_flag_depth1_A[counter_split_flag_depth1];
        3'd2: condA <= availableA & split_flag_depth2_A[counter_split_flag_depth2];
        3'd3: condA <= availableA & split_flag_depth3_A[counter_split_flag_depth3];
        default: condA <= 0;
        endcase

always_ff @(posedge clk)
    if(state == CU_CQT)
        ctx_cqt_addr <= ctx_cu_addr;
    else
        ctx_cqt_addr <= condL ? (condA ? CTXIDX_SPLIT_CU_FLAG[2] : CTXIDX_SPLIT_CU_FLAG[1]) :
                                (condA ? CTXIDX_SPLIT_CU_FLAG[1] : CTXIDX_SPLIT_CU_FLAG[0]);

logic state_SPLIT_CU_FLAG_CQT_d, state_start_SPLIT_CU_FLAG_CQT;
always_ff @(posedge clk) state_SPLIT_CU_FLAG_CQT_d <= (state == SPLIT_CU_FLAG_CQT) ? 1 : 0;
assign state_start_SPLIT_CU_FLAG_CQT = ({state_SPLIT_CU_FLAG_CQT_d, (state == SPLIT_CU_FLAG_CQT) ? 1 : 0} == 2'b01) ? 1 : 0;
always_ff @(posedge clk) dec_run_cqt <= (state == CU_CQT) ? dec_run_cu : state_start_SPLIT_CU_FLAG_CQT;
always_ff @(posedge clk) ctx_cqt_addr_vld <= state_start_SPLIT_CU_FLAG_CQT;
always_ff @(posedge clk) EPMode_cqt <= (state == CU_CQT) ? EPMode_cu : 1'b0;

// Sub FSMs
qdec_cu_fsm cu_fsm(
    .clk,
    .rst_n,

    .cu_start,
    .xCU,
    .yCU,
    .log2CUSize,
    .slice_type,
    .transquant_bypass_enabled_flag,

    .ctx_cu_addr,
    .ctx_cu_addr_vld,
    .dec_run_cu,
    .dec_rdy,
    .EPMode_cu,
    .ruiBin,
    .ruiBin_vld,
    .cu_done_intr
);

endmodule
