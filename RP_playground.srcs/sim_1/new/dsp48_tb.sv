`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2017 03:57:51 PM
// Design Name: 
// Module Name: dsp48_tb
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


module dsp48_tb
  #(
    parameter TNN   = 32,   // Total number of samples
    parameter DW    = 18,     // Data bitwidth
    parameter NMAC  = 2,      // Number of Multiply accumulator
    parameter ADC_DW = 14     // ADC bitwidth (14-bit for the board we are using)
  )  
  (

    );
localparam ND     = TNN/NMAC    ;     // Number of Data per MAC
localparam BUF_AW = $clog2(TNN) ;     // Address bitwidth for circular buffer
localparam ROM_AW     = $clog2(ND)  ;     // Address bitwidth (For ROM and MAC)

localparam ROM_SIZE = ND * DW;        // Total bits of a single ROM

// FAKE CLOCK
reg clk = 0;
always #5 clk <= ~clk;


// counter for CE
reg [5 - 1 : 0] counter5 = 0;
always @(posedge clk) begin
  counter5 <= counter5 + 1;
end

wire mac_ce;
assign mac_ce = counter5[4];

// Local registers and bus declaration
reg   [ROM_AW - 1 : 0]    rom_addr = 0;
wire  [DW - 1 : 0]        data_00;

wire  [DW - 1 : 0]        mac00;
reg                     mac_load = 1;     // Don't need these two lines in our fir filter
reg [48-1 : 0]          load_data = 9;


always@(posedge clk) begin
  rom_addr <= rom_addr + 1;
end


reg mac_clear = 0;
reg [3:0] mac_clear_wait_counter = 0;
reg [3:0] mac_clear_active_counter = 0;
always@(posedge clk) begin
  if (mac_clear) begin
    mac_clear_active_counter <= mac_clear_active_counter + 1;
    if(mac_clear_active_counter == 3) begin
      mac_clear_active_counter <= 0;
      mac_clear <= 0;
    end
  end else begin
    mac_clear_wait_counter <= mac_clear_wait_counter + 1;
    if (mac_clear_wait_counter == 13) begin
      mac_clear_wait_counter <= 0;
      mac_clear <= 1;
    end
  end
end


// ROM to store coefficients
// xpm_memory_sprom: Single Port ROM
// Xilinx Parameterized Macro, Version 2016.4
xpm_memory_sprom # (
  // Common module parameters
  .MEMORY_SIZE        (ROM_SIZE),           //positive integer
  .MEMORY_PRIMITIVE   ("block"),         //string; "auto", "distributed", or "block";
  .MEMORY_INIT_FILE   ("FIR_COEFF_0.MEM"),         //string; "none" or "<filename>.mem" 
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
  .READ_LATENCY_A     (1)               //non-negative integer

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
  .douta          (data_00),
  .sbiterra       (),      //do not change
  .dbiterra       ()       //do not change
);


// MACC_MACRO: Multiply Accumulate Function implemented in a DSP48E
//             Artix-7
// Xilinx HDL Language Template, version 2016.4

MACC_MACRO #(
   .DEVICE("7SERIES"), // Target Device: "7SERIES" 
   .LATENCY(2),        // Desired clock cycle latency, 1-4
   .WIDTH_A(DW),       // Multiplier A-input bus width, 1-25
   .WIDTH_B(DW),       // Multiplier B-input bus width, 1-18
   .WIDTH_P(48)        // Accumulator output bus width, 1-48
) MACC_MACRO_inst (
   .P(mac00),     // MACC output bus, width determined by WIDTH_P parameter 
   .A(data_00),     // MACC input A bus, width determined by WIDTH_A parameter 
   .ADDSUB(1), // 1-bit add/sub input, high selects add, low selects subtract
   .B(data_00),     // MACC input B bus, width determined by WIDTH_B parameter 
   .CARRYIN(0), // 1-bit carry-in input to accumulator
   .CE(mac_ce),     // 1-bit active high input clock enable
   .CLK(clk),   // 1-bit positive edge clock input
   .LOAD(1'b0), // 1-bit active high input load accumulator enable
   .LOAD_DATA(48'b0), // Load accumulator input data, width determined by WIDTH_P parameter
   .RST(mac_clear)    // 1-bit input active high reset
);

endmodule
