/* 
 * Copyright (C) 2018-2020 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 *
 *                http://solderpad.org/licenses/SHL-0.51. 
 *
 * Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * Alfio Di Mauro <adimauro@iis.ee.ethz.ch>
 *
 */
module udma_subsystem_tb;

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
	logic clk_delayed_i;
	logic [1:0] tcdm_req_i;
	logic [1:0] tcdm_gnt_o;
	logic [1:0][31:0] tcdm_add_i;
	logic [1:0] tcdm_wen_i;
	logic [1:0][3:0] tcdm_be_i;
	logic [1:0][31:0] tcdm_data_i;
	logic [1:0][31:0] tcdm_r_data_o;
	logic [1:0] tcdm_r_valid_o;

	apb_test_pkg::APB_BUS_t APB_BUS;

tcdm_model #(
	.MP(2), 
	.PROB_STALL(0.5),
	.BASE_ADDR(32'h1C000000)

	) i_tcdm_model (

	.clk_i         (sys_clk_i      ),
	.clk_delayed_i (clk_delayed_i  ),
	.randomize_i   (1'b0           ),
	.enable_i      (dft_cg_enable_i),
	.stallable_i   (1'b1           ),
	.tcdm_wen_i    (tcdm_wen_i     ),
	.tcdm_req_i    (tcdm_req_i     ),
	.tcdm_gnt_o    (tcdm_gnt_o     ),
	.tcdm_add_i    (tcdm_add_i     ),
	.tcdm_be_i     (tcdm_be_i      ),
	.tcdm_data_i   (tcdm_data_i    ),
	.tcdm_r_valid_o(tcdm_r_valid_o ),
	.tcdm_r_data_o (tcdm_r_data_o  )
);

BIPAD_IF pad_uart_rx();
BIPAD_IF pad_uart_tx();

BIPAD_IF PAD_DATA0();
BIPAD_IF PAD_DATA1();
BIPAD_IF PAD_DATA2();
BIPAD_IF PAD_DATA3();
BIPAD_IF PAD_CLK();
BIPAD_IF PAD_WRD();

udma_subsystem #(
	.APB_ADDR_WIDTH(32)
) i_dut (

	.L2_ro_wen_o     (tcdm_wen_i[0]      ),
	.L2_ro_req_o     (tcdm_req_i[0]      ),
	.L2_ro_gnt_i     (tcdm_gnt_o[0]      ),
	.L2_ro_addr_o    (tcdm_add_i[0]      ),
	.L2_ro_be_o      (tcdm_be_i[0]       ),
	.L2_ro_wdata_o   (tcdm_data_i[0]     ),
	.L2_ro_rvalid_i  (tcdm_r_valid_o[0]  ),
	.L2_ro_rdata_i   (tcdm_r_data_o[0]   ),

	.L2_wo_wen_o     (tcdm_wen_i[1]      ),
	.L2_wo_req_o     (tcdm_req_i[1]      ),
	.L2_wo_gnt_i     (tcdm_gnt_o[1]      ),
	.L2_wo_addr_o    (tcdm_add_i[1]      ),
	.L2_wo_wdata_o   (tcdm_data_i[1]     ),
	.L2_wo_be_o      (tcdm_be_i[1]       ),
	.L2_wo_rvalid_i  (tcdm_r_valid_o[1]  ),
	.L2_wo_rdata_i   (tcdm_r_data_o[1]   ),

	.dft_test_mode_i (1'b0               ),
	.dft_cg_enable_i (1'b0               ),

	.sys_clk_i       (sys_clk_i       ),
	.sys_resetn_i    (sys_resetn_i    ),
	.periph_clk_i    (periph_clk_i    ),

	.udma_apb_paddr  ( APB_BUS.paddr     ),
	.udma_apb_pwdata ( APB_BUS.pwdata    ),
	.udma_apb_pwrite ( APB_BUS.pwrite    ),
	.udma_apb_psel   ( APB_BUS.psel      ),
	.udma_apb_penable( APB_BUS.penable   ),
	.udma_apb_prdata ( APB_BUS.prdata    ),
	.udma_apb_pready ( APB_BUS.pready    ),
	.udma_apb_pslverr( APB_BUS.pslverr   ),

	.events_o        (events_o           ),
	.event_valid_i   (event_valid_i      ),
	.event_data_i    (event_data_i       ),
	.event_ready_o   (event_ready_o      ),

	.PAD_DATA0 (PAD_DATA0),
	.PAD_DATA1 (PAD_DATA1),
	.PAD_DATA2 (PAD_DATA2),
	.PAD_DATA3 (PAD_DATA3),
	.PAD_CLK   (PAD_CLK  ),
	.PAD_WRD   (PAD_WRD  ),

	.pad_uart_rx     (pad_uart_rx        ),
	.pad_uart_tx     (pad_uart_tx        )
	
);

always #10ns sys_clk_i = ~sys_clk_i;
always #20ns periph_clk_i = ~periph_clk_i;

uart_tb_rx i_uart_tb_rx (
	.rx(pad_uart_tx.OUT), 
	.tx(pad_uart_rx.IN), 
	.rx_en(1'b1), 
	.tx_en(1'b1),
	.word_done(word_done)
);

initial begin

	$readmemh("tcdm_stim.txt", udma_subsystem_tb.i_tcdm_model.memory);

	sys_clk_i = 0;
	periph_clk_i = 0;
	#30ns;
	sys_resetn_i	= 0;
	#30ns;
	sys_resetn_i	= 1;
	//pad_uart_tx[0].IN = 1'b0;
	//pad_uart_tx[1].IN = 1'b0;

	apb_test_pkg::udma_core_cg_en(0,sys_clk_i,APB_BUS); // enabling clock for periph id 0
	apb_test_pkg::udma_uart0_tx_en(sys_clk_i,APB_BUS); // enable the transmission
	apb_test_pkg::udma_uart0_write_tx_saddr(32'h1C000000,sys_clk_i,APB_BUS); // write L2 start address
	apb_test_pkg::udma_uart0_write_tx_size(7,sys_clk_i,APB_BUS); // configure the transfer size

	#1us;

	apb_test_pkg::udma_uart1_rx_en(sys_clk_i,APB_BUS); // enable the transmission
	apb_test_pkg::udma_uart1_read_rx_saddr(32'h1C000800,sys_clk_i,APB_BUS); // write L2 start address
	apb_test_pkg::udma_uart1_read_rx_size(7,sys_clk_i,APB_BUS); // configure the transfer size
	apb_test_pkg::udma_uart0_write(sys_clk_i,APB_BUS); // start transmission
	apb_test_pkg::udma_uart1_read(sys_clk_i,APB_BUS); // start transmission

	#10us;

	$stop;

end
	
endmodule