module s3_pc_tb;

	reg clk = 1'b0;
	reg rst = 1'b1;

	wire       op_jmp;
	wire [7:0] op_tgt;
	wire       op_cond_inv;
	wire [3:0] op_cond_mask;
	wire [3:0] op_cond_val;
	wire [3:0] a_reg;
	wire [7:0] pc;

	// DUT
	s3_pc dut_I (
		.op_jmp(op_jmp),
		.op_tgt(op_tgt),
		.op_cond_inv(op_cond_inv),
		.op_cond_mask(op_cond_mask),
		.op_cond_val(op_cond_val),
		.a_reg(a_reg),
		.pc(pc),
		.clk(clk),
		.rst(rst)
	);

	assign op_cond_mask = 4'hf;
	assign op_cond_val  = 4'hd;
	assign op_cond_inv  = 1'b1;
	assign a_reg        = 4'h0;

	assign op_jmp = 1'b0;
	assign op_tgt = 8'ha5;

	// Setup recording
	initial begin
		$dumpfile("s3_pc_tb.vcd");
		$dumpvars(0,s3_pc_tb);
	end

	// Reset pulse
	initial begin
		# 200 rst = 0;
		# 100000 $finish;
	end

	// Clocks
	always #10 clk = !clk;

endmodule
