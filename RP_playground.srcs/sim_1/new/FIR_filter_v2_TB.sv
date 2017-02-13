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
#8 clk <= ~clk;

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


localparam REDUCER_BW = 9;
localparam RESET_NUMBER = 250/4; // 250/4=75
reg [REDUCER_BW : 0] clk_reducer = 0;
reg slow_clk = 0;
always @(posedge clk) begin
  if (clk_reducer >= RESET_NUMBER) begin
    clk_reducer <= 0;
    slow_clk <= ~slow_clk;
  end else begin
    clk_reducer <= clk_reducer + 1;  
  end
end

wire fir_clk;
// assign fir_clk = clk_reducer[REDUCER_BW];
assign fir_clk = slow_clk;
FIR_filter_v2 #(
    .TNN(512*4),   // Total number of samples
    .ROM_DW(24),
    .NMAC(4),      // Number of Multiply accumulator
    .ADC_DW(14) // ADC bitwidth (14-bit for the board we are using)
  )
  filter_inst
  (
    .sample_in(sample),
    .clk(fir_clk)// Input clock

  );

endmodule
