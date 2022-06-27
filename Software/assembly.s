# x6 = N, x12 = M, x13 = P, x7 = X pointer, x8 = Y pointer, x9 = Z pointer

addi x7, x0, 0		# X
addi x8, x0, 512	# Y
addi x9, x0, 2560	# Z

addi x6, x0, 16		# N
addi x12, x0, 32	# M
addi x13, x0, 64	# P

vmul.vx v8, v8, x0	# Initializing v8 with zeros

loop4:
	add x11, x0, x13	# x11 = P
	
	loop3:
		vsetvli x16, x11, e16, m2	# 16-bit data
		add x18, x0, x16
		
		loop2:
			add x10, x0, x12			# x10 = M
			# slli x15, x11, 2 			# Needed in case of 32-bit data
			# slli x15, x11, 1 			# Needed in case of 16-bit data
			vsetvli x5, x10, e16, m2	# 16-bit data
			vmul.vx v6, v6, x0			# Initializing v6 with zeros
			
			loop1:
				vsetvli x5, x10, e8, m1		# 8-bit data
				vle8.v v0, (x7)  			# Load a vector form the first matrix
				vlse8.v v2, (x8), x11 		# Load a vector from the second matrix, if 16-bit or 32-bit data is used, then instead of x11 x15 should be used
				vwmul.vv v4, v0, v2   		# Multiply two vectors
				vsetvli x5, x10, e16, m2 	# 16-bit data
				vredsum.vs v6, v4, v6		# Sum reduction
				sub x10, x10, x5			# Calculate how many elements are left to process
				# slli x5, x5, 2 			# Needed if 32-bit date used
				# slli x5, x5, 1 			# Needed if 16-bit date used
				add x7, x7, x5 				# Increment pointer for X
				add x28, x0, x13			# x28 = P
				add x29, x0, x0				# x29 = 0
				
				multiply:
					add x29, x29, x5	        # x29 += x5
					addi x30, x0, 1
					sub x28, x28, x30
					bnez x28, multiply
					
				add x8, x8, x29				# Increment pointer for Y
				bgtz x10, loop1				# Checks if x6 is zero. It should check if x6 is less than zero	
			
			vsetvli x16, x11, e16, m2	# To get the proper vector length
			vslideup.vi v8, v8, 1		# v8[i + 1] = v8[i]
			vadd.vv v8, v8, v6			# Inserts v6[0] in v8
			add x8, x8, 1				# Increment pointer for Y, determines which column in matrix Y is next, 2 and 4 for 16- and 32-bit inputs, respectively
			addi x30, x0, 1
			sub x16, x16, x30
			bnez x16, loop2
		
		vse16.v v8, (x9) 			# Store result, ovaj store treba modifikovati
		vmul.vx v8, v8, x0			# Resetting v8
		slli x30, x18, 2			# 1 and 4 in case of 8-bit and 32-bir results
		addi x9, x9, x30			# Increment pointer for Z
		sub x11, x11, x18			# For one row of matrix X P columns of matrix Y have to be processed
		bgtz x11, loop3				# Check if x11 is zero

addi x30, x0, 1
sub x6, x6, x30		# We have to go through all the rows of matrix X
add x7, x7, x12		# Increment pointer for Y
bnez x6, loop4		# Check if x6 is zero
