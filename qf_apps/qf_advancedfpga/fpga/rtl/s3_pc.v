`default_nettype none

module s3_pc (
	// Jump ?
	input  wire       op_jmp,
	input  wire [7:0] op_tgt,

	// Condition
	input  wire       op_cond_inv,
	input  wire [3:0] op_cond_mask,
	input  wire [3:0] op_cond_val,
	input  wire [3:0] a_reg,

	// Next PC
	output wire [7:0] pc,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	wire [1:0] match_mid;
	wire [1:0] match;
	wire       ctrl;
	wire       rst_n;

	wire [7:0] pc_reg;
	wire [7:0] pc_inc;
	wire [7:0] pc_mux;


	// Match
	// -----

	// This generates
	//  match[1] = (a_reg[3:2] & op_cond_mask[3:2]) == op_cond_val[3:2]
	//  match[0] = (a_reg[1:0] & op_cond_mask[1:0]) == op_cond_val[1:0]

	logic_cell_macro match_0_I (
		.BA1  (1'b1),
		.BA2  (1'b1),
		.BAB  (op_cond_mask[1]),
		.BAS1 (1'b0),
		.BAS2 (1'b0),
		.BB1  (a_reg[1]),
		.BB2  (a_reg[1]),
		.BBS1 (1'b1),
		.BBS2 (1'b0),
		.BSL  (op_cond_val[1]),
		.F1   (1'b0),
		.F2   (match_mid[0]),
		.FS   (match_mid[1]),
		.QCK  (1'b0),
		.QCKS (1'b0),
		.QDI  (1'b0),
		.QDS  (1'b0),
		.QEN  (1'b0),
		.QRT  (1'b0),
		.QST  (1'b0),
		.TA1  (1'b1),
		.TA2  (1'b1),
		.TAB  (op_cond_mask[0]),
		.TAS1 (1'b0),
		.TAS2 (1'b0),
		.TB1  (a_reg[0]),
		.TB2  (a_reg[0]),
		.TBS  (match_mid[0]),
		.TBS1 (1'b1),
		.TBS2 (1'b0),
		.TSL  (op_cond_val[0]),
		.CZ   (match[0]),
		.FZ   (),
		.QZ   (),
		.TZ   (match_mid[0])
	);

	logic_cell_macro match_1_I (
		.BA1  (1'b1),
		.BA2  (1'b1),
		.BAB  (op_cond_mask[3]),
		.BAS1 (1'b0),
		.BAS2 (1'b0),
		.BB1  (a_reg[3]),
		.BB2  (a_reg[3]),
		.BBS1 (1'b1),
		.BBS2 (1'b0),
		.BSL  (op_cond_val[3]),
		.F1   (1'b0),
		.F2   (match_mid[2]),
		.FS   (match_mid[3]),
		.QCK  (1'b0),
		.QCKS (1'b0),
		.QDI  (1'b0),
		.QDS  (1'b0),
		.QEN  (1'b0),
		.QRT  (1'b0),
		.QST  (1'b0),
		.TA1  (1'b1),
		.TA2  (1'b1),
		.TAB  (op_cond_mask[2]),
		.TAS1 (1'b0),
		.TAS2 (1'b0),
		.TB1  (a_reg[2]),
		.TB2  (a_reg[2]),
		.TBS  (match_mid[1]),
		.TBS1 (1'b1),
		.TBS2 (1'b0),
		.TSL  (op_cond_val[2]),
		.CZ   (match[1]),
		.FZ   (),
		.QZ   (),
		.TZ   (match_mid[1])
	);


	// Control
	// -------

	dffc dff_rst (
		.Q(rst_n),
		.D(1'b1),
		.CLK(clk),
		.CLR(rst)
	);

	assign ctrl = op_jmp;

//	AND2I0 ctrl_I (
//		.A(rst_n),
//		.B(op_jmp),
//		.Q(ctrl)
//	);


	// Incrementer
	// -----------

	s3_inc8 pc_inc_I (
		.a(pc_reg),
		.x(pc_inc)
	);


	// Final Mux cells
	// ---------------

	logic_cell_macro mux_I[7:0] (
		.BA1  (pc_inc),
		.BA2  (pc_mux),
		.BAB  (match[0]),
		.BAS1 (1'b0),
		.BAS2 (1'b0),
		.BB1  (pc_mux),
		.BB2  (pc_inc),
		.BBS1 (1'b0),
		.BBS2 (1'b0),
		.BSL  (op_cond_inv),
		.F1   (pc_inc),
		.F2   (op_tgt),
		.FS   (ctrl),
		.QCK  (clk),
		.QCKS (1'b1),
		.QDI  (1'b0),
		.QDS  (1'b0),
		.QEN  (1'b1),
		.QRT  (rst),
		.QST  (1'b0),
		.TA1  (pc_inc),
		.TA2  (pc_mux),
		.TAB  (match[0]),
		.TAS1 (1'b0),
		.TAS2 (1'b0),
		.TB1  (pc_inc),
		.TB2  (pc_mux),
		.TBS  (match[1]),
		.TBS1 (1'b0),
		.TBS2 (1'b0),
		.TSL  (op_cond_inv),
		.CZ   (pc),
		.FZ   (pc_mux),
		.QZ   (pc_reg),
		.TZ   ()
	);

endmodule // s3_pc
