`timescale 1ns / 1ps
module coeff_table  (
	input 						clk,
	input 						en,
	input [4-1:0] 			addr,
	output reg [32-1:0] data_01,
	output reg [32-1:0] data_02,
	output reg [32-1:0] data_03,
	output reg [32-1:0] data_04
    );
always @(posedge clk) begin
	if (en) begin
		case(addr)
			4'd0: data_01 <= 1;
			4'd1: data_01 <= 2;
			4'd2: data_01 <= 3;
			4'd3: data_01 <= 4;
			4'd4: data_01 <= 5;
			4'd5: data_01 <= 6;
			4'd6: data_01 <= 7;
			4'd7: data_01 <= 8;
			4'd8: data_01 <= 9;
			4'd9: data_01 <= 10;
			4'd10: data_01 <= 11;
			4'd11: data_01 <= 12;
			4'd12: data_01 <= 13;
			4'd13: data_01 <= 14;
			4'd14: data_01 <= 15;
			4'd15: data_01 <= 16;
			default: data_01 <= 0;
		endcase
	end
end
always @(posedge clk) begin
	if (en) begin
		case(addr)
			4'd0: data_02 <= 17;
			4'd1: data_02 <= 18;
			4'd2: data_02 <= 19;
			4'd3: data_02 <= 20;
			4'd4: data_02 <= 21;
			4'd5: data_02 <= 22;
			4'd6: data_02 <= 23;
			4'd7: data_02 <= 24;
			4'd8: data_02 <= 25;
			4'd9: data_02 <= 26;
			4'd10: data_02 <= 27;
			4'd11: data_02 <= 28;
			4'd12: data_02 <= 29;
			4'd13: data_02 <= 30;
			4'd14: data_02 <= 31;
			4'd15: data_02 <= 32;
			default: data_02 <= 0;
		endcase
	end
end
always @(posedge clk) begin
	if (en) begin
		case(addr)
			4'd0: data_03 <= 33;
			4'd1: data_03 <= 34;
			4'd2: data_03 <= 35;
			4'd3: data_03 <= 36;
			4'd4: data_03 <= 37;
			4'd5: data_03 <= 38;
			4'd6: data_03 <= 39;
			4'd7: data_03 <= 40;
			4'd8: data_03 <= 41;
			4'd9: data_03 <= 42;
			4'd10: data_03 <= 43;
			4'd11: data_03 <= 44;
			4'd12: data_03 <= 45;
			4'd13: data_03 <= 46;
			4'd14: data_03 <= 47;
			4'd15: data_03 <= 48;
			default: data_03 <= 0;
		endcase
	end
end
always @(posedge clk) begin
	if (en) begin
		case(addr)
			4'd0: data_04 <= 49;
			4'd1: data_04 <= 50;
			4'd2: data_04 <= 51;
			4'd3: data_04 <= 52;
			4'd4: data_04 <= 53;
			4'd5: data_04 <= 54;
			4'd6: data_04 <= 55;
			4'd7: data_04 <= 56;
			4'd8: data_04 <= 57;
			4'd9: data_04 <= 58;
			4'd10: data_04 <= 59;
			4'd11: data_04 <= 60;
			4'd12: data_04 <= 61;
			4'd13: data_04 <= 62;
			4'd14: data_04 <= 63;
			4'd15: data_04 <= 64;
			default: data_04 <= 0;
		endcase
	end
end
endmodule
