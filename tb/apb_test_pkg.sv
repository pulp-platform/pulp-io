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
package apb_test_pkg;

	//`define  PRINT

	localparam CORE_OFFSET = 32'h0000000;
	localparam PERIPH_ID_OFFSET = 32'h0000080;

	typedef struct {
		logic [31:0] paddr;
		logic [31:0] pwdata;
		logic        pwrite;
		logic        psel;
		logic        penable;
		logic [31:0] prdata;
		logic        pready;
		logic        pslverr;
	} APB_BUS_t;

	typedef struct {

		logic [7:0][31:0] master;

	} XBAR_CFG_t;

//   ¦¦¦¦¦  ¦¦¦¦¦¦  ¦¦¦¦¦¦      ¦¦¦¦¦¦  ¦¦¦¦¦¦  ¦¦ ¦¦    ¦¦ ¦¦¦¦¦¦¦ ¦¦¦¦¦¦  
//  ¦¦   ¦¦ ¦¦   ¦¦ ¦¦   ¦¦     ¦¦   ¦¦ ¦¦   ¦¦ ¦¦ ¦¦    ¦¦ ¦¦      ¦¦   ¦¦ 
//  ¦¦¦¦¦¦¦ ¦¦¦¦¦¦  ¦¦¦¦¦¦      ¦¦   ¦¦ ¦¦¦¦¦¦  ¦¦ ¦¦    ¦¦ ¦¦¦¦¦   ¦¦¦¦¦¦  
//  ¦¦   ¦¦ ¦¦      ¦¦   ¦¦     ¦¦   ¦¦ ¦¦   ¦¦ ¦¦  ¦¦  ¦¦  ¦¦      ¦¦   ¦¦ 
//  ¦¦   ¦¦ ¦¦      ¦¦¦¦¦¦      ¦¦¦¦¦¦  ¦¦   ¦¦ ¦¦   ¦¦¦¦   ¦¦¦¦¦¦¦ ¦¦   ¦¦                                                                        
	                                                                                                                                                                                                          
	task automatic APB_WRITE(
		
		input logic [31:0] addr, 
		input logic [31:0] data, 
		ref   logic        clk_i, 
		ref   APB_BUS_t    APB_BUS);
		
		APB_BUS.penable  = '0;
		APB_BUS.pwdata   = '0;
		APB_BUS.paddr    = '0;
		APB_BUS.pwrite   = '0;
		APB_BUS.psel     = '0;
		@(posedge clk_i);
		APB_BUS.penable  = 1'b0;
		APB_BUS.pwdata   = data;
		APB_BUS.paddr    = addr;
		APB_BUS.pwrite   = 1'b1;
		APB_BUS.psel     = 1'b1;
		//@(posedge clk_i);
		//APB_BUS.psel     = 1'b1;
		@(posedge clk_i);
		APB_BUS.penable  = 1'b1;
		//@(posedge clk_i);
		while(~APB_BUS.pready);
		@(posedge clk_i);
		APB_BUS.paddr = 0;
		APB_BUS.pwdata = 0;
		APB_BUS.pwrite = 0;
		APB_BUS.psel = 0;
		APB_BUS.penable = 0;
		//@(posedge clk_i);
		`ifdef PRINT
			$display("---------[t=%0t] [APB-WRITE: 0b%32b (0x%8h) @addr 0x%5h] ---------",$time,data,data,addr);
		`endif
	endtask : APB_WRITE

	task automatic APB_READ(
		
		input  logic [31:0] addr, 
		output logic [31:0] data, 
		ref    logic        clk_i, 
		ref    APB_BUS_t    APB_BUS);
		
		APB_BUS.penable  = '0;
		APB_BUS.pwdata   = '0;
		APB_BUS.paddr    = '0;
		APB_BUS.pwrite   = '0;
		APB_BUS.psel     = '0;
		@(posedge clk_i);
		APB_BUS.penable  = 1'b0;
		APB_BUS.pwdata   = '0;
		APB_BUS.paddr    = addr;
		APB_BUS.pwrite   = 1'b0;
		APB_BUS.psel     = 1'b0;
		@(posedge clk_i);
		APB_BUS.psel     = 1'b1;
		@(posedge clk_i);
		APB_BUS.penable  = 1'b1;
		@(posedge clk_i);
		while(~APB_BUS.pready);
		@(posedge clk_i);
		data = APB_BUS.prdata;
		@(posedge clk_i);
		APB_BUS.paddr = 0;
		APB_BUS.pwdata = 0;
		APB_BUS.pwrite = 0;
		APB_BUS.psel = 0;
		APB_BUS.penable = 0;
		//@(posedge clk_i);
		`ifdef PRINT
			$display("---------[t=%0t] [APB-READ: 0b%32b (0x%8h) @addr 0x%5h] ---------",$time,data,data,addr);
		`endif
	endtask : APB_READ

