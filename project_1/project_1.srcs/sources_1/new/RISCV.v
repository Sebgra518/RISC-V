`timescale 1ns / 1ps

module RISCV(input wire clk);
    
    wire [31:0] count_out, program_out;
    wire [6:0] funct7, opcode;
    wire [2:0] funct3;
    wire [3:0] alu_ctrl;
    
    
    
    
    ProgramCounter(clk,0,count_out);
    ProgramMemory(count_out,program_out);
    InstructionDecode(program_out,funct7,rs2,rs1,funct3,rd,opcode,imm);
    
    ALUControl(funct7,funct3,opcode,alu_ctrl);
    
    ALU(inputA,inputB,alu_ctrl,result,zero);
    
    
    
endmodule