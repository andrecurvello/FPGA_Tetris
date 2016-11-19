module vga_controller(iRST_n,
                      iVGA_CLK,
                      oBLANK_n,
                      oHS,
                      oVS,
                      b_data,
                      g_data,
                      r_data,
							 iboardgrid,
							 inextpiece,
							 iscoreofplayer,
							 isgameover);
							 
		//	Horizontal Parameter	( Pixel )
	parameter	H_SYNC_CYC	=	96;
	parameter	H_SYNC_BACK	=	45+3;
	parameter	H_SYNC_ACT	=	640;
	parameter	H_SYNC_FRONT=	13+3;
	parameter	H_SYNC_TOTAL=	800;

	//	Virtical Parameter		( Line )
	parameter	V_SYNC_CYC	=	2;
	parameter	V_SYNC_BACK	=	30+2;
	parameter	V_SYNC_ACT	=	480;
	parameter	V_SYNC_FRONT=	9+2;
	parameter	V_SYNC_TOTAL=	525;

	//	Start Offset
	parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK+4;
	parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;						 
							 
	//	Control Signal						
	input iRST_n;
	input iVGA_CLK;
	
	//rowinputs
	input [9:0]	  iboardgrid[0:19];
	input [15:0]  inextpiece;
	input [15:0]  iscoreofplayer;
	input			isgameover;
	
	//	VGA Side
	output oBLANK_n;
	output oHS;
	output oVS;
	output [7:0] b_data;
	output [7:0] g_data;  
	output [7:0] r_data;                        
	///////// ////                     
	reg 	[18:0] 	ADDR;
	reg 	[23:0] 	bgr_data_BG, bgr_data_GO;
	reg	[7:0]		Cur_Color_R;
	reg	[7:0]		Cur_Color_G;
	reg	[7:0]		Cur_Color_B;

	wire VGA_CLK_n;
	wire [7:0] index_BG, index_GO;
	wire [23:0] bgr_data_raw_BG, bgr_data_raw_GO;
	wire cBLANK_n,cHS,cVS,rst;
	wire [9:0] H_Cont, V_Cont;
	////
	assign rst = ~iRST_n;
	
	assign	b_data = Cur_Color_B;
	assign	g_data = Cur_Color_G;
	assign	r_data = Cur_Color_R;
	////
	video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
											.reset(rst),
											.blank_n(cBLANK_n),
											.H_Cont(H_Cont),
											.V_Cont(V_Cont),
											.HS(cHS),
											.VS(cVS));
	////
	////Addresss generator
	always@(posedge iVGA_CLK,negedge iRST_n)
	begin
	  if (!iRST_n)
		  ADDR<=19'd990;
	  else if (cHS==1'b0 && cVS==1'b0)
		  ADDR<=19'd990;
	  else if (cBLANK_n==1'b1)
		  ADDR<=ADDR+1;
	end
	//////////////////////////
	//////INDEX addr.
	assign VGA_CLK_n = ~iVGA_CLK;
	img_data	img_data_inst (
		.address ( ADDR ),
		.clock ( VGA_CLK_n ),
		.q ( index_BG )
		);
	//////Color table output
	img_index	img_index_inst (
		.address ( index_BG ),
		.clock ( iVGA_CLK ),
		.q ( bgr_data_raw_BG)
		);	
	//////
	
	game_over_data	game_over_data_inst (
		.address ( ADDR ),
		.clock ( VGA_CLK_n ),
		.q ( index_GO )
		);
	//////Color table output
	game_over_index	game_over_index_inst (
		.address ( index_GO ),
		.clock ( iVGA_CLK ),
		.q ( bgr_data_raw_GO)
		);	
	//////
	
	//////latch valid data at falling edge;
	
	
	always@(posedge VGA_CLK_n) begin
	
		bgr_data_BG <= bgr_data_raw_BG;
		bgr_data_GO <= bgr_data_raw_GO;
	end

	always@(posedge VGA_CLK_n or negedge iRST_n)
	begin
		if(!iRST_n)
		begin
			Cur_Color_R	<=	0;
			Cur_Color_G	<=	0;
			Cur_Color_B	<=	0;
		end
		else
		begin
			if(	H_Cont>=X_START+8 && H_Cont<X_START+H_SYNC_ACT+8 &&
				V_Cont>=Y_START && V_Cont<Y_START+V_SYNC_ACT )
			begin
				//**********************************************************************
				//******************** Show Playing Grid  ******************************
				//**********************************************************************
				
				if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 420 ) && ((V_Cont - Y_START) < 440)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[19][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//*************************************************************************************
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 400 ) && ((V_Cont - Y_START) < 420)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[18][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//**********************************************************************************************************
				
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 380 ) && ((V_Cont - Y_START) < 400)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[17][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				
				//*************************************************
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 360 ) && ((V_Cont - Y_START) < 380)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[16][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//*************************************************************************************
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 340 ) && ((V_Cont - Y_START) < 360)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[15][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//**********************************************************************************************************
				
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 320 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[14][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				
				//*************************************************
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 300 ) && ((V_Cont - Y_START) < 320)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[13][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//*************************************************************************************
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 280 ) && ((V_Cont - Y_START) < 300)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[12][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//**********************************************************************************************************
				
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 260 ) && ((V_Cont - Y_START) < 280)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[11][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				
				
				//*************************************************
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 240 ) && ((V_Cont - Y_START) < 260)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[10][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//*************************************************************************************
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 240)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[9][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//**********************************************************************************************************
				
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 200 ) && ((V_Cont - Y_START) < 220)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[8][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				
				
				//*************************************************
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 180 ) && ((V_Cont - Y_START) < 200)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[7][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//*************************************************************************************
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 160 ) && ((V_Cont - Y_START) < 180)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[6][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				
				//**********************************************************************************************************
				
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 140 ) && ((V_Cont - Y_START) < 160)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[5][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 120 ) && ((V_Cont - Y_START) < 140)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[4][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 100 ) && ((V_Cont - Y_START) < 120)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[3][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 80 ) && ((V_Cont - Y_START) < 100)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[2][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 60 ) && ((V_Cont - Y_START) < 80)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[1][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 60 ) && ((H_Cont - X_START) < 80)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][9]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 80 ) && ((H_Cont - X_START) < 100)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][8]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 100 ) && ((H_Cont - X_START) < 120)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][7]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 120 ) && ((H_Cont - X_START) < 140)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][6]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 140 ) && ((H_Cont - X_START) < 160)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][5]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 160 ) && ((H_Cont - X_START) < 180)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][4]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 180 ) && ((H_Cont - X_START) < 200)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][3]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 200 ) && ((H_Cont - X_START) < 220)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][2]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 220 ) && ((H_Cont - X_START) < 240)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][1]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				else if( (((V_Cont - Y_START) > 40 ) && ((V_Cont - Y_START) < 60)) && (((H_Cont - X_START) > 240 ) && ((H_Cont - X_START) < 260)) )
				begin
					
					Cur_Color_R	<=	{8{iboardgrid[0][0]}} ;
					Cur_Color_G	<=	0 ;
					Cur_Color_B	<=	8'h7f;
				end
				
				//**********************************************************************
				//*****************   the next piece generation   **********************
				//**********************************************************************
				
				else if( (((V_Cont - Y_START) > 130 ) && ((V_Cont - Y_START) < 150)) && (((H_Cont - X_START) > 280 ) && ((H_Cont - X_START) < 300)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[3]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 130 ) && ((V_Cont - Y_START) < 150)) && (((H_Cont - X_START) > 300 ) && ((H_Cont - X_START) < 320)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[2]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 130 ) && ((V_Cont - Y_START) < 150)) && (((H_Cont - X_START) > 320 ) && ((H_Cont - X_START) < 340)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[1]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 130 ) && ((V_Cont - Y_START) < 150)) && (((H_Cont - X_START) > 340 ) && ((H_Cont - X_START) < 360)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[0]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 110 ) && ((V_Cont - Y_START) < 130)) && (((H_Cont - X_START) > 280 ) && ((H_Cont - X_START) < 300)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[7]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 110 ) && ((V_Cont - Y_START) < 130)) && (((H_Cont - X_START) > 300 ) && ((H_Cont - X_START) < 320)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[6]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 110 ) && ((V_Cont - Y_START) < 130)) && (((H_Cont - X_START) > 320 ) && ((H_Cont - X_START) < 340)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[5]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 110 ) && ((V_Cont - Y_START) < 130)) && (((H_Cont - X_START) > 340 ) && ((H_Cont - X_START) < 360)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[4]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 90 ) && ((V_Cont - Y_START) < 110)) && (((H_Cont - X_START) > 280 ) && ((H_Cont - X_START) < 300)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[11]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 90 ) && ((V_Cont - Y_START) < 110)) && (((H_Cont - X_START) > 300 ) && ((H_Cont - X_START) < 320)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[10]}} ;
					Cur_Color_B	<=	0;
				end
				else if( (((V_Cont - Y_START) > 90 ) && ((V_Cont - Y_START) < 110)) && (((H_Cont - X_START) > 320 ) && ((H_Cont - X_START) < 340)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[9]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 90 ) && ((V_Cont - Y_START) < 110)) && (((H_Cont - X_START) > 340 ) && ((H_Cont - X_START) < 360)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[8]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 70 ) && ((V_Cont - Y_START) < 90)) && (((H_Cont - X_START) > 280 ) && ((H_Cont - X_START) < 300)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[15]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 70 ) && ((V_Cont - Y_START) < 90)) && (((H_Cont - X_START) > 300 ) && ((H_Cont - X_START) < 320)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[14]}} ;
					Cur_Color_B	<=	0;
				end
				else if( (((V_Cont - Y_START) > 70 ) && ((V_Cont - Y_START) < 90)) && (((H_Cont - X_START) > 320 ) && ((H_Cont - X_START) < 340)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[13]}} ;
					Cur_Color_B	<=	0;
				end
				
				else if( (((V_Cont - Y_START) > 70 ) && ((V_Cont - Y_START) < 90)) && (((H_Cont - X_START) > 340 ) && ((H_Cont - X_START) < 360)) )
				begin
					
					Cur_Color_R	<=	0 ;
					Cur_Color_G	<=	{8{inextpiece[12]}} ;
					Cur_Color_B	<=	0;
				end
				
				//**********************************************************************
				//*****************   the score generation   ***************************
				//**********************************************************************
				
				else if( (((V_Cont - Y_START) > 205 ) && ((V_Cont - Y_START) < 340)) && (((H_Cont - X_START) > 270 ) && ((H_Cont - X_START) < 370)) )
				begin
					if((((H_Cont - X_START) > 280 ) && ((H_Cont - X_START) < 300)))
					begin
						 if(((V_Cont - Y_START) == 210 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[0]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if(((V_Cont - Y_START) == 220 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[6]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if(((V_Cont - Y_START) == 230 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[3]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 210 ) && ((V_Cont - Y_START) < 220)) && ((H_Cont - X_START) == 281 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[5]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 210 ) && ((V_Cont - Y_START) < 220)) && ((H_Cont - X_START) == 299 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[1]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 230)) && ((H_Cont - X_START) == 281 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[4]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 230)) && ((H_Cont - X_START) == 299 ))
						 begin
							 Cur_Color_R	<=	{8{digit3[2]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else
						 begin
							 Cur_Color_R	<=	8'h26 ;
							 Cur_Color_G	<=	8'h1D ;
							 Cur_Color_B	<=	8'h09;
						 end

					end
					
					else if((((H_Cont - X_START) > 310 ) && ((H_Cont - X_START) < 330)))
					begin
					if(((V_Cont - Y_START) == 210 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[0]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if(((V_Cont - Y_START) == 220 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[6]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if(((V_Cont - Y_START) == 230 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[3]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 210 ) && ((V_Cont - Y_START) < 220)) && ((H_Cont - X_START) == 311 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[5]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 210 ) && ((V_Cont - Y_START) < 220)) && ((H_Cont - X_START) == 329 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[1]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 230)) && ((H_Cont - X_START) == 311 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[4]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 230)) && ((H_Cont - X_START) == 329 ))
						 begin
							 Cur_Color_R	<=	{8{digit2[2]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else
						 begin
							 Cur_Color_R	<=	8'h26 ;
							 Cur_Color_G	<=	8'h1D ;
							 Cur_Color_B	<=	8'h09;
						  end
					end
					
					else if((((H_Cont - X_START) > 340 ) && ((H_Cont - X_START) < 360)))
					begin
					if(((V_Cont - Y_START) == 210 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[0]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if(((V_Cont - Y_START) == 220 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[6]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if(((V_Cont - Y_START) == 230 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[3]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 210 ) && ((V_Cont - Y_START) < 220)) && ((H_Cont - X_START) == 341 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[5]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 210 ) && ((V_Cont - Y_START) < 220)) && ((H_Cont - X_START) == 359 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[1]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 230)) && ((H_Cont - X_START) == 341 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[4]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else if ((((V_Cont - Y_START) > 220 ) && ((V_Cont - Y_START) < 230)) && ((H_Cont - X_START) == 359 ))
						 begin
							 Cur_Color_R	<=	{8{digit1[2]}} ;
							 Cur_Color_G	<=	0 ;
							 Cur_Color_B	<=	0 ; 
						 end
						 
						 else
						 begin
							Cur_Color_R	<=	8'h26 ;
							Cur_Color_G	<=	8'h1D ;
							Cur_Color_B	<=	8'h09;
						  end

					end
					
					else 
					begin
						Cur_Color_R	<=	8'h26 ;
						Cur_Color_G	<=	8'h1D ;
						Cur_Color_B	<=	8'h09;
					end
				end 
				 
				//***************************************************************************
				else
				begin
					Cur_Color_R	<=	bgr_data_BG[23:16];
					Cur_Color_G	<=	bgr_data_BG[15:8];
					Cur_Color_B	<=	bgr_data_BG[7:0];
				end
				
				//Draw GAME OVER
				if (isgameover) begin
					if (bgr_data_GO != 24'd0) begin
						Cur_Color_R	<=	bgr_data_GO[23:16];
						Cur_Color_G	<=	bgr_data_GO[15:8];
						Cur_Color_B	<=	bgr_data_GO[7:0];
					end
				end
			end
			else begin
				Cur_Color_R	<=	8'd0 ;
				Cur_Color_G	<=	8'd0 ;
				Cur_Color_B	<=	8'd0;
			end
		end
	end

	//////Delay the iHD, iVD,iDEN for one clock cycle;

	reg [4:0] delay_bus;
	reg [4:0] delay_busv;
	reg [4:0] delay_bush;

	always@(posedge VGA_CLK_n or negedge iRST_n)
	begin
		if (!iRST_n)
			begin
				delay_bus <= 0;
				delay_busv <= 0;
				delay_bush <= 0;

			end
		else
			begin
				delay_bus <= {delay_bus[3:0],cBLANK_n};
				delay_bush <= {delay_bush[3:0],cHS};
				delay_busv <= {delay_busv[3:0],cVS};
				
				
			end
	end

	assign oBLANK_n = delay_bus[1];
	assign oHS = delay_bush[1];
	assign oVS = delay_busv[1];
	
	//digit logic calculation for display score
	reg [6:0] digit1 , digit2, digit3 ;
	wire [6:0] tdigit0 ,  tdigit1 , tdigit2 , tdigit3 , tdigit4 , tdigit5 , tdigit6 , tdigit7 , tdigit8 , tdigit9 ;

	hexout u1(iscoreofplayer       , tdigit0) ; 
	hexout u2(iscoreofplayer - 10  , tdigit1) ;
	hexout u3(iscoreofplayer - 20  , tdigit2) ;
	hexout u4(iscoreofplayer - 30  , tdigit3) ;
	hexout u5(iscoreofplayer - 40  , tdigit4) ;
	hexout u6(iscoreofplayer - 50  , tdigit5) ;
	hexout u7(iscoreofplayer - 60  , tdigit6) ;
	hexout u8(iscoreofplayer - 70  , tdigit7) ;
	hexout u9(iscoreofplayer - 80  , tdigit8) ;
	hexout u10(iscoreofplayer - 90  , tdigit9) ;



	always @ (*)
	begin
		if (iscoreofplayer < 10) 
		begin 
		digit1 = tdigit0  ; 
		digit2 = 7'b0111111 ;
		digit3 = 7'b0111111 ;  
		end

		else if (iscoreofplayer < 20) 
		begin
		digit1 = tdigit1  ; 
		digit2 = 7'b0000110 ;
		digit3 = 7'b0111111 ;
		end

		else if (iscoreofplayer < 30) 
		begin 
		digit1 = tdigit2  ; 
		digit2 = 7'b1011011 ; 
		digit3 = 7'b0111111 ;
		end

		else if (iscoreofplayer < 40) 
		begin 
		digit1 = tdigit3  ; 
		digit2 = 7'b1001111 ; 
		digit3 = 7'b0111111 ;
		end


		else if (iscoreofplayer < 50) 
		begin 
		digit1 = tdigit4  ; 
		digit2 = 7'b1100110 ;  
		digit3 = 7'b0111111 ;
		end


		else if (iscoreofplayer < 60) 
		begin 
		digit1 = tdigit5  ; 
		digit2 = 7'b1101101 ; 
		digit3 = 7'b0111111 ;
		end


		else if (iscoreofplayer < 70) 
		begin 
		digit1 = tdigit6  ; 
		digit2 = 7'b1111101 ;
		digit3 = 7'b0111111 ; 
		end

		else if (iscoreofplayer < 80) 
		begin 
		digit1 = tdigit7  ; 
		digit2 = 7'b0000111 ; 
		digit3 = 7'b0111111 ;
		end

		else if (iscoreofplayer < 90) 
		begin 
		digit1 = tdigit8  ; 
		digit2 = 7'b1111111 ;
		digit3 = 7'b0111111 ;
		end

		else if (iscoreofplayer < 100) 
		begin 
		digit1 = tdigit9  ; 
		digit2 = 7'b1100111 ; 
		digit3 = 7'b0111111 ;
		end

	end


endmodule
 	
//***************************for the scoring display**************************************************
module hexout(
input wire [15:0] value , 
output reg  [6:0] outvalue
);

wire [3:0] tempvalue ; 
assign tempvalue = value[3:0] ; 


always @ (value)
 case(tempvalue)
	4'd0 : outvalue = 7'b0111111 ; 
	4'd1 : outvalue = 7'b0000110 ; 
	4'd2 : outvalue = 7'b1011011 ; 
	4'd3 : outvalue = 7'b1001111 ; 
	4'd4 : outvalue = 7'b1100110 ; 
	4'd5 : outvalue = 7'b1101101 ; 
	4'd6 : outvalue = 7'b1111101 ; 
	4'd7 : outvalue = 7'b0000111 ; 
	4'd8 : outvalue = 7'b1111111 ; 
	4'd9 : outvalue = 7'b1100111 ; 
    default : outvalue = 7'b0111111 ;
 endcase 

endmodule 
















