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

    // peripherals and channels configuration
    import udma_cfg_pkg::*;   

#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    output logic                       L2_ro_wen_o    ,
    output logic                       L2_ro_req_o    ,
    input  logic                       L2_ro_gnt_i    ,
    output logic                [31:0] L2_ro_addr_o   ,
    output logic [L2_DATA_WIDTH/8-1:0] L2_ro_be_o     ,
    output logic   [L2_DATA_WIDTH-1:0] L2_ro_wdata_o  ,
    input  logic                       L2_ro_rvalid_i ,
    input  logic   [L2_DATA_WIDTH-1:0] L2_ro_rdata_i  ,

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

    input  logic                       sys_clk_i,
    input  logic                       sys_resetn_i,
    input  logic                       periph_clk_i,

    input  logic  [APB_ADDR_WIDTH-1:0] udma_apb_paddr,
    input  logic                [31:0] udma_apb_pwdata,
    input  logic                       udma_apb_pwrite,
    input  logic                       udma_apb_psel,
    input  logic                       udma_apb_penable,
    output logic                [31:0] udma_apb_prdata,
    output logic                       udma_apb_pready,
    output logic                       udma_apb_pslverr,

    output logic            [32*4-1:0] events_o,
    input  logic                       event_valid_i,
    input  logic                [7:0]  event_data_i,
    output logic                       event_ready_o,

    //--- IO peripherals

    // ██╗   ██╗ █████╗ ██████╗ ████████╗
    // ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝
    // ██║   ██║███████║██████╔╝   ██║   
    // ██║   ██║██╔══██║██╔══██╗   ██║   
    // ╚██████╔╝██║  ██║██║  ██║   ██║   
    //  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    

    input  logic [N_UART-1:0] uart_rx_i,
    output logic [N_UART-1:0] uart_tx_o

   /*

    //  ██████╗ ███████╗██████╗ ██╗      ███╗   ███╗
    // ██╔═══██╗██╔════╝██╔══██╗██║      ████╗ ████║
    // ██║   ██║███████╗██████╔╝██║█████╗██╔████╔██║
    // ██║▄▄ ██║╚════██║██╔═══╝ ██║╚════╝██║╚██╔╝██║
    // ╚██████╔╝███████║██║     ██║      ██║ ╚═╝ ██║
    //  ╚══▀▀═╝ ╚══════╝╚═╝     ╚═╝      ╚═╝     ╚═╝

    output logic [`N_QSPIM-1:0]       spi_clk_o,
    output logic [`N_QSPIM-1:0] [3:0] spi_csn_o,
    output logic [`N_QSPIM-1:0] [3:0] spi_oen_o,
    output logic [`N_QSPIM-1:0] [3:0] spi_sdo_o,
    input  logic [`N_QSPIM-1:0] [3:0] spi_sdi_i,

    // ██╗██████╗  ██████╗
    // ██║╚════██╗██╔════╝
    // ██║ █████╔╝██║     
    // ██║██╔═══╝ ██║     
    // ██║███████╗╚██████╗
    // ╚═╝╚══════╝ ╚═════╝    

    input  logic [`N_I2C-1:0] i2c_scl_i,
    output logic [`N_I2C-1:0] i2c_scl_o,
    output logic [`N_I2C-1:0] i2c_scl_oe,
    input  logic [`N_I2C-1:0] i2c_sda_i,
    output logic [`N_I2C-1:0] i2c_sda_o,
    output logic [`N_I2C-1:0] i2c_sda_oe,

    // ██╗██████╗ ███████╗
    // ██║╚════██╗██╔════╝
    // ██║ █████╔╝███████╗
    // ██║██╔═══╝ ╚════██║
    // ██║███████╗███████║
    // ╚═╝╚══════╝╚══════╝
                   
    input  logic i2s_slave_sd0_i  ,
    input  logic i2s_slave_sd1_i  ,
    input  logic i2s_slave_ws_i   ,
    output logic i2s_slave_ws_o   ,
    output logic i2s_slave_ws_oe  ,
    input  logic i2s_slave_sck_i  ,
    output logic i2s_slave_sck_o  ,
    output logic i2s_slave_sck_oe ,
    output logic i2s_master_sd0_o ,
    output logic i2s_master_sd1_o ,
    input  logic i2s_master_ws_i  ,
    output logic i2s_master_ws_o  ,
    output logic i2s_master_ws_oe ,
    input  logic i2s_master_sck_i ,
    output logic i2s_master_sck_o ,
    output logic i2s_master_sck_oe,

    // ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗       ██████╗ 
    // ██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗      ██╔══██╗
    // ███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝█████╗██████╔╝
    // ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗╚════╝██╔══██╗
    // ██║  ██║   ██║   ██║     ███████╗██║  ██║      ██████╔╝
    // ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝      ╚═════╝ 
    output logic                            hyperbus_clk_periphs_core_o  ,    
    output logic                            hyperbus_clk_periphs_per_o   ,   
    output logic                            hyperbus_sys_resetn_o        ,          

    output  logic                    [31:0] hyperbus_periph_data_to_o    ,
    output  logic                     [4:0] hyperbus_periph_addr_o       ,
    output  logic                           hyperbus_periph_valid_o      ,
    output  logic                           hyperbus_periph_rwn_o        ,
    input   logic                           hyperbus_periph_ready_i      ,
    input   logic                    [31:0] hyperbus_periph_data_from_i  ,

    input  logic                     [31:0] hyperbus_rx_cfg_startaddr_i  ,
    input  logic                     [31:0] hyperbus_rx_cfg_size_i       ,
    input  logic                            hyperbus_rx_cfg_continuous_i ,
    input  logic                            hyperbus_rx_cfg_en_i         ,
    input  logic                            hyperbus_rx_cfg_clr_i        ,
    output logic                            hyperbus_rx_ch_en_o          ,
    output logic                            hyperbus_rx_ch_pending_o     ,
    output logic                     [31:0] hyperbus_rx_ch_curr_addr_o   ,
    output logic                     [31:0] hyperbus_rx_ch_bytes_left_o  ,

    input  logic                     [31:0] hyperbus_tx_cfg_startaddr_i  ,
    input  logic                     [31:0] hyperbus_tx_cfg_size_i       ,
    input  logic                            hyperbus_tx_cfg_continuous_i ,
    input  logic                            hyperbus_tx_cfg_en_i         ,
    input  logic                            hyperbus_tx_cfg_clr_i        ,
    output logic                            hyperbus_tx_ch_en_o          ,
    output logic                            hyperbus_tx_ch_pending_o     ,
    output logic                     [31:0] hyperbus_tx_ch_curr_addr_o   ,
    output logic                     [31:0] hyperbus_tx_ch_bytes_left_o  ,

    input  logic                            hyperbus_tx_req_i            ,
    output logic                            hyperbus_tx_gnt_o            ,
    input  logic                      [1:0] hyperbus_tx_datasize_i       ,
    output logic                     [31:0] hyperbus_tx_o                ,
    output logic                            hyperbus_tx_valid_o          ,
    input  logic                            hyperbus_tx_ready_i          ,

    input  logic                      [1:0] hyperbus_rx_datasize_i       ,
    input  logic                     [31:0] hyperbus_rx_i                ,
    input  logic                            hyperbus_rx_valid_i          ,
    output logic                            hyperbus_rx_ready_o          ,
    input  logic                            evt_eot_hyper_i,

    //  ██████╗██████╗       ██╗███████╗
    // ██╔════╝██╔══██╗      ██║██╔════╝
    // ██║     ██████╔╝█████╗██║█████╗  
    // ██║     ██╔═══╝ ╚════╝██║██╔══╝  
    // ╚██████╗██║           ██║██║     
    //  ╚═════╝╚═╝           ╚═╝╚═╝     

    input  logic       cam_clk_i,
    input  logic [7:0] cam_data_i,
    input  logic       cam_hsync_i,
    input  logic       cam_vsync_i,

    // ██████╗ ██╗   ██╗███████╗      ██╗███████╗
    // ██╔══██╗██║   ██║██╔════╝      ██║██╔════╝
    // ██║  ██║██║   ██║███████╗█████╗██║█████╗  
    // ██║  ██║╚██╗ ██╔╝╚════██║╚════╝██║██╔══╝  
    // ██████╔╝ ╚████╔╝ ███████║      ██║██║     
    // ╚═════╝   ╚═══╝  ╚══════╝      ╚═╝╚═╝     
                                     
    output logic        dvs_asa_o     ,
    output logic        dvs_are_o     ,
    output logic        dvs_asy_o     ,
    output logic        dvs_ynrst_o   ,
    output logic        dvs_yclk_o    ,
    output logic        dvs_sxy_o     ,
    output logic        dvs_xclk_o    ,
    output logic        dvs_xnrst_o   ,
    input  logic [3:0]  dvs_on_i      ,
    input  logic [3:0]  dvs_off_i     ,
    input  logic [7:0]  dvs_xy_data_i ,

    output logic [7:0]  dvs_cfg_if_o  , 
    input  logic [7:0]  dvs_cfg_if_i  , 
    output logic [7:0]  dvs_cfg_if_oe ,

    // ███████╗███╗   ██╗███████╗    ███████╗████████╗██████╗ ███████╗ █████╗ ███╗   ███╗
    // ██╔════╝████╗  ██║██╔════╝    ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║
    // ███████╗██╔██╗ ██║█████╗      ███████╗   ██║   ██████╔╝█████╗  ███████║██╔████╔██║
    // ╚════██║██║╚██╗██║██╔══╝      ╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║
    // ███████║██║ ╚████║███████╗    ███████║   ██║   ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║
    // ╚══════╝╚═╝  ╚═══╝╚══════╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
                                                                                                                                                    
    output logic [31:0] sne_stream_data_o    ,
    output logic        sne_stream_valid_o   ,
    input  logic        sne_stream_ready_i   ,
    output logic  [1:0] sne_stream_datasize_o,
    output logic        sne_stream_sot_o     ,
    output logic        sne_stream_eot_o

    */
                                    
);

    //--- Tx lin channels signals declaration
    logic [N_TX_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] s_tx_cfg_startaddr   ;
    logic [N_TX_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] s_tx_cfg_size        ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_cfg_continuous  ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_cfg_en          ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_cfg_clr         ;
    logic [N_TX_LIN_CHANNELS-1:0]               [31 : 0] s_tx_ch_data         ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_valid        ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_ready        ;
    logic [N_TX_LIN_CHANNELS-1:0]                [1 : 0] s_tx_ch_datasize     ;
    logic [N_TX_LIN_CHANNELS-1:0]      [DEST_SIZE-1 : 0] s_tx_ch_destination  ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_events       ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_en           ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_pending      ;
    logic [N_TX_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] s_tx_ch_curr_addr    ;
    logic [N_TX_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] s_tx_ch_bytes_left   ;

    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_req          ;
    logic [N_TX_LIN_CHANNELS-1:0]                        s_tx_ch_gnt          ;

    //--- Rx lin channels signal declaration
    logic [N_RX_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] s_rx_cfg_startaddr   ;
    logic [N_RX_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] s_rx_cfg_size        ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_cfg_continuous  ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_cfg_en          ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_cfg_clr         ;
    logic [N_RX_LIN_CHANNELS-1:0]               [31 : 0] s_rx_ch_data         ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_ch_valid        ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_ch_ready        ;
    logic [N_RX_LIN_CHANNELS-1:0]                [1 : 0] s_rx_ch_datasize     ;
    logic [N_RX_LIN_CHANNELS-1:0]      [DEST_SIZE-1 : 0] s_rx_ch_destination  ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_ch_events       ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_ch_en           ;
    logic [N_RX_LIN_CHANNELS-1:0]                        s_rx_ch_pending      ;
    logic [N_RX_LIN_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] s_rx_ch_curr_addr    ;
    logic [N_RX_LIN_CHANNELS-1:0]     [TRANS_SIZE-1 : 0] s_rx_ch_bytes_left   ;

    logic [N_RX_LIN_CHANNELS-1:0]                [1 : 0] s_rx_cfg_stream      ;
    logic [N_RX_LIN_CHANNELS-1:0] [STREAM_ID_WIDTH-1: 0] s_rx_cfg_stream_id   ;

    //--- Rx ext channel signal declaration 
    logic [N_RX_EXT_CHANNELS-1:0]  [L2_AWIDTH_NOAL-1 : 0] s_rx_ext_addr       ;
    logic [N_RX_EXT_CHANNELS-1:0]                 [1 : 0] s_rx_ext_datasize   ;
    logic [N_RX_EXT_CHANNELS-1:0]       [DEST_SIZE-1 : 0] s_rx_ext_destination;
    logic [N_RX_EXT_CHANNELS-1:0]                 [1 : 0] s_rx_ext_stream     ;
    logic [N_RX_EXT_CHANNELS-1:0] [STREAM_ID_WIDTH-1 : 0] s_rx_ext_stream_id  ;
    logic [N_RX_EXT_CHANNELS-1:0]                         s_rx_ext_sot        ;
    logic [N_RX_EXT_CHANNELS-1:0]                         s_rx_ext_eot        ;
    logic [N_RX_EXT_CHANNELS-1:0]                         s_rx_ext_valid      ;
    logic [N_RX_EXT_CHANNELS-1:0]                [31 : 0] s_rx_ext_data       ;
    logic [N_RX_EXT_CHANNELS-1:0]                         s_rx_ext_ready      ;

    //--- Tx ext channel signal declaration 
    logic [N_TX_EXT_CHANNELS-1:0]                        s_tx_ext_req         ;
    logic [N_TX_EXT_CHANNELS-1:0]                [1 : 0] s_tx_ext_datasize    ;
    logic [N_TX_EXT_CHANNELS-1:0]      [DEST_SIZE-1 : 0] s_tx_ext_destination ;
    logic [N_TX_EXT_CHANNELS-1:0] [L2_AWIDTH_NOAL-1 : 0] s_tx_ext_addr        ;
    logic [N_TX_EXT_CHANNELS-1:0]                        s_tx_ext_gnt         ;
    logic [N_TX_EXT_CHANNELS-1:0]                        s_tx_ext_valid       ;
    logic [N_TX_EXT_CHANNELS-1:0]               [31 : 0] s_tx_ext_data        ;
    logic [N_TX_EXT_CHANNELS-1:0]                        s_tx_ext_ready       ;

    logic [        N_STREAMS-1:0]               [31 : 0] s_stream_data        ;
    logic [        N_STREAMS-1:0]                [1 : 0] s_stream_datasize    ;
    logic [        N_STREAMS-1:0]                        s_stream_valid       ;
    logic [        N_STREAMS-1:0]                        s_stream_sot         ;
    logic [        N_STREAMS-1:0]                        s_stream_eot         ;
    logic [        N_STREAMS-1:0]                        s_stream_ready       ;

    logic [16*8-1:0] s_events;

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
    logic            [  N_I2C-1:0] s_i2c_evt;
    //logic            [ `N_UART-1:0] s_uart_evt;

    logic         [3:0] s_trigger_events;

    //logic s_cam_evt;
    //logic s_i2s_evt;
    //logic s_i2c1_evt;

    logic s_filter_eot_evt;
    logic s_filter_act_evt;


    //integer i;
    //assign s_cam_evt     = 1'b0;
    //assign s_i2s_evt     = 1'b0;
    //assign s_uart_evt    = 1'b0;

    assign events_o      = s_events;

    assign L2_ro_wen_o   = 1'b1;
    assign L2_wo_wen_o   = 1'b0;

    assign L2_ro_be_o    =  'h0;
    assign L2_ro_wdata_o =  'h0;

    UDMA_LIN_CH lin_ch_rx[N_RX_LIN_CHANNELS-1:0](.clk_i(clk_i));
    UDMA_LIN_CH lin_ch_tx[N_TX_LIN_CHANNELS-1:0](.clk_i(clk_i));
    UDMA_EXT_CH ext_ch_rx[N_RX_EXT_CHANNELS-1:0](.clk_i(clk_i));
    UDMA_EXT_CH ext_ch_tx[N_TX_EXT_CHANNELS-1:0](.clk_i(clk_i));
    UDMA_EXT_CH str_ch_tx[N_STREAMS-1:0](.clk_i(clk_i));

    // ██╗   ██╗██████╗ ███╗   ███╗ █████╗      ██████╗ ██████╗ ██████╗ ███████╗
    // ██║   ██║██╔══██╗████╗ ████║██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
    // ██║   ██║██║  ██║██╔████╔██║███████║    ██║     ██║   ██║██████╔╝█████╗  
    // ██║   ██║██║  ██║██║╚██╔╝██║██╔══██║    ██║     ██║   ██║██╔══██╗██╔══╝  
    // ╚██████╔╝██████╔╝██║ ╚═╝ ██║██║  ██║    ╚██████╗╚██████╔╝██║  ██║███████╗
    //  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

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


    // ██╗   ██╗ █████╗ ██████╗ ████████╗
    // ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝
    // ██║   ██║███████║██████╔╝   ██║   
    // ██║   ██║██╔══██║██╔══██╗   ██║   
    // ╚██████╔╝██║  ██║██║  ██║   ██║   
    //  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   

    // PER_ID:
    // UART0 = 0
    // UART1 = 1
    for (genvar g_uart=0;g_uart<N_UART;g_uart++) begin: uart

        assign s_events[4*(PER_ID_UART+g_uart)+0]        = s_rx_ch_events[CH_ID_LIN_RX_UART+g_uart];
        assign s_events[4*(PER_ID_UART+g_uart)+1]        = s_tx_ch_events[CH_ID_LIN_TX_UART+g_uart];
        assign s_events[4*(PER_ID_UART+g_uart)+2]        = 1'b0                                    ;
        assign s_events[4*(PER_ID_UART+g_uart)+3]        = 1'b0                                    ;

        assign s_rx_cfg_stream[CH_ID_LIN_RX_UART+g_uart]     = 'h0;
        assign s_rx_cfg_stream_id[CH_ID_LIN_RX_UART+g_uart]  = 'h0;
        assign s_rx_ch_destination[CH_ID_LIN_RX_UART+g_uart] = 'h0;
        assign s_tx_ch_destination[CH_ID_LIN_TX_UART+g_uart] = 'h0;

        udma_uart_top #(
            .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
            .TRANS_SIZE(TRANS_SIZE)

        ) i_uart(

            .sys_clk_i           ( s_clk_periphs_core[         PER_ID_UART+g_uart] ),
            .periph_clk_i        ( s_clk_periphs_per[          PER_ID_UART+g_uart] ),
            .rstn_i              ( sys_resetn_i                                    ),

            .uart_tx_o           ( uart_tx_o[                              g_uart] ),
            .uart_rx_i           ( uart_rx_i[                              g_uart] ),

            .cfg_data_i          ( s_periph_data_to                                ),
            .cfg_addr_i          ( s_periph_addr                                   ),
            .cfg_valid_i         ( s_periph_valid[             PER_ID_UART+g_uart] ),
            .cfg_rwn_i           ( s_periph_rwn                                    ),
            .cfg_data_o          ( s_periph_data_from[         PER_ID_UART+g_uart] ),
            .cfg_ready_o         ( s_periph_ready[             PER_ID_UART+g_uart] ),

            .cfg_rx_startaddr_o  ( s_rx_cfg_startaddr[   CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_size_o       ( s_rx_cfg_size[        CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_continuous_o ( s_rx_cfg_continuous[  CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_en_o         ( s_rx_cfg_en[          CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_clr_o        ( s_rx_cfg_clr[         CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_en_i         ( s_rx_ch_en[           CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_pending_i    ( s_rx_ch_pending[      CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_curr_addr_i  ( s_rx_ch_curr_addr[    CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_bytes_left_i ( s_rx_ch_bytes_left[   CH_ID_LIN_RX_UART+g_uart] ),
            .cfg_rx_datasize_o   (                                                 ),  // FIXME ANTONIO

            .cfg_tx_startaddr_o  ( s_tx_cfg_startaddr[   CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_size_o       ( s_tx_cfg_size[        CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_continuous_o ( s_tx_cfg_continuous[  CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_en_o         ( s_tx_cfg_en[          CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_clr_o        ( s_tx_cfg_clr[         CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_en_i         ( s_tx_ch_en[           CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_pending_i    ( s_tx_ch_pending[      CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_curr_addr_i  ( s_tx_ch_curr_addr[    CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_bytes_left_i ( s_tx_ch_bytes_left[   CH_ID_LIN_TX_UART+g_uart] ),
            .cfg_tx_datasize_o   (                                                 ),  // FIXME ANTONIO

            .data_tx_req_o       ( s_tx_ch_req[          CH_ID_LIN_TX_UART+g_uart] ),
            .data_tx_gnt_i       ( s_tx_ch_gnt[          CH_ID_LIN_TX_UART+g_uart] ),
            .data_tx_datasize_o  ( s_tx_ch_datasize[     CH_ID_LIN_TX_UART+g_uart] ),
            .data_tx_i           ( s_tx_ch_data[         CH_ID_LIN_TX_UART+g_uart] ),
            .data_tx_valid_i     ( s_tx_ch_valid[        CH_ID_LIN_TX_UART+g_uart] ),
            .data_tx_ready_o     ( s_tx_ch_ready[        CH_ID_LIN_TX_UART+g_uart] ),

            .data_rx_datasize_o  ( s_rx_ch_datasize[     CH_ID_LIN_RX_UART+g_uart] ),
            .data_rx_o           ( s_rx_ch_data[         CH_ID_LIN_RX_UART+g_uart] ),
            .data_rx_valid_o     ( s_rx_ch_valid[        CH_ID_LIN_RX_UART+g_uart] ),
            .rx_char_event_o     (                                                 ), //---> FIXME (why not connected?)
            .err_event_o         (                                                 ), //---> FIXME (why not connected?)
            .data_rx_ready_i     ( s_rx_ch_ready[        CH_ID_LIN_RX_UART+g_uart] )
        );
    end: uart

/*    //  ██████╗ ███████╗██████╗ ██╗      ███╗   ███╗
    // ██╔═══██╗██╔════╝██╔══██╗██║      ████╗ ████║
    // ██║   ██║███████╗██████╔╝██║█████╗██╔████╔██║
    // ██║▄▄ ██║╚════██║██╔═══╝ ██║╚════╝██║╚██╔╝██║
    // ╚██████╔╝███████║██║     ██║      ██║ ╚═╝ ██║
    //  ╚══▀▀═╝ ╚══════╝╚═╝     ╚═╝      ╚═╝     ╚═╝

    // PER_ID:
    // QSPIM0 = 2   
    // QSPIM1 = 3   
    // QSPIM2 = 4   
    // QSPIM3 = 5   
    generate
        for (genvar g_spi=0;g_spi<`N_QSPIM;g_spi++)
        begin : i_spim_gen
            assign s_events[4*(PER_ID_QSPIM+g_spi)+0] = s_rx_ch_events[    CH_ID_LIN_RX_QSPIM+g_spi];
            assign s_events[4*(PER_ID_QSPIM+g_spi)+1] = s_tx_ch_events[    CH_ID_LIN_TX_QSPIM+g_spi];
            assign s_events[4*(PER_ID_QSPIM+g_spi)+2] = s_tx_ch_events[CH_ID_LIN_TX_CMD_QSPIM+g_spi];
            assign s_events[4*(PER_ID_QSPIM+g_spi)+3] = s_spi_eot[                            g_spi];

            assign s_rx_cfg_stream[CH_ID_LIN_RX_QSPIM+g_spi]         = 'h0;
            assign s_rx_cfg_stream_id[CH_ID_LIN_RX_QSPIM+g_spi]      = 'h0;
            assign s_rx_ch_destination[CH_ID_LIN_RX_QSPIM+g_spi]     = 'h0;
            assign s_tx_ch_destination[CH_ID_LIN_TX_QSPIM+g_spi]     = 'h0;
            assign s_tx_ch_destination[CH_ID_LIN_TX_CMD_QSPIM+g_spi] = 'h0;
            udma_spim_top
            #(
                .L2_AWIDTH_NOAL      ( L2_AWIDTH_NOAL                                     ),
                .TRANS_SIZE          ( TRANS_SIZE                                         )

            ) i_spim (

                .sys_clk_i           ( s_clk_periphs_core[PER_ID_QSPIM+g_spi]             ),
                .periph_clk_i        ( s_clk_periphs_per[ PER_ID_QSPIM+g_spi]             ),
                .rstn_i              ( sys_resetn_i                                       ),
                .dft_test_mode_i     ( dft_test_mode_i                                    ),
                .dft_cg_enable_i     ( dft_cg_enable_i                                    ),
                .spi_eot_o           ( s_spi_eot[g_spi]                                   ),
                .spi_event_i         ( s_trigger_events                                   ),
                .spi_clk_o           ( spi_clk_o[g_spi]                                   ),
                .spi_csn0_o          ( spi_csn_o[g_spi][0]                                ),
                .spi_csn1_o          ( spi_csn_o[g_spi][1]                                ),
                .spi_csn2_o          ( spi_csn_o[g_spi][2]                                ),
                .spi_csn3_o          ( spi_csn_o[g_spi][3]                                ),
                .spi_oen0_o          ( spi_oen_o[g_spi][0]                                ),
                .spi_oen1_o          ( spi_oen_o[g_spi][1]                                ),
                .spi_oen2_o          ( spi_oen_o[g_spi][2]                                ),
                .spi_oen3_o          ( spi_oen_o[g_spi][3]                                ),
                .spi_sdi0_i          ( spi_sdi_i[g_spi][0]                                ),
                .spi_sdi1_i          ( spi_sdi_i[g_spi][1]                                ),
                .spi_sdi2_i          ( spi_sdi_i[g_spi][2]                                ),
                .spi_sdi3_i          ( spi_sdi_i[g_spi][3]                                ),
                .spi_sdo0_o          ( spi_sdo_o[g_spi][0]                                ),
                .spi_sdo1_o          ( spi_sdo_o[g_spi][1]                                ),
                .spi_sdo2_o          ( spi_sdo_o[g_spi][2]                                ),
                .spi_sdo3_o          ( spi_sdo_o[g_spi][3]                                ),

                .cfg_data_i          ( s_periph_data_to                                   ),
                .cfg_addr_i          ( s_periph_addr                                      ),
                .cfg_valid_i         ( s_periph_valid[PER_ID_QSPIM+g_spi]                 ),
                .cfg_rwn_i           ( s_periph_rwn                                       ),
                .cfg_data_o          ( s_periph_data_from[PER_ID_QSPIM+g_spi]             ),
                .cfg_ready_o         ( s_periph_ready[PER_ID_QSPIM+g_spi]                 ),

                .cmd_req_o           ( s_tx_ch_req[CH_ID_LIN_TX_CMD_QSPIM+g_spi]          ),
                .cmd_gnt_i           ( s_tx_ch_gnt[CH_ID_LIN_TX_CMD_QSPIM+g_spi]          ),
                .cmd_datasize_o      ( s_tx_ch_datasize[CH_ID_LIN_TX_CMD_QSPIM+g_spi]     ),
                .cmd_i               ( s_tx_ch_data[CH_ID_LIN_TX_CMD_QSPIM+g_spi]         ),
                .cmd_valid_i         ( s_tx_ch_valid[CH_ID_LIN_TX_CMD_QSPIM+g_spi]        ),
                .cmd_ready_o         ( s_tx_ch_ready[CH_ID_LIN_TX_CMD_QSPIM+g_spi]        ),

                .data_tx_req_o       ( s_tx_ch_req[CH_ID_LIN_TX_QSPIM+g_spi]              ),
                .data_tx_gnt_i       ( s_tx_ch_gnt[CH_ID_LIN_TX_QSPIM+g_spi]              ),
                .data_tx_datasize_o  ( s_tx_ch_datasize[CH_ID_LIN_TX_QSPIM+g_spi]         ),
                .data_tx_i           ( s_tx_ch_data[CH_ID_LIN_TX_QSPIM+g_spi]             ),
                .data_tx_valid_i     ( s_tx_ch_valid[CH_ID_LIN_TX_QSPIM+g_spi]            ),
                .data_tx_ready_o     ( s_tx_ch_ready[CH_ID_LIN_TX_QSPIM+g_spi]            ),

                .data_rx_datasize_o  ( s_rx_ch_datasize[CH_ID_LIN_RX_QSPIM+g_spi]         ),
                .data_rx_o           ( s_rx_ch_data[CH_ID_LIN_RX_QSPIM+g_spi]             ),
                .data_rx_valid_o     ( s_rx_ch_valid[CH_ID_LIN_RX_QSPIM+g_spi]            ),
                .data_rx_ready_i     ( s_rx_ch_ready[CH_ID_LIN_RX_QSPIM+g_spi]            ),

                .cfg_cmd_startaddr_o  ( s_tx_cfg_startaddr[CH_ID_LIN_TX_CMD_QSPIM+g_spi]  ),
                .cfg_cmd_size_o       ( s_tx_cfg_size[CH_ID_LIN_TX_CMD_QSPIM+g_spi]       ),
                .cfg_cmd_continuous_o ( s_tx_cfg_continuous[CH_ID_LIN_TX_CMD_QSPIM+g_spi] ),
                .cfg_cmd_en_o         ( s_tx_cfg_en[CH_ID_LIN_TX_CMD_QSPIM+g_spi]         ),
                .cfg_cmd_clr_o        ( s_tx_cfg_clr[CH_ID_LIN_TX_CMD_QSPIM+g_spi]        ),
                .cfg_cmd_en_i         ( s_tx_ch_en[CH_ID_LIN_TX_CMD_QSPIM+g_spi]          ),
                .cfg_cmd_pending_i    ( s_tx_ch_pending[CH_ID_LIN_TX_CMD_QSPIM+g_spi]     ),
                .cfg_cmd_curr_addr_i  ( s_tx_ch_curr_addr[CH_ID_LIN_TX_CMD_QSPIM+g_spi]   ),
                .cfg_cmd_bytes_left_i ( s_tx_ch_bytes_left[CH_ID_LIN_TX_CMD_QSPIM+g_spi]  ),

                .cfg_tx_startaddr_o  ( s_tx_cfg_startaddr[CH_ID_LIN_TX_QSPIM+g_spi]       ),
                .cfg_tx_size_o       ( s_tx_cfg_size[CH_ID_LIN_TX_QSPIM+g_spi]            ),
                .cfg_tx_continuous_o ( s_tx_cfg_continuous[CH_ID_LIN_TX_QSPIM+g_spi]      ),
                .cfg_tx_en_o         ( s_tx_cfg_en[CH_ID_LIN_TX_QSPIM+g_spi]              ),
                .cfg_tx_clr_o        ( s_tx_cfg_clr[CH_ID_LIN_TX_QSPIM+g_spi]             ),
                .cfg_tx_en_i         ( s_tx_ch_en[CH_ID_LIN_TX_QSPIM+g_spi]               ),
                .cfg_tx_pending_i    ( s_tx_ch_pending[CH_ID_LIN_TX_QSPIM+g_spi]          ),
                .cfg_tx_curr_addr_i  ( s_tx_ch_curr_addr[CH_ID_LIN_TX_QSPIM+g_spi]        ),
                .cfg_tx_bytes_left_i ( s_tx_ch_bytes_left[CH_ID_LIN_TX_QSPIM+g_spi]       ),

                .cfg_rx_startaddr_o  ( s_rx_cfg_startaddr[CH_ID_LIN_RX_QSPIM+g_spi]       ),
                .cfg_rx_size_o       ( s_rx_cfg_size[CH_ID_LIN_RX_QSPIM+g_spi]            ),
                .cfg_rx_continuous_o ( s_rx_cfg_continuous[CH_ID_LIN_RX_QSPIM+g_spi]      ),
                .cfg_rx_en_o         ( s_rx_cfg_en[CH_ID_LIN_RX_QSPIM+g_spi]              ),
                .cfg_rx_clr_o        ( s_rx_cfg_clr[CH_ID_LIN_RX_QSPIM+g_spi]             ),
                .cfg_rx_en_i         ( s_rx_ch_en[CH_ID_LIN_RX_QSPIM+g_spi]               ),
                .cfg_rx_pending_i    ( s_rx_ch_pending[CH_ID_LIN_RX_QSPIM+g_spi]          ),
                .cfg_rx_curr_addr_i  ( s_rx_ch_curr_addr[CH_ID_LIN_RX_QSPIM+g_spi]        ),
                .cfg_rx_bytes_left_i ( s_rx_ch_bytes_left[CH_ID_LIN_RX_QSPIM+g_spi]       )
            );
        end
    endgenerate

    // ██╗██████╗  ██████╗
    // ██║╚════██╗██╔════╝
    // ██║ █████╔╝██║     
    // ██║██╔═══╝ ██║     
    // ██║███████╗╚██████╗
    // ╚═╝╚══════╝ ╚═════╝

    //PER_ID:
    //I2C0 = 6
    //I2C1 = 7
    //I2C2 = 8
    generate
        for (genvar g_i2c=0;g_i2c<`N_I2C;g_i2c++)
        begin: i_i2c_gen
            assign s_events[4*(PER_ID_I2C+g_i2c)+0] = s_rx_ch_events[CH_ID_LIN_RX_I2C+g_i2c];
            assign s_events[4*(PER_ID_I2C+g_i2c)+1] = s_tx_ch_events[CH_ID_LIN_TX_I2C+g_i2c];
            assign s_events[4*(PER_ID_I2C+g_i2c)+2] = 1'b0;
            assign s_events[4*(PER_ID_I2C+g_i2c)+3] = 1'b0;

            assign s_rx_cfg_stream[     CH_ID_LIN_RX_I2C+g_i2c]       = 'h0;
            assign s_rx_cfg_stream_id[  CH_ID_LIN_RX_I2C+g_i2c]       = 'h0;
            assign s_rx_ch_destination[ CH_ID_LIN_RX_I2C+g_i2c]       = 'h0;
            assign s_tx_ch_destination[ CH_ID_LIN_TX_I2C+g_i2c]       = 'h0;
            assign s_rx_ch_data[        CH_ID_LIN_RX_I2C+g_i2c][31:8] = 'h0;

            udma_i2c_top #(
                .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
                .TRANS_SIZE(TRANS_SIZE)
            ) i_i2c (

                .sys_clk_i           ( s_clk_periphs_core[       PER_ID_I2C+g_i2c]      ),
                .periph_clk_i        ( s_clk_periphs_per[        PER_ID_I2C+g_i2c]      ),
                .rstn_i              ( sys_resetn_i                                     ),

                .cfg_data_i          ( s_periph_data_to                                 ),
                .cfg_addr_i          ( s_periph_addr                                    ),
                .cfg_valid_i         ( s_periph_valid[           PER_ID_I2C+g_i2c]      ),
                .cfg_rwn_i           ( s_periph_rwn                                     ),
                .cfg_data_o          ( s_periph_data_from[       PER_ID_I2C+g_i2c]      ),
                .cfg_ready_o         ( s_periph_ready[           PER_ID_I2C+g_i2c]      ),
      

                .cfg_tx_startaddr_o  ( s_tx_cfg_startaddr[ CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_size_o       ( s_tx_cfg_size[      CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_continuous_o ( s_tx_cfg_continuous[CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_en_o         ( s_tx_cfg_en[        CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_clr_o        ( s_tx_cfg_clr[       CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_en_i         ( s_tx_ch_en[         CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_pending_i    ( s_tx_ch_pending[    CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_curr_addr_i  ( s_tx_ch_curr_addr[  CH_ID_LIN_TX_I2C+g_i2c]      ),
                .cfg_tx_bytes_left_i ( s_tx_ch_bytes_left[ CH_ID_LIN_TX_I2C+g_i2c]      ),

                .cfg_rx_startaddr_o  ( s_rx_cfg_startaddr[ CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_size_o       ( s_rx_cfg_size[      CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_continuous_o ( s_rx_cfg_continuous[CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_en_o         ( s_rx_cfg_en[        CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_clr_o        ( s_rx_cfg_clr[       CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_en_i         ( s_rx_ch_en[         CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_pending_i    ( s_rx_ch_pending[    CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_curr_addr_i  ( s_rx_ch_curr_addr[  CH_ID_LIN_RX_I2C+g_i2c]      ),
                .cfg_rx_bytes_left_i ( s_rx_ch_bytes_left[ CH_ID_LIN_RX_I2C+g_i2c]      ),

                .data_tx_req_o       ( s_tx_ch_req[        CH_ID_LIN_TX_I2C+g_i2c]      ),
                .data_tx_gnt_i       ( s_tx_ch_gnt[        CH_ID_LIN_TX_I2C+g_i2c]      ),
                .data_tx_datasize_o  ( s_tx_ch_datasize[   CH_ID_LIN_TX_I2C+g_i2c]      ),
                .data_tx_i           ( s_tx_ch_data[       CH_ID_LIN_TX_I2C+g_i2c][7:0] ),
                .data_tx_valid_i     ( s_tx_ch_valid[      CH_ID_LIN_TX_I2C+g_i2c]      ),
                .data_tx_ready_o     ( s_tx_ch_ready[      CH_ID_LIN_TX_I2C+g_i2c]      ),

                .data_rx_datasize_o  ( s_rx_ch_datasize[   CH_ID_LIN_RX_I2C+g_i2c]      ),
                .data_rx_o           ( s_rx_ch_data[       CH_ID_LIN_RX_I2C+g_i2c][7:0] ),
                .data_rx_valid_o     ( s_rx_ch_valid[      CH_ID_LIN_RX_I2C+g_i2c]      ),
                .data_rx_ready_i     ( s_rx_ch_ready[      CH_ID_LIN_RX_I2C+g_i2c]      ),

                .err_o               ( s_i2c_evt[g_i2c]                                 ),

                .scl_i               ( i2c_scl_i[g_i2c]                                 ),
                .scl_o               ( i2c_scl_o[g_i2c]                                 ),
                .scl_oe              ( i2c_scl_oe[g_i2c]                                ),
                .sda_i               ( i2c_sda_i[g_i2c]                                 ),
                .sda_o               ( i2c_sda_o[g_i2c]                                 ),
                .sda_oe              ( i2c_sda_oe[g_i2c]                                ),
                .ext_events_i        ( s_trigger_events                                 )
            );
        end
    endgenerate

    // ██╗██████╗ ███████╗
    // ██║╚════██╗██╔════╝
    // ██║ █████╔╝███████╗
    // ██║██╔═══╝ ╚════██║
    // ██║███████╗███████║
    // ╚═╝╚══════╝╚══════╝

    //PER_ID:
    //I2S0 = 9
    assign s_events[4*PER_ID_I2S]    = s_rx_ch_events[CH_ID_LIN_RX_I2S];
    assign s_events[4*PER_ID_I2S+1]  = s_tx_ch_events[CH_ID_LIN_TX_I2S];
    assign s_events[4*PER_ID_I2S+2]  = 1'b0;
    assign s_events[4*PER_ID_I2S+3]  = 1'b0;
    assign s_rx_cfg_stream[CH_ID_LIN_RX_I2S] = 'h0;
    assign s_rx_cfg_stream_id[CH_ID_LIN_RX_I2S] = 'h0;
    assign s_rx_ch_destination[CH_ID_LIN_RX_I2S] = 'h0;
    assign s_tx_ch_destination[CH_ID_LIN_TX_I2S] = 'h0;
    udma_i2s_top #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) i_i2s_udma (
        .sys_clk_i           ( s_clk_periphs_core[       PER_ID_I2S] ),
        .periph_clk_i        ( s_clk_periphs_per[        PER_ID_I2S] ),
        .rstn_i              ( sys_resetn_i                          ),

        .dft_test_mode_i     ( dft_test_mode_i                       ),
        .dft_cg_enable_i     ( dft_cg_enable_i                       ),

        .pad_slave_sd0_i     ( i2s_slave_sd0_i                       ),
        .pad_slave_sd1_i     ( i2s_slave_sd1_i                       ),
        .pad_slave_sck_i     ( i2s_slave_sck_i                       ),
        .pad_slave_sck_o     ( i2s_slave_sck_o                       ),
        .pad_slave_sck_oe    ( i2s_slave_sck_oe                      ),
        .pad_slave_ws_i      ( i2s_slave_ws_i                        ),
        .pad_slave_ws_o      ( i2s_slave_ws_o                        ),
        .pad_slave_ws_oe     ( i2s_slave_ws_oe                       ),

        .pad_master_sd0_o    ( i2s_master_sd0_o                      ),
        .pad_master_sd1_o    ( i2s_master_sd1_o                      ),
        .pad_master_sck_i    ( i2s_master_sck_i                      ),
        .pad_master_sck_o    ( i2s_master_sck_o                      ),
        .pad_master_sck_oe   ( i2s_master_sck_oe                     ),
        .pad_master_ws_i     ( i2s_master_ws_i                       ),
        .pad_master_ws_o     ( i2s_master_ws_o                       ),
        .pad_master_ws_oe    ( i2s_master_ws_oe                      ),

        .cfg_data_i          ( s_periph_data_to                      ),
        .cfg_addr_i          ( s_periph_addr                         ),
        .cfg_rwn_i           ( s_periph_rwn                          ),
        .cfg_valid_i         ( s_periph_valid[           PER_ID_I2S] ),
        .cfg_data_o          ( s_periph_data_from[       PER_ID_I2S] ),
        .cfg_ready_o         ( s_periph_ready[           PER_ID_I2S] ),

        .cfg_rx_startaddr_o  ( s_rx_cfg_startaddr[ CH_ID_LIN_RX_I2S] ),
        .cfg_rx_size_o       ( s_rx_cfg_size[      CH_ID_LIN_RX_I2S] ),
        .cfg_rx_continuous_o ( s_rx_cfg_continuous[CH_ID_LIN_RX_I2S] ),
        .cfg_rx_en_o         ( s_rx_cfg_en[        CH_ID_LIN_RX_I2S] ),
        .cfg_rx_clr_o        ( s_rx_cfg_clr[       CH_ID_LIN_RX_I2S] ),
        .cfg_rx_en_i         ( s_rx_ch_en[         CH_ID_LIN_RX_I2S] ),
        .cfg_rx_pending_i    ( s_rx_ch_pending[    CH_ID_LIN_RX_I2S] ),
        .cfg_rx_curr_addr_i  ( s_rx_ch_curr_addr[  CH_ID_LIN_RX_I2S] ),
        .cfg_rx_bytes_left_i ( s_rx_ch_bytes_left[ CH_ID_LIN_RX_I2S] ),

        .cfg_tx_startaddr_o  ( s_tx_cfg_startaddr[ CH_ID_LIN_TX_I2S] ),
        .cfg_tx_size_o       ( s_tx_cfg_size[      CH_ID_LIN_TX_I2S] ),
        .cfg_tx_continuous_o ( s_tx_cfg_continuous[CH_ID_LIN_TX_I2S] ),
        .cfg_tx_en_o         ( s_tx_cfg_en[        CH_ID_LIN_TX_I2S] ),
        .cfg_tx_clr_o        ( s_tx_cfg_clr[       CH_ID_LIN_TX_I2S] ),
        .cfg_tx_en_i         ( s_tx_ch_en[         CH_ID_LIN_TX_I2S] ),
        .cfg_tx_pending_i    ( s_tx_ch_pending[    CH_ID_LIN_TX_I2S] ),
        .cfg_tx_curr_addr_i  ( s_tx_ch_curr_addr[  CH_ID_LIN_TX_I2S] ),
        .cfg_tx_bytes_left_i ( s_tx_ch_bytes_left[ CH_ID_LIN_TX_I2S] ),

        .data_rx_datasize_o  ( s_rx_ch_datasize[   CH_ID_LIN_RX_I2S] ),
        .data_rx_o           ( s_rx_ch_data[       CH_ID_LIN_RX_I2S] ),
        .data_rx_valid_o     ( s_rx_ch_valid[      CH_ID_LIN_RX_I2S] ),
        .data_rx_ready_i     ( s_rx_ch_ready[      CH_ID_LIN_RX_I2S] ),

        .data_tx_req_o       ( s_tx_ch_req[        CH_ID_LIN_TX_I2S] ),
        .data_tx_gnt_i       ( s_tx_ch_gnt[        CH_ID_LIN_TX_I2S] ),
        .data_tx_datasize_o  ( s_tx_ch_datasize[   CH_ID_LIN_TX_I2S] ),
        .data_tx_i           ( s_tx_ch_data[       CH_ID_LIN_TX_I2S] ),
        .data_tx_valid_i     ( s_tx_ch_valid[      CH_ID_LIN_TX_I2S] ),
        .data_tx_ready_o     ( s_tx_ch_ready[      CH_ID_LIN_TX_I2S] ) 
    );

    // ██╗  ██╗██╗   ██╗██████╗ ███████╗██████╗       ██████╗ 
    // ██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗      ██╔══██╗
    // ███████║ ╚████╔╝ ██████╔╝█████╗  ██████╔╝█████╗██████╔╝
    // ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗╚════╝██╔══██╗
    // ██║  ██║   ██║   ██║     ███████╗██║  ██║      ██████╔╝
    // ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝╚═╝  ╚═╝      ╚═════╝ 

    //PER_ID:
    //HYPER_BUS = 10
    //--- dummy hyperbus (the real instance has been moved to top)
        assign hyperbus_clk_periphs_core_o             = s_clk_periphs_core[       PER_ID_HYPER];
        assign hyperbus_clk_periphs_per_o              = s_clk_periphs_per[        PER_ID_HYPER];
        assign hyperbus_sys_resetn_o                   = sys_resetn_i                           ;

        assign hyperbus_periph_data_to_o               = s_periph_data_to                       ;
        assign hyperbus_periph_addr_o                  = s_periph_addr                          ;
        assign hyperbus_periph_valid_o                 = s_periph_valid[           PER_ID_HYPER];
        assign hyperbus_periph_rwn_o                   = s_periph_rwn                           ;
        assign s_periph_ready[           PER_ID_HYPER] = hyperbus_periph_ready_i                ;
        assign s_periph_data_from[       PER_ID_HYPER] = hyperbus_periph_data_from_i            ;

        //--- cfg rx channel
        assign s_rx_cfg_startaddr[ CH_ID_LIN_RX_HYPER] = hyperbus_rx_cfg_startaddr_i[L2_AWIDTH_NOAL-1 : 0];
        assign s_rx_cfg_size[      CH_ID_LIN_RX_HYPER] = hyperbus_rx_cfg_size_i[         TRANS_SIZE-1 : 0];
        assign s_rx_cfg_continuous[CH_ID_LIN_RX_HYPER] = hyperbus_rx_cfg_continuous_i           ;
        assign s_rx_cfg_en[        CH_ID_LIN_RX_HYPER] = hyperbus_rx_cfg_en_i                   ;
        assign s_rx_cfg_clr[       CH_ID_LIN_RX_HYPER] = hyperbus_rx_cfg_clr_i                  ;
        assign hyperbus_rx_ch_en_o                     = s_rx_ch_en[         CH_ID_LIN_RX_HYPER];
        assign hyperbus_rx_ch_pending_o                = s_rx_ch_pending[    CH_ID_LIN_RX_HYPER];
        assign hyperbus_rx_ch_curr_addr_o              = {{31-L2_AWIDTH_NOAL{1'b0}},s_rx_ch_curr_addr[  CH_ID_LIN_RX_HYPER]}; //---> FIXME (check)
        assign hyperbus_rx_ch_bytes_left_o             = {{    31-TRANS_SIZE{1'b0}},s_rx_ch_bytes_left[ CH_ID_LIN_RX_HYPER]}; //---> FIXME (check)

        //cfg tx channel
        assign s_tx_cfg_startaddr[ CH_ID_LIN_TX_HYPER] = hyperbus_tx_cfg_startaddr_i[  L2_AWIDTH_NOAL-1 : 0];
        assign s_tx_cfg_size[      CH_ID_LIN_TX_HYPER] = hyperbus_tx_cfg_size_i[           TRANS_SIZE-1 : 0];
        assign s_tx_cfg_continuous[CH_ID_LIN_TX_HYPER] = hyperbus_tx_cfg_continuous_i           ;
        assign s_tx_cfg_en[        CH_ID_LIN_TX_HYPER] = hyperbus_tx_cfg_en_i                   ;
        assign s_tx_cfg_clr[       CH_ID_LIN_TX_HYPER] = hyperbus_tx_cfg_clr_i                  ;
        assign hyperbus_tx_ch_en_o                     = s_tx_ch_en[         CH_ID_LIN_TX_HYPER];
        assign hyperbus_tx_ch_pending_o                = s_tx_ch_pending[    CH_ID_LIN_TX_HYPER];
        assign hyperbus_tx_ch_curr_addr_o              = {{31-L2_AWIDTH_NOAL{1'b0}},s_tx_ch_curr_addr[  CH_ID_LIN_TX_HYPER]}; //---> FIXME (check) 
        assign hyperbus_tx_ch_bytes_left_o             = {{    31-TRANS_SIZE{1'b0}},s_tx_ch_bytes_left[ CH_ID_LIN_TX_HYPER]}; //---> FIXME (check) 

        //--- tx channel 
        assign s_tx_ch_req[        CH_ID_LIN_TX_HYPER] = hyperbus_tx_req_i                      ;
        assign hyperbus_tx_gnt_o                       = s_tx_ch_gnt[        CH_ID_LIN_TX_HYPER];
        assign s_tx_ch_datasize[   CH_ID_LIN_TX_HYPER] = hyperbus_tx_datasize_i                 ;
        assign hyperbus_tx_o                           = s_tx_ch_data[       CH_ID_LIN_TX_HYPER];
        assign hyperbus_tx_valid_o                     = s_tx_ch_valid[      CH_ID_LIN_TX_HYPER];
        assign s_tx_ch_ready[      CH_ID_LIN_TX_HYPER] = hyperbus_tx_ready_i                    ;

        //--- rx channel
        assign s_rx_ch_datasize[   CH_ID_LIN_RX_HYPER] = hyperbus_rx_datasize_i                 ;
        assign s_rx_ch_data[       CH_ID_LIN_RX_HYPER] = hyperbus_rx_i                          ;
        assign s_rx_ch_valid[      CH_ID_LIN_RX_HYPER] = hyperbus_rx_valid_i                    ;
        assign hyperbus_rx_ready_o                     = s_rx_ch_ready[      CH_ID_LIN_RX_HYPER];

        assign s_rx_cfg_stream[    CH_ID_LIN_RX_HYPER] = 'h0;
        assign s_rx_cfg_stream_id[ CH_ID_LIN_RX_HYPER] = 'h0;
        assign s_rx_ch_destination[CH_ID_LIN_RX_HYPER] = 'h0;
        assign s_tx_ch_destination[CH_ID_LIN_TX_HYPER] = 'h0;

        assign s_events[             4*PER_ID_HYPER  ] = s_rx_ch_events[CH_ID_LIN_RX_HYPER];
        assign s_events[             4*PER_ID_HYPER+1] = s_tx_ch_events[CH_ID_LIN_TX_HYPER];
        assign s_events[             4*PER_ID_HYPER+2] = 1'b0;
        assign s_events[             4*PER_ID_HYPER+3] = evt_eot_hyper_i;


    //  ██████╗██████╗       ██╗███████╗
    // ██╔════╝██╔══██╗      ██║██╔════╝
    // ██║     ██████╔╝█████╗██║█████╗  
    // ██║     ██╔═══╝ ╚════╝██║██╔══╝  
    // ╚██████╗██║           ██║██║     
    //  ╚═════╝╚═╝           ╚═╝╚═╝     

    //PER_ID
    //CPI = 11
    assign s_events[             4*PER_ID_CAM  ] = s_rx_ch_events[CH_ID_LIN_RX_CAM];
    assign s_events[             4*PER_ID_CAM+1] = 1'b0;
    assign s_events[             4*PER_ID_CAM+2] = 1'b0;
    assign s_events[             4*PER_ID_CAM+3] = 1'b0;
    assign s_rx_cfg_stream[    CH_ID_LIN_RX_CAM] = 'h0;
    assign s_rx_cfg_stream_id[ CH_ID_LIN_RX_CAM] = 'h0;
    assign s_rx_ch_destination[CH_ID_LIN_RX_CAM] = 'h0;
    camera_if #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE),
        .DATA_WIDTH(8)
    ) i_camera_if (
        .clk_i               ( s_clk_periphs_core[       PER_ID_CAM]      ),
        .rstn_i              ( sys_resetn_i                               ),

        .dft_test_mode_i     ( dft_test_mode_i                            ),
        .dft_cg_enable_i     ( dft_cg_enable_i                            ),

        .cfg_data_i          ( s_periph_data_to                           ),
        .cfg_addr_i          ( s_periph_addr                              ),
        .cfg_rwn_i           ( s_periph_rwn                               ),
        .cfg_valid_i         ( s_periph_valid[           PER_ID_CAM]      ),
        .cfg_data_o          ( s_periph_data_from[       PER_ID_CAM]      ),
        .cfg_ready_o         ( s_periph_ready[           PER_ID_CAM]      ),

        .cfg_rx_startaddr_o  ( s_rx_cfg_startaddr[ CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_size_o       ( s_rx_cfg_size[      CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_continuous_o ( s_rx_cfg_continuous[CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_en_o         ( s_rx_cfg_en[        CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_clr_o        ( s_rx_cfg_clr[       CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_en_i         ( s_rx_ch_en[         CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_pending_i    ( s_rx_ch_pending[    CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_curr_addr_i  ( s_rx_ch_curr_addr[  CH_ID_LIN_RX_CAM]      ),
        .cfg_rx_bytes_left_i ( s_rx_ch_bytes_left[ CH_ID_LIN_RX_CAM]      ),

        .data_rx_datasize_o  ( s_rx_ch_datasize[   CH_ID_LIN_RX_CAM]      ),
        .data_rx_data_o      ( s_rx_ch_data[       CH_ID_LIN_RX_CAM][15:0]),
        .data_rx_valid_o     ( s_rx_ch_valid[      CH_ID_LIN_RX_CAM]      ),
        .data_rx_ready_i     ( s_rx_ch_ready[      CH_ID_LIN_RX_CAM]      ),

        .cam_clk_i           ( cam_clk_i                                  ),
        .cam_data_i          ( cam_data_i                                 ),
        .cam_hsync_i         ( cam_hsync_i                                ),
        .cam_vsync_i         ( cam_vsync_i                                )
    );
    assign s_rx_ch_data[CH_ID_LIN_RX_CAM][31:16]='h0;

    // ███████╗███╗   ██╗███████╗
    // ██╔════╝████╗  ██║██╔════╝
    // ███████╗██╔██╗ ██║█████╗  
    // ╚════██║██║╚██╗██║██╔══╝  
    // ███████║██║ ╚████║███████╗
    // ╚══════╝╚═╝  ╚═══╝╚══════╝

    //--- this is not a peripheral, we simply redirect data from dvsi either to udma channel or to sne streaming port
    //--- alternatively, we can redirect a udma stream to the sne port

    logic  [31:0] cfg_dvsi_control_s;
    logic         shortcut_s  ;

    logic [ 1:0] sne_dvsi_rx_datasize_o;
    logic [31:0] sne_dvsi_rx_addr_o    ;
    logic [31:0] sne_dvsi_rx_o         ;
    logic        sne_dvsi_rx_valid_o   ;
    logic        sne_dvsi_rx_ready_i   ;   

    //--- if direct shortcut --> send dvs data to sne and silence the udma channel
    assign s_rx_ext_addr[      CH_ID_EXT_RX_DVS] = shortcut_s ? '0 : sne_dvsi_rx_addr_o              ;
    assign s_rx_ext_datasize[  CH_ID_EXT_RX_DVS] = shortcut_s ? '0 : sne_dvsi_rx_datasize_o          ;
    assign s_rx_ext_valid[     CH_ID_EXT_RX_DVS] = shortcut_s ? '0 : sne_dvsi_rx_valid_o             ;
    assign s_rx_ext_data[      CH_ID_EXT_RX_DVS] = shortcut_s ? '0 : sne_dvsi_rx_o                   ;

    //--- if direct shortcut --> take the ready from sne stream, otherwise from the udma channel ready
    assign sne_dvsi_rx_ready_i                   = shortcut_s ? sne_stream_ready_i : s_rx_ext_ready[CH_ID_EXT_RX_DVS];

    //--- if direct shortcut --> take data from the dvs, otherwise, from the udma stream (not tested)
    assign sne_stream_data_o                     = shortcut_s ?  sne_dvsi_rx_o          : s_stream_data[     STREAM_ID_SNE];
    assign sne_stream_datasize_o                 = shortcut_s ?  sne_dvsi_rx_datasize_o : s_stream_datasize[ STREAM_ID_SNE];
    assign sne_stream_valid_o                    = shortcut_s ?  sne_dvsi_rx_valid_o    : s_stream_valid[    STREAM_ID_SNE];
    assign sne_stream_sot_o                      = shortcut_s ?  1'b0                   : s_stream_sot[      STREAM_ID_SNE];
    assign sne_stream_eot_o                      = shortcut_s ?  1'b0                   : s_stream_eot[      STREAM_ID_SNE];


    // ██████╗ ██╗   ██╗███████╗      ██╗███████╗
    // ██╔══██╗██║   ██║██╔════╝      ██║██╔════╝
    // ██║  ██║██║   ██║███████╗█████╗██║█████╗  
    // ██║  ██║╚██╗ ██╔╝╚════██║╚════╝██║██╔══╝  
    // ██████╔╝ ╚████╔╝ ███████║      ██║██║     
    // ╚═════╝   ╚═══╝  ╚══════╝      ╚═╝╚═╝     

    assign s_rx_ext_destination[CH_ID_EXT_RX_DVS] = cfg_dvsi_control_s[  7:0];
    assign s_rx_ext_stream[CH_ID_EXT_RX_DVS     ] = cfg_dvsi_control_s[ 15:8];
    assign s_rx_ext_stream_id[CH_ID_EXT_RX_DVS  ] = cfg_dvsi_control_s[23:16];
    assign s_rx_ext_sot[CH_ID_EXT_RX_DVS        ] = cfg_dvsi_control_s[   24];
    assign s_rx_ext_eot[CH_ID_EXT_RX_DVS        ] = cfg_dvsi_control_s[   25];
    assign shortcut_s                             = cfg_dvsi_control_s[   26];

    logic dvsi_interrupt;

     //PER_ID:
     //DVSI = 12
     assign s_events[4*PER_ID_DVS  ]  = dvsi_interrupt;
     assign s_events[4*PER_ID_DVS+1]  = 1'b0;
     assign s_events[4*PER_ID_DVS+2]  = 1'b0;
     assign s_events[4*PER_ID_DVS+3]  = 1'b0;

     dvsi #(
         .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL), 
         .TRANS_SIZE(TRANS_SIZE),
         .DATA_WIDTH(32), //---> FIXME (check size) 
         .ADDR_WIDTH(32), //---> FIXME (check size)  
         .BUFFER_DEPTH(32)

          ) i_dvsi (
      
         .sys_clk_i          ( s_clk_periphs_core[     PER_ID_DVS] ),
         .periph_clk_i       ( s_clk_periphs_core[      PER_ID_DVS] ),
         .rst_ni             ( sys_resetn_i                        ),
         .clk_en_i           ( 1'b1                                ), //---> FIXME

         .ASA                ( dvs_asa_o                           ), 
         .ARE                ( dvs_are_o                           ), 
         .ASY                ( dvs_asy_o                           ), 
         .YNRST              ( dvs_ynrst_o                         ), 
         .YCLK               ( dvs_yclk_o                          ), 
         .SXY                ( dvs_sxy_o                           ), 
         .XCLK               ( dvs_xclk_o                          ), 
         .XNRST              ( dvs_xnrst_o                         ), 
         .ON                 ( dvs_on_i                            ), 
         .OFF                ( dvs_off_i                           ), 
         .XY_DATA            ( dvs_xy_data_i                       ),

         .CFG_IF_o           ( dvs_cfg_if_o                        ),
         .CFG_IF_i           ( dvs_cfg_if_i                        ),
         .CFG_IF_oe          ( dvs_cfg_if_oe                       ),

         .interrupt_o        ( dvsi_interrupt                      ), //---> FIXME

         //--- cfg interface
         .cfg_data_i         ( s_periph_data_to                    ), 
         .cfg_addr_i         ( s_periph_addr                       ), 
         .cfg_valid_i        ( s_periph_valid[         PER_ID_DVS] ), 
         .cfg_rwn_i          ( s_periph_rwn                        ), 
         .cfg_data_o         ( s_periph_data_from[     PER_ID_DVS] ),
         .cfg_ready_o        ( s_periph_ready[         PER_ID_DVS] ),

         //--- control/status registers
         .cfg_dvsi_control_o( cfg_dvsi_control_s                   ),

         //--- udma channel
         .data_rx_datasize_o ( sne_dvsi_rx_datasize_o              ),
         .data_rx_addr_o     ( sne_dvsi_rx_addr_o                  ),
         .data_rx_o          ( sne_dvsi_rx_o                       ),
         .data_rx_valid_o    ( sne_dvsi_rx_valid_o                 ),
         .data_rx_ready_i    ( sne_dvsi_rx_ready_i                 )  

     );

    //PER_ID 7
    assign s_events[4*PER_ID_FILTER]    = s_filter_eot_evt;
    assign s_events[4*PER_ID_FILTER+1]  = s_filter_act_evt;
    assign s_events[4*PER_ID_FILTER+2]  = 1'b0;
    assign s_events[4*PER_ID_FILTER+3]  = 1'b0;

    assign s_rx_ext_destination[CH_ID_EXT_RX_FILTER] = 'h0;
    assign s_rx_ext_stream[CH_ID_EXT_RX_FILTER]      = 'h0;
    assign s_rx_ext_stream_id[CH_ID_EXT_RX_FILTER]   = 'h0;
    assign s_rx_ext_sot[CH_ID_EXT_RX_FILTER]         = 'h0;
    assign s_rx_ext_eot[CH_ID_EXT_RX_FILTER]         = 'h0;

    assign s_tx_ext_destination[CH_ID_EXT_TX_FILTER]   = 'h0;
    assign s_tx_ext_destination[CH_ID_EXT_TX_FILTER+1] = 'h0;

    // ███████╗██╗██╗  ████████╗███████╗██████╗ 
    // ██╔════╝██║██║  ╚══██╔══╝██╔════╝██╔══██╗
    // █████╗  ██║██║     ██║   █████╗  ██████╔╝
    // ██╔══╝  ██║██║     ██║   ██╔══╝  ██╔══██╗
    // ██║     ██║███████╗██║   ███████╗██║  ██║
    // ╚═╝     ╚═╝╚══════╝╚═╝   ╚══════╝╚═╝  ╚═╝

    //PER_ID:
    //FILTER = 13
    udma_filter #(
        .L2_AWIDTH_NOAL(L2_AWIDTH_NOAL),
        .TRANS_SIZE(TRANS_SIZE)
    ) i_filter (
        .clk_i(s_clk_periphs_core[PER_ID_FILTER]),
        .resetn_i(sys_resetn_i),

        .cfg_data_i               ( s_periph_data_to                         ),
        .cfg_addr_i               ( s_periph_addr                            ),
        .cfg_valid_i              ( s_periph_valid[           PER_ID_FILTER] ),
        .cfg_rwn_i                ( s_periph_rwn                             ),
        .cfg_data_o               ( s_periph_data_from[       PER_ID_FILTER] ),
        .cfg_ready_o              ( s_periph_ready[           PER_ID_FILTER] ),

        .eot_event_o              ( s_filter_eot_evt                         ),
        .act_event_o              ( s_filter_act_evt                         ),

        .filter_tx_ch0_req_o      ( s_tx_ext_req[       CH_ID_EXT_TX_FILTER] ),
        .filter_tx_ch0_addr_o     ( s_tx_ext_addr[      CH_ID_EXT_TX_FILTER] ),
        .filter_tx_ch0_datasize_o ( s_tx_ext_datasize[  CH_ID_EXT_TX_FILTER] ),
        .filter_tx_ch0_gnt_i      ( s_tx_ext_gnt[       CH_ID_EXT_TX_FILTER] ),

        .filter_tx_ch0_valid_i    ( s_tx_ext_valid[     CH_ID_EXT_TX_FILTER] ),
        .filter_tx_ch0_data_i     ( s_tx_ext_data[      CH_ID_EXT_TX_FILTER] ),
        .filter_tx_ch0_ready_o    ( s_tx_ext_ready[     CH_ID_EXT_TX_FILTER] ),

        .filter_tx_ch1_req_o      ( s_tx_ext_req[     CH_ID_EXT_TX_FILTER+1] ),
        .filter_tx_ch1_addr_o     ( s_tx_ext_addr[    CH_ID_EXT_TX_FILTER+1] ),
        .filter_tx_ch1_datasize_o ( s_tx_ext_datasize[CH_ID_EXT_TX_FILTER+1] ),
        .filter_tx_ch1_gnt_i      ( s_tx_ext_gnt[     CH_ID_EXT_TX_FILTER+1] ),

        .filter_tx_ch1_valid_i    ( s_tx_ext_valid[   CH_ID_EXT_TX_FILTER+1] ),
        .filter_tx_ch1_data_i     ( s_tx_ext_data[    CH_ID_EXT_TX_FILTER+1] ),
        .filter_tx_ch1_ready_o    ( s_tx_ext_ready[   CH_ID_EXT_TX_FILTER+1] ),

        .filter_rx_ch_addr_o      ( s_rx_ext_addr[      CH_ID_EXT_RX_FILTER] ),
        .filter_rx_ch_datasize_o  ( s_rx_ext_datasize[  CH_ID_EXT_RX_FILTER] ),
        .filter_rx_ch_valid_o     ( s_rx_ext_valid[     CH_ID_EXT_RX_FILTER] ),
        .filter_rx_ch_data_o      ( s_rx_ext_data[      CH_ID_EXT_RX_FILTER] ),
        .filter_rx_ch_ready_i     ( s_rx_ext_ready[     CH_ID_EXT_RX_FILTER] ),

        .filter_id_i              (  ),
        .filter_data_i            ( s_stream_data[         STREAM_ID_FILTER] ),
        .filter_datasize_i        ( s_stream_datasize[     STREAM_ID_FILTER] ),
        .filter_valid_i           ( s_stream_valid[        STREAM_ID_FILTER] ),
        .filter_sof_i             ( s_stream_sot[          STREAM_ID_FILTER] ),
        .filter_eof_i             ( s_stream_eot[          STREAM_ID_FILTER] ),
        .filter_ready_o           ( s_stream_ready[        STREAM_ID_FILTER] )
    );

    //--- silence unused events
    generate
        genvar e;
        //--- we are starting from the first event after the last peripheral (FILTER*4 + 4)
        for (e = PER_ID_FILTER*4 + 4; e < 128; e++) begin
            assign s_events[e]  = 1'b0;
        end
    endgenerate

    */

endmodule
