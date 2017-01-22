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


reg signed [12:0] a12 = -29;
reg signed [12:0] b12 = -100;
wire signed [13:0] sum_ab = a12+b12;
wire        [13:0] usum_ab = a12+b12;

wire signed [26:0] sum_ab_26 = a12 + b12;
wire        [26:0] usum_ab_26 = a12 + b12;

wire [7:0] sum_ab_8 = (a12+b12) >>> 1;
wire [7:0] sum_ab_8_non = (a12+b12) >> 1;

reg signed [48:0] a = -8194;
wire [7:0] b;
assign b = {~a[30], a[6:0]};

wire [13:0] c;
assign c = {~a[48], a[12:0]};

// always @(posedge clk) begin
//   a = a+1;
//   $display("a= %d.. b= %d, %d, %d", a, b, $signed(b), $unsigned(b));
//   $display("a= %d.. c= %d, %d, %d", a, c, $signed(c), $unsigned(c));
// end


initial begin
  for (int i = 0; i < 500; i++) begin
    $display("A= %d.. clog2(A-1)+1 = %d", i, $clog2(i-1) + 1);

  end
end


// always @(posedge clk) begin
//   // sample <= {~sample_raw[13], sample_raw[12:0]};
//   $display("RAW:%014b (%6d), NEW: %014b (%6d)", sample_raw,sample_raw, $signed(sample), $signed(sample));

// end



endmodule
