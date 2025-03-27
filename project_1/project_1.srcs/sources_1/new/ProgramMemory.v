`timescale 1ns / 1ps

module ProgramMemory(address, programOut);
    input wire [31:0] address;
    output reg [31:0] programOut;
    
    always @(*) begin
        case (address)
           32'd0:  programOut = 32'h00000001;
           32'd1:  programOut = 32'h00000002;
           32'd2:  programOut = 32'h00000003;
           32'd3:  programOut = 32'h00000004;
           32'd4:  programOut = 32'h00000005;
           32'd5:  programOut = 32'h00000006;
           32'd6:  programOut = 32'h00000007;
           32'd7:  programOut = 32'h00000008;
           32'd8:  programOut = 32'h00000009;
           32'd9:  programOut = 32'h0000000A;
           32'd10:  programOut = 32'h0000000B;
           
           
        endcase
    end
endmodule
