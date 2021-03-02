`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:18:32 11/18/2020 
// Design Name: 
// Module Name:    RF 
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
module RF(
    input clk,
    input rst,
    input [4:0] rsAddr,
    input [4:0] rtAddr,
    input [4:0] WA,
    input [31:0] WD,
    input regWrite,
    input [31:0] PC,
    output [31:0] rsData,
    output [31:0] rtData
    );

reg [31:0] grf[0:31];

assign rsData = grf[rsAddr];
assign rtData = grf[rtAddr];

always @(posedge clk) begin
    if (rst) begin
        // reset
        begin: clrGrf
            integer i;
            for (i=0; i<32; i = i+1) begin
                grf[i] <= 0;
            end
        end
    end
    else if (regWrite&&WA!=0) begin
        $display("%d@%h: $%d <= %h", $time, PC, WA,WD);
        grf[WA] <= WD;
    end else grf[0]<=0;
end

endmodule
