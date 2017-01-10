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
  .dina           (smpl_buf_00_din),
  .injectsbiterra (1'b0),
  .injectdbiterra (1'b0),
  .douta          (smpl_buf_00_dout),
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
  .douta          (coe_00),
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
   .P(mac_00_out),     // MACC output bus, width determined by WIDTH_P parameter 
   .A(coe_00[23:0]),     // MACC input A bus, width determined by WIDTH_A parameter 
   .ADDSUB(1'b1), // 1-bit add/sub input, high selects add, low selects subtract
   .B(smpl_buf_00_dout),     // MACC input B bus, width determined by WIDTH_B parameter 
   .CARRYIN(1'b0), // 1-bit carry-in input to accumulator
   .CE(mac_ce),     // 1-bit active high input clock enable
   .CLK(clk),   // 1-bit positive edge clock input
   .LOAD(1'b0), // 1-bit active high input load accumulator enable
   .LOAD_DATA(48'b0), // Load accumulator input data, width determined by WIDTH_P parameter
   .RST(mac_clear)    // 1-bit input active high reset
);