	.text                     # Start text section
	    .balign 4                 # align 4 byte instructions by 4 bytes

	addi x2, x0, 3
	addi x10, x0, 1
	addi x1, x0, 10
	vsetvli x2, x0, e16, m1
	vslideup.vx v10, v11, x1
	#sw   x4, 0(x5)
loop1:			    	    


	beq x1, x2, jmp
	addi x10, x10, 5
jmp:
	addi x1, x0, 15       
	vadd.vv v1, v2, v3
	vsub.vv v4, v6, v6    
	vadd.vv v5, v7, v8
	vadd.vv v6, v7, v8
	  
	vsetvli x2, x0, e16, m1
	vadd.vv v6, v8, v7
	vsub.vv v2, v5, v4
	vsetvli x2, x0, e8, m1
	nop
	nop
	nop
	#vslidedown.vx v1, v2, x1	    
