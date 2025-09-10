`timescale 1ns / 1ps

module ProgramMemory(address, programOut);

    initial programOut = 0;

    input wire [31:0] address;
    output reg [31:0] programOut;
    
    always @(*) begin
        case (address)
           32'd0:  programOut = 32'h00000000;
           32'd1:  programOut = 32'b00000000001100000000010100010011; //li a0, 3
           32'd2:  programOut = 32'b00000000010100000000010110010011; //li a1, 5
           32'd3:  programOut = 32'b00000000101101010000010100110011; //add a0, a0, a1
           32'd4:  programOut = 32'h00000004;
           32'd5:  programOut = 32'h00000005;
           32'd6:  programOut = 32'h00000006;
           32'd7:  programOut = 32'h00000007;
           32'd8:  programOut = 32'h00000008;
           32'd9:  programOut = 32'h00000009;
           32'd10:  programOut = 32'h0000000A;
          default: programOut = 0;
        endcase
    end
endmodule
