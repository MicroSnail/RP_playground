`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/12/2017 02:21:19 PM
// Design Name: 
// Module Name: DAC_study
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


module DAC_study#(
  parameter AW = 9,    //  address width
  parameter BW = 32,    //  data bitwidth
  parameter NMAC = 64,   //  number of MACs
  parameter DAC_DW =14
  )(
   // ADC
   input                 clk_i           ,  // clock
   // system bus
   input      [ 32-1: 0] sys_addr        ,  // bus address
   input      [ 32-1: 0] sys_wdata       ,  // bus write data
   input      [  4-1: 0] sys_sel         ,  // bus write byte select
   input                 sys_wen         ,  // bus write enable
   input                 sys_ren         ,  // bus read enable
   output reg [ 32-1: 0] sys_rdata       ,  // bus read data
   output reg            sys_err         ,  // bus error indicator
   output reg            sys_ack         ,  // bus acknowledge signal
   output reg [DAC_DW-1 : 0]    dac_test_CH1,    
   output reg [DAC_DW-1 : 0]    dac_test_CH2    
    );
// assign testArrayOut = testArray;
// reg [DAC_DW -1 : 0] testArray = 0;
wire sys_en;
assign sys_en = sys_wen | sys_ren;

//  System bus connection
always @(posedge clk_i) begin
   if (sys_wen) begin
      if (sys_addr[19:0]==20'h00fc)   dac_test_CH1       <= sys_wdata[24-1: 0] ;
      if (sys_addr[19:0]==20'h00ec)   dac_test_CH2       <= sys_wdata[24-1: 0] ;
   end
end


always @(posedge clk_i) begin
   sys_err <= 1'b0 ;
   casez (sys_addr[19:0])
     20'h00fc   : begin sys_ack <= sys_en;  sys_rdata <= {{32-DAC_DW{1'b0}}, dac_test_CH1}          ; end
     20'h00ec   : begin sys_ack <= sys_en;  sys_rdata <= {{32-DAC_DW{1'b0}}, dac_test_CH2}          ; end
       default  : begin sys_ack <= sys_en;  sys_rdata <=   32'h0                           ; end
   endcase
end
endmodule
