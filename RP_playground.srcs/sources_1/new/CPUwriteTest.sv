`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/04/2017 12:24:47 PM
// Design Name: 
// Module Name: CPUwriteTest
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


module CPUwriteTest#(
  parameter AW = 9,    //  address width
  parameter BW = 32,    //  data bitwidth
  parameter NMAC = 64   //  number of MACs
  )(
   // ADC
   input                 clk_i           ,  // clock
   // system bus
   input      [ 32-1: 0] sys_addr        ,  // bus address
   input      [ 32-1: 0] sys_wdata       ,  // bus write data
   input      [  4-1: 0] sys_sel         ,  // bus write byte select
   input                 sys_wen         ,  // bus write enable
   input                 sys_ren         ,  // bus read enable
   output reg [ 32-1: 0] sys_rdata       ,  // bus read data
   output reg            sys_err         ,  // bus error indicator
   output reg            sys_ack         ,  // bus acknowledge signal
   output     [ 7: 0]    testArrayOut    ,
   input      [14-1:  0] adc_raw_in
    );
//////////////////////////////////////

// Test the system bus way?
reg [7:0] testArray = 8'b10011011;
assign testArrayOut = testArray;
// wire [20-1:0] coefficient;
wire  [NMAC-1:0][BW-1:0] coeff_readout;

reg [AW-1:0] addrRequest;

// coeff_table memory (
//   .clk(clk_i),
//   .en(1),
//   .addr(addrRequest),
//   .data(coeff_readout)
// );


coeff_table coeff_table_inst (
    .clk    (  clk_i  ),
    .en     (  1  ),
    .addr   ( addrRequest  ),     // Supply 8-bit address
    .data_01 ( coeff_readout[00] ),
    .data_02 ( coeff_readout[01] ),
    .data_03 ( coeff_readout[02] ),
    .data_04 ( coeff_readout[03] ),
    .data_05 ( coeff_readout[04] ),
    .data_06 ( coeff_readout[05] ),
    .data_07 ( coeff_readout[06] ),
    .data_08 ( coeff_readout[07] ),
    .data_09 ( coeff_readout[08] ),
    .data_10 ( coeff_readout[09] ),
    .data_11 ( coeff_readout[10] ),
    .data_12 ( coeff_readout[11] ),
    .data_13 ( coeff_readout[12] ),
    .data_14 ( coeff_readout[13] ),
    .data_15 ( coeff_readout[14] ),
    .data_16 ( coeff_readout[15] ),
    .data_17 ( coeff_readout[16] ),
    .data_18 ( coeff_readout[17] ),
    .data_19 ( coeff_readout[18] ),
    .data_20 ( coeff_readout[19] ),
    .data_21 ( coeff_readout[20] ),
    .data_22 ( coeff_readout[21] ),
    .data_23 ( coeff_readout[22] ),
    .data_24 ( coeff_readout[23] ),
    .data_25 ( coeff_readout[24] ),
    .data_26 ( coeff_readout[25] ),
    .data_27 ( coeff_readout[26] ),
    .data_28 ( coeff_readout[27] ),
    .data_29 ( coeff_readout[28] ),
    .data_30 ( coeff_readout[29] ),
    .data_31 ( coeff_readout[30] ),
    .data_32 ( coeff_readout[31] ),
    .data_33 ( coeff_readout[32] ),
    .data_34 ( coeff_readout[33] ),
    .data_35 ( coeff_readout[34] ),
    .data_36 ( coeff_readout[35] ),
    .data_37 ( coeff_readout[36] ),
    .data_38 ( coeff_readout[37] ),
    .data_39 ( coeff_readout[38] ),
    .data_40 ( coeff_readout[39] ),
    .data_41 ( coeff_readout[40] ),
    .data_42 ( coeff_readout[41] ),
    .data_43 ( coeff_readout[42] ),
    .data_44 ( coeff_readout[43] ),
    .data_45 ( coeff_readout[44] ),
    .data_46 ( coeff_readout[45] ),
    .data_47 ( coeff_readout[46] ),
    .data_48 ( coeff_readout[47] ),
    .data_49 ( coeff_readout[48] ),
    .data_50 ( coeff_readout[49] ),
    .data_51 ( coeff_readout[50] ),
    .data_52 ( coeff_readout[51] ),
    .data_53 ( coeff_readout[52] ),
    .data_54 ( coeff_readout[53] ),
    .data_55 ( coeff_readout[54] ),
    .data_56 ( coeff_readout[55] ),
    .data_57 ( coeff_readout[56] ),
    .data_58 ( coeff_readout[57] ),
    .data_59 ( coeff_readout[58] ),
    .data_60 ( coeff_readout[59] ),
    .data_61 ( coeff_readout[60] ),
    .data_62 ( coeff_readout[61] ),
    .data_63 ( coeff_readout[62] ),
    .data_64 ( coeff_readout[63] )      // Supply 32-bit bus
);



//  System bus connection

always @(posedge clk_i) begin
   if (sys_wen) begin
      if (sys_addr[19:0]==20'h2ffc)   testArray       <= sys_wdata[24-1: 0] ;
      if (sys_addr[19:0]==20'h1ffc)   addrRequest     <= sys_wdata[24-1: 0] ;
   end
end

wire sys_en;
assign sys_en = sys_wen | sys_ren;

always @(posedge clk_i) begin
   sys_err <= 1'b0 ;
   casez (sys_addr[19:0])
     20'h2ffc   : begin sys_ack <= sys_en;  sys_rdata <= {{32-8{1'b0}}, testArray}          ; end
     20'h0000   : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}}, adc_raw_in}          ; end
     20'd00004: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[00]}; end
     20'd00008: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[01]}; end
     20'd00012: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[02]}; end
     20'd00016: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[03]}; end
     20'd00020: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[04]}; end
     20'd00024: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[05]}; end
     20'd00028: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[06]}; end
     20'd00032: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[07]}; end
     20'd00036: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[08]}; end
     20'd00040: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[09]}; end
     20'd00044: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[10]}; end
     20'd00048: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[11]}; end
     20'd00052: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[12]}; end
     20'd00056: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[13]}; end
     20'd00060: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[14]}; end
     20'd00064: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[15]}; end
     20'd00068: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[16]}; end
     20'd00072: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[17]}; end
     20'd00076: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[18]}; end
     20'd00080: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[19]}; end
     20'd00084: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[20]}; end
     20'd00088: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[21]}; end
     20'd00092: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[22]}; end
     20'd00096: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[23]}; end
     20'd00100: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[24]}; end
     20'd00104: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[25]}; end
     20'd00108: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[26]}; end
     20'd00112: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[27]}; end
     20'd00116: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[28]}; end
     20'd00120: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[29]}; end
     20'd00124: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[30]}; end
     20'd00128: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[31]}; end
     20'd00132: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[32]}; end
     20'd00136: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[33]}; end
     20'd00140: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[34]}; end
     20'd00144: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[35]}; end
     20'd00148: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[36]}; end
     20'd00152: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[37]}; end
     20'd00156: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[38]}; end
     20'd00160: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[39]}; end
     20'd00164: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[40]}; end
     20'd00168: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[41]}; end
     20'd00172: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[42]}; end
     20'd00176: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[43]}; end
     20'd00180: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[44]}; end
     20'd00184: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[45]}; end
     20'd00188: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[46]}; end
     20'd00192: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[47]}; end
     20'd00196: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[48]}; end
     20'd00200: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[49]}; end
     20'd00204: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[50]}; end
     20'd00208: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[51]}; end
     20'd00212: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[52]}; end
     20'd00216: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[53]}; end
     20'd00220: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[54]}; end
     20'd00224: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[55]}; end
     20'd00228: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[56]}; end
     20'd00232: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[57]}; end
     20'd00236: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[58]}; end
     20'd00240: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[59]}; end
     20'd00244: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[60]}; end
     20'd00248: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[61]}; end
     20'd00252: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[62]}; end
     20'd00256: begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[63]}; end
     20'h1ffc   : begin sys_ack <= sys_en;  sys_rdata <= {{32-AW{1'b0}}, addrRequest}          ; end 
       default  : begin sys_ack <= sys_en;  sys_rdata <=   32'h0                           ; end
   endcase
end

// always @(posedge clk_i) begin
//    sys_err <= 1'b0 ;
//    casez (sys_addr[19:0])
//      20'h2ffc   : begin sys_ack <= sys_en;  sys_rdata <= {{32-8{1'b0}}, testArray}          ; end
//      20'h0000   : begin sys_ack <= sys_en;  sys_rdata <= {{32-14{1'b0}}, adc_raw_in}          ; end
//      20'h0004   : begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[00]}          ; end
//      20'h0008   : begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[01]}          ; end
//      20'h000c   : begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[02]}          ; end
//      20'h0010   : begin sys_ack <= sys_en;  sys_rdata <= {{32-BW{1'b0}}, coeff_readout[03]}          ; end
//      20'h0100   : begin sys_ack <= sys_en;  sys_rdata <= {{32-AW{1'b0}}, addrRequest}          ; end 
//        default  : begin sys_ack <= sys_en;  sys_rdata <=   32'h0                           ; end
//    endcase
// end


endmodule
