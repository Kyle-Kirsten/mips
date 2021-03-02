`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:22:50 11/24/2020 
// Design Name: 
// Module Name:    piplineStructDelay2 
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
//课上专用版流水线
//把流水线寄存器直接拆开成四个always块，避免写端口的繁琐
//always块中信号更新最好也分好类来写
//把instrDecoder拆开，避免写端口，
//信号定义时分好类别
//先把generate模板写好
//dm预留一个读端口以备不时之需(指不管关键路径暴力访存)
//instr直接流水以备不时之需
//rsData、rtData从Rf_Alu流水到Alu_Dm(带转发，同理用二阶段译码，把Crash信息也带过去)
//把IM_RF等流水线寄存器从1到4编号
//分布式译码，要用到相关数据时再拿出指令来译码
`define AdEL	5'd4
`define AdEs    5'd5
`define RI      5'd10
`define Ov      5'd12
`define Int     5'd0

`define SR      5'd12
`define Cause   5'd13
`define EPC     5'd14
`define PRId    5'd15
module CPU(
    input clk,
    input reset,
    input [15:10] intSrc,
    input [31:0] prRD,
    output [31:0] prWD,
    output prWrite,
    output [31:0] prAddr,
    output [31:0] addr
    );

//要用的信号线
//分组定义

//PC
wire en_PC;
wire [31:0] nextPC;
wire [31:0] PC;
//IM
wire [31:0] instr0;
//流水寄存器的几类通用信号
wire rst[1:4];
wire en[1:4];
reg [31:0] pc[1:4];
//regWrite和regWriteAddr在RF阶段译完码后直接流水就行，不用现译
wire nextRegWrite[1:4];
reg regWrite[1:4];
wire [4:0] nextRegWriteAddr[1:4];
reg [4:0] regWriteAddr[1:4];
wire [31:0] nextRsValue[1:4];
reg [31:0] rsValue[1:4];
wire [31:0] nextRtValue[1:4];
reg [31:0] rtValue[1:4];
//每阶段的初步译码可用generate实现
reg [31:0] instr[1:4];
wire [31:26] op[1:4];
wire [5:0] aluOp[1:4];
wire [25:0] instrIndex[1:4];
wire [25:21] rs[1:4];
wire [20:16] rt[1:4];
wire [15:11] rd[1:4];
wire [15:0]  imm[1:4];
wire [10:6] s[1:4];
wire isAddu[1:4];
wire isAdd[1:4];
wire isSubu[1:4];
wire isSub[1:4];
wire isAddiu[1:4];
wire isAddi[1:4];
wire isAnd[1:4];
wire isAndi[1:4];
wire isOri[1:4];
wire isOr[1:4];
wire isXor[1:4];
wire isXori[1:4];
wire isNor[1:4];
wire isNori[1:4];
wire isSll[1:4];
wire isSrl[1:4];
wire isSra[1:4];
wire isSllv[1:4];
wire isSrlv[1:4];
wire isSrav[1:4];
wire isSlt[1:4];
wire isSlti[1:4];
wire isSltu[1:4];
wire isSltiu[1:4];
wire isLui[1:4];
wire isLw[1:4];
wire isLh[1:4];
wire isLhu[1:4];
wire isLb[1:4];
wire isLbu[1:4];
wire isSw[1:4];
wire isSh[1:4];
wire isSb[1:4];
wire isBeq[1:4];
wire isBne[1:4];
wire isBlez[1:4];
wire isBltz[1:4];
wire isBgez[1:4];
wire isBgtz[1:4];
wire isJal[1:4];
wire isJr[1:4];
wire isJalr[1:4];
wire isJ[1:4];
wire isMultu[1:4];
wire isMult[1:4];
wire isDivu[1:4];
wire isDiv[1:4];
wire isMfhi[1:4];
wire isMthi[1:4];
wire isMflo[1:4];
wire isMtlo[1:4];
wire isNope[1:4];
wire isEret[1:4];
wire isMtc0[1:4];
wire isMfc0[1:4];
wire isUnknown[1:4];
wire isJump[1:4];
wire isLoad[1:4];
wire isStore[1:4];
//数据通路信号
//RF
wire [31:0] rsData;
wire [31:0] rtData;
//ALU
wire [31:0] nextCalcRes[1:4];
reg [31:0] calcRes[1:4];
wire [32:0] addRes;
wire [32:0] addiRes;
wire [32:0] subRes;
wire [32:0] sltRes;
wire [32:0] sltuRes;
wire [32:0] sltiRes;
wire [32:0] sltiuRes;
//ALU中的乘法器
wire start;
wire mulEn;
wire mulRst;
wire [32:0] opr1;
wire [32:0] opr2;
wire [63:0] multRes;
wire [31:0] divHi;
wire [31:0] divLo;
wire nextBusy;
reg busy;
wire [31:0] nextCount;
reg [31:0] count;
wire [31:0] nextHi;
reg [31:0] HI;
wire [31:0] nextLo;
reg [31:0] LO;
//CP0，放在ALU阶段
wire cp0En;
wire cp0Rst;
reg [31:0] CP0[0:31];
wire [31:0] nextSR;
wire [15:10] nextIM7_2;
wire [15:10] IM7_2;
wire nextEXL;
wire EXL;
wire nextIE;
wire IE;
wire [31:0] nextCause;
wire nextBD;
wire BD;
wire nextInDelay[1:4];
reg  inDelay[1:4];
wire inPrepheral;
wire [6:2] nextExcCode[1:4];
reg  [6:2] ExcCode[1:4];
wire nextIsExc[1:4];
reg  isExc[1:4];
wire [15:10] nextIP7_2;
wire [15:10] IP7_2;
wire [31:0] nextEPC;
wire intReq;
wire [31:0] nextPRId;
//两个计时器

