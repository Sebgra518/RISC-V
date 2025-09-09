module BranchCompare(is_b,rs1,rs2,imm,taken_br);

    input wire [2:0] is_b;
    input wire [31:0] rs1, rs2;
    input wire [31:0] imm;
    output reg taken_br;

    wire signed [31:0] a_signed = rs1;
    wire signed [31:0] b_signed = rs2;

    initial begin
        taken_br = 0;
    end

    always @(*) begin
        // Default values
        taken_br = 1'b0;

        case (is_b)
            3'b000: taken_br = (rs1 == rs2);                  // BEQ
            3'b001: taken_br = (rs1 != rs2);                  // BNE
            3'b010: taken_br = (a_signed < b_signed);     // BLT
            3'b011: taken_br = (a_signed >= b_signed);    // BGE
            3'b100: taken_br = (rs1 < rs2);                   // BLTU
            3'b101: taken_br = (rs1 >= rs2);                  // BGEU
            default: taken_br = 1'b0;
        endcase
    end
endmodule