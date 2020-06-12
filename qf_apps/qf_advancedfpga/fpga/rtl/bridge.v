`default_nettype none

module bridge (
	// Wishbone bus
	input  wire [16:0] wb_addr,
	output wire [31:0] wb_rdata,
	input  wire [31:0] wb_wdata,
	input  wire [ 3:0] wb_wstb,
	input  wire        wb_we,
	input  wire        wb_re,
	input  wire        wb_cyc,
	input  wire        wb_stb,
	output wire        wb_ack,

	// X-Clock USB control
	output wire [11:0] usb_addr,
	output wire [15:0] usb_wdata,
	input  wire [15:0] usb_rdata,
	output wire        usb_cyc,
	output wire        usb_we,
	input  wire        usb_ack,

	input  wire        usb_clk,
	input  wire        usb_rst,

	// MicroCode write
	output wire [ 7:0] uc_addr,
	output wire [15:0] uc_data,
	output reg         uc_we,

	// USB EP buffer interface
	output wire [ 8:0] ep_tx_addr,
	output wire [31:0] ep_tx_data,
	output reg         ep_tx_we,

	output wire [ 8:0] ep_rx_addr,
	input  wire [31:0] ep_rx_data,
	output wire        ep_rx_re,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	reg         ack;

	wire        wb_cyc_usb;
	wire        wb_ack_usb;
	wire [31:0] wb_rdata_usb;


	// X-clock USB
	// -----------

	xclk_wb #(
		.DW(16),
		.AW(12)
	) usb_if_I (
		.s_addr (wb_addr[13:2]),
		.s_wdata(wb_wdata[15:0]),
		.s_rdata(wb_rdata_usb[15:0]),
		.s_cyc  (wb_cyc_usb),
		.s_ack  (wb_ack_usb),
		.s_we   (wb_we),
		.s_clk  (clk),
		.m_addr (usb_addr),
		.m_wdata(usb_wdata),
		.m_rdata(usb_rdata),
		.m_cyc  (usb_cyc),
		.m_ack  (usb_ack),
		.m_we   (usb_we),
		.m_clk  (usb_clk),
		.rst    (rst)
	);

	assign wb_rdata_usb[31:16] = 16'h0000;
	assign wb_cyc_usb = wb_cyc & wb_stb & ~wb_addr[14];


	// RAM accesses
	// ------------

	(* keep *)
	wire ram_we = wb_cyc & wb_stb & wb_we & ~ack;

	// MicroCode write
	assign uc_addr = wb_addr[9:2];
	assign uc_data = wb_wdata[15:0];

	always @(posedge clk)
		uc_we <= ram_we & (wb_addr[14:13] == 2'b10);


	// EP Buffer
	assign ep_tx_addr = wb_addr[10:2];
	assign ep_rx_addr = wb_addr[10:2];

	assign ep_tx_data = wb_wdata;

	assign ep_rx_re   = 1'b1;

	always @(posedge clk)
		ep_tx_we <= ram_we & (wb_addr[14:13] == 2'b11);


	// Bus sharing
	// -----------

	always @(posedge clk)
		ack <= wb_cyc & wb_stb & wb_addr[14] & ~ack;

	assign wb_rdata = wb_addr[14] ? ep_rx_data : wb_rdata_usb;
	assign wb_ack = ack | wb_ack_usb;

endmodule
