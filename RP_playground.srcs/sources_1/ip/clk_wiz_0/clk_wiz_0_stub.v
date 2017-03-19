// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (win64) Build 1733598 Wed Dec 14 22:35:39 MST 2016
// Date        : Mon Jan 16 11:07:38 2017
// Host        : EpsilonIJK running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top clk_wiz_0 -prefix
//               clk_wiz_0_ clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_250_n90deg, clk_250, clk_125, locked, 
  clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_250_n90deg,clk_250,clk_125,locked,clk_in1" */;
  output clk_250_n90deg;
  output clk_250;
  output clk_125;
  output locked;
  input clk_in1;
endmodule
