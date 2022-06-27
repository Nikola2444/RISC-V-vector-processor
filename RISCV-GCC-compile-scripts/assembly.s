.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

    addi x1, x0,  64
    addi x2, x0, 1024
    
    addi x3, x0, 1024
    addi x3, x3, 1024
    
    addi x4, x0, 1024
    addi x4, x4, 1024
    addi x4, x4, 1024
    addi x4, x4, 1024
    addi x4, x4, 1024
    addi x4, x4, 1024
    addi x4, x4, 1024
    addi x4, x4, 1024
    
    vsetvli x10, x1, e32, m1
    
    vle32.v v2, (x4)
    vadd.vv v4, v2, v3
    vadd.vv v5, v2, v4
    vle32.v v3, (x4)    

    vadd.vv v4, v2, v3

    nop
    nop
    nop
    nop
    addi x4, x0, 4
    vse32.v v4, (x4) 
   
    
    lw1: nop
    nop
    nop
    nop
    nop
    jal lw1
