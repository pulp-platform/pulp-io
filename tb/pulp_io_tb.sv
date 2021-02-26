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
	import apb_gpio_pkg::*;
	import pulp_io_pkg::*;
	localparam PAD_NUM = 4;

	gpio_to_pad_t                gpio_to_pad;
	pad_to_gpio_t                pad_to_gpio;
	uart_to_pad_t [  N_UART-1:0] uart_to_pad;
	pad_to_uart_t [  N_UART-1:0] pad_to_uart;
	i2c_to_pad_t  [   N_I2C-1:0]  i2c_to_pad;
	pad_to_i2c_t  [   N_I2C-1:0]  pad_to_i2c;
	qspi_to_pad_t [ N_QSPIM-1:0] qspi_to_pad;
	pad_to_qspi_t [ N_QSPIM-1:0] pad_to_qspi;
	pad_to_cpi_t  [   N_CPI-1:0]  pad_to_cpi;
	dvsi_to_pad_t [  N_DVSI-1:0] dvsi_to_pad;
	pad_to_dvsi_t [  N_DVSI-1:0] pad_to_dvsi;

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

	.L2_wo_wen_o      (tcdm_wen_i[1]      ),
	.L2_wo_req_o      (tcdm_req_i[1]      ),
	.L2_wo_gnt_i      (tcdm_gnt_o[1]      ),
	.L2_wo_addr_o     (tcdm_add_i[1]      ),
	.L2_wo_wdata_o    (tcdm_data_i[1]     ),
	.L2_wo_be_o       (tcdm_be_i[1]       ),
	.L2_wo_rvalid_i   (tcdm_r_valid_o[1]  ),
	.L2_wo_rdata_i    (tcdm_r_data_o[1]   ),

	.dft_test_mode_i  (1'b0               ),
	.dft_cg_enable_i  (1'b0               ),

	.sys_clk_i        (sys_clk_i          ),
	.sys_rst_ni       (sys_resetn_i       ),
	.periph_clk_i     (periph_clk_i       ),

	.udma_apb_paddr   ( APB_BUS.paddr     ),
	.udma_apb_pwdata  ( APB_BUS.pwdata    ),
	.udma_apb_pwrite  ( APB_BUS.pwrite    ),
	.udma_apb_psel    ( APB_BUS.psel      ),
	.udma_apb_penable ( APB_BUS.penable   ),
	.udma_apb_prdata  ( APB_BUS.prdata    ),
	.udma_apb_pready  ( APB_BUS.pready    ),
	.udma_apb_pslverr ( APB_BUS.pslverr   ),

	.events_o         ( events_o          ),
	.event_valid_i    ( event_valid_i     ),
	.event_data_i     ( event_data_i      ),
	.event_ready_o    ( event_ready_o     ),
	.gpio_apb_paddr   ( gpio_apb_paddr    ),
	.gpio_apb_pwdata  ( gpio_apb_pwdata   ),
	.gpio_apb_pwrite  ( gpio_apb_pwrite   ),
	.gpio_apb_psel    ( gpio_apb_psel     ),
	.gpio_apb_penable ( gpio_apb_penable  ),
	.gpio_apb_prdata  ( gpio_apb_prdata   ),
	.gpio_apb_pready  ( gpio_apb_pready   ),
	.gpio_apb_pslverr ( gpio_apb_pslverr  ),
	.interrupt_o      ( interrupt_o       ),
	.gpio_in_sync_o   ( gpio_in_sync_o    ),
	.gpio_padcfg_o    ( gpio_padcfg_o     ),

	.gpio_to_pad      ( gpio_to_pad       ),
	.pad_to_gpio      ( pad_to_gpio       ),

	.uart_to_pad      ( uart_to_pad       ),
	.pad_to_uart      ( pad_to_uart       ),
	.i2c_to_pad       ( i2c_to_pad        ),
	.pad_to_i2c       ( pad_to_i2c        ),
	.qspi_to_pad      ( qspi_to_pad       ),
	.pad_to_qspi      ( pad_to_qspi       ),
	.pad_to_cpi       ( pad_to_cpi        ),
	.dvsi_to_pad      ( dvsi_to_pad       ),
	.pad_to_dvsi      ( pad_to_dvsi       )

);

always #13ns sys_clk_i    = ~sys_clk_i;
always #20ns periph_clk_i = ~periph_clk_i;

// attach uarts to simple receiver, and loop back the tx signals on RX
for (genvar i = 0; i < N_UART; i++) begin
	uart_tb_rx #(
		.ID (i),
		.BAUD_RATE(1470588)
	)i_uart_tb_rx (
		.rx(uart_to_pad[i].tx_o), 
		.tx(pad_to_uart[i].rx_i), 
		.rx_en(1'b1), 
		.tx_en(1'b1),
		.word_done()
	);
end

logic power_cycle;
wire [N_I2C-1:0] w_sda;
wire [N_I2C-1:0] w_scl;

for (genvar i = 0; i < N_I2C; i++) begin: FRAM
	FRAM_I2C i_FRAM_I2C (
		.power_cycle(power_cycle                            ),
		.A0         (i[0]                                   ),
		.A1         (i[1]                                   ),
		.A2         (i[2]                                   ),
		.WP         (1'b0                                   ),
		.SDA        ( w_sda[i]                              ),
		.SCL        ( w_scl[i]                              ),
		.RESET      (sys_resetn_i                           )
	);

	// active high buffer (verilog primitive)
	//       out        in                 control
	assign (pull1,weak0) w_sda[i] = 1'b1; // this should play the role of a pullup
	bufif1 (w_sda[i],i2c_to_pad[i].sda_o, i2c_to_pad[i].sda_oe); // this should drive with "strong0/1" > "pull0/1" strength
	assign pad_to_i2c[i].sda_i = w_sda[i];

	assign (pull1,weak0) w_scl[i] = 1'b1;
	bufif1 (w_scl[i],i2c_to_pad[i].scl_o, i2c_to_pad[i].scl_oe);
	assign pad_to_i2c[i].scl_i = w_scl[i];

end: FRAM


import apb_test_pkg::PERIPH_ID_OFFSET;



logic [31:0] uart_words[N_UART-1:0];
logic [31:0] uart_l2offset[N_UART-1:0];
logic [31:0] uart_errors;
logic [31:0] uart_transactions;

logic [31:0] i2c_words[N_I2C-1:0];
logic [31:0] i2c_l2offset[N_I2C-1:0];
logic [31:0] i2c_errors;
logic [31:0] i2c_transactions;
logic [31:0] i2c_cmd_words[N_I2C-1:0];
logic [31:0] i2c_cmd_l2offset[N_I2C-1:0];
logic [31:0] i2c_cmd_errors;
logic [31:0] i2c_cmd_transactions;

logic [31:0] qspi_words[N_QSPIM-1:0];
logic [31:0] qspi_l2offset[N_QSPIM-1:0];
logic [31:0] qspi_errors;
logic [31:0] qspi_transactions;
logic [31:0] qspi_cmd_words[N_QSPIM-1:0];
logic [31:0] qspi_cmd_l2offset[N_QSPIM-1:0];
logic [31:0] qspi_cmd_errors;
logic [31:0] qspi_cmd_transactions;

localparam MEM_DISP_OFFSET = 5;

initial begin

	//$readmemh("tcdm_stim.txt", pulp_io_tb.i_tcdm_model.memory);

	// bus starts clean
	APB_BUS.penable  = '0;
	APB_BUS.pwdata   = '0;
	APB_BUS.paddr    = '0;
	APB_BUS.pwrite   = '0;
	APB_BUS.psel     = '0;

	sys_clk_i = 0;
	periph_clk_i = 0;
	power_cycle = 1'b0;
	sys_resetn_i	= 1;
	#1us;
	power_cycle = 1'b1;
	#30ns;
	sys_resetn_i	= 0;
	#30ns;
	sys_resetn_i	= 1;

	uart_errors = 0;
	uart_transactions = 0;

	i2c_errors = 0;
	i2c_transactions = 0;

	#1ms;

	// uart setup
	$display("UART TEST");
	for (int i = PER_ID_UART; i < N_UART; i++) begin
		apb_test_pkg::udma_core_cg_en(i,sys_clk_i,APB_BUS); // enabling clock for periph id i
	end
	for (int i = PER_ID_UART; i < N_UART; i++) begin
		uart_words[i] = $urandom_range(1,8);            // transmit up to 128 bytes
		uart_l2offset[i] = $urandom_range(i*32,i*32+MEM_DISP_OFFSET); // when allocating memory, account for the worst case 
		$display("[DATA %0d] WORDS = %0d, L2OFFSET = %0d",i,uart_words[i]+1,uart_l2offset[i]);
		for (int j = 0; j < uart_words[i]; j++) begin
			pulp_io_tb.i_tcdm_model.memory[uart_l2offset[i] + j] = $urandom;
		end
		pulp_io_tb.i_tcdm_model.memory[uart_l2offset[i] + uart_words[i]] = 32'h0000000a; // make sure at least the last byte trigger the print (at the receiver)
		apb_test_pkg::udma_uart_setup(  PERIPH_ID_OFFSET + i*128,      sys_clk_i,APB_BUS); // enable the transmission
		apb_test_pkg::udma_lin_tx_saddr(PERIPH_ID_OFFSET + i*128,8'h10,32'h1C000000 + uart_l2offset[i]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_lin_tx_size( PERIPH_ID_OFFSET + i*128,8'h14,(uart_words[i]+1)*4,sys_clk_i,APB_BUS); // configure the transfer size
		apb_test_pkg::udma_lin_rx_saddr(PERIPH_ID_OFFSET + i*128,8'h00,32'h1C001000 + uart_l2offset[i]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_lin_rx_size( PERIPH_ID_OFFSET + i*128,8'h04,(uart_words[i]+1)*4,sys_clk_i,APB_BUS); // configure the transfer size
		apb_test_pkg::udma_uart_read(   PERIPH_ID_OFFSET + i*128,      sys_clk_i,APB_BUS); // start reception
		apb_test_pkg::udma_uart_write(  PERIPH_ID_OFFSET + i*128,      sys_clk_i,APB_BUS); // start transmission
	end

	#1us;

	// i2c setup
	$display("I2C TEST");
	for (int i = PER_ID_I2C; i < PER_ID_I2C+N_I2C; i++) begin
		apb_test_pkg::udma_core_cg_en(i,sys_clk_i,APB_BUS); // enabling clock for periph id i
	end

	// generating random data to transfer
	for (int i = PER_ID_I2C; i < PER_ID_I2C + N_I2C; i++) begin
		// generating random data
		i2c_words[i-PER_ID_I2C] = $urandom_range(1,8);            // transmit up to 128 bytes
		i2c_l2offset[i-PER_ID_I2C] = $urandom_range(i*32,i*32+MEM_DISP_OFFSET); // when allocating memory, account for the worst case 
		$display("[DATA %0d] WORDS = %0d, L2OFFSET = %0d",i,i2c_words[i-PER_ID_I2C],i2c_l2offset[i-PER_ID_I2C]);
		for (int j = 0; j < i2c_words[i-PER_ID_I2C]; j++) begin
			pulp_io_tb.i_tcdm_model.memory[i2c_l2offset[i-PER_ID_I2C] + j] = $urandom;
		end

		// generating writing commands
		i2c_cmd_words[i-PER_ID_I2C] = 7; // this must be fixed
		i2c_cmd_l2offset[i-PER_ID_I2C] = $urandom_range(i*32+MEM_DISP_OFFSET+8,i*32+8+2*MEM_DISP_OFFSET); // when allocating memory, account for the worst case 
		$display("[CMD %0d] WORDS = %0d, L2OFFSET = %0d",i,i2c_cmd_words[i-PER_ID_I2C],i2c_cmd_l2offset[i-PER_ID_I2C]);
		// here the content can't be random
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 0] = 32'he0000000  + $urandom_range(12'h08f,12'h08f);
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 1] = 32'h00000000;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 2] = 32'h70000000  + (4'b1010 << 4) + (3'b000 << 1) + 1'b0;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 3] = 32'h70000000;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 4] = 32'hc0000000  + i2c_words[i-PER_ID_I2C]*4;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 5] = 32'h80000000; 
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 6] = 32'h20000000;

		$writememh("tcdm_stim_out_data_cmd.txt", pulp_io_tb.i_tcdm_model.memory);

		// configuring data channels
		apb_test_pkg::udma_lin_tx_saddr(  PERIPH_ID_OFFSET + i*128,8'h10,32'h1C000000 + i2c_l2offset[i-PER_ID_I2C]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_lin_tx_size(   PERIPH_ID_OFFSET + i*128,8'h14,(i2c_words[i-PER_ID_I2C])*4,sys_clk_i,APB_BUS); // configure the transfer size

		// configuring command channels
		apb_test_pkg::udma_lin_tx_saddr( PERIPH_ID_OFFSET + i*128,8'h20,32'h1C000000 + i2c_cmd_l2offset[i-PER_ID_I2C]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_lin_tx_size(  PERIPH_ID_OFFSET + i*128,8'h24,(i2c_cmd_words[i-PER_ID_I2C])*4,sys_clk_i,APB_BUS); // configure the transfer size		
		apb_test_pkg::udma_i2c_setup(PERIPH_ID_OFFSET + i*128,sys_clk_i,APB_BUS); // enable the transmission
	end

	 $display("QSPI TEST");
	 for (int i = PER_ID_QSPIM; i < PER_ID_QSPIM+N_QSPIM; i++) begin
	 	apb_test_pkg::udma_core_cg_en(i,sys_clk_i,APB_BUS); // enabling clock for periph id i
	 end

	 // generating random data to transfer
	 for (int i = PER_ID_QSPIM; i < PER_ID_QSPIM + N_QSPIM; i++) begin
	 	// generating random data
	 	qspi_words[i-PER_ID_QSPIM] = $urandom_range(1,8);            // transmit up to 128 bytes
	 	qspi_l2offset[i-PER_ID_QSPIM] = $urandom_range(i*32+MEM_DISP_OFFSET+8,i*32+8+2*MEM_DISP_OFFSET); // when allocating memory, account for the worst case 
	 	$display("[DATA %0d] WORDS = %0d, L2OFFSET = %0d",i,qspi_words[i-PER_ID_I2C],qspi_l2offset[i-PER_ID_I2C]);
	 	for (int j = 0; j < qspi_words[i-PER_ID_QSPIM]; j++) begin
	 		pulp_io_tb.i_tcdm_model.memory[qspi_l2offset[i-PER_ID_QSPIM] + j] = 32'h87654321;
	 	end

	 	// generating writing commands
	 	qspi_cmd_words[i-PER_ID_QSPIM] = 5; // this must be fixed
	 	qspi_cmd_l2offset[i-PER_ID_QSPIM] = $urandom_range(i*32+16,i*32+MEM_DISP_OFFSET+16); // when allocating memory, account for the worst case 
	 	$display("[CMD %0d] WORDS = %0d, L2OFFSET = %0d",i,qspi_cmd_words[i-PER_ID_QSPIM],qspi_cmd_l2offset[i-PER_ID_QSPIM]);
	 	// here the content can't be random
	 	pulp_io_tb.i_tcdm_model.memory[qspi_cmd_l2offset[i-PER_ID_QSPIM] + 0] = 32'h000000ff;
	 	pulp_io_tb.i_tcdm_model.memory[qspi_cmd_l2offset[i-PER_ID_QSPIM] + 1] = 32'h10000000;
	 	pulp_io_tb.i_tcdm_model.memory[qspi_cmd_l2offset[i-PER_ID_QSPIM] + 2] = 32'h20000000  + (1'b0 << 27) + (8'h07 << 16) + 8'hfa;
	 	pulp_io_tb.i_tcdm_model.memory[qspi_cmd_l2offset[i-PER_ID_QSPIM] + 3] = 32'h60000000  + (1'b0 << 27) + ( 1'b1 << 26) + (8'h07 << 16) + qspi_words[i-PER_ID_QSPIM];
	 	pulp_io_tb.i_tcdm_model.memory[qspi_cmd_l2offset[i-PER_ID_QSPIM] + 4] = 32'h90000000;

	 	$writememh("tcdm_stim_out_data_cmd.txt", pulp_io_tb.i_tcdm_model.memory);

	 	// configuring data channels
	 	apb_test_pkg::udma_lin_tx_saddr(  PERIPH_ID_OFFSET + i*128,8'h10,32'h1C000000 + qspi_l2offset[i-PER_ID_QSPIM]*4,sys_clk_i,APB_BUS); // write L2 start address
	 	apb_test_pkg::udma_lin_tx_size(   PERIPH_ID_OFFSET + i*128,8'h14,(qspi_words[i-PER_ID_QSPIM])*4,sys_clk_i,APB_BUS); // configure the transfer size

	 	// configuring command channels
	 	apb_test_pkg::udma_lin_tx_saddr( PERIPH_ID_OFFSET + i*128,8'h20,32'h1C000000 + qspi_cmd_l2offset[i-PER_ID_QSPIM]*4,sys_clk_i,APB_BUS); // write L2 start address
	 	apb_test_pkg::udma_lin_tx_size(  PERIPH_ID_OFFSET + i*128,8'h24,(qspi_cmd_words[i-PER_ID_QSPIM])*4,sys_clk_i,APB_BUS); // configure the transfer size		
	 	apb_test_pkg::udma_qspi_setup(PERIPH_ID_OFFSET + i*128,sys_clk_i,APB_BUS); // enable the transmission
	 end

	#10000us;

	for (int i = PER_ID_I2C; i < PER_ID_I2C + N_I2C; i++) begin
		//i2c_l2offset[i-PER_ID_I2C] = $urandom_range(i*32,i*32+8); 
		$display("[DATA %0d] WORDS = %0d, L2OFFSET = %0d",i,i2c_words[i-PER_ID_I2C],i2c_l2offset[i-PER_ID_I2C]);

		// generating reading commands
		i2c_cmd_words[i-PER_ID_I2C] = 10; // this must be fixed
		i2c_cmd_l2offset[i-PER_ID_I2C] = $urandom_range(i*32+MEM_DISP_OFFSET+8,i*32+8+2*MEM_DISP_OFFSET); // when allocating memory, account for the worst case 
		$display("[CMD %0d] WORDS = %0d, L2OFFSET = %0d",i,i2c_cmd_words[i-PER_ID_I2C],i2c_cmd_l2offset[i-PER_ID_I2C]);
		// here the content can't be random
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 0] = 32'he0000000  + $urandom_range(12'h08f,12'h08f);
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 1] = 32'h00000000;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 2] = 32'h70000000  + (4'b1010 << 4) + (3'b000 << 1) + 1'b0;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 3] = 32'h70000000;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 4] = 32'h00000000; //start
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 5] = 32'h70000000  + (4'b1010 << 4) + (3'b000 << 1) + 1'b1;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 6] = 32'hc0000000  + (i2c_words[i-PER_ID_I2C])*4 -1;
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 7] = 32'h40000000; // read ack
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 8] = 32'h60000000; // last read nack
		pulp_io_tb.i_tcdm_model.memory[i2c_cmd_l2offset[i-PER_ID_I2C] + 9] = 32'h20000000;

		$writememh("tcdm_stim_out_data_cmd.txt", pulp_io_tb.i_tcdm_model.memory);

		// configuring data channels
		apb_test_pkg::udma_lin_rx_saddr(  PERIPH_ID_OFFSET + i*128,8'h00,32'h1C001100 + i2c_l2offset[i-PER_ID_I2C]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_lin_rx_size(   PERIPH_ID_OFFSET + i*128,8'h04,(i2c_words[i-PER_ID_I2C])*4,sys_clk_i,APB_BUS); // configure the transfer size

		// configuring command channels (override previous ones)
		apb_test_pkg::udma_lin_tx_saddr( PERIPH_ID_OFFSET + i*128,8'h20,32'h1C000000 + i2c_cmd_l2offset[i-PER_ID_I2C]*4,sys_clk_i,APB_BUS); // write L2 start address
		apb_test_pkg::udma_lin_tx_size(  PERIPH_ID_OFFSET + i*128,8'h24,(i2c_cmd_words[i-PER_ID_I2C])*4,sys_clk_i,APB_BUS); // configure the transfer size		
	end

	for (int i = PER_ID_I2C; i < PER_ID_I2C + N_I2C; i++) begin
		apb_test_pkg::udma_i2c_rw(PERIPH_ID_OFFSET + i*128,sys_clk_i,APB_BUS); // enable the transmission
	end

	#10000us;

	$writememh("tcdm_stim_out.txt", pulp_io_tb.i_tcdm_model.memory);

	for (int i = 0; i < N_UART; i++) begin
		for (int j = 0; j < uart_words[i]; j++) begin
			uart_transactions = uart_transactions + 4;
			if (pulp_io_tb.i_tcdm_model.memory[uart_l2offset[i] + j] !== pulp_io_tb.i_tcdm_model.memory[uart_l2offset[i] + j + 1024]) begin
				uart_errors = uart_errors + 4;
				$display("ERROR @ %8x --> TX = %8x, RX = %8x", 32'h1C001000 + (uart_l2offset[i] + j)*4, pulp_io_tb.i_tcdm_model.memory[uart_l2offset[i] + j],pulp_io_tb.i_tcdm_model.memory[uart_l2offset[i] + j + 512]);
			end else begin
				//$display("TX = %8x, RX = %8x",pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j],pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j + 512]);
			end
		end
	end

	if (uart_errors == 0) begin
		$display("[UART TEST PASS] %0d/%0d transaction PASSED",uart_transactions-uart_errors,uart_transactions);
	end else begin
		$error("[UART TEST FAIL] %0d/%0d transaction PASSED, %0d FAILED",uart_transactions-uart_errors,uart_transactions, uart_errors);
	end

	for (int i = 0; i < N_I2C; i++) begin
		for (int j = 0; j < i2c_words[i]; j++) begin
			i2c_transactions = i2c_transactions + 4;
			if (pulp_io_tb.i_tcdm_model.memory[i2c_l2offset[i] + j] !== pulp_io_tb.i_tcdm_model.memory[i2c_l2offset[i] + j + 1024+64]) begin
				i2c_errors = i2c_errors + 4;
				$display("ERROR @ %8x --> TX = %8x, RX = %8x", 32'h1C001100 + (i2c_l2offset[i] + j)*4, pulp_io_tb.i_tcdm_model.memory[i2c_l2offset[i] + j],pulp_io_tb.i_tcdm_model.memory[i2c_l2offset[i] + j + 576]);
			end else begin
				//$display("TX = %8x, RX = %8x",pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j],pulp_io_tb.i_tcdm_model.memory[l2offset[i] + j + 512]);
			end
		end
	end

	if (i2c_errors == 0) begin
		$display("[I2C  TEST PASS] %0d/%0d transaction PASSED",i2c_transactions-i2c_errors,i2c_transactions);
	end else begin
		$error("[I2C  TEST FAIL] %0d/%0d transaction PASSED, %0d FAILED",i2c_transactions-i2c_errors,i2c_transactions, i2c_errors);
	end

	#50ms;

	$stop;

end
	
endmodule