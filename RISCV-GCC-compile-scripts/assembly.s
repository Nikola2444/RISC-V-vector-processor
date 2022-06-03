.text                     # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes
    	
    vadd.vv v1, v2, v3
    vsub.vv v4, v2, v3    
    vadd.vv v5, v2, v3
    vadd.vv v6, v5, v4
    vsetvli x0, x0, e32, m1
    vor.vv  v2, v5, v3
    vand.vv v5, v2, v3
