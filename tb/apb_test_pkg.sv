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

//`define VERBOSE

package apb_test_pkg;

	`define  PRINT

	localparam CORE_OFFSET      = 32'h00000000;
	localparam PERIPH_ID_OFFSET = 32'h00000080;

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
                                                                         
//                AAA               PPPPPPPPPPPPPPPPP   BBBBBBBBBBBBBBBBB   
//               A:::A              P::::::::::::::::P  B::::::::::::::::B  
//              A:::::A             P::::::PPPPPP:::::P B::::::BBBBBB:::::B 
//             A:::::::A            PP:::::P     P:::::PBB:::::B     B:::::B
//            A:::::::::A             P::::P     P:::::P  B::::B     B:::::B
//           A:::::A:::::A            P::::P     P:::::P  B::::B     B:::::B
//          A:::::A A:::::A           P::::PPPPPP:::::P   B::::BBBBBB:::::B 
//         A:::::A   A:::::A          P:::::::::::::PP    B:::::::::::::BB  
//        A:::::A     A:::::A         P::::PPPPPPPPP      B::::BBBBBB:::::B 
//       A:::::AAAAAAAAA:::::A        P::::P              B::::B     B:::::B
//      A:::::::::::::::::::::A       P::::P              B::::B     B:::::B
//     A:::::AAAAAAAAAAAAA:::::A      P::::P              B::::B     B:::::B
//    A:::::A             A:::::A   PP::::::PP          BB:::::BBBBBB::::::B
//   A:::::A               A:::::A  P::::::::P          B:::::::::::::::::B 
//  A:::::A                 A:::::A P::::::::P          B::::::::::::::::B  
// AAAAAAA                   AAAAAAAPPPPPPPPPP          BBBBBBBBBBBBBBBBB   
	                                                                                                                                                                                                          
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
			`ifdef VERBOSE
				$display("---------[t=%0t] [APB-WRITE: 0b%32b (0x%8h) @addr 0x%5h] ---------",$time,data,data,addr);
			`endif
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
			`ifdef VERBOSE
				$display("---------[t=%0t] [APB-READ: 0b%32b (0x%8h) @addr 0x%5h] ---------",$time,data,data,addr);
			`endif
		`endif
	endtask : APB_READ                              

