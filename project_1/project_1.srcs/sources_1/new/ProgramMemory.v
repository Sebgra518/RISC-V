`timescale 1ns / 1ps

module ProgramMemory(address, programOut);

    initial programOut = 0;

    input wire [31:0] address;
    output reg [31:0] programOut;
    
    always @(*) begin
        case (address)
           32'd0:  programOut = 32'h00000000;
           32'd1:  programOut = 32'b00000000001100000000001010010011; //li x5, 3
           32'd2:  programOut = 32'b00000000101000110000001010010011; //addi x6, x5, 5
           32'd3:  programOut = 32'b00000000010100101010010000010011; //slti x8, x5, 5
           32'd4:  programOut = 32'b00000110010000101011010010010011; //sltiu x9, x5, 100
           32'd5:  programOut = 32'b00000001010000101100010100010011; //xori x10, x5, 20
           32'd6:  programOut = 32'b00000000111100101110010110010011; //ori x11, x5, 15
           32'd7:  programOut = 32'b00000000110000101111011000010011; //andi x12, x5, 12
           32'd8:  programOut = 32'b00000000001100101001011010010011;//SLLI x13, x5, 3
           32'd9:  programOut = 32'b01000000000100101101011100010011;//SRAI x14, x5, 1
           
           32'd10: programOut = 32'b00000000000001010000011110000011;//lb x15, 0(x10)
           32'd11: programOut = 32'b00000000001001010001100000000011;// lh x16, 0(x10)
           32'd12: programOut = 32'//LW x16, 0(x10)
           32'd13: programOut = 32'//LBU x5, 0(x10)
           32'd14: programOut = 32'
          default: programOut = 0;
        endcase
    end
endmodule
