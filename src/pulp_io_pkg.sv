package pulp_io_pkg;
	// as a general rule, every peripherla MUST provide input,output and output enable signals
	
	// uart structure
	typedef struct packed {
		logic tx_o;
		logic tx_oe;
	} uart_to_pad_t;
	typedef struct packed {
		logic rx_i;
	} pad_to_uart_t;

	// qspi structure
	typedef struct packed {
		logic sd0_o;
		logic sd0_oe;
		logic sd1_o;
		logic sd1_oe;
		logic sd2_o;
		logic sd2_oe;
		logic sd3_o;
		logic sd3_oe;
		logic csn0_o;
		logic csn0_oe;
		logic csn1_o;
		logic csn1_oe;
		logic csn2_o;
		logic csn2_oe;
		logic csn3_o;
		logic csn3_oe;
		logic sck_o;
		logic sck_oe;
	} qspi_to_pad_t;
	typedef struct packed {
		logic sd0_i;
		logic sd1_i;
		logic sd2_i;
		logic sd3_i;
	} pad_to_qspi_t;

	// i2c structure
	typedef struct packed {
	   logic sda_o;
	   logic sda_oe;
	   logic scl_o;
	   logic scl_oe;
	  } i2c_to_pad_t;
	typedef struct packed {
	   logic sda_i;
	   logic scl_i;
	 } pad_to_i2c_t;

	 // cpi structure
	typedef struct packed{
		logic pclk_i;
		logic hsync_i;
		logic vsync_i;
		logic data0_i;
		logic data1_i;
		logic data2_i;
		logic data3_i;
		logic data4_i;
		logic data5_i;
		logic data6_i;
		logic data7_i;
	}pad_to_cpi_t;

	typedef struct packed {
	    logic asa_o;
	    logic asa_oe;
	    logic are_o;
	    logic are_oe;
	    logic asy_o;
	    logic asy_oe;
	    logic ynrst_o;
	    logic ynrst_oe;
	    logic yclk_o;
	    logic yclk_oe;
	    logic sxy_o;
	    logic sxy_oe;
	    logic xclk_o;
	    logic xclk_oe;
	    logic xnrst_o;
	    logic xnrst_oe;

	    logic cfg0_o;
		logic cfg0_oe;	    
	    logic cfg1_o;
		logic cfg1_oe;	    
	    logic cfg2_o;
		logic cfg2_oe;	    
	    logic cfg3_o;
		logic cfg3_oe;	    
	    logic cfg4_o;
		logic cfg4_oe;	    
	    logic cfg5_o;
		logic cfg5_oe;	    
	    logic cfg6_o;
		logic cfg6_oe;	    
	    logic cfg7_o;
		logic cfg7_oe;	    

	}dvsi_to_pad_t;
	typedef struct packed{
		logic xydata0_i;
		logic xydata1_i;
		logic xydata2_i;
		logic xydata3_i;
		logic xydata4_i;
		logic xydata5_i;
		logic xydata6_i;
		logic xydata7_i;
		logic on0_i;
		logic on1_i;
		logic on2_i;
		logic on3_i;
		logic off0_i;
		logic off1_i;
		logic off2_i;
		logic off3_i;
	}pad_to_dvsi_t;
endpackage