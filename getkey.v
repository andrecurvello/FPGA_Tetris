module getkey(
				clk,
				rst,
				ir_rxd,
				key_out
				);
				
	input clk, rst, ir_rxd;
	output reg [2:0] key_out;
	
	parameter 	NONE				= 3'b000,
					LEFT 				= 3'b001,
					RIGHT 			= 3'b010,
					DOWN 				= 3'b011,
					PERFECT_DOWN 	= 3'b100,
					SPIN				= 3'b101;
					
	wire data_ready;
	wire [31:0] data_out_ir;
	
	
	IR_RECEIVE TEST (
		.iCLK(clk),
		.iRST_n(rst),				
		.iIRDA(ir_rxd),
		.oDATA_READY(data_ready),
		.oDATA(data_out_ir)         
		);
		
	always @(negedge data_ready or negedge rst) begin
	
		if (!rst) begin
			key_out <= NONE;
		end
		else
		if (!data_ready) begin
			case (data_out_ir[23:16])
				8'h04: key_out <= LEFT;
				8'h06: key_out <= RIGHT;
				8'h02: key_out <= SPIN;
				8'h08: key_out <= DOWN;
				8'h05: key_out <= PERFECT_DOWN;
				default: key_out <= NONE;
			endcase 
		end
	end
endmodule 			
				