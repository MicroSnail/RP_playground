`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/14/2017 07:25:34 PM
// Design Name: 
// Module Name: PID_block
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


module PID_block #(
  parameter     RESCALE_FACTOR = 15, //[CHANGE THIS AT TOP MODULE] RESCALE OUTPUTS ACCORDING TO THE FIR COEFF SCALE FACTOR
  parameter     IBW = 48        , // Input bitwidth
  parameter     PID_OBW = 14    , // PID output bitwidth, default is 14bit (DAC_BW)
  parameter     PSR = 0         , // SR = shift right
  parameter     ISR = 0         ,
  parameter     DSR = 0          
)
(
  // data
  input                           clk_i,      // clock
  input                           rstn_i,     // reset - active low
  input  signed [ IBW-1: 0]       dat_i,      // input data   (signed!)
  input  signed [ 14-1 : 0]       adc_in,
  output        [ PID_OBW-1: 0]   dat_o,      // output data  (unsigned!)

  // settings
  // input  signed [ IBW-1: 0]       set_point,  // set point
  // input  signed [ IBW-1: 0]       kp,         // Kp
  // input  signed [ IBW-1: 0]       ki,         // Ki
  // input  signed [ 14-1: 0]        kp_SR,      // Kp_result >>> kp_SR (shift right)
  // input  signed [ 14-1: 0]        ki_SR,      // int_result >>> ki_SR (shift right)

  // input                           int_rst_i,  // integrator reset

  // helper parameters, need to move these somewhere else later
  output     reg [7:0]              fir_SR_set = 15,
  output     reg                    clamp_negative2zero = 1,

  // input  signed [ IBW-1: 0]       dc_offset,  //pid_sum = p + i + d + offset
  output     [ PID_OBW-1: 0]        errorMon_o,
  output     reg [ 7:0 ]                led_o,
  //Ki, Kp enabled switches;
  input                 KiEnabled       , 
  input                 KpEnabled       ,   
  // system bus
  input      [ 32-1: 0] sys_addr        ,  //!< bus address
  input      [ 32-1: 0] sys_wdata       ,  //!< bus write data
  input      [  4-1: 0] sys_sel         ,  //!< bus write byte select
  input                 sys_wen         ,  //!< bus write enable
  input                 sys_ren         ,  //!< bus read enable
  output reg [ 32-1: 0] sys_rdata       ,  //!< bus read data
  output reg            sys_err         ,  //!< bus error indicator
  output reg            sys_ack            //!< bus acknowledge signal

  );

// settings
wire signed [ IBW-1: 0] set_point;  // set point
wire signed [ IBW-1: 0] kp;         // Kp
wire signed [ IBW-1: 0] ki;         // Ki
wire [ 14-1: 0]  kp_SR;      // Kp_result >>> kp_SR (shift right)
wire [ 14-1: 0]  ki_SR;      // int_result >>> ki_SR (shift right)

reg int_rst_i = 0;  // integrator reset


reg signed [ 32-1: 0] set_point_set = 0;  // set point
reg signed [ 32-1: 0] kp_set = 1;         // Kp
reg signed [ 32-1: 0] ki_set = 0;         // Ki
reg [ 14-1: 0] kp_SR_set = 0;      // Kp_result >>> kp_SR (shift right)
reg [ 14-1: 0] ki_SR_set = 0;      // int_result >>> ki_SR (shift right)

assign set_point  = {{(IBW-32+1){set_point_set[31]}}, set_point_set[30:0]};
assign kp         = {{(IBW-32+1){kp_set[31]}}, kp_set[30:0]};
assign ki         = {{(IBW-32+1){ki_set[31]}}, ki_set[30:0]};
assign kp_SR      = kp_SR_set;
assign ki_SR      = ki_SR_set;

//---------------------------------------------------------------------------------
//  Set point error calculation

reg  signed [IBW-1: 0] error;
wire signed [IBW-1: 0] alt_dat_in;
assign alt_dat_in = {{IBW-14+1{adc_in[13]}}, adc_in[12:0]};


always @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    error <= {IBW{1'b0}};
  end else begin
    // error <= alt_dat_in - set_point; // Filename has _neg.bit
    error <= dat_i - set_point;  // Filename has _pos.bit
  end
end

// Error signal monitor output
assign errorMon_o = {~error[IBW-1], error[12:0]};
// assign errorMon_o = {~adc_in[13], adc_in[12:0]};


//---------------------------------------------------------------------------------
//  Proportional part
reg  signed [IBW-1: 0] kp_reg        ;    //default = 29-12-1 (17 bit)
wire signed [IBW-1: 0] kp_mult       ;

always @(posedge clk_i) begin
  if ((rstn_i == 1'b0)) begin
    kp_reg  <= {IBW{1'b0}};
  end else begin
    kp_reg <= kp_mult;
  end
end

// assign kp_mult = (kp * error);
assign kp_mult = (kp * error) >>> kp_SR;


//---------------------------------------------------------------------------------
//  Integrator

reg  signed [ IBW-1: 0] ki_mult ;
wire signed [ IBW  : 0] int_sum ; 
reg  signed [ IBW-1: 0] int_reg ;

always @(posedge clk_i) begin
  if ((rstn_i == 1'b0) | ~KiEnabled) begin
    ki_mult  <= {IBW{1'b0}};
    int_reg  <= {IBW{1'b0}};
  end
  else begin
    ki_mult <= error * ki ;
    //int_sum <= $signed(ki_mult) + $signed(int_reg) ;
    
    if (int_rst_i)
      int_reg <= {IBW{1'b0}}; // reset
    else if ({int_sum[IBW:IBW-1]} == 2'b01) begin // positive saturation
      int_reg <= {1'b0, {(IBW-1){1'b1}}}; // max positive
      led_o[7:0] <= 8'b00001111;
    end else if ({int_sum[IBW:IBW-1]} == 2'b10) begin // negative saturation
      int_reg <= {1'b1, {(IBW-1){1'b0}}}; // max negative
      led_o[7:0] <= 8'b00110000;
    end else begin
      int_reg <= {int_sum[IBW], int_sum[IBW-2:0]} ; // use sum as it is
      led_o[7:0] <= 8'b11000000;
    end
  end
end

assign int_sum = ki_mult + int_reg;



//---------------------------------------------------------------------------------
//  Sum together - saturate output

wire  signed [ IBW-1: 0]       dc_offset;  //pid_sum = p + i + d + offset
reg   signed [ 32-1:0] dc_offset_set = 0;
assign dc_offset = {{(IBW-32+1){dc_offset_set[31]}}, dc_offset_set[30:0]};

wire signed [IBW: 0]      pid_sum; // biggest posible bit-width
reg         [PID_OBW-1: 0]  pid_out; 

always @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    pid_out    <= 14'd8192 ;
  end
  else begin
    //These are going to assume that pid_out is the direct output (unsigned through DAC)
    if ({pid_sum[IBW], |pid_sum[IBW-1:PID_OBW-1]} == 2'b01) //positive overflow
      pid_out <= 14'b11_1111_1111_1111; // unsigned representation
    else if ({pid_sum[IBW], &pid_sum[IBW-1:PID_OBW-1]} == 2'b10) // negative output
      pid_out <= 14'b00_0000_0000_0000;  
//    else if ({pid_sum[33-1],&pid_sum[33-2:13]} == 2'b10) //negative overflow
//       pid_out <= 14'h2000 ;
    else
      // pid_out <= {~pid_sum[IBW], pid_sum[12:0]}; // back to unsigned
      pid_out <= {~pid_sum[IBW], pid_sum[12:0]};
  end
end

// tested kp_reg alone. problem probably comes from addition and assigning?
assign pid_sum = kp_reg + (int_reg>>> ki_SR) + dc_offset;
assign dat_o = pid_out;

reg sp_manual = 0;

always @(posedge clk_i) begin
  if (rstn_i == 1'b0) begin
    set_point_set     <=   32'd0 ;
    kp_set            <=   32'd0 ;
    ki_set            <=   32'd0 ;
    kp_SR_set         <=   32'b0 ;
    ki_SR_set         <=   32'b0 ; // intetralTerm = $signed(Integrated >>> ki_SR)
    int_rst_i         <=    1'b1 ;
    sp_manual         <=    1'b1 ;
    dc_offset_set     <=   32'b0 ;
    clamp_negative2zero <= 1'b0  ;
    // adderEnabled  <=    1'b0 ;
    // sweepGain     <=   14'b0 ;
  end
  else begin
    if (sys_wen) begin
      if (sys_addr[19:0]==16'h400)    {int_rst_i} <= sys_wdata[0] ;

      if (sys_addr[19:0]==16'h404) set_point_set <= sys_wdata[32-1:0]  ;
      if (sys_addr[19:0]==16'h408) kp_set        <= sys_wdata[32-1:0]  ;
      if (sys_addr[19:0]==16'h40c) ki_set        <= sys_wdata[32-1:0]  ;
      if (sys_addr[19:0]==16'h410) kp_SR_set     <= sys_wdata[14-1:0]  ; // kp_SR * kp
      if (sys_addr[19:0]==16'h414) ki_SR_set     <= sys_wdata[14-1:0]  ; // Ki divider
      if (sys_addr[19:0]==16'h418) sp_manual     <= sys_wdata[0]       ; // sp_manual = 1 to use manual set point
      if (sys_addr[19:0]==16'h41c) dc_offset_set <= sys_wdata[32-1:0]  ; // DC offset 
      if (sys_addr[19:0]==16'h420) fir_SR_set    <= sys_wdata[32-1:0]  ; // FIR result shift right 
      if (sys_addr[19:0]==16'h420) clamp_negative2zero    <= sys_wdata[0]  ; // 1 -> clamp negative outputs to 14'b10_0000_0000_0000

      // if (sys_addr[19:0]==16'h420) pid_out       <= sys_wdata[14-1:0]  ; // DC offset 

      // if (sys_addr[19:0]==16'h420) adderEnabled  <= sys_wdata[0]       ; // PID_out + sweep
      // if (sys_addr[19:0]==16'h424) sweepGain     <= sys_wdata[15-1:0]  ; //
    end
  end
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i)
if (rstn_i == 1'b0) begin
  sys_err <= 1'b0 ;
  sys_ack <= 1'b0 ;
end else begin
  sys_err <= 1'b0 ;

  casez (sys_addr[19:0])
    20'h400 : begin sys_ack <= sys_en; sys_rdata <= {{32- 1{1'b0}}, int_rst_i} ; end 
    20'h404 : begin sys_ack <= sys_en; sys_rdata <= set_point_set ; end 
    20'h408 : begin sys_ack <= sys_en; sys_rdata <= kp_set        ; end 
    20'h40c : begin sys_ack <= sys_en; sys_rdata <= ki_set        ; end 
    20'h410 : begin sys_ack <= sys_en; sys_rdata <= kp_SR_set     ; end 
    20'h414 : begin sys_ack <= sys_en; sys_rdata <= ki_SR_set     ; end
    20'h418 : begin sys_ack <= sys_en; sys_rdata <= {{32- 1{1'b0}}, sp_manual    } ; end 
    20'h41c : begin sys_ack <= sys_en; sys_rdata <= dc_offset     ; end 
    20'h420 : begin sys_ack <= sys_en; sys_rdata <= fir_SR_set     ; end 
    20'h420 : begin sys_ack <= sys_en; sys_rdata <= clamp_negative2zero     ; end         
    // 20'h420 : begin sys_ack <= sys_en; sys_rdata <= {{14-1{1'b0}}, pid_out}     ; end 
    // 20'h420 : begin sys_ack <= sys_en; sys_rdata <= {{32- 1{1'b0}}, adderEnabled } ; end 
    // 20'h424 : begin sys_ack <= sys_en; sys_rdata <= {{32- 15{1'b0}}, sweepGain    } ; end        
    // 20'h428 : begin sys_ack <= sys_en; sys_rdata <= {}; end        
    default : begin sys_ack <= sys_en; sys_rdata <=  32'h0                     ; end
  endcase
end

endmodule
