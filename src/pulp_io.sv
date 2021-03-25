module pulp_io 

	// signal bitwidths
	import udma_pkg::L2_DATA_WIDTH;  
	import udma_pkg::L2_ADDR_WIDTH;  
	import apb_gpio_pkg::*;
	import uart_pkg::*;
	import qspi_pkg::*;
	import i2c_pkg::*;
	import cpi_pkg::*;
	import dvsi_pkg::*;
	import hyper_pkg::*;
	import udma_pkg::udma_stream_req_t;
	import udma_pkg::udma_stream_rsp_t;
	// peripherals and channels configuration
	import udma_cfg_pkg::*;  

	#(
	    parameter APB_ADDR_WIDTH = 12,  //APB slaves are 4KB by default
	    parameter PAD_NUM        = 4
	)
	(

	// udma reset
	input  logic                       sys_rst_ni     ,
	// udma core clock
	input  logic                       sys_clk_i      ,
	// peripheral clock
	input  logic                       periph_clk_i   ,
	
	// memory ports
	// read only port
	output logic                       L2_ro_wen_o    ,
	output logic                       L2_ro_req_o    ,
	input  logic                       L2_ro_gnt_i    ,
	output logic                [31:0] L2_ro_addr_o   ,
	output logic [L2_DATA_WIDTH/8-1:0] L2_ro_be_o     ,
	output logic   [L2_DATA_WIDTH-1:0] L2_ro_wdata_o  ,
	input  logic                       L2_ro_rvalid_i ,
	input  logic   [L2_DATA_WIDTH-1:0] L2_ro_rdata_i  ,

	// write only port
	output logic                       L2_wo_wen_o    ,
	output logic                       L2_wo_req_o    ,
	input  logic                       L2_wo_gnt_i    ,
	output logic                [31:0] L2_wo_addr_o   ,
	output logic   [L2_DATA_WIDTH-1:0] L2_wo_wdata_o  ,
	output logic [L2_DATA_WIDTH/8-1:0] L2_wo_be_o     ,
	input  logic                       L2_wo_rvalid_i ,
	input  logic   [L2_DATA_WIDTH-1:0] L2_wo_rdata_i  ,

	input  logic                       dft_test_mode_i,
	input  logic                       dft_cg_enable_i,

	// external streamer
	output udma_stream_req_t          udma_stream_req,
	input  udma_stream_rsp_t          udma_stream_rsp,


	input  logic  [APB_ADDR_WIDTH-1:0] udma_apb_paddr,
	input  logic                [31:0] udma_apb_pwdata,
	input  logic                       udma_apb_pwrite,
	input  logic                       udma_apb_psel,
	input  logic                       udma_apb_penable,
	output logic                [31:0] udma_apb_prdata,
	output logic                       udma_apb_pready,
	output logic                       udma_apb_pslverr,

	input  logic  [APB_ADDR_WIDTH-1:0] gpio_apb_paddr,
	input  logic                [31:0] gpio_apb_pwdata,
	input  logic                       gpio_apb_pwrite,
	input  logic                       gpio_apb_psel,
	input  logic                       gpio_apb_penable,
	output logic                [31:0] gpio_apb_prdata,
	output logic                       gpio_apb_pready,
	output logic                       gpio_apb_pslverr,

	output logic           [31:0][3:0] events_o,
	input  logic                       event_valid_i,
	input  logic                 [7:0] event_data_i,
	output logic                       event_ready_o,

	output logic                      interrupt_o,
	output logic        [PAD_NUM-1:0] gpio_in_sync_o,
	output logic   [PAD_NUM-1:0][3:0] gpio_padcfg_o,
  // triggers for DVSI readout
  input logic                       dvsi_saer_frame_timer_i,
  input logic                       dvsi_framebuf_frame_timer_i,
	//--- IO peripheral pads
	// GPIOS
	// PAD SIGNALS CONNECTION
	output  gpio_to_pad_t                gpio_to_pad,
	input   pad_to_gpio_t                pad_to_gpio,
	// UART
	output  uart_to_pad_t [  N_UART-1:0] uart_to_pad,
	input   pad_to_uart_t [  N_UART-1:0] pad_to_uart,
	// I2C
	output  i2c_to_pad_t  [   N_I2C-1:0] i2c_to_pad,
	input   pad_to_i2c_t  [   N_I2C-1:0] pad_to_i2c,
	// QSPI
	output  qspi_to_pad_t [ N_QSPIM-1:0] qspi_to_pad,
	input   pad_to_qspi_t [ N_QSPIM-1:0] pad_to_qspi,
	//CPI
	input   pad_to_cpi_t   [   N_CPI-1:0] pad_to_cpi,
	// DVSI
	output  dvsi_to_pad_t [  N_DVSI-1:0] dvsi_to_pad,
	input   pad_to_dvsi_t [  N_DVSI-1:0] pad_to_dvsi,
	// HYPER
	output  hyper_to_pad_t [ N_HYPER-1:0] hyper_to_pad,
	input   pad_to_hyper_t [ N_HYPER-1:0] pad_to_hyper
	
);

	///////////////////////////////////////////////////////////////
	//  █████╗ ██████╗ ██████╗      ██████╗ ██████╗ ██╗ ██████╗  //
	// ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝ ██╔══██╗██║██╔═══██╗ //
	// ███████║██████╔╝██████╔╝    ██║  ███╗██████╔╝██║██║   ██║ //
	// ██╔══██║██╔═══╝ ██╔══██╗    ██║   ██║██╔═══╝ ██║██║   ██║ //
	// ██║  ██║██║     ██████╔╝    ╚██████╔╝██║     ██║╚██████╔╝ //
	// ╚═╝  ╚═╝╚═╝     ╚═════╝      ╚═════╝ ╚═╝     ╚═╝ ╚═════╝  //
	///////////////////////////////////////////////////////////////

	apb_gpio_wrap #(.APB_ADDR_WIDTH(APB_ADDR_WIDTH), .PAD_NUM(PAD_NUM)) i_apb_gpio_wrap (
		.clk_i          ( sys_clk_i        ),
		.rst_ni         ( sys_rst_ni       ),
		.dft_cg_enable_i( dft_cg_enable_i  ),
		.PADDR          ( gpio_apb_paddr   ),
		.PWDATA         ( gpio_apb_pwdata  ),
		.PWRITE         ( gpio_apb_pwrite  ),
		.PSEL           ( gpio_apb_psel    ),
		.PENABLE        ( gpio_apb_penable ),
		.PRDATA         ( gpio_apb_prdata  ),
		.PREADY         ( gpio_apb_pready  ),
		.PSLVERR        ( gpio_apb_pslverr ),
		.interrupt_o    ( interrupt_o      ),
		.gpio_in_sync_o ( gpio_in_sync_o   ),
		.gpio_padcfg_o  ( gpio_padcfg_o    ),
		// BI-PAD signals
		.gpio_to_pad    ( gpio_to_pad      ),
		.pad_to_gpio    ( pad_to_gpio      )
	);

	////////////////////////////////////////////////////////////////////////////////////////////////
	// ██╗   ██╗██████╗ ███╗   ███╗ █████╗     ███████╗██╗   ██╗██████╗ ███████╗██╗   ██╗███████╗ //
	// ██║   ██║██╔══██╗████╗ ████║██╔══██╗    ██╔════╝██║   ██║██╔══██╗██╔════╝╚██╗ ██╔╝██╔════╝ //
	// ██║   ██║██║  ██║██╔████╔██║███████║    ███████╗██║   ██║██████╔╝███████╗ ╚████╔╝ ███████╗ //
	// ██║   ██║██║  ██║██║╚██╔╝██║██╔══██║    ╚════██║██║   ██║██╔══██╗╚════██║  ╚██╔╝  ╚════██║ //
	// ╚██████╔╝██████╔╝██║ ╚═╝ ██║██║  ██║    ███████║╚██████╔╝██████╔╝███████║   ██║   ███████║ //
	//  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝ //
	////////////////////////////////////////////////////////////////////////////////////////////////

	udma_subsystem #(.APB_ADDR_WIDTH(APB_ADDR_WIDTH)) i_udma_subsystem (
	.sys_resetn_i        ( sys_rst_ni        ),
	.sys_clk_i           ( sys_clk_i         ),
	.periph_clk_i        ( periph_clk_i      ),
	.L2_ro_wen_o         ( L2_ro_wen_o       ),
	.L2_ro_req_o         ( L2_ro_req_o       ),
	.L2_ro_gnt_i         ( L2_ro_gnt_i       ),
	.L2_ro_addr_o        ( L2_ro_addr_o      ),
	.L2_ro_be_o          ( L2_ro_be_o        ),
	.L2_ro_wdata_o       ( L2_ro_wdata_o     ),
	.L2_ro_rvalid_i      ( L2_ro_rvalid_i    ),
	.L2_ro_rdata_i       ( L2_ro_rdata_i     ),
	.L2_wo_wen_o         ( L2_wo_wen_o       ),
	.L2_wo_req_o         ( L2_wo_req_o       ),
	.L2_wo_gnt_i         ( L2_wo_gnt_i       ),
	.L2_wo_addr_o        ( L2_wo_addr_o      ),
	.L2_wo_wdata_o       ( L2_wo_wdata_o     ),
	.L2_wo_be_o          ( L2_wo_be_o        ),
	.L2_wo_rvalid_i      ( L2_wo_rvalid_i    ),
	.L2_wo_rdata_i       ( L2_wo_rdata_i     ),
	.dft_test_mode_i     ( dft_test_mode_i   ),
	.dft_cg_enable_i     ( dft_cg_enable_i   ),
	.udma_apb_paddr      ( udma_apb_paddr    ),
	.udma_apb_pwdata     ( udma_apb_pwdata   ),
	.udma_apb_pwrite     ( udma_apb_pwrite   ),
	.udma_apb_psel       ( udma_apb_psel     ),
	.udma_apb_penable    ( udma_apb_penable  ),
	.udma_apb_prdata     ( udma_apb_prdata   ),
	.udma_apb_pready     ( udma_apb_pready   ),
	.udma_apb_pslverr    ( udma_apb_pslverr  ),
	.udma_stream_req     ( udma_stream_req   ),
	.udma_stream_rsp     ( udma_stream_rsp   ),
  .dvsi_saer_frame_timer_i,
  .dvsi_framebuf_frame_timer_i,
	.events_o            ( events_o          ),
	.event_valid_i       ( event_valid_i     ),
	.event_data_i        ( event_data_i      ),
	.event_ready_o       ( event_ready_o     ),
	.uart_to_pad         ( uart_to_pad       ),
	.pad_to_uart         ( pad_to_uart       ),
	.i2c_to_pad          ( i2c_to_pad        ),
	.pad_to_i2c          ( pad_to_i2c        ),
	.qspi_to_pad         ( qspi_to_pad       ),
	.pad_to_qspi         ( pad_to_qspi       ),
	.pad_to_cpi          ( pad_to_cpi        ),
	.dvsi_to_pad         ( dvsi_to_pad       ),
	.pad_to_dvsi         ( pad_to_dvsi       ),
	.hyper_to_pad        ( hyper_to_pad      ),
	.pad_to_hyper        ( pad_to_hyper      )
);


endmodule
