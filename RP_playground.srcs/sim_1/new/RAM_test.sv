`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/09/2017 10:53:13 AM
// Design Name: 
// Module Name: RAM_test
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


module RAM_test(

    );

localparam DW = 14;
localparam ND = 8;
localparam AW = $clog2(ND);
localparam BUF_RAM_SIZE = DW * ND;


reg clk = 0;
always #5 clk <= ~clk;


reg [4:0] counter5 = 0;
reg [3:0] counter4 = 0;
reg [2:0] counter3 = 0;
always @(posedge clk) begin 
  counter5 <= counter5 + 1;
  counter4 <= counter4 + 1;
  counter3 <= counter3 + 1;
end

reg smpl_buf_wen = 0;
reg [AW - 1 : 0] smpl_buf_addr = 0;
reg [DW - 1 : 0] smpl_buf_din  = 0;
wire [DW - 1 : 0] smpl_buf_dout;

always @(posedge clk) begin 
  if (&counter3) begin
    smpl_buf_wen <= ~smpl_buf_wen;
  end

  smpl_buf_din <= smpl_buf_din + 1;
  smpl_buf_addr <= smpl_buf_addr + 1;
end


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
  .WRITE_DATA_WIDTH_A (DW),             //positive integer
  .READ_DATA_WIDTH_A  (DW),             //positive integer
  .BYTE_WRITE_WIDTH_A (DW),             //integer; 8, 9, or WRITE_DATA_WIDTH_A value
  .ADDR_WIDTH_A       (AW),              //positive integer
  .READ_RESET_VALUE_A ("0"),            //string
  .ECC_MODE           ("no_ecc"),       //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
  .AUTO_SLEEP_TIME    (0),              //Do not Change
  .READ_LATENCY_A     (1),              //non-negative integer
  .WRITE_MODE_A       ("no_change")    //string; "write_first", "read_first", "no_change" 

) xpm_memory_spram_inst (

  // Common module ports
  .sleep          (1'b0),

  // Port A module ports
  .clka           (clk),
  .rsta           (1'b0),
  .ena            (1'b1),
  .regcea         (1'b1),
  .wea            (smpl_buf_wen),
  .addra          (smpl_buf_addr),
  .dina           (smpl_buf_din),
  .injectsbiterra (1'b0),
  .injectdbiterra (1'b0),
  .douta          (smpl_buf_dout),
  .sbiterra       (),
  .dbiterra       ()
);

// End of xpm_memory_spram instance declaration
endmodule
