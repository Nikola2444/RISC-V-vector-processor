# x6 = N, x12 = M, x13 = P, x7 = X pointer, x8 = Y pointer, x9 = Z pointer

addi x6, x0, 5120	# Bias
addi x7, x0, 0		# X
addi x8, x0, 512	# Y
addi x9, x0, 2560	# Z

addi x12, x0, 32	# M
addi x11, x0, 64	# P

# NxM * MxP = NxP
# 1xM * MxP = 1xP

vmul.vx v8, v8, x0	# Initializing v8 with zeros
add  x13, x0, x11 	# P

loop3:
	vsetvli x16, x11, e16, m2	# 16-bit data
	add x18, x0, x16
	
	loop2:
		add x10, x0, x12			# x10 = M
		vsetvli x5, x10, e16, m2	# 16-bit data
		vmul.vx v6, v6, x0			# Initializing v6 with zeros
		
		loop1:
			vsetvli x5, x10, e8, m1		# 8-bit data
			vle8.v v0, (x7)  			# Load a vector form the first matrix
			vle8.v v2, (x8)	 			# Load a vector from the second matrix
			vwmul.vv v4, v0, v2   		# Multiply two vectors
			vsetvli x5, x10, e16, m2 	# 16-bit data
			vredsum.vs v6, v4, v6		# Sum reduction
			sub x10, x10, x5			# Calculate how many elements are left to process
			add x7, x7, x5 				# Increment pointer for X
			add x8, x8, x5				# Increment pointer for Y
			bgtz x10, loop1				# Checks if x6 is zero. It should check if x6 is less than zero
		
		vsetvli x16, x11, e16, m2	# To get the proper vector length
		vslideup.vi v8, v8, 1		# v8[i + 1] = v8[i]
		vadd.vv v8, v8, v6			# Inserts v6[0] in v8
		add x8, x8, 1				# Increment pointer for Y
		addi x30, x0, 1
		sub x16, x16, x30
		bnez x16, loop2
	
	vle16.v v10, (x6)			# Load bias
	vadd.vv v8, v8, v10			# Add bias to the calculated result
	vse16.v v8, (x9) 			# Store result
	vmul.vx v8, v8, x0			# Resetting v8
	slli x30, x18, 2			# 1 and 4 in case of 8-bit and 32-bir results
	add x9, x9, x30			    # Increment pointer for Z
	sub x11, x11, x18			# For one row of matrix X P columns of matrix Y have to be processed
	bgtz x11, loop3				# Check if x11 is zero
