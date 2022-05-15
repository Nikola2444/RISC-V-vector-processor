.text                     # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes
    	
    vand.vv  v1, v2, v3                                  # Prepare calling bcd2ascii()
    addi  sp, sp, -68         # grow stack by 64+4 bytes, some additional
    addi  sp, sp, -68         # grow stack by 64+4 bytes, some additional
    li    a0, 0               # set exit status to zero
.loop:
    vsetvli t0, a2, e32       # configure vectors of 32 bit elements

    vle32.v   v4, (a1)          # Load t0 elements into v4,
                              # starting at the address stored in a1

    slli    t1, t0, 2         # shift-left logical, i.e. times 4
    add     a1, a1, t1        # increment src by read elements
    sub     a2, a2, t0        # decrement n
    bnez    a2, .Loop
