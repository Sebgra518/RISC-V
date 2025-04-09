module ALUControl (funct7,funct3,opcode,alu_ctrl);

    input  wire [6:0] funct7;
    input  wire [2:0] funct3;
    input  wire [6:0] opcode;
    output reg  [3:0] alu_ctrl;

    initial begin
        alu_ctrl = 0;
    end


    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type instructions
                case ({funct7, funct3})
                    10'b0000000000: alu_ctrl = 4'b0000; // ADD
                    10'b0100000000: alu_ctrl = 4'b0001; // SUB
                    10'b0000000111: alu_ctrl = 4'b0010; // AND
                    10'b0000000110: alu_ctrl = 4'b0011; // OR
                    10'b0000000100: alu_ctrl = 4'b0100; // XOR
                    10'b0000000001: alu_ctrl = 4'b0101; // SLL (Shift Left Logical)
                    10'b0000000101: alu_ctrl = 4'b0110; // SRL (Shift Right Logical)
                    10'b0100000101: alu_ctrl = 4'b0111; // SRA (Shift Right Arithmetic)
                    10'b0000000010: alu_ctrl = 4'b1000; // SLT (Set Less Than)
                    10'b0000000011: alu_ctrl = 4'b1001; // SLTU (Set Less Than Unsigned)
                    default: alu_ctrl = 4'b0000; // Default to ADD
                endcase
            end
            7'b0010011: begin // I-type ALU instructions
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b001: alu_ctrl = 4'b0101; // SLLI
                    3'b101: alu_ctrl = (funct7 == 7'b0000000) ? 4'b0110 : 4'b0111; // SRLI/SRAI
                    3'b010: alu_ctrl = 4'b1000; // SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTIU
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            default: alu_ctrl = 4'b0000; // Default case
        endcase
    end

endmodule
