#!/usr/bin/env python3
"""
rv32i_assembler.py
Simple two-pass assembler for RV32I (base integer ISA).
Produces hex, binary, or .mem files for FPGA ROM/BRAM initialization.

Usage:
    python rv32i_assembler.py input.s -o output.mem --format mem
    python rv32i_assembler.py input.s          # prints hex words to stdout
    Example Usage: python rv32i_assembler.py ExampleProgram.s -o out.mem --format mem
"""

import sys
import re
import argparse

# -------------------------
# Register name mapping
# -------------------------
ABI_REGS = {
    "zero": 0, "ra": 1,  "sp": 2,  "gp": 3,  "tp": 4,
    "t0": 5,   "t1": 6,  "t2": 7,
    "s0": 8,   "fp": 8,  "s1": 9,
    "a0": 10,  "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18,  "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28,  "t4": 29, "t5": 30, "t6": 31
}
def reg_num(tok):
    tok = tok.strip()
    if tok.startswith('x'):
        return int(tok[1:])
    if tok in ABI_REGS:
        return ABI_REGS[tok]
    raise ValueError(f"Invalid register '{tok}'")

# -------------------------
# Helpers for immediates
# -------------------------
def parse_imm(tok, labels=None, cur_addr=0):
    """
    Parse immediate token. Accepts decimal, -decimal, 0xhex, 0bbin, or label names.
    labels: dict mapping label->address (in bytes) for branch/jump resolution.
    cur_addr: current instruction address (in bytes) for relative offsets.
    """
    tok = tok.strip()
    # label (only if exact token and in labels)
    if labels and tok in labels:
        return labels[tok] - cur_addr
    # decimal / signed decimal
    if re.match(r'^-?\d+$', tok):
        return int(tok, 10)
    # hex
    if tok.startswith(('0x','-0x')):
        return int(tok, 16)
    # binary
    if tok.startswith(('0b','-0b')):
        return int(tok, 2)
    raise ValueError(f"Cannot parse immediate or label '{tok}'")

def mask_bits(value, bits):
    """Return unsigned lower 'bits' bits of value."""
    return value & ((1 << bits) - 1)

def signed_range_check(value, bits, name="imm"):
    lo = -(1 << (bits-1))
    hi = (1 << (bits-1)) - 1
    if not (lo <= value <= hi):
        raise ValueError(f"{name} {value} out of signed {bits}-bit range [{lo}..{hi}]")

# -------------------------
# Instruction encoding helpers
# -------------------------
def encode_R(funct7, rs2, rs1, funct3, rd, opcode):
    return ((funct7 & 0x7f) << 25) | ((rs2 & 0x1f) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1f) << 7) | (opcode & 0x7f)

def encode_I(imm12, rs1, funct3, rd, opcode):
    return ((imm12 & 0xfff) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 0x7) << 12) | ((rd & 0x1f) << 7) | (opcode & 0x7f)

def encode_S(imm12, rs2, rs1, funct3, opcode):
    imm11_5 = (imm12 >> 5) & 0x7f
    imm4_0  = imm12 & 0x1f
    return (imm11_5 << 25) | ((rs2 & 0x1f) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 0x7) << 12) | (imm4_0 << 7) | (opcode & 0x7f)

