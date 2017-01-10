`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
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

reg [13:0] sample = 0;


always @(posedge clk) begin
  sample <= sample + 1;
end

// initial begin 
//   for (int i = 0; i < 64; i++) begin
//     $display("$clog2(%0d)=%0d", i, $clog2(i));
//   end
// end



FIR_filter_v2 #(
    .TNN(2048),   // Total number of samples
    .DW(32),     // Data bitwidth
    .NMAC(64),      // Number of Multiply accumulator
    .ADC_DW(14) // ADC bitwidth (14-bit for the board we are using)
  )
  filter_inst
  (
    .sample_in(sample),
    .clk(clk)// Input clock

  );

endmodule
