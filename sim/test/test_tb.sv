`timescale 1ps/1ps

module test_tb();

logic a, b, c;
logic clk, rst;

initial begin
    $dumpfile("test_waveform.vcd");
    $dumpvars(0, test);
    a = 0;
    b = 1;
    clk = 0;
    rst = 0;
    #100
    rst = 1;
    #100
    rst = 0;
    #10000
    $finish();
end

always #5 clk <= ~clk;

always #20 a <= ~a;
always #40 b <= ~b;

test test(
    .clk,
    .rst,
    .a,
    .b,
    .c
);

endmodule
