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
module pulp_io_tb;

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
	import udma_cfg_pkg::*;
	localparam PAD_NUM = 4;

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

BIPAD_IF PAD_GPIO[PAD_NUM-1:0]();
BIPAD_IF PAD_UART_RX[N_UART-1:0]();
BIPAD_IF PAD_UART_TX[N_UART-1:0]();


pulp_io #(
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

	.sys_clk_i       (sys_clk_i          ),
	.sys_rst_ni      (sys_resetn_i       ),
	.periph_clk_i    (periph_clk_i       ),

	.udma_apb_paddr  ( APB_BUS.paddr     ),
	.udma_apb_pwdata ( APB_BUS.pwdata    ),
	.udma_apb_pwrite ( APB_BUS.pwrite    ),
	.udma_apb_psel   ( APB_BUS.psel      ),
	.udma_apb_penable( APB_BUS.penable   ),
	.udma_apb_prdata ( APB_BUS.prdata    ),
	.udma_apb_pready ( APB_BUS.pready    ),
	.udma_apb_pslverr( APB_BUS.pslverr   ),

	.events_o        ( events_o          ),
	.event_valid_i   ( event_valid_i     ),
	.event_data_i    ( event_data_i      ),
	.event_ready_o   ( event_ready_o     ),

	.PAD_GPIO        ( PAD_GPIO          ),
	.PAD_UART_RX     ( PAD_UART_RX       ),
	.PAD_UART_TX     ( PAD_UART_TX       )
	
);

always #10ns sys_clk_i    = ~sys_clk_i;
always #20ns periph_clk_i = ~periph_clk_i;

for (genvar i = 0; i < N_UART; i++) begin
	uart_tb_rx #(

		.ID (i),
		.BAUD_RATE(1470588)

	)i_uart_tb_rx (
		.rx(PAD_UART_TX[i].OUT), 
		.tx(PAD_UART_RX[i].IN), 
		.rx_en(1'b1), 
		.tx_en(1'b1),
		.word_done()
	);
	assign PAD_UART_TX[i].IN = 1'b1;

end

import apb_test_pkg::PERIPH_ID_OFFSET;

//localparam BYTES = 16;

int words[N_UART-1:0];
int l2offset[N_UART-1:0];

int errors;
int transactions;

initial begin

	//$readmemh("tcdm_stim.txt", pulp_io_tb.i_tcdm_model.memory);

	sys_clk_i = 0;
	periph_clk_i = 0;
	#30ns;
	sys_resetn_i	= 0;
	#30ns;
	sys_resetn_i	= 1;

	errors = 0;
	transactions = 0;



	for (int i = 0; i < N_UART; i++) begin
		words[i] = $urandom_range(1,64);         // transmit up to 128 bytes
		l2offset[i] = $urandom_range(i*128,i*128+64); // when allocating memory, account for the worst case 

		$display("[%0d] WORDS = %0d, L2OFFSET = %0d",i,words[i]+1,l2offset[i]);
		for (int j = 0; j < words[i]; j++) begin
			pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j] = $urandom;
		end
		pulp_io_tb.i_tcdm_model.memory[l2offset[i] + words[i]] = 32'h0000000a; // make sure at least the last byte trigger the print (at the receiver)


		apb_test_pkg::udma_core_cg_en(i,sys_clk_i,APB_BUS); // enabling clock for periph id i
		apb_test_pkg::udma_uart_setup(PERIPH_ID_OFFSET + i*128,sys_clk_i,APB_BUS); // enable the transmission
		
		apb_test_pkg::udma_uart_write_tx_saddr(PERIPH_ID_OFFSET + i*128,32'h1C000000 + l2offset[i]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_uart_write_tx_size(PERIPH_ID_OFFSET + i*128,(words[i]+1)*4,sys_clk_i,APB_BUS); // configure the transfer size

		apb_test_pkg::udma_uart_read_rx_saddr(PERIPH_ID_OFFSET + i*128,32'h1C000800 + l2offset[i]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_uart_read_rx_size(PERIPH_ID_OFFSET + i*128,(words[i]+1)*4,sys_clk_i,APB_BUS); // configure the transfer size

		
		apb_test_pkg::udma_uart_read(PERIPH_ID_OFFSET + i*128,sys_clk_i,APB_BUS); // start reception
		apb_test_pkg::udma_uart_write(PERIPH_ID_OFFSET + i*128,sys_clk_i,APB_BUS); // start transmission
	end

	#10000us;

	// artificial error injected here
	pulp_io_tb.i_tcdm_model.memory[446] = 0;

	$writememh("tcdm_stim_out.txt", pulp_io_tb.i_tcdm_model.memory);

	for (int i = 0; i < N_UART; i++) begin
		for (int j = 0; j < words[i]; j++) begin
			transactions = transactions + 1;
			if (pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j] !== pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j + 512]) begin
				errors = errors + 1;
				$display("ERROR @ %8x --> TX = %8x, RX = %8x", 32'h1C000800 + (l2offset[i] + j)*4, pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j],pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j + 512]);
			end else begin
				$display("TX = %8x, RX = %8x",pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j],pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j + 512]);
			end
		end
	end

	if (errors == 0) begin
		$display(":-) TEST PASS: %0d/%0d PASSED, %0d FAILED",transactions-errors,transactions, errors);
	end else begin
		$error(":'( TEST FAIL: %0d/%0d PASSED, %0d FAILED",transactions-errors,transactions, errors);
	end

	#1ms;

	$stop;

end
	
endmodule