`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/07/2017 12:32:12 PM
// Design Name: 
// Module Name: circular_buffer_TB
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


module circular_buffer_TB(

    );


// module circular_buffer
//   #(
//       parameter DW = 32,        // Datawidth
//       parameter AW = 8          // Address width
//   )
//   (
//     output reg [DW - 1 : 0] data_out,
//     input  reg [DW - 1 : 0] data_in,
//     input                   clk,
//     input                   write,
//     input                   traverse,
//     output                  writeComplete,
//     output reg              traverseComplete,
//     output reg [AW - 1 : 0] rel_addr
//   );

parameter DW = 32;
parameter AW = 8;

reg clk = 0;
always #5 clk <= ~clk;

reg [DW - 1: 0] new_sample = 0;

wire samples_write_complete;


reg sampleReady = 0;
reg mac_run = 0;

always @(posedge clk) begin
  if(~mac_run && ~sampleReady) begin
    new_sample  <= new_sample + 1;
    sampleReady <= 1;
  end else begin
    sampleReady <= 0;
  end
end


always @(posedge clk) begin
  if (samples_write_complete) begin
    mac_run <= 1;
  end else if (samples_traverse_complete) begin 
    mac_run <= 0;
  end
end

reg traverserReady = 1;

wire [DW - 1: 0] data = 0;
reg  [DW - 1: 0] data_buf = 0;


always @(posedge clk) begin
  if(mac_run & ~samples_traverse_complete) begin
    traverserReady <= 1;
    data_buf       <= data;
  end else if (samples_traverse_complete) begin
    traverserReady <= 0;
  end
end


circular_buffer #(.DW(DW), .AW(AW)) samples (
      .data_out(data),
      .data_in(new_sample),
      .clk(clk),
      .write(sampleReady),
      .traverse(traverserReady),
      .writeComplete(samples_write_complete),
      .traverseComplete(samples_traverse_complete),
      .rel_addr(rel_addr) 
  );




// reg s_s_handle = 0;
// reg s_t_handle = 0;
// reg t_s_handle = 0;
// reg t_t_handle = 0;
// wire sampleReady;
// wire traverserReady;

// assign sampleReady    = s_s_handle ^ s_t_handle;
// assign traverserReady = ~(t_s_handle ^ t_t_handle);



// always @(posedge clk) begin
//   if(samples_traverse_complete) begin
//     new_sample  <= new_sample + 1;
//     s_s_handle <= ~s_s_handle;
//     t_s_handle <= ~t_s_handle;
//   end
// end

// wire [DW - 1: 0] sample_data;
// reg  [DW - 1: 0] bufferData;

// wire samples_write_complete;
// wire samples_traverse_complete;

// wire [AW - 1: 0] rel_addr;

// always @(posedge clk) begin
//   if(samples_write_complete) begin
//     bufferData <= sample_data;
//   end 

//   if(samples_traverse_complete) begin
//     s_t_handle <= ~s_t_handle;
//   end
// end

endmodule
