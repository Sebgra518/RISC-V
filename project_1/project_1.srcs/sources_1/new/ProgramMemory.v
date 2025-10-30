`timescale 1ns / 1ps

module ProgramMemory(address, programOut);

    initial programOut = 0;

    input wire [31:0] address;
    output reg [31:0] programOut;
    
    always @(*) begin
        case (address)
           32'd0:  programOut = 32'h00000000;
           32'd1:  programOut = 32'h01b00293;
           32'd2:  programOut = 32'h00f00313;
           32'd3:  programOut = 32'h006283b3;
           32'd4:  programOut = 32'h00010e37;
           32'd5:  programOut = 32'h000e0e13;
           32'd6:  programOut = 32'h007e2023;
          default: programOut = 0;
        endcase
    end
endmodule
