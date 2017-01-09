`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/30/2016 09:57:40 AM
// Design Name: 
// Module Name: FIR_filter
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
//////////////////////////////////////////////////////////////////////


module FIR_filter
  #(
      parameter BW = 32,            //data width
      parameter OBW = BW,         //output width
      parameter AW = 8,           // address width, NDMAC = 2^AW
      parameter NMAC = 8           //number of MACs
  )
  (
    input       [BW - 1 : 0]                datIn,
    output reg  [OBW - 1 : 0]               datOut,
    input                                   clk,
    input                                   rst,
    output     [7:0]                        debugOut,
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

// total number of sample/ size of the sample array is
// (NDMAC * NMAC)
// The total number of bits in the flatten array then 
// is given by (NDMAC * NMAC * dataBitwidth)
localparam TBW = NDMAC * NMAC * BW; // total bitwidth (# of total coeff * BW)
localparam TNN = NDMAC * NMAC;
localparam NDMAC= 1 << AW;    //number of data each MAC handle
localparam MACBW  = NDMAC * BW;   // bitwidth of data/coeffs in a MAC

/////////////////////////////////////////////////////////


//------------Some storages and signals----------------//
// reg   [TBW - 1 : 0]      flatCoeff = 0;
reg   [OBW * NMAC - 1 : 0]   mac_out_storage = 0;
wire  [OBW * NMAC - 1 : 0]   mac_direct_out;
wire   [OBW - 1 : 0]         mac_sum;
wire  [NMAC - 1: 0]             mac_armed;
wire  [NMAC - 1: 0]             mac_done;
wire                            sum_finished;
wire                            sum_armed;

// For debugging with samples
reg [$clog2(TNN) - 1 : 0] dbs_wr_addr       = 0;
reg [BW - 1 : 0]          dbs_wr_value  = 0;
reg   [TBW - 1 : 0]       debugSample   = 2048'b00000000000000000000000001000000000000000000000000000000001111110000000000000000000000000011111000000000000000000000000000111101000000000000000000000000001111000000000000000000000000000011101100000000000000000000000000111010000000000000000000000000001110010000000000000000000000000011100000000000000000000000000000110111000000000000000000000000001101100000000000000000000000000011010100000000000000000000000000110100000000000000000000000000001100110000000000000000000000000011001000000000000000000000000000110001000000000000000000000000001100000000000000000000000000000010111100000000000000000000000000101110000000000000000000000000001011010000000000000000000000000010110000000000000000000000000000101011000000000000000000000000001010100000000000000000000000000010100100000000000000000000000000101000000000000000000000000000001001110000000000000000000000000010011000000000000000000000000000100101000000000000000000000000001001000000000000000000000000000010001100000000000000000000000000100010000000000000000000000000001000010000000000000000000000000010000000000000000000000000000000011111000000000000000000000000000111100000000000000000000000000001110100000000000000000000000000011100000000000000000000000000000110110000000000000000000000000001101000000000000000000000000000011001000000000000000000000000000110000000000000000000000000000001011100000000000000000000000000010110000000000000000000000000000101010000000000000000000000000001010000000000000000000000000000010011000000000000000000000000000100100000000000000000000000000001000100000000000000000000000000010000000000000000000000000000000011110000000000000000000000000000111000000000000000000000000000001101000000000000000000000000000011000000000000000000000000000000101100000000000000000000000000001010000000000000000000000000000010010000000000000000000000000000100000000000000000000000000000000111000000000000000000000000000001100000000000000000000000000000010100000000000000000000000000000100000000000000000000000000000000110000000000000000000000000000001000000000000000000000000000000001;
reg                       debug_wr_en   = 0;
reg [$clog2(NMAC * BW) - 1 : 0] coeff_wr_addr = 0;
/////////////////////////////////////////////////////////





always @(posedge clk) begin
  if(debug_wr_en)
    debugSample[dbs_wr_addr * BW +: BW] <= dbs_wr_value;
end





//--------------Coefficient ROM for MACs---------------//
wire [ NMAC * BW - 1 : 0] coeffs;
wire  [AW : 0] rd_addr_next; // with one bit more for counting
reg  [AW     : 0] rd_addr_l  = 0; // =rd_addr - 1;
reg  [AW - 1 : 0] rd_addr    = 0;

assign rd_addr_next = rd_addr + 1;

wire [NMAC-1 : 0] mac_execute;

always @(posedge clk) begin
  // if(&mac_execute) begin
  if (sampled) begin      // Be careful with this implementation!
    rd_addr_l <= rd_addr_next;
    rd_addr   <= rd_addr_next[AW - 1 : 0];
  end else begin
    rd_addr   <= 0;
    rd_addr_l <= 0;
  end
end
//// This counting logic looks clumsy...

coeff_table coeff_table_inst (
    .clk    (  clk  ),
    .en     (  1  ),
    .addr   (  rd_addr  ),      // Supply 8-bit address
    .data_01 ( coeffs[01 * BW - 1: 00 * BW] ),
    .data_02 ( coeffs[02 * BW - 1: 01 * BW] ),
    .data_03 ( coeffs[03 * BW - 1: 02 * BW] ),
    .data_04 ( coeffs[04 * BW - 1: 03 * BW] ),
    .data_05 ( coeffs[05 * BW - 1: 04 * BW] ),
    .data_06 ( coeffs[06 * BW - 1: 05 * BW] ),
    .data_07 ( coeffs[07 * BW - 1: 06 * BW] ),
    .data_08 ( coeffs[08 * BW - 1: 07 * BW] )     // Supply 32-bit bus
);
/////////////////////////////////////////////////////////


//------Sampler----------------------------------------//
reg   [TBW - 1 : 0]         flatSample  = 0;
reg                         sampled     = 0;
wire  [BW - 1 : 0]          newSample;
wire                        rst_sampler;
assign rst_sampler = rst;

assign newSample = datIn;

always @(posedge clk) begin
  if(&mac_armed) begin
    if (~sampled) begin 
      flatSample <= {newSample, flatSample[TBW - 1 : BW]};
      sampled <= 1;
    end else if (&mac_done) begin
      sampled <= 0;
    end    
  end

end
/////////////////////////////////////////////////////////

//-----------MAC output storage -----------------------//
//    reg mac_out_ready = 0;
reg mac_out_storage_updated = 0;

always @(posedge clk) begin    
  // Only update the MAC results if mac_done is 
  // flagged and the storage is not updated
  // storage_updated flag need to be reset somewhere
  if(mac_done && ~mac_out_storage_updated ) begin 
    mac_out_storage <= mac_direct_out;
  // mac_out_ready   <= 1;
    mac_out_storage_updated <= 1;
  end else if (sum_finished) begin
    mac_out_storage_updated <= 0;
  end
end
/////////////////////////////////////////////////////////


//----Instantiate multiple MACs -----------------------//
multiplyAccumulator 
#(
  .ND(NDMAC),
  .BW(BW), 
  .OBW(OBW)
) MACs [NMAC-1 : 0]
  (
    // .inA(flatCoeff),
    .singleInA(coeffs),     // This might be problematic 
    // .inB(flatSample),
    .inB(debugSample),
    .rd_addr(rd_addr),
    .rd_addr_l_MSB(rd_addr_l[AW]),
    .inputUpdated(sampled),
    .clk(clk),
    .rst(1'b0),
    .mac_done(mac_done),
    .mac_armed(mac_armed),
    .execute( mac_execute),
    .mac_out(mac_direct_out)
  );        
/////////////////////////////////////////////////////////

//------MAC sum----------------------------------------//

wire [OBW - 1:0] db_new_result;
wire [$clog2(NMAC)  : 0] db_n;
wire db_execute;

serial_sum #(.NMAC(NMAC), .BW(BW), .OBW(OBW))
  inst_serial_sum 
    (
      // debug ports 
      .n(db_n),
      .new_result(db_new_result),
      .execute(db_execute),
      .mac_output(mac_out_storage),
      .inputUpdated(mac_out_storage_updated),
      .clk(clk),
      .rst(0),
      .mac_sum(mac_sum),
      .sum_finished(sum_finished)
    );
/////////////////////////////////////////////////////////


//---------------Output logics-------------------------//
// Is there anything wrong with using negedge? 
// Why don't people do that? (Mixing posedge and negedge)
always @(negedge sum_finished) begin
  datOut <= mac_sum;
end
/////////////////////////////////////////////////////////




//  System bus connection

always @(posedge clk) begin
  if (sys_wen) begin
    if (sys_addr[19:0]==20'h0000)   dbs_wr_addr       <= sys_wdata[24-1: 0] ;
    if (sys_addr[19:0]==20'h0004)   dbs_wr_value      <= sys_wdata[24-1: 0] ;
    if (sys_addr[19:0]==20'h0014)   coeff_wr_addr     <= sys_wdata[24-1: 0] ;    
    if (sys_addr[19:0]==20'h0008)   debug_wr_en       <= sys_wdata[24-1: 0] ;      
  end
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;
always @(posedge clk) begin
  sys_err <= 1'b0 ;
  sys_ack <= sys_en;
  casez (sys_addr[19:0])
    20'h0000  : begin sys_rdata <= {{32-$clog2(TNN){1'b0}}, dbs_wr_addr}; end
    20'h0004  : begin sys_rdata <= {{32-BW{1'b0}}, dbs_wr_value}; end
    20'h0008  : begin sys_rdata <= {{32-1{1'b0}}, debug_wr_en}; end 
    20'h000c  : begin sys_rdata <= {{32-BW{1'b0}}, datOut}; end 
    20'h0010  : begin sys_rdata <= {{32-BW{1'b0}}, debugSample[dbs_wr_addr * BW +: BW]}          ; end 
    20'h0014  : begin sys_rdata <= {{32-$clog2(NMAC * BW){1'b0}}, coeff_wr_addr}          ; end 
    20'h0018  : begin sys_rdata <= {{32-BW{1'b0}}, coeffs[coeff_wr_addr * BW +: BW]}          ; end 
    20'h001c  : begin sys_rdata <= {{32-BW{1'b0}}, mac_sum}; end 
    20'h0020  : begin sys_rdata <= {{32-OBW{1'b0}}, db_new_result}; end 
    20'h0024  : begin sys_rdata <= {{32-$clog2(NMAC){1'b0}}, db_n}; end 
    20'h0028  : begin sys_rdata <= {{32-1{1'b0}}, mac_out_storage_updated}          ; end 
    20'h002c  : begin sys_rdata <= {{32-1{1'b0}}, sampled}; end 
    20'h0030  : begin sys_rdata <= {{32-1{1'b0}}, db_execute}; end 
    20'h0034  : begin sys_rdata <= {{32-1{1'b0}}, sum_finished}; end 
      default : begin sys_rdata <=   32'h0                           ; end
  endcase
end


//-----------split coeffs for debugging-----------------//
genvar jj;
wire  [BW - 1: 0] coeffs_split [0 : NMAC-1];
generate  
  for(jj = 0; jj<NMAC; jj++) begin: debugsplit1
    assign coeffs_split[jj] = coeffs[jj * BW +: BW]; 
  end
endgenerate
//////////////////////////////////////////////////////////

//------split flatSample for debug reason-----------------//
// genvar jj;
wire  [BW - 1: 0] flatSample_split [0 : NMAC-1][0 : NDMAC-1];
genvar ii;
generate  
  for(jj = 0; jj<NMAC; jj++) begin: debugsplit2
    for(ii = 0; ii< NDMAC; ii++) begin: debugsplit4
      assign flatSample_split[jj][ii] = flatSample[jj * NDMAC * BW + ii * BW +:  BW]; 
    end
  end
endgenerate
//////////////////////////////////////////////////////////

//------split flatSample for debugging------------------//
// genvar jj;
wire  [BW - 1: 0] debugSample_split [0 : NMAC-1][0 : NDMAC-1];
generate  
  for(jj = 0; jj<NMAC; jj++) begin: debugSample_debug
    for(ii = 0; ii< NDMAC; ii++) begin: debugSample_debug_more
      assign debugSample_split[jj][ii] = debugSample[jj * NDMAC * BW + ii * BW +:  BW]; 
    end
  end
endgenerate
//////////////////////////////////////////////////////////

endmodule
