`timescale 1ns / 1ps

module sim();
    reg [31:0] instruction;
    wire [7:0] funct7;
    wire[4:0] rs2;
    wire [4:0] rs1;
    wire [2:0] funct3;
    wire [4:0] rd;
    wire [6:0] opcode;
    wire [31:0] imm;
    
    initial begin
        instruction = 32'b00000000011100110000001010110011;
    end
    
    
    //always #1 count_out = ~count_out;  // Toggle clock every 10 time units (50 MHz)
    
    InstructionDecode ID(instruction,funct7,rs2,rs1,funct3,rd,opcode,imm);
    
endmodule
