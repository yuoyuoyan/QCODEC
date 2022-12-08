package axi_pkg;

parameter	R_AWID	= 32;
parameter	R_DWID	= 32;
parameter	WID_TID		= 8;

typedef struct packed { 
	logic	[R_AWID-1:0]	AWADDR;
	logic	[WID_TID-1:0]	AWID;	
} t_regAXI_AW_s;

typedef struct packed { 
	logic	[R_DWID-1:0]	WDATA;
	logic	[R_DWID/8-1:0]	WSTRB;
} t_regAXI_W_s;

typedef struct packed { 
	logic	[R_AWID-1:0]	ARADDR;
	logic	[WID_TID-1:0]	ARID;	
} t_regAXI_AR_s;

typedef struct packed { 
	t_AXI_RESP_e			BRESP;
	logic	[WID_TID-1:0]	BID;	
} t_regAXI_B_s;

typedef struct packed {
	logic	[R_DWID-1:0]	RDATA;
	t_AXI_RESP_e			RRESP;
	logic	[WID_TID-1:0]	RID;	
} t_regAXI_R_s;

typedef struct packed { 
	logic				clk_en;
	t_regAXI_AW_s		AW;
	logic				AWVALID;
	t_regAXI_W_s		W;
	logic				WVALID;
	t_regAXI_AR_s		AR;
	logic				ARVALID;
	logic				BREADY;
	logic				RREADY;
} t_reg_req_s;

typedef struct packed { 
	logic				AWREADY;
	logic				WREADY;
	logic				ARREADY;
	t_regAXI_B_s		B;
	logic				BVALID;
	t_regAXI_R_s		R;
	logic				RVALID;
} t_reg_resp_s;

endpackage
