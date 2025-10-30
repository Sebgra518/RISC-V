addi x5, x0, 27          # t0 = 27
addi x6, x0, 15          # t1 = 15
add  x7, x5, x6          # t2 = t0 + t1 = 42
lui  x28, 0x10010        # load upper 20 bits of address (example)
addi x28, x28, 0         # load lower 12 bits of address (example)
sw   x7, 0(x28)          # store result into memory