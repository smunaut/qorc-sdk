/*
 * usb_ep_buf.v
 *
 * vim: ts=4 sw=4
 *
 * Copyright (C) 2019 Sylvain Munaut
 * All rights reserved.
 *
 * LGPL v3+, see LICENSE.lgpl3
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

`default_nettype none

module usb_ep_buf #(
	parameter TARGET = "QL-S3",
	parameter integer RWIDTH = 32,	// 8/16/32/64
	parameter integer WWIDTH = 8,	// 8/16/32/64
	parameter integer AWIDTH = 11,	// Assuming 'byte' access

	parameter integer ARW = AWIDTH - $clog2(RWIDTH / 8),
	parameter integer AWW = AWIDTH - $clog2(WWIDTH / 8)
)(
	// Read port
	input  wire [ARW-1:0] rd_addr_0,
	output wire [RWIDTH-1:0] rd_data_1,
	input  wire rd_en_0,
	input  wire rd_clk,

	// Write port
	input  wire [AWW-1:0] wr_addr_0,
	input  wire [WWIDTH-1:0] wr_data_0,
	input  wire wr_en_0,
	input  wire wr_clk
);

	generate
		if (AWIDTH != 11)
			$error("Unsupported EP buffer config");

		if ((RWIDTH == 8) && (WWIDTH == 32))
		begin

			wire [35:0] ram_wdata;
			wire [ 8:0] ram_rdata;

			RAM_16K_BLK #(
				.Concatenation_En(   1),
				.wr_addr_int0    (   9),
				.rd_addr_int0    (  11),
				.wr_depth_int0   ( 512),
				.rd_depth_int0   (2048),
				.wr_width_int0   (  36),
				.rd_width_int0   (   9),
				.wr_enable_int0  (   4),
				.reg_rd_int0     (   0)
			) ram_I (
				.WA0(wr_addr_0),
				.RA0(rd_addr_0),
				.WD0(ram_wdata),
				.WD0_SEL(1'b1),
				.RD0_SEL(1'b1),
				.WClk0(wr_clk),
				.RClk0(rd_clk),
				.WClk0_En(1'b1),
				.RClk0_En(rd_en_0),
				.WEN0({4{wr_en_0}}),
				.RD0(ram_rdata),
				.LS(1'b0),
				.DS(1'b0),
				.SD(1'b0),
				.LS_RB1(1'b0),
				.DS_RB1(1'b0),
				.SD_RB1(1'b0)
			);

			assign ram_wdata = {
				1'b0, wr_data_0[31:24],
				1'b0, wr_data_0[23:16],
				1'b0, wr_data_0[15: 8],
				1'b0, wr_data_0[ 7: 0]
			};
			assign rd_data_1 = ram_rdata[7:0];

		end
		else if ((RWIDTH == 32) && (WWIDTH == 8))
		begin

			wire [ 8:0] ram_wdata;
			wire [35:0] ram_rdata;

			RAM_16K_BLK #(
				.Concatenation_En(   1),
				.wr_addr_int0    (  11),
				.rd_addr_int0    (   9),
				.wr_depth_int0   (2048),
				.rd_depth_int0   ( 512),
				.wr_width_int0   (   9),
				.rd_width_int0   (  36),
				.wr_enable_int0  (   1),
				.reg_rd_int0     (   0)
			) ram_I (
				.WA0(wr_addr_0),
				.RA0(rd_addr_0),
				.WD0(ram_wdata),
				.WD0_SEL(1'b1),
				.RD0_SEL(1'b1),
				.WClk0(wr_clk),
				.RClk0(rd_clk),
				.WClk0_En(1'b1),
				.RClk0_En(rd_en_0),
				.WEN0(wr_en_0),
				.RD0(ram_rdata),
				.LS(1'b0),
				.DS(1'b0),
				.SD(1'b0),
				.LS_RB1(1'b0),
				.DS_RB1(1'b0),
				.SD_RB1(1'b0)
			);

			assign ram_wdata = { 1'b0, wr_data_0[ 7: 0] };
			assign rd_data_1 = {
				ram_rdata[34: 27],
				ram_rdata[25: 18],
				ram_rdata[16:  9],
				ram_rdata[ 7:  0]
			};

		end
		else
			$error("Unsupported EP buffer config");

	endgenerate

endmodule // usb_ep_buf
