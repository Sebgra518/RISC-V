`timescale 1ns / 1ps

module RISCV(input wire clk);
    
    wire [31:0] count_out, program_out;
    wire [6:0] funct7, opcode;
    wire [2:0] funct3;
    wire [3:0] alu_ctrl;
    
    reg reset = 0;
    
    ProgramCounter PC(clk,reset,count_out);
    
    ProgramMemory PM(count_out,program_out);
    InstructionDecode ID(program_out,funct7,rs2,rs1,funct3,rd,opcode,imm);
    
    RegisterFileRead RFR(clk,reset,1,rs1,imm,read_enable_1,read_address_1,read_data_1,read_enable_2,read_address_2,read_data_2);
    
    ALUControl ALUC(funct7,funct3,opcode,alu_ctrl);
    
    ALU ALU(inputA,inputB,alu_ctrl,result,zero);
    
    
    
endmodule