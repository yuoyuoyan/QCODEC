// Arthor: Qi Wang
// tasks to initialize bitstream RAM
// task mem_load(
//     output logic [7:0]  dout,
//     output logic        dout_vld
// );

module mem_load
(
    input clk,
    input rst_n,

    output logic [7:0] dout,
    output logic       dout_vld,
    output logic       data_init_done,
    output logic       frame_started
);

integer fp, temp;
// logic [8*256-1:0]str;
logic [27:0]     bitstream_addr;
logic [8*16-1:0] bitstream_buf;
logic [15:0]     bitstream_buf_top;
logic [2:0]      state;
localparam HEAD0 = 0;
localparam HEAD1 = 1;
localparam HEAD2 = 2;
localparam FRAME_START = 3;
localparam FRAME_JUDGE = 4;
localparam FRAME_END = 5;

initial begin
    // fp = $fopen("../../database/bitstream.txt", "r");
    fp = $fopen("../../database/RaceHorses_832x480_30_RE.265", "rb");
    
    dout_vld = 0;
    state = HEAD0;
    data_init_done = 0;
    frame_started = 0;
    do begin
        // temp = $fscanf(fp, "%x: %x %x %x %x %x %x %x %x  %s", bitstream_addr, 
        //                 bitstream_buf[8*16-1:7*16], bitstream_buf[7*16-1:6*16], bitstream_buf[6*16-1:5*16], bitstream_buf[5*16-1:4*16],
        //                 bitstream_buf[4*16-1:3*16], bitstream_buf[3*16-1:2*16], bitstream_buf[2*16-1:1*16], bitstream_buf[1*16-1:0*16], str);
        temp = $fread(bitstream_buf, fp);
        // $display("read data %032x\n", bitstream_buf);
        repeat(8) begin
            @(posedge clk);
            bitstream_buf_top = bitstream_buf[8*16-1:7*16];
            case(state)
            HEAD0: state = (bitstream_buf_top == 16'h0000) ? HEAD1 : HEAD0;
            HEAD1: state = (bitstream_buf_top == 16'h0001) ? HEAD2 : HEAD0;
            HEAD2: state = (bitstream_buf_top == 16'h4e01) ? FRAME_START : HEAD0;
            FRAME_START: state = (bitstream_buf_top == 16'h0000) ? FRAME_JUDGE : FRAME_START;
            FRAME_JUDGE: state = (bitstream_buf_top == 16'h0001) ? FRAME_END : FRAME_START;
            FRAME_END: state = FRAME_END;
            default: state = HEAD0;
            endcase
            // $display("bitstream buf top %04x, state %01x", bitstream_buf_top, state);
            if(state == FRAME_START || state == FRAME_JUDGE) begin
                frame_started = 1;
                dout_vld = 1;
                dout = bitstream_buf_top[15:8];
                @(posedge clk);
                dout = bitstream_buf_top[7:0];
                @(posedge clk);
                dout_vld = 0;
            end
            bitstream_buf = {bitstream_buf[7*16-1:0], 16'h0};
        end
    end while(state != FRAME_END);
    
    dout_vld = 0;
    data_init_done = 1;
    frame_started = 0;
    
    $fclose(fp);
end

endmodule
// endtask
