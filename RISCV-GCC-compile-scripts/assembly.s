.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

li x30, 1        # Slide amt

li x10, 49       # Iterator over pixels
li x11, 512      # Iterator over output filters
li x12, 2048     # Depth of filter
li x13, 4        # Number of output channels per batch
li x14, 128      # Number of batches

li x21, 1024     # Pointer to start of image
li x22, 1048576  # Pointer to start of weights
li x23, 4194304  # Pointer to start of results

add x6,x21,x0  # Pointer to start of image
add x2,x22,x0  # Pointer to start of weights
add x3,x23,x0  # Pointer to start of results
add x5,x10,x0  # Set to track number of pixels

vsetvli x31, x12, e8, m4	# 8-bit data

l_ch_batch_first_px: nop

add x6, x21, x0              # Pointer to start of image

vle8.v        v0, (x6)        # load pixel in v0  ~ fixed for all output pixels
vmul.vx       v28,  v28, x0   #reset results to zero
vmul.vx       v20,  v20, x0   #reset results to zero

vle8.v        v4, (x2)        # load first filter in v2
add x2, x2, x12

vmul.vv       v24, v0,  v4    # Multiply weights and pixels
vredsum.vs    v28, v24, v28	  # sum to zeroth 

vle8.v        v8, (x2)        # 
add x2, x2, x12

vslideup.vx   v20, v28, x30		# slide up result by one each time 
vadd.vx       v28, v20, x0		# mov to result vector

vmul.vv       v24, v0,  v8    # Multiply weights and pixels
vredsum.vs    v28, v24, v28	  # sum to zeroth 

vle8.v        v12, (x2)        # 
add x2, x2, x12

vslideup.vx   v20, v28, x30		# slide up result by one each time 
vadd.vx       v28, v20, x0		# mov to result vector

vmul.vv       v24, v0,  v12    # Multiply weights and pixels
vredsum.vs    v28, v24, v28	  # sum to zeroth 

vle8.v        v16, (x2)        # 
add x2, x2, x12

vslideup.vx   v20, v28, x30		# slide up result by one each time 
vadd.vx       v28, v20, x0		# mov to result vector

vmul.vv       v24, v0,  v16    # Multiply weights and pixels
vredsum.vs    v28, v24, v28	  # sum to zeroth 

vsetvli x31, x13, e8, m4	# 8-bit data / vlen 16
vse8.v v28, (x3)          # load image in v0

addi x5,  x5,  -1           # one pixel done (first batch of output channels)
add x3, x3, x11          # set x3 to next ofm pixel position

vsetvli x31, x12, e8, m4	# 8-bit data / vlen 64

l_ch_batch_other_px: nop

add           x6, x6, x12     # next pixel
vle8.v        v0, (x6)        # load pixel in v0  ~ fixed for all output pixels
vmul.vx       v28,  v28, x0   #reset results to zero

vmul.vv       v24, v0,  v4    # Multiply weights and pixels 0

vredsum.vs    v28, v24, v28	  # sum to zeroth  0

vmul.vv       v24, v0,  v8    # Multiply weights and pixels 1

vslideup.vx   v20, v28, x30		# slide up result by one each time  0
vadd.vx       v28, v20, x0		# mov to result vector 0

vredsum.vs    v28, v24, v28	  # sum to zeroth 1

vmul.vv       v24, v0,  v12    # Multiply weights and pixels 2

vslideup.vx   v20, v28, x30		# slide up result by one each time 1
vadd.vx       v28, v20, x0		# mov to result vector 1

vredsum.vs    v28, v24, v28	  # sum to zeroth 2

vmul.vv       v24, v0,  v16    # Multiply weights and pixels 3

vslideup.vx   v20, v28, x30		# slide up result by one each time 2
vadd.vx       v28, v20, x0		# mov to result vector 2

vredsum.vs    v28, v24, v28	  # sum to zeroth 3

vsetvli x31, x13, e8, m4	# 8-bit data / vlen 16
vse8.v v28, (x3)          # load image in v0
add x3, x3, x11          # set x3 to next ofm pixel position
vsetvli x31, x12, e8, m4	# 8-bit data / vlen 64

addi x5,  x5,  -1           # one pixel done (first batch of output channels)

beq x5, x0, l_ch_batch_exit
jal l_ch_batch_other_px
l_ch_batch_exit:  nop

addi x14, x14, -1 # one batch finished
add  x5, x10, x0  # reset pixels
add  x23, x23, x13 # offsetreult pointer by batch size
add  x3, x23, x0 # reset result pointer

beq x14, x0, l_finished
jal l_ch_batch_first_px
l_finished: nop
nop
nop
nop
nop





