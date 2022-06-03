.text                     # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes
    	
    vand.vv  v1, v2, v3                                  # Prepare calling bcd2ascii()
    addi  sp, sp, -68         # grow stack by 64+4 bytes, some additional
    addi  sp, sp, -68         # grow stack by 64+4 bytes, some additional
    li    a0, 0               # set exit status to zero
.loop:

    vadd.vv v1, v2, v3
    vsub.vv v4, v2, v3    
    vadd.vv v5, v2, v3    
    vle32.v   v4, (a1)          # Load t0 elements into v4,
                              # starting at the address stored in a1    
