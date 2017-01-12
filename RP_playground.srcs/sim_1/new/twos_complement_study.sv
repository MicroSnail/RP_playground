`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jialun Luo
// 
// Create Date: 01/11/2017 12:39:32 PM
// Design Name: 
// Module Name: twos_complement_study
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


module twos_complement_study(

    );
reg clk = 0;
always 
#5 clk <= ~clk;

reg [13:0] sample_raw = 0;



always @(posedge clk) begin
  sample_raw <= sample_raw + 1;
end

wire [13:0] sample;
assign sample = {~sample_raw[13], sample_raw[12:0]};

always @(posedge clk) begin
  // sample <= {~sample_raw[13], sample_raw[12:0]};
  $display("RAW:%014b (%6d), NEW: %014b (%6d)", sample_raw,sample_raw, $signed(sample), $signed(sample));
end



endmodule
