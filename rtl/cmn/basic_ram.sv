// xilinx simple dual port ram
module basic_ram #(
    parameter ADDR_SIZE = 9,
    parameter DATA_SIZE = 72
) (
    input clk,
    input wea,
    input reb,
    input        [ADDR_SIZE-1:0] addra,
    input        [ADDR_SIZE-1:0] addrb,
    input        [DATA_SIZE-1:0] dina,
    output logic [DATA_SIZE-1:0] doutb
);

(* ram_style = "block" *) reg [DATA_SIZE-1:0] data [2**ADDR_SIZE-1:0];

always @(posedge clk) begin
    if (wea)
        data[addra] <= dina;
end

always @(posedge clk)
    if (reb)
        doutb <= data[addrb];

endmodule 

