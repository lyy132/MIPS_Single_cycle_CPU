/*
 * schoolMIPS - small MIPS CPU for "Young Russian Chip Architects" 
 *              summer school ( yrca@googlegroups.com )
 *
 * originally based on Sarah L. Harris MIPS CPU 
 * 
 * Copyright(c) 2017 Stanislav Zhelnio 
 *                   Aleksandr Romanov 
 */ 

//ALU commands
`define ALU_ADD     4'b0000
`define ALU_OR      4'b0001
`define ALU_LUI     4'b0010
`define ALU_SRL     4'b0011
`define ALU_SLTU    4'b0100
`define ALU_SUBU    4'b0101
`define ALU_MUL     4'b0110
`define ALU_AND     4'b0111
`define ALU_NOR     4'b1000
`define ALU_XOR     4'b1001
`define ALU_ROTATE  4'b1010
`define ALU_SUB     4'b1011

//instruction operation code
`define C_SPEC      6'b000000 // Special instructions (depends on function field)
`define C_ADDIU     6'b001001 // I-type, Integer Add Immediate Unsigned
                              //         Rd = Rs + Immed
`define C_BEQ       6'b000100 // I-type, Branch On Equal
                              //         if (Rs == Rt) PC += (int)offset
`define C_LUI       6'b001111 // I-type, Load Upper Immediate
                              //         Rt = Immed << 16
`define C_BNE       6'b000101 // I-type, Branch on Not Equal
                              //         if (Rs != Rt) PC += (int)offset
`define C_LW        6'b100011 // I-type, Load Word
                              //         Rt = memory[Rs + Immed]
`define C_SW        6'b101011 //I-type,  Store Word
                              //         memory[Rs + Immed] = Rt
`define C_JUMP      6'b000010 //JUMP
`define C_LH        6'b100001//I_TYPE    LOAD HALFWORD
`define C_ORI       6'b001101 //I_type   OR immediate

//instruction function field
`define F_ADDU      6'b100001 // R-type, Integer Add Unsigned
                              //         Rd = Rs + Rt
`define F_OR        6'b100101 // R-type, Logical OR
                              //         Rd = Rs | Rt
`define F_SRL       6'b000010 // R-type, Shift Right Logical
                              //         Rd = Rs? >> shift
`define F_SLTU      6'b101011 // R-type, Set on Less Than Unsigned
                              //         Rd = (Rs? < Rt?) ? 1 : 0
`define F_SUBU      6'b100011 // R-type, Unsigned Subtract
                              //         Rd = Rs - Rt
`define F_MULU      6'b000010//R-type,multiplication 
                               //Rd = Rs * Rt
`define F_AND       6'b100100 //R-TYPE AND
                                //Rd = Rs and Rt    
`define F_MOVN      6'b001011 // MOVN (Move conditional on not zero)  
`define F_NOR       6'b100111 // NOR (Not or)
`define F_XOR       6'b100110 // Exclusive OR (Rd = Rs XOR Rt )      
`define F_ROTR      6'b000011 //Rotate word right 
`define F_SUB       6'b100010 //Subtract (considering overflow)                                                                                
`define F_ANY       6'b??????