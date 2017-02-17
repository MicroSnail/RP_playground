`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jialun Luo
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
  output logic [14-1:0] dac_dat_o  ,  // DAC combined data
  output logic          dac_wrt_o  ,  // DAC write
  output logic          dac_sel_o  ,  // DAC channel select
  output logic          dac_clk_o  ,  // DAC clock
  output logic          dac_rst_o  ,  // DAC reset
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
wire pll_clk_250;
wire pll_clk_250_n90deg;
wire pll_clk_125;
wire pll_locked;
 
clk_wiz_0 clock_PLL
  (
  // Clock out ports  
  .clk_250 	(	pll_clk_250	),
  .clk_250_n90deg 	(	pll_clk_250_n90deg	),
  .clk_125	(	pll_clk_125	),
 // Clock in ports
  .clk_in1(adc_clk_in),
  .locked(pll_locked)
  );

wire clk_250_n90deg;			//	250	MHz 45 deg phase shift
wire clk_250;			//	50	MHz
wire clk_125;			//	125	MHz

wire adc_clk = clk_125;
wire dac_clk_1x = clk_125;
wire dac_clk_2x = clk_250;
wire dac_clk_2x_n90deg = clk_250_n90deg;

BUFG bufg_clk_250_45deg   	(.O (clk_250_n90deg   ), .I (pll_clk_250_n90deg   ));
BUFG bufg_clk_125           (.O (clk_125  ), .I (pll_clk_125  ));
BUFG bufg_clk_250   	      (.O (clk_250   ), .I (pll_clk_250   ));
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

//-------------ARM chip processor---------------------------------------//

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
//////////////////////////////////////////////////////////////////////////

//-------------IO Buffering---------------------------------------------//

IOBUF iobuf_led   [8-1:0] (.IO(led_o),    .I(led_o_buf), .T(8'b0 ));

// Input with respect to the IO port, so it is from the system to IO port to outside
// if we want to use the IO port as inputs we set T = 1, use the output of the buffer
IOBUF iobuf_exp_p_1_inst (.O(exp_p_o_buf[6]), .IO(exp_p_io[6]), .T(1));
IOBUF iobuf_exp_n_1_inst (.O(exp_n_o_buf[6]), .IO(exp_n_io[6]), .T(1));
 
// assign led_o_buf = ledArray;
//////////////////////////////////////////////////////////////////////////


//-------------ADC Logics-----------------------------------------------//
assign adc_cdcs_o = 1'b1;	// Enable the duty cycle stabilizer (copied from rp code)
assign adc_clk_o = 2'b10;	// generating ADC clock is disabled

reg adc_rstn;

reg  [14-1:0] adc_dat_raw_CH1;
reg  [14-1:0] adc_dat_raw_CH2;

// These would be in signed (2's complement) format, but use $signed() whenever needed
reg signed [14-1:0] adc_dat_CH1;
reg signed [14-1:0] adc_dat_CH2;

// IO block registers should be used here (JL: ??? what does this mean?)
// lowest 2 bits reserved for 16bit ADC (JL: we don't really need to worry about this)
// adc_dat_raw's range from 0-16383, unsigned.
always @(posedge clk_125)
begin
  // unsigned ADC inputs
  adc_dat_raw_CH1 <= adc_dat_i[0][16-1:2];
  adc_dat_raw_CH2 <= adc_dat_i[1][16-1:2];

  // signed ADC inputs: 0-->16383 maps to -8192-->8191
  adc_dat_CH1 <= {~adc_dat_i[0][16-1], adc_dat_i[0][16-2:2]};
  // adc_dat_CH2 <= {~adc_dat_CH2_buf[13], adc_dat_CH2_buf[12:0]};
  adc_dat_CH2 <= {~adc_dat_i[1][16-1], adc_dat_i[1][16-2:2]};
end
// wire [14-1:0] adc_dat_CH2_buf;
// IBUF adc_dat_in_inst [14-1:0] (.I(adc_dat_i[1][16-1:2]), .O(adc_dat_CH2_buf));


// ADC reset (active low)
always @(posedge adc_clk) adc_rstn <=  pll_locked;
//////////////////////////////////////////////////////////////////////////

//-------------------------FIR FILTER-----------------------------------//
parameter FIR_OUT_BW=48;
wire signed [FIR_OUT_BW-1:0] fir_result;
wire bypass_fir;

localparam REDUCER_BW = 9;
localparam RESET_NUMBER = 250/4; // 250/4=75 * 2 = 125
reg [REDUCER_BW : 0] clk_reducer = 0;
reg slow_clk = 0;
always @(posedge clk_125) begin
  if (clk_reducer >= RESET_NUMBER) begin
    clk_reducer <= 0;
    slow_clk <= ~slow_clk;
  end else begin
    clk_reducer <= clk_reducer + 1;  
  end
end

wire fir_clk;
// assign fir_clk = clk_reducer[REDUCER_BW];
assign fir_clk = clk_125;
localparam NMAC = 60;

FIR_filter_v2 #(
    .TNN(512*NMAC),   // Total number of samples
    .ROM_DW(24),  // coefficient bitwdith
    .NMAC(NMAC),      // Number of Multiply accumulator
    .ADC_DW(14) // ADC bitwidth (14-bit for the board we are using)
  )
  filter_test
  (
    .sample_in(adc_dat_CH1),
    .result(fir_result),
    .output_refreshed(led_o_buf[0]),
    .clk(fir_clk)
  );

// assign led_o_buf[5:1] = 5'b0;
// assign led_o_buf[7:6] = fir_result[FIR_OUT_BW-1: FIR_OUT_BW-2];
// assign led_o_buf[6:0] = 7'b0;
//////////////////////////////////////////////////////////////////////////



//-------------DAC Logics-----------------------------------------------//
// NOTE: The code handling ODDR macros down there is mostly from here:
//       https://github.com/pavel-demin/red-pitaya-notes/blob/master/cores/axis_red_pitaya_dac_v1_0/axis_red_pitaya_dac.v 
reg [14-1 : 0] dac_CH1;
reg [14-1 : 0] dac_CH2;
reg dac_rst = 0;

///////////// [IMPORTANT:] CHANGE THIS PARAMETER ACCORDING TO THE SCALING FACTOR OF COEFFICIENTS /////////////
localparam FIR_SHIFT_RIGHT = 15;
wire [7:0] fir_SR;
wire [FIR_OUT_BW-1:0] fir_result_rescaled;
assign fir_result_rescaled = fir_result >>> fir_SR;

wire [14-1 : 0] dac_CH1_wire;
wire [14-1 : 0] dac_CH2_wire;

wire noNegOutputs;
wire useSweepSignal;
wire seeFIRoutput;
wire [14-1 : 0] errorMonitor;

reg [14-1: 0] fir_result_rescaled_trunc;

// Used for diagnosing the FIR filter unit
always @(posedge clk_125) begin // clip the fir_result_rescaled if it overflows // unsigned representation
  //positive overflow
  if({fir_result_rescaled[FIR_OUT_BW-1], |fir_result_rescaled[FIR_OUT_BW-2:13]}==2'b01) begin
    fir_result_rescaled_trunc <= 14'b11_1111_1111_1111;
  end else if({fir_result_rescaled[FIR_OUT_BW-1], &fir_result_rescaled[FIR_OUT_BW-2:13]}==2'b10)begin // negative overflow
    fir_result_rescaled_trunc <= 14'b0;
  end else begin 
    fir_result_rescaled_trunc <= {~fir_result_rescaled[FIR_OUT_BW-1], fir_result_rescaled[12:0]};
  end
  
end

// assign dac_CH2_wire = fir_result_rescaled_trunc[14-1] ? fir_result_rescaled_trunc : 14'b10_0000_0000_0000;
assign dac_CH2_wire = seeFIRoutput? fir_result_rescaled_trunc : errorMonitor;


wire [13:0] dac_debug_value;


// dac_CH1, CH2 should be in unsigned representation
always @(posedge dac_clk_1x)  // dac_clk_1x = 125MHz 
begin
  dac_CH1 <= noNegOutputs ? (dac_CH1_wire[14-1] ? 14'b10_0000_0000_0000 : dac_CH1_wire) : dac_CH1_wire;
  dac_CH2 <= dac_CH2_wire;
end

// DDR outputs
ODDR oddr_dac_dat [14-1:0] (.Q(dac_dat_o), .D1(dac_CH1), .D2(dac_CH2), .C(dac_clk_1x      ), .CE(1'b1), .R(1'b0), .S(1'b0));
ODDR ODDR_rst(.Q(dac_rst_o), .D1(dac_rst), .D2(dac_rst), .C(dac_clk_1x), .CE(1'b1), .R(1'b0), .S(1'b0));
ODDR ODDR_sel(.Q(dac_sel_o), .D1(1'b0), .D2(1'b1), .C(dac_clk_1x), .CE(1'b1), .R(1'b0), .S(1'b0));
ODDR ODDR_wrt(.Q(dac_wrt_o), .D1(1'b0), .D2(1'b1), .C(dac_clk_2x_n90deg), .CE(1'b1), .R(1'b0), .S(1'b0));
ODDR ODDR_clk(.Q(dac_clk_o), .D1(1'b0), .D2(1'b1), .C(dac_clk_2x_n90deg), .CE(1'b1), .R(1'b0), .S(1'b0));

// DAC reset (active high)
always @(posedge dac_clk_1x) dac_rst  <= ~pll_locked;
//////////////////////////////////////////////////////////////////////////



// Testing PID block 
PID_block #(.RESCALE_FACTOR(FIR_SHIFT_RIGHT) ) 
    pid_inst 
  (
  .clk_i        ( clk_125      ),
  .rstn_i       ( 1'b1     ),
  .sweep_in     ( adc_dat_CH2 ),
  .adc_in       ( adc_dat_CH1 ),
  // .dat_i        ( {adc_dat_CH1[13], {48-14{1'b0}}, adc_dat_CH1[12:0]}  ),
  .dat_i        ( fir_result_rescaled   ),
  .dat_o        ( dac_CH1_wire ),
  .errorMon_o   ( errorMonitor ),

  .KiEnabled    (      1     ),
  .KpEnabled    (      1     ),

  .fir_SR_set           ( fir_SR          ),
  .clamp_negative2zero  ( noNegOutputs    ),
  .adderEnabledOut      ( useSweepSignal  ),
  .dac_debug_value      ( dac_debug_value ),
  .seeFIRoutput         ( seeFIRoutput    ), // 1 -- see FIR output; 0 -- see error monitor
  // .bypass_fir           ( bypass_fir      ),

        // System bus connection 
  .sys_addr     (    sys_addr          ),
  .sys_wdata    (    sys_wdata         ),
  .sys_sel      (    sys_sel           ),
  .sys_wen      (    sys_wen[0]        ),
  .sys_ren      (    sys_ren[0]        ),
  .sys_rdata    (    sys_rdata[31 : 0] ),
  .sys_err      (    sys_err[0]        ),
  .sys_ack      (    sys_ack[0]        )  
  );

endmodule
