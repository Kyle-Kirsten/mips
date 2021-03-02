`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:47:59 12/31/2020 
// Design Name: 
// Module Name:    Bridge 
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
module Bridge(
    input [31:0] PrAddr,
    input [31:0] PrWD,
    input PrWrite,
    output [31:0] PrRD,
    output [15:10] PrInt,
    output [31:2] DevAddr,
    output [6:1] DevWrite,
    input [31:0] DevRD1,
    input [31:0] DevRD2,
    input [31:0] DevRD3,
    input [31:0] DevRD4,
    input [31:0] DevRD5,
    input [31:0] DevRD6,
    output [31:0] DevWD,
    input [6:1] DevInt
    );
assign PrRD = PrAddr>=32'h00007f00&&PrAddr<=32'h00007f0b ? DevRD1:
              PrAddr>=32'h00007f10&&PrAddr<=32'h00007f1b ? DevRD2: 0;
assign PrInt = DevInt;
assign DevAddr = PrAddr[31:2];
assign DevWrite[6:3] = 0;
assign DevWrite[2] = PrWrite&&PrAddr>=32'h00007f10&&PrAddr<=32'h00007f1b;
assign DevWrite[1] = PrWrite&&PrAddr>=32'h00007f00&&PrAddr<=32'h00007f0b;
assign DevWD = PrWD;
endmodule
