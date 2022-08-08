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
addi x16, x16, 1 # Pointer to start of weights
addi x15, x0, 0


l_finished:nop
nop
nop
nop
nop
jal l_finished



