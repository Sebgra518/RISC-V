`timescale 1ns / 1ps

module ReCirculatingCalculator(val1,op,enter,out);
    input wire [31:0] val1;
    input wire [1:0] op;
    output reg [31:0] out = 0;
    input wire enter;
    
    initial out = 0;
    
    always @ (posedge enter) begin
        case (op)
            2'b00 : out <= out + val1;
            2'b01 : out <= out - val1;
            2'b10 : out <= out * val1;
            2'b11 : out <= out / val1;
        endcase
        
    end
endmodule
