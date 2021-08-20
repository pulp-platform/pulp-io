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

module pulp_io

	// signal bitwidths
	import uart_pkg::*;
	import qspi_pkg::*;
	import i2c_pkg::*;
	import cpi_pkg::*;
	import dvsi_pkg::*;
	import hyper_pkg::*;
	import udma_pkg::*;
  import gpio_reg_pkg::GPIOCount;
	// peripherals and channels configuration
	import udma_cfg_pkg::*;

	#(
	    parameter APB_ADDR_WIDTH = 12,  // APB slaves are 4KB by default
	    localparam NUM_GPIOS      = GPIOCount  // The number of GPIOs.
                                             // If you want to change this number you have to regenerate the control register file
                                             // for the GPIO peripheral. There is a make target to do that automatically
                                             // in the toplevel repo of the GPIO peripheral.
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

  // GPIO
  input logic [NUM_GPIOS-1:0]           gpio_in,
  output logic [NUM_GPIOS-1:0]          gpio_out,
  output logic [NUM_GPIOS-1:0]          gpio_tx_en_o,
  output logic [NUM_GPIOS-1:0]          gpio_in_sync_o, //Synchronized GPIO inputs (can be used as external signal)
  output logic                          gpio_interrupt_o,

  // UART
	output  uart_to_pad_t [  N_UART-1:0]  uart_to_pad,
	input   pad_to_uart_t [  N_UART-1:0]  pad_to_uart,
	// I2C
	output  i2c_to_pad_t  [   N_I2C-1:0]  i2c_to_pad,
	input   pad_to_i2c_t  [   N_I2C-1:0]  pad_to_i2c,
	// QSPI
	output  qspi_to_pad_t [ N_QSPIM-1:0]  qspi_to_pad,
	input   pad_to_qspi_t [ N_QSPIM-1:0]  pad_to_qspi,
	//CPI
	input   pad_to_cpi_t   [   N_CPI-1:0] pad_to_cpi,

	`ifndef HYPER_MACRO
	// HYPER
	output  hyper_to_pad_t [ N_HYPER-1:0] hyper_to_pad,
	input   pad_to_hyper_t [ N_HYPER-1:0] pad_to_hyper
	`else
	// configuration from udma core to the macro
	output cfg_req_t [N_HYPER-1:0] hyper_cfg_req_o,
	input cfg_rsp_t [N_HYPER-1:0] hyper_cfg_rsp_i,
	// data channels from/to the macro
	output udma_linch_tx_req_t [N_HYPER-1:0] hyper_linch_tx_req_o,
	input udma_linch_tx_rsp_t [N_HYPER-1:0] hyper_linch_tx_rsp_i,
	input udma_linch_rx_req_t [N_HYPER-1:0] hyper_linch_rx_req_i,
	output udma_linch_rx_rsp_t [N_HYPER-1:0] hyper_linch_rx_rsp_o,
	input udma_evt_t [N_HYPER-1:0] hyper_macro_evt_i,
	output udma_evt_t [N_HYPER-1:0] hyper_macro_evt_o
	`endif
);

  APB #(.DATA_WIDTH(32), .ADDR_WIDTH(32)) s_apb_gpio();
  assign s_apb_gpio.paddr = gpio_apb_paddr;
  assign s_apb_gpio.pprot = '0;
  assign s_apb_gpio.psel = gpio_apb_psel;
  assign s_apb_gpio.penable = gpio_apb_penable;
  assign s_apb_gpio.pwrite = gpio_apb_pwrite;
  assign s_apb_gpio.pwdata = gpio_apb_pwdata;
  assign s_apb_gpio.pstrb = '1;
  assign gpio_apb_pready = s_apb_gpio.pready;
  assign gpio_apb_prdata = s_apb_gpio.prdata;
  assign gpio_apb_pslverr = s_apb_gpio.pslverr;

  gpio_apb_wrap_intf #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
  ) i_gpio (
    .clk_i       ( sys_clk_i        ),
    .rst_ni      ( sys_rst_ni       ),
    .gpio_in,
    .gpio_out,
    .gpio_tx_en_o,
    .gpio_in_sync_o,
    .interrupt_o ( gpio_interrupt_o ),
    .apb_slave   ( s_apb_gpio       )
  );

	////////////////////////////////////////////////////////////////////////////////////////////////
	// ██╗   ██╗██████╗ ███╗   ███╗ █████╗     ███████╗██╗   ██╗██████╗ ███████╗██╗   ██╗███████╗ //
	// ██║   ██║██╔══██╗████╗ ████║██╔══██╗    ██╔════╝██║   ██║██╔══██╗██╔════╝╚██╗ ██╔╝██╔════╝ //
	// ██║   ██║██║  ██║██╔████╔██║███████║    ███████╗██║   ██║██████╔╝███████╗ ╚████╔╝ ███████╗ //
	// ██║   ██║██║  ██║██║╚██╔╝██║██╔══██║    ╚════██║██║   ██║██╔══██╗╚════██║  ╚██╔╝  ╚════██║ //
	// ╚██████╔╝██████╔╝██║ ╚═╝ ██║██║  ██║    ███████║╚██████╔╝██████╔╝███████║   ██║   ███████║ //
	//  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝ //
	////////////////////////////////////////////////////////////////////////////////////////////////

	udma_subsystem #(.APB_ADDR_WIDTH(32)) i_udma_subsystem (
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
	.uart_to_pad         ( uart_to_pad       ),
	.pad_to_uart         ( pad_to_uart       ),
	.i2c_to_pad          ( i2c_to_pad        ),
	.pad_to_i2c          ( pad_to_i2c        ),
	.qspi_to_pad         ( qspi_to_pad       ),
	.pad_to_qspi         ( pad_to_qspi       ),
	.pad_to_cpi          ( pad_to_cpi        ),
	`ifndef HYPER_MACRO
	.hyper_to_pad        ( hyper_to_pad         ),
	.pad_to_hyper        ( pad_to_hyper         )
	`else
	.hyper_cfg_req_o     ( hyper_cfg_req_o      ),
	.hyper_cfg_rsp_i     ( hyper_cfg_rsp_i      ),
	.hyper_linch_tx_req_o( hyper_linch_tx_req_o ),
	.hyper_linch_tx_rsp_i( hyper_linch_tx_rsp_i ),
	.hyper_linch_rx_req_i( hyper_linch_rx_req_i ),
	.hyper_linch_rx_rsp_o( hyper_linch_rx_rsp_o ),
	.hyper_macro_evt_i   ( hyper_macro_evt_i    ),
	.hyper_macro_evt_o   ( hyper_macro_evt_o    )
	`endif
);


endmodule
