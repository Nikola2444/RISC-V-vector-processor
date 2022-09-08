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
* * The above copyright notice and this permission notice shall be included in * all copies or substantial portions of the Software.
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

#include "xil_exception.h"
#include "xscugic.h"

#include "assembly.h"

// NOTE: UNCOMMENT FOR DEBUG SIGNALS
#define DBG_PRINTS

// SUPPORT CONSTANTS
#define MEMORY_SIZE       8192*1024

#define BATCH_SIZE        16
#define IMAGE_START       1024
#define FILTER_START      1048576
#define RESULT_START      4194304

// REGISTERS
#define USR_RISCV_CE          (XPAR_RISCV_V_0_BASEADDR + 0)
#define USR_MEM_BASE_ADDRESS  (XPAR_RISCV_V_0_BASEADDR + 4)
#define USR_RISCV_PC          (XPAR_RISCV_V_0_BASEADDR + 8)
#define USR_RISCV_INTERRUPT   (XPAR_RISCV_V_0_BASEADDR + 12)

#define IM_SIZE 3
#define IN_D    512
#define OUT_D   16


volatile u32 main_memory [MEMORY_SIZE]        = {0};
u8 ifm    [IM_SIZE][IM_SIZE]       [IN_D];
u8 filter                   [OUT_D][IN_D];
u8 ofm    [IM_SIZE][IM_SIZE][OUT_D]       ={0};
u8 ro_ofm;

