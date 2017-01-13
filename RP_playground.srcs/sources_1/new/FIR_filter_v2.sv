`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Jialun Luo
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
    parameter TNN   = 128,   // Total number of samples
    parameter DW    = 32,     // Data bitwidth
    parameter ROM_DW= 24,
    parameter NMAC  = 8,      // Number of Multiply accumulator
    parameter DSP_OUT_DW = 48,
    parameter ADC_DW = 14     // ADC bitwidth (14-bit for the board we are using)
  )
  (
    input [ADC_DW - 1: 0]             sample_in,
    input                             clk,  
    input                             clk_45deg,  // 45 degree out of phase w.r.t. clk
    output signed [DSP_OUT_DW -1 : 0] result,
    output reg                        output_refreshed,  

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

localparam ROM_SIZE     = ND * ROM_DW;        // Total number of bits of a single ROM
localparam BUF_RAM_SIZE = ND * ADC_DW;    // Total number of bits of the buffer for a single MAC
localparam ROM_LATENCY = 1;           // Must be 1 or higher to infer BRAM, see ROM instantiation template 
localparam MAC_LATENCY = 2;           

localparam N_SUM_STAGE = $clog2(NMAC) - 1; // minus 1 because we summed once at the time MAC is done

// Local registers and bus declaration
reg   [ROM_AW - 1 : 0]    rom_addr = 0;

// Circular buffer for sample_in storage
reg [BUF_AW - 1 : 0]          latest_addr = {BUF_AW{1'b1}};    // Addr for the last obtained sample_in
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


reg signed [47:0] output_buffer = 0;
assign result = output_buffer;

reg signed [DSP_OUT_DW - 1 : 0] partial_mac [0 : (NMAC >> 1)-1] = '{default: {DSP_OUT_DW{1'b0}}};

// Signals to activate MAC and clear MAC
reg mac_clear = 0;
reg [BUF_AW - 1 : 0] mac_addr = 0;
reg mac_ce = 0;

reg sampler_en = 1'b1;
reg [2:0] sampler_delay = 0;

// For sample_in RAM
wire [BUF_RAM_AW - 1 : 0]  smpl_buf_addr;

// FIR unit specific in/out's
wire signed [ADC_DW - 1 : 0] smpl_buf_din[0 : NMAC - 1];
wire signed [ADC_DW - 1 : 0] earliest_sample_out[0 : NMAC - 1];
wire signed [48-1 : 0] mac_out[0 : NMAC - 1];


// Connecting RAMs such that the earliest sample of the N-th RAM
// becomes the latest sample of the (N-1)th RAM;
// And the last RAM takes new sample as the latest sample
genvar i;
generate
  for (i = 0; i < NMAC-1; i++) begin
    assign smpl_buf_din[i] = earliest_sample_out[i+1];
  end

  assign smpl_buf_din[NMAC-1] = sample_in;

  //This is only for debugging and use my predefined numbers in a loop
  // assign smpl_buf_din[NMAC-1] = earliest_sample_out[0];     
endgenerate

// FIR unit shared signals
wire smpl_buf_wen;
reg  smpl_buf_wen_1 = 0;
reg  smpl_buf_wen_2 = 1;
assign smpl_buf_wen = smpl_buf_wen_2 ^ smpl_buf_wen_1;
assign smpl_buf_addr = smpl_buf_wen ? earliest_addr : mac_addr;

// a counter add latencies to the start of addr advancements
reg [2:0] addr_delay = 0; 
reg mac_addr_en = 1;
reg rom_addr_en = 1;

reg [ROM_AW : 0] addr_counted = 0;

wire [BUF_AW - 1 : 0] rel_buf_addr;
assign rel_buf_addr = mac_addr - earliest_addr;

// Signal for fir_units to update their earliest sample output buffer
wire is_earliest_addr;
assign is_earliest_addr = (addr_counted==ND);

// Signal for controlling the summation cascade after partial MACs finished
wire sum_ce;
reg sum_ce_1 = 0;
reg sum_ce_2 = 0;
assign sum_ce = sum_ce_1 ^ sum_ce_2;


reg [$clog2(N_SUM_STAGE) : 0] i_stage = 0; 
reg sum_done = 0;

reg output_refreshed_once = 1'b0;

// Controls the signaling for a new sample and the need for a new sample
// genvar j;
always @(posedge clk) begin
  if (sampler_en) begin
    case({sample_expired, sample_obtained}) 
      (2'b10):  
        begin
          mac_clear <= 1'b0;
        end

      (2'b11):  
        begin 
        // FIR finishes computation, now we need a new sample_in
          sample_obtained_1 <= ~sample_obtained_1;
          smpl_buf_wen_1 <= ~smpl_buf_wen_1;

          // Make use of the output immediately and sum them in pairs.
          for (int j = 0; j < (NMAC >> 1); j++) begin: partial_mac_buffer
            partial_mac[j] <= mac_out[2*j] + mac_out[2*j + 1];
          end
          $display("%0d", partial_mac[0]);
        
        // In the meantime, clear the MAC
          mac_clear       <= 1'b1;

        // These are to accommodate the latency of MAC
          sampler_en      <= 1'b0;
          sampler_delay   <= 0;

        // Start summing the partial mac outputs
          sum_ce_1        <= ~sum_ce_1;
          sum_done        <= 1'b0;

        end
      (2'b01):
        begin
          mac_clear <= 1'b0;
        end
      // What happens without a default? I don't know yet...
    endcase // {sample_expired, sample_obtained}
  end else if (mac_clear) begin // To accommodate the set up latency of MAC
    sampler_en <= 1'b1;
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

// Logic for summation of partial MACs

  if(sum_ce) begin
    i_stage <= i_stage + 1;

    for (int i = 0; i < N_SUM_STAGE; i++) begin
      if(i_stage == i) begin 
        // $display("stage %0d", i_stage);
        if(i_stage == N_SUM_STAGE-1) begin
          sum_ce_2 <= ~sum_ce_2;
          sum_done <= 1'b1;
          i_stage <= 0;
          output_refreshed <= 1'b1;
        end           

        for (int j = 0; j < (NMAC >> 2) >> i_stage; j++) begin
          partial_mac[j*(1<<(i+1))] <= partial_mac[j*(1<<(i+1))] + partial_mac[j*(1<<(i+1)) + (1 << i)];
          // $display("Doing this");
          // $display("partial_mac[%0d] <= partial_mac[%0d] + partial_mac[%0d]",j*(1<<(i+1)), j*(1<<(i+1)), j*(1<<(i+1)) + (1 << i));
        end

        // $display("--------------stage %0d done--------------", i_stage);
      end
    end
  end

  if (sum_done) begin
    output_buffer <= partial_mac[0];
  end

  if (output_refreshed)
    output_refreshed <= 1'b0;


end 




// Instantiate partial FIR modules, each responsible for integrating a chunk of the kernel
generate
  for (i = 0; i < NMAC; i++) begin : partial_fir
    fir_unit #(
      .MEM_ID_1           (i / 10 + 48),      // Use ASCII code for single digits!! D[1] D[0]
      .MEM_ID_0           (i % 10 + 48),      // For example, for 13, enter ID1=049, ID0=051      
      .TNN              ( TNN                 ), // Total number of samples
      .DW               ( DW                  ), // Data bitwidth (coefficient obsolete)
      .NMAC             ( NMAC                ), // Number of Multiply accumulator
      .ADC_DW           ( ADC_DW              ), // ADC bitwidth (14-bit for the board we are using)
      .ROM_LATENCY      ( ROM_LATENCY         ),  
      .MAC_LATENCY      ( MAC_LATENCY         )
        ) fir_sub_module  (
      .clk            ( clk                   ),
      .smpl_buf_wen   ( smpl_buf_wen          ),
      .rom_addr       ( rom_addr              ),
      .smpl_buf_addr  ( smpl_buf_addr         ),
      .smpl_buf_din   ( smpl_buf_din[i]       ),
      .mac_out        ( mac_out[i]            ),
      .mac_ce         ( mac_ce                ),
      .mac_clear      ( mac_clear             ),
      .earliest_sample_out    ( earliest_sample_out[i]  ),
      .update_earliest_buffer ( is_earliest_addr        )
    );
  end
endgenerate

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
    // 20'h0000  : begin sys_rdata <= {{32-ROM_AW{1'b0}},  rom_addr}; end
    // 20'h0004  : begin sys_rdata <= {{32-DW{1'b0}},      result}; end
      default : begin sys_rdata <=   32'h0                           ; end
  endcase
end

endmodule
