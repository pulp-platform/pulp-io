/* 
 * Alfio Di Mauro <adimauro@iis.ee.ethz.ch>
 *
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
 */

 // this package holds all udma configuration
package udma_cfg_pkg;

	// entry point, select io peripherals
	localparam N_QSPIM                 = 4                               ;
	localparam N_UART                  = 2                               ;
	localparam N_I2C                   = 4                               ;
	localparam N_CPI                   = 1                               ;
	localparam N_DVSI                  = 1                               ;
	localparam N_HYPER                 = 1                               ;
	localparam N_I2S                   = 0                               ;
	localparam N_FILTER                = 0                               ;
	localparam N_TGEN_TX_LIN           = 0                               ;

	localparam N_PERIPHS               = N_UART + N_FILTER + N_QSPIM + N_I2C + N_CPI + N_HYPER + N_I2S + N_DVSI;

	// derive the total number of channels
	localparam N_STREAMS               = N_FILTER                                               ;
	localparam N_TX_LIN_CHANNELS       = N_UART + N_QSPIM*2 + N_I2C*2 +         N_HYPER + N_I2S ;
	localparam N_RX_LIN_CHANNELS       = N_UART + N_QSPIM   + N_I2C   + N_CPI + N_HYPER + N_I2S ;
	localparam N_TX_EXT_CHANNELS       = N_FILTER*2                                             ;
	localparam N_RX_EXT_CHANNELS       = N_FILTER + N_DVSI                                      ;

	// Channel IDs, not related to peripheral order, and they are not symmetrical for most of the peripherals. 
	// Example: SPI0 might be connected on Tx lin channel 3 and 7, and on Rx channel 9
	// Drivers need to know the exact peripheral channel mapping to enque data/commands on them.
	//--- TX Lin. Channels
	localparam CH_ID_LIN_TX_UART       = 0                                ; //0
	localparam CH_ID_LIN_TX_QSPIM      = CH_ID_LIN_TX_UART      + N_UART  ; //4
	localparam CH_ID_LIN_TX_CMD_QSPIM  = CH_ID_LIN_TX_QSPIM     + N_QSPIM ; //8
	localparam CH_ID_LIN_TX_I2C        = CH_ID_LIN_TX_CMD_QSPIM + N_QSPIM ; //12
	localparam CH_ID_LIN_TX_CMD_I2C    = CH_ID_LIN_TX_I2C       + N_I2C   ; 
	localparam CH_ID_LIN_TX_HYPER      = CH_ID_LIN_TX_CMD_I2C   + N_I2C   ;

	//--- RX Lin. Channels
	localparam CH_ID_LIN_RX_UART       = 0                                ; 
	localparam CH_ID_LIN_RX_QSPIM      = CH_ID_LIN_RX_UART      + N_UART  ; 
	localparam CH_ID_LIN_RX_I2C        = CH_ID_LIN_RX_QSPIM     + N_QSPIM ; 
	localparam CH_ID_LIN_RX_CPI        = CH_ID_LIN_RX_I2C       + N_I2C   ; 
	localparam CH_ID_LIN_RX_HYPER      = CH_ID_LIN_RX_CPI       + N_CPI   ; 

	// External channel restart from ID o
	//--- Tx Ext. channels
	localparam CH_ID_EXT_TX_FILTER     = 0                                ;

	//--- Rx Ext. channels
	localparam CH_ID_EXT_RX_FILTER     = 0                                ;
	localparam CH_ID_EXT_RX_DVSI       = CH_ID_EXT_RX_FILTER    + N_FILTER;
	
	//--- Stream (Ext.) channels
	localparam STREAM_ID_FILTER        = 0                                ;

	//--- peripheral IDs (unique for each peripheral, regardless of the number of channels)
	localparam PER_ID_UART             = 0                                ; 
	localparam PER_ID_QSPIM            = PER_ID_UART        + N_UART      ; 
	localparam PER_ID_I2C              = PER_ID_QSPIM       + N_QSPIM     ; 
	localparam PER_ID_CPI              = PER_ID_I2C         + N_I2C       ; 
	localparam PER_ID_DVSI             = PER_ID_CPI         + N_CPI       ; 
	localparam PER_ID_HYPER            = PER_ID_DVSI        + N_DVSI      ;
	
endpackage