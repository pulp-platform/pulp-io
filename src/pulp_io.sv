module pulp_io 

	// signal bitwidths
	import udma_pkg::L2_DATA_WIDTH;  
	import udma_pkg::L2_ADDR_WIDTH;  

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

	//--- IO pads
	// GPIO BI-PADS
	BIPAD_IF.PERIPH_SIDE PAD_GPIO[PAD_NUM-1:0],
	// I2C BI-PADS
	BIPAD_IF.PERIPH_SIDE PAD_I2C_SCL[ N_I2C-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_I2C_SDA[ N_I2C-1:0],
	// UART BI-PADS
	BIPAD_IF.PERIPH_SIDE PAD_UART_RX[N_UART-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_UART_TX[N_UART-1:0],
	// QSPI
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_SCLK[     N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_CSN0[     N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_CSN1[     N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_CSN2[     N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_CSN3[     N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_MOSI_IO0[ N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_MISO_IO1[ N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_IO2[      N_QSPIM-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_QSPI_IO3[      N_QSPIM-1:0],
	// CPI
	BIPAD_IF.PERIPH_SIDE PAD_CPI_PCLK[        N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_VSYNCH[      N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_HSYNCH[      N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA0[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA1[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA2[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA3[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA4[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA5[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA6[       N_CPI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_CPI_DATA7[       N_CPI-1:0],
	// QSPI
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ASA[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ARE[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ASY[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_YNRST[     N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_YCLK[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_SXY[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XCLK[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XNRST[     N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ON0[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ON1[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ON2[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_ON3[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_OFF0[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_OFF1[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_OFF2[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_OFF3[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY0[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY1[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY2[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY3[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY4[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY5[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY6[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_XY7[       N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG0[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG1[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG2[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG3[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG4[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG5[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG6[      N_DVSI-1:0],
	BIPAD_IF.PERIPH_SIDE PAD_DVSI_CFG7[      N_DVSI-1:0]


	
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
		.PAD_GPIO       ( PAD_GPIO         )
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
	.events_o            ( events_o          ),
	.event_valid_i       ( event_valid_i     ),
	.event_data_i        ( event_data_i      ),
	.event_ready_o       ( event_ready_o     ),

	// BI-PAD signals
	.PAD_UART_RX         ( PAD_UART_RX       ),
	.PAD_UART_TX         ( PAD_UART_TX       ),
	
	.PAD_I2C_SCL         ( PAD_I2C_SCL       ),
	.PAD_I2C_SDA         ( PAD_I2C_SDA       ),

	.PAD_QSPI_SCLK       ( PAD_QSPI_SCLK     ),
	.PAD_QSPI_CSN0       ( PAD_QSPI_CSN0     ),
	.PAD_QSPI_CSN1       ( PAD_QSPI_CSN1     ),
	.PAD_QSPI_CSN2       ( PAD_QSPI_CSN2     ),
	.PAD_QSPI_CSN3       ( PAD_QSPI_CSN3     ),
	.PAD_QSPI_MOSI_IO0   ( PAD_QSPI_MOSI_IO0 ),
	.PAD_QSPI_MISO_IO1   ( PAD_QSPI_MISO_IO1 ),
	.PAD_QSPI_IO2        ( PAD_QSPI_IO2      ),
	.PAD_QSPI_IO3        ( PAD_QSPI_IO3      ),

	.PAD_CPI_PCLK        ( PAD_CPI_PCLK      ),
	.PAD_CPI_VSYNCH      ( PAD_CPI_VSYNCH    ),
	.PAD_CPI_HSYNCH      ( PAD_CPI_HSYNCH    ),
	.PAD_CPI_DATA0       ( PAD_CPI_DATA0     ),
	.PAD_CPI_DATA1       ( PAD_CPI_DATA1     ),
	.PAD_CPI_DATA2       ( PAD_CPI_DATA2     ),
	.PAD_CPI_DATA3       ( PAD_CPI_DATA3     ),
	.PAD_CPI_DATA4       ( PAD_CPI_DATA4     ),
	.PAD_CPI_DATA5       ( PAD_CPI_DATA5     ),
	.PAD_CPI_DATA6       ( PAD_CPI_DATA6     ),
	.PAD_CPI_DATA7       ( PAD_CPI_DATA7     ),

	.PAD_DVSI_ASA        ( PAD_DVSI_ASA      ),
	.PAD_DVSI_ARE        ( PAD_DVSI_ARE      ),
	.PAD_DVSI_ASY        ( PAD_DVSI_ASY      ),
	.PAD_DVSI_YNRST      ( PAD_DVSI_YNRST    ),
	.PAD_DVSI_YCLK       ( PAD_DVSI_YCLK     ),
	.PAD_DVSI_SXY        ( PAD_DVSI_SXY      ),
	.PAD_DVSI_XCLK       ( PAD_DVSI_XCLK     ),
	.PAD_DVSI_XNRST      ( PAD_DVSI_XNRST    ),
	.PAD_DVSI_ON0        ( PAD_DVSI_ON0      ),
	.PAD_DVSI_ON1        ( PAD_DVSI_ON1      ),
	.PAD_DVSI_ON2        ( PAD_DVSI_ON2      ),
	.PAD_DVSI_ON3        ( PAD_DVSI_ON3      ),
	.PAD_DVSI_OFF0       ( PAD_DVSI_OFF0     ),
	.PAD_DVSI_OFF1       ( PAD_DVSI_OFF1     ),
	.PAD_DVSI_OFF2       ( PAD_DVSI_OFF2     ),
	.PAD_DVSI_OFF3       ( PAD_DVSI_OFF3     ),
	.PAD_DVSI_XY0        ( PAD_DVSI_XY0      ),
	.PAD_DVSI_XY1        ( PAD_DVSI_XY1      ),
	.PAD_DVSI_XY2        ( PAD_DVSI_XY2      ),
	.PAD_DVSI_XY3        ( PAD_DVSI_XY3      ),
	.PAD_DVSI_XY4        ( PAD_DVSI_XY4      ),
	.PAD_DVSI_XY5        ( PAD_DVSI_XY5      ),
	.PAD_DVSI_XY6        ( PAD_DVSI_XY6      ),
	.PAD_DVSI_XY7        ( PAD_DVSI_XY7      ),
	.PAD_DVSI_CFG0       ( PAD_DVSI_CFG0     ),
	.PAD_DVSI_CFG1       ( PAD_DVSI_CFG1     ),
	.PAD_DVSI_CFG2       ( PAD_DVSI_CFG2     ),
	.PAD_DVSI_CFG3       ( PAD_DVSI_CFG3     ),
	.PAD_DVSI_CFG4       ( PAD_DVSI_CFG4     ),
	.PAD_DVSI_CFG5       ( PAD_DVSI_CFG5     ),
	.PAD_DVSI_CFG6       ( PAD_DVSI_CFG6     ),
	.PAD_DVSI_CFG7       ( PAD_DVSI_CFG7     )

);


endmodule