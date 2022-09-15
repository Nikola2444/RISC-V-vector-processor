# TESTING READS AND READ EVICTION 
# 	AS A REASULT OF READING TO SAME CACHE BLOCK
li a0, 0 #set x11 to zero
outer1: li a1, 0 #set x11 to zero
li a2, 64 # number of reads
inner1: lw a7, 0(a0)
addi a0, a0, 4 # increase adress (add offset)
addi a1, a1, 4 # increase iterator (counts bytes to get to a block)
beq a1, a2, einner1
jal inner1
einner1: lui a4, 1
addi a4, a4, 64
beq a0, a4 eouter1
lui a0, 1
jal outer1
# TESTING WRITES (WRITEBACK TO LVL1D CACHE) 
# 	AS A REASULT OF READING TO SAME CACHE BLOCK
eouter1:lui a0, 1
li a1, 0
li a2, 64
inner2: sw a0, 0(a0) #write address value to address (lvl1d), check if dirty is set
addi a0, a0, 4 # increase adress (add offset)
addi a1, a1, 4 # increase iterator (counts bytes to get to a block)
beq a1, a2, einner2
jal inner2
## TESTING FLUSHES (EVICTION of DIRTY blocks)
einner2: lui a6, 1
outer3: slli a6, a6, 1
addi a0, a6, 0
li a1, 0
li a2, 64
inner3: lw a7, 0(a0) #read address value, check if dirty data is flushed
addi a0, a0, 4 # increase adress (add offset)
addi a1, a1, 4 # increase iterator (counts bytes to get to a block)
beq a1, a2, einner3
jal inner3
einner3: jal outer3
