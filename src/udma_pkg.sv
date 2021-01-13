package udma_pkg;

	localparam L2_DATA_WIDTH  = 32;
	localparam L2_ADDR_WIDTH  = 19;   //L2 addr space of 2MB
	localparam CAM_DATA_WIDTH = 8;
	localparam APB_ADDR_WIDTH = 12;  //APB slaves are 4KB by default
	localparam TRANS_SIZE     = 20;  //max uDMA transaction size of 1MB
	localparam L2_AWIDTH_NOAL = L2_ADDR_WIDTH + 2;
	localparam DEST_SIZE               = 2;
	localparam N_FILTER                = 1;
	localparam N_STREAMS               = N_FILTER + 1;     //--- the additional stream goes outside uDMA (to SNE)
	localparam STREAM_ID_WIDTH         = $clog2(N_STREAMS);

	typedef struct packed {
	    logic [L2_AWIDTH_NOAL-1 : 0] tx_cfg_startaddr   ;
	    logic     [TRANS_SIZE-1 : 0] tx_cfg_size        ;
	    logic                        tx_cfg_continuous  ;
	    logic                        tx_cfg_en          ;
	    logic                        tx_cfg_clr         ;
	    logic               [31 : 0] tx_ch_data         ;
	    logic                        tx_ch_valid        ;
	    logic                        tx_ch_ready        ;
	    logic                [1 : 0] tx_ch_datasize     ;
	    logic      [DEST_SIZE-1 : 0] tx_ch_destination  ;
	    logic                        tx_ch_events       ;
	    logic                        tx_ch_en           ;
	    logic                        tx_ch_pending      ;
	    logic [L2_AWIDTH_NOAL-1 : 0] tx_ch_curr_addr    ;
	    logic     [TRANS_SIZE-1 : 0] tx_ch_bytes_left   ;
	    logic                        tx_ch_req          ;
	    logic                        tx_ch_gnt          ;
	} udma_lin_tx_ch_t;

	typedef struct packed {
		logic [L2_AWIDTH_NOAL-1 : 0] rx_cfg_startaddr   ;
		logic     [TRANS_SIZE-1 : 0] rx_cfg_size        ;
		logic                        rx_cfg_continuous  ;
		logic                        rx_cfg_en          ;
		logic                        rx_cfg_clr         ;
		logic               [31 : 0] rx_ch_data         ;
		logic                        rx_ch_valid        ;
		logic                        rx_ch_ready        ;
		logic                [1 : 0] rx_ch_datasize     ;
		logic      [DEST_SIZE-1 : 0] rx_ch_destination  ;
		logic                        rx_ch_events       ;
		logic                        rx_ch_en           ;
		logic                        rx_ch_pending      ;
		logic [L2_AWIDTH_NOAL-1 : 0] rx_ch_curr_addr    ;
		logic     [TRANS_SIZE-1 : 0] rx_ch_bytes_left   ;
		logic                [1 : 0] rx_cfg_stream      ;
		logic [STREAM_ID_WIDTH-1: 0] rx_cfg_stream_id   ;
	} udma_lin_rx_ch_t;

	typedef struct packed {
	    logic                [1 : 0] tx_ext_datasize    ;
	    logic      [DEST_SIZE-1 : 0] tx_ext_destination ;
	    logic [L2_AWIDTH_NOAL-1 : 0] tx_ext_addr        ;
	    logic                        tx_ext_valid       ;
	    logic               [31 : 0] tx_ext_data        ;
	    logic                        tx_ext_ready       ;

	    logic                        tx_ext_req         ;
	    logic                        tx_ext_gnt         ;
	} udma_ext_tx_ch_t;

	typedef struct packed {
	    logic                 [1 : 0] rx_ext_datasize   ;
	    logic       [DEST_SIZE-1 : 0] rx_ext_destination;
	    logic  [L2_AWIDTH_NOAL-1 : 0] rx_ext_addr       ;
	    logic                         rx_ext_valid      ;
	    logic                [31 : 0] rx_ext_data       ;
	    logic                         rx_ext_ready      ;

	    logic                 [1 : 0] rx_ext_stream     ;
	    logic [STREAM_ID_WIDTH-1 : 0] rx_ext_stream_id  ;
	    logic                         rx_ext_sot        ;
	    logic                         rx_ext_eot        ;
	} udma_ext_rx_ch_t;


	typedef struct packed {
		logic                [31 : 0] stream_data       ;
		logic                 [1 : 0] stream_datasize   ;
		logic                         stream_valid      ;
		logic                         stream_sot        ;
		logic                         stream_eot        ;
		logic                         stream_ready      ;
	} udma_stream_t;
endpackage