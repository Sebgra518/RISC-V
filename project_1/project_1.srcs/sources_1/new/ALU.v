module ALU (a,b,alu_ctrl,result);

    input  wire [31:0] a;
    input  wire [31:0] b;
    input  wire [3:0]  alu_ctrl;
    output reg [31:0] result;
    
    
    initial result = 0;
    
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;        // ADD
            4'b0001: result = a - b;        // SUB
            4'b0010: result = a & b;        // AND
            4'b0011: result = a | b;        // OR
            4'b0100: result = a ^ b;        // XOR
            4'b0101: result = a << b[4:0];  // SLL (Shift Left Logical)
            4'b0110: result = a >> b[4:0];  // SRL (Shift Right Logical)
            4'b0111: result = $signed(a) >>> b[4:0]; // SRA (Shift Right Arithmetic)
            4'b1000: result = (a < b) ? 32'b1 : 32'b0; // SLT (Set Less Than)
            4'b1001: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0; // SLTU (Set Less Than Unsigned)
            default: result = 32'b0; // Default case
        endcase
    end

endmodule
