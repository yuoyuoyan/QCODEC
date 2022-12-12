// Arthor: Qi Wang
// Tasks to write a 32-bit data into a certain address
task reg_write;
`ifndef IVERILOG
import axi_pkg::*;
`endif
input  logic         clk;
output t_reg_req_s   reg_req;
input  t_reg_resp_s  reg_resp;
input  logic [31:0]  waddr;
input  logic [31:0]  wdata;

@(negedge clk);
reg_req.AWVALID = 1;
reg_req.AWADDR = waddr;
reg_req.AWID = 0;
reg_req.WDATA = wdata;
reg_req.WVALID = 1;
reg_req.BREADY = 1;
while(!reg_resp.WREADY) @(negedge clk);
reg_req.AWVALID = 0;
reg_req.WVALID = 0;

endtask

task reg_read;
`ifndef IVERILOG
import axi_pkg::*;
`endif
input  logic         clk;
output t_reg_req_s   reg_req;
input  t_reg_resp_s  reg_resp;
input  logic [31:0]  raddr;
output logic [31:0]  rdata;

@(negedge clk);
reg_req.ARVALID = 1;
reg_req.ARADDR = raddr;
reg_req.ARID = 0;
reg_req.RREADY = 1;
while(!reg_resp.RVALID) @(negedge clk);
@(negedge clk)
reg_req.ARVALID = 0;
rdata = reg_resp.RDATA;
$display("Read address 32'h%08h, got data 32'h%08h\n", raddr, rdata);

endtask
