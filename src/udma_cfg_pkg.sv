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
	localparam N_QSPIM                 = 0                               ;
	localparam N_UART                  = 1                               ;
	localparam N_I2C                   = 0                               ;
	localparam N_CPI                   = 0                               ;
	localparam N_DVS                   = 0                               ;
	localparam N_I2S                   = 0                               ;
	localparam N_HYPER                 = 0                               ;
	localparam N_FILTER                = 0                               ;
	localparam N_TGEN_TX_LIN           = 1                               ;

	localparam N_PERIPHS               = N_UART + N_FILTER + N_QSPIM + N_I2C + N_CPI + N_HYPER + N_I2S + N_DVS + N_TGEN_TX_LIN;

	// derive the number of channels
	localparam N_STREAMS               = N_FILTER                                            ;
	localparam N_RX_LIN_CHANNELS       = N_UART + N_QSPIM   + N_I2C + N_CPI + N_HYPER + N_I2S;
	localparam N_TX_LIN_CHANNELS       = N_UART + N_QSPIM*2 + N_I2C +         N_HYPER + N_I2S + N_TGEN_TX_LIN;
	localparam N_RX_EXT_CHANNELS       = N_FILTER + N_DVS                                    ;
	localparam N_TX_EXT_CHANNELS       = N_FILTER*2                                          ;

	//--- TX Lin. Channels
	localparam CH_ID_LIN_TX_UART       = 0                                ; 
	localparam CH_ID_LIN_TX_QSPIM      = CH_ID_LIN_TX_UART      + N_UART  ; 
	localparam CH_ID_LIN_TX_CMD_QSPIM  = CH_ID_LIN_TX_QSPIM     + N_QSPIM ; 
	localparam CH_ID_LIN_TX_I2C        = CH_ID_LIN_TX_CMD_QSPIM + N_QSPIM ; 
	localparam CH_ID_LIN_TX_I2S        = CH_ID_LIN_TX_I2C       + N_I2C   ; 
	localparam CH_ID_LIN_TX_HYPER      = CH_ID_LIN_TX_I2S       + N_I2S   ; 
	localparam CH_ID_LIN_TX_TGEN       = CH_ID_LIN_TX_HYPER     + 1       ;

	//--- RX Lin. Channels
	localparam CH_ID_LIN_RX_UART       = 0                                ; 
	localparam CH_ID_LIN_RX_QSPIM      = CH_ID_LIN_RX_UART      + N_UART  ; 
	localparam CH_ID_LIN_RX_I2C        = CH_ID_LIN_RX_QSPIM     + N_QSPIM ; 
	localparam CH_ID_LIN_RX_I2S        = CH_ID_LIN_RX_I2C       + N_I2C   ; 
	localparam CH_ID_LIN_RX_HYPER      = CH_ID_LIN_RX_I2S       + N_I2S   ; 
	localparam CH_ID_LIN_RX_CAM        = CH_ID_LIN_RX_HYPER     + N_HYPER ; 

	//--- Tx Ext. channels
	localparam CH_ID_EXT_TX_FILTER     = 0                                ;

	//--- Rx Ext. channels
	localparam CH_ID_EXT_RX_FILTER     = 0                                ;
	localparam CH_ID_EXT_RX_DVS        = CH_ID_EXT_RX_FILTER    + N_FILTER;
	
	//--- Stream (Ext.) channels
	localparam STREAM_ID_FILTER        = 0                                ;

	//--- peripheral IDs
	localparam PER_ID_UART             = 0                                ; 
	localparam PER_ID_QSPIM            = PER_ID_UART        + N_UART      ; 
	localparam PER_ID_I2C              = PER_ID_QSPIM       + N_QSPIM     ; 
	localparam PER_ID_I2S              = PER_ID_I2C         + N_I2C       ; 
	localparam PER_ID_HYPER            = PER_ID_I2S         + N_I2S       ; 
	localparam PER_ID_CAM              = PER_ID_HYPER       + N_HYPER     ; 
	localparam PER_ID_DVS              = PER_ID_CAM         + N_CPI       ; 
	localparam PER_ID_FILTER           = PER_ID_DVS         + N_DVS       ; 
	localparam PER_ID_TGEN_TX_LIN      = PER_ID_DVS         + N_FILTER    ;
	
endpackage