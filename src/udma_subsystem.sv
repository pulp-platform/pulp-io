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
module udma_subsystem

    // signal bitwidths
    import udma_pkg::L2_DATA_WIDTH;  
    import udma_pkg::L2_ADDR_WIDTH;  
    import udma_pkg::CAM_DATA_WIDTH; 
    import udma_pkg::TRANS_SIZE;     
    import udma_pkg::L2_AWIDTH_NOAL; 
    import udma_pkg::STREAM_ID_WIDTH;
    import udma_pkg::DEST_SIZE;  

    import udma_pkg::udma_evt_t;

    // peripherals and channels configuration
    import udma_cfg_pkg::*;   

#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(

    // udma reset
    input  logic                       sys_resetn_i   ,
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

    output logic           [31:0][3:0] events_o,
    input  logic                       event_valid_i,
    input  logic                 [7:0] event_data_i,
    output logic                       event_ready_o,

    //--- IO peripheral pads
    // UART  
    BIPAD_IF.PERIPH_SIDE PAD_UART_RX[N_UART-1:0],
    BIPAD_IF.PERIPH_SIDE PAD_UART_TX[N_UART-1:0],
    // I2C
    BIPAD_IF.PERIPH_SIDE PAD_I2C_SCL[ N_I2C-1:0],
    BIPAD_IF.PERIPH_SIDE PAD_I2C_SDA[ N_I2C-1:0],
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
    //CPI
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
    // DVSI
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

    // max 32 peripherals
    udma_evt_t   [31:0] s_events;
    logic         [1:0] s_rf_event;

    logic [N_PERIPHS-1:0]        s_clk_periphs_core;
    logic [N_PERIPHS-1:0]        s_clk_periphs_per;

    logic                 [31:0] s_periph_data_to;
    logic                  [4:0] s_periph_addr;
    logic                        s_periph_rwn;
    logic [N_PERIPHS-1:0] [31:0] s_periph_data_from;
    logic [N_PERIPHS-1:0]        s_periph_valid;
    logic [N_PERIPHS-1:0]        s_periph_ready;

    logic            [N_QSPIM-1:0] s_spi_eot;

    logic         [3:0] s_trigger_events;

    logic s_filter_eot_evt;
    logic s_filter_act_evt;


    assign L2_ro_wen_o   = 1'b1;
    assign L2_wo_wen_o   = 1'b0;

    assign L2_ro_be_o    =  'h0;
    assign L2_ro_wdata_o =  'h0;

    // udma channel declaration
    UDMA_LIN_CH lin_ch_rx[N_RX_LIN_CHANNELS-1:0](.clk_i(s_clk_periphs_core[0]));
    UDMA_LIN_CH lin_ch_tx[N_TX_LIN_CHANNELS-1:0](.clk_i(s_clk_periphs_core[0]));
    UDMA_EXT_CH ext_ch_rx[N_RX_EXT_CHANNELS-1:0](.clk_i(s_clk_periphs_core[0]));
    UDMA_EXT_CH ext_ch_tx[N_TX_EXT_CHANNELS-1:0](.clk_i(s_clk_periphs_core[0]));
    UDMA_EXT_CH str_ch_tx[        N_STREAMS-1:0](.clk_i(s_clk_periphs_core[0]));

    udma_core #(

        .N_RX_LIN_CHANNELS       ( N_RX_LIN_CHANNELS    ),
        .N_TX_LIN_CHANNELS       ( N_TX_LIN_CHANNELS    ),

        .N_RX_EXT_CHANNELS       ( N_RX_EXT_CHANNELS    ),
        .N_TX_EXT_CHANNELS       ( N_TX_EXT_CHANNELS    ),

        .N_STREAMS               ( N_STREAMS            ),
        .N_PERIPHS               ( N_PERIPHS            ),
        .APB_ADDR_WIDTH          ( APB_ADDR_WIDTH       )

    ) i_udmacore (

        .sys_clk_i               ( sys_clk_i            ),
        .per_clk_i               ( periph_clk_i         ),

        .dft_cg_enable_i         ( dft_cg_enable_i      ),

        .HRESETn                 ( sys_resetn_i         ),

        .PADDR                   ( udma_apb_paddr       ),
        .PWDATA                  ( udma_apb_pwdata      ),
        .PWRITE                  ( udma_apb_pwrite      ),
        .PSEL                    ( udma_apb_psel        ),
        .PENABLE                 ( udma_apb_penable     ),
        .PRDATA                  ( udma_apb_prdata      ),
        .PREADY                  ( udma_apb_pready      ),
        .PSLVERR                 ( udma_apb_pslverr     ),

        .periph_per_clk_o        ( s_clk_periphs_per    ),
        .periph_sys_clk_o        ( s_clk_periphs_core   ),

        .event_valid_i           ( event_valid_i        ),
        .event_data_i            ( event_data_i         ),
        .event_ready_o           ( event_ready_o        ),

        .event_o                 ( s_trigger_events     ),

        .periph_data_to_o        ( s_periph_data_to     ),
        .periph_addr_o           ( s_periph_addr        ),
        .periph_data_from_i      ( s_periph_data_from   ),
        .periph_ready_i          ( s_periph_ready       ),
        .periph_valid_o          ( s_periph_valid       ),
        .periph_rwn_o            ( s_periph_rwn         ),
    
        .tx_l2_req_o             ( L2_ro_req_o          ),
        .tx_l2_gnt_i             ( L2_ro_gnt_i          ),
        .tx_l2_addr_o            ( L2_ro_addr_o         ),
        .tx_l2_rdata_i           ( L2_ro_rdata_i        ),
        .tx_l2_rvalid_i          ( L2_ro_rvalid_i       ),
    
        .rx_l2_req_o             ( L2_wo_req_o          ),
        .rx_l2_gnt_i             ( L2_wo_gnt_i          ),
        .rx_l2_addr_o            ( L2_wo_addr_o         ),
        .rx_l2_be_o              ( L2_wo_be_o           ),
        .rx_l2_wdata_o           ( L2_wo_wdata_o        ),
    
        //--- stream channels connections
        .str_ch_tx               ( str_ch_tx            ),
        //--- Tx lin channels connections
        .lin_ch_tx               ( lin_ch_tx            ),
        //--- Rx lin channels connections
        .lin_ch_rx               ( lin_ch_rx            ),
        //--- Rx ext channels connections
        .ext_ch_rx               ( ext_ch_rx            ),
        //--- Tx ext channels connections
        .ext_ch_tx               ( ext_ch_tx            )

    );

    // UART Peripheral
    udma_evt_t [N_UART-1:0] s_evt_uart;
    for (genvar g_uart=0;g_uart<N_UART;g_uart++) begin: uart
        udma_uart_wrap i_udma_uart_wrap (
            .sys_clk_i   ( s_clk_periphs_core[PER_ID_UART + g_uart] ),
            .periph_clk_i( s_clk_periphs_per[ PER_ID_UART + g_uart] ),
            .rstn_i      ( sys_resetn_i                             ),
            .cfg_data_i  ( s_periph_data_to                         ),
            .cfg_addr_i  ( s_periph_addr                            ),
            .cfg_valid_i ( s_periph_valid[    PER_ID_UART + g_uart] ),
            .cfg_rwn_i   ( s_periph_rwn                             ),
            .cfg_ready_o ( s_periph_ready[    PER_ID_UART + g_uart] ),
            .cfg_data_o  ( s_periph_data_from[PER_ID_UART + g_uart] ),
            // FIXME ALFIO
            // ch_events_i () missing
            // events_i    () missing
            .events_o    ( s_evt_uart[                      g_uart] ), 
            // pads
            .PAD_UART_RX ( PAD_UART_RX[                     g_uart] ),
            .PAD_UART_TX ( PAD_UART_TX[                     g_uart] ),
            // data channels
            .rx_ch       ( lin_ch_rx[CH_ID_LIN_RX_UART + g_uart:CH_ID_LIN_RX_UART + g_uart] ),
            .tx_ch       ( lin_ch_tx[CH_ID_LIN_TX_UART + g_uart:CH_ID_LIN_TX_UART + g_uart] )
        );
        // bind uart events
        assign s_events[PER_ID_UART + g_uart] = s_evt_uart[g_uart];
    end: uart

    // I2C Peripheral
    udma_evt_t [N_I2C-1:0] s_evt_i2c;
    for (genvar g_i2c = 0; g_i2c < N_I2C; g_i2c++) begin: i2c
        udma_i2c_wrap i_udma_i2c_wrap (
            .sys_clk_i   ( s_clk_periphs_core[PER_ID_I2C + g_i2c] ),
            .periph_clk_i( s_clk_periphs_per[ PER_ID_I2C + g_i2c] ),
            .rstn_i      ( sys_resetn_i                           ),
            .cfg_data_i  ( s_periph_data_to                       ),
            .cfg_addr_i  ( s_periph_addr                          ),
            .cfg_valid_i ( s_periph_valid[    PER_ID_I2C + g_i2c] ),
            .cfg_rwn_i   ( s_periph_rwn                           ),
            .cfg_ready_o ( s_periph_ready[    PER_ID_I2C + g_i2c] ),
            .cfg_data_o  ( s_periph_data_from[PER_ID_I2C + g_i2c] ),
            // FIXME ALFIO
            // ch_events_i () missing
            .events_o    ( s_evt_i2c[                      g_i2c] ),
            .events_i    ( s_trigger_events                       ),
            //pads
            .PAD_I2C_SCL ( PAD_I2C_SCL[                    g_i2c] ),
            .PAD_I2C_SDA ( PAD_I2C_SDA[                    g_i2c] ),
            // data channels
            .rx_ch       ( lin_ch_rx[    CH_ID_LIN_RX_I2C + g_i2c:    CH_ID_LIN_RX_I2C + g_i2c] ),
            .tx_ch       ( lin_ch_tx[    CH_ID_LIN_TX_I2C + g_i2c:    CH_ID_LIN_TX_I2C + g_i2c] ),
            .cmd_ch      ( lin_ch_tx[CH_ID_LIN_TX_CMD_I2C + g_i2c:CH_ID_LIN_TX_CMD_I2C + g_i2c] )
        );
        // bind i2c events
        assign s_events[PER_ID_I2C + g_i2c] = s_evt_i2c[g_i2c];
    end: i2c

    // QSPI Peripheral
    udma_evt_t [N_QSPIM-1] s_evt_qspi;
    for (genvar g_qspi = 0; g_qspi < N_QSPIM; g_qspi++) begin: qspi
        udma_qspi_wrap i_udma_qspi_wrap (
            .sys_clk_i        ( s_clk_periphs_core[PER_ID_QSPIM + g_qspi] ),
            .periph_clk_i     ( s_clk_periphs_per[ PER_ID_QSPIM + g_qspi] ),
            .rstn_i           ( sys_resetn_i                              ),
            .cfg_data_i       ( s_periph_data_to                          ),
            .cfg_addr_i       ( s_periph_addr                             ),
            .cfg_valid_i      ( s_periph_valid[    PER_ID_QSPIM + g_qspi] ),
            .cfg_rwn_i        ( s_periph_rwn                              ),
            .cfg_ready_o      ( s_periph_ready[    PER_ID_QSPIM + g_qspi] ),
            .cfg_data_o       ( s_periph_data_from[PER_ID_QSPIM + g_qspi] ),
            //.ch_events_i      ( ch_events_i                               ),
            .events_o         ( s_evt_qspi[                       g_qspi] ), 
            .events_i         ( s_trigger_events                          ),
            // pads
            .PAD_QSPI_SCLK    ( PAD_QSPI_SCLK[                    g_qspi] ),
            .PAD_QSPI_CSN0    ( PAD_QSPI_CSN0[                    g_qspi] ),
            .PAD_QSPI_CSN1    ( PAD_QSPI_CSN1[                    g_qspi] ),
            .PAD_QSPI_CSN2    ( PAD_QSPI_CSN2[                    g_qspi] ),
            .PAD_QSPI_CSN3    ( PAD_QSPI_CSN3[                    g_qspi] ),
            .PAD_QSPI_MOSI_IO0( PAD_QSPI_MOSI_IO0[                g_qspi] ),
            .PAD_QSPI_MISO_IO1( PAD_QSPI_MISO_IO1[                g_qspi] ),
            .PAD_QSPI_IO2     ( PAD_QSPI_IO2[                     g_qspi] ),
            .PAD_QSPI_IO3     ( PAD_QSPI_IO3[                     g_qspi] ),
            // channels
            .tx_ch            ( lin_ch_tx[    CH_ID_LIN_TX_QSPIM + g_qspi:    CH_ID_LIN_TX_QSPIM + g_qspi] ),
            .rx_ch            ( lin_ch_rx[    CH_ID_LIN_RX_QSPIM + g_qspi:    CH_ID_LIN_RX_QSPIM + g_qspi] ),
            .cmd_ch           ( lin_ch_tx[CH_ID_LIN_TX_CMD_QSPIM + g_qspi:CH_ID_LIN_TX_CMD_QSPIM + g_qspi] )

        );
    end: qspi

    // CPI peripheral
    udma_evt_t [N_CPI-1:0] s_evt_cpi;
    for (genvar g_cpi = 0; g_cpi < N_CPI; g_cpi++) begin: cpi
        udma_cpi_wrap i_udma_cpi_wrap (
            .sys_clk_i   ( s_clk_periphs_core[PER_ID_CPI + g_cpi]  ),
            .periph_clk_i( s_clk_periphs_per[ PER_ID_CPI + g_cpi]  ),
            .rstn_i      ( sys_resetn_i                            ),
            .cfg_data_i  ( s_periph_data_to                        ),
            .cfg_addr_i  ( s_periph_addr                           ),
            .cfg_valid_i ( s_periph_valid[    PER_ID_CPI + g_cpi]  ),
            .cfg_rwn_i   ( s_periph_rwn                            ),
            .cfg_ready_o ( s_periph_ready[    PER_ID_CPI + g_cpi]  ),
            .cfg_data_o  ( s_periph_data_from[PER_ID_CPI + g_cpi]  ),
            //.ch_events_i ( ch_events_i                             ), // FIXME ALFIO (Connect udma events channels)
            .events_o    ( s_evt_cpi[                       g_cpi] ), 
            .events_i    ( s_trigger_events                        ),
            .PAD_PCLK    ( PAD_CPI_PCLK[                    g_cpi] ),
            .PAD_VSYNCH  ( PAD_CPI_VSYNCH[                  g_cpi] ),
            .PAD_HSYNCH  ( PAD_CPI_HSYNCH[                  g_cpi] ),
            .PAD_DATA0   ( PAD_CPI_DATA0[                   g_cpi] ),
            .PAD_DATA1   ( PAD_CPI_DATA1[                   g_cpi] ),
            .PAD_DATA2   ( PAD_CPI_DATA2[                   g_cpi] ),
            .PAD_DATA3   ( PAD_CPI_DATA3[                   g_cpi] ),
            .PAD_DATA4   ( PAD_CPI_DATA4[                   g_cpi] ),
            .PAD_DATA5   ( PAD_CPI_DATA5[                   g_cpi] ),
            .PAD_DATA6   ( PAD_CPI_DATA6[                   g_cpi] ),
            .PAD_DATA7   ( PAD_CPI_DATA7[                   g_cpi] ),
            .rx_ch       ( lin_ch_rx[  CH_ID_LIN_RX_CPI + g_cpi:    CH_ID_LIN_RX_CPI + g_cpi]       )
        );
    end: cpi

    udma_evt_t [N_DVSI-1:0] s_evt_dvsi;
    for (genvar g_dvsi = 0; g_dvsi < N_DVSI; g_dvsi++) begin

        udma_dvsi_wrap i_udma_dvsi_wrap (

            .sys_clk_i     ( s_clk_periphs_core[PER_ID_DVSI + g_dvsi] ),
            .periph_clk_i  ( s_clk_periphs_per[ PER_ID_DVSI + g_dvsi] ),
            .rstn_i        ( sys_resetn_i                             ),

            .cfg_data_i    ( s_periph_data_to                         ),
            .cfg_addr_i    ( s_periph_addr                            ),
            .cfg_valid_i   ( s_periph_valid[    PER_ID_DVSI + g_dvsi] ),
            .cfg_rwn_i     ( s_periph_rwn                             ),
            .cfg_ready_o   ( s_periph_ready[    PER_ID_DVSI + g_dvsi] ),
            .cfg_data_o    ( s_periph_data_from[PER_ID_DVSI + g_dvsi] ),

            //.ch_events_i   ( ch_events_i                              ), // FIXME ALFIO
            .events_o      ( s_evt_dvsi                               ), 
            .events_i      ( s_trigger_events                         ),

            .PAD_DVSI_ASA  ( PAD_DVSI_ASA[                    g_dvsi] ),
            .PAD_DVSI_ARE  ( PAD_DVSI_ARE[                    g_dvsi] ),
            .PAD_DVSI_ASY  ( PAD_DVSI_ASY[                    g_dvsi] ),
            .PAD_DVSI_YNRST( PAD_DVSI_YNRST[                  g_dvsi] ),
            .PAD_DVSI_YCLK ( PAD_DVSI_YCLK[                   g_dvsi] ),
            .PAD_DVSI_SXY  ( PAD_DVSI_SXY[                    g_dvsi] ),
            .PAD_DVSI_XCLK ( PAD_DVSI_XCLK[                   g_dvsi] ),
            .PAD_DVSI_XNRST( PAD_DVSI_XNRST[                  g_dvsi] ),
            .PAD_DVSI_ON0  ( PAD_DVSI_ON0[                    g_dvsi] ),
            .PAD_DVSI_ON1  ( PAD_DVSI_ON1[                    g_dvsi] ),
            .PAD_DVSI_ON2  ( PAD_DVSI_ON2[                    g_dvsi] ),
            .PAD_DVSI_ON3  ( PAD_DVSI_ON3[                    g_dvsi] ),
            .PAD_DVSI_OFF0 ( PAD_DVSI_OFF0[                   g_dvsi] ),
            .PAD_DVSI_OFF1 ( PAD_DVSI_OFF1[                   g_dvsi] ),
            .PAD_DVSI_OFF2 ( PAD_DVSI_OFF2[                   g_dvsi] ),
            .PAD_DVSI_OFF3 ( PAD_DVSI_OFF3[                   g_dvsi] ),
            .PAD_DVSI_XY0  ( PAD_DVSI_XY0[                    g_dvsi] ),
            .PAD_DVSI_XY1  ( PAD_DVSI_XY1[                    g_dvsi] ),
            .PAD_DVSI_XY2  ( PAD_DVSI_XY2[                    g_dvsi] ),
            .PAD_DVSI_XY3  ( PAD_DVSI_XY3[                    g_dvsi] ),
            .PAD_DVSI_XY4  ( PAD_DVSI_XY4[                    g_dvsi] ),
            .PAD_DVSI_XY5  ( PAD_DVSI_XY5[                    g_dvsi] ),
            .PAD_DVSI_XY6  ( PAD_DVSI_XY6[                    g_dvsi] ),
            .PAD_DVSI_XY7  ( PAD_DVSI_XY7[                    g_dvsi] ),
            .PAD_DVSI_CFG0 ( PAD_DVSI_CFG0[                   g_dvsi] ),
            .PAD_DVSI_CFG1 ( PAD_DVSI_CFG1[                   g_dvsi] ),
            .PAD_DVSI_CFG2 ( PAD_DVSI_CFG2[                   g_dvsi] ),
            .PAD_DVSI_CFG3 ( PAD_DVSI_CFG3[                   g_dvsi] ),
            .PAD_DVSI_CFG4 ( PAD_DVSI_CFG4[                   g_dvsi] ),
            .PAD_DVSI_CFG5 ( PAD_DVSI_CFG5[                   g_dvsi] ),
            .PAD_DVSI_CFG6 ( PAD_DVSI_CFG6[                   g_dvsi] ),
            .PAD_DVSI_CFG7 ( PAD_DVSI_CFG7[                   g_dvsi] ),

            .rx_ch         ( ext_ch_rx[CH_ID_EXT_RX_DVSI + g_dvsi:    CH_ID_EXT_RX_DVSI + g_dvsi] )
        );
    end


    // pad unused events
    for (genvar i = N_PERIPHS; i < 32; i++) begin: evt_zero
        assign s_events[i] = 4'b0000;
    end: evt_zero

    // assign output events
    assign events_o      = s_events;

endmodule
