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

`define EXPORT_UDMA_STREAM(str_ch,port) \
    assign ``port``_req.addr = str_ch.addr; \
    assign ``port``_req.datasize = str_ch.datasize; \
    assign ``port``_req.data = str_ch.data; \
    assign ``port``_req.valid = str_ch.valid; \
    assign  str_ch.ready = ``port``_rsp.ready;

module udma_subsystem

    // signal bitwidths
    import udma_pkg::*;
    import uart_pkg::*;
    import qspi_pkg::*;
    import i2c_pkg::*;
    import cpi_pkg::*;
    import dvsi_pkg::*;
    import hyper_pkg::*;
    import filter_pkg::*;
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

    input  logic                       dvsi_saer_frame_timer_i,
    input  logic                       dvsi_framebuf_frame_timer_i,
    output logic                       cutie_trigger_o,

    output logic           [31:0][3:0] events_o,
    input  logic                       event_valid_i,
    input  logic                 [7:0] event_data_i,
    output logic                       event_ready_o,

    //--- IO peripheral pads
    // UART
    output  uart_to_pad_t [N_UART-1:0] uart_to_pad,
    input   pad_to_uart_t [N_UART-1:0] pad_to_uart,
    // I2C
    output  i2c_to_pad_t  [ N_I2C-1:0] i2c_to_pad,
    input   pad_to_i2c_t  [ N_I2C-1:0] pad_to_i2c,
    // QSPI
    output  qspi_to_pad_t [ N_QSPIM-1:0] qspi_to_pad,
    input   pad_to_qspi_t [ N_QSPIM-1:0] pad_to_qspi,
    // CPI
    input  pad_to_cpi_t [ N_CPI-1:0] pad_to_cpi,
    // DVSI
    output  dvsi_to_pad_t [ N_DVSI-1:0] dvsi_to_pad,
    input   pad_to_dvsi_t [ N_DVSI-1:0] pad_to_dvsi,

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

    // max 32 peripherals
    udma_evt_t [31:0] s_events;
    logic [1:0] s_rf_event;

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
            .events_i    ( 4'b0000                                  ), // UART do not receive events
            .events_o    ( s_evt_uart[                      g_uart] ),
            // pads
            .uart_to_pad ( uart_to_pad[                     g_uart] ),
            .pad_to_uart ( pad_to_uart[                     g_uart] ),
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
            .events_o    ( s_evt_i2c[                      g_i2c] ),
            .events_i    ( s_trigger_events                       ),
            //pads
            .i2c_to_pad ( i2c_to_pad[                      g_i2c] ),
            .pad_to_i2c ( pad_to_i2c[                      g_i2c] ),
            // data channels
            .rx_ch       ( lin_ch_rx[    CH_ID_LIN_RX_I2C + g_i2c:    CH_ID_LIN_RX_I2C + g_i2c] ),
            .tx_ch       ( lin_ch_tx[    CH_ID_LIN_TX_I2C + g_i2c:    CH_ID_LIN_TX_I2C + g_i2c] ),
            .cmd_ch      ( lin_ch_tx[CH_ID_LIN_TX_CMD_I2C + g_i2c:CH_ID_LIN_TX_CMD_I2C + g_i2c] )
        );
        // bind i2c events
        assign s_events[PER_ID_I2C + g_i2c] = s_evt_i2c[g_i2c];
    end: i2c

    // QSPI Peripheral
    udma_evt_t [N_QSPIM-1:0] s_evt_qspi;
    for (genvar g_qspi = 0; g_qspi < N_QSPIM; g_qspi++) begin: qspi
        udma_qspi_wrap i_udma_qspi_wrap (
            .sys_clk_i   ( s_clk_periphs_core[PER_ID_QSPIM + g_qspi] ),
            .periph_clk_i( s_clk_periphs_per[ PER_ID_QSPIM + g_qspi] ),
            .rstn_i      ( sys_resetn_i                              ),
            .dft_test_mode_i(dft_test_mode_i                         ),
            .dft_cg_enable_i(dft_cg_enable_i                         ),
            .cfg_data_i  ( s_periph_data_to                          ),
            .cfg_addr_i  ( s_periph_addr                             ),
            .cfg_valid_i ( s_periph_valid[    PER_ID_QSPIM + g_qspi] ),
            .cfg_rwn_i   ( s_periph_rwn                              ),
            .cfg_ready_o ( s_periph_ready[    PER_ID_QSPIM + g_qspi] ),
            .cfg_data_o  ( s_periph_data_from[PER_ID_QSPIM + g_qspi] ),
            .events_o    ( s_evt_qspi[                       g_qspi] ),
            .events_i    ( s_trigger_events                          ),
            // pads
            .qspi_to_pad ( qspi_to_pad[                      g_qspi] ),
            .pad_to_qspi ( pad_to_qspi[                      g_qspi] ),
            // channels
            .tx_ch       ( lin_ch_tx[    CH_ID_LIN_TX_QSPIM + g_qspi:    CH_ID_LIN_TX_QSPIM + g_qspi] ),
            .rx_ch       ( lin_ch_rx[    CH_ID_LIN_RX_QSPIM + g_qspi:    CH_ID_LIN_RX_QSPIM + g_qspi] ),
            .cmd_ch      ( lin_ch_tx[CH_ID_LIN_TX_CMD_QSPIM + g_qspi:CH_ID_LIN_TX_CMD_QSPIM + g_qspi] )

        );
        // bind qspi events
        assign s_events[PER_ID_QSPIM + g_qspi] = s_evt_qspi[g_qspi];
    end: qspi

    // CPI peripheral
    udma_evt_t [N_CPI-1:0] s_evt_cpi;
    for (genvar g_cpi = 0; g_cpi < N_CPI; g_cpi++) begin: cpi
        udma_cpi_wrap i_udma_cpi_wrap (
            .sys_clk_i   ( s_clk_periphs_core[PER_ID_CPI + g_cpi]  ),
            .periph_clk_i( s_clk_periphs_per[ PER_ID_CPI + g_cpi]  ),
            .rstn_i      ( sys_resetn_i                            ),
            .dft_test_mode_i,
            .dft_cg_enable_i,
            .cfg_data_i  ( s_periph_data_to                        ),
            .cfg_addr_i  ( s_periph_addr                           ),
            .cfg_valid_i ( s_periph_valid[    PER_ID_CPI + g_cpi]  ),
            .cfg_rwn_i   ( s_periph_rwn                            ),
            .cfg_ready_o ( s_periph_ready[    PER_ID_CPI + g_cpi]  ),
            .cfg_data_o  ( s_periph_data_from[PER_ID_CPI + g_cpi]  ),
            .events_o    ( s_evt_cpi[                       g_cpi] ),
            .events_i    ( s_trigger_events                        ),
            .pad_to_cpi  ( pad_to_cpi[                      g_cpi] ),
            .rx_ch       ( lin_ch_rx[  CH_ID_LIN_RX_CPI + g_cpi:    CH_ID_LIN_RX_CPI + g_cpi]       )
        );
        //bind cpi events
        assign s_events[PER_ID_CPI + g_cpi] = s_evt_cpi[g_cpi];
    end: cpi

    // DVSI peripheral
    udma_evt_t [N_DVSI-1:0] s_evt_dvsi;
    for (genvar g_dvsi = 0; g_dvsi < N_DVSI; g_dvsi++) begin: dvsi
      logic cutie_start_s;
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
            .events_o      ( s_evt_dvsi[                      g_dvsi] ),
            .events_i      ( s_trigger_events                         ),
            .cutie_start_o ( cutie_start_s                            ),
            .saer_frame_timer_i( dvsi_saer_frame_timer_i              ),
            .framebuf_frame_timer_i( dvsi_framebuf_frame_timer_i      ),
            .dvsi_to_pad   ( dvsi_to_pad[                     g_dvsi] ),
            .pad_to_dvsi   ( pad_to_dvsi[                     g_dvsi] ),
            .rx_ch         ( ext_ch_rx[CH_ID_EXT_RX_DVSI + g_dvsi:    CH_ID_EXT_RX_DVSI + g_dvsi] )
        );
        //bind DVSI events
        assign s_events[PER_ID_DVSI + g_dvsi] = s_evt_dvsi[g_dvsi];
        if (g_dvsi == 0) begin
          // CUTIE can be triggered by the framebuffer_done event -> #2
          assign cutie_trigger_o = cutie_start_s;
        end
    end: dvsi

    udma_evt_t [N_HYPER-1:0] s_evt_hyper;
    // Hyperbus peripheral
    for (genvar g_hyper = 0; g_hyper < N_HYPER; g_hyper++) begin: hyper
        `ifndef HYPER_MACRO
            udma_hyper_wrap i_udma_hyper_wrap (
                .sys_clk_i    ( s_clk_periphs_core[PER_ID_HYPER + g_hyper] ),
                .periph_clk_i ( s_clk_periphs_per[ PER_ID_HYPER + g_hyper] ),
                .rstn_i       ( sys_resetn_i                               ),
                .cfg_data_i   ( s_periph_data_to                           ),
                .cfg_addr_i   ( s_periph_addr                              ),
                .cfg_valid_i  ( s_periph_valid[    PER_ID_HYPER + (g_hyper+1)*(1+N_CH_HYPER)-1:PER_ID_HYPER + g_hyper*(1+N_CH_HYPER)] ),
                .cfg_rwn_i    ( s_periph_rwn                               ),
                .cfg_ready_o  ( s_periph_ready[    PER_ID_HYPER + (g_hyper+1)*(1+N_CH_HYPER)-1:PER_ID_HYPER + g_hyper*(1+N_CH_HYPER)] ),
                .cfg_data_o   ( s_periph_data_from[PER_ID_HYPER + (g_hyper+1)*(1+N_CH_HYPER)-1:PER_ID_HYPER + g_hyper*(1+N_CH_HYPER)] ),
                .events_o     ( s_evt_hyper[       g_hyper         ]       ),
                .events_i     ( s_trigger_events                           ),
                .tx_ch        ( lin_ch_tx[  CH_ID_LIN_TX_HYPER + (g_hyper+1)*N_CH_HYPER-1:    CH_ID_LIN_TX_HYPER + g_hyper*N_CH_HYPER] ),
                .rx_ch        ( lin_ch_rx[  CH_ID_LIN_RX_HYPER + (g_hyper+1)*N_CH_HYPER-1:    CH_ID_LIN_RX_HYPER + g_hyper*N_CH_HYPER] ),

                .hyper_to_pad( hyper_to_pad[ g_hyper                     ] ),
                .pad_to_hyper( pad_to_hyper[ g_hyper                     ] )
            );
            //bind Hyperbus events
            assign s_events[PER_ID_HYPER + g_hyper * N_CH_HYPER] = s_evt_hyper[g_hyper];
            for (genvar i=0; i<N_CH_HYPER; i++) begin : hyper_open_events
              assign s_events[PER_ID_HYPER + g_hyper * N_CH_HYPER + i + 1] = '0;
            end
        `else
            hyper_macro_bridge i_hyper_macro_bridge (
                .sys_clk_i           ( s_clk_periphs_core[PER_ID_HYPER + g_hyper] ),
                .periph_clk_i        ( s_clk_periphs_per[ PER_ID_HYPER + g_hyper] ),
                .rstn_i              ( sys_resetn_i                               ),
                .cfg_data_i          ( s_periph_data_to                           ),
                .cfg_addr_i          ( s_periph_addr                              ),
                .cfg_valid_i         ( s_periph_valid[    PER_ID_HYPER + (g_hyper+1)*(1+N_CH_HYPER)-1:PER_ID_HYPER + g_hyper*(1+N_CH_HYPER)] ),
                .cfg_rwn_i           ( s_periph_rwn                               ),
                .cfg_ready_o         ( s_periph_ready[    PER_ID_HYPER + (g_hyper+1)*(1+N_CH_HYPER)-1:PER_ID_HYPER + g_hyper*(1+N_CH_HYPER)] ),
                .cfg_data_o          ( s_periph_data_from[PER_ID_HYPER + (g_hyper+1)*(1+N_CH_HYPER)-1:PER_ID_HYPER + g_hyper*(1+N_CH_HYPER)] ),
                .events_o            ( s_evt_hyper[       g_hyper         ]       ),
                .events_i            ( s_trigger_events                           ),
                .tx_ch               ( lin_ch_tx[  CH_ID_LIN_TX_HYPER + (g_hyper+1)*N_CH_HYPER-1:    CH_ID_LIN_TX_HYPER + g_hyper*N_CH_HYPER] ),
                .rx_ch               ( lin_ch_rx[  CH_ID_LIN_RX_HYPER + (g_hyper+1)*N_CH_HYPER-1:    CH_ID_LIN_RX_HYPER + g_hyper*N_CH_HYPER] ),

                .hyper_macro_evt_i   ( hyper_macro_evt_i[g_hyper]                 ),
                .hyper_macro_evt_o   ( hyper_macro_evt_o[g_hyper]                 ),
                .hyper_cfg_req_o     ( hyper_cfg_req_o[g_hyper]                   ),
                .hyper_cfg_rsp_i     ( hyper_cfg_rsp_i[g_hyper]                   ),
                .hyper_linch_tx_req_o( hyper_linch_tx_req_o[g_hyper]              ),
                .hyper_linch_tx_rsp_i( hyper_linch_tx_rsp_i[g_hyper]              ),

                .hyper_linch_rx_req_i( hyper_linch_rx_req_i[g_hyper]              ),
                .hyper_linch_rx_rsp_o( hyper_linch_rx_rsp_o[g_hyper]              )
            );
            //bind Hyperbus events
            assign s_events[PER_ID_HYPER + g_hyper * N_CH_HYPER] = s_evt_hyper[g_hyper];
            for (genvar i=0; i<N_CH_HYPER; i++) begin : hyper_open_events
              assign s_events[PER_ID_HYPER + g_hyper * N_CH_HYPER + i + 1] = '0;
            end
        `endif

    end: hyper

    // uDMA filter peripheral
    udma_evt_t [N_FILTER-1:0] s_evt_filter;
    for (genvar g_filter = 0; g_filter < N_FILTER; g_filter++) begin: filter
        udma_filter_wrap i_udma_filter_wrap (
            .sys_clk_i    (s_clk_periphs_core[PER_ID_FILTER + g_filter] ),
            .rstn_i       (sys_resetn_i                                 ),
            .cfg_data_i   (s_periph_data_to                             ),
            .cfg_addr_i   (s_periph_addr                                ),
            .cfg_valid_i  (s_periph_valid[    PER_ID_FILTER + g_filter] ),
            .cfg_rwn_i    (s_periph_rwn                                 ),
            .cfg_ready_o  (s_periph_ready[    PER_ID_FILTER + g_filter] ),
            .cfg_data_o   (s_periph_data_from[PER_ID_FILTER + g_filter] ),
            .events_o     (s_evt_filter[                      g_filter] ),
            .events_i     (4'h0                                         ),
            .rx_ch        (ext_ch_rx[   CH_ID_EXT_RX_FILTER + g_filter: CH_ID_EXT_RX_FILTER + g_filter] ),
            .tx_ch        (ext_ch_tx[   CH_ID_EXT_TX_FILTER + g_filter*2 + 1: CH_ID_EXT_TX_FILTER + g_filter*2] ),
            .str_rx_ch    (str_ch_tx[      STREAM_ID_FILTER + g_filter:    STREAM_ID_FILTER + g_filter] )
        );
        // bind filter events
        assign s_events[PER_ID_FILTER + g_filter] = s_evt_filter;
    end: filter

    // here we are connecting the last stream to the output port
    // `EXPORT_UDMA_STREAM(str_ch_tx[STREAM_ID_EXTERNAL],udma_stream)

    // pad unused events
    for (genvar i = N_PERIPHS; i < 32; i++) begin: evt_zero
        assign s_events[i] = 4'b0000;
    end: evt_zero

    // assign output events
    assign events_o  = s_events;

endmodule
