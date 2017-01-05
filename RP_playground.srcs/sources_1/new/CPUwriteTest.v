`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2017 12:24:47 PM
// Design Name: 
// Module Name: CPUwriteTest
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


module CPUwriteTest#(
  parameter AW = 15,    //address width
  parameter BW = 20     //data bitwidth
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
   output 		[ 7: 0] 	 testArrayOut		 ,
   input			[14-1:	0] adc_raw_in
    );
//////////////////////////////////////

// Test the system bus way?
reg [7:0] testArray = 8'b10011011;
assign testArrayOut = testArray;
// wire [20-1:0] coefficient;
wire  [3:0][BW-1:0] coeff_readout;

reg [AW-1:0] addrRequest;

// coeff_table memory (
//   .clk(clk_i),
//   .en(1),
//   .addr(addrRequest),
//   .data(coeff_readout)
// );


coeff_table coeff_table_inst (
    .clk    (  clk_i  ),
    .en     (  1  ),
    .addr   ( addrRequest  ),     // Supply 8-bit address
    .data_01 ( coeff_readout[00] ),
    .data_02 ( coeff_readout[01] ),
    .data_03 ( coeff_readout[02] ),
    .data_04 ( coeff_readout[03] )     // Supply 64-bit bus
);



//  System bus connection

always @(posedge clk_i) begin
   if (sys_wen) begin
      if (sys_addr[19:0]==20'h2ffc)   testArray       <= sys_wdata[24-1: 0] ;
      if (sys_addr[19:0]==20'h000c)   addrRequest     <= sys_wdata[24-1: 0] ;
   end
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i) begin
   sys_err <= 1'b0 ;
   casez (sys_addr[19:0])
     20'h2ffc 	:	begin sys_ack <= sys_en;         sys_rdata <= {{32-8{1'b0}}, testArray}          ; end
     20'h0000   : begin sys_ack <= sys_en;         sys_rdata <= {{32-14{1'b0}}, adc_raw_in}          ; end
     20'h0004   : begin sys_ack <= sys_en;         sys_rdata <= {{32-BW{1'b0}}, coeff_readout}          ; end
     20'h0008   : begin sys_ack <= sys_en;         sys_rdata <= {{32-BW{1'b0}}, coeff_readout}          ; end
     20'h000c   : begin sys_ack <= sys_en;         sys_rdata <= {{32-BW{1'b0}}, coeff_readout}          ; end
     20'h0010   : begin sys_ack <= sys_en;         sys_rdata <= {{32-BW{1'b0}}, coeff_readout}          ; end
     20'h0100   : begin sys_ack <= sys_en;         sys_rdata <= {{32-AW{1'b0}}, addrRequest}          ; end 
       default 	: begin sys_ack <= sys_en;         sys_rdata <=   32'h0                           ; end
   endcase
end
endmodule
