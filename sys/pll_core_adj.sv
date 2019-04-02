// ElectronAsh. 1-4-19.
//
//
module pll_core_adj (
	input wire clk_sys,
	input wire reset_n,

	input wire ntsc,

	input wire        core_cfg_waitrequest,
	output reg        core_cfg_write,
	output wire [5:0] core_cfg_address,
	output wire [31:0] core_cfg_data,
	
	output wire core_cfg_running
);

assign core_cfg_address = (ntsc) ? init_data_ntsc[ data_index ][37:32] : init_data_pal[ data_index ][37:32];
assign core_cfg_data    = (ntsc) ? init_data_ntsc[ data_index ][31:0]  : init_data_pal[ data_index ][31:0];

assign core_cfg_running = cfg_state>0;


parameter DATA_COUNT = 10;

parameter C0_ADDR = 5'b00000;
parameter C1_ADDR = 5'b00001;
parameter C2_ADDR = 5'b00010;
parameter RCFG_MODE = 1'b0;			// Mode register (0=waitrequest. 1=polling).


parameter [7:0] NTSC_M_CNT_HI  = 8'h05;		// M counter. [15:8]=Hi count.
parameter [7:0] NTSC_M_CNT_LO  = 8'h04;		// M counter. [7:0]=Lo count.
parameter 		 NTSC_M_CNT_BYP = 1'b0;			// M counter. [16]=Bypass.
parameter 		 NTSC_M_CNT_ODD = 1'b1;			// M counter. [17]=Odd division.

parameter [7:0] NTSC_N_CNT_HI  = 8'h00;		// N counter. [15:8]=Hi count.
parameter [7:0] NTSC_N_CNT_LO  = 8'h00;		// N counter. [15:8]=Lo count.
parameter 		 NTSC_N_CNT_BYP = 1'b1;			// N counter. [16]=Bypass.
parameter 		 NTSC_N_CNT_ODD = 1'b0;			// N counter. [17]=Odd division.

// C counter 0 (SDRAM Controller clock). ~64 MHz.
parameter [7:0]  NTSC_C_CNT0_HI  = 8'h04;		// C counter. [15:8]=Hi count.
parameter [7:0]  NTSC_C_CNT0_LO  = 8'h03;		// C counter. [7:0]=Lo count.
parameter 		  NTSC_C_CNT0_BYP = 1'b0;		// C counter. [16]=Bypass.
parameter 		  NTSC_C_CNT0_ODD = 1'b1;		// C counter. [17]=Odd division.
parameter [15:0] NTSC_C_CNT0_SFT = 16'h0001;	// [15:0]=Shift amount.
parameter 		  NTSC_C_CNT0_POS = 1'b0;		// [21]=Shift direction. (0=Negative shift. 1=Positive shift.)

// C counter 1 (SDRAM chip clock). ~64 MHz, with negative -4365ps phase shift.
parameter [7:0]  NTSC_C_CNT1_HI  = 8'h04;		// C counter. [15:8]=Hi count.
parameter [7:0]  NTSC_C_CNT1_LO  = 8'h03;		// C counter. [7:0]=Lo count.
parameter 		  NTSC_C_CNT1_BYP = 1'b0;		// C counter. [16]=Bypass.
parameter 		  NTSC_C_CNT1_ODD = 1'b1;		// C counter. [17]=Odd division.
parameter [15:0] NTSC_C_CNT1_SFT = 16'h0006;	// [15:0]=Shift amount.
parameter 		  NTSC_C_CNT1_POS = 1'b0;		// [21]=Shift direction. (0=Negative shift. 1=Positive shift.)

// C counter 2 (Core clock). ~32 MHz.
parameter [7:0]  NTSC_C_CNT2_HI  = 8'h07;		// C counter. [15:8]=Hi count.
parameter [7:0]  NTSC_C_CNT2_LO  = 8'h07;		// C counter. [7:0]=Lo count.
parameter 		  NTSC_C_CNT2_BYP = 1'b0;		// C counter. [16]=Bypass.
parameter 		  NTSC_C_CNT2_ODD = 1'b0;		// C counter. [17]=Odd division.
parameter [15:0] NTSC_C_CNT2_SFT = 16'h0001;	// [15:0]=Shift amount.
parameter 		  NTSC_C_CNT2_POS = 1'b0;		// [21]=Shift direction. (0=Negative shift. 1=Positive shift.)


