`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/20/2016 01:52:58 PM
// Design Name: 
// Module Name: multiplyAccumulator
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


module multiplyAccumulator
#(
  parameter ND = 16,        // number of data
  parameter BW = 32,        // bitwidth of data
  parameter OBW = BW    // bitwidth of output
)
( 
  input   [ND * BW - 1  : 0]        inA,
  input   [BW - 1       : 0]        singleInA,
  input   [ND * BW - 1  : 0]        inB,
  input   [$clog2(ND) -1: 0]        rd_addr,

  // a flag to know rd_addr looped through a cycle
  input                             rd_addr_l_MSB, 
  
  input                             clk,
  input                             rst,
  input                             inputUpdated,
  output  reg [OBW - 1 : 0]         mac_out = 0,
  output                            mac_done,
  output  reg                       execute = 0,
  output  reg                       mac_armed = 1
  
);

  // reg [$clog2(ND) : 0] rd_addr = 0;
//  reg execute = 0;
// wire execute;
assign mac_done = rd_addr_l_MSB && (~mac_armed);


// assign execute = (~mac_done) && inputUpdated;

wire [BW - 1 : 0] debug_current_elem;
assign debug_current_elem = elem_buf;

reg [BW-1 : 0] elem_buf=0;
reg delay_exec = 0;

always @(posedge clk) begin
  if (rst) begin
    elem_buf <= 0;
  end else begin
    elem_buf <= inB[rd_addr * BW +: BW];
  end
end

// only a stub

always @(posedge clk) begin
  if (rst) begin
    // rd_addr  <=  0;
    mac_out  <=  {(ND * BW - 1){1'b0}};
    mac_armed <= 1;
    execute <= 0;
    delay_exec <= 0;
  end else begin
    if (mac_armed && inputUpdated) begin
      execute   <= 1;
      delay_exec <= 1;
      mac_armed <= 0;
      // rd_addr   <= 0;
      mac_out   <= 0;
    end else if(execute && ~mac_done) begin
      if (delay_exec) begin
        delay_exec <= 0;
      end else begin
        mac_out <= mac_out + singleInA * elem_buf;
      end
      // rd_addr <= rd_addr + 1;
    end
    
    if (mac_done) begin
      mac_armed   <= 1;
      execute     <= 0;
    end
  end
end


endmodule
