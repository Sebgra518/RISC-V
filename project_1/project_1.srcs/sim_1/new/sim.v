`timescale 1ns / 1ps

module sim();
    reg clk;

    wire [31:0] debug_imm;
    wire [6:0] debug_funct7, debug_opcode;
    wire [4:0]  debug_rs1, debug_rs2, debug_rd;
    wire [2:0] debug_funct3;
    wire [31:0] debug_ALU;
    wire [3:0]  debug_alu_ctrl;
    wire debug_IType;
    wire [31:0] debug_read_data_1, debug_read_data_2;
    
    initial begin
        clk = 0;
    end
    


    always #1 clk = ~clk;  // Toggle clock every 10 time units (50 MHz)
    
    RISCV RISCV(clk,debug_imm,debug_funct7, debug_opcode,debug_rs1, debug_rs2, debug_rd,debug_funct3,debug_alu_ctrl,debug_ALU, debug_IType,debug_read_data_1, debug_read_data_2);
endmodule