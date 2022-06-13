.text                     # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

    vredsum.vs v1, v2, v3
    vsub.vv v4, v6, v6    
    vadd.vv v5, v7, v8
    vadd.vv v6, v5, v4
    addi x1, x2, 1
    vslideup.vx v10, v10, x1  
    
    
    vsetvli x2, x0, e16, m1
    vor.vv  v2, v5, v3
    vand.vv v5, v2, v3
    vor.vv  v2, v5, v3
    vand.vv v5, v2, v3
    vsetvli x2, x0, e8, m1	
    vadd.vv v6, v8, v7
    vsub.vv v2, v5, v4
    