def encode_B(imm13, rs2, rs1, funct3, opcode):
    # imm13 is signed 13-bit (bits [12:1], LSB is zero)
    # encoding: imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
    imm = imm13
    imm12 = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3f
    imm4_1 = (imm >> 1) & 0xf
    imm11 = (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | ((rs2 & 0x1f) << 20) | ((rs1 & 0x1f) << 15) | ((funct3 & 0x7) << 12) | (imm4_1 << 8) | (imm11 << 7) | (opcode & 0x7f)

def encode_U(imm20, rd, opcode):
    return ((imm20 & 0xfffff) << 12) | ((rd & 0x1f) << 7) | (opcode & 0x7f)

def encode_J(imm21, rd, opcode):
    # imm21 signed: bits [20|10:1|11|19:12]
    imm = imm21
    imm20 = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3ff
    imm11 = (imm >> 11) & 0x1
    imm19_12 = (imm >> 12) & 0xff
    return (imm20 << 31) | (imm19_12 << 12) | (imm11 << 20) | (imm10_1 << 21) | ((rd & 0x1f) << 7) | (opcode & 0x7f)

# -------------------------
# Instruction definitions (opcode/funct3/funct7 as integers)
# -------------------------
# Reference: RISC-V spec (RV32I)
# opcodes are 7-bit values, funct3 3-bit, funct7 7-bit where applicable.

# Opcodes:
OP_R      = 0b0110011
OP_I_ALU  = 0b0010011
OP_LOAD   = 0b0000011
OP_STORE  = 0b0100011
OP_BRANCH = 0b1100011
OP_JAL    = 0b1101111
OP_JALR   = 0b1100111
OP_LUI    = 0b0110111
OP_AUIPC  = 0b0010111
OP_MISC_MEM = 0b0001111
OP_SYSTEM = 0b1110011

# Map mnemonic -> (type, opcode, funct3, funct7 if R or shift/I-shift where needed)
# type is one of 'R','I','S','B','U','J','I-shift' (I-type but shift uses shamt and funct7)
INSTR = {
    # R-type
    "add": ("R", OP_R, 0b000, 0b0000000),
    "sub": ("R", OP_R, 0b000, 0b0100000),
    "sll": ("R", OP_R, 0b001, 0b0000000),
    "slt": ("R", OP_R, 0b010, 0b0000000),
    "sltu":("R", OP_R, 0b011, 0b0000000),
    "xor": ("R", OP_R, 0b100, 0b0000000),
    "srl": ("R", OP_R, 0b101, 0b0000000),
    "sra": ("R", OP_R, 0b101, 0b0100000),
    "or":  ("R", OP_R, 0b110, 0b0000000),
    "and": ("R", OP_R, 0b111, 0b0000000),

    # I-type ALU immediates
    "addi":("I", OP_I_ALU, 0b000),
    "slti":("I", OP_I_ALU, 0b010),
    "sltiu":("I", OP_I_ALU, 0b011),
    "xori":("I", OP_I_ALU, 0b100),
    "ori": ("I", OP_I_ALU, 0b110),
    "andi":("I", OP_I_ALU, 0b111),

    # I-type shifts (use funct7)
    "slli":("I-shift", OP_I_ALU, 0b001, 0b0000000),
    "srli":("I-shift", OP_I_ALU, 0b101, 0b0000000),
    "srai":("I-shift", OP_I_ALU, 0b101, 0b0100000),

    # Loads (I-type)
    "lb": ("I", OP_LOAD, 0b000),
    "lh": ("I", OP_LOAD, 0b001),
    "lw": ("I", OP_LOAD, 0b010),
    "lbu":("I", OP_LOAD, 0b100),
    "lhu":("I", OP_LOAD, 0b101),

    # Stores (S-type)
    "sb": ("S", OP_STORE, 0b000),
    "sh": ("S", OP_STORE, 0b001),
    "sw": ("S", OP_STORE, 0b010),

    # Branches (B-type)
    "beq": ("B", OP_BRANCH, 0b000),
    "bne": ("B", OP_BRANCH, 0b001),
    "blt": ("B", OP_BRANCH, 0b100),
    "bge": ("B", OP_BRANCH, 0b101),
    "bltu":("B", OP_BRANCH, 0b110),
    "bgeu":("B", OP_BRANCH, 0b111),

    # Jumps
    "jal": ("J", OP_JAL, None),
    "jalr":("I", OP_JALR, 0b000),

    # U-type
    "lui": ("U", OP_LUI, None),
    "auipc":("U", OP_AUIPC, None),
}

# -------------------------
# Assembly parsing utilities
# -------------------------
token_re = re.compile(r"[(),\s]+")  # split on commas/parens/whitespace

def tokenize_operands(operand_str):
    # split by commas/parens while preserving tokens like '0(x1)' -> ['0','x1']
    # Replace '(' and ')' with commas to split more easily
    s = operand_str.replace('(', ' ').replace(')', ' ')
    toks = [t for t in re.split(r'[\s,]+', s) if t != '']
    return toks

# -------------------------
# Two-pass assembly
# -------------------------
def first_pass(lines):
    labels = {}
    pc = 0
    for lineno, raw in enumerate(lines, start=1):
        line = raw.split('#',1)[0].strip()
        if not line:
            continue
        # label?
        while True:
            m = re.match(r'^([A-Za-z_]\w*):', line)
            if m:
                lbl = m.group(1)
                if lbl in labels:
                    raise ValueError(f"Duplicate label '{lbl}' at line {lineno}")
                labels[lbl] = pc
                line = line[m.end():].strip()
            else:
                break
        if not line:
            continue
        # assume one instruction per line; increment PC by 4
        pc += 4
    return labels

def assemble_instruction(line, labels, cur_pc):
    """
    line: instruction text with no comments and no leading labels
    labels: mapping label->address
    cur_pc: address in bytes (int)
    returns: 32-bit word (int)
    """
    if not line:
        return None
    parts = line.strip().split(None, 1)
    if not parts:
        return None
    mn = parts[0].lower()
    ops_str = parts[1] if len(parts) > 1 else ""
    if mn not in INSTR:
        raise ValueError(f"Unknown opcode '{mn}' in '{line}'")
    info = INSTR[mn]
    typ = info[0]

    # parse operands into tokens
    ops = tokenize_operands(ops_str) if ops_str else []

    if typ == "R":
        if len(ops) != 3:
            raise ValueError(f"R-type {mn} requires rd, rs1, rs2")
        rd = reg_num(ops[0]); rs1 = reg_num(ops[1]); rs2 = reg_num(ops[2])
        opcode = info[1]; funct3 = info[2]; funct7 = info[3]
        return encode_R(funct7, rs2, rs1, funct3, rd, opcode)

    if typ == "I":
        if mn == "jalr":
            # jalr rd, imm(rs1)  or jalr rd, rs1, imm? Standard: jalr rd, offset(rs1)
            # Accept both: jalr rd, rs1, imm OR jalr rd, imm(rs1)
            if len(ops) == 2:
                rd = reg_num(ops[0])
                # ops[1] could be "imm rs1" if original had parentheses; tokenization does that; but usually it's imm then rs1
                # we will try two forms: imm, rs1  OR imm(rs1) parsed as [imm, rs1]
                try:
                    imm = parse_imm(ops[1], labels, cur_pc)
                    rs1 = 0
                    raise ValueError()  # force treat as imm(rs1) attempt below
                except Exception:
                    pass
            # fallback: expect "rd, rs1, imm" OR "rd, imm, rs1" OR "rd, imm(rs1)"
            if len(ops) == 3:
                rd = reg_num(ops[0]); rs1 = reg_num(ops[1]); imm = parse_imm(ops[2], labels, cur_pc)
            elif len(ops) == 2:
                # treat as rd, imm(rs1) -> ops = [rd, imm, rs1] after tokenization earlier
                rd = reg_num(ops[0]); imm = parse_imm(ops[1], labels, cur_pc); rs1 = 0
                raise ValueError("Unsupported jalr operand format. Use: jalr rd, imm(rs1) or jalr rd, rs1, imm")
            else:
                raise ValueError("jalr requires rd, rs1, imm or rd, imm(rs1)")
            signed_range_check(imm, 12, "jalr imm")
            return encode_I(mask_bits(imm,12), rs1, info[2], rd, info[1])

        if len(ops) != 3 and not (len(ops)==2 and mn.startswith('l')):  # loads often are rd, imm(rs1) => tokenized as [rd, imm, rs1]
            # allow rd, imm(rs1) tokenization (3 tokens) or rd, rs1, imm (3)
            # for loads, tokenization yields [rd, imm, rs1] which we'll handle below
            pass

        if mn in ("lb","lh","lw","lbu","lhu"):
            # expect rd, imm(rs1) -> tokens [rd, imm, rs1]
            if len(ops) != 3:
                raise ValueError(f"{mn} requires rd, imm(rs1)")
            rd = reg_num(ops[0]); imm = parse_imm(ops[1], labels, cur_pc); rs1 = reg_num(ops[2])
            signed_range_check(imm, 12, f"{mn} imm")
            return encode_I(mask_bits(imm,12), rs1, info[2], rd, info[1])

        # general immediate ALU
        if typ == "I":
            if len(ops) != 3:
                raise ValueError(f"I-type {mn} requires rd, rs1, imm")
            rd = reg_num(ops[0]); rs1 = reg_num(ops[1]); imm = parse_imm(ops[2], labels, cur_pc)
            signed_range_check(imm, 12, f"{mn} imm")
            return encode_I(mask_bits(imm,12), rs1, info[2], rd, info[1])

    if typ == "I-shift":
        # slli rd, rs1, shamt  OR slli rd, shamt(rs1) is not used - usual is rd, rs1, shamt
        if len(ops) != 3:
            raise ValueError(f"{mn} requires rd, rs1, shamt")
        rd = reg_num(ops[0]); rs1 = reg_num(ops[1]); shamt = parse_imm(ops[2], labels, cur_pc)
        # shamt is 5-bit unsigned for RV32I
        if not (0 <= shamt <= 31):
            raise ValueError(f"Shift amount {shamt} out of range 0-31")
        # Make imm12 where funct7 goes in upper bits for shift immediate encoding
        funct7 = info[3]; funct3 = info[2]; opcode = info[1]
        imm12 = (funct7 << 5) | (shamt & 0x1f)
        return encode_I(imm12, rs1, funct3, rd, opcode)

    if typ == "S":
        if len(ops) != 3:
            raise ValueError(f"S-type {mn} requires rs2, imm(rs1) or rs2, rs1, imm")
        # Accept rs2, imm(rs1) -> tokenized [rs2, imm, rs1]
        rs2 = reg_num(ops[0]); imm = parse_imm(ops[1], labels, cur_pc); rs1 = reg_num(ops[2])
        signed_range_check(imm, 12, f"{mn} imm")
        return encode_S(mask_bits(imm,12), rs2, rs1, info[2], info[1])

    if typ == "B":
        if len(ops) != 3:
            raise ValueError(f"B-type {mn} requires rs1, rs2, label/imm")
        rs1 = reg_num(ops[0]); rs2 = reg_num(ops[1])
        target = ops[2]
        imm = parse_imm(target, labels, cur_pc)
        # Branch immediate is relative to PC (current instruction address)
        # In RISC-V, branch immediate is offset from PC (in bytes). The spec encodes imm in multiples of 2 (LSB zero).
        # We must check alignment.
        if imm % 2 != 0:
            raise ValueError(f"Branch target offset {imm} not aligned by 2 (must be even).")
        # imm field for B is 13 bits signed (imm[12:1] << 1)
        signed_range_check(imm, 13, f"{mn} imm")
        return encode_B(mask_bits(imm,13), rs2, rs1, info[2], info[1])

    if typ == "U":
        if len(ops) != 2:
            raise ValueError(f"U-type {mn} requires rd, imm20")
        rd = reg_num(ops[0]); imm = parse_imm(ops[1], labels, cur_pc)
        # U-type uses upper 20 bits (imm[31:12]), the lower 12 bits are zeroed by hardware when used
        # Ensure imm fits in 32-bit when shifted; check that lower 12 bits are zero if user provided full immediate
        # We'll accept imm that fits in signed 32-bit and will place top 20 bits.
        # Convert imm into top 20 representing imm >> 12
        imm20 = (imm >> 12)
        # For safer error checking, ensure imm fits into 32 bits
        if not (- (1<<31) <= imm <= (1<<31)-1):
            raise ValueError(f"{mn} immediate {imm} out of 32-bit range")
        return encode_U(mask_bits(imm20,20), rd, info[1])

    if typ == "J":
        # jal rd, label/imm
        if len(ops) != 2:
            raise ValueError("jal requires rd, label/imm")
        rd = reg_num(ops[0]); target = ops[1]
        imm = parse_imm(target, labels, cur_pc)
        # jal immediate is relative to PC (signed), must be multiple of 1 (LSB ignored?), but spec requires alignment by 1? The LSB is zero in encoding (immediate is multiple of 1 but bit0 is always zero for aligned addresses since instructions are 4 bytes). For J-type, imm is multiple of 1 (lowest bit is ignored in encoding), but actual address alignment is 4 bytes so imm%1==0 always true. We'll check 4-byte alignment for jump to instruction boundary.
        if imm % 1 != 0:
            raise ValueError("Invalid jal immediate alignment")
        signed_range_check(imm, 21, "jal imm")
        return encode_J(mask_bits(imm,21), rd, info[1])

    raise ValueError(f"Unhandled instruction type '{typ}' for {mn}")


def assemble(lines):
    labels = first_pass(lines)
    pc = 0
    words = []
    for raw in lines:
        line = raw.split('#',1)[0].strip()
        if not line:
            continue
        # strip labels at start
        while True:
            m = re.match(r'^([A-Za-z_]\w*):', line)
            if m:
                line = line[m.end():].strip()
            else:
                break
        if not line:
            continue
        word = assemble_instruction(line, labels, pc)
        if word is not None:
            words.append((pc, word, line))
            pc += 4
    return words

# -------------------------
# CLI & IO
# -------------------------
def format_word(word, fmt):
    if fmt == "hex":
        return f"0x{word:08x}"
    if fmt == "bin":
        return f"{word:032b}"
    if fmt == "mem":
        # simple .mem: one hex word per line without 0x
        return f"{word:08x}"
    return f"{word:08x}"

def main():
    parser = argparse.ArgumentParser(description="RV32I assembler (simple)")
    parser.add_argument("input", nargs='?', help="Input assembly file (.s). If omitted, reads stdin.")
    parser.add_argument("-o","--output", help="Output file (default stdout)")
    parser.add_argument("--format", choices=["hex","bin","mem"], default="hex", help="Output format (hex/bin/mem). mem = plain hex words (no 0x).")
    args = parser.parse_args()

    if args.input:
        with open(args.input, 'r') as f:
            lines = f.readlines()
    else:
        lines = sys.stdin.read().splitlines()

    try:
        words = assemble(lines)
    except Exception as e:
        print(f"Assembly error: {e}", file=sys.stderr)
        sys.exit(2)

    out_lines = []
    for addr, w, inst_text in words:
        out_lines.append(format_word(w, args.format))

    if args.output:
        with open(args.output, 'w') as f:
            if args.format == "mem":
                # For .mem used in many flows a header isn't necessary; just write words from address 0..N-1
                f.write("\n".join(out_lines))
            else:
                f.write("\n".join(out_lines) + "\n")
        print(f"Wrote {len(out_lines)} words to {args.output}")
    else:
        print("\n".join(out_lines))

if __name__ == "__main__":
    main()