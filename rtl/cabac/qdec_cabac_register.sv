// Author: Qi Wang
// Control register module for top-level to interact

module qdec_cabac_register 
`ifndef IVERILOG
import qdec_axi_pkg::*; import qdec_cabac_package::*;
`endif
(
    input clk,
    input rst_n,

    output logic        cabac_start,
    output t_CABAC_AO_s reg_allout,

    input  t_reg_req_s  reg_req,
    output t_reg_resp_s reg_resp
);

`include "reg_axi_logic.svh"

t_reg_CABAC_START_s                                          reg_CABAC_START;
t_reg_CABAC_VPS_0_s                                          reg_CABAC_VPS_0;
t_reg_CABAC_SPS_0_s                                          reg_CABAC_SPS_0;
t_reg_CABAC_SPS_1_s                                          reg_CABAC_SPS_1;
t_reg_CABAC_PPS_0_s                                          reg_CABAC_PPS_0;
t_reg_CABAC_SLICE_HEADER_0_s                                 reg_CABAC_SLICE_HEADER_0;

parameter [31:0] reg_CABAC_START_MASK                           = 32'h00000001;
parameter [31:0] reg_CABAC_VPS_0_MASK                           = 32'h0000000f;
parameter [31:0] reg_CABAC_SPS_0_MASK                           = 32'h0fffffff;
parameter [31:0] reg_CABAC_SPS_1_MASK                           = 32'h07ffffff;
parameter [31:0] reg_CABAC_PPS_0_MASK                           = 32'h0000ffff;
parameter [31:0] reg_CABAC_SLICE_HEADER_0_MASK                  = 32'h0000ffff;

always @(posedge clk) 
if (!rst_n) begin 
    reg_CABAC_START                                      <= 32'h0;
    reg_CABAC_VPS_0                                      <= 32'h0;
    reg_CABAC_SPS_0                                      <= 32'h0;
    reg_CABAC_SPS_1                                      <= 32'h0;
    reg_CABAC_PPS_0                                      <= 32'h0;
    reg_CABAC_SLICE_HEADER_0                             <= 32'h0;
end
else if (wr_en) 
case(reg_addr_wr)
    ADDR_CABAC_START                                :   reg_CABAC_START             <= reg_req_hwdata & reg_CABAC_START_MASK;
    ADDR_CABAC_VPS_0                                :   reg_CABAC_VPS_0             <= reg_req_hwdata & reg_CABAC_VPS_0_MASK;
    ADDR_CABAC_SPS_0                                :   reg_CABAC_SPS_0             <= reg_req_hwdata & reg_CABAC_SPS_0_MASK;
    ADDR_CABAC_SPS_1                                :   reg_CABAC_SPS_1             <= reg_req_hwdata & reg_CABAC_SPS_1_MASK;
    ADDR_CABAC_PPS_0                                :   reg_CABAC_PPS_0             <= reg_req_hwdata & reg_CABAC_PPS_0_MASK;
    ADDR_CABAC_SLICE_HEADER_0                       :   reg_CABAC_SLICE_HEADER_0    <= reg_req_hwdata & reg_CABAC_SLICE_HEADER_0_MASK;
endcase


always_comb begin 
case(reg_addr_rd)
    ADDR_CABAC_START                                : pre_rdata = reg_CABAC_START;
    ADDR_CABAC_VPS_0                                : pre_rdata = reg_CABAC_VPS_0;
    ADDR_CABAC_SPS_0                                : pre_rdata = reg_CABAC_SPS_0;
    ADDR_CABAC_SPS_1                                : pre_rdata = reg_CABAC_SPS_1;
    ADDR_CABAC_PPS_0                                : pre_rdata = reg_CABAC_PPS_0;
    ADDR_CABAC_SLICE_HEADER_0                       : pre_rdata = reg_CABAC_SLICE_HEADER_0;
	default                                    	: pre_rdata = REG_BAD_DATA; 
endcase
end




assign reg_allout.reg_CABAC_START                               = reg_CABAC_START;
assign reg_allout.reg_CABAC_VPS_0                               = reg_CABAC_VPS_0;
assign reg_allout.reg_CABAC_SPS_0                               = reg_CABAC_SPS_0;
assign reg_allout.reg_CABAC_SPS_1                               = reg_CABAC_SPS_1;
assign reg_allout.reg_CABAC_PPS_0                               = reg_CABAC_PPS_0;
assign reg_allout.reg_CABAC_SLICE_HEADER_0                      = reg_CABAC_SLICE_HEADER_0;



//custom logic here
always_ff @(posedge clk) begin
    if(!rst_n) begin
        cabac_start   <=  '0;
    end else begin
        cabac_start   <=  (wr_en & (reg_addr_wr==ADDR_CABAC_START) & reg_req_hwdata[0]);
    end
end

endmodule
