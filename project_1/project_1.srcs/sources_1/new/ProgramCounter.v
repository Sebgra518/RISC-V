`timescale 1ns / 1ps

module ProgramCounter(clk, reset, count_out);

    input wire  clk;
    input wire reset;
    output reg [31:0] count_out;
    
    always @ (posedge clk, reset) begin
        if(reset)
            count_out = 0;
        else
            count_out = count_out + 1;
    end
    
    

endmodule
