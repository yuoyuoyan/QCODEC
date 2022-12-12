//
module basic_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8,
    parameter DATA_DEPTH = 256
)
(
    input clk,
    input rst_n,

    input  logic [DATA_WIDTH-1:0] din,
    input  logic                  din_vld,
    output logic                  din_rdy,

    output logic [DATA_WIDTH-1:0] dout,
    output logic                  dout_vld,
    input  logic                  dout_rdy
);

logic [ADDR_WIDTH:0] wpt, rpt;
logic [DATA_DEPTH-1:0][DATA_WIDTH-1:0] buffer;

always_ff @(posedge clk)
    if(!rst_n) wpt <= 0;
    else if(din_vld & din_rdy) wpt <= wpt + 1;

always_ff @(posedge clk)
    if(!rst_n) rpt <= 0;
    else if(dout_vld & dout_rdy) rpt <= rpt + 1;

assign din_rdy  = ((wpt[ADDR_WIDTH-1:0] == rpt[ADDR_WIDTH-1:0]) & (wpt[ADDR_WIDTH] != rpt[ADDR_WIDTH])) ? 0 : 1;
assign dout_vld = ((wpt[ADDR_WIDTH-1:0] == rpt[ADDR_WIDTH-1:0]) & (wpt[ADDR_WIDTH] == rpt[ADDR_WIDTH])) ? 0 : 1;

`ifdef IVERILOG
always_ff @(posedge clk)
    if(din_vld & din_rdy) buffer[wpt] <= din;
`else
logic [DATA_DEPTH-1:0] wren;

generate;
    for(genvar i=0; i<DATA_DEPTH; i++) begin : write
        assign wren[i] = (wpt == i) & din_vld & din_rdy;
        always_ff @(posedge clk)
            if(wren[i]) buffer[i] <= din;
    end
endgenerate
`endif

always_comb dout = buffer[rpt];

endmodule