//         CCCCCCCCCCCCC     OOOOOOOOO     RRRRRRRRRRRRRRRRR   EEEEEEEEEEEEEEEEEEEEEE
//      CCC::::::::::::C   OO:::::::::OO   R::::::::::::::::R  E::::::::::::::::::::E
//    CC:::::::::::::::C OO:::::::::::::OO R::::::RRRRRR:::::R E::::::::::::::::::::E
//   C:::::CCCCCCCC::::CO:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEEE::::E
//  C:::::C       CCCCCCO::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
// C:::::C              O:::::O     O:::::O  R::::R     R:::::R  E:::::E             
// C:::::C              O:::::O     O:::::O  R::::RRRRRR:::::R   E::::::EEEEEEEEEE   
// C:::::C              O:::::O     O:::::O  R:::::::::::::RR    E:::::::::::::::E   
// C:::::C              O:::::O     O:::::O  R::::RRRRRR:::::R   E:::::::::::::::E   
// C:::::C              O:::::O     O:::::O  R::::R     R:::::R  E::::::EEEEEEEEEE   
// C:::::C              O:::::O     O:::::O  R::::R     R:::::R  E:::::E             
//  C:::::C       CCCCCCO::::::O   O::::::O  R::::R     R:::::R  E:::::E       EEEEEE
//   C:::::CCCCCCCC::::CO:::::::OOO:::::::ORR:::::R     R:::::REE::::::EEEEEEEE:::::E
//    CC:::::::::::::::C OO:::::::::::::OO R::::::R     R:::::RE::::::::::::::::::::E
//      CCC::::::::::::C   OO:::::::::OO   R::::::R     R:::::RE::::::::::::::::::::E
//         CCCCCCCCCCCCC     OOOOOOOOO     RRRRRRRR     RRRRRRREEEEEEEEEEEEEEEEEEEEEE

	//clock enable
	task automatic udma_core_cg_en(
		input logic [31:0] peripheral_id,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CORE_OFFSET,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << peripheral_id);
		APB_WRITE(CORE_OFFSET,reg_val,clk_i,APB_BUS);    
		//`ifdef VERBOSE
			$display("[UDMA CORE: CG ENABLE ID %0d]",peripheral_id);
		//`endif
	endtask : udma_core_cg_en

	//clock disable
	task automatic udma_core_cg_dis(
		input logic [31:0] peripheral_id,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CORE_OFFSET,reg_val,clk_i,APB_BUS);
		reg_val = reg_val & ~(1'b1 << peripheral_id);
		APB_WRITE(CORE_OFFSET,reg_val,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[UDMA CORE: CG DISABLE ID %0d]",peripheral_id);
		`endif
	endtask : udma_core_cg_dis

	//lin ch write start address
	task automatic udma_lin_tx_saddr(
		input logic [31:0] CH_OFFSET,
		input logic [31:0] RG_OFFSET,
		input logic [31:0] saddr,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		APB_WRITE(CH_OFFSET + RG_OFFSET,saddr,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[LIN: TX SADDR]");
		`endif
	endtask : udma_lin_tx_saddr

	//lin ch write transfer size address
	task automatic udma_lin_tx_size(
		input logic [31:0] CH_OFFSET,
		input logic [31:0] RG_OFFSET,
		input logic [31:0] size,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		APB_WRITE(CH_OFFSET + RG_OFFSET,size,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[LIN: TX SIZE]");
		`endif
	endtask : udma_lin_tx_size

	//lin ch write start address
	task automatic udma_lin_rx_saddr(
		input logic [31:0] CH_OFFSET,
		input logic [31:0] RG_OFFSET,
		input logic [31:0] saddr,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		APB_WRITE(CH_OFFSET + RG_OFFSET,saddr,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[LIN: RX SADDR]");
		`endif
	endtask : udma_lin_rx_saddr

	//lin ch write transfer size address
	task automatic udma_lin_rx_size(
		input logic [31:0] CH_OFFSET,
		input logic [31:0] RG_OFFSET,
		input logic [31:0] size,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		APB_WRITE(CH_OFFSET + RG_OFFSET,size,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[LIN: RX SIZE]");
		`endif
	endtask : udma_lin_rx_size


// UUUUUUUU     UUUUUUUU           AAA               RRRRRRRRRRRRRRRRR   TTTTTTTTTTTTTTTTTTTTTTT
// U::::::U     U::::::U          A:::A              R::::::::::::::::R  T:::::::::::::::::::::T
// U::::::U     U::::::U         A:::::A             R::::::RRRRRR:::::R T:::::::::::::::::::::T
// UU:::::U     U:::::UU        A:::::::A            RR:::::R     R:::::RT:::::TT:::::::TT:::::T
//  U:::::U     U:::::U        A:::::::::A             R::::R     R:::::RTTTTTT  T:::::T  TTTTTT
//  U:::::D     D:::::U       A:::::A:::::A            R::::R     R:::::R        T:::::T        
//  U:::::D     D:::::U      A:::::A A:::::A           R::::RRRRRR:::::R         T:::::T        
//  U:::::D     D:::::U     A:::::A   A:::::A          R:::::::::::::RR          T:::::T        
//  U:::::D     D:::::U    A:::::A     A:::::A         R::::RRRRRR:::::R         T:::::T        
//  U:::::D     D:::::U   A:::::AAAAAAAAA:::::A        R::::R     R:::::R        T:::::T        
//  U:::::D     D:::::U  A:::::::::::::::::::::A       R::::R     R:::::R        T:::::T        
//  U::::::U   U::::::U A:::::AAAAAAAAAAAAA:::::A      R::::R     R:::::R        T:::::T        
//  U:::::::UUU:::::::UA:::::A             A:::::A   RR:::::R     R:::::R      TT:::::::TT      
//   UU:::::::::::::UUA:::::A               A:::::A  R::::::R     R:::::R      T:::::::::T      
//     UU:::::::::UU A:::::A                 A:::::A R::::::R     R:::::R      T:::::::::T      
//       UUUUUUUUU  AAAAAAA                   AAAAAAARRRRRRRR     RRRRRRR      TTTTTTTTTTT      
                                        
	//setup read/write
	task automatic udma_uart_setup(
		input logic [31:0] CH_OFFSET,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CH_OFFSET + 8'h24,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << 9) | (1'b1 << 8) | (1'b1 << 0) | (2'b11 << 1) | ( 1'b1 << 20); 
		APB_WRITE(CH_OFFSET + 8'h24,reg_val,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[UART: TXEN]");
		`endif
	endtask : udma_uart_setup

	//write
	task automatic udma_uart_write(
		input logic [31:0] CH_OFFSET,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << 4); 
		APB_WRITE(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[UART: TX DATA]");
		`endif
	endtask : udma_uart_write

	//read
	task automatic udma_uart_read(
		input logic [31:0] CH_OFFSET,
		ref   logic        clk_i   , 
		ref   APB_BUS_t    APB_BUS);
		logic [31:0] reg_val;
		APB_READ(CH_OFFSET + 8'h08,reg_val,clk_i,APB_BUS);
		reg_val = reg_val | (1'b1 << 4); 
		APB_WRITE(CH_OFFSET + 8'h08,reg_val,clk_i,APB_BUS);    
		`ifdef VERBOSE
			$display("[UART: TX DATA]");
		`endif
	endtask : udma_uart_read

	                                                  
//	IIIIIIIIII 222222222222222           CCCCCCCCCCCCC
//	I::::::::I2:::::::::::::::22      CCC::::::::::::C
//	I::::::::I2::::::222222:::::2   CC:::::::::::::::C
//	II::::::II2222222     2:::::2  C:::::CCCCCCCC::::C
//	  I::::I              2:::::2 C:::::C       CCCCCC
//	  I::::I              2:::::2C:::::C              
//	  I::::I           2222::::2 C:::::C              
//	  I::::I      22222::::::22  C:::::C              
//	  I::::I    22::::::::222    C:::::C              
//	  I::::I   2:::::22222       C:::::C              
//	  I::::I  2:::::2            C:::::C              
//	  I::::I  2:::::2             C:::::C       CCCCCC
//	II::::::II2:::::2       222222 C:::::CCCCCCCC::::C
//	I::::::::I2::::::2222222:::::2  CC:::::::::::::::C
//	I::::::::I2::::::::::::::::::2    CCC::::::::::::C
//	IIIIIIIIII22222222222222222222       CCCCCCCCCCCCC

//setup read/write
task automatic udma_i2c_setup(
	input logic [31:0] CH_OFFSET,
	ref   logic        clk_i   , 
	ref   APB_BUS_t    APB_BUS);
	logic [31:0] reg_val;
	APB_READ(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);  
	
	APB_READ(CH_OFFSET + 8'h28,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h28,reg_val,clk_i,APB_BUS);  
	`ifdef VERBOSE
		$display("[UART: TXEN]");
	`endif
endtask : udma_i2c_setup

//setup read/write
task automatic udma_i2c_rw(
	input logic [31:0] CH_OFFSET,
	ref   logic        clk_i   , 
	ref   APB_BUS_t    APB_BUS);
	logic [31:0] reg_val;
	APB_READ(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS); 
	
	APB_READ(CH_OFFSET + 8'h08,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h08,reg_val,clk_i,APB_BUS);   
	
	APB_READ(CH_OFFSET + 8'h28,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h28,reg_val,clk_i,APB_BUS);  
	`ifdef VERBOSE
		$display("[UART: TXEN]");
	`endif
endtask : udma_i2c_rw


// qspi
//setup read/write
task automatic udma_qspi_setup(
	input logic [31:0] CH_OFFSET,
	ref   logic        clk_i   , 
	ref   APB_BUS_t    APB_BUS);
	logic [31:0] reg_val;
	APB_READ(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h18,reg_val,clk_i,APB_BUS);  
	
	APB_READ(CH_OFFSET + 8'h28,reg_val,clk_i,APB_BUS);
	reg_val = reg_val | (1'b1 << 4); 
	APB_WRITE(CH_OFFSET + 8'h28,reg_val,clk_i,APB_BUS);  
	`ifdef VERBOSE
		$display("[UART: TXEN]");
	`endif
endtask : udma_qspi_setup





endpackage : apb_test_pkg