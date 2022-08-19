.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

nop  
addi x10, x10, 256   # Number of Pixels/Weights
addi x11, x11, 1024 # Pointer to start of image
addi x12, x12, 1024 # Pointer to start of biases
addi x12, x12, 1024 # Pointer to start of biases	
addi x13, x13, 1024 # Pointer to start of result
addi x13, x13, 1024 # Pointer to start of result
addi x13, x13, 1024 # Pointer to start of result
addi x13, x13, 1024 # Pointer to start of result		
addi x14, x14, 1024 # Pointer to start of weights
addi x14, x14, 1024 # Pointer to start of weights
addi x14, x14, 1024 # Pointer to start of weights
addi x16, x16, 9 # Pointer to start of weights
addi x15, x0, 0
vsetvli x31, x10, e8, m1	# 8-bit data	
vle8.v v28, (x11)          # load image in v0  ~ fixed for all output pixels
vslideup.vx   v8,  v28, x16		 # slide up result by one each time, 	


l_finished:nop
nop
nop
nop
nop
jal l_finished



