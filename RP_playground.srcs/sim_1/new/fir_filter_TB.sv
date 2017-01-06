`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/05/2017 11:52:55 AM
// Design Name: 
// Module Name: fir_filter_TB
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


module fir_filter_TB(

    );

parameter BW = 32     ;            //data width
parameter OBW = BW  ;        //output width
parameter NDMAC= 16   ;        //number of data each MA
parameter NMAC = 4    ;       //number of MACs

parameter SBW = 14; // sample bitwidth

reg clk=0;
wire [OBW - 1 : 0] result;

always  
  #5 clk <= ~clk;
 

reg [SBW-1 : 0] sample = 0;

always @(posedge clk) begin
  sample <= sample + 1;
end


FIR_filter DUT(
  .datIn({  {BW - SBW{1'b0}}, sample  }),
  .datOut(result),
  .clk(clk),
  .rst(0)
  );

endmodule
