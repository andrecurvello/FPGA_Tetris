module Tetris(
					iCLK,
					iRST_n,
					ir_rxd,
					iKEY,
					boardgrid,
					onextpiece,
					oscoreofplayer,
					isgameover
					 );
	
	// Control signal
	input			iCLK;
	input			iRST_n;
	input			ir_rxd;
	input [3:0] iKEY;
	
	//VGA output signal
	output  reg [9:0] boardgrid [0:19];
	output		[15:0] 	onextpiece;
	output		[15:0]	oscoreofplayer;
	output reg			isgameover;
					
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
	
	parameter 	NONE				= 3'b000,
					LEFT 				= 3'b001,
					RIGHT 			= 3'b010,
					DOWN 				= 3'b011,
					PERFECT_DOWN 	= 3'b100,
					SPIN				= 3'b101;
				 
	parameter   INIT = 5'd0,
            GENERATE = 5'd1,
            PRE_GENERATE = 5'd2,
            WRITE_TO_SRAM = 5'd3,
            WAIT = 5'd4,
            REMOVE_COLOR = 5'd5,
            CHECK_IF_MOVABLE = 5'd6,
            MOVE_ONE_DOWN = 5'd7,
            MOVE_LEFT = 5'd8,
            MOVE_RIGHT = 5'd9,
            SPIN_LEFT = 5'd10,
            CHECK_COMPLETE_ROW = 5'd11,
            DELETE_ROW = 5'd12,
            SHIFT_ALL_BLOCKS_ABOVE = 5'd13,
            SHIFT_BLOCKS_READ_ABOVE = 5'd14,
            SHIFT_BLOCKS_WRITE_TO_CURRENT = 5'd15,
            GAME_OVER = 5'd16,
            DECREMENT_SHIFT_COUNT_Y = 5'd17,
            INCREMENT_SHIFT_COUNT_X = 5'd18,
            INCREMENT_DRAW_COUNT = 5'd19,
            COLOR_READ_BUFFER = 5'd20,
            CHECK_BUFFER = 5'd21,
            PRE_WAIT = 5'd22;
				
	// variable for current, next piece and boardgrid
	reg [15:0] next_piece;
	wire [15:0] random_piece;
	reg [15:0] current_piece;
	reg [15:0] score_of_player;
	reg [3:0] 	current_x [0:3];
	reg [4:0]  current_y [0:3];
	
	// Type of check that was requested
	reg [2:0] requestMovableCheck;
	wire [2:0] move_key;
	
	// Variable for delete row
	reg [4:0] delete_row;
	reg [4:0] count_row;
	
	
	assign oscoreofplayer = score_of_player;
	assign onextpiece 	 = next_piece;
	//assign ocurrentpiece  = current_piece;
	
	//variable for state
	reg [4:0] STATE;
	
	/*---- Control variables ----*/
	wire move_left_key, move_right_key, spin_key, down_key;
	
	MoveKey toLeft(~iKEY[3], move_left_key, iCLK, iRST_n);
	MoveKey toRight(~iKEY[2], move_right_key, iCLK, iRST_n);
	MoveKey toSpin(~iKEY[1], spin_key, iCLK, iRST_n);
	MoveKey toDown(~iKEY[0], down_key, iCLK, iRST_n);
					
	//variable for timer
	wire [31:0] sec;
	reg forceReset;
	SecTimer secondClock(
								.clk(iCLK), 
								.rst(iRST_n), 
								.sec(sec), 
								.forceReset(forceReset)
								);
	
	
	// Generate random tetromino every clock
	new_piece R1(
					.clk(iCLK), 
					.rst(iRST_n), 
					.next_block_shape(random_piece)
					);
	
	//Get movable key
