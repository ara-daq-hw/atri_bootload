module atri_bootload(
				// not actually 250 MHz
				input PCIE_250M_N,
				input PCIE_250M_P,
				input PCIE_PERST_B_LS,
				input PCIE_RX0_N,
				input PCIE_RX0_P,
				output PCIE_TX0_N,
				output PCIE_TX0_P,
				// CCLK is a valid GPIO after configuration in S6
				output F_SPI_SCK,
				output F_SPI_MOSI,
				input F_SPI_MISO,
				output F_SPI_CS_B,
				// these are the extra two for x4 mode
				output F_SPI_DQ2_W_B,
				output F_SPI_DQ3_RESET_B,
				// what the ever
				output [4:0] MON
		     );

	wire clk;

      
   // literally all we have is the Xillybus core. every time
   // we receive 8 bits, we clock it out and put the received
   // 8 bits in the outbound side.

   // to handle the chip-select line, we just lower it
   // when we open, and close it when we're closed.
   // yes this is a pain in the neck from a software
   // perspective BUT WHO ACTUALLY CARES

   wire quiesce;   

	// okay doing this without a FIFO is a mess to debug
	//	so fine, whatever
	// this is the side going to xillybus
	wire user_spiin_full;
	wire [7:0] user_spiin_data;
	wire user_spiin_wren;

   wire spi_in_open;   

	// this is the side going to logic
	wire		  spi_in_read;
   wire [7:0] spi_in_data;
   wire       spi_in_valid;

	xilly_infifo u_infifo(.clk(clk),
								 .srst(!spi_in_open),
								 .din(user_spiin_data),
								 .wr_en(user_spiin_wren),
								 .full(user_spiin_full),
								 .dout(spi_in_data),
								 .valid(spi_in_valid),
								 .rd_en(spi_in_read));
	// outbound still wants a FIFO just to make debugging
	// easy.
	
	// this side heads to Xillybus
	wire [7:0] user_spiout_data;
	wire 		  user_spiout_empty;
	wire		  user_spiout_rden;

	wire      spi_out_open;

	// this side heads to logic
	// yes this is stupidly named, it's OUR input register
	// and the data goes OUT to Xilly
   reg [7:0] spi_in_reg = {8{1'b0}};
	wire		 spi_out_write;
	wire		 spi_out_full;
	
	xilly_outfifo u_outfifo(.clk(clk),
									.srst(!spi_out_open),
									.din(spi_in_reg),
									.wr_en(spi_out_write),
									.full(spi_out_full),
									.dout(user_spiout_data),
									.rd_en(user_spiout_rden),
									.empty(user_spiout_empty));
	
   reg 	spi_cs = 0;
   (* IOB = "TRUE" *)
   reg  spi_miso = 0;
   (* IOB = "TRUE" *)
   reg spi_mosi = 0;
	(* IOB = "TRUE" *)
   reg spi_cclk = 0;   
	
	(* KEEP = "TRUE" *)
	reg spi_mosi_debug = 0;
	(* KEEP = "TRUE" *)
	reg spi_cclk_debug = 0;
	(* KEEP = "TRUE" *)
	reg spi_cs_debug = 0;
	
	// yes this is stupidly named, it's OUR output register
	// it comes IN from xilly
   reg [7:0] spi_out_reg = {8{1'b0}};
	      
   // nominally PCIe is 125M, I think,
   // so let's try running SPI at 12.5M
   localparam SPI_COUNT_MAX = 9;
   reg [7:0] spi_clk_counter = {8{1'b0}};

   reg [3:0] spi_bit_counter = {4{1'b0}};   
   
   localparam FSM_BITS = 4;
   localparam [FSM_BITS-1:0] IDLE = 0;
   localparam [FSM_BITS-1:0] ACCEPT = 1;
   localparam [FSM_BITS-1:0] CLK_LOW = 2;
   localparam [FSM_BITS-1:0] CLK_HIGH = 3;
   localparam [FSM_BITS-1:0] FINISH = 4;
   reg [FSM_BITS-1:0] state = IDLE;
   

   xillybus u_xillybus(
		       .PCIE_TX0_P(PCIE_TX0_P),
				 .PCIE_TX0_N(PCIE_TX0_N),
				 .PCIE_RX0_P(PCIE_RX0_P),
				 .PCIE_RX0_N(PCIE_RX0_N),
				 .PCIE_250M_P(PCIE_250M_P),
				 .PCIE_250M_N(PCIE_250M_N),
				 .PCIE_PERST_B_LS(PCIE_PERST_B_LS),
				 // spi from CPU (in to FPGA)
				 .user_w_spi_in_full(user_spiin_full),
				 .user_w_spi_in_wren(user_spiin_wren),
				 .user_w_spi_in_data(user_spiin_data),
				 .user_w_spi_in_open(spi_in_open),
				 // spi to CPU
				 .user_r_spi_out_empty(user_spiout_empty),
				 .user_r_spi_out_rden(user_spiout_rden),
				 .user_r_spi_out_data(user_spiout_data),
				 .user_r_spi_out_open(spi_out_open),
				 .user_r_spi_out_eof(1'b0),
				 // bus clk
				 .bus_clk(clk),
				 .quiesce(quiesce));
		       
   
	assign spi_in_read = spi_in_valid && (state == ACCEPT);
	assign spi_out_write = !spi_out_full && (state == FINISH); 
	
   always @(posedge clk) begin
      spi_cs <= spi_in_open && spi_out_open;
		spi_cs_debug <= spi_in_open && spi_out_open;
		
      if (state == CLK_LOW || state == CLK_HIGH) begin
			if (spi_clk_counter == SPI_COUNT_MAX)
				spi_clk_counter <= {8{1'b0}};
			else spi_clk_counter <= spi_clk_counter + 1;
      end else begin
			spi_clk_counter <= {8{1'b0}};
      end

      if (state == ACCEPT && spi_in_valid) 
			spi_out_reg <= spi_in_data;
      else if (state == CLK_HIGH && spi_clk_counter == SPI_COUNT_MAX)
			spi_out_reg <= {spi_out_reg[6:0],1'b0};

      spi_mosi <= spi_out_reg[7];      
		spi_mosi_debug <= spi_out_reg[7];
      spi_miso <= F_SPI_MISO;
      
      // data actually changes at clock low so this is fine
      if (state == CLK_HIGH && spi_clk_counter == 0)
			spi_in_reg <= { spi_in_reg[6:0], spi_miso };
      
      spi_cclk <= (state == CLK_HIGH);
		spi_cclk_debug <= (state == CLK_HIGH);
		
      if (quiesce || !spi_cs) state <= IDLE;
      else begin
			case (state)
				IDLE: if (spi_cs) state <= ACCEPT;
				ACCEPT: if (spi_in_valid) state <= CLK_LOW;
				CLK_LOW: if (spi_bit_counter == 8) state <= FINISH;
							else if (spi_clk_counter == SPI_COUNT_MAX) state <= CLK_HIGH;
				CLK_HIGH: if (spi_clk_counter == SPI_COUNT_MAX) state <= CLK_LOW;
				FINISH: if (!spi_out_full) state <= IDLE;
			endcase // case (state)	 
      end

		// overall sequence is (set SPI_MAX to 1 or something)
		// clk	state		bit_counter		clk
		//	0		ACCEPT	X					0
		// 1     CLK_LOW	0					0
		// 2		CLK_LOW	0					0
		//	3		CLK_HIGH	1					0
		// 3		CLK_HIGH	1					1	edge 1
		// 4     CLK_LOW	1					1
		//	5		CLK_LOW	1					0
		// 6		CLK_HIGH	2					0
		// 7		CLK_HIGH 2					1	edge 2
		// 8 		CLK_LOW	2					1
		// 9 		CLK_LOW	2					0
		// 10		CLK_HIGH	3					0
		// 11		CLK_HIGH	3					1	edge 3
		// 12		CLK_LOW	3					1
		// 13		CLK_LOW	3					0
		// 14		CLK_HIGH	4					0
		// 14		CLK_HIGH	4					1	edge 4
		// 15		CLK_LOW	4					1
		// 16 	CLK_LOW	4					0
		// 17		CLK_HIGH	5					0
		// 18		CLK_HIGH	5					1  edge 5
		// 19		CLK_LOW	5					1
		// 20		CLK_LOW	5					0
		// 21		CLK_HIGH	6					0
		// 22		CLK_HIGH 6					1	edge 6
		// 23		CLK_LOW	6					1
		// 24		CLK_LOW	6					0
		// 25		CLK_HIGH	7					0
		// 26		CLK_HIGH	7					1	edge 7
		// 27		CLK_LOW	7					1
		// 28		CLK_LOW	7					0
		// 29		CLK_HIGH	8					0
		// 30		CLK_HIGH	8					1	edge 8
		// 31		CLK_LOW	8					1
		// 32		FINISH	8					0
		// 33		IDLE		8					0
		// 34		ACCEPT	8					0
		// 35		CLK_LOW	0
		// so you can see we need to exit at 8 not 7
		if (state == ACCEPT) 
			spi_bit_counter <= {4{1'b0}};
		else if (state == CLK_LOW && spi_clk_counter == SPI_COUNT_MAX)
			spi_bit_counter <= spi_bit_counter + 1;
   end

	wire [35:0] ila_to_icon;
	chipscope_icon u_icon(.CONTROL0(ila_to_icon));
	chipscope_ila u_ila(.CONTROL(ila_to_icon),
							  .CLK(clk),
							  .TRIG0(spi_in_data),
							  .TRIG1(spi_in_read),
							  .TRIG2(spi_out_reg),
							  .TRIG3(spi_out_write),
							  .TRIG4(state),
							  .TRIG5(spi_cs_debug),
							  .TRIG6(spi_cclk_debug),
							  .TRIG7(spi_mosi_debug),
							  .TRIG8(spi_miso));

	assign MON[4] = !quiesce;
	assign MON[3] = spi_in_open;
	assign MON[2] = spi_out_open;
	assign MON[1] = spi_miso;
	assign MON[0] = spi_cclk_debug;

   assign F_SPI_MOSI = spi_mosi;
   assign F_SPI_CS_B = !spi_cs; 
   assign F_SPI_SCK = spi_cclk;

	assign F_SPI_DQ2_W_B = 1'b1;
	assign F_SPI_DQ3_RESET_B = 1'b1;
endmodule // atri_bootload