//DM
wire [3:0] dmWrite;
wire [31:0] dmWriteData;
wire [31:0] nextDmReadData[1:4];
reg [31:0] dmReadData[1:4];
wire [31:0] dmRD;
//WB
wire [31:0] nextRegWriteData[1:4];
reg [31:0] regWriteData[1:4];
wire [31:0] realRegWriteData[1:4];
wire realRegWrite[1:4];
//冲突信号
wire rsRead;
wire rtRead;
wire [4:0] nextRsCrash[1:4];
reg [4:0] rsCrash[1:4]; //表示与rsCrash拍后的指令冲突，为0表示不冲突
wire [4:0] nextRtCrash[1:4];
reg [4:0] rtCrash[1:4];
wire [4:0] nextTnew[1:4];
reg [4:0] Tnew[1:4];
wire [4:0] Tnew1; //这个是由于只在RF阶段译码
wire [4:0] rsTuse;
wire [4:0] rtTuse;
wire [4:0] crashTnew;
//暂停信号
wire isStop;
//分支信号
wire isBranch;
wire [31:0] branchAddr;

//按数据通路连接模块
assign en_PC = !isStop||isEret[1]||isEret[2]||isEret[3];
assign nextPC = intReq||nextIsExc[4] ? 32'h00004180:
				isEret[4] ? CP0[`EPC] :
				isBranch ? branchAddr: PC+4;
PC PrgCnt (
    .clk(clk), 
    .rst(reset), 
    .en(en_PC), 
    .nextPC(nextPC), 
    .PC(PC)
    );
//异常更新
assign nextIsExc[1] = PC[1:0]!=0||PC<32'h00003000||PC>32'h00004ffc;
assign nextExcCode[1] = PC[1:0]!=0||PC<32'h00003000||PC>32'h00004ffc ? `AdEL : 0;

IM IM (
    .A(PC), 
    .D(instr0)
    );

assign rst[1] = reset||intReq||nextIsExc[4]||isEret[1]||isEret[2]||isEret[3]||isEret[4];
assign en[1]  = !isStop;
//IM_RF流水寄存器
always @(posedge clk) begin
    if (rst[1]) begin
        // reset
        instr[1] <= 0;
        pc[1] <= 0;
        inDelay[1] <= 0;
        isExc[1] <= 0;
        ExcCode[1] <= 0;
    end
    else if (en[1]) begin
        instr[1] <= instr0;
        pc[1] <= PC;
        inDelay[1] <= isJump[1];
        isExc[1] <= nextIsExc[1];
        ExcCode[1] <= nextExcCode[1];
    end
end
//初步译码器
genvar i;
generate
    for (i=1; i<=4; i=i+1) 
    begin: decode
    assign op[i] = instr[i][31:26];
    assign aluOp[i] = instr[i][5:0];
    assign instrIndex[i] = instr[i][25:0];
    assign rs[i] = instr[i][25:21];
    assign rt[i] = instr[i][20:16];
    assign rd[i] = instr[i][15:11];
    assign imm[i] = instr[i][15:0];
    assign s[i] = instr[i][10:6];

    assign isAddu[i] = (op[i]=='b000000&&aluOp[i]=='b100001);
    assign isSubu[i] = (op[i]=='b000000&&aluOp[i]=='b100011);
    assign isAdd[i]  = (op[i]=='b000000&&aluOp[i]=='b100000);
    assign isSub[i]  = (op[i]=='b000000&&aluOp[i]=='b100010);
    assign isOr[i]   = (op[i]=='b000000&&aluOp[i]=='b100101);
    assign isAnd[i]  = (op[i]=='b000000&&aluOp[i]=='b100100);
    assign isXor[i]  = (op[i]=='b000000&&aluOp[i]=='b100110);
    assign isNor[i]  = (op[i]=='b000000&&aluOp[i]=='b100111);
    assign isSlt[i]  = (op[i]=='b000000&&aluOp[i]=='b101010);
    assign isSltu[i] = (op[i]=='b000000&&aluOp[i]=='b101011);
    assign isSll[i]  = (op[i]=='b000000&&aluOp[i]=='b000000);
    assign isSrl[i]  = (op[i]=='b000000&&aluOp[i]=='b000010);
    assign isSra[i]  = (op[i]=='b000000&&aluOp[i]=='b000011);
    assign isSllv[i] = (op[i]=='b000000&&aluOp[i]=='b000100);
    assign isSrlv[i] = (op[i]=='b000000&&aluOp[i]=='b000110);
    assign isSrav[i] = (op[i]=='b000000&&aluOp[i]=='b000111);

    assign isMult[i] = (op[i]=='b000000&&aluOp[i]=='b011000);
    assign isMultu[i] = (op[i]=='b000000&&aluOp[i]=='b011001);
    assign isDiv[i] = (op[i]=='b000000&&aluOp[i]=='b011010);
    assign isDivu[i] = (op[i]=='b000000&&aluOp[i]=='b011011);
    assign isMfhi[i] = (op[i]=='b000000&&aluOp[i]=='b010000);
    assign isMflo[i] = (op[i]=='b000000&&aluOp[i]=='b010010);
    assign isMthi[i] = (op[i]=='b000000&&aluOp[i]=='b010001);
    assign isMtlo[i] = (op[i]=='b000000&&aluOp[i]=='b010011);

    assign isSlti[i] = (op[i]=='b001010);
    assign isSltiu[i]= (op[i]=='b001011);    
    assign isAddi[i] = (op[i]=='b001000);
    assign isAddiu[i]= (op[i]=='b001001);
    assign isOri[i]  = (op[i]=='b001101);
    assign isAndi[i] = (op[i]=='b001100);
    assign isXori[i] = (op[i]=='b001110);
    assign isNori[i] = 0;
    assign isLui[i]  = (op[i]=='b001111);

    assign isLw[i]   = (op[i]=='b100011);
    assign isSw[i]   = (op[i]=='b101011);
    assign isLb[i]   = (op[i]=='b100000);
    assign isLbu[i]  = (op[i]=='b100100);
    assign isLh[i]   = (op[i]=='b100001);
    assign isLhu[i]  = (op[i]=='b100101);
    assign isSb[i]   = (op[i]=='b101000);
    assign isSh[i]   = (op[i]=='b101001);

    assign isBeq[i]  = (op[i]=='b000100);
    assign isBne[i]  = (op[i]=='b000101);
    assign isBltz[i] = (op[i]=='b000001&&rt[i]=='b00000);
    assign isBlez[i] = (op[i]=='b000110);
    assign isBgez[i] = (op[i]=='b000001&&rt[i]=='b00001);
    assign isBgtz[i] = (op[i]=='b000111);
    assign isJal[i]  = (op[i]=='b000011);
    assign isJr[i]   = (op[i]=='b000000&&aluOp[i]=='b001000);
    assign isJalr[i] = (op[i]=='b000000&&aluOp[i]=='b001001);
    assign isJ[i]    = (op[i]=='b000010);

    assign isEret[i] = (op[i]=='b010000&&aluOp[i]=='b011000);
    assign isMtc0[i] = (op[i]=='b010000&&rs[i]=='b00100);
    assign isMfc0[i] = (op[i]=='b010000&&rs[i]=='b00000);

    //跳转且有延迟槽的指令
    assign isJump[i] = isJ[i]||isJr[i]||isJalr[i]||isJal[i]
    					||isBeq[i]||isBne[i]||isBlez[i]||isBltz[i]||isBgez[i]||isBgtz[i];
    assign isLoad[i] = isLw[i]||isLh[i]||isLhu[i]||isLb[i]||isLbu[i];
    assign isStore[i] = isSw[i]||isSh[i]||isSb[i];
    assign isNope[i] = (instr[i]==0);
    assign isUnknown[i] = !(isAdd[i]||isAddu[i]||isAddi[i]||isAddiu[i]
    						||isSub[i]||isSubu[i]||isOr[i]||isOri[i]
    						||isAndi[i]||isAnd[i]||isXor[i]||isXori[i]||isNor[i]
    						||isSlt[i]||isSlti[i]||isSltu[i]||isSltiu[i]
    						||isSll[i]||isSrl[i]||isSra[i]||isSllv[i]||isSrlv[i]||isSrav[i]
    						||isMult[i]||isMultu[i]||isDiv[i]||isDivu[i]||isMthi[i]||isMtlo[i]||isMfhi[i]||isMflo[i]
    						||isLui[i]||isLw[i]||isLh[i]||isLhu[i]||isLb[i]||isLbu[i]||isSw[i]||isSh[i]||isSb[i]
    						||isBeq[i]||isBne[i]||isBlez[i]||isBltz[i]||isBgez[i]||isBgtz[i]
    						||isJal[i]||isJr[i]||isJalr[i]||isJ[i]
    						||isEret[i]||isMtc0[i]||isMfc0[i]);
    
    end
endgenerate
//跳转
assign isBranch = isJ[1]||isJal[1]||isJr[1]||isJalr[1]
                    ||isBeq[1]&&(nextRsValue[2]==nextRtValue[2])
                    ||isBne[1]&&(nextRsValue[2]!=nextRtValue[2])
                    ||isBlez[1]&&($signed($signed(nextRsValue[2])<=$signed(0)))
                    ||isBltz[1]&&($signed($signed(nextRsValue[2])<$signed(0)))
                    ||isBgez[1]&&($signed($signed(nextRsValue[2])>=$signed(0)))
                    ||isBgtz[1]&&($signed($signed(nextRsValue[2])>$signed(0)));
assign branchAddr = (isJr[1]||isJalr[1]) ? nextRsValue[2]: 
                         (isJ[1]||isJal[1])   ? {pc[1][31:28], instrIndex[1], 2'b0} : pc[1]+4+{{14{imm[1][15]}}, imm[1], 2'b0};
//冲突
assign rsRead = isMult[1]||isDiv[1]||isMultu[1]||isDivu[1]||isMthi[1]||isMtlo[1]
                ||isAddu[1]||isAdd[1]||isAddi[1]||isAddiu[1]||isSubu[1]||isSub[1]
                ||isOr[1]||isOri[1]||isAnd[1]||isAndi[1]||isXor[1]||isXori[1]||isNor[1]||isNori[1]
                ||isSllv[1]||isSrlv[1]||isSrav[1]
                ||isSlt[1]||isSlti[1]||isSltu[1]||isSltiu[1]
                ||isLw[1]||isLb[1]||isLbu[1]||isLh[1]||isLhu[1]
                ||isSw[1]||isSb[1]||isSh[1]
                ||isBeq[1]||isBne[1]||isBltz[1]||isBlez[1]||isBgtz[1]||isBgez[1]
                ||isJr[1]||isJalr[1];
assign rtRead = isMult[1]||isDiv[1]||isMultu[1]||isDivu[1]||isMtc0[1]
                ||isAdd[1]||isAddu[1]||isSubu[1]||isSub[1]||isOr[1]||isAnd[1]||isXor[1]||isNor[1]
                ||isSll[1]||isSllv[1]||isSrl[1]||isSrlv[1]||isSra[1]||isSrav[1]
                ||isSlt[1]||isSltu[1]
                ||isSw[1]||isSb[1]||isSh[1]
                ||isBeq[1]||isBne[1];

assign rsTuse = isMult[1]||isDiv[1]||isMultu[1]||isDivu[1]||isMthi[1]||isMtlo[1]
                ||isAddu[1]||isAdd[1]||isAddi[1]||isAddiu[1]||isSubu[1]||isSub[1]
                ||isOr[1]||isOri[1]||isAnd[1]||isAndi[1]||isXor[1]||isXori[1]||isNor[1]||isNori[1]
                ||isSllv[1]||isSrlv[1]||isSrav[1]
                ||isSlt[1]||isSlti[1]||isSltu[1]||isSltiu[1]
                ||isLw[1]||isLb[1]||isLbu[1]||isLh[1]||isLhu[1]
                ||isSw[1]||isSb[1]||isSh[1] ? 1:
				isBeq[1]||isBne[1]||isBltz[1]||isBlez[1]||isBgtz[1]||isBgez[1]
                ||isJr[1]||isJalr[1] ? 0 : 3;
assign rtTuse = isMult[1]||isDiv[1]||isMultu[1]||isDivu[1]||isMtc0[1]
                ||isAdd[1]||isAddu[1]||isSubu[1]||isSub[1]||isOr[1]||isAnd[1]||isXor[1]||isNor[1]
                ||isSll[1]||isSllv[1]||isSrl[1]||isSrlv[1]||isSra[1]||isSrav[1]
                ||isSlt[1]||isSltu[1] ? 1:
				isSw[1]||isSb[1]||isSh[1] ? 2:
				isBeq[1]||isBne[1] ? 0: 3;
//为最大化延展性，Tnew表示结果写到regWriteData里还需要的拍数，这样转发代码就统一了
//乘除特判，不用AT法
assign Tnew1  = isMfhi[1]||isMflo[1]||isMfc0[1]
                ||isAddu[1]||isAdd[1]||isAddi[1]||isAddiu[1]||isSubu[1]||isSub[1]
                ||isOr[1]||isOri[1]||isAnd[1]||isAndi[1]||isXor[1]||isXori[1]||isNor[1]||isNori[1]
                ||isSllv[1]||isSrlv[1]||isSrav[1]||isSll[1]||isSrl[1]||isSra[1]
                ||isSlt[1]||isSlti[1]||isSltu[1]||isSltiu[1] ? 2:
				isLw[1]||isLb[1]||isLbu[1]||isLh[1]||isLhu[1] ? 3:
				isJal[1]||isJalr[1]||isLui[1] ? 1: 0;
//Tnew递减到0就保持不变
assign nextTnew[2] = Tnew1==0 ? 0 : Tnew1-1;
generate
    for (i=2; i<4;i = i+1)
    begin: TnewCnt
    assign nextTnew[i+1] = Tnew[i]==0 ? 0 : Tnew[i]-1;
    end
endgenerate
//rsCrash[i]表示与其冲突的指令在之后的第几拍，比较特殊的是move指令，因为此时Tnew理论上和move之前的指令相关
//这时需要追溯到第一个不是Move或不冲突的指令，或忍受浪费，取Tnew为crashTnew+1
//最简单的做法是看成addiu $t, 0指令，则Tnew1 = 2
assign nextRsCrash[2] = (rs[1]!=0&&rsRead) ?
                            (regWrite[2]&&rs[1]==regWriteAddr[2]) ? 1:
                            (regWrite[3]&&rs[1]==regWriteAddr[3]) ? 2:
                            (regWrite[4]&&rs[1]==regWriteAddr[4]) ? 3: 0
                        : 0;
assign nextRtCrash[2] = (rt[1]!=0&&rtRead) ?
                            (regWrite[2]&&rt[1]==regWriteAddr[2]) ? 1:
                            (regWrite[3]&&rt[1]==regWriteAddr[3]) ? 2:
                            (regWrite[4]&&rt[1]==regWriteAddr[4]) ? 3: 0
                        : 0;
assign crashTnew = (nextRsCrash[2]==1||nextRtCrash[2]==1) ? Tnew[2] :
                    (nextRsCrash[2]==2||nextRtCrash[2]==2) ? Tnew[3] : 0;
//暂停
assign isStop = nextRsCrash[2]!=0&&rsTuse<crashTnew||nextRtCrash[2]!=0&&rtTuse<crashTnew
                ||(isMult[1]||isDiv[1]||isMultu[1]||isDivu[1]
                    ||isMthi[1]||isMtlo[1]||isMfhi[1]||isMtlo[1])&&(busy||start); 

//RF
RF RF (
    .clk(clk), 
    .rst(reset), 
    .rsAddr(rs[1]), 
    .rtAddr(rt[1]), 
    .WA(regWriteAddr[4]), 
    .WD(realRegWriteData[4]), 
    .regWrite(realRegWrite[4]), 
    .PC(pc[4]),
    .rsData(rsData), 
    .rtData(rtData)
    );
//转发
assign nextRsValue[2] = (nextRsCrash[2]==1) ? realRegWriteData[2]:
                    (nextRsCrash[2]==2) ? realRegWriteData[3]:
                    (nextRsCrash[2]==3) ? realRegWriteData[4]: rsData;
assign nextRtValue[2] = (nextRtCrash[2]==1) ? realRegWriteData[2]:
                    (nextRtCrash[2]==2) ? realRegWriteData[3]:
                    (nextRtCrash[2]==3) ? realRegWriteData[4]: rtData;
//寄存器读写相关译码
assign nextRegWrite[2] = isMfhi[1]||isMflo[1]||isMfc0[1]
                        ||isAddu[1]||isAdd[1]||isAddi[1]||isAddiu[1]||isSubu[1]||isSub[1]
                        ||isOr[1]||isOri[1]||isAnd[1]||isAndi[1]||isXor[1]||isXori[1]||isNor[1]||isNori[1]
                        ||isSllv[1]||isSrlv[1]||isSrav[1]||isSll[1]||isSrl[1]||isSra[1]
                        ||isSlt[1]||isSlti[1]||isSltu[1]||isSltiu[1]
                        ||isLw[1]||isLb[1]||isLbu[1]||isLh[1]||isLhu[1]
                        ||isJal[1]||isJalr[1]||isLui[1];
assign nextRegWriteAddr[2] = isMfhi[1]||isMflo[1]
                            ||isAdd[1]||isAddu[1]||isSubu[1]||isSub[1]||isOr[1]||isAnd[1]||isXor[1]||isNor[1]
                            ||isSll[1]||isSllv[1]||isSrl[1]||isSrlv[1]||isSra[1]||isSrav[1]
                            ||isSlt[1]||isSltu[1]
                            ||isJalr[1] ? rd[1]:
                            isAddi[1]||isAddiu[1]||isOri[1]||isAndi[1]||isXori[1]||isNori[1]
                            ||isSlti[1]||isSltiu[1]||isMfc0[1]
                            ||isLw[1]||isLb[1]||isLbu[1]||isLh[1]||isLhu[1]||isLui[1]   ? rt[1]:
                             isJal[1]                         ? 5'd31: 5'd0;
assign nextRegWriteData[2] = isJal[1]||isJalr[1] ? pc[1]+8:
                             isLui[1] ? {imm[1], 16'b0}: 0;
//异常相关
assign nextIsExc[2] = isExc[1]||isUnknown[1];
assign nextExcCode[2] = isExc[1] ? ExcCode[1]
						: isUnknown[1] ? `RI : 0;
//RF_ALU
assign rst[2] = reset||intReq&&intIndex>0||nextIsExc[4]||isStop;
assign en[2] = 1;
always @(posedge clk) begin
    if (rst[2]) begin
        // reset
        rsValue[2] <= 0;
        rtValue[2] <= 0;
        regWrite[2] <= 0;
        regWriteAddr[2] <= 0;
        regWriteData[2] <= 0;
        rsCrash[2] <= 0;
        rtCrash[2] <= 0;
        Tnew[2] <= 0;
        pc[2] <= 0;
        instr[2] <= 0;
        inDelay[2] <= 0;
        isExc[2] <= 0;
        ExcCode[2] <= 0;
    end
    else if (en[2]) begin
        rsValue[2] <= nextRsValue[2];
        rtValue[2] <= nextRtValue[2];
        regWrite[2] <= nextRegWrite[2];
        regWriteAddr[2] <= nextRegWriteAddr[2];
        regWriteData[2] <= nextRegWriteData[2];
        rsCrash[2] <= nextRsCrash[2];
        rtCrash[2] <= nextRtCrash[2];
        Tnew[2] <= nextTnew[2];
        pc[2] <= pc[1];
        instr[2] <= instr[1];
        inDelay[2] <= inDelay[1];
        isExc[2] <= nextIsExc[2];
        ExcCode[2] <= nextExcCode[2];
    end
end
//ALU
assign realRegWriteData[2] = regWriteData[2];
//转发
assign nextRsValue[3] = rsCrash[2]==1 ? realRegWriteData[3] :
                        rsCrash[2]==2 ? realRegWriteData[4] : rsValue[2];
assign nextRtValue[3] = rtCrash[2]==1 ? realRegWriteData[3] :
                        rtCrash[2]==2 ? realRegWriteData[4] : rtValue[2];
//ALU运算
assign addRes = {nextRsValue[3][31], nextRsValue[3]} + {nextRtValue[3][31], nextRtValue[3]};
assign addiRes = {nextRsValue[3][31], nextRsValue[3]} + {{17{imm[2][15]}}, imm[2]};
assign subRes = {nextRsValue[3][31], nextRsValue[3]} - {nextRtValue[3][31], nextRtValue[3]};
assign sltRes = $signed($signed(nextRsValue[3])<$signed(nextRtValue[3])) ? 1 : 0;
assign sltuRes = nextRsValue[3]<nextRtValue[3] ? 1 : 0;
assign sltiRes = $signed($signed(nextRsValue[3])<$signed({{16{imm[2][15]}}, imm[2]})) ? 1 : 0;
assign sltiuRes = nextRsValue[3]<{{16{imm[2][15]}}, imm[2]} ? 1 : 0;
assign nextCalcRes[3] = isAdd[2]||isAddu[2] ? addRes[31:0]:
                        isAddi[2]||isAddiu[2]
                        ||isLw[2]||isLb[2]||isLbu[2]||isLh[2]||isLhu[2]
                        ||isSw[2]||isSb[2]||isSh[2] ? addiRes[31:0]:
                        isSub[2]||isSubu[2] ? subRes[31:0]:
                        isOr[2]  ? nextRsValue[3] | nextRtValue[3]:
                        isOri[2] ? nextRsValue[3] | {16'b0, imm[2]}:
                        isAnd[2] ? nextRsValue[3] & nextRtValue[3]:
                        isAndi[2] ? nextRsValue[3] & {16'b0, imm[2]}: 
                        isXor[2] ? nextRsValue[3] ^ nextRtValue[3]:
                        isXori[2] ? nextRsValue[3] ^ {16'b0, imm[2]}:
                        isNor[2] ? ~(nextRsValue[3] | nextRtValue[3]):
                        isNori[2] ? ~(nextRsValue[3] | {16'b0, imm[2]}):
                        isSlt[2] ? sltRes[31:0]:
                        isSltu[2] ? sltuRes[31:0]:
                        isSlti[2] ? sltiRes[31:0]:
                        isSltiu[2] ? sltiuRes[31:0]:
                        isSll[2] ? nextRtValue[3]<<s[2]:
                        isSllv[2] ? nextRtValue[3]<<nextRsValue[3][4:0]:
                        isSrl[2] ? nextRtValue[3]>>s[2]:
                        isSrlv[2] ? nextRtValue[3]>>nextRsValue[3][4:0]:
                        isSra[2] ? $signed($signed(nextRtValue[3])>>>s[2]):
                        isSrav[2] ? $signed($signed(nextRtValue[3])>>>nextRsValue[3][4:0]): 0;
//溢出异常
assign nextIsExc[3] = isExc[2]
					||isAdd[2]&&addRes[32]!=addRes[31]||isAddi[2]&&addiRes[32]!=addiRes[31]||isSub[2]&&subRes[32]!=subRes[31]
					||isLw[2]&&addiRes[1:0]!=0||(isLh[2]||isLhu[2])&&addiRes[0]!=0
						||(isLh[2]||isLhu[2]||isLb[2]||isLbu[2])&&inPrepheral
						||isLoad[2]&&(addiRes[31]!=addiRes[32]||!inPrepheral&&addiRes[31:0]>32'h00002fff)
					||isSw[2]&&addiRes[1:0]!=0||isSh[2]&&addiRes[0]!=0
						||(isSh[2]||isSb[2])&&inPrepheral
						||isStore[2]&&(addiRes[31]!=addiRes[32]||!inPrepheral&&addiRes[31:0]>32'h00002fff
							||addiRes[31:0]==32'h00007f08||addiRes[31:0]==32'h00007f18);

assign inPrepheral = addiRes[31:0]>=32'h00007f00&&addiRes[31:0]<=32'h00007f0b
			||addiRes[31:0]>=32'h00007f10&&addiRes[31:0]<=32'h00007f1b;
assign nextExcCode[3] = isExc[2] ? ExcCode[2] :
						isAdd[2]&&addRes[32]!=addRes[31]||isAddi[2]&&addiRes[32]!=addiRes[31]
							||isSub[2]&&subRes[32]!=subRes[31] ? `Ov :
						isLw[2]&&addiRes[1:0]!=0||(isLh[2]||isLhu[2])&&addiRes[0]!=0
							||(isLh[2]||isLhu[2]||isLb[2]||isLbu[2])&&inPrepheral
							||isLoad[2]&&(addiRes[31]!=addiRes[32]||!inPrepheral&&addiRes[31:0]>32'h00002fff)
							? `AdEL :
						isSw[2]&&addiRes[1:0]!=0||isSh[2]&&addiRes[0]!=0
							||(isSh[2]||isSb[2])&&inPrepheral
							||isStore[2]&&(addiRes[31]!=addiRes[32]||!inPrepheral&&addiRes[31:0]>32'h00002fff
								||addiRes[31:0]==32'h00007f08||addiRes[31:0]==32'h00007f18)
							? `AdEs : 0;
//乘除模块
assign start = isMult[2]||isMultu[2]||isDiv[2]||isDivu[2];
assign opr1 = isDiv[2]||isMult[2] ? {nextRsValue[3][31], nextRsValue[3]} : {1'b0, nextRsValue[3]};
assign opr2 = isDiv[2]||isMult[2] ? {nextRtValue[3][31], nextRtValue[3]} : {1'b0, nextRtValue[3]};
assign multRes = $signed(opr1)*$signed(opr2);
assign divHi = $signed(opr1)%$signed(opr2);
assign divLo = $signed(opr1)/$signed(opr2);
assign nextHi = isMthi[2] ? nextRsValue[3]:
                isMult[2]||isMultu[2] ? multRes[63:32]:
                isDiv[2]||isDivu[2] ? divHi: HI;
assign nextLo = isMtlo[2] ? nextRsValue[3]:
                isMult[2]||isMultu[2] ? multRes[31:0]:
                isDiv[2]||isDivu[2] ? divLo: LO;
assign nextBusy = (count==0&&start) ? 1 : 
                    (count==1) ? 0 : busy;
assign nextCount = (count==0) ? 
                        (isMult[2]||isMultu[2]) ? 5 :
                        (isDiv[2]||isDivu[2]) ? 10 : 0
                    : count-1;
assign mulEn = !(intReq&&intIndex>1||nextIsExc[4]||nextIsExc[3]);
assign mulRst = reset;
always @(posedge clk) begin
    if (mulRst) begin
        // reset
        HI <= 0;
        LO <= 0;
        count <= 0;
        busy <= 0;
    end
    else if (mulEn) begin
        HI <= nextHi;
        LO <= nextLo;
        count <= nextCount;
        busy <= nextBusy;
    end
end
//CP0
assign intReq = (|(IM7_2&intSrc[15:10])) & IE & !EXL;
assign IE = CP0[`SR][0];
assign EXL = CP0[`SR][1];
assign IM7_2 = CP0[`SR][15:10];
assign cp0Rst = reset;
assign cp0En  = !(intReq&&intIndex>1||nextIsExc[4]||nextIsExc[3])&&isMtc0[2];
assign nextSR = intReq||nextIsExc[4] ? {CP0[`SR][31:2], 1'b1, CP0[`SR][0]} : CP0[`SR];
//保证发生中断时受害指令不在延迟槽中（不然逻辑上有问题
assign nextCause = intReq ? {1'b0, 15'b0, intSrc[15:10], 3'b0, `Int, 2'b0}
				: nextIsExc[4] ? {inDelay[3], 15'b0, 6'b0, 3'b0, nextExcCode[4], 2'b0}
				: CP0[`Cause];
assign intIndex = nextIsExc[4] ? 
					inDelay[3] ? 4 : 3
				: isJump[3] ? 3
				: pc[2]!=0 ? 2
				: pc[1]!=0 ? 1 : 0;
assign nextEPC =  intReq ? 
					intIndex==0 ? PC:
					intIndex==1 ? pc[1]:
					intIndex==2 ? pc[2]:
					intIndex==3 ? pc[3]:
					intIndex==4 ? pc[4]: CP0[`EPC]
				: nextIsExc[4] ? 
					inDelay[3] ? pc[4] : pc[3]
				: CP0[`EPC];
always @(posedge clk) begin
	if (cp0Rst) begin
		// reset
        begin:resetCP0
            integer i;
		    for (i=0; i<32; i=i+1) begin 
			     CP0[i] <= 0;
		    end
        end
	end
	else if (cp0En) begin
		CP0[rd[2]] <= nextRtValue[3];
	end else begin
		CP0[`SR] <= nextSR;
		CP0[`Cause] <= nextCause;
		CP0[`EPC] <= nextEPC;
	end
end
//寄存器写数据
assign nextRegWriteData[3] = isAddu[2]||isAdd[2]||isAddi[2]||isAddiu[2]||isSubu[2]||isSub[2]
                            ||isOr[2]||isOri[2]||isAnd[2]||isAndi[2]||isXor[2]||isXori[2]||isNor[2]||isNori[2]
                            ||isSllv[2]||isSrlv[2]||isSrav[2]||isSll[2]||isSrl[2]||isSra[2]
                            ||isSlt[2]||isSlti[2]||isSltu[2]||isSltiu[2] ? nextCalcRes[3]: 
                             isMfhi[2] ? HI : 
                             isMflo[2] ? LO : 
                             isMfc0[2] ? CP0[rd[2]] : realRegWriteData[2];
//ALU_DM
assign rst[3] = reset||intReq&&intIndex>1||nextIsExc[4];
assign en[3] = 1;
always @(posedge clk) begin
    if (rst[3]) begin
        // reset
        rsValue[3] <= 0;
        rtValue[3] <= 0;
        calcRes[3] <= 0;
        regWriteData[3] <= 0;
        regWrite[3] <= 0;
        regWriteAddr[3] <= 0;
        rsCrash[3] <= 0;
        rtCrash[3] <= 0;
        Tnew[3] <= 0;
        instr[3] <= 0;
        pc[3] <= 0;
        inDelay[3] <= 0;
        isExc[3] <= 0;
        ExcCode[3] <= 0;
    end
    else if (en[3]) begin
        rsValue[3] <= nextRsValue[3];
        rtValue[3] <= nextRtValue[3];
        calcRes[3] <= nextCalcRes[3];
        regWriteData[3] <= nextRegWriteData[3];
        regWrite[3] <= regWrite[2];
        regWriteAddr[3] <= regWriteAddr[2];
        rsCrash[3] <= rsCrash[2];
        rtCrash[3] <= rtCrash[2];
        Tnew[3] <= nextTnew[3];
        instr[3] <= instr[2];
        pc[3] <= pc[2];
        inDelay[3] <= inDelay[2];
        isExc[3] <= nextIsExc[3];
        ExcCode[3] <= nextExcCode[3];
    end
end
//异常相关
assign nextIsExc[4] = isExc[3];
assign nextExcCode[4] = ExcCode[3];
//DM
assign realRegWriteData[3] = regWriteData[3];
//转发
assign nextRsValue[4] = rsCrash[3]==1 ? realRegWriteData[4] : rsValue[3];
assign nextRtValue[4] = rtCrash[3]==1 ? realRegWriteData[4] : rtValue[3];
//访存
assign dmWriteData = isSb[3] ? 
                        calcRes[3][1:0]==1 ? {16'b0, nextRtValue[4][7:0], 8'b0}:
                        calcRes[3][1:0]==2 ? {8'b0, nextRtValue[4][7:0], 16'b0}:
                        calcRes[3][1:0]==3 ? {nextRtValue[4][7:0], 24'b0}: nextRtValue[4]
                    : isSh[3] ?
                        calcRes[3][1:0]==2 ? {nextRtValue[4][15:0], 16'b0} : nextRtValue[4]
                    : nextRtValue[4]; 
assign dmWrite = 	intReq&&intIndex>2||nextIsExc[4]||calcRes[3]>32'h00002fff ? 4'b0000 :
					isSb[3] ? 4'b0001<<calcRes[3][1:0] :
                    isSh[3] ? 4'b0011<<calcRes[3][1:0] :
                    isSw[3] ? 4'b1111 : 4'b0000;
DM DM (
    .clk(clk), 
    .rst(reset), 
    .A(calcRes[3]), 
    .WD(dmWriteData), 
    .dmWrite(dmWrite), 
    .PC(pc[3]),
    .RD(dmRD)
    );
//访问外设
assign prAddr = calcRes[3];
assign prWD   = dmWriteData;
assign prWrite = !(intReq&&intIndex>2||nextIsExc[4])&&isSw[3]&&calcRes[3]>32'h00002fff;
assign nextDmReadData[4] = calcRes[3]>32'h00002fff ? prRD : dmRD;
//寄存器写数据
assign nextRegWriteData[4] = realRegWriteData[3];
//DM_RF
assign rst[4] = reset||intReq&&intIndex>2||nextIsExc[4];
assign en[4] = 1;
always @(posedge clk) begin
    if (rst[4]) begin
        // reset
        rsValue[4] <= 0;
        rtValue[4] <= 0;
        regWriteData[4] <= 0;
        regWriteAddr[4] <= 0;
        regWrite[4] <= 0;
        dmReadData[4] <= 0;
        calcRes[4] <= 0;
        Tnew[4] <= 0;
        instr[4] <= 0;
        pc[4] <= 0;
    end
    else if (en[4]) begin
        rsValue[4] <= nextRsValue[4];
        rtValue[4] <= nextRtValue[4];
        regWriteData[4] <= nextRegWriteData[4];
        regWriteAddr[4] <= regWriteAddr[3];
        regWrite[4] <= regWrite[3];
        dmReadData[4] <= nextDmReadData[4];
        calcRes[4] <= calcRes[3];
        Tnew[4] <= nextTnew[4];
        instr[4] <= instr[3];
        pc[4] <= pc[3];
    end
end
//处理Lb等指令
assign realRegWriteData[4] = isLb[4] ? 
                                calcRes[4][1:0]==0 ? {{24{dmReadData[4][7]}}, dmReadData[4][7:0]}:
                                calcRes[4][1:0]==1 ? {{24{dmReadData[4][15]}}, dmReadData[4][15:8]}:
                                calcRes[4][1:0]==2 ? {{24{dmReadData[4][23]}}, dmReadData[4][23:16]}:
                                {{24{dmReadData[4][31]}}, dmReadData[4][31:24]}
                            : isLbu[4] ? 
                                calcRes[4][1:0]==0 ? {24'b0, dmReadData[4][7:0]}:
                                calcRes[4][1:0]==1 ? {24'b0, dmReadData[4][15:8]}:
                                calcRes[4][1:0]==2 ? {24'b0, dmReadData[4][23:16]}:
                                {24'b0, dmReadData[4][31:24]}
                            : isLh[4] ?
                                calcRes[4][1:0]==0 ? {{16{dmReadData[4][15]}}, dmReadData[4][15:0]}:
                                calcRes[4][1:0]==1 ? {{16{dmReadData[4][23]}}, dmReadData[4][23:8]}:
                                 {{16{dmReadData[4][31]}}, dmReadData[4][31:16]}
                            : isLhu[4] ? 
                                calcRes[4][1:0]==0 ? {16'b0, dmReadData[4][15:0]}:
                                calcRes[4][1:0]==1 ? {16'b0, dmReadData[4][23:8]}:
                                 {16'b0, dmReadData[4][31:16]}
                            : isLw[4] ? dmReadData[4]
                            : regWriteData[4] ;
assign realRegWrite[4] = intReq&&nextIsExc[4]&&inDelay[3] ? 0 : regWrite[4];
//只有当同时发生中断和异常，且受害指令在延迟槽中时，需要从第4阶段的指令开始重新执行，故此时不能写RF
//其它情况重新开始执行的指令均可以在第4阶段之前，故可以写RF
assign addr = pc[4]!=0 ? pc[4] :
			  pc[3]!=0 ? pc[3] :
			  pc[2]!=0 ? pc[2] :
			  pc[1]!=0 ? pc[1] : PC;
endmodule
