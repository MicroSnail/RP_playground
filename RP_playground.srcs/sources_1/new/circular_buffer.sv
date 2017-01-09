`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2017 12:02:50 PM
// Design Name: 
// Module Name: circular_buffer
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


module circular_buffer
  #(
      parameter DW = 32,        // Datawidth
      parameter AW = 8          // Address width
  )
  (
    output reg [DW - 1 : 0] data_out = 0,
    input  reg [DW - 1 : 0] data_in,
    input                   clk,
    input                   write,
    input                   traverse,
    output reg              writeComplete = 0,
    output                  traverseComplete,
    output reg [AW - 1 : 0] rel_addr
  );

wire  [AW : 0]        rd_addr_next;
reg   [AW - 1 : 0]    rd_addr = 0;

wire  [AW : 0]        wr_addr_next;
reg   [AW - 1 : 0]    wr_addr = 0;

assign rd_addr_next = rd_addr + 1;
assign wr_addr_next = wr_addr + 1;

reg [0 : 2^AW - 1][DW - 1:0] data_buffer;
assign traverseComplete = rd_addr_next[AW];

always @(posedge clk) begin
  case({traverse, write})
    2'b10: // traverse mode
      begin
        writeComplete <= 0;
        rel_addr      <= rel_addr + 1;
        data_out      <= data_buffer[rd_addr];
        rd_addr       <= rd_addr_next[AW - 1 : 0];
      end
    2'b01: // write mode
      begin
        data_buffer[wr_addr]  <= data_in;
        wr_addr               <= wr_addr_next[AW - 1 : 0];
        rd_addr               <= wr_addr + 1;
        writeComplete         <= 1;
      end
    2'b11: // traverse and write, this shouldn't happen
      begin
      end
    2'b00:
      begin
      end
  endcase // {traverse, write}
end

endmodule
