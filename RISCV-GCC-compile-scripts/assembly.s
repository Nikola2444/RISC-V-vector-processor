.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

  
li x10, 64   # Number of Pixels/Weights
li x11, 1024 # Pointer to start of image
li x12, 2048 # Pointer to start of biases
li x13, 4096 # Pointer to start of result
li x14, 3072 # Pointer to start of weights
li x16, 1 # Pointer to start of weights
addi x15, x0, 0
vsetvli x31, x10, e8, m1	# 8-bit data

add x17, x0, x10           # Set iterator to number of pixels

vle8.v v0, (x11)          # load image in v0  ~ fixed for all output pixels
vmul.vx       v28, v28, x0     #reset to zero
vmul.vx       v8,  v8, x0     #reset to zero

l_image_loop:

vle8.v        v16, (x13)       # load first set of weights in v16
vmul.vv       v16, v0, v16     # Multiply weights and pixels


vredsum.vs    v28, v16, v28	   # sum

addi x17,  x17,  -1               # one output pixel done, reduce iterator of the loop
beq x17, x0, l_image_loop_exit


vslideup.vx   v8,  v28, x16		 # slide up result by one each time, 
vadd.vx       v28, v8, x0     # add up v28 with v8 to add pixel to result 
            
add x13, x13, x10               # increment weight pointer to next set of weights

jal l_image_loop
l_image_loop_exit:nop


vle8.v v8, (x12)          # load biases in v8 ~ fixed for all output pixels
vadd.vv v28, v28, v8
vse8.v v28, (x14)          # load image in v0


l_finished:nop
nop
nop
nop
nop
jal l_finished



