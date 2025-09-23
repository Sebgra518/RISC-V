`timescale 1ns/1ps
`default_nettype none

module RISCV(
    input  wire clk
    , output wire [31:0] debug_imm
    , output wire [6:0] debug_funct7, debug_opcode
    , output wire [4:0]  debug_rs1, debug_rs2, debug_rd
    , output wire [2:0] debug_funct3
    , output wire [3:0] debug_alu_ctrl
    , output wire [31:0] debug_ALU
    , output wire debug_IType
    , output wire [31:0] debug_read_data_1, debug_read_data_2
);

    // Reset: keep a single declaration; drive it somehow in real HW (input or POR)
    reg reset = 1'b0;

    // Program Counter wires
    (* mark_debug = "true" *) wire [31:0] pc;
    wire [31:0] pc_next;
    wire        taken_br;

    // Instruction Decode Outputs
    wire [6:0]  funct7, opcode;
    wire [4:0]  rs1, rs2, rd;
    wire [2:0]  funct3;
    (* mark_debug = "true" *) wire [31:0] instruction, imm;
    wire [31:0] read_data_1, read_data_2;

    // ALU
    wire [3:0]  alu_ctrl;
    (* mark_debug = "true" *) wire [31:0] alu_out;

    wire IType;
    wire RType;
    wire JType;

    // =========================================================================
    // Minimal next-PC so PC advances (prevents X/pruning). Replace with your
    // branch/jump sequencing when ready.
    // If imm is PC-relative and word-aligned in your design, you can do:
    // wire [31:0] pc_plus4 = pc + 32'd4;
    // wire [31:0] br_tgt   = pc + imm;
    // assign pc_next = taken_br ? br_tgt : pc_plus4;
    // For now, keep it simple:
    assign pc_next = (opcode == 7'b1100111) ? (rs1 + imm) : (pc + 1'b1);

    // =========================================================================

    // Program Counter
    // DONT_TOUCH keeps it from being removed during opt_design
    (* DONT_TOUCH = "TRUE" *)
    ProgramCounter u_pc (
        .clk     (clk),
        .reset   (reset),
        .next_pc (pc_next),
        .count_out(pc)
    );

    // Program Memory (assumed combinational read)
    ProgramMemory u_pm (
        .address    (pc),
        .programOut (instruction)
    );

    // Decode instruction
    InstructionDecode u_id (
        .instruction (instruction),
        .funct7      (funct7),
        .rs2         (rs2),
        .rs1         (rs1),
        .funct3      (funct3),
        .rd          (rd),
        .opcode      (opcode),
        .imm         (imm),
        .RType       (RType),
        .JType       (JType)
    );

    // Register File
    // NOTE: write_enable=0 disables writes; consider driving it from control.
    RegisterFileRead u_rfr (
        .clk            (clk),
        .write_enable   ((IType || RType) ? 1'b1 : 1'b0),
        .write_address  (rd),
        .write_data     (alu_out),
        .read_enable_1 ((IType) ? 1'b0 : 1'b1),
        .read_address_1 (rs1),
        .read_data_1    (read_data_1),
        .read_enable_2 ((IType) ? 1'b0 : 1'b1),
        .read_address_2 (rs2),
        .read_data_2    (read_data_2)
    );

    // ALU Control
    ALUControl u_aluctrl (
        .funct7   (funct7),
        .funct3   (funct3),
        .opcode   (opcode),
        .alu_ctrl (alu_ctrl),
        .IType (IType)
    );

    // ALU
    ALU u_alu (
        .a        (read_data_1),
        .b        ((IType) ? imm : read_data_2),   // consider muxing in IMM when needed
        .alu_ctrl (alu_ctrl),
        .result   (alu_out)
    );

    // BranchCompare for branch instructions
    // TODO: Verify port types. If .is_b is a 1-bit “is branch”, drive from opcode:
    // wire is_branch = (opcode == 7'b1100011);
    // BranchCompare u_bc(.is_b(is_branch), .funct3(funct3), ...)
    BranchCompare u_bc (
        .is_b   (funct3),   // <-- likely width/semantic mismatch; check module
        .rs1    (read_data_1),
        .rs2    (read_data_2),
        .imm    (imm),
        .taken_br(taken_br)
    );

    // Optional: tie out debug ports if you add them to the top
    assign debug_funct7      = funct7;
    assign debug_opcode = opcode;
    assign debug_rd = rd;
    assign debug_rs1 = rs1;
    assign debug_rs2 = rs2;
    assign debug_funct3 = funct3;
    assign debug_imm = imm;
    assign debug_ALU = alu_out;
    assign debug_alu_ctrl = alu_ctrl;
    assign debug_IType = IType;
    assign debug_read_data_1 = read_data_1;
    assign debug_read_data_2 = read_data_2;

endmodule

`default_nettype wire
