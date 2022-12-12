module test(
    input  logic clk,
    input  logic rst,
    input  logic a,
    input  logic b,
    output logic c
);

always_ff @(posedge clk)
    if(rst) c <= 0;
    else c <= a ^ b;

endmodule