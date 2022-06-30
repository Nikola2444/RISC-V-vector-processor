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
#define MEMORY_SIZE				8*1024
#define FIRST_N_NBYTES			128
// REGISTERS
#define USR_RISCV_CE 			(XPAR_RISCV_V_0_BASEADDR + 0)
#define USR_MEM_BASE_ADDRESS 	(XPAR_RISCV_V_0_BASEADDR + 4)
#define USR_RISCV_PC		 	(XPAR_RISCV_V_0_BASEADDR + 8)
#define LAYER_LEN				256
int main()
{
	int read_pc = 0;
		int read_ce = 0;
	u32 main_memory [MEMORY_SIZE] = {0};
	u8  * main_memory_bw = (u8 *) main_memory; // byte-wise access to main memory
	u8  exp_result [LAYER_LEN] = {0}; // bytewise access to main memory

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
	// Processor needs to know base adress of memory,
	// It will start executing from this locatons onward.
	printf("\nThis is first memory address %p\n",&main_memory[0]);
	Xil_Out32(USR_MEM_BASE_ADDRESS, (u32)&main_memory[0]);

	// *************** INITIALIZE WITH MACHINE CODE *****************************************
	// Find size of assembly program (machine code), then initialize memory
	size_t assembly_num_el = sizeof(assembly)/sizeof(assembly[0]);
	for (int i=0; i<assembly_num_el; i++)
		main_memory[i] = assembly[i];
	printf("\n\n***** Checking memory array after initialization with machine code *****\n");
	printf("\n* First block [0-64]: *\n");
	for(int i = 0; i < 16; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:0x%08x; ",(i*4),(unsigned int)main_memory[i]);
	}

	printf("\n\n* Image vector (pixels) [1024:1024+LAYER_LEN]: *\n");
	for(int i=1024; i<1024+LAYER_LEN; i++)
	{
		main_memory_bw[i] = i%LAYER_LEN;
		if(i%8 == 0)
			printf("\n");
		printf("%d:%d;  ",(i),(unsigned char)main_memory_bw[i]);
	}
	printf("\n");
	printf("\n\n* Biases vector (for each of the weights) [2048:2048+LAYER_LEN]: *\n");
	for(int i=2048; i<2048+LAYER_LEN; i++)
	{
		main_memory_bw[i] = i%LAYER_LEN;
		if(i%8 == 0)
			printf("\n");
		printf("%d:%d;  ",(i),(unsigned char)main_memory_bw[i]);
	}
	printf("\n");
	printf("\n\n* Output layer (result) vector [4096:4096+LAYER_LEN]: *\n");
	for(int i=3072; i<3072+LAYER_LEN; i++)
	{
		if(i%8 == 0)
			printf("\n");
		printf("%d:%d;  ",(i),(unsigned char)main_memory_bw[i]);
	}
	printf("\n");
	printf("\n\n* Weight vectors (for each output pixel) [4096:4096+(128)...]: *\n");
	for(int i=4096; i<(4096+(LAYER_LEN*LAYER_LEN)); i++)
	{
		main_memory_bw[i] = i%LAYER_LEN;
		if(i<(4096+128))
		{
			if(i%8 == 0)
				printf("\n");
			printf("%d:%d;  ",(i),(unsigned char)main_memory_bw[i]);
		}

	}
	printf("\n");
	 // Reference model.
		//****************************************************************************************
		for(int op=0; op<LAYER_LEN; op++)
		{
			exp_result[op] = main_memory_bw[2048+op];
			for(int px=0; px<LAYER_LEN; px++)
			{
				exp_result[op] += main_memory_bw[1024+px]*main_memory_bw[4096+(LAYER_LEN*op)+px];
			}
		}
		//****************************************************************************************
		printf("\n\n* Expected result: *\n");
		printf("\n\n* Data is printed in format addr:data *\n");
		for(int op=0; op<LAYER_LEN; op++)
		{
			if(op%8 == 0)
				printf("\n");
			printf("%d:%d;  ",(op),(unsigned char)exp_result[op]);
		}


		// Start executing program (by setting ce to 1)
		Xil_Out32(USR_RISCV_CE, (u32)1);
		// Wait for enough time to set trash and force eviction
		sleep(1);
		// We can stop execution now, no need for processor to spin
		//Xil_Out32(USR_RISCV_CE, (u32)0);

		printf("\n");
		printf("\n\n* Output layer (result) vector [3072:3072+LAYER_LEN]: *\n");
		printf("\n\n* Data is printed in format addr:data *\n");
		for(int i=0; i<+LAYER_LEN; i++)
		{
			if(i%8 == 0)
				printf("\n");
			printf("%d:%d;  ",(i),(unsigned char)main_memory_bw[3072+i]);
		}
		 printf(".\n");



    print("done.\n");
    cleanup_platform();
    return 0;
}
