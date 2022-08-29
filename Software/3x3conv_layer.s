.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

li x30, 1        # Slide amt

li x9,  56     # Iterator over pixels
li x10, 56     # Iterator over pixels
li x11, 64     # Iterator over output filters
li x12, 64     # Number of Pixels/Weights
li x13, 16     # Number of output channels per batch
li x14, 4      # Number of batches
li x15, 3712   # Input feature map row size

li x21, 1024     # Pointer to start of image
li x22, 1048576  # Pointer to start of weights
li x23, 1064960  # Pointer to start of results

addi x6, x11, x0  # Iterator over filters 

addi x2, x22,x0  # Pointer to start of weights

vsetvli x1, x12, e8, m1	# 8-bit data

l_ld_next_filter: nop

addi x24, x21, 0    # First row
add  x25, x24, x15  # Second row
add  x26, x25, x15  # Third row

addi x5,  x10, x0  # Iterator over X
addi x4,  x9,  x0  # Iterator over Y

add x3, x23, x0 # set start address if a result

# LOAD A FILTER
vle8.v  v10, (x2)
add x2, x2, x12
vle8.v  v11, (x2)
add x2, x2, x12
vle8.v  v12, (x2)
add x2, x2, x12
vle8.v  v13, (x2)
add x2, x2, x12
vle8.v  v14, (x2)
add x2, x2, x12
vle8.v  v15, (x2)
add x2, x2, x12
vle8.v  v16, (x2)
add x2, x2, x12
vle8.v  v17, (x2)
add x2, x2, x12
vle8.v  v18, (x2)
add x2, x2, x12

l_start_next_row: nop

addi x27, x24, 0 #First row and counting
addi x28, x25, 0 #Second row and counting
addi x29, x26, 0 #Third row and counting

vmul.vx       v31, v31, 0     # Reset results

#LOAD FIRST PIXEL IN A ROW
#First row
vle8.v v0, (x27)
add x27, x27, x12
vle8.v v1, (x27)
add x27, x27, x12
vle8.v v2, (x27)
add x27, x27, x12
#Second row
vle8.v v3, (x28)
add x28, x28, x12
vle8.v v4, (x28)
add x28, x28, x12
vle8.v v5, (x28)
add x28, x28, x12
#Third row
vle8.v v6, (x29)
add x29, x29, x12
vle8.v v7, (x29)
add x29, x29, x12
vle8.v v8, (x29)
add x29, x29, x12

# MAC FILTER X IMAGE 3x3
vmul.vx       v30, v30, 0     # Reset results
vmul.vv       v29, v0,  v10   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v1,  v11   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v2,  v12   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v3,  v13   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v4,  v14  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v5,  v15  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v6,  v16  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v7,  v17  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v8,  v18  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 

vsetvli       x1, x30, e8, m1	# 8-bit data
vse8.v        v31, (x3)          # load image in v0
add           x3, x3, x11
vsetvli       x1, x12, e8, m1	# 8-bit data

addi x5, x5, -1

l_next_3_same_row: nop

# Load another 3 pixels, shift to left the ones being reused
vadd.vx       v0, v1, x0
vadd.vx       v1, v2, x0
vle8.v        v2, (x27)
add x27, x27, x12

vadd.vx       v3, v4, x0
vadd.vx       v4, v5, x0
vle8.v        v5, (x28)
add x28, x28, x12

vadd.vx       v6, v7, x0
vadd.vx       v7, v8, x0
vle8.v        v8, (x29)
add x29, x29, x12

# MAC FILTER X IMAGE 3x3
vmul.vx       v30, v30, 0     # Reset results
vmul.vv       v29, v0,  v10   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v1,  v11   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v2,  v12   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v3,  v13   # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v4,  v14  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v5,  v15  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v6,  v16  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v7,  v17  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 
vmul.vv       v29, v8,  v18  # Multiply weights and pixels
vredsum.vs    v31, v29, v31	  # sum to zeroth 

vsetvli       x1, x30, e8, m1	# 8-bit data
vse8.v        v31, (x3)          # load image in v0
add           x3, x3, x11
vsetvli       x1, x12, e8, m1	# 8-bit data

addi x5, x5, -1

beq x5, x0, l_ld_row_finished

jal l_next_3_same_row

l_row_finished: nop

#go to next row

addi x4, x4, -1

add x24, x25, x0 
add x25, x26, x0
add x26, x26, x15

beq x4, x0, l_ld_filter_finished

jal l_start_next_row

l_ld_filter_finished: nop

addi x23, x23, 1 # results incremented by 1 for next filter
addi x6, x6 -1

beq x6, x0, l_finised

jal l_ld_next_filter

l_finished: nop
nop
nop
nop





