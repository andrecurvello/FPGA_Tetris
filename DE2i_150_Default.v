// ============================================================================
// Copyright (c) 2012 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//  
//  
//                     web: http://www.terasic.com/  
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	de2i_150_Default
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author              :| Mod. Date :| Changes Made:
//   V1.1 :| WadeWang            :| 07/04/12  :| Initial Revision
//   V2.0 :| Peli Li             :| 07/04/12  :| Initial Revision
// --------------------------------------------------------------------


module DE2i_150_Default(

							/////// CLOCK //////
							CLOCK2_50,
							CLOCK3_50,
							CLOCK_50,

							//////// SEG7 ////////
							HEX0,
							HEX1,
							HEX2,
							HEX3,
							HEX4,
							HEX5,
							HEX6,
							HEX7,

							//////// IRDA ////////
							IRDA_RXD,

							//////// KEY /////////
							KEY,


							//////// LED //////////
							LEDG,
							LEDR,
							
							/////// SW /////////
							SW,

							//////// VGA ////////
							VGA_B,
							VGA_BLANK_N,
							VGA_CLK,
							VGA_G,
							VGA_HS,
							VGA_R,
							VGA_SYNC_N,
							VGA_VS
);

//=======================================================
//  PORT declarations
//=======================================================

///////////////// CLOCK ///////////////////

input                			CLOCK2_50;
input               			 	CLOCK3_50;
input                			CLOCK_50;

/////////////// SEG7 //////////////////////////
output              [6:0]     HEX0;
output              [6:0]     HEX1;
output              [6:0]     HEX2;
output              [6:0]     HEX3;
output              [6:0]     HEX4;
output              [6:0]     HEX5;
output              [6:0]     HEX6;
output              [6:0]     HEX7;

/////////////// IRDA /////////////////////////
input                         IRDA_RXD;

/////////////// KEY //////////////////////////
input               [3:0]     KEY;

/////////////// LED //////////////////////////
output              [8:0]     LEDG;
output              [17:0]    LEDR;

/////////////// SW ///////////////////////////
input               [17:0]    SW;

////////////// VGA ///////////////////////////
output              [7:0]     VGA_B;
output                        VGA_BLANK_N;
output                        VGA_CLK;
output              [7:0]     VGA_G;
output                        VGA_HS;
output              [7:0]     VGA_R;
output                        VGA_SYNC_N;
output                        VGA_VS;

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire		   VGA_CTRL_CLK;
wire		   DLY_RST;

wire [9:0] boardgrid [0:19];
wire [15:0] score_of_player;
wire [15:0] next_piece;
wire			game_over;

//	Reset Delay Timer
Reset_Delay		r0	(
						   .iCLK(CLOCK_50),
							.oRESET(DLY_RST),
							.iRST_n(SW[0]) 	
						);

reg vga_clk_reg;
always @(posedge CLOCK_50)
vga_clk_reg = !vga_clk_reg;

assign VGA_CTRL_CLK = vga_clk_reg;

//	VGA Controller
//assign VGA_BLANK_N = !cDEN;
assign VGA_CLK = ~VGA_CTRL_CLK;
vga_controller u4  (
							.iRST_n  (DLY_RST),
							.iVGA_CLK(VGA_CTRL_CLK),
							.oBLANK_n(VGA_BLANK_N),
							.oHS     (VGA_HS),
							.oVS     (VGA_VS),
							.b_data  (VGA_B),
							.g_data  (VGA_G),
							.r_data  (VGA_R),
							.iboardgrid(boardgrid),
							.inextpiece(next_piece),
							.iscoreofplayer(score_of_player),
							.isgameover(game_over)
						 );

Tetris	MAIN (
					.iCLK(CLOCK_50),
					.iRST_n(DLY_RST),
					.ir_rxd(IRDA_RXD),
					.iKEY(KEY[3:0]),
					.boardgrid(boardgrid),
					.onextpiece(next_piece),
					.oscoreofplayer(score_of_player),
					.isgameover(game_over)
					 );

endmodule
