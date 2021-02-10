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
    // ██╗   ██╗ █████╗ ██████╗ ████████╗
    // ██║   ██║██╔══██╗██╔══██╗╚══██╔══╝
    // ██║   ██║███████║██████╔╝   ██║   
    // ██║   ██║██╔══██║██╔══██╗   ██║   
    // ╚██████╔╝██║  ██║██║  ██║   ██║   
    //  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    

    BIPAD_IF.PERIPH_SIDE PAD_UART_RX[N_UART-1:0],
    BIPAD_IF.PERIPH_SIDE PAD_UART_TX[N_UART-1:0]
                                    
);

    logic [        N_STREAMS-1:0]               [31 : 0] s_stream_data        ;
    logic [        N_STREAMS-1:0]                [1 : 0] s_stream_datasize    ;
    logic [        N_STREAMS-1:0]                        s_stream_valid       ;
    logic [        N_STREAMS-1:0]                        s_stream_sot         ;
    logic [        N_STREAMS-1:0]                        s_stream_eot         ;
    logic [        N_STREAMS-1:0]                        s_stream_ready       ;

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
    logic            [  N_I2C-1:0] s_i2c_evt;

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

    udma_evt_t [N_UART-1:0] s_evt_uart;

    for (genvar g_uart=0;g_uart<1;g_uart++) begin: uart

        udma_uart_wrap i_udma_uart_wrap (

            .sys_clk_i   ( s_clk_periphs_core[ g_uart ] ),
            .periph_clk_i( s_clk_periphs_per[  g_uart ] ),
            .rstn_i      ( sys_resetn_i                 ),
            .cfg_data_i  ( s_periph_data_to             ),
            .cfg_addr_i  ( s_periph_addr                ),
            .cfg_valid_i ( s_periph_valid[g_uart ]      ),
            .cfg_rwn_i   ( s_periph_rwn                 ),
            .cfg_ready_o ( s_periph_ready[g_uart ]      ),
            .cfg_data_o  ( s_periph_data_from[g_uart ]  ),
            .events_o    ( s_evt_uart[g_uart]           ), 

            .rx_ch       ( lin_ch_rx[g_uart:g_uart]     ),
            .tx_ch       ( lin_ch_tx[g_uart:g_uart]     ),
            .PAD_UART_RX ( PAD_UART_RX[g_uart]          ),
            .PAD_UART_TX ( PAD_UART_TX[g_uart]          )

        );

        // bind uart events
        assign s_events[g_uart] = s_evt_uart[g_uart];
    end: uart

    // pad unused events
    for (genvar i = N_PERIPHS; i < 32; i++) begin
        assign s_events[i] = 4'b0000;
    end

    // assign output events
    assign events_o      = s_events;

endmodule
