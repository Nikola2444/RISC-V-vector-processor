.text                     # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

    vle32.v v10, (a3)	
    vse32.v v1, (a4)
    vsub.vv v4, v2, v3    
    vadd.vv v5, v2, v3
    vadd.vv v6, v5, v4
    vsetvli x2, x0, e16, m1
    vor.vv  v2, v5, v3
    vand.vv v5, v2, v3
    vor.vv  v2, v5, v3
    vand.vv v5, v2, v3
    vsetvli x2, x0, e8, m1	
    vadd.vv v6, v8, v7
    vsub.vv v2, v5, v4
    
