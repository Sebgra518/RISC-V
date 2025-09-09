`timescale 1ns / 1ps

module sim();
    reg clk;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire [31:0] debug_imm;
    wire [6:0] debug_funct7, debug_opcode;
    wire [4:0]  debug_rs1, debug_rs2, debug_rd;
    wire [2:0] debug_funct3;
    
    initial begin
        clk = 0;
    end
        
    always #1 clk = ~clk;  // Toggle clock every 10 time units (50 MHz)
    
    RISCV RISCV(clk,debug_pc,debug_instruction,debug_imm,debug_funct7, debug_opcode,debug_rs1, debug_rs2, debug_rd,debug_funct3);
    
endmodule
