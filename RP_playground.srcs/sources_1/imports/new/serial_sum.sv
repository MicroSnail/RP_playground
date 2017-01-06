`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2016 10:11:10 AM
// Design Name: 
// Module Name: serial_sum
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


module serial_sum
#(
parameter NMAC = 4,
parameter BW = 32,
parameter OBW = 32
)
  (
    // Debug hijacking
    output reg [$clog2(NMAC)  : 0] n = 0,
    output reg [OBW - 1:0] new_result  = 0,
    output reg               execute     = 0,

    input [OBW * NMAC - 1: 0]   mac_output,
    input                         inputUpdated,
    input                         clk,
    input                         rst,
    output reg [OBW - 1:0]      mac_sum = 0,
    output                        sum_finished
  );
    
// use the following reg instead of an output port when finished 
// debugging
// reg [$clog2(NMAC)  : 0] n = 0;
// reg [OBW - 1:0] new_result  = 0;
// reg               execute     = 0;


//    wire execute;
assign sum_finished = (n>=NMAC);
//    assign execute = ~sum_finished && inputUpdated;

// always @(posedge clk or posedge inputUpdated or posedge sum_finished) begin
always @(posedge clk) begin
  if(rst) begin
    mac_sum     <= 0;
    n           <= 0;
    new_result  <= 0;
    execute     <= 0;
  end else begin

    if (sum_finished) begin
      execute <= 0;
      mac_sum <= new_result;
      n       <= 0;
    end else begin
      if(execute) begin
        n           <= n + 1;
        new_result  <= new_result + mac_output[n * OBW +: OBW];        
      end else if (inputUpdated) begin
        execute     <= 1;
        new_result  <= 0;
        n           <= 0;
      end
    end
  end      
end
    


   
endmodule
