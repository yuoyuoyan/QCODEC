// Author: Qi Wang
// context memory, store all the arithemetic model probability
module qdec_ctx_mem(
    input clk,
    input rst_n,

    // ctx memory interface
    input  logic [9:0] ctx_addr,
    input  logic [7:0] ctx_wdata,
    input  logic [7:0] ctx_rdata,
    input  logic       ctx_we,
    input  logic       ctx_re,
);

basic_ram #(
    .ADDR_SIZE(10),
    .DATA_SIZE(8)
) ctx_mem
(
    .clk,
    .wea   (ctx_we),
    .reb   (ctx_re),
    .addra (ctx_addr),
    .addrb (ctx_addr),
    .dina  (ctx_wdata),
    .doutb (ctx_rdata)
);

endmodule
