/******************************************************************************
 *
 * Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Use of the Software is limited solely to applications:
 * (a) running on a Xilinx device, or
 * (b) that interact with a Xilinx device through a bus or interconnect.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
 * OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Except as contained in this notice, the name of the Xilinx shall not be used
 * in advertising or otherwise to promote the sale, use or other dealings in
 * this Software without prior written authorization from Xilinx.
 *
 ******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <unistd.h>
#include <inttypes.h>

#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_io.h"

#include "platform.h"
#include "xparameters.h"

#include "assembly.h"

// SUPPORT CONSTANTS
#define MEMORY_SIZE				6*1024
#define FIRST_N_NBYTES			128
// REGISTERS
#define USR_RISCV_CE 			(XPAR_RISCV_V_0_BASEADDR + 0)
#define USR_MEM_BASE_ADDRESS 		(XPAR_RISCV_V_0_BASEADDR + 4)
#define USR_RISCV_PC		 	(XPAR_RISCV_V_0_BASEADDR + 8)

int main()
{
	int read_pc = 0;
	int read_ce = 0;
	u32 main_memory [MEMORY_SIZE] = {0};
	init_platform();
	// Invalidate range of memory which we are using as main
	Xil_DCacheInvalidateRange((int)main_memory,MEMORY_SIZE);
	Xil_ICacheInvalidateRange((int)main_memory,MEMORY_SIZE);
	for(int i = 0; i < MEMORY_SIZE; i++)
		main_memory[i] = 0;
	// Read program counter and clock enable values
	// To make sure processor isn't running
	read_pc = Xil_In32(USR_RISCV_PC);
	read_ce = Xil_In32(USR_RISCV_CE);
	printf("\nPC value: %d\n CE value: %d\n",read_pc,read_ce);


	// Checking if memory is initialized to zero
	printf("\n***** Checking memory array to see if it's initialized to all zeros *****\n");
	printf("*** First and last block of memory, each location is 32b = 4B ***\n");
	printf("*** Pairs [address:data] will be displayed ***\n");
	printf("\n* First block *\n");
	for(int i = 0; i < 16; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:0x%08x; ",(i*4),(unsigned int)main_memory[i]);
	}
	printf("\n\n* Last block *\n");
	for(int i = MEMORY_SIZE-16; i < MEMORY_SIZE; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:0x%08x; ",(i*4),(unsigned int)main_memory[i]);
	}

	// Initializing memory array with assembly code of test program
	/* Goal is to catch eviction of a block to main memory.
	 * Eviction will happen as a consequence of set trashing LVL2 4-way cache.
	 * Assembly program reads a block  starting with 4096 and ending with 4159),
	 * then writes 4096-4159 data to it. That is, processor will write 4096 to 
	 * location 4096; 4100 to 4100 etc...
	 * After that, processor in a loop reads blocks 8192, 12288, 16384 and 20480 
	 * These 4 blocks will evict block 4096 from lvl2 4-way cache forsing processor
	 * to push data to main memory. As our main memory is a simple array, we can notice
	 * change in array after processor writes data to locations 4096-4160
	 * Notice that each place in our test memory is 4 bytes, so actual adresses that
	 * are going to change are 1024-1040 ! */

	// Find size of assembly program (machine code), then initialize memory
	size_t assembly_num_el = sizeof(assembly)/sizeof(assembly[0]);
	for (int i=0; i<assembly_num_el; i++)
		main_memory[i] = assembly[i];

	printf("\n\n***** Checking memory array after initialization with machine code *****\n");
	printf("*** First block and target block will be displayed ***\n");
	printf("\n* First block [0-64]: *\n");
	for(int i = 0; i < 16; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:0x%08x; ",(i*4),(unsigned int)main_memory[i]);
	}
	printf("\n\n* Target block [4096-4160]: *\n");
	for(int i=1024; i<1040; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:%d;  ",(i*4),(unsigned int)main_memory[i]);
	}
	printf("\n");

	// Processor needs to know base adress of memory, 
	// It will start executing from this locatons onward.
	printf("\nThis is first memory address %p\n",&main_memory[0]);
	Xil_Out32(USR_MEM_BASE_ADDRESS, (u32)&main_memory[0]);

	// Start executing program (by setting ce to 1)
	Xil_Out32(USR_RISCV_CE, (u32)1);
	// Wait for enough time to set trash and force eviction
	sleep(5);
	// We can stop execution now, no need for processor to spin
	//Xil_Out32(USR_RISCV_CE, (u32)0);

	printf("\n***** Checking memory array after program execution *****\n");
	printf("*** First block and target block will be displayed ***\n");
	printf("\n* First block [0-64]: *\n");
	for(int i = 0; i < 16; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:0x%08x; ",(i*4),(unsigned int)main_memory[i]);
	}
	printf("\n\n* Target block [4096-4160]: *\n");
	for(int i=1024; i<1040; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:%d;  ",(i*4),(unsigned int)main_memory[i]);
	}
	printf("\n\n* If target blocks have values 4096-4156, the program executed as expected *\n");
	/* TESTED:
	 * level 1 instruction cache fetch
	 * level 1 data cache fetch and flush
	 * level 2 fetching until all 4 ways are filled
	 * level 2 forsed flushing (and eviction) due to set trashing */

	cleanup_platform();
	return 0;
}
