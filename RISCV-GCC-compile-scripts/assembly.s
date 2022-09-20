.text                         # Start text section
    .balign 4                 # align 4 byte instructions by 4 bytes

li x30, 1        # Slide amt


li x12, 128      # Number of Pixels/Weights [INPUT DIM]
li x11, 512      # Iterator over output filters [OUTPUT DIM]
li x13, 16       # Number of output channels per batch [BATCH_SIZE]
li x14, 8        # Number of batches [OUT_D / BATCH_SIZE]

li x21, 1024     # Pointer to start of image


add x6,x21,x0  # Pointer to start of image
add x2,x22,x0  # Pointer to start of weights
add x3,x23,x0  # Pointer to start of results
add x5,x10,x0  # Set to track number of pixels

vsetvli x31, x12, e8, m1	# 8-bit data

add x6, x21, x0              # Pointer to start of image

vle8.v        v0, (x6)        # load pixel in v0  ~ fixed for all output pixels
vslideup.vx   v1, v0, x30		# slide up result by one each time 
vse8.v v1, (x3)          # load image in v0