int main()
{
  int read_pc = 0;
  int read_ce = 0;
  int read_int = 0;

  unsigned int missmatches = 0;

  volatile u8  * main_memory_bw = (u8 *) main_memory; // byte-wise access to main memory

  init_platform();
  // Invalidate range of memory which we are using as main
  Xil_DCacheInvalidateRange((int)main_memory,MEMORY_SIZE);
  Xil_ICacheInvalidateRange((int)main_memory,MEMORY_SIZE);

  // Explicitly reset memory
  for(int i = 0; i < MEMORY_SIZE; i++)
    main_memory[i] = 0;

  #ifdef DBG_PRINTS
  // Read register values to make sure processor isn't running
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\n CE value: %d\n INT value: %d\n",read_pc,read_ce,read_int);
  #endif

  // Processor needs to know base adress of memory,
  // It will start executing from this locatons onward.
  Xil_Out32(USR_MEM_BASE_ADDRESS, (u32)&main_memory[0]);
  #ifdef DBG_PRINTS
  printf("\nThis is first memory address %p\n",&main_memory[0]);
  #endif

  // *************** INITIALIZE WITH MACHINE CODE *****************************************
  // Find size of assembly program (machine code), then initialize memory
  size_t assembly_num_el = sizeof(assembly)/sizeof(assembly[0]);
  for (int i=0; i<assembly_num_el; i++)
    main_memory[i] = assembly[i];
  // Check if it's initialized
  #ifdef DBG_PRINTS
  printf("\n\n***** Checking memory array after initialization with machine code *****\n");
  printf("\n* First block [0-64]: *\n");
  for(int i = 0; i < 16; i++)
  {
    if(i%8 == 0)
      printf("\n");
    printf("%d:0x%08x; ",(i*4),(unsigned int)main_memory[i]);
  }
  #endif

  // Initialize input feature map (Image)
  for (int y=0; y<IM_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE; x++)
    {
      for (int ich=0; ich<IN_D; ich++)
      {
        ifm[y][x][ich]=y*IM_SIZE+x+ich%3;
        main_memory_bw[IMAGE_START+(y*IM_SIZE*IN_D)+(x*IN_D)+ich]=ifm[y][x][ich];
      }
    }
  }
  #ifdef DBG_PRINTS
  printf("\n\n* Input feature map (for:y=0,x=0) DDR[IMAGE_START:IMAGE_START+IN_D]: *\n");
  // Print some values for conformation
  for(int i=IMAGE_START; i<IMAGE_START+IN_D; i++)
  {
    if(i%8 == 0)
      printf("\n");
    printf("%d:%02x;  ",(i),(unsigned char)main_memory_bw[i]);
  }
  #endif

  // Initialize filters
  for (int och=0; och<OUT_D; och++)
  {
    for (int ich=0; ich<IN_D; ich++)
    {
      filter[och][ich]=((och+ich)-(ich%10));
      main_memory_bw[FILTER_START+(och*IN_D)+ich]=filter[och][ich];
    }
  }
  #ifdef DBG_PRINTS
  printf("\n\n* Filter values (for:och=0) DDR[FILTER_START:FILTER_START+IN_D]: *\n");
  for(int i=FILTER_START; i<FILTER_START+IN_D; i++)
  {
    if(i%8 == 0)
      printf("\n");
    printf("%d:%02x;  ",(i),(unsigned char)main_memory_bw[i]);
  }
  #endif


  #ifdef DBG_PRINTS
  printf("\n");
  printf("\n\n* Output layer (result) vector for y=0 x=0 [RESULT_START:RESULT_START+OUT_D]: *\n");
  for(int i=RESULT_START; i<RESULT_START+OUT_D; i++)
  {
    if(i%8 == 0)
      printf("\n");
    printf("%d:%02x;  ",(i),(unsigned char)main_memory_bw[i]);
  }
  printf("\n");
  #endif

  // Reference model (Expected results)
  //****************************************************************************************
  for (int y=0; y<IM_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE; x++)
    {
      for (int och=0; och<OUT_D; och++)
      {
        ofm[y][x][och] = 0;
        for (int ich=0; ich<IN_D; ich++)
        {
          ofm[y][x][och]+=(ifm[y][x][ich]*filter[och][ich]);
        }
      }
    }
  }
  #ifdef DBG_PRINTS
  printf("\n\n* Expected result vector (for:y=0,x=0) DDR[RESULT_START:RESULT_START+OUT_D]: *\n");
  for (int och=0; och<OUT_D; och++)
  {
    if(och%8 == 0)
      printf("\n");
    printf("%d:%02x;  ",(och),(unsigned char)ofm[0][0][och]);
  }
  #endif
  //****************************************************************************************
  
  #ifdef DBG_PRINTS
  // Read register values
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\n CE value: %d\n INT value: %d\n",read_pc,read_ce,read_int);
  #endif

  // Start executing program (by setting ce to 1)
  Xil_Out32(USR_RISCV_CE, (u32)1);

  #ifdef DBG_PRINTS
  // Read register values
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\n CE value: %d\n INT value: %d\n",read_pc,read_ce,read_int);
  #endif

  /* read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc);
  */


  // Wait until finished
  sleep(1);
  // We can stop execution now, no need for processor to spin
  Xil_Out32(USR_RISCV_CE, (u32)0);

  #ifdef DBG_PRINTS
  printf("\n\n* Data is printed in format addr:data *\n");
  printf("\n\n* Output feature map (for:y=0,x=0) DDR[RESULT_START:RESULT_START+OUT_D]: *\n");
  for(int i=RESULT_START; i<RESULT_START+OUT_D; i++)
  {
    if(i%8 == 0)
      printf("\n");
    printf("%d:%02x;  ",(i),(unsigned char)main_memory_bw[i]);
  }
  printf(".\n");
  #endif


  /*
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  read_pc  = Xil_In32(USR_RISCV_PC);
  printf("\nPC value: %d\n",read_pc/4);
  */

  // Read register values
  #ifdef DBG_PRINTS
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\n CE value: %d\n INT value: %d\n",read_pc,read_ce,read_int);
  #endif

  printf("\n Checking results... \n");
  for (int y=0; y<IM_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE; x++)
    {
      for (int och=0; och<OUT_D; och++)
      {
        ro_ofm = ofm[y][x][(och/16+1)*BATCH_SIZE-(och%BATCH_SIZE)-1];
        if (ro_ofm!=main_memory_bw[RESULT_START+(y*IM_SIZE*OUT_D+x*OUT_D+och)])
        {
          missmatches++;
          printf("Missmatch! %02x:%02x\n",ro_ofm, main_memory_bw[RESULT_START+(y*IM_SIZE*OUT_D+x*OUT_D+och)]);
        }
      }
    }
  }

  if(missmatches)
    printf("\n***** TEST FAILED! Missmatches:%d \n",missmatches);
  else
    printf("\n***** TEST PASSED!\n");



  print("done.\n");
  cleanup_platform();
  return 0;
}
