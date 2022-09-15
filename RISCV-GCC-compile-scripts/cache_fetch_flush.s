# TESTING READS AND READ EVICTION 
# 	AS A REASULT OF READING TO SAME CACHE BLOCK
li a0, 0 #set x11 to zero
outer1: nop
li a1, 0 #set x11 to zero
li a2, 64 # number of reads
inner1: nop
lw a7, 0(a0)
addi a0, a0, 4 # increase adress (add offset)
addi a1, a1, 4 # increase iterator (counts bytes to get to a block)
beq a1, a2, einner1
jal inner1
einner1: nop
lui a4, 1
addi a4, a4, 64
beq a0, a4, eouter1
lui a0, 1
jal outer1
eouter1:nop

# TESTING WRITES (WRITEBACK TO LVL1D CACHE) 
# 	AS A REASULT OF READING TO SAME CACHE BLOCK

lui a0, 1
li a1, 0
li a2, 64
inner2: nop
sw a0, 0(a0) #write address value to address (lvl1d), check if dirty is set
addi a0, a0, 4 # increase adress (add offset)
addi a1, a1, 4 # increase iterator (counts bytes to get to a block)
beq a1, a2, einner2
jal inner2
einner2: nop

## TESTING FLUSHES (EVICTION of DIRTY blocks)
lui a0, 2
li a1, 0
li a2, 64
inner3: nop
lw a7, 0(a0) #read address value, check if dirty data is flushed
addi a0, a0, 4 # increase adress (add offset)
addi a1, a1, 4 # increase iterator (counts bytes to get to a block)
beq a1, a2, einner3
jal inner3
einner3: nop
nop
jal einner3