parameter NTSC_M_FRAC  = 32'h29E3FC13;	// Fractional part of the M counter (for DSM). MFRAC=K[(X-1):0]/2X (X = 8, 16,24, or 32).
parameter NTSC_BWIDTH  = 32'h00000007;	// Bandwidth setting.
parameter NTSC_PUMP_VAL= 32'h00000002;	// Charge Pump setting.
parameter NTSC_VCO_DIV = 32'h00000008;	// VCO DIV setting.


wire [37:0] init_data_ntsc [DATA_COUNT] = 
'{
	{6'b000000, 31'h0000000, RCFG_MODE},
	
	{6'b000011, 14'h0000, NTSC_N_CNT_ODD, NTSC_N_CNT_BYP, NTSC_N_CNT_HI, NTSC_N_CNT_LO},
	{6'b000100, 14'h0000, NTSC_M_CNT_ODD, NTSC_M_CNT_BYP, NTSC_M_CNT_HI, NTSC_M_CNT_LO},

	{6'b000101, 9'h00, C0_ADDR, NTSC_C_CNT0_ODD, NTSC_C_CNT0_BYP,  NTSC_C_CNT0_HI, NTSC_C_CNT0_LO},	// [22:18]=Index of C counter to change!
	//{6'b000110, 11'h000,  NTSC_C_CNT0_POS, C0_ADDR, NTSC_C_CNT0_SFT},
	
	{6'b000101, 9'h00, C1_ADDR, NTSC_C_CNT1_ODD, NTSC_C_CNT1_BYP,  NTSC_C_CNT1_HI, NTSC_C_CNT1_LO},	// [22:18]=Index of C counter to change!
	//{6'b000110, 11'h000,  NTSC_C_CNT1_POS, C1_ADDR, NTSC_C_CNT1_SFT},

	{6'b000101, 9'h00, C2_ADDR, NTSC_C_CNT2_ODD, NTSC_C_CNT2_BYP,  NTSC_C_CNT2_HI, NTSC_C_CNT2_LO},	// [22:18]=Index of C counter to change!
	//{6'b000110, 11'h000,  NTSC_C_CNT2_POS, C2_ADDR, NTSC_C_CNT2_SFT},
	
	{6'b000111, NTSC_M_FRAC},
	{6'b001000, NTSC_BWIDTH},
	{6'b001001, NTSC_PUMP_VAL},
	//{6'b011100, NTSC_VCO_DIV},
	
	{6'b000010, 32'h00000001}		// Start Register. Write 0 or 1 (anything?) to start fractional PLL reconfig.
};




parameter [7:0] PAL_M_CNT_HI  = 8'd6;			// M counter. [15:8]=Hi count.
parameter [7:0] PAL_M_CNT_LO  = 8'd6;			// M counter. [7:0]=Lo count.
parameter 		 PAL_M_CNT_BYP = 1'b0;			// M counter. [16]=Bypass.
parameter 		 PAL_M_CNT_ODD = 1'b0;			// M counter. [17]=Odd division.

parameter [7:0] PAL_N_CNT_HI  = 8'd0;			// N counter. [15:8]=Hi count.
parameter [7:0] PAL_N_CNT_LO  = 8'd0;			// N counter. [15:8]=Lo count.
parameter 		 PAL_N_CNT_BYP = 1'b1;			// N counter. [16]=Bypass.
parameter 		 PAL_N_CNT_ODD = 1'b0;			// N counter. [17]=Odd division.

// C counter 0 (SDRAM Controller clock). ~64 MHz.
parameter [7:0]  PAL_C_CNT0_HI  = 8'd5;		// C counter. [15:8]=Hi count.
parameter [7:0]  PAL_C_CNT0_LO  = 8'd5;		// C counter. [7:0]=Lo count.
parameter 		  PAL_C_CNT0_BYP = 1'b0;		// C counter. [16]=Bypass.
parameter 		  PAL_C_CNT0_ODD = 1'b0;		// C counter. [17]=Odd division.
parameter [15:0] PAL_C_CNT0_SFT = 16'h0001;	// [15:0]=Shift amount.
parameter 		  PAL_C_CNT0_POS = 1'b0;		// [21]=Shift direction. (0=Negative shift. 1=Positive shift.)

// C counter 1 (SDRAM chip clock). ~64 MHz, with negative -4365ps phase shift.
parameter [7:0]  PAL_C_CNT1_HI  = 8'd5;		// C counter. [15:8]=Hi count.
parameter [7:0]  PAL_C_CNT1_LO  = 8'd5;		// C counter. [7:0]=Lo count.
parameter 		  PAL_C_CNT1_BYP = 1'b0;		// C counter. [16]=Bypass.
parameter 		  PAL_C_CNT1_ODD = 1'b0;		// C counter. [17]=Odd division.
parameter [15:0] PAL_C_CNT1_SFT = 16'h0008;	// [15:0]=Shift amount.
parameter 		  PAL_C_CNT1_POS = 1'b0;		// [21]=Shift direction. (0=Negative shift. 1=Positive shift.)

// C counter 2 (Core clock). ~32 MHz.
parameter [7:0]  PAL_C_CNT2_HI  = 8'd10;		// C counter. [15:8]=Hi count.
parameter [7:0]  PAL_C_CNT2_LO  = 8'd10;		// C counter. [7:0]=Lo count.
parameter 		  PAL_C_CNT2_BYP = 1'b0;		// C counter. [16]=Bypass.
parameter 		  PAL_C_CNT2_ODD = 1'b0;		// C counter. [17]=Odd division.
parameter [15:0] PAL_C_CNT2_SFT = 16'h0001;	// [15:0]=Shift amount.
parameter 		  PAL_C_CNT2_POS = 1'b0;		// [21]=Shift direction. (0=Negative shift. 1=Positive shift.)


parameter PAL_M_FRAC  = 32'h9C766C6E;	// Fractional part of the M counter (for DSM). MFRAC=K[(X-1):0]/2X (X = 8, 16,24, or 32).
parameter PAL_BWIDTH  = 32'h00000008;	// Bandwidth setting.
parameter PAL_PUMP_VAL= 32'h00000003;	// Charge Pump setting.
parameter PAL_VCO_DIV = 32'h00000008;	// VCO DIV setting.


wire [37:0] init_data_pal [DATA_COUNT] = 
'{
	{6'b000000, 31'h0000000, RCFG_MODE},
	
	{6'b000011, 14'h0000, PAL_N_CNT_ODD, PAL_N_CNT_BYP, PAL_N_CNT_HI, PAL_N_CNT_LO},
	{6'b000100, 14'h0000, PAL_M_CNT_ODD, PAL_M_CNT_BYP, PAL_M_CNT_HI, PAL_M_CNT_LO},

	{6'b000101, 9'h00, C0_ADDR, PAL_C_CNT0_ODD, PAL_C_CNT0_BYP,  PAL_C_CNT0_HI, PAL_C_CNT0_LO},	// [22:18]=Index of C counter to change!
	//{6'b000110, 11'h000,  PAL_C_CNT0_POS, C0_ADDR, PAL_C_CNT0_SFT},
	
	{6'b000101, 9'h00, C1_ADDR, PAL_C_CNT1_ODD, PAL_C_CNT1_BYP,  PAL_C_CNT1_HI, PAL_C_CNT1_LO},	// [22:18]=Index of C counter to change!
	//{6'b000110, 11'h000,  PAL_C_CNT1_POS, C1_ADDR, PAL_C_CNT1_SFT},

	{6'b000101, 9'h00, C2_ADDR, PAL_C_CNT2_ODD, PAL_C_CNT2_BYP,  PAL_C_CNT2_HI, PAL_C_CNT2_LO},	// [22:18]=Index of C counter to change!
	//{6'b000110, 11'h000,  PAL_C_CNT2_POS, C2_ADDR, PAL_C_CNT2_SFT},
	
	{6'b000111, PAL_M_FRAC},
	{6'b001000, PAL_BWIDTH},
	{6'b001001, PAL_PUMP_VAL},
	//{6'b011100, PAL_VCO_DIV},
	
	{6'b000010, 32'h00000001}		// Start Register. Write 0 or 1 (anything?) to start fractional PLL reconfig.
};



reg ntsc_1, ntsc_2;

reg [1:0] cfg_state;
reg [5:0] data_index;

always @(posedge clk_sys) begin
	ntsc_1 <= ntsc;
	ntsc_2 <= ntsc_1;
	
	if (!reset_n) begin
		cfg_state <= 2'd0;
		core_cfg_write <= 1'b0;
	end


	case (cfg_state)
	0: if (ntsc_1 != ntsc_2) begin
		data_index <= 6'd0;
		cfg_state <= cfg_state + 1'b1;
	end
	
	1: if (!core_cfg_waitrequest) begin
		if (data_index<DATA_COUNT) begin
			cfg_state <= cfg_state + 1'b1;
		end
		else cfg_state <= 2'd0;
	end
	
	2: begin
		core_cfg_write <= 1'b1;
		cfg_state <= cfg_state + 1'b1;
	end
	
	3: begin
		core_cfg_write <= 1'b0;
		cfg_state <= cfg_state + 1'b1;
	end

	4: begin
		data_index <= data_index + 1;
		cfg_state <= 2'd1;	// Loop back.
	end
	
	endcase
end


endmodule
