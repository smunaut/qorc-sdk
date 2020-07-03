

`default_nettype none

module usb_bench (
	// Microcode programming
	input wire  [7:0] uc_addr,
	input wire [15:0] uc_data,
	input wire        uc_we,
	input wire        uc_clk,

	output reg [1:0] x,

	// Common
	input  wire clk,
	input  wire rst
);

	reg [3:0] mc_a_reg;
	wire [ 7:0] mc_pc;
	wire [15:0] mc_opcode;

	always @(posedge clk) begin
		mc_a_reg <= mc_opcode[11:8];
		x <= mc_a_reg[1:0];
	end

	s3_pc dut_I (
		.op_jmp       (mc_opcode[15]),
		.op_tgt       ({mc_opcode[13:8], 2'b00}),
		.op_cond_inv  (mc_opcode[14]),
		.op_cond_mask (mc_opcode[7:4]),
		.op_cond_val  (mc_opcode[3:0]),
		.a_reg        (mc_a_reg),
		.pc           (mc_pc),
		.clk          (clk),
		.rst          (rst)
	);

	RAM_16K_BLK #(
		.Concatenation_En(   0),
		.wr_addr_int0    (   8),
		.rd_addr_int0    (   8),
		.wr_depth_int0   ( 256),
		.rd_depth_int0   ( 256),
		.wr_width_int0   (  16),
		.rd_width_int0   (  16),
		.wr_enable_int0  (   2),
		.reg_rd_int0     (   0)
	) ram_I (
		.WA0(uc_addr),
		.RA0(mc_pc),
		.WD0(uc_data),
		.WD0_SEL(1'b1),
		.RD0_SEL(1'b1),
		.WClk0(uc_clk),
		.RClk0(clk),
		.WClk0_En(1'b1),
		.RClk0_En(1'b1),
		.WEN0({2{uc_we}}),
		.RD0(mc_opcode),
		.LS(1'b0),
		.DS(1'b0),
		.SD(1'b0),
		.LS_RB1(1'b0),
		.DS_RB1(1'b0),
		.SD_RB1(1'b0)
	);

endmodule
