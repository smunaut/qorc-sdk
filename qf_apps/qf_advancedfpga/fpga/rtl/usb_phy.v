/*
 * usb_phy.v
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

module usb_phy #(
	parameter TARGET = "ICE40"
)(
	// Pads
	inout  wire pad_dp,
	inout  wire pad_dn,

	// RX
	output wire rx_dp,
	output wire rx_dn,
	output wire rx_chg,

	// TX
	input  wire tx_dp,
	input  wire tx_dn,
	input  wire tx_en,

	// Common
	input  wire clk,
	input  wire rst
);

	wire [1:0] rx_dp_i;
	wire [1:0] rx_dn_i;
	reg  [2:0] dp_state;
	reg  [2:0] dn_state;

	// IO buffers
	wire rx_dp_io, rx_dn_io;
	reg  rx_dp_ff, rx_dn_ff;

	bipad io_dp_I (
		.A(tx_dp),
		.EN(tx_en),
		.Q(rx_dp_io),
		.P(pad_dp)
	);

	bipad io_dn_I (
		.A(tx_dn),
		.EN(tx_en),
		.Q(rx_dn_io),
		.P(pad_dn)
	);

	always @(posedge clk)
	begin
		rx_dp_ff <= rx_dp_io;
		rx_dn_ff <= rx_dn_io;
	end

	assign rx_dp_i = { rx_dp_ff, rx_dp_ff };
	assign rx_dn_i = { rx_dn_ff, rx_dn_ff };

	// Input sync, filter and change detect
	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			dp_state <= 3'b000;
			dn_state <= 3'b000;
		end else begin
			case ({dp_state[1:0], rx_dp_i})
				4'b0000: dp_state <= 3'b000;
				4'b0001: dp_state <= 3'b001;
				4'b0010: dp_state <= 3'b001;
				4'b0011: dp_state <= 3'b001;
				4'b0100: dp_state <= 3'b000;
				4'b0101: dp_state <= 3'b001;
				4'b0110: dp_state <= 3'b001;
				4'b0111: dp_state <= 3'b111;
				4'b1000: dp_state <= 3'b100;
				4'b1001: dp_state <= 3'b010;
				4'b1010: dp_state <= 3'b010;
				4'b1011: dp_state <= 3'b011;
				4'b1100: dp_state <= 3'b010;
				4'b1101: dp_state <= 3'b010;
				4'b1110: dp_state <= 3'b010;
				4'b1111: dp_state <= 3'b011;
				default: dp_state <= 3'bxxx;
			endcase

			case ({dn_state[1:0], rx_dn_i})
				4'b0000: dn_state <= 3'b000;
				4'b0001: dn_state <= 3'b001;
				4'b0010: dn_state <= 3'b001;
				4'b0011: dn_state <= 3'b001;
				4'b0100: dn_state <= 3'b000;
				4'b0101: dn_state <= 3'b001;
				4'b0110: dn_state <= 3'b001;
				4'b0111: dn_state <= 3'b111;
				4'b1000: dn_state <= 3'b100;
				4'b1001: dn_state <= 3'b010;
				4'b1010: dn_state <= 3'b010;
				4'b1011: dn_state <= 3'b011;
				4'b1100: dn_state <= 3'b010;
				4'b1101: dn_state <= 3'b010;
				4'b1110: dn_state <= 3'b010;
				4'b1111: dn_state <= 3'b011;
				default: dn_state <= 3'bxxx;
			endcase
		end
	end

	assign rx_dp  = dp_state[1];
	assign rx_dn  = dn_state[1];
	assign rx_chg = dp_state[2] | dn_state[2];

endmodule // usb_phy
