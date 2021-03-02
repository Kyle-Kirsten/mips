`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:47:27 11/17/2020 
// Design Name: 
// Module Name:    IM 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module IM(
    input [31:0] A,
    output [31:0] D
    );

reg	[31:0] ROM[0:4095];

wire [31:0] index = A-'h0000_3000;
assign D = ROM[index[13:2]];

initial begin
	$readmemh("testFib.txt", ROM);
end


endmodule
