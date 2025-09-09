module ProgramCounter(input clk, input reset, input [31:0] next_pc, output reg [31:0] count_out);

    initial count_out = 0;

    always @(posedge clk or posedge reset) begin
        if (reset)
            count_out <= 0;
        else
            count_out <= next_pc;
    end
endmodule
