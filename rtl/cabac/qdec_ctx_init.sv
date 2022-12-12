// Author : Qi Wang
// The sub-FSM to handle context model initialization
module qdec_ctx_init 
`ifndef IVERILOG
import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    input  logic       ctx_init_start,
    input  logic [5:0] qp,

    output logic [9:0] ctx_init_addr,
    output logic [6:0] ctx_init_wdata,
    output logic       ctx_init_we,
    output logic       ctx_init_done_intr
);

logic [5:0] qp_r;
logic [9:0] counter_scan;
logic [9:0] counter_scan_d[2:0];
logic       scan_done;
logic [2:0] scan_done_d;
logic       scan_running;
logic [2:0] scan_running_d;
logic [7:0] init_value;
logic [5:0] init_value_shrink; // totally 59 possible init values, even though the max value is 255

t_state_init state, nxt_state;

always_comb
    case(state)
    IDLE_INIT:                nxt_state = ctx_init_start===1'b1 ? SCAN_INIT : IDLE_INIT;
    SCAN_INIT:                nxt_state = scan_done===1'b1 ? ENDING_INIT : SCAN_INIT;
    ENDING_INIT:              nxt_state = IDLE_INIT;
    default:                  nxt_state = IDLE_INIT;
    endcase

always_ff @(posedge clk)
    if(!rst_n) state <= IDLE_INIT;
    else state <= nxt_state;

// interrupt output to top-level
always_ff @(posedge clk) ctx_init_done_intr <= (state == ENDING_INIT) ? 1 : 0;

// Main FSM control signals
always_ff @(posedge clk)
    if(state == SCAN_INIT) counter_scan <= (counter_scan == 10'd566) ? counter_scan : counter_scan + 1;
    else counter_scan <= 0;
always_ff @(posedge clk) begin
    counter_scan_d[0] <= counter_scan;
    counter_scan_d[1] <= counter_scan_d[0];
    counter_scan_d[2] <= counter_scan_d[1];
end
always_ff @(posedge clk) {scan_done, scan_done_d} <= {scan_done_d, (counter_scan == 10'd566) ? 1'b1 : 1'b0}; // totally 566 states to be initialized
always_ff @(posedge clk) {scan_running, scan_running_d} <= {scan_running_d, (counter_scan == 10'd0) ? 1'b0 : 1'b1};

// context memory access control
always_ff @(posedge clk) init_value <= CTX_INIT_VALUE[counter_scan];
always_ff @(posedge clk)
    case(init_value)
    8'd31 : init_value_shrink <= 6'd0;
    8'd61 : init_value_shrink <= 6'd1;
    8'd63 : init_value_shrink <= 6'd2;
    8'd74 : init_value_shrink <= 6'd3;
    8'd78 : init_value_shrink <= 6'd4;
    8'd79 : init_value_shrink <= 6'd5;
    8'd91 : init_value_shrink <= 6'd6;
    8'd92 : init_value_shrink <= 6'd7;
    8'd93 : init_value_shrink <= 6'd8;
    8'd94 : init_value_shrink <= 6'd9;
    8'd95 : init_value_shrink <= 6'd10;
    8'd107: init_value_shrink <= 6'd11;
    8'd108: init_value_shrink <= 6'd12;
    8'd109: init_value_shrink <= 6'd13;
    8'd110: init_value_shrink <= 6'd14;
    8'd111: init_value_shrink <= 6'd15;
    8'd121: init_value_shrink <= 6'd16;
    8'd122: init_value_shrink <= 6'd17;
    8'd123: init_value_shrink <= 6'd18;
    8'd124: init_value_shrink <= 6'd19;
    8'd125: init_value_shrink <= 6'd20;
    8'd126: init_value_shrink <= 6'd21;
    8'd127: init_value_shrink <= 6'd22;
    8'd134: init_value_shrink <= 6'd23;
    8'd136: init_value_shrink <= 6'd24;
    8'd137: init_value_shrink <= 6'd25;
    8'd138: init_value_shrink <= 6'd26;
    8'd139: init_value_shrink <= 6'd27;
    8'd140: init_value_shrink <= 6'd28;
    8'd141: init_value_shrink <= 6'd29;
    8'd143: init_value_shrink <= 6'd30;
    8'd149: init_value_shrink <= 6'd31;
    8'd151: init_value_shrink <= 6'd32;
    8'd152: init_value_shrink <= 6'd33;
    8'd153: init_value_shrink <= 6'd34;
    8'd154: init_value_shrink <= 6'd35;
    8'd155: init_value_shrink <= 6'd36;
    8'd157: init_value_shrink <= 6'd37;
    8'd160: init_value_shrink <= 6'd38;
    8'd166: init_value_shrink <= 6'd39;
    8'd167: init_value_shrink <= 6'd40;
    8'd168: init_value_shrink <= 6'd41;
    8'd169: init_value_shrink <= 6'd42;
    8'd170: init_value_shrink <= 6'd43;
    8'd171: init_value_shrink <= 6'd44;
    8'd179: init_value_shrink <= 6'd45;
    8'd182: init_value_shrink <= 6'd46;
    8'd183: init_value_shrink <= 6'd47;
    8'd184: init_value_shrink <= 6'd48;
    8'd185: init_value_shrink <= 6'd49;
    8'd194: init_value_shrink <= 6'd50;
    8'd196: init_value_shrink <= 6'd51;
    8'd197: init_value_shrink <= 6'd52;
    8'd198: init_value_shrink <= 6'd53;
    8'd200: init_value_shrink <= 6'd54;
    8'd201: init_value_shrink <= 6'd55;
    8'd208: init_value_shrink <= 6'd56;
    8'd224: init_value_shrink <= 6'd57;
    8'd227: init_value_shrink <= 6'd58;
    default:init_value_shrink <= 6'd59;
    endcase

always_ff @(posedge clk) qp_r <= qp;
always_ff @(posedge clk) ctx_init_addr <= counter_scan_d[1];
always_ff @(posedge clk) ctx_init_wdata <= CTX_INIT_STATE_ROM[qp_r][init_value_shrink];
always_ff @(posedge clk) ctx_init_we <= scan_running;

// Other output signal control

// Sub FSMs

endmodule
