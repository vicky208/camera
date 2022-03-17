// --------------------------------------------------------------------
// Copyright (c) 2007 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
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
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//


module I2C_VCM_Config (	//	Host Side
						iCLK,
						iRST_N,
						VCM_DATA,
						ENABLE,
						END,
						
						//	I2C Side
						I2C_SCLK,
						I2C_SDAT
						);
						
//	Host Side
input			 iCLK;
input			 iRST_N;
input [15:0] VCM_DATA;
input        ENABLE;
output		 END;

//	I2C Side
inout		I2C_SCLK;
inout		   I2C_SDAT;



//	Internal Registers/Wires
reg	[23:0]	mI2C_DATA;
wire			 mI2C_CTRL_CLK;
reg			 mI2C_GO;
wire         mI2C_END;
wire	       mI2C_ACK;
reg	[3:0]	 mSetup_ST;
wire         END;


////////////////////////////////////////////////////////////////////
			
I2C_VCM_Controller  
#(
.CLK_Freq(50_000_000),//50MHz CLOCK
//I2C_Freq(100_000) // 100K
.I2C_Freq(10_000) // 10K
)u0(

	/*input  */    .CLOCK(iCLK),
	/*input  */    .RESET_N(iRST_N),	
	
	/*inout        */    .I2C_SCLK(I2C_SCLK), 
 	/*inout        */    .I2C_SDAT(I2C_SDAT), 
	/*input [23:0] */    .I2C_DATA(mI2C_DATA),	
	
	/*input       */    .GO(mI2C_GO),  
	/*output reg  */    .END(mI2C_END),	
	/*output wire */    .ACK(mI2C_ACK), 
	
	/*output wire */    .mI2C_Clock(mI2C_CTRL_CLK) 
);
					
////////////////////////////////////////////////////////////////////
//////////////////////	Config Control	////////////////////////////
reg f_trig;
reg f_trig_clear;

always@(posedge mI2C_CTRL_CLK or negedge iRST_N)
begin
	if(!iRST_N)		       f_trig  <= 1'b1;
	else if(f_trig_clear) f_trig  <= 1'b0;
end


always@(posedge mI2C_CTRL_CLK )
begin
	case(mSetup_ST)
			0:	begin
					mI2C_DATA	<=	{8'h18,VCM_DATA}; // 0x18 is VCM149C's I2C slave Addr
					if(ENABLE) begin
				   	mSetup_ST	<=	1;
						mI2C_GO		<=	1;
					end
					else begin
   					mSetup_ST	<=	0;
						mI2C_GO		<=	0;
					end
					f_trig_clear <= 1'b0;
				end
			1:	begin
					if(mI2C_END)
					begin
						if(!mI2C_ACK)
						mSetup_ST	<=	2;
						else
						mSetup_ST	<=	0;							
						mI2C_GO		<=	0;
					end
					f_trig_clear <= 1'b0;
				end
			2: begin
			    if(f_trig)  begin 
				     mSetup_ST  	<=	0;	
					  f_trig_clear <= 1'b1;
				 end
             else begin
					mSetup_ST	<=	2;	
					f_trig_clear <= 1'b0;
				 end
			 end
			default:		mSetup_ST	<=	0;
		endcase
end


assign END = (mSetup_ST==2);

endmodule
