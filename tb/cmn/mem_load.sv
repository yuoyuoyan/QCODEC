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
logic [16*8-1:0] bitstream_buf;
logic [7:0]      bitstream_buf_top;
logic [3:0]      state;
localparam HEAD0 = 0;
localparam HEAD1 = 1;
localparam HEAD2 = 2;
localparam FRAME_START = 3;
localparam FRAME_JUDGE0 = 4;
localparam FRAME_JUDGE1 = 5;
localparam FRAME_END = 6;

initial begin
    // fp = $fopen("../../database/bitstream.txt", "r");
    fp = $fopen("../../database/RaceHorses_832x480_30_RE.265", "rb");
    
    dout_vld = 0;
    state = HEAD0;
    data_init_done = 0;
    frame_started = 0;
    do begin
        temp = $fread(bitstream_buf, fp);
        // $display("read data %032x\n", bitstream_buf);
        repeat(16) begin
            @(posedge clk);
            bitstream_buf_top = bitstream_buf[16*8-1:15*8];
            case(state)
            HEAD0: state = (bitstream_buf_top == 8'h00) ? HEAD1 : HEAD0;
            HEAD1: state = (bitstream_buf_top == 8'h00) ? HEAD2 : HEAD0;
            HEAD2: state = (bitstream_buf_top == 8'h01) ? FRAME_START : ((bitstream_buf_top == 8'h00) ? HEAD2 : HEAD0);
            FRAME_START: state = (bitstream_buf_top == 8'h00) ? FRAME_JUDGE0 : FRAME_START;
            FRAME_JUDGE0: state = (bitstream_buf_top == 8'h00) ? FRAME_JUDGE1 : FRAME_START;
            FRAME_JUDGE1: state = (bitstream_buf_top == 8'h01) ? FRAME_END : ((bitstream_buf_top == 8'h00) ? FRAME_JUDGE1 : FRAME_START);
            FRAME_END: state = FRAME_END;
            default: state = HEAD0;
            endcase
            dout_vld = 1;
            dout = bitstream_buf_top;
            @(posedge clk);
            dout_vld = 0;
            // $display("bitstream buf top %04x, state %01x", bitstream_buf_top, state);
            if(state == FRAME_START || state == FRAME_JUDGE0 || state == FRAME_JUDGE1) begin
                frame_started = 1;
            end
            bitstream_buf = {bitstream_buf[15*8-1:0], 8'h0};
        end
    end while(state != FRAME_END);
    
    dout_vld = 0;
    data_init_done = 1;
    frame_started = 0;
    
    $fclose(fp);
end

endmodule
// endtask
