`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/12/2017 04:25:58 PM
// Design Name: 
// Module Name: clock_study
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


module clock_study(

    );

reg adc_clk_in = 0;
always #8 adc_clk_in <= ~adc_clk_in;


//clocks
wire pll_clk_250;
wire pll_clk_250_n90deg;
wire pll_clk_125;
wire pll_locked;
wire pll_clk_125_45;
 
clk_wiz_0 clock_PLL
  (
  // Clock out ports  
  .clk_250  ( pll_clk_250 ),
  .clk_250_n90deg   ( pll_clk_250_n90deg  ),
  .clk_125  ( pll_clk_125 ),
 // Clock in ports
  .clk_in1(adc_clk_in),
  .clk_125_45(pll_clk_125_45),
  .locked(pll_locked)
  );

wire clk_250_n90deg;      //  250 MHz 45 deg phase shift
wire clk_250;     //  50  MHz
wire clk_125;     //  125 MHz

wire adc_clk = clk_125;
wire dac_clk_1x = clk_125;
wire dac_clk_2x = clk_250;
wire dac_clk_2x_n90deg = clk_250_n90deg;

BUFG bufg_clk_250_45deg     (.O (clk_250_n90deg   ), .I (pll_clk_250_n90deg   ));
BUFG bufg_clk_125           (.O (clk_125  ), .I (pll_clk_125  ));
BUFG bufg_clk_250           (.O (clk_250   ), .I (pll_clk_250   ));

endmodule
