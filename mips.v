`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:28:23 12/31/2020 
// Design Name: 
// Module Name:    mips 
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
module mips(
    input clk,
    input reset,
    input interrupt,
    output [31:0] addr
    );
wire [15:10] PrInt;
wire [31:0]  PrRD;
wire [31:0]  PrWD;
wire PrWrite;
wire [31:0] PrAddr;
wire [31:2] DevAddr;
wire [6:1] DevWrite;
wire [31:0] DevRD1;
wire [31:0] DevRD2;
wire [31:0] DevWD;
wire [6:1] DevInt;

CPU	CPU(
	.clk(clk),
	.reset(reset),
	.intSrc(PrInt),
	.prRD(PrRD),
    .prWD(PrWD),
    .prWrite(PrWrite),
    .prAddr(PrAddr),
    .addr(addr)
	);

Bridge Bridge(
	.PrAddr(PrAddr),
    .PrWD(PrWD),
    .PrWrite(PrWrite),
    .PrRD(PrRD),
    .PrInt(PrInt),
    .DevAddr(DevAddr),
    .DevWrite(DevWrite),
    .DevRD1(DevRD1),
    .DevRD2(DevRD2),
    .DevWD(DevWD),
    .DevInt(DevInt)
	);

TC timer1(
	.clk(clk),
	.reset(reset),
	.Addr(DevAddr),
	.WE(DevWrite[1]),
	.Din(DevWD),
	.Dout(DevRD1),
	.IRQ(DevInt[1])
	);

TC timer2(
	.clk(clk),
	.reset(reset),
	.Addr(DevAddr),
	.WE(DevWrite[2]),
	.Din(DevWD),
	.Dout(DevRD2),
	.IRQ(DevInt[2])
	);

assign DevInt[3] = interrupt;

endmodule
