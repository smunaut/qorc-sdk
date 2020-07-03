module s3_inc8_tb;

	reg  [7:0] a;
	wire [7:0] x;
	wire [7:0] y;
	wire [7:0] d;
	wire err;

	reg clk = 1'b0;
	reg rst = 1'b1;

	always @(posedge clk)
		if (rst)
			a <= 8'h00;
		else
			a <= y;

	assign y = a + 1;
	assign d = x ^ y;
	assign err = |d;

	s3_inc8 inc_I (
		.a(a),
		.x(x)
	);

	// Setup recording
	initial begin
		$dumpfile("s3_inc8_tb.vcd");
		$dumpvars(0,s3_inc8_tb);
	end

	// Reset pulse
	initial begin
		# 200 rst = 0;
		# 100000 $finish;
	end

	// Clocks
	always #10 clk = !clk;

endmodule
