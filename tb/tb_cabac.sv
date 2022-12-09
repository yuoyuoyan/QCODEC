`timescale 1ns/1ns

module tb_cabac;

import qdec_cabac_package::*;

logic clk, rst_n;
t_reg_req_s      reg_req;
t_reg_resp_s     reg_resp;
logic [7:0]  bitstreamFetch;
logic        bitstreamFetch_vld;
logic        bitstreamFetch_rdy;
logic       error_intr;
logic       done_intr;
logic       ctu_done_intr;
logic [11:0] lb_raddr;
logic [7:0]  lb_dout;
logic        lb_re;


initial begin
    clk = 1'b0;
    rst_n = 1'b1;
    
    // Reset for 1us
    #100 
    rst_n = 1'b0;
    #1000
    rst_n = 1'b1;
end

// Generate 100MHz clock signal
always #5 clock <= ~clock;

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
