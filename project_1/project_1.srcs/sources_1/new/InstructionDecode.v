`timescale 1ns / 1ps

module InstructionDecode(instruction,funct7,rs2,rs1,funct3,rd,opcode);
    input wire [31:0] instruction;
    
    output reg [7:0] funct7;
    output reg [4:0] rs2;
    output reg [4:0] rs1;
    output reg [2:0] funct3;
    output reg [4:0] rd;
    output reg [6:0] opcode;
    
    
    reg is_u_instruction;
    reg is_r_instruction;
    reg is_s_instruction;
    reg is_j_instruction;
    reg is_i_instruction;
    reg is_b_instruction;

    always @ * begin
        is_u_instruction = ((instruction[6:2] == 5'b00_101) || (instruction[6:2] == 5'b01_101));
        is_r_instruction = ((instruction[6:2] == 5'b01_011) || (instruction[6:2] == 5'b01_100) || (instruction[6:2] == 5'b01_110) || (instruction[6:2] == 5'b10_100));
        is_s_instruction = ((instruction[6:2] == 5'b01_000) || (instruction[6:2] == 5'b01_001));
        is_j_instruction = (instruction[6:2] == 5'b11_011);
        is_i_instruction = ((instruction[6:2] == 5'b00_000) || (instruction[6:2] == 5'b00_001) || (instruction[6:2] == 5'b00_100) || (instruction[6:2] == 5'b00_110) || (instruction[6:2] == 5'b11_001));
        is_b_instruction = (instruction[6:2] == 5'b11_000);
        
        opcode  = instruction[6:0];
       
       
       if(!is_u_instruction || !is_j_instruction) begin
            funct3 = instruction[14:12];
            rs1 = instruction[19:15];
            
            if(is_i_instruction)begin
                rd = instruction[11:7];
            end else begin
                rs2 = instruction[24:20]; 
                
                if(is_r_instruction)begin
                    funct7 = instruction[31:25];
                    rd = instruction[11:7];
                end
                
            end
            
       end else begin
            rd = instruction[11:7];
       end
       
       
            
            
            
            
            
            
    end
    
    
    
endmodule
