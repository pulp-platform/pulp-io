module udma_subsystem_tb;


	logic L2_ro_wen_o;
	logic L2_ro_req_o;
	logic L2_ro_gnt_i;
	logic [31:0] L2_ro_addr_o;
	logic [32/8-1:0] L2_ro_be_o;
	logic [31:0] L2_ro_wdata_o;
	logic L2_ro_rvalid_i;
	logic [31:0] L2_ro_rdata_i;
	logic L2_wo_wen_o;
	logic L2_wo_req_o;
	logic L2_wo_gnt_i;
	logic [31:0] L2_wo_addr_o;
	logic [31:0] L2_wo_wdata_o;
	logic [32/8-1:0] L2_wo_be_o;
	logic L2_wo_rvalid_i;
	logic [31:0] L2_wo_rdata_i;
	logic dft_test_mode_i;
	logic dft_cg_enable_i;
	logic sys_clk_i;
	logic sys_resetn_i;
	logic periph_clk_i;
	logic [31:0] udma_apb_paddr;
	logic [31:0] udma_apb_pwdata;
	logic udma_apb_pwrite;
	logic udma_apb_psel;
	logic udma_apb_penable;
	logic [31:0] udma_apb_prdata;
	logic udma_apb_pready;
	logic udma_apb_pslverr;
	logic [32*4-1:0] events_o;
	logic event_valid_i;
	logic [7:0] event_data_i;
	logic event_ready_o;
	logic  spi_clk;
	logic [3:0] spi_csn;
	logic [3:0] spi_oen;
	logic [3:0] spi_sdo;
	logic [3:0] spi_sdi;
	logic [1:0] i2c_scl_i;
	logic [1:0] i2c_scl_o;
	logic [1:0] i2c_scl_oe;
	logic [1:0] i2c_sda_i;
	logic [1:0] i2c_sda_o;
	logic [1:0] i2c_sda_oe;
	logic cam_clk_i;
	logic [7:0] cam_data_i;
	logic cam_hsync_i;
	logic cam_vsync_i;
	logic uart_rx_i;
	logic uart_tx_o;
	logic sdio_clk_o;
	logic sdio_cmd_o;
	logic sdio_cmd_i;
	logic sdio_cmd_oen_o;
	logic [3:0] sdio_data_o;
	logic [3:0] sdio_data_i;
	logic [3:0] sdio_data_oen_o;
	logic i2s_slave_sd0_i;
	logic i2s_slave_sd1_i;
	logic i2s_slave_ws_i;
	logic i2s_slave_ws_o;
	logic i2s_slave_ws_oe;
	logic i2s_slave_sck_i;
	logic i2s_slave_sck_o;
	logic i2s_slave_sck_oe;
udma_subsystem #(
	.L2_ADDR_WIDTH (13),
	.APB_ADDR_WIDTH(32),
	.N_SPI         (1),
	.N_UART        (1),
	.N_I2C         (2)
) i_udma_subsystem (
	.L2_ro_wen_o     (L2_ro_wen_o     ),
	.L2_ro_req_o     (L2_ro_req_o     ),
	.L2_ro_gnt_i     (L2_ro_gnt_i     ),
	.L2_ro_addr_o    (L2_ro_addr_o    ),
	.L2_ro_be_o      (L2_ro_be_o      ),
	.L2_ro_wdata_o   (L2_ro_wdata_o   ),
	.L2_ro_rvalid_i  (L2_ro_rvalid_i  ),
	.L2_ro_rdata_i   (L2_ro_rdata_i   ),
	.L2_wo_wen_o     (L2_wo_wen_o     ),
	.L2_wo_req_o     (L2_wo_req_o     ),
	.L2_wo_gnt_i     (L2_wo_gnt_i     ),
	.L2_wo_addr_o    (L2_wo_addr_o    ),
	.L2_wo_wdata_o   (L2_wo_wdata_o   ),
	.L2_wo_be_o      (L2_wo_be_o      ),
	.L2_wo_rvalid_i  (L2_wo_rvalid_i  ),
	.L2_wo_rdata_i   (L2_wo_rdata_i   ),
	.dft_test_mode_i (dft_test_mode_i ),
	.dft_cg_enable_i (dft_cg_enable_i ),
	.sys_clk_i       (sys_clk_i       ),
	.sys_resetn_i    (sys_resetn_i    ),
	.periph_clk_i    (periph_clk_i    ),
	.udma_apb_paddr  (udma_apb_paddr  ),
	.udma_apb_pwdata (udma_apb_pwdata ),
	.udma_apb_pwrite (udma_apb_pwrite ),
	.udma_apb_psel   (udma_apb_psel   ),
	.udma_apb_penable(udma_apb_penable),
	.udma_apb_prdata (udma_apb_prdata ),
	.udma_apb_pready (udma_apb_pready ),
	.udma_apb_pslverr(udma_apb_pslverr),
	.events_o        (events_o        ),
	.event_valid_i   (event_valid_i   ),
	.event_data_i    (event_data_i    ),
	.event_ready_o   (event_ready_o   ),
	.spi_clk         (spi_clk         ),
	.spi_csn         (spi_csn         ),
	.spi_oen         (spi_oen         ),
	.spi_sdo         (spi_sdo         ),
	.spi_sdi         (spi_sdi         ),
	.i2c_scl_i       (i2c_scl_i       ),
	.i2c_scl_o       (i2c_scl_o       ),
	.i2c_scl_oe      (i2c_scl_oe      ),
	.i2c_sda_i       (i2c_sda_i       ),
	.i2c_sda_o       (i2c_sda_o       ),
	.i2c_sda_oe      (i2c_sda_oe      ),
	.cam_clk_i       (cam_clk_i       ),
	.cam_data_i      (cam_data_i      ),
	.cam_hsync_i     (cam_hsync_i     ),
	.cam_vsync_i     (cam_vsync_i     ),
	.uart_rx_i       (uart_rx_i       ),
	.uart_tx_o       (uart_tx_o       ),
	.sdio_clk_o      (sdio_clk_o      ),
	.sdio_cmd_o      (sdio_cmd_o      ),
	.sdio_cmd_i      (sdio_cmd_i      ),
	.sdio_cmd_oen_o  (sdio_cmd_oen_o  ),
	.sdio_data_o     (sdio_data_o     ),
	.sdio_data_i     (sdio_data_i     ),
	.sdio_data_oen_o (sdio_data_oen_o ),
	.i2s_slave_sd0_i (i2s_slave_sd0_i ),
	.i2s_slave_sd1_i (i2s_slave_sd1_i ),
	.i2s_slave_ws_i  (i2s_slave_ws_i  ),
	.i2s_slave_ws_o  (i2s_slave_ws_o  ),
	.i2s_slave_ws_oe (i2s_slave_ws_oe ),
	.i2s_slave_sck_i (i2s_slave_sck_i ),
	.i2s_slave_sck_o (i2s_slave_sck_o ),
	.i2s_slave_sck_oe(i2s_slave_sck_oe)
);

initial begin

	//$fatal

end
	
endmodule