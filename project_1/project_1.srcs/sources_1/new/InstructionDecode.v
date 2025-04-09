`timescale 1ns / 1ps

module InstructionDecode(instruction,funct7,rs2,rs1,funct3,rd,opcode,imm);
    input wire [31:0] instruction;
    
    output reg [7:0] funct7;
    output reg [4:0] rs2;
    output reg [4:0] rs1;
    output reg [2:0] funct3;
    output reg [4:0] rd;
    output reg [6:0] opcode;
    output reg [31:0] imm;
    

    always @ * begin
        
        opcode  = instruction[6:0];
       
       
       //R Type
       if((instruction[6:2] == 5'b01_011) || (instruction[6:2] == 5'b01_100) || (instruction[6:2] == 5'b01_110) || (instruction[6:2] == 5'b10_100)) begin
            rd = instruction[11:7];
            funct3 = instruction[14:12];
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            funct7 = instruction[31:25];
       end
       
       //I Type
       if((instruction[6:2] == 5'b00_000) || (instruction[6:2] == 5'b00_001) || (instruction[6:2] == 5'b00_100) || (instruction[6:2] == 5'b00_110) || (instruction[6:2] == 5'b11_001))begin
            rd = instruction[11:7];
            funct3 = instruction[14:12];
            rs1 = instruction[19:15];
            
            imm = {{20{instruction[31]}}, instruction[31:20]};//"{20{instruction[31]" is used for sign extention. The "20" represents the amount of bits to add to the end based on if instruction[31] is 0 or 1

       end
       
       //S Type
       if((instruction[6:2] == 5'b01_000) || (instruction[6:2] == 5'b01_001)) begin
            funct3 = instruction[14:12];
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            
            imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
       end
       
       //U Type
       if((instruction[6:2] == 5'b00_101) || (instruction[6:2] == 5'b01_101)) begin
            rd = instruction[11:7];

            imm = {instruction[31:12], 12'b0};
       end
       
       //J Type
       if(instruction[6:2] == 5'b11_011) begin 
            rd = instruction[11:7];
            
            imm = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

       end
       
       //B Type
       if(instruction[6:2] == 5'b11_000) begin
            funct3 = instruction[14:12];
            rs1 = instruction[19:15];
            rs2 = instruction[24:20];
            funct7 = instruction[31:25];
            
            imm = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
       end
      
    end
    
endmodule
