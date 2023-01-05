/*
 * schoolMIPS - small MIPS CPU for "Young Russian Chip Architects" 
 *              summer school ( yrca@googlegroups.com )
 *
 * originally based on Sarah L. Harris MIPS CPU 
 * 
 * Copyright(c) 2017 Stanislav Zhelnio 
 *                   Aleksandr Romanov 
 */ 

`include "sm_cpu.vh"

module sm_cpu
(
    input           clk,        // clock
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address register address
    output  [31:0]  regData,    // debug access reg data (like PC )
    output  [31:0]  imAddr,     // instruction memory address
    input   [31:0]  imData,     // instruction memory data
    output  [31:0]  dmAddr,     // data memory address
    output          dmWe,       // data memory write enable
    output  [31:0]  dmWData,    // data memory write data
    input   [31:0]  dmRData,     // data memory read data
    output  [31:0]  aluResult
);
    //control wires
    wire        pcSrc;
    wire        Jump;
    wire        regDst;
    wire        regWrite;
    wire        aluSrc;
    wire        aluZero;
    wire [ 2:0] aluControl;
    wire        memToReg;
    wire        memWrite;
    wire        lh_or_normal;
    wire        rt_0;
    wire        movn;
    wire        srl;
    wire        overflow;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch;
    wire [31:0] pcNext  = pc +1;
    wire [31:0] pc_new   = ~pcSrc ? pcNext : pcBranch;
    wire [27:0] pc_shifted = instr[25:0] <<2 ;
//    sl2 sl2(
//        .in (instr[25:0]),
//        .out (pc_shifted)
//    );
    wire [31:0] PCJump = { pcNext[31:28],pc_shifted };
    wire [31:0] pc_final = ~Jump ? pc_new : PCJump;
    sm_register r_pc(clk ,rst_n, pc_final, pc);

    //program memory access
    assign imAddr = pc;
    wire [31:0] instr = imData;

    //debug register access
    wire [31:0] rd0;
    assign regData = (regAddr != 0) ? rd0 : pc; // originally used for debug 
//    assign regData = rd1 ;  // here modified  

    //register file
    wire [ 4:0] a3  = regDst ? instr[15:11] : instr[20:16];
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3_ori;
    wire [31:0] wd3_mid;
    wire [31:0] wd3;

    sm_register_file rf
    (
        .clk        ( clk          ),
        .a0         ( regAddr      ), //used foe debug 
        .a1         ( instr[25:21] ),
        .a2         ( instr[20:16] ),
        .a3         ( a3           ),
        .rd0        ( rd0          ), //debug output
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite     )
    );

    //sign extension
    wire [31:0] signImm = { {16 { instr[15] }}, instr[15:0] };
    assign pcBranch = pcNext + signImm;

    //alu
    
    wire [31:0] srcA_1 = rt_0 ? 0 : rd1;
    wire [31:0] srcA = srl ? {{27{1'b0}},instr[10:6]}:srcA_1;
    wire [31:0] srcB = aluSrc ? signImm : rd2;

    sm_alu alu
    (
        .srcA       ( srcA          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .shift      ( instr[10:6 ] ),
        .zero       ( aluZero      ),
        .overflow   ( overflow     ),
        .result     ( aluResult    ) 
    );
    

    //data memory access
    assign wd3_ori = memToReg ? dmRData : aluResult;
    assign wd3_mid = lh_or_normal? { {16 {wd3_ori[15] }},wd3_ori[15:0]}:wd3_ori;
    assign wd3 = movn ? rd1 : wd3_mid ;
    assign dmWe = memWrite;
    assign dmAddr = aluResult;
    assign dmWData = rd2;

    //control
    sm_control sm_control
    (
        .cmdOper    ( instr[31:26] ),
        .cmdFunk    ( instr[ 5:0 ] ),
        .aluZero    ( aluZero      ),
        .overflow   ( overflow     ),              
        .pcSrc      ( pcSrc        ), 
        .Jump       ( Jump         ), 
        .regDst     ( regDst       ), 
        .regWrite   ( regWrite     ), 
        .aluSrc     ( aluSrc       ),
        .aluControl ( aluControl   ),
        .memWrite   ( memWrite     ),
        .memToReg   ( memToReg     ),
        .lh_or_normal(lh_or_normal ),
        .movn       ( movn         ),
        .rt_0       (rt_0          ),
        .srl        (srl           )

    );

endmodule

module sm_control
(
    input      [5:0] cmdOper,
    input      [5:0] cmdFunk,
    input            aluZero,
    input            overflow,
    output           pcSrc, 
    output reg          Jump,
    output reg       regDst, 
    output reg       regWrite, 
    output reg       aluSrc,
    output reg [2:0] aluControl,
    output reg       memWrite,
    output reg       memToReg,
    output reg       lh_or_normal,
    output reg       rt_0,
    output reg       movn,
    output reg       srl
);
    reg          branch;
    reg          condZero;
    assign pcSrc = branch & (aluZero == condZero);

    always @ (*) begin
        branch      = 1'b0;
        condZero    = 1'b0;
        regDst      = 1'b0;
        regWrite    = 1'b0;
        aluSrc      = 1'b0;
        aluControl  = `ALU_ADD;
        memWrite    = 1'b0;
        memToReg    = 1'b0;
        Jump        = 1'b0;
        lh_or_normal= 1'b0;
        rt_0        = 1'b0;
        movn        = 1'b0;
        srl         = 1'b0;

        casez( {cmdOper,cmdFunk} )
            default               : ;

            { `C_SPEC,  `F_ADDU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `C_SPEC,  `F_OR   } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `C_SPEC,  `F_SRL  } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `C_SPEC,  `F_SLTU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `C_SPEC,  `F_SUBU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_SUBU; end
            { `C_SPEC,  `F_MULU } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_MUL;  end
            { `C_SPEC,  `F_AND  } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_AND;  end
            { `C_SPEC,  `F_MOVN } : begin regDst = 1'b1; regWrite = aluZero ? 1'b0 : 1'b1;rt_0 = 1'b1; aluControl = `ALU_SUBU; movn = 1'b1; end
            { `C_SPEC,  `F_NOR  } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_NOR;  end
            { `C_SPEC,  `F_XOR  } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_XOR;  end
            { `C_SPEC,  `F_ROTR } : begin regDst = 1'b1; regWrite = 1'b1; aluControl = `ALU_ROTATE; srl = 1'b1; end
            { `C_SPEC,  `F_SUB  } : begin regDst = 1'b1; regWrite = overflow ? 1'b0: 1'b1; aluControl = `ALU_SUB; end

            { `C_ADDIU, `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD;  end
            { `C_LUI,   `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_LUI;  end
            { `C_LW,    `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; memToReg = 1'b1; end
            { `C_SW,    `F_ANY  } : begin memWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD;  end
            { `C_LH,    `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; memToReg = 1'b1;lh_or_normal = 1'b1; end
            { `C_ORI,   `F_ANY  } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_OR;   end

            { `C_BEQ,   `F_ANY  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUBU; end
            { `C_BNE,   `F_ANY  } : begin branch = 1'b1; aluControl = `ALU_SUBU; end
            { `C_JUMP,  `F_ANY  } : begin Jump = 1'b1; end
        endcase
    end
endmodule


module sm_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 2:0] oper,
    input  [ 4:0] shift,
    output        zero,
    output reg    overflow,
    output reg [31:0] result
);
    reg [31:0] temp;
    reg [31:0] digits;
    always @ (*) begin
        temp = srcB;
        digits = srcA;
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_LUI  : result = (srcB << 16);
            `ALU_SRL  : result = srcB >> shift;
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUBU : result = srcA - srcB;
            `ALU_MUL  : result = srcA * srcB;
            `ALU_AND  : result = srcA & srcB;
            `ALU_NOR  : result = ~ (srcA | srcB );
            `ALU_XOR  : result = srcA ^ srcB;
            `ALU_ROTATE : 
             begin 
                repeat (digits !=32'b0) begin
                result = {temp[0],temp[31:1]};
                digits = digits - 32'b1;
                end
              end
             `ALU_SUB : begin 
                result = srcA - srcB;
                overflow=((srcA[31]==0&&srcB[31]==1&&result[31]==1)||(srcA[31]==1&&srcB[31]==0&&result[31]==0))?1:0;
                end
        endcase
    end

    assign zero   = (result == 0);
endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule

module sl2(
    input [25:0] in,
    output [27:0] out
);
    assign out = in<<2;
endmodule