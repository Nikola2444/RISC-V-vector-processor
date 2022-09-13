.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

li x30, 1        # Slide amt

li x10, 3136     # Iterator over pixels
li x12, 128      # Number of Pixels/Weights [INPUT DIM]
li x11, 512      # Iterator over output filters [OUTPUT DIM]
li x13, 16       # Number of output channels per batch [BATCH_SIZE]
li x14, 8        # Number of batches [OUT_D / BATCH_SIZE]

li x21, 1024     # Pointer to start of image
li x22, 1048576  # Pointer to start of weights
li x23, 4194304  # Pointer to start of results

add x6,x21,x0  # Pointer to start of image
add x2,x22,x0  # Pointer to start of weights
add x3,x23,x0  # Pointer to start of results
add x5,x10,x0  # Set to track number of pixels

vsetvli x31, x12, e8, m1	# 8-bit data

l_ch_batch_first_px: nop

add x6, x21, x0              # Pointer to start of image

vle8.v        v0, (x6)        # load pixel in v0  ~ fixed for all output pixels
vmul.vx       v31,  v31, x0   #reset results to zero
vmul.vx       v29,  v29, x0   #reset results to zero

vle8.v        v1, (x2)        # load first filter in v1
add x2, x2, x12

vmul.vv       v30, v0,  v1    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v2, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v2    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v3, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v3    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v4, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v4    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v5, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v5    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v6, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v6    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v7, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v7    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v8, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v8    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v9, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v9    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v10, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v10    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v11, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector


vmul.vv       v30, v0,  v11    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v12, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v12    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v13, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v13    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v14, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v14    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v15, (x2)        # load first filter in v1
add x2, x2, x12

vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vmul.vv       v30, v0,  v15    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vle8.v        v16, (x2)       # load first filter in v1
add x2, x2, x12


vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

addi x5,  x5,  -1           # one pixel done (first batch of output channels)

vmul.vv       v30, v0,  v16    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 

vsetvli x31, x13, e8, m1	# 8-bit data / vlen 16
vse8.v v31, (x3)          # load image in v0

add x3, x3, x11          # set x3 to next ofm pixel position
vsetvli x31, x12, e8, m1	# 8-bit data / vlen 64


l_ch_batch_other_px: nop

add           x6, x6, x12     # next pixel
vle8.v        v0, (x6)        # load pixel in v0  ~ fixed for all output pixels
vmul.vx       v31,  v31, x0   #reset results to zero

vmul.vv       v30, v0,  v1    # Multiply weights and pixels
vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v2    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v3    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v4    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v5    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v6    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v7    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v8    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v9    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v10    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v11    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v12    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v13    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v14    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v15    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 
vmul.vv       v30, v0,  v16    # Multiply weights and pixels
vslideup.vx   v29, v31, x30		# slide up result by one each time 
vadd.vx       v31, v29, x0		# mov to result vector

vredsum.vs    v31, v30, v31	  # sum to zeroth 

vsetvli x31, x13, e8, m1	# 8-bit data / vlen 16
vse8.v v31, (x3)          # load image in v0
add x3, x3, x11          # set x3 to next ofm pixel position
vsetvli x31, x12, e8, m1	# 8-bit data / vlen 64

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





