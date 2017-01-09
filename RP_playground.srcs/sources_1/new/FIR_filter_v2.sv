`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2017 11:02:15 AM
// Design Name: 
// Module Name: FIR_filter_v2
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


module FIR_filter_v2
  #(
    parameter TNN   = 512,   // Total number of samples
    parameter DW    = 32,     // Data bitwidth
    parameter NMAC  = 1,      // Number of Multiply accumulator
    parameter ADC_DW = 14     // ADC bitwidth (14-bit for the board we are using)
  )
  (
    output [7:0]          led_debug_out   ,
    input [ADC_DW - 1: 0] sample_in          ,
    input                 clk             ,  // Input clock
    output [DW -1 : 0]    result          ,

    // system bus (for debugging?)
    input      [ 32-1: 0] sys_addr        ,  // bus address
    input      [ 32-1: 0] sys_wdata       ,  // bus write data
    input      [  4-1: 0] sys_sel         ,  // bus write byte select
    input                 sys_wen         ,  // bus write enable
    input                 sys_ren         ,  // bus read enable
    output reg [ 32-1: 0] sys_rdata       ,  // bus read data
    output reg            sys_err         ,  // bus error indicator
    output reg            sys_ack       
  );

localparam ND     = TNN >> $clog2(NMAC)    ;     // Number of Data per MAC
localparam BUF_AW = $clog2(TNN) ;     // Address bitwidth for circular buffer
localparam ROM_AW = $clog2(ND)  ;     // Address bitwidth (For ROM and MAC)
localparam BUF_RAM_AW = $clog2(ND)  ;

localparam ROM_SIZE     = ND * DW;        // Total number of bits of a single ROM
localparam BUF_RAM_SIZE = ND * ADC_DW;    // Total number of bits of the buffer for a single MAC
localparam ROM_LATENCY = 1;               // Must be 1 or higher to infer BRAM, see ROM instantiation template 
localparam MAC_LATENCY = 2;           

// Local registers and bus declaration
reg   [ROM_AW - 1 : 0]    rom_addr = 0;
wire  [DW - 1 : 0]        coe_00;

// LED logic
assign led_debug_out = coe_00[7:0];


// Circular buffer for sample_in storage
reg [BUF_AW - 1 : 0]          latest_addr = {BUF_AW{1'b1}};    // Addr for the last obtained sample_in
reg [0 : TNN - 1][DW - 1 : 0] sample_buffer = 0;
wire [BUF_AW - 1 : 0]         earliest_addr;



assign earliest_addr = latest_addr + 1;


// Signal acknowledging obtaining a sample_in
// reg sample_obtained = 0;
wire sample_obtained;
reg sample_obtained_1 = 0;
reg sample_obtained_2 = 0;

assign sample_obtained = sample_obtained_1 ^ sample_obtained_2;

// reg sample_expired  = 1;      // Meaning FIR finishes computing with the new sample_in

wire sample_expired;
reg sample_expired_sampler = 0;
reg sample_expired_mac = 1;
assign sample_expired = sample_expired_mac ^ sample_expired_sampler;
// Initially 0, whichever one changes it flips value;


reg [47:0] output_buffer = 0;
assign result = output_buffer;

wire [48-1 : 0] mac_00_out;
wire [48-1 : 0] mac_01_out;

wire [DW-1 : 0] stage1_sum;
assign stage1_sum = mac_01_out + mac_00_out;


// Signals to activate MAC and clear MAC
reg mac_clear = 0;
reg [BUF_AW - 1 : 0] mac_addr = 0;
reg mac_ce = 0;


reg sampler_en = 1'b1;

reg [2:0] sampler_delay = 0;

// For sample_in RAM
// reg [BUF_AW - 1 : 0]  smpl_buf_addr = 0;
wire [BUF_RAM_AW - 1 : 0]  smpl_buf_addr;
wire [ADC_DW - 1 : 0] smpl_buf_00_din;
wire [ADC_DW - 1 : 0] smpl_buf_01_din;
wire [ADC_DW - 1 : 0] smpl_buf_00_dout;

assign smpl_buf_00_din = sample_in;
assign smpl_buf_01_din = smpl_buf_00_dout;
assign smpl_buf_addr = smpl_buf_wen ? earliest_addr : mac_addr;

wire smpl_buf_wen;
reg  smpl_buf_wen_sampler = 0;
reg  smpl_buf_wen_2 = 1;
assign smpl_buf_wen = smpl_buf_wen_2 ^ smpl_buf_wen_sampler;

// Controls the signaling for a new sample and the need for a new sample
always @(posedge clk) begin
  if (sampler_en) begin
    case({sample_expired, sample_obtained}) 
      (2'b10):  
        begin
          sample_buffer[earliest_addr] <= {{(DW - ADC_DW){1'b0}}, sample_in};
          // sample_obtained   <= 1'b1;      
          
          // smpl_buf_wen_sampler <= ~smpl_buf_wen_sampler;          
          // latest_addr       <= earliest_addr;
          mac_clear <= 1'b0;
        end

      (2'b11):  
        begin // FIR finishes computation, now we need a new sample_in
          sample_obtained_1 <= ~sample_obtained_1;
          smpl_buf_wen_sampler <= ~smpl_buf_wen_sampler;          
          output_buffer   <= stage1_sum;
          mac_clear       <= 1'b1;
          sampler_en      <= 1'b0;
          sampler_delay   <= 0;

        end
      (2'b01):
        begin
          mac_clear <= 1'b0;
        end
      // What happens without a default?
    endcase // {sample_expired, sample_obtained}
  end else if (mac_clear) begin // To accommodate the set up latency of MAC
    // sampler_delay <= sampler_delay + 1;
    sampler_en <= 1'b1;
    // if (sampler_delay >= 1) begin
    //   sampler_en <= 1'b1;
    // end
  end

  if (smpl_buf_wen) begin
    smpl_buf_wen_2 <= ~smpl_buf_wen_2;
    sample_obtained_2 <= ~sample_obtained_2;
    sample_expired_sampler    <= ~sample_expired_sampler;
    latest_addr <= earliest_addr;
    mac_addr    <= earliest_addr + 1;  // need the new earliest address
  end

  if (sample_obtained) begin
      mac_ce <= 1;
  end 
end 


// a counter add latencies to the start of addr advancements
reg [2:0] addr_delay = 0; 
reg mac_addr_en = 1;
reg rom_addr_en = 1;

reg [ROM_AW : 0] addr_counted = 0;

wire [BUF_AW - 1 : 0] rel_buf_addr;
assign rel_buf_addr = mac_addr - earliest_addr;

// reg [1:0] mac_ce_delay = 0;
// localparam MAC_CE_LATENCY = 1;

always @(posedge clk) begin


  // if (rom_addr_en) begin
  //   rom_addr <= rom_addr + 1;

  // end else begin  // This is to accommodate the latency of MAC
  //   rom_addr <= 0;
  //   if (addr_delay >= MAC_LATENCY) rom_addr_en <= 1;
  // end


  if (mac_addr_en) begin
    if (mac_ce) begin
      mac_addr <= mac_addr + 1;
      rom_addr <= rom_addr + 1;

      addr_counted <= addr_counted + 1;
    end

    if (addr_counted >= ND + MAC_LATENCY - 1) begin
      addr_counted <= 0;
      mac_ce <= 0;
      sample_expired_mac <= ~sample_expired_mac;
      mac_addr_en <= 0;
      rom_addr_en <= 0;
      addr_delay <= 0;
    end
  end else begin  // This is to accommodate the latencies of MAC and sample RAM
    addr_delay <= addr_delay + 1;
    rom_addr <= 0;
    if (addr_delay >= MAC_LATENCY - ROM_LATENCY) mac_addr_en <= 1;
  end


end

wire [48-1 : 0] mac_00_out;

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

// Log2 logic to sum MAC outputs 



//  System bus connection

always @(posedge clk) begin
  if (sys_wen) begin
    // if (sys_addr[19:0]==20'h0000)   rom_addr       <= sys_wdata[24-1: 0] ;
  end
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;
always @(posedge clk) begin
  sys_err <= 1'b0 ;
  sys_ack <= sys_en;
  casez (sys_addr[19:0])
    20'h0000  : begin sys_rdata <= {{32-ROM_AW{1'b0}}, rom_addr}; end
    20'h0004  : begin sys_rdata <= {{32-DW{1'b0}}, coe_00}; end
      default : begin sys_rdata <=   32'h0                           ; end
  endcase
end

endmodule