//   ¦¦¦¦¦¦  ¦¦¦¦¦¦  ¦¦¦¦¦¦  ¦¦¦¦¦¦¦ 
//  ¦¦      ¦¦    ¦¦ ¦¦   ¦¦ ¦¦      
//  ¦¦      ¦¦    ¦¦ ¦¦¦¦¦¦  ¦¦¦¦¦   
//  ¦¦      ¦¦    ¦¦ ¦¦   ¦¦ ¦¦      
//   ¦¦¦¦¦¦  ¦¦¦¦¦¦  ¦¦   ¦¦ ¦¦¦¦¦¦¦                                

	//clock enable
	task automatic udma_core_cg_en(
		input peripheral_id,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CORE_OFFSET,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << peripheral_id);
		APB_WRITE(CORE_OFFSET,reg_val,clk_i,APB_BUS);    
		$display("[UDMA CORE: CG ENABLE ID %0d]",peripheral_id);
	endtask : udma_core_cg_en

	//clock disable
	task automatic udma_core_cg_dis(
		input peripheral_id,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CORE_OFFSET,reg_val,clk_i,APB_BUS);
		reg_val = reg_val & ~(1'b1 << peripheral_id);
		APB_WRITE(CORE_OFFSET,reg_val,clk_i,APB_BUS);    
		$display("[UDMA CORE: CG DISABLE ID %0d]",peripheral_id);
	endtask : udma_core_cg_dis

//  ¦¦    ¦¦  ¦¦¦¦¦  ¦¦¦¦¦¦  ¦¦¦¦¦¦¦¦ 
//  ¦¦    ¦¦ ¦¦   ¦¦ ¦¦   ¦¦    ¦¦    
//  ¦¦    ¦¦ ¦¦¦¦¦¦¦ ¦¦¦¦¦¦     ¦¦    
//  ¦¦    ¦¦ ¦¦   ¦¦ ¦¦   ¦¦    ¦¦    
//   ¦¦¦¦¦¦  ¦¦   ¦¦ ¦¦   ¦¦    ¦¦    
                                        
	localparam UART0_OFFSET = PERIPH_ID_OFFSET + 0;

	//uart write start address
	task automatic udma_uart0_write_saddr(
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(UART0_OFFSET,reg_val,clk_i,APB_BUS);
		reg_val = reg_val;
		APB_WRITE(UART0_OFFSET,reg_val,clk_i,APB_BUS);    
		$display("[UART0: WRITE SADDR]");
	endtask : udma_uart0_write_saddr

	//uart write transfer size address
	task automatic udma_uart0_write_size(
		input logic [31:0] size,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		APB_WRITE(UART0_OFFSET + 8'h14,size,clk_i,APB_BUS);    
		$display("[UART0: WRITE SIZE]");
	endtask : udma_uart0_write_size

	//uart test
	task automatic udma_uart0_tx_en(
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(UART0_OFFSET + 8'h24,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << 8) | | (1'b1 << 0); 
		APB_WRITE(UART0_OFFSET + 8'h24,reg_val,clk_i,APB_BUS);    
		$display("[UART0: TXEN]");
	endtask : udma_uart0_tx_en

	//uart test
	task automatic udma_uart0_write(
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(UART0_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << 4); 
		APB_WRITE(UART0_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);    
		$display("[UART0: TX DATA]");
	endtask : udma_uart0_write

endpackage : apb_test_pkg