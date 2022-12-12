rm test_waveform.vcd
iverilog -o test.vvp -g2012 test.sv test_tb.sv
vvp test.vvp