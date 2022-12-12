logic				ACLK;
logic				ARESET;
logic				ACLK_EN;

assign ACLK	    = clk;
assign ARESET	= !rst_n;


localparam		WRIDLE	= 2'd0, 
				WRDATA	= 2'd1, 
				WRRESP	= 2'd2, 
				WRRESET	= 2'd3,
				RDIDLE	= 2'd0, 
				RDDATA	= 2'd1, 
				RDRESET	= 2'd2, 
				ADDR_BITS	= R_AWID;


//------------------------Local signal-------------------
    reg  [1:0]                    wstate; // = WRRESET;
    reg  [1:0]                    wnext;
    reg  [ADDR_BITS-1:0]          waddr;
    wire [31:0]                   wmask;
    wire                          aw_hs;
    wire                          w_hs;
    reg  [1:0]                    rstate; // = RDRESET;
    reg  [1:0]                    rnext;
    reg  [31:0]                   rdata;
    wire                          ar_hs;
    wire [ADDR_BITS-1:0]          raddr;



//------------------------AXI write fsm------------------
assign reg_resp.AWREADY = (wstate == WRIDLE);
assign reg_resp.WREADY  = (wstate == WRDATA);
assign reg_resp.B.BRESP   = AXI_OKAY_RESP;
assign reg_resp.B.BID	= 0;
assign reg_resp.BVALID  = (wstate == WRRESP);
assign wmask   = { {8{reg_req.W.WSTRB[3]}}, {8{reg_req.W.WSTRB[2]}}, {8{reg_req.W.WSTRB[1]}}, {8{reg_req.W.WSTRB[0]}} };
assign aw_hs   = reg_req.AWVALID & reg_resp.AWREADY;
assign w_hs    = reg_req.WVALID & reg_resp.WREADY;

// wstate
always @(posedge ACLK) begin
    if (ARESET)
        wstate <= WRRESET;
    else
        wstate <= wnext;
end

// wnext
always @(*) begin
    case (wstate)
        WRIDLE:
            if (reg_req.AWVALID)
                wnext = WRDATA;
            else
                wnext = WRIDLE;
        WRDATA:
            if (reg_req.WVALID)
                wnext = WRRESP;
            else
                wnext = WRDATA;
        WRRESP:
            if (reg_req.BREADY)
                wnext = WRIDLE;
            else
                wnext = WRRESP;
        default:
            wnext = WRIDLE;
    endcase
end

// waddr
always @(posedge ACLK) begin
    if (aw_hs)
        waddr <= reg_req.AW.AWADDR[ADDR_BITS-1:0];
end

//------------------------AXI read fsm-------------------
assign reg_resp.ARREADY = (rstate == RDIDLE);
assign reg_resp.R.RDATA   = rdata;
assign reg_resp.R.RRESP   = AXI_OKAY_RESP;
assign reg_resp.R.RID	= 'd0;
assign reg_resp.RVALID  = (rstate == RDDATA);
assign ar_hs   = reg_req.ARVALID & reg_resp.ARREADY;
assign raddr   = reg_req.AR.ARADDR[ADDR_BITS-1:0];

// rstate
always @(posedge ACLK) begin
    if (ARESET)
        rstate <= RDRESET;
    else
        rstate <= rnext;
end

// rnext
always @(*) begin
    case (rstate)
        RDIDLE:
            if (reg_req.ARVALID)
                rnext = RDDATA;
            else
                rnext = RDIDLE;
        RDDATA:
            if (reg_req.RREADY & reg_resp.RVALID)
                rnext = RDIDLE;
            else
                rnext = RDDATA;
        default:
            rnext = RDIDLE;
    endcase
end

logic	[R_DWID-1:0]	pre_rdata;
// rdata
always @(posedge ACLK) begin
    if (ar_hs) begin
        rdata <= pre_rdata;
    end
end



logic						wr_en;
logic						rd_en;
logic	[R_AWID-1:0]		reg_addr_wr, reg_addr_rd;

assign wr_en		= w_hs;
assign rd_en		= ar_hs;

assign reg_addr_wr	= waddr;
assign reg_addr_rd	= raddr;


logic	[R_DWID-1:0]	reg_req_hwdata;
assign reg_req_hwdata	= reg_req.W.WDATA;

