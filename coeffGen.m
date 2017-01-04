AW = 15;            % address width
NN = 2^AW;          % total number of coefficients
DW = 20;            % data width


fileID = fopen('coeff_table.sv', 'w');

data = zeros(NN, 1);
for j=1:NN 
    data(j) = 1;
end
line1 = sprintf('\t\t\t%d''d', AW);

simulationTimeScaleHeader = sprintf('`timescale 1ns / 1ps\n');

fprintf(fileID, simulationTimeScaleHeader);
fprintf(fileID, 'module coeff_table(\n');
fprintf(fileID, '	input 						clk,\n');
fprintf(fileID, '	input 						en,\n');
fprintf(fileID, '	input [%d:0] 			addr,\n', AW);
fprintf(fileID, '	output reg [%d:0] data\n', DW-1 );
fprintf(fileID, '    );\n');
fprintf(fileID, 'always @(posedge clk) begin\n');
fprintf(fileID, '	if (en) begin\n');
fprintf(fileID, '		case(addr)\n');

for i=1:NN
    address = i-1;
    
    line2 = sprintf('%d: data <= %d;\n', address, data(i));
    line = [line1, line2];
    fprintf(fileID, line);
end
fprintf(fileID, '\t\t\tdefault: data <= 0;\n');
fprintf(fileID, '		endcase\n');
fprintf(fileID, '	end\n');
fprintf(fileID, 'end\n');
fprintf(fileID, 'endmodule 			\n');
fclose(fileID);