//	getkey G0 (
//					.clk(iCLK),
//					.rst(iRST_n),
//					.ir_rxd(ir_rxd),
//					.key_out(move_key)
//					);
	
	// Calculate next state
	
	always @(posedge iCLK or negedge iRST_n) begin
    if (!iRST_n) begin
        STATE <= INIT;
		  score_of_player <= 16'd0;
		  next_piece <= 16'd0;
		  current_piece <= 16'd0;
		  forceReset <= 1'b0;
		  requestMovableCheck <= NONE;
		  isgameover <= 1'b0;
		  delete_row <= 5'd19;
		  count_row <= 5'd19;
		  
		  boardgrid[0] <= 10'd0; 
		  boardgrid[1] <= 10'd0;
		  boardgrid[2] <= 10'd0;
		  boardgrid[3] <= 10'd0;
		  boardgrid[4] <= 10'd0;
		  boardgrid[5] <= 10'd0;
		  boardgrid[6] <= 10'd0;
		  boardgrid[7] <= 10'd0;
		  boardgrid[8] <= 10'd0;
		  boardgrid[9] <= 10'd0;
		  boardgrid[10] <= 10'd0;
		  boardgrid[11] <= 10'd0;
		  boardgrid[12] <= 10'd0;
		  boardgrid[13] <= 10'd0;
		  boardgrid[14] <= 10'd0;
		  boardgrid[15] <= 10'd0;
		  boardgrid[16] <= 10'd0;
		  boardgrid[17] <= 10'd0;
		  boardgrid[18] <= 10'd0;
		  boardgrid[19] <= 10'd0;
    end
    else begin
		 case (STATE)
			  INIT: begin
					next_piece <= random_piece;
					if (sec == 1) begin	 
						 STATE <= PRE_GENERATE;
						 forceReset <= 1'b1;
					end
					else begin
						STATE <= INIT;
						forceReset <= 1'b0;
					end
			  end
			  PRE_GENERATE: begin
					current_piece <= next_piece;
					next_piece <= next_piece;
					STATE <= GENERATE;
			  end
			  GENERATE: begin
					current_piece <= next_piece;
					next_piece <= random_piece;
					case(current_piece)
						BLOCK_O: begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd5;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_I_1:begin
							current_x[0] <= 4'd3;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd6;
							
							current_y[0] <= 5'd3;
							current_y[1] <= 5'd3;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						
						BLOCK_I_2:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd4;
							
							current_y[0] <= 5'd0;
							current_y[1] <= 5'd1;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						
						
						BLOCK_S_1:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd5;
							current_x[2] <= 4'd3;
							current_x[3] <= 4'd4;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_S_2:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_Z_1:begin
							current_x[0] <= 4'd3;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_Z_2:begin
							current_x[0] <= 4'd5;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd4;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
							
						BLOCK_L_1:begin
							current_x[0] <= 4'd3;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd3;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_L_2:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
							
						BLOCK_L_3:begin
							current_x[0] <= 4'd5;
							current_x[1] <= 4'd3;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd3;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_L_4:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd5;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd1;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_J_1:begin
							current_x[0] <= 4'd3;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_J_2:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd5;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd4;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd1;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_J_3:begin
							current_x[0] <= 4'd3;
							current_x[1] <= 4'd3;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd3;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_J_4:begin
							current_x[0] <= 4'd5;
							current_x[1] <= 4'd5;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_T_1:begin
							current_x[0] <= 4'd3;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd4;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_T_2:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd4;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						BLOCK_T_3:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd3;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd3;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
						BLOCK_T_4:begin
							current_x[0] <= 4'd5;
							current_x[1] <= 4'd4;
							current_x[2] <= 4'd5;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd1;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd2;
							current_y[3] <= 5'd3;
						end
						default:begin
							current_x[0] <= 4'd4;
							current_x[1] <= 4'd5;
							current_x[2] <= 4'd4;
							current_x[3] <= 4'd5;
							
							current_y[0] <= 5'd2;
							current_y[1] <= 5'd2;
							current_y[2] <= 5'd3;
							current_y[3] <= 5'd3;
						end
					endcase
					STATE <= PRE_WAIT;
			  end
			  
			  PRE_WAIT: begin
					boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b1;
					boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b1;
					boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b1;
					boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b1;
					forceReset <= 1'b0;
					STATE <= WAIT;
			  end
			  
			  WAIT: begin
            // When it waited for a certain amount of time
            if (sec >= 32'd25) begin
                STATE <= CHECK_IF_MOVABLE;
					 requestMovableCheck <= NONE;
            end
				else
					if (move_left_key == 1'b1 && move_right_key == 1'b0 && spin_key == 1'b0 && down_key == 1'b0)
						begin
							requestMovableCheck <= LEFT;
							STATE <= CHECK_IF_MOVABLE;
							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
						end
					else if (move_left_key == 1'b0 && move_right_key == 1'b1 && spin_key == 1'b0 && down_key == 1'b0)
						begin
							requestMovableCheck <= RIGHT;
							STATE <= CHECK_IF_MOVABLE;
							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
						end
					else if (move_left_key == 1'b0 && move_right_key == 1'b0 && spin_key == 1'b0 && down_key == 1'b1)
						begin
							requestMovableCheck <= DOWN;
							STATE <= CHECK_IF_MOVABLE;
							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
						end
//						begin
//							requestMovableCheck <= PERFECT_DOWN;
//							STATE <= CHECK_IF_MOVABLE;
//							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
//							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
//							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
//							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
//						end
					else if (move_left_key == 1'b0 && move_right_key == 1'b0 && spin_key == 1'b1 && down_key == 1'b0)
						begin
							requestMovableCheck <= SPIN;
							STATE <= CHECK_IF_MOVABLE;
							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
						end
					else begin
							requestMovableCheck <= NONE;
							STATE <= WAIT;
						end
			  end
			  
			  CHECK_IF_MOVABLE: begin
			  
				case (requestMovableCheck)
					LEFT: begin
						if (!(current_x[0] == 4'd0 || current_x[1] == 4'd0 || current_x[2] == 4'd0 || current_x[3] == 4'd0)) begin
							if (!(boardgrid [current_y[0] - 5'd4][4'd10 - current_x[0]] == 1'b1 ||
							boardgrid [current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b1 ||
							boardgrid [current_y[2] - 5'd4][4'd10 - current_x[2]] == 1'b1 ||
							boardgrid [current_y[3] - 5'd4][4'd10 - current_x[3]] == 1'b1)
							) begin
								boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
								boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
								boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
								boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
								current_x[0] <= current_x[0] - 4'd1;
								current_x[1] <= current_x[1] - 4'd1;
								current_x[2] <= current_x[2] - 4'd1;
								current_x[3] <= current_x[3] - 4'd1;
							end
							else begin
								boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b1;
								boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b1;
								boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b1;
								boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b1;
								current_x[0] <= current_x[0];
								current_x[1] <= current_x[1];
								current_x[2] <= current_x[2];
								current_x[3] <= current_x[3];
							end
							
						end
						else begin
							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b1;
							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b1;
							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b1;
							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b1;
							current_x[0] <= current_x[0];
							current_x[1] <= current_x[1];
							current_x[2] <= current_x[2];
							current_x[3] <= current_x[3];
						end
						STATE <= PRE_WAIT;
					end
					RIGHT: begin
						if (!(current_x[0] == 4'd9 || current_x[1] == 4'd9 || 
								current_x[2] == 4'd9 || current_x[3] == 4'd9)) begin
						
							if (!(boardgrid [current_y[0] - 5'd4][4'd8 - current_x[0]] == 1'b1 ||
								boardgrid [current_y[1] - 5'd4][4'd8 - current_x[1]] == 1'b1 ||
								boardgrid [current_y[2] - 5'd4][4'd8 - current_x[2]] == 1'b1 ||
								boardgrid [current_y[3] - 5'd4][4'd8 - current_x[3]] == 1'b1))
							begin
								boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
								boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
								boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
								boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
								current_x[0] <= current_x[0] + 4'd1;
								current_x[1] <= current_x[1] + 4'd1;
								current_x[2] <= current_x[2] + 4'd1;
								current_x[3] <= current_x[3] + 4'd1;
							end
							else begin
								boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b1;
								boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b1;
								boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b1;
								boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b1;
								current_x[0] <= current_x[0];
								current_x[1] <= current_x[1];
								current_x[2] <= current_x[2];
								current_x[3] <= current_x[3];
							end
						end
						else begin
							boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b1;
							boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b1;
							boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b1;
							boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b1;
							current_x[0] <= current_x[0];
							current_x[1] <= current_x[1];
							current_x[2] <= current_x[2];
							current_x[3] <= current_x[3];
						end
						STATE <= PRE_WAIT;
					end
					
					DOWN: begin
						if (boardgrid [current_y[0] - 5'd3][4'd9 - current_x[0]] == 1'b1 ||
								boardgrid [current_y[1] - 5'd3][4'd9 - current_x[1]] == 1'b1 ||
								boardgrid [current_y[2] - 5'd3][4'd9 - current_x[2]] == 1'b1 ||
								boardgrid [current_y[3] - 5'd3][4'd9 - current_x[3]] == 1'b1 ||
								current_y[0] == 5'd23 || current_y[1] == 5'd23 || 
								current_y[2] == 5'd23 || current_y[3] == 5'd23 )
							begin
							 current_y[0] <= current_y[0];
							 current_y[1] <= current_y[1];
							 current_y[2] <= current_y[2];
							 current_y[3] <= current_y[3];
							 STATE <= PRE_WAIT;
							end
						else 
						begin
							 current_y[0] <= current_y[0] + 5'd1;
							 current_y[1] <= current_y[1] + 5'd1;
							 current_y[2] <= current_y[2] + 5'd1;
							 current_y[3] <= current_y[3] + 5'd1;
							 STATE <= PRE_WAIT;
						end
						
					end
					PERFECT_DOWN: begin
						STATE <= PRE_WAIT;
					end
					SPIN: begin
						case (current_piece)
							
							BLOCK_I_1: begin
								if (boardgrid[current_y[1] - 5'd5][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd6][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd3][4'd9 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[1];
										current_y[0] <= current_y[1] - 5'd2;
										current_x[1] <= current_x[1];
										current_y[1] <= current_y[1] - 5'd1;
										current_x[2] <= current_x[1];
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1];
										current_y[3] <= current_y[1] + 5'd1;
										current_piece <= BLOCK_I_2;
									end
								else if (boardgrid[current_y[2] - 5'd5][4'd9 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd9 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd2][4'd9 - current_x[2]] == 1'b0) 
									begin
										current_x[0] <= current_x[2];
										current_y[0] <= current_y[2] - 5'd1;
										current_x[1] <= current_x[2];
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[2];
										current_y[2] <= current_y[2] + 5'd1;
										current_x[3] <= current_x[2];
										current_y[3] <= current_y[2] + 5'd2;
										current_piece <= BLOCK_I_2;
									end
							end
							BLOCK_I_2: begin
								if (boardgrid[current_y[1] - 5'd4][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd4][4'd7 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[1] - 4'd1;
										current_y[0] <= current_y[1];
										current_x[2] <= current_x[1] + 4'd1;
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1] + 4'd2;
										current_y[3] <= current_y[1];
										current_piece <= BLOCK_I_1;
									end
								else if (boardgrid[current_y[2] - 5'd4][4'd8 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd4][4'd11 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd4][4'd10 - current_x[2]] == 1'b0) 
									begin
										current_x[0] <= current_x[2] - 4'd2;
										current_y[0] <= current_y[2];
										current_x[1] <= current_x[2] - 4'd1;
										current_y[1] <= current_y[2];
										current_x[3] <= current_x[2] + 4'd1;
										current_y[3] <= current_y[2];
										current_piece <= BLOCK_I_1;
									end
							end
							BLOCK_S_1: begin;
								if (boardgrid[current_y[0] - 5'd5][4'd9 - current_x[0]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd3][4'd9 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[0];
										current_y[0] <= current_y[0] - 5'd1;
										current_x[1] <= current_x[0];
										current_y[1] <= current_y[0];
										current_x[2] <= current_x[1];
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1];
										current_y[3] <= current_y[1] + 5'd1;
										current_piece <= BLOCK_S_2;
									end
								else if (boardgrid[current_y[2] - 5'd5][4'd9 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[3] - 5'd3][4'd9 - current_x[3]] == 1'b0) 
									begin
										current_x[0] <= current_x[2];
										current_y[0] <= current_y[2] - 5'd1;
										current_x[1] <= current_x[2];
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[3];
										current_y[2] <= current_y[3];
										current_x[3] <= current_x[3];
										current_y[3] <= current_y[3] + 5'd1;
										current_piece <= BLOCK_S_2;
									end
							end
							BLOCK_S_2: begin
								if (boardgrid[current_y[0] - 5'd4][4'd8 - current_x[0]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[0];
										current_y[0] <= current_y[0];
										current_x[1] <= current_x[0] + 4'd1;
										current_y[1] <= current_y[0];
										current_x[2] <= current_x[1] - 4'd1;
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1];
										current_y[3] <= current_y[1];
										current_piece <= BLOCK_S_1;
									end
								else if (boardgrid[current_y[2] - 5'd4][4'd8 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[3] - 5'd4][4'd10 - current_x[3]] == 1'b0) 
									begin
										current_x[0] <= current_x[2];
										current_y[0] <= current_y[2];
										current_x[1] <= current_x[2] + 4'd1;
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[3] - 4'd1;
										current_y[2] <= current_y[3];
										current_x[3] <= current_x[3];
										current_y[3] <= current_y[3];
										current_piece <= BLOCK_S_1;
									end
							end
							BLOCK_Z_1: begin
								if (boardgrid[current_y[1] - 5'd4][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd5][4'd8 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[1] + 4'd1;
										current_y[0] <= current_y[1] - 5'd1;
										current_x[1] <= current_x[1];
										current_y[1] <= current_y[1];
										current_x[2] <= current_x[1] + 4'd1;
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[2];
										current_y[3] <= current_y[2];
										current_piece <= BLOCK_Z_2;
									end
								else if (boardgrid[current_y[2] - 5'd4][4'd10 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd10 - current_x[2]] == 1'b0) 
									begin
										current_x[0] <= current_x[1];
										current_y[0] <= current_y[1];
										current_x[1] <= current_x[2] - 4'd1;
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[2];
										current_y[2] <= current_y[2];
										current_x[3] <= current_x[2] - 4'd1;
										current_y[3] <= current_y[2] + 5'd1;
										current_piece <= BLOCK_Z_2;
									end
							end
							BLOCK_Z_2: begin
								if (boardgrid[current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[3] - 5'd4][4'd8 - current_x[3]] == 1'b0) 
									begin
										current_x[0] <= current_x[1] - 4'd1;
										current_y[0] <= current_y[1];
										current_x[1] <= current_x[1];
										current_y[1] <= current_y[1];
										current_x[2] <= current_x[3];
										current_y[2] <= current_y[3];
										current_x[3] <= current_x[3] + 4'd1;
										current_y[3] <= current_y[3];
										current_piece <= BLOCK_Z_1;
									end
								else if (boardgrid[current_y[2] - 5'd3][4'd9 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd8 - current_x[2]] == 1'b0) 
									begin
										current_x[0] <= current_x[1];
										current_y[0] <= current_y[1];
										current_x[1] <= current_x[2];
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[2];
										current_y[2] <= current_y[2] + 5'd1;
										current_x[3] <= current_x[2] + 4'd1;
										current_y[3] <= current_y[2] + 5'd1;
										current_piece <= BLOCK_Z_1;
									end
							end
							BLOCK_L_1: begin
								if (boardgrid[current_y[1] - 5'd5][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd3][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd3][4'd8 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[1];
										current_y[0] <= current_y[1] - 5'd1;
										current_x[1] <= current_x[1];
										current_y[1] <= current_y[1];
										current_x[2] <= current_x[1];
										current_y[2] <= current_y[1] + 5'd1;
										current_x[3] <= current_x[1] + 4'd1;
										current_y[3] <= current_y[1] + 5'd1;
										current_piece <= BLOCK_L_2;
									end
							end
							BLOCK_L_2: begin
								if (boardgrid[current_y[1] - 5'd5][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd4][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[0] + 4'd1;
										current_y[0] <= current_y[0];
										current_x[1] <= current_x[1] - 4'd1;
										current_y[1] <= current_y[1];
										current_x[2] <= current_x[1];
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1] + 4'd1;
										current_y[3] <= current_y[1];
										current_piece <= BLOCK_L_3;
									end
							end
							BLOCK_L_3: begin
								if (boardgrid[current_y[2] - 5'd5][4'd9 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd5][4'd10 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd9 - current_x[2]] == 1'b0) 
									begin
										current_x[0] <= current_x[2] - 4'd1;
										current_y[0] <= current_y[2] - 5'd1;
										current_x[1] <= current_x[2];
										current_y[1] <= current_y[2] - 5'd1;
										current_x[2] <= current_x[2];
										current_y[2] <= current_y[2];
										current_x[3] <= current_x[2];
										current_y[3] <= current_y[2] + 5'd1;
										current_piece <= BLOCK_L_4;
									end
							end
							BLOCK_L_4: begin
								if (boardgrid[current_y[2] - 5'd4][4'd8 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd4][4'd10 - current_x[2]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd10 - current_x[2]] == 1'b0) 
									begin
										current_x[0] <= current_x[2] - 4'd1;
										current_y[0] <= current_y[2];
										current_x[1] <= current_x[2];
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[2] + 4'd1;
										current_y[2] <= current_y[2];
										current_x[3] <= current_x[2] - 4'd1;
										current_y[3] <= current_y[2] + 5'd1;
										current_piece <= BLOCK_L_1;
									end
							
							end
							BLOCK_J_1: begin
								if (boardgrid[current_y[1] - 5'd5][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd5][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd3][4'd9 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[1];
										current_y[0] <= current_y[1] - 5'd1;
										current_x[1] <= current_x[1] + 4'd1;
										current_y[1] <= current_y[1] - 5'd1;
										current_x[2] <= current_x[1];
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1];
										current_y[3] <= current_y[1] + 5'd1;
										current_piece <= BLOCK_J_2;
									end
							end
							BLOCK_J_2: begin
								if (boardgrid[current_y[2] - 5'd4][4'd10 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd4][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd5][4'd10 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[2] - 4'd1;
										current_y[0] <= current_y[2] - 5'd1;
										current_x[1] <= current_x[2] - 4'd1;
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[2];
										current_y[2] <= current_y[2];
										current_x[3] <= current_x[2] + 4'd1;
										current_y[3] <= current_y[2];
										current_piece <= BLOCK_J_3;
									end
							end
							BLOCK_J_3: begin
								if (boardgrid[current_y[2] - 5'd5][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd9 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[2] - 5'd3][4'd10 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[2];
										current_y[0] <= current_y[2] - 5'd1;
										current_x[1] <= current_x[2];
										current_y[1] <= current_y[2];
										current_x[2] <= current_x[2] - 4'd1;
										current_y[2] <= current_y[2] + 5'd1;
										current_x[3] <= current_x[2];
										current_y[3] <= current_y[2] + 5'd1;
										current_piece <= BLOCK_J_4;
									end
							end
							BLOCK_J_4: begin
								if (boardgrid[current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd4][4'd8 - current_x[1]] == 1'b0 &&
									boardgrid[current_y[1] - 5'd3][4'd8 - current_x[1]] == 1'b0) 
									begin
										current_x[0] <= current_x[1] - 4'd1;
										current_y[0] <= current_y[1];
										current_x[1] <= current_x[1];
										current_y[1] <= current_y[1];
										current_x[2] <= current_x[1] + 4'd1;
										current_y[2] <= current_y[1];
										current_x[3] <= current_x[1] + 4'd1;
										current_y[3] <= current_y[1] + 5'd1;
										current_piece <= BLOCK_J_1;
									end
							end
							BLOCK_T_1: begin
								if (boardgrid[current_y[1] - 5'd5][4'd9 - current_x[1]] == 1'b0) begin
									current_x[0] <= current_x[1];
									current_y[0] <= current_y[1] - 5'd1;
									current_piece <= BLOCK_T_2;
								end
							end
							BLOCK_T_2: begin
								if (boardgrid[current_y[1] - 5'd4][4'd10 - current_x[1]] == 1'b0) begin
									current_x[1] <= current_x[1] - 4'd1;
									current_y[1] <= current_y[1];
									current_x[2] <= current_x[1];
									current_y[2] <= current_y[1];
									current_x[3] <= current_x[2];
									current_y[3] <= current_y[2];
									current_piece <= BLOCK_T_3;
								end
							end
							BLOCK_T_3: begin
								
								if (boardgrid[current_y[2] - 5'd3][4'd9 - current_x[2]] == 1'b0) begin
									current_x[3] <= current_x[2];
									current_y[3] <= current_y[2] + 5'd1;
									current_piece <= BLOCK_T_4;
								end
							end
							BLOCK_T_4: begin
								if (boardgrid[current_y[2] - 5'd4][4'd8 - current_x[2]] == 1'b0) begin
									current_x[0] <= current_x[1];
									current_y[0] <= current_y[1];
									current_x[1] <= current_x[2];
									current_y[1] <= current_y[2];
									current_x[2] <= current_x[2] + 4'd1;
									current_y[2] <= current_y[2];
									current_piece <= BLOCK_T_1;
								end
							end
							default: begin
								current_piece <= current_piece;
								current_x[0] <= current_x[0];
								current_x[1] <= current_x[1];
								current_x[2] <= current_x[2];
								current_x[3] <= current_x[3];
								current_y[0] <= current_y[0];
								current_y[1] <= current_y[1];
								current_y[2] <= current_y[2];
								current_y[3] <= current_y[3];
							end
						endcase
						
						STATE <= PRE_WAIT;
					end
					default: begin //NONE
					
					// Reset seconds count here
						 forceReset <= 1'b1;
						 if (!(current_y[0] == 5'd23 || current_y[1] == 5'd23 || 
							current_y[2] == 5'd23 || current_y[3] == 5'd23))
						 begin
							 boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b0;
							 boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b0;
							 boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b0;
							 boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b0;
						 end
						 else begin
							 boardgrid [current_y[0] - 5'd4][4'd9 - current_x[0]] <= 1'b1;
							 boardgrid [current_y[1] - 5'd4][4'd9 - current_x[1]] <= 1'b1;
							 boardgrid [current_y[2] - 5'd4][4'd9 - current_x[2]] <= 1'b1;
							 boardgrid [current_y[3] - 5'd4][4'd9 - current_x[3]] <= 1'b1;
						 end
						 current_y[0] <= current_y[0] + 5'd1;
						 current_y[1] <= current_y[1] + 5'd1;
						 current_y[2] <= current_y[2] + 5'd1;
						 current_y[3] <= current_y[3] + 5'd1;
						 current_x[0] <= current_x[0];
						 current_x[1] <= current_x[1];
						 current_x[2] <= current_x[2];
						 current_x[3] <= current_x[3];
						 STATE <= MOVE_ONE_DOWN;
					end
				endcase
			  end
			  MOVE_ONE_DOWN: begin
					if ((current_y[0] > 5'd3 && boardgrid[current_y[0]- 5'd4][4'd9 - current_x[0]] == 1'b1) ||
						(current_y[1] > 5'd3 && boardgrid[current_y[1] - 5'd4][4'd9 - current_x[1]] == 1'b1) ||
						(current_y[2] > 5'd3 && boardgrid[current_y[2] - 5'd4][4'd9 - current_x[2]] == 1'b1) ||
						(current_y[3] > 5'd3 && boardgrid[current_y[3] - 5'd4][4'd9 - current_x[3]] == 1'b1) ||
						current_y[0] == 5'd24 || current_y[1] == 5'd24 || 
						current_y[2] == 5'd24 || current_y[3] == 5'd24 )
						begin
							boardgrid [current_y[0] - 5'd5][4'd9 - current_x[0]] <= 1'b1;
							boardgrid [current_y[1] - 5'd5][4'd9 - current_x[1]] <= 1'b1;
							boardgrid [current_y[2] - 5'd5][4'd9 - current_x[2]] <= 1'b1;
							boardgrid [current_y[3] - 5'd5][4'd9 - current_x[3]] <= 1'b1;
							STATE <= GAME_OVER;
						end
					else
						STATE <= PRE_WAIT;
			  end
			  
			  GAME_OVER: begin
					if (current_y[0] <= 5'd3 || current_y[1] <= 5'd3 || current_y[2] <= 5'd3 || current_y[3] <= 5'd3)
					begin
						isgameover = 1'b1;
						STATE <= GAME_OVER;
					end
					else begin
						isgameover = 1'b0;
						STATE <= CHECK_COMPLETE_ROW;
					end
			  end
			  
			  CHECK_COMPLETE_ROW: begin
			  
					count_row <= 5'd0;
					case (current_piece)
							
							BLOCK_O, BLOCK_S_1, BLOCK_Z_1, BLOCK_L_1, BLOCK_L_3, BLOCK_J_1, BLOCK_J_3, BLOCK_T_1, BLOCK_T_3: begin
								if (!(boardgrid [current_y[0] - 5'd4][0] == 1'b0 || boardgrid [current_y[0] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][2] == 1'b0 || boardgrid [current_y[0] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][4] == 1'b0 || boardgrid [current_y[0] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][6] == 1'b0 || boardgrid [current_y[0] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][8] == 1'b0 || boardgrid [current_y[0] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[0] - 5'd4;
									count_row <= current_y[0] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[3] - 5'd4][0] == 1'b0 || boardgrid [current_y[3] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][2] == 1'b0 || boardgrid [current_y[3] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][4] == 1'b0 || boardgrid [current_y[3] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][6] == 1'b0 || boardgrid [current_y[3] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][8] == 1'b0 || boardgrid [current_y[3] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[3] - 5'd4;
									count_row <= current_y[3] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else begin
									delete_row <= 5'd19;
									count_row <= 5'd19;
									STATE <= PRE_GENERATE;
								end
							end
							
							BLOCK_I_1: begin
								if (!(boardgrid [current_y[0] - 5'd4][0] == 1'b0 || boardgrid [current_y[0] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][2] == 1'b0 || boardgrid [current_y[0] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][4] == 1'b0 || boardgrid [current_y[0] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][6] == 1'b0 || boardgrid [current_y[0] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][8] == 1'b0 || boardgrid [current_y[0] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[0] - 5'd4;
									count_row <= current_y[0] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else 
									delete_row <= 5'd19;
									count_row <= 5'd19;
									STATE <= PRE_GENERATE;
							end
							BLOCK_I_2: begin
								if (!(boardgrid [current_y[0] - 5'd4][0] == 1'b0 || boardgrid [current_y[0] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][2] == 1'b0 || boardgrid [current_y[0] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][4] == 1'b0 || boardgrid [current_y[0] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][6] == 1'b0 || boardgrid [current_y[0] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][8] == 1'b0 || boardgrid [current_y[0] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[0] - 5'd4;
									count_row <= current_y[0] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[1] - 5'd4][0] == 1'b0 || boardgrid [current_y[1] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][2] == 1'b0 || boardgrid [current_y[1] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][4] == 1'b0 || boardgrid [current_y[1] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][6] == 1'b0 || boardgrid [current_y[1] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][8] == 1'b0 || boardgrid [current_y[1] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[1] - 5'd4;
									count_row <= current_y[1] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[2] - 5'd4][0] == 1'b0 || boardgrid [current_y[2] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][2] == 1'b0 || boardgrid [current_y[2] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][4] == 1'b0 || boardgrid [current_y[2] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][6] == 1'b0 || boardgrid [current_y[2] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][8] == 1'b0 || boardgrid [current_y[2] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[2] - 5'd4;
									count_row <= current_y[2] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[3] - 5'd4][0] == 1'b0 || boardgrid [current_y[3] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][2] == 1'b0 || boardgrid [current_y[3] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][4] == 1'b0 || boardgrid [current_y[3] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][6] == 1'b0 || boardgrid [current_y[3] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][8] == 1'b0 || boardgrid [current_y[3] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[3] - 5'd4;
									count_row <= current_y[3] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else begin
									delete_row <= 5'd19;
									count_row <= 5'd19;
									STATE <= PRE_GENERATE;
								end
							end
							
							BLOCK_L_4, BLOCK_J_2: begin
								if (!(boardgrid [current_y[0] - 5'd4][0] == 1'b0 || boardgrid [current_y[0] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][2] == 1'b0 || boardgrid [current_y[0] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][4] == 1'b0 || boardgrid [current_y[0] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][6] == 1'b0 || boardgrid [current_y[0] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][8] == 1'b0 || boardgrid [current_y[0] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[0] - 5'd4;
									count_row <= current_y[0] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[2] - 5'd4][0] == 1'b0 || boardgrid [current_y[2] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][2] == 1'b0 || boardgrid [current_y[2] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][4] == 1'b0 || boardgrid [current_y[2] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][6] == 1'b0 || boardgrid [current_y[2] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[2] - 5'd4][8] == 1'b0 || boardgrid [current_y[2] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[2] - 5'd4;
									count_row <= current_y[2] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[3] - 5'd4][0] == 1'b0 || boardgrid [current_y[3] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][2] == 1'b0 || boardgrid [current_y[3] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][4] == 1'b0 || boardgrid [current_y[3] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][6] == 1'b0 || boardgrid [current_y[3] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][8] == 1'b0 || boardgrid [current_y[3] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[3] - 5'd4;
									count_row <= current_y[3] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else begin
									delete_row <= 5'd19;
									count_row <= 5'd19;
									STATE <= PRE_GENERATE;
								end
							end
							default: begin
								if (!(boardgrid [current_y[0] - 5'd4][0] == 1'b0 || boardgrid [current_y[0] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][2] == 1'b0 || boardgrid [current_y[0] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][4] == 1'b0 || boardgrid [current_y[0] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][6] == 1'b0 || boardgrid [current_y[0] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[0] - 5'd4][8] == 1'b0 || boardgrid [current_y[0] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[0] - 5'd4;
									count_row <= current_y[0] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[1] - 5'd4][0] == 1'b0 || boardgrid [current_y[1] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][2] == 1'b0 || boardgrid [current_y[1] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][4] == 1'b0 || boardgrid [current_y[1] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][6] == 1'b0 || boardgrid [current_y[1] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[1] - 5'd4][8] == 1'b0 || boardgrid [current_y[1] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[1] - 5'd4;
									count_row <= current_y[1] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else if (!(boardgrid [current_y[3] - 5'd4][0] == 1'b0 || boardgrid [current_y[3] - 5'd4][1] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][2] == 1'b0 || boardgrid [current_y[3] - 5'd4][3] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][4] == 1'b0 || boardgrid [current_y[3] - 5'd4][5] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][6] == 1'b0 || boardgrid [current_y[3] - 5'd4][7] == 1'b0 ||
									boardgrid [current_y[3] - 5'd4][8] == 1'b0 || boardgrid [current_y[3] - 5'd4][9] == 1'b0)) begin
									
									delete_row <= current_y[3] - 5'd4;
									count_row <= current_y[3] - 5'd5;
									STATE <= DELETE_ROW;
								end
								else begin
									delete_row <= 5'd19;
									count_row <= 5'd19;
									STATE <= PRE_GENERATE;
								end
							end
						endcase
			  end
			  
			  DELETE_ROW: begin
					if (delete_row != 5'd0) begin
						boardgrid [delete_row][0] <= boardgrid [count_row][0];
						boardgrid [delete_row][1] <= boardgrid [count_row][1];
						boardgrid [delete_row][2] <= boardgrid [count_row][2];
						boardgrid [delete_row][3] <= boardgrid [count_row][3];
						boardgrid [delete_row][4] <= boardgrid [count_row][4];
						boardgrid [delete_row][5] <= boardgrid [count_row][5];
						boardgrid [delete_row][6] <= boardgrid [count_row][6];
						boardgrid [delete_row][7] <= boardgrid [count_row][7];
						boardgrid [delete_row][8] <= boardgrid [count_row][8];
						boardgrid [delete_row][9] <= boardgrid [count_row][9];
						delete_row <= delete_row - 5'd1;
						count_row <= count_row - 5'd1;
						STATE <= DELETE_ROW;
					end
					else begin
						boardgrid [delete_row][0] <= 5'd0;
						boardgrid [delete_row][1] <= 5'd0;
						boardgrid [delete_row][2] <= 5'd0;
						boardgrid [delete_row][3] <= 5'd0;
						boardgrid [delete_row][4] <= 5'd0;
						boardgrid [delete_row][5] <= 5'd0;
						boardgrid [delete_row][6] <= 5'd0;
						boardgrid [delete_row][7] <= 5'd0;
						boardgrid [delete_row][8] <= 5'd0;
						boardgrid [delete_row][9] <= 5'd0;
						score_of_player <= score_of_player + 5'd1;
						STATE <= CHECK_COMPLETE_ROW;
					end
					
			  end
			  default:
						STATE <= INIT;
			  
		endcase
	 end
	end
				
endmodule 