`define REG_TX_SADDR     5'b00100 //BASEADDR+0x10
`define REG_TX_SIZE      5'b00101 //BASEADDR+0x14
`define REG_TX_CFG       5'b00110 //BASEADDR+0x18
`define REG_TX_INTCFG    5'b00111 //BASEADDR+0x1C

`define REG_STATUS       5'b01000 //BASEADDR+0x20
`define REG_TGEN_SETUP   5'b01001 //BASEADDR+0x24

module tgen_tx_lin (

	    input  logic         sys_clk_i,
	    input  logic         periph_clk_i,
		input  logic         rstn_i,

		input  logic  [31:0] cfg_data_i,
		input  logic   [4:0] cfg_addr_i,
		input  logic         cfg_valid_i,
		input  logic         cfg_rwn_i,
		output logic         cfg_ready_o,
	    output logic  [31:0] cfg_data_o,

	    output logic  [3:0]  events_o,

	    // UDMA CHANNEL CONNECTION
	    UDMA_LIN_CH.tx_in    tx_ch,

	    // PAD SIGNALS CONNECTION
		BIPAD_IF.PERIPH_SIDE PAD_DATA0,
		BIPAD_IF.PERIPH_SIDE PAD_DATA1,
		BIPAD_IF.PERIPH_SIDE PAD_DATA2,
		BIPAD_IF.PERIPH_SIDE PAD_DATA3,
		BIPAD_IF.PERIPH_SIDE PAD_CLK,
		BIPAD_IF.PERIPH_SIDE PAD_WRD

	);

	import udma_pkg::TRANS_SIZE;     
	import udma_pkg::L2_AWIDTH_NOAL; 

    logic                [4:0] s_rd_addr;
    logic                [4:0] s_wr_addr;
    
    // default configuation registers
    logic [L2_AWIDTH_NOAL-1:0] r_tx_startaddr;
    logic   [TRANS_SIZE-1 : 0] r_tx_size;
    logic                      r_tx_continuous;
    logic                      r_tx_en;
    logic                      r_tx_clr;

    // user defined registers
    logic               [31:0] r_tgen_setup;
    logic               [31:0] r_tgen_status; 

    //------------------------------------------------------------------------------- peripheral instance

    logic               [31:0] s_pre_cdc_data;
    logic                      s_pre_cdc_valid;
    logic                      s_pre_cdc_ready;

    logic           [7:0][3:0] s_post_cdc_data;
    logic                      s_post_cdc_valid;
    logic                      s_post_cdc_ready;

    // generic fifo to pre-fetch data from L2
    io_tx_fifo #(
      .DATA_WIDTH(32),
      .BUFFER_DEPTH(2)
      ) u_fifo (
        .clk_i        ( sys_clk_i          ),
        .rstn_i       ( rstn_i             ),
        .clr_i        ( 1'b0               ),
     
        .valid_i      ( tx_ch.valid        ),
        .data_i       ( tx_ch.data         ),
        .ready_o      ( tx_ch.ready        ),
     
        .req_o        ( tx_ch.req          ),
        .gnt_i        ( tx_ch.gnt          ),
     
        .data_o       ( s_pre_cdc_data     ),
        .valid_o      ( s_pre_cdc_valid    ),
        .ready_i      ( s_pre_cdc_ready    )

    );

    // CDC
    udma_dc_fifo #(32,4) u_dc_fifo_tx
    (
        .src_clk_i    ( sys_clk_i          ),  
        .src_rstn_i   ( rstn_i             ),  
        .src_data_i   ( s_pre_cdc_data     ),
        .src_valid_i  ( s_pre_cdc_valid    ),
        .src_ready_o  ( s_pre_cdc_ready    ),

        .dst_clk_i    ( periph_clk_i       ),
        .dst_rstn_i   ( rstn_i             ),
        .dst_data_o   ( s_post_cdc_data    ),
        .dst_valid_o  ( s_post_cdc_valid   ),
        .dst_ready_i  ( s_post_cdc_ready   )
    );

    logic tx_done;
    logic tx_phase;

    enum logic [1:0] {
    	RESET,
    	TX,
    	DONE
    }PS, NS;

    always_ff @(posedge periph_clk_i or negedge rstn_i) begin : proc_PS
    	if(~rstn_i) begin
    		PS <= RESET;
    	end else begin
    		PS <= NS;
    	end
    end

    always_comb begin : proc_NS
    	case (PS)
    		RESET : begin
    			if (tx_ch.en && s_post_cdc_valid) begin
    				NS = TX;
    			end else begin
    				NS = RESET;
    			end
    		end

    		TX    : begin
    			if (tx_done) begin
    				NS = DONE;
    			end else begin
    				NS = TX;
    			end
    		end

    		DONE  : begin
    			NS = RESET;
    		end

    		default : begin
    			NS = RESET;
    		end
    	endcase
    end

    always_comb begin : proc_OUT
    	case (PS)
    		RESET : begin
    			s_post_cdc_ready = 1'b0;
    			tx_phase         = 1'b0;
    		end

    		TX    : begin
    			s_post_cdc_ready = 1'b0;
    			tx_phase         = 1'b1;
    		end

    		DONE  : begin
    			s_post_cdc_ready = 1'b1;
    			tx_phase         = 1'b0;
    		end

    		default : begin
    			s_post_cdc_ready = 1'b0;
    			tx_phase         = 1'b0;
    		end
    	endcase
    end

    logic [1:0] r_cnt;

    assign tx_done = (r_cnt == 0);

    always_ff @(posedge periph_clk_i or negedge rstn_i) begin : proc_cnt
    	if(~rstn_i) begin
    		r_cnt <= 3;
    	end else if (tx_phase) begin
    		r_cnt <= r_cnt - 1'b1;
    	end
    end

	always_ff @(posedge periph_clk_i or negedge rstn_i) begin : proc_TX
		if(~rstn_i) begin
			PAD_DATA0.OUT <= 1'b0;
			PAD_DATA1.OUT <= 1'b0;
			PAD_DATA2.OUT <= 1'b0;
			PAD_DATA3.OUT <= 1'b0;
			PAD_DATA0.OE <= 1'b0;
			PAD_DATA1.OE <= 1'b0;
			PAD_DATA2.OE <= 1'b0;
			PAD_DATA3.OE <= 1'b0;
		end else begin
			PAD_DATA0.OUT <= s_post_cdc_data[r_cnt][0];
			PAD_DATA1.OUT <= s_post_cdc_data[r_cnt][1];
			PAD_DATA2.OUT <= s_post_cdc_data[r_cnt][2];
			PAD_DATA3.OUT <= s_post_cdc_data[r_cnt][3];
			PAD_DATA0.OE <= 1'b1;
			PAD_DATA1.OE <= 1'b1;
			PAD_DATA2.OE <= 1'b1;
			PAD_DATA3.OE <= 1'b1;
		end
	end


    // drive unused signals
    assign tx_ch.destination = 'h0;

    //------------------------------------------------------------------------------- peripheral configuration registers

    // check if a read or a write access
    assign s_wr_addr = (cfg_valid_i & ~cfg_rwn_i) ? cfg_addr_i : 5'h0;
    assign s_rd_addr = (cfg_valid_i &  cfg_rwn_i) ? cfg_addr_i : 5'h0;

    // expose channel configutation to the udma core
    assign tx_ch.startaddr   = r_tx_startaddr;
    assign tx_ch.size        = r_tx_size;
    assign tx_ch.continuous  = r_tx_continuous;
    assign tx_ch.cen         = r_tx_en;


    // register read write logic
    always_ff @(posedge sys_clk_i, negedge rstn_i) begin
        if(~rstn_i) begin
            r_tx_startaddr     <=  'h0;
            r_tx_size          <=  'h0;
            r_tx_continuous    <=  'h0;
            r_tx_en            <=  'h0;
            r_tx_clr           <=  'h0;
        end else begin 
            if (cfg_valid_i & ~cfg_rwn_i) begin
                case (s_wr_addr)

                	// default register set (linear tx channel)
	                `REG_TX_SADDR:
	                    r_tx_startaddr       <= cfg_data_i[L2_AWIDTH_NOAL-1:0];
	                `REG_TX_SIZE:
	                    r_tx_size            <= cfg_data_i[TRANS_SIZE-1:0];
	                `REG_TX_CFG: begin
	                    r_tx_clr             <= cfg_data_i[6];
	                    r_tx_en              <= cfg_data_i[4];
	                    r_tx_continuous      <= cfg_data_i[0];
	                end
	                // user reg
	                `REG_TGEN_SETUP: begin
	                    r_tgen_setup         <= cfg_data_i;
	                end
                endcase
            end
        end
    end 

    always_comb begin

        case (s_rd_addr)
	        `REG_TX_SADDR:
	            cfg_data_o = tx_ch.curr_addr;
	        `REG_TX_SIZE:
	            cfg_data_o[TRANS_SIZE-1:0] = tx_ch.bytes_left;
	        `REG_TX_CFG:
	            cfg_data_o = {26'h0,tx_ch.pending,tx_ch.en,3'h0,r_tx_continuous};
	        // user regs
	        `REG_TGEN_SETUP:
	            cfg_data_o = r_tgen_setup;
	        `REG_STATUS:
	            cfg_data_o = r_tgen_status;
	        default: 
	            cfg_data_o = 32'h0;
        endcase // s_rd_addr
    end

    assign cfg_ready_o  = 1'b1;

endmodule