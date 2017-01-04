// Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2016.4 (win64) Build 1733598 Wed Dec 14 22:35:39 MST 2016
// Date        : Tue Jan 03 22:48:38 2017
// Host        : EpsilonIJK running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Users/MicroSnail/Documents/Cornell/Vengalattore/FPGA_PID/RP_playground/RP_playground.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z010clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(clk_50, clk_25, clk_125, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_50,clk_25,clk_125,clk_in1" */;
  output clk_50;
  output clk_25;
  output clk_125;
  input clk_in1;
endmodule
