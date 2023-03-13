`ifndef IVERILOG
package qdec_axi_pkg;
`endif

parameter	D_DWID	= 256;
parameter	D_AWID	= 64;
parameter	C_DWID	= 32;
parameter	C_AWID	= 32;
parameter	R_AWID	= 32;
parameter	R_DWID	= 32;

parameter	WID_USER	= 8;
parameter	WID_TID		= 8;

typedef enum logic [1:0] { 
	AXI_OKAY_RESP, 
	AXI_EXOKAY_RESP, 
	AXI_SLVERR_RESP, 
	AXI_DECERR_RESP
} t_AXI_RESP_e;

// typedef struct packed { 
// 	logic	[R_AWID-1:0]	AWADDR;
// 	logic	[WID_TID-1:0]	AWID;	
// } t_regAXI_AW_s;

// typedef struct packed { 
// 	logic	[R_DWID-1:0]	WDATA;
// 	logic	[R_DWID/8-1:0]	WSTRB;
// } t_regAXI_W_s;

// typedef struct packed { 
// 	logic	[R_AWID-1:0]	ARADDR;
// 	logic	[WID_TID-1:0]	ARID;	
// } t_regAXI_AR_s;

// typedef struct packed { 
// 	t_AXI_RESP_e			BRESP;
// 	logic	[WID_TID-1:0]	BID;	
// } t_regAXI_B_s;

// typedef struct packed {
// 	logic	[R_DWID-1:0]	RDATA;
// 	t_AXI_RESP_e			RRESP;
// 	logic	[WID_TID-1:0]	RID;	
// } t_regAXI_R_s;

typedef struct packed { 
	logic				clk_en;
	// t_regAXI_AW_s		AW;
	logic	[R_AWID-1:0]	AWADDR;
	logic	[WID_TID-1:0]	AWID;	
	logic				AWVALID;
	// t_regAXI_W_s		W;
	logic	[R_DWID-1:0]	WDATA;
	logic	[R_DWID/8-1:0]	WSTRB;
	logic				WVALID;
	// t_regAXI_AR_s		AR;
	logic	[R_AWID-1:0]	ARADDR;
	logic	[WID_TID-1:0]	ARID;	
	logic				ARVALID;
	logic				BREADY;
	logic				RREADY;
} t_reg_req_s;

typedef struct packed { 
	logic				AWREADY;
	logic				WREADY;
	logic				ARREADY;
	// t_regAXI_B_s		B;
	t_AXI_RESP_e			BRESP;
	logic	[WID_TID-1:0]	BID;	
	logic				BVALID;
	// t_regAXI_R_s		R;
	logic	[R_DWID-1:0]	RDATA;
	t_AXI_RESP_e			RRESP;
	logic	[WID_TID-1:0]	RID;
	logic				RVALID;
} t_reg_resp_s;

parameter	[R_DWID-1:0]	REG_BAD_DATA	= 32'hDEAD_ADDE;

`ifndef IVERILOG
endpackage
`endif
