`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:08:36 11/19/2020 
// Design Name: 
// Module Name:    DM 
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
module DM(
    input clk,
    input rst,
    input [31:0] A,
    input [31:0] WD,
    input [3:0] dmWrite,
    input [31:0] PC,
    output [31:0] RD
    );

reg [31:0] DM[0:4095];
wire [31:0] nextDm;
assign RD = DM[A[13:2]];
genvar i;
generate
	for (i=0; i<4; i=i+1)
	begin: updateByte
	assign nextDm[(i+1)*8-1: i*8] = dmWrite[i] ? WD[(i+1)*8-1: i*8] : RD[(i+1)*8-1: i*8];
	end
endgenerate

always @(posedge clk) begin
	if (rst) begin
		// reset
		begin: clrDM
			integer i;
			for (i=0; i<1024; i = i+1) begin
				DM[i] <= 0;
			end
		end
	end
	else if (dmWrite) begin
		$display("%d@%h: *%h <= %h", $time, PC, {A[31:2], 2'b0}, nextDm); 
		DM[A[13:2]] <= nextDm;
	end
end

endmodule
