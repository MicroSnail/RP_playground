`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2017 03:39:43 PM
// Design Name: 
// Module Name: fir_unit
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


module fir_unit #(
    parameter MEM_INIT_FILE = "FIR_COEFF_0.MEM",
    parameter TNN   = 16,   // Total number of samples
    parameter DW    = 32,     // Data bitwidth
    parameter NMAC  = 1,      // Number of Multiply accumulator
    parameter ADC_DW = 14,     // ADC bitwidth (14-bit for the board we are using)
    parameter ROM_LATENCY = 1,  
    parameter MAC_LATENCY = 2,
    parameter ND     = TNN >> $clog2(NMAC),     // Number of Data per MAC
    parameter BUF_AW = $clog2(TNN),     // Address bitwidth for circular buffer
    parameter ROM_AW = $clog2(ND),     // Address bitwidth (For ROM and MAC)
    parameter BUF_RAM_AW = $clog2(ND)
  )
( 
  input                           clk,
  input                           smple_buf_wen,

  input [ROM_AW - 1 : 0]          rom_addr,
  input [BUF_RAM_AW - 1 : 0]      smpl_buf_addr,
  input [ADC_DW - 1 : 0]          smpl_buf_din,
  output  [48-1 : 0]              mac_out,
  input                           mac_ce,
  input                           mac_clear

    );


localparam ROM_SIZE     = ND * DW;        // Total number of bits of a single ROM
localparam BUF_RAM_SIZE = ND * ADC_DW;    // Total number of bits of the buffer for a single MAC

wire  [DW - 1 : 0]        coe_out;
wire [ADC_DW - 1 : 0] smpl_buf_dout;

// RAM for storing samples
// xpm_memory_spram: Single Port RAM
// Xilinx Parameterized Macro, Version 2016.4
xpm_memory_spram # (

  // Common module parameters
  .MEMORY_SIZE        (BUF_RAM_SIZE),           //positive integer
  .MEMORY_PRIMITIVE   ("block"),         //string; "auto", "distributed", "block" or "ultra";
  .MEMORY_INIT_FILE   ("none"),         //string; "none" or "<filename>.mem" 
  .MEMORY_INIT_PARAM  (""    ),         //string;
  .USE_MEM_INIT       (0),              //integer; 0,1
  .WAKEUP_TIME        ("disable_sleep"),//string; "disable_sleep" or "use_sleep_pin" 
  .MESSAGE_CONTROL    (0),              //integer; 0,1

  // Port A module parameters
  .WRITE_DATA_WIDTH_A (ADC_DW),             //positive integer
  .READ_DATA_WIDTH_A  (ADC_DW),             //positive integer
  .BYTE_WRITE_WIDTH_A (ADC_DW),             //integer; 8, 9, or WRITE_DATA_WIDTH_A value
  .ADDR_WIDTH_A       (BUF_RAM_AW),              //positive integer
  .READ_RESET_VALUE_A ("0"),            //string
  .ECC_MODE           ("no_ecc"),       //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
  .AUTO_SLEEP_TIME    (0),              //Do not Change
  .READ_LATENCY_A     (1),              //non-negative integer
  .WRITE_MODE_A       ("no_change")    //string; "write_first", "read_first", "no_change" 

) spram_00 (

  // Common module ports
  .sleep          (1'b0),

  // Port A module ports
  .clka           (clk),
  .rsta           (1'b0),
  .ena            (1'b1),
  .regcea         (1'b1),
  .wea            (smple_buf_wen),
  .addra          (smpl_buf_addr),
  .dina           (smpl_buf_din),
  .injectsbiterra (1'b0),
  .injectdbiterra (1'b0),
  .douta          (smpl_buf_dout),
  .sbiterra       (),
  .dbiterra       ()
);

// End of xpm_memory_spram instance declaration



// ROM to store coefficients
// xpm_memory_sprom: Single Port ROM
// Xilinx Parameterized Macro, Version 2016.4
xpm_memory_sprom # (

  // Common module parameters
  .MEMORY_SIZE        (ROM_SIZE),           //positive integer
  .MEMORY_PRIMITIVE   ("block"),         //string; "auto", "distributed", or "block";
  .MEMORY_INIT_FILE   (MEM_INIT_FILE),         //string; "none" or "<filename>.mem" 
  .MEMORY_INIT_PARAM  (""    ),         //string;
  .USE_MEM_INIT       (1),              //integer; 0,1
  .WAKEUP_TIME        ("disable_sleep"),//string; "disable_sleep" or "use_sleep_pin" 
  .MESSAGE_CONTROL    (0),              //integer; 0,1
  .ECC_MODE           ("no_ecc"),       //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
  .AUTO_SLEEP_TIME    (0),              //Do not Change

  // Port A module parameters
  .READ_DATA_WIDTH_A  (DW),             //positive integer
  .ADDR_WIDTH_A       (ROM_AW),              //positive integer
  .READ_RESET_VALUE_A ("0"),            //string
  .READ_LATENCY_A     (ROM_LATENCY)               //non-negative integer

) ROM_00 (

  // Common module ports
  .sleep          (1'b0),

  // Port A module ports
  .clka           (clk),
  .rsta           (1'b0),
  .ena            (1'b1),
  .regcea         (1'b1),
  .addra          (rom_addr),
  .injectsbiterra (1'b0),  //do not change
  .injectdbiterra (1'b0),  //do not change
  .douta          (coe_out),
  .sbiterra       (),      //do not change
  .dbiterra       ()       //do not change
);

// End of xpm_memory_sprom instance declaration


// Multiply accumulator
MACC_MACRO #(
   .DEVICE("7SERIES"), // Target Device: "7SERIES" 
   .LATENCY(MAC_LATENCY),        // Desired clock cycle latency, 1-4
   .WIDTH_A(24),       // Multiplier A-input bus width, 1-25
   .WIDTH_B(14),       // Multiplier B-input bus width, 1-18
   .WIDTH_P(48)        // Accumulator output bus width, 1-48
) MACC_MACRO_inst (
   .P(mac_out),     // MACC output bus, width determined by WIDTH_P parameter 
   .A(coe_out[23:0]),     // MACC input A bus, width determined by WIDTH_A parameter 
   .ADDSUB(1'b1), // 1-bit add/sub input, high selects add, low selects subtract
   .B(smpl_buf_dout),     // MACC input B bus, width determined by WIDTH_B parameter 
   .CARRYIN(1'b0), // 1-bit carry-in input to accumulator
   .CE(mac_ce),     // 1-bit active high input clock enable
   .CLK(clk),   // 1-bit positive edge clock input
   .LOAD(1'b0), // 1-bit active high input load accumulator enable
   .LOAD_DATA(48'b0), // Load accumulator input data, width determined by WIDTH_P parameter
   .RST(mac_clear)    // 1-bit input active high reset
);


endmodule
