// Arthor: Qi Wang
// tasks to initialize bitstream RAM
task mem_load(
    input logic clk
);

integer fp, count;
logic [8*256-1:0]str;
logic [27:0]     bitstream_addr;
logic [8*16-1:0] bitstream_buf;
logic [15:0]     bitstream_buf_top;
logic [2:0]      state;
logic [15:0]     counter;
localparam HEAD0 = 0;
localparam HEAD1 = 1;
localparam HEAD2 = 2;
localparam FRAME_START = 3;
localparam FRAME_JUDGE = 4;
localparam FRAME_END = 5;

fp = $fopen("../../database/bitstream.txt", "r");

counter = 0;
do{
    count = $fscanf(fp, "%x: %x %x %x %x %x %x %x %x  %s", bitstream_addr, 
                    bitstream_buf[8*16-1:7*16], bitstream_buf[7*16-1:6*16], bitstream_buf[6*16-1:5*16], bitstream_buf[5*16-1:4*16],
                    bitstream_buf[4*16-1:3*16], bitstream_buf[3*16-1:2*16], bitstream_buf[2*16-1:1*16], bitstream_buf[1*16-1:0*16], str);
    $display("read data %032x\n", bitstream_buf);
    repeat(8) begin
        bitstream_buf_top = bitstream_buf[8*16-1:7*16];
        case(state)
        HEAD0: state = (bitstream_buf_top = 16'h0000) ? HEAD1 : HEAD0;
        HEAD1: state = (bitstream_buf_top = 16'h0001) ? HEAD2 : HEAD0;
        HEAD2: state = (bitstream_buf_top = 16'h4e01) ? FRAME_START : HEAD0;
        FRAME_START: state = (bitstream_buf_top = 16'h0000) ? FRAME_JUDGE : FRAME_START;
        FRAME_JUDGE: state = (bitstream_buf_top = 16'h0001) ? FRAME_END : FRAME_START;
        FRAME_END: state = FRAME_END;
        default: state = HEAD0;
        endcase
        $root.bitstream_fifo.buffer[counter] = bitstream_buf_top[15:8];
        $root.bitstream_fifo.buffer[counter+1] = bitstream_buf_top[7:0];
        counter = counter+2;
        bitstream_buf = {bitstream_buf[7*16-1:0], 16'h0};
    end
} while(state != FRAME_END)

$root.bitstream_fifo.wpt = counter;

$fclose(fp);

endtask
