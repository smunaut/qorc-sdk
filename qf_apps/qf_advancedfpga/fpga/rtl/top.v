`default_nettype none

module top #(
	parameter [15:0] DEV_ID = 16'hbabe
)(
	// USB
	inout  wire usb_dp,
	inout  wire usb_dn,
	inout  wire usb_pu_fs,
	inout  wire usb_pu_ls,

	// LEDs
	output wire led_r_o,
	output wire led_g_o,
	output wire led_b_o
);

	// Signals
	// -------

	// Wishbone bus
	wire [16:0] wb_addr;
	wire [31:0] wb_rdata;
	wire [31:0] wb_wdata;
	wire [ 3:0] wb_wstb;
	wire        wb_we;
	wire        wb_re;
	wire        wb_cyc;
	wire        wb_stb;
	wire        wb_ack;
	wire        wb_rst;

	// USB wb bus
	wire [11:0] usb_addr;
	wire [15:0] usb_wdata;
	wire [15:0] usb_rdata;
	wire        usb_cyc;
	wire        usb_we;
	wire        usb_ack;

	// MicroCode write
	wire [ 7:0] uc_addr;
	wire [15:0] uc_data;
	wire        uc_we;

	// USB EP buffer interface
	wire [ 8:0] ep_tx_addr;
	wire [31:0] ep_tx_data;
	wire        ep_tx_we;

	wire [ 8:0] ep_rx_addr;
	wire [31:0] ep_rx_data;
	wire        ep_rx_re;


	wire sys_int = 1'b0;

	// Clock / Reset
	wire sys_clk0;
	wire sys_clk0_rst;
	wire sys_clk1;
	wire sys_clk1_rst;

	wire rst_wb_a;
	reg  rst_wb_i;
	reg  rst_usb_i;

	wire clk_wb;
	wire rst_wb;

	wire rst_usb;
	wire clk_usb;


	// Dummy USB output
	// ----------------

//	bipad usb0_I ( .A(1'b0), .EN(1'b0), .Q(), .P(usb_dp) );
//	bipad usb1_I ( .A(1'b0), .EN(1'b0), .Q(), .P(usb_dn) );
//	bipad usb2_I ( .A(1'b0), .EN(1'b0), .Q(), .P(usb_pu_fs) );
//	bipad usb3_I ( .A(1'b0), .EN(1'b0), .Q(), .P(usb_pu_ls) );



	// LED debug
	// ---------

	reg [3:0] cnt_wb;
	always @(posedge clk_wb)
		if (rst_wb)
			cnt_wb <= 0;
		else
			cnt_wb <= cnt_wb + 1;

	reg [3:0] cnt_usb;
	always @(posedge clk_usb)
		if (rst_usb)
			cnt_usb <= 0;
		else
			cnt_usb <= cnt_usb + 1;

	assign led_r_o = cnt_wb  == 4'hf;
	assign led_g_o = cnt_usb == 4'hf;
	assign led_b_o = ram_we;


	wire [10:0] ram_raddr;
	wire [10:0] ram_waddr;
	wire [ 7:0] ram_rdata;
	wire [ 7:0] ram_wdata;
	wire        ram_we;

	reg a;

	always @(posedge clk_usb)
		a <= usb_cyc & ~a;

	assign usb_rdata = { 8'h00, ram_rdata };
	assign usb_ack = a;

//`define USB
`ifdef USB
	assign ram_raddr = usb_addr;
	assign ram_waddr = usb_addr;
	assign ram_wdata = usb_wdata[7:0];
	assign ram_we = usb_cyc & usb_we & ~usb_ack;
`else

	reg [6:0] cnt_0;
	reg [6:0] cnt_1;

	always @(posedge clk_usb)
		if (rst_usb) begin
			cnt_0 <= 0;
			cnt_1 <= 0;
		end else begin
			cnt_0 <= cnt_0 + 1;
			cnt_1 <= cnt_0;
		end

	assign ram_raddr = { 5'b00000, cnt_0[5:0] };
	assign ram_waddr = { 5'b00000, cnt_1[5:0] };
	assign ram_wdata = { cnt_1[3:0], ram_rdata[3:0] };
	assign ram_we    = cnt_1[6];
`endif

	usb_ep_buf #(
		.RWIDTH(8),
		.WWIDTH(32)
	) buf_tx (
		.rd_addr_0 (ram_raddr),
		.rd_data_1 (ram_rdata),
		.rd_en_0   (1'b1),
		.rd_clk    (clk_usb),
		.wr_addr_0 (ep_tx_addr),
		.wr_data_0 (ep_tx_data),
		.wr_en_0   (ep_tx_we),
		.wr_clk    (clk_wb)
	);

	usb_ep_buf #(
		.RWIDTH(32),
		.WWIDTH(8)
	) buf_rx (
		.rd_addr_0 (ep_rx_addr),
		.rd_data_1 (ep_rx_data),
		.rd_en_0   (ep_rx_re),
		.rd_clk    (clk_wb),
		.wr_addr_0 (ram_waddr),
		.wr_data_0 (ram_wdata),
		.wr_en_0   (ram_we),
		.wr_clk    (clk_usb)
	);


	// Bridge
	// ------

	bridge bridge_I (
		.wb_addr    (wb_addr),
		.wb_rdata   (wb_rdata),
		.wb_wdata   (wb_wdata),
		.wb_wstb    (wb_wstb),
		.wb_we      (wb_we),
		.wb_re      (wb_re),
		.wb_cyc     (wb_cyc),
		.wb_stb     (wb_stb),
		.wb_ack     (wb_ack),
		.usb_addr   (usb_addr),
		.usb_wdata  (usb_wdata),
		.usb_rdata  (usb_rdata),
		.usb_cyc    (usb_cyc),
		.usb_we     (usb_we),
		.usb_ack    (usb_ack),
		.usb_clk    (clk_usb),
		.usb_rst    (rst_usb),
		.uc_addr    (uc_addr),
		.uc_data    (uc_data),
		.uc_we      (uc_we),
		.ep_tx_addr (ep_tx_addr),
		.ep_tx_data (ep_tx_data),
		.ep_tx_we   (ep_tx_we),
		.ep_rx_addr (ep_rx_addr),
		.ep_rx_data (ep_rx_data),
		.ep_rx_re   (ep_rx_re),
		.clk        (clk_wb),
		.rst        (rst_wb)
	);



	// Internal interface
	// ------------------

	qlal4s3b_cell_macro if_I (
		// AHB-To-FPGA Bridge
		.WBs_ADR         ( wb_addr             ), // output [16:0] | Address Bus                to   FPGA
		.WBs_CYC         ( wb_cyc              ), // output        | Cycle Chip Select          to   FPGA
		.WBs_BYTE_STB    ( wb_wstb             ), // output  [3:0] | Byte Select                to   FPGA
		.WBs_WE          ( wb_we               ), // output        | Write Enable               to   FPGA
		.WBs_RD          ( wb_re               ), // output        | Read  Enable               to   FPGA
		.WBs_STB         ( wb_stb              ), // output        | Strobe Signal              to   FPGA
		.WBs_WR_DAT      ( wb_wdata            ), // output [31:0] | Write Data Bus             to   FPGA
		.WB_CLK          ( clk_wb              ), // input         | FPGA Clock                 from FPGA
		.WB_RST          ( wb_rst              ), // output        | FPGA Reset                 to   FPGA
		.WBs_RD_DAT      ( wb_rdata            ), // input  [31:0] | Read Data Bus              from FPGA
		.WBs_ACK         ( wb_ack              ), // input         | Transfer Cycle Acknowledge from FPGA

		// SDMA Signals
		.SDMA_Req        (4'b0000              ), // input   [3:0]
		.SDMA_Sreq       (4'b0000              ), // input   [3:0]
		.SDMA_Done       (                     ), // output  [3:0]
		.SDMA_Active     (                     ), // output  [3:0]

		// FB Interrupts
		.FB_msg_out      ( {3'b000, sys_int}   ), // input   [3:0]
		.FB_Int_Clr      (  8'h0               ), // input   [7:0]
		.FB_Start        (                     ), // output
		.FB_Busy         (  1'b0               ), // input

		// FB Clocks
		.Sys_Clk0        ( sys_clk0            ), // output (clk 16)
		.Sys_Clk0_Rst    ( sys_clk0_rst        ), // output
		.Sys_Clk1        ( sys_clk1            ), // output (clk 21)
		.Sys_Clk1_Rst    ( sys_clk1_rst        ), // output

		// Packet FIFO
		.Sys_PKfb_Clk    (  1'b0               ), // input
		.Sys_PKfb_Rst    (                     ), // output
		.FB_PKfbData     ( 32'h0               ), // input  [31:0]
		.FB_PKfbPush     (  4'h0               ), // input   [3:0]
		.FB_PKfbSOF      (  1'b0               ), // input
		.FB_PKfbEOF      (  1'b0               ), // input
		.FB_PKfbOverflow (                     ), // output

		// Sensor Interface
		.Sensor_Int      (                     ), // output  [7:0]
		.TimeStamp       (                     ), // output [23:0]

		// SPI Master APB Bus
		.Sys_Pclk        (                     ), // output
		.Sys_Pclk_Rst    (                     ), // output      <-- Fixed to add "_Rst"
		.Sys_PSel        (  1'b0               ), // input
		.SPIm_Paddr      ( 16'h0               ), // input  [15:0]
		.SPIm_PEnable    (  1'b0               ), // input
		.SPIm_PWrite     (  1'b0               ), // input
		.SPIm_PWdata     ( 32'h0               ), // input  [31:0]
		.SPIm_Prdata     (                     ), // output [31:0]
		.SPIm_PReady     (                     ), // output
		.SPIm_PSlvErr    (                     ), // output

		// Misc
		.Device_ID       ( DEV_ID              ), // input  [15:0]

		// FBIO Signals
		.FBIO_In         (                     ), // output [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
		.FBIO_In_En      (                     ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
		.FBIO_Out        (                     ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO
		.FBIO_Out_En     (                     ), // input  [13:0] <-- Do Not make any connections; Use Constraint manager in SpDE to sFBIO

		// ???
		.SFBIO           (                     ), // inout  [13:0]
		.Device_ID_6S    ( 1'b0                ), // input
		.Device_ID_4S    ( 1'b0                ), // input
		.SPIm_PWdata_26S ( 1'b0                ), // input
		.SPIm_PWdata_24S ( 1'b0                ), // input
		.SPIm_PWdata_14S ( 1'b0                ), // input
		.SPIm_PWdata_11S ( 1'b0                ), // input
		.SPIm_PWdata_0S  ( 1'b0                ), // input
		.SPIm_Paddr_8S   ( 1'b0                ), // input
		.SPIm_Paddr_6S   ( 1'b0                ), // input
		.FB_PKfbPush_1S  ( 1'b0                ), // input
		.FB_PKfbData_31S ( 1'b0                ), // input
		.FB_PKfbData_21S ( 1'b0                ), // input
		.FB_PKfbData_19S ( 1'b0                ), // input
		.FB_PKfbData_9S  ( 1'b0                ), // input
		.FB_PKfbData_6S  ( 1'b0                ), // input
		.Sys_PKfb_ClkS   ( 1'b0                ), // input
		.FB_BusyS        ( 1'b0                ), // input
		.WB_CLKS         ( 1'b0                )  // input
	);


	// Clock / Reset
	// -------------

	// Reset synchronizers
	assign rst_wb_a = sys_clk0_rst | wb_rst;

	always @(posedge clk_wb or posedge rst_wb_a)
		if (rst_wb_a)
			rst_wb_i <= 1'b1;
		else
			rst_wb_i <= 1'b0;

	always @(posedge clk_usb or posedge sys_clk1_rst)
		if (sys_clk1_rst)
			rst_usb_i <= 1'b1;
		else
			rst_usb_i <= 1'b0;

	// Global Buffers
	gclkbuff gbuf_clk_wb  ( .A(sys_clk0),  .Z(clk_wb) );
	gclkbuff gbuf_rst_wb  ( .A(rst_wb_i),  .Z(rst_wb) );

	gclkbuff gbuf_clk_usb ( .A(sys_clk1),  .Z(clk_usb) );
	gclkbuff gbuf_rst_usb ( .A(rst_usb_i), .Z(rst_usb) );

endmodule
