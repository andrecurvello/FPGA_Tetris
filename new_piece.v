
module new_piece(
					clk,
					rst,
					next_block_shape
					);
	
	input clk, rst;
	output reg [15:0] next_block_shape;
	
	
	parameter	A = 5'b00000,
					B = 5'b00001,
					C = 5'b00010,
					D = 5'b00011,
					E = 5'b00100,
					F = 5'b00101,
					G = 5'b00110,
					H = 5'b00111,
					I = 5'b01000,
					J = 5'b01001,
					K = 5'b01010,
					L = 5'b01011,
					M = 5'b01100,
					N = 5'b01101,
					O = 5'b01110,
					P = 5'b01111,
					Q = 5'b10000,
					R = 5'b10001,
					S = 5'b10010;
					
	parameter BLOCK_O = 16'h0660,
				 BLOCK_I_1 = 16'h0f00,
				 BLOCK_I_2 = 16'h4444,
				 BLOCK_S_1 = 16'h0360,
				 BLOCK_S_2 = 16'h2310,
				 BLOCK_Z_1 = 16'h0630,
				 BLOCK_Z_2 = 16'h2640,
				 BLOCK_L_1 = 16'h0740,
				 BLOCK_L_2 = 16'h4460,
				 BLOCK_L_3 = 16'h02e0,
				 BLOCK_L_4 = 16'h6220,
				 BLOCK_J_1 = 16'h0e20,
				 BLOCK_J_2 = 16'h6440,
				 BLOCK_J_3 = 16'h0470,
				 BLOCK_J_4 = 16'h2260,
				 BLOCK_T_1 = 16'h0720,
				 BLOCK_T_2 = 16'h4640,
				 BLOCK_T_3 = 16'h0270,
				 BLOCK_T_4 = 16'h2620;
	
	reg [31:0] random;
	reg [4:0] random_block_type;
	
//	initial begin
//		random_block_type = BLOCK_O;
//		random_block_type = 5'b0;
//		rand = 32'h12345678;
//	end
	
	always@ (posedge clk)
	begin
		if(!rst) begin
			random_block_type <= 5'd0;
			next_block_shape <= 16'd0;
         random <= 32'h12345678;
		end
		else
		begin
			random <= {random[21]^random[10], random[22]^random[9], random[23]^random[8], random[24]^random[7], random[25]^random[6], random[26]^random[5], random[27]^random[4], random[10:1], random[28]^random[3], random[29]^random[2], random[30]^random[1], random[31]^random[0], random[20:11], random[31]};
			random_block_type <= {random[4], random[9], random[25], random[0], random[13]};
			
			case(random_block_type)
				A:
					next_block_shape <= BLOCK_O;
				
				B: 
					next_block_shape <= BLOCK_I_1;
					
				C: 
					next_block_shape <= BLOCK_I_2;
				
				D: 
					next_block_shape <= BLOCK_S_1;
					
				E: 
					next_block_shape <= BLOCK_S_2;
					
				F:
					next_block_shape <= BLOCK_Z_1;
					
				G: 
					next_block_shape <= BLOCK_Z_2;
					
				H: 
					next_block_shape <= BLOCK_L_1;
					
				I: 
					next_block_shape <= BLOCK_L_2;
					
				J: 
					next_block_shape <= BLOCK_L_3;
					
				K: 
					next_block_shape <= BLOCK_L_4;
					
				L: 
					next_block_shape <= BLOCK_J_1;
					
				M: 
					next_block_shape <= BLOCK_J_2;
					
				N: 
					next_block_shape <= BLOCK_J_3;
					
				O: 
					next_block_shape <= BLOCK_J_4;
					
				P: 
					next_block_shape <= BLOCK_T_1;
					
				Q: 
					next_block_shape <= BLOCK_T_2;
					
				R:
					next_block_shape <= BLOCK_T_3;
					
				S: 
					next_block_shape <= BLOCK_T_4;
					
				default:
					next_block_shape <= BLOCK_O;
			endcase
		end
	end
	
endmodule 
