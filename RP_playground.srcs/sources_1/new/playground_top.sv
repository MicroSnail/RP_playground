`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2017 03:30:39 PM
// Design Name: 
// Module Name: playground_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module playground_top#(
  // identification
  bit [0:5*32-1] GITH = '0,
  // module numbers
  int unsigned MNA = 2,  // number of acquisition modules
  int unsigned MNG = 2   // number of generator   modules
)(
  // PS connections
  inout  logic [54-1:0] FIXED_IO_mio     ,
  inout  logic          FIXED_IO_ps_clk  ,
  inout  logic          FIXED_IO_ps_porb ,
  inout  logic          FIXED_IO_ps_srstb,
  inout  logic          FIXED_IO_ddr_vrn ,
  inout  logic          FIXED_IO_ddr_vrp ,
  // DDR
  inout  logic [15-1:0] DDR_addr   ,
  inout  logic [ 3-1:0] DDR_ba     ,
  inout  logic          DDR_cas_n  ,
  inout  logic          DDR_ck_n   ,
  inout  logic          DDR_ck_p   ,
  inout  logic          DDR_cke    ,
  inout  logic          DDR_cs_n   ,
  inout  logic [ 4-1:0] DDR_dm     ,
  inout  logic [32-1:0] DDR_dq     ,
  inout  logic [ 4-1:0] DDR_dqs_n  ,
  inout  logic [ 4-1:0] DDR_dqs_p  ,
  inout  logic          DDR_odt    ,
  inout  logic          DDR_ras_n  ,
  inout  logic          DDR_reset_n,
  inout  logic          DDR_we_n   ,

  // Red Pitaya periphery

  // ADC
  input  logic [MNA-1:0] [16-1:2] adc_dat_i,  // ADC data
  input  logic           [ 2-1:0] adc_clk_i,  // ADC clock {p,n}
  output logic           [ 2-1:0] adc_clk_o,  // optional ADC clock source (unused)
  output logic                    adc_cdcs_o, // ADC clock duty cycle stabilizer
  // // DAC
  // output logic [14-1:0] dac_dat_o  ,  // DAC combined data
  // output logic          dac_wrt_o  ,  // DAC write
  // output logic          dac_sel_o  ,  // DAC channel select
  // output logic          dac_clk_o  ,  // DAC clock
  // output logic          dac_rst_o  ,  // DAC reset
  // // PWM DAC
  // output logic [ 4-1:0] dac_pwm_o  ,  // 1-bit PWM DAC
  // // XADC
  // input  logic [ 5-1:0] vinp_i     ,  // voltages p
  // input  logic [ 5-1:0] vinn_i     ,  // voltages n
  // Expansion connector
  inout  logic [ 8-1:0] exp_p_io   ,
  inout  logic [ 8-1:0] exp_n_io   ,
  // SATA connector
  // output logic [ 2-1:0] daisy_p_o  ,  // line 1 is clock capable
  // output logic [ 2-1:0] daisy_n_o  ,
  // input  logic [ 2-1:0] daisy_p_i  ,  // line 1 is clock capable
  // input  logic [ 2-1:0] daisy_n_i  ,
  // LED
  inout  logic [ 8-1:0] led_o
);

//buffer for switches
// My two switches.... >_<
// wire [7:0] exp_p_i_buf;
// wire [7:0] exp_n_i_buf;
wire [7:0] exp_p_o_buf;
wire [7:0] exp_n_o_buf;
wire [7:0] led_o_buf;


//-------------------------CLOCKS ---------------------//
// diferential clock input
IBUFDS i_clk (.I (adc_clk_i[1]), .IB (adc_clk_i[0]), .O (adc_clk_in)); 

//clocks
wire pll_clk_50;
wire pll_clk_25;
wire pll_clk_125;
 
clk_wiz_0 inst
  (
  // Clock out ports  
  .clk_50 	(	pll_clk_50	),
  .clk_25 	(	pll_clk_25	),
  .clk_125	(	pll_clk_125	),
 // Clock in ports
  .clk_in1(adc_clk_in)
  );

wire clk_25;			//	25	MHz
wire clk_50;			//	50	MHz
wire clk_125;			//	125	MHz

BUFG bufg_clk_25   	(.O (clk_25   ), .I (pll_clk_25   ));
BUFG bufg_clk_125   (.O (clk_125  ), .I (pll_clk_125  ));
BUFG bufg_clk_50   	(.O (clk_50   ), .I (pll_clk_50   ));
//-----------------------------------------------------//

////////////////////////////////////////////////////////////////////////////////
// system bus decoder & multiplexer (it breaks memory addresses into 8 regions)
////////////////////////////////////////////////////////////////////////////////

localparam NR = 2; // number of address region?

// System bus
sys_bus_if   ps_sys       (.clk  (clk_125), .rstn    (exp_n_o_buf[6]));

wire              sys_clk   = ps_sys.clk  ;
wire              sys_rstn  = ps_sys.rstn ;
wire  [  32-1: 0] sys_addr  = ps_sys.addr ;
wire  [  32-1: 0] sys_wdata = ps_sys.wdata;
wire  [   4-1: 0] sys_sel   = 4'hf;
wire  [NR   -1: 0] sys_wen   ;
wire  [NR   -1: 0] sys_ren   ;
wire  [NR*32-1: 0] sys_rdata ;
wire  [NR* 1-1: 0] sys_err   ;
wire  [NR* 1-1: 0] sys_ack   ;
wire  [NR   -1: 0] sys_cs    ;

assign sys_cs = {NR{1'h1}} << sys_addr[22:20];

assign sys_wen = sys_cs & {NR{ps_sys.wen}};
assign sys_ren = sys_cs & {NR{ps_sys.ren}};

assign ps_sys.rdata = sys_rdata[sys_addr[22:20]*32+:32];

assign ps_sys.err   = |(sys_cs & sys_err);
assign ps_sys.ack   = |(sys_cs & sys_ack);





///////////////////////////////////////////////////////////////


processing_system ps(
    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
    .clk_125(clk_125),
    .bus(ps_sys)
  );




// ADC-related 
assign adc_cdcs_o = 1'b1;	// Enable the duty cycle stabilizer (copied from rp code)
assign adc_clk_o = 2'b10;	// generating ADC clock is disabled

reg  [14-1:0] adc_dat_raw_CH1;
reg  [14-1:0] adc_dat_raw_CH2;

// IO block registers should be used here (JL: ??? what does this mean?)
// lowest 2 bits reserved for 16bit ADC (JL: we don't really need to worry about this)
// adc_dat_raw's range from 0-16383, unsigned.
always @(posedge clk_125)
begin
  adc_dat_raw_CH1 <= adc_dat_i[0][16-1:2];
  adc_dat_raw_CH2 <= adc_dat_i[1][16-1:2];
end

// ADC reset (active low)
// always @(posedge adc_clk)
// adc_rstn <=  frstn[0] &  pll_locked;

//----------------------------------------------------------------------//

//-------------IO Buffering---------------------------------------------//

IOBUF iobuf_led   [8-1:0] (.IO(led_o),    .I(led_o_buf), .T(8'b0 ));

// Input with respect to the IO port, so it is from the system to IO port to outside
// if we want to use the IO port as inputs we set T = 1, use the output of the buffer
IOBUF iobuf_exp_p_1_inst (.O(exp_p_o_buf[6]), .IO(exp_p_io[6]), .T(1));
IOBUF iobuf_exp_n_1_inst (.O(exp_n_o_buf[6]), .IO(exp_n_io[6]), .T(1));
 
// assign led_o_buf = ledArray;

wire [31:0] fir_result;

//////////////////////////////////////////////////////////////////////////

//-------------------------FIR FILTER TEST------------------------------//
// FIR_filter_v2 #(
//     .TNN      ( 2048  ), 
//     .DW       ( 32    ),  
//     .NMAC     ( 2     )
//   )
//   fir_inst 
//   (
//     .clk    (clk_125),
//     .led_debug_out(led_o_buf),
//     // System bus connection 
//     .sys_addr     (    sys_addr          ),
//     .sys_wdata    (    sys_wdata         ),
//     .sys_sel      (    sys_sel           ),
//     .sys_wen      (    sys_wen[0]        ),
//     .sys_ren      (    sys_ren[0]        ),
//     .sys_rdata    (    sys_rdata[31 : 0]   ),
//     .sys_err      (    sys_err[0]        ),
//     .sys_ack      (    sys_ack[0]        )
//     );

FIR_filter_v2 #(
    .TNN(8192),   // Total number of samples
    .DW(32),     // Data bitwidth
    .NMAC(32),      // Number of Multiply accumulator
    .ADC_DW(14) // ADC bitwidth (14-bit for the board we are using)
  )
  filter_test
  (
    .sample_in(adc_dat_raw_CH1),
    .result(fir_result),
    .output_refreshed(led_o_buf[7]),
    .clk(clk_125)// Input clock

  );

// assign led_o_buf = fir_result[6:0];
assign led_o_buf[6:0] = 7'b0;
endmodule
