`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/10/2017 02:28:21 PM
// Design Name: 
// Module Name: string_test
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


module string_test(

    );

string a [0:31];
initial begin
  for (int i = 0; i < 32; i++) begin
    a[i] = $sformatf("FILE_%02d.MEM",i);
  end
  
  for (int i = 0; i < 32; i++) begin
    $display(a[i]);
  end
  
end

endmodule
