`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jialun Luo
// 
// Create Date: 01/07/2017 11:19:44 PM
// Design Name: 
// Module Name: FIR_filter_v2_TB
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


module FIR_filter_v2_TB(

    );

reg clk = 0;
always 
#5 clk <= ~clk;

reg signed [13:0] sample = -500;

reg signed [13:0] addsub = 1;
always @(posedge clk) begin
  // if (sample >= 49) begin 
  //   addsub <= -1;
  // end else if (sample <= -49) begin 
  //   addsub <= 1;
  // end
  sample <= sample + addsub;
end





FIR_filter_v2 #(
    .TNN(40),   // Total number of samples
    .ROM_DW(18),
    .NMAC(5),      // Number of Multiply accumulator
    .ADC_DW(14) // ADC bitwidth (14-bit for the board we are using)
  )
  filter_inst
  (
    .sample_in(sample),
    .clk(clk)// Input clock

  );

endmodule
