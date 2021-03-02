`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:53:51 11/20/2020 
// Design Name: 
// Module Name:    PC 
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
module PC(
    input clk,
    input rst,
    input en,
    input [31:0] nextPC,
    output reg [31:0] PC
    );
always @(posedge clk) begin
	if (rst) begin
		// reset
		PC <= 'h0000_3000;
	end
	else if (en) begin
		PC <= nextPC;
	end else begin
		PC <= PC;
	end
end

endmodule
