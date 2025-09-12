`timescale 1ns / 1ps

module ProgramMemory(address, programOut);

    initial programOut = 0;

    input wire [31:0] address;
    output reg [31:0] programOut;
    
    always @(*) begin
        case (address)
           32'd0:  programOut = 32'h00000000;
           32'd1:  programOut = 32'b00000000001100000000001010010011;//li x5, 3
           32'd2:  programOut = 32'b00000000010100000000001100010011;//li x6, 5
           32'd3:  programOut = 32'b00000000011000101000001110110011;//add x7, x5, x6
           32'd4:  programOut = 32'b00000000001000000000010000010011;//li x8, 2
           32'd5:  programOut = 32'b00000000100000111000010010110011;//add x9, x7, x8
           32'd6:  programOut = 32'h00000000;
           32'd7:  programOut = 32'h00000000;
           32'd8:  programOut = 32'h00000000;
           32'd9:  programOut = 32'h00000000;
           32'd10:  programOut = 32'h00000000;
          default: programOut = 0;
        endcase
    end
endmodule
