`timescale 1ns / 1ps

module sim();
    reg [31:0] val1;
    wire [31:0] out;
    reg enter;
    reg [1:0] op;
    
    initial enter = 0;  // Initialize clock to 0
    always #1 enter = ~enter;  // Toggle clock every 10 time units (50 MHz)
    
    ReCirculatingCalculator c(val1,op,enter,out);
    
    initial begin 
        val1 = 25;
        op = 0;
        #4
        op = 1;
        
    
    end
    
endmodule
