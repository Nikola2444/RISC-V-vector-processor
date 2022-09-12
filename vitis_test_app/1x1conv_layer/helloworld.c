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

#include "xtime_l.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xil_io.h"

#include "platform.h"
#include "xparameters.h"

#include "xil_exception.h"
#include "xscugic.h"

#include "assembly.h"

// TODO: UNCOMMENT TO CHANGE BEHAVIOUR *************************
#define DBG_PRINTS
#define USE_INTERRUPT
// ***********************************************************

// Interrupt parameters
#ifdef USE_INTERRUPT
#define INTC_DEVICE_ID 		XPAR_PS7_SCUGIC_0_DEVICE_ID
#define RISCVV_INTR_ID		XPAR_FABRIC_RISCV_V_0_INTERRUPT_O_INTR
#endif

// SUPPORT CONSTANTS
#define MEMORY_SIZE       8192*1024


#define IMAGE_START       1024
#define FILTER_START      1048576
#define RESULT_START      4194304

// REGISTERS
#define USR_RISCV_CE          (XPAR_RISCV_V_0_BASEADDR + 0)
#define USR_MEM_BASE_ADDRESS  (XPAR_RISCV_V_0_BASEADDR + 4)
#define USR_RISCV_PC          (XPAR_RISCV_V_0_BASEADDR + 8)
#define USR_RISCV_INTERRUPT   (XPAR_RISCV_V_0_BASEADDR + 12)

#define IM_SIZE           28
#define IN_D              512
#define OUT_D             128
#define BATCH_SIZE        16  // Only for 1x1 assembly
#define PD_SIZE           0
#define FR_SIZE           1

// Interrupt variables
void riscvv_interrupt_handler(void *intc_inst_ptr);

#ifdef USE_INTERRUPT
u32 enable_intr_system(u32 DeviceID);
void disable_intr_system();
static XScuGic INTCInst;
#endif
volatile int riscvv_intr_done;

volatile u32 main_memory [MEMORY_SIZE]={0};
u8 ifm    [IM_SIZE+2*PD_SIZE][IM_SIZE+2*PD_SIZE][IN_D];
u8 filter [OUT_D][FR_SIZE][FR_SIZE][IN_D];
u8 ofm    [IM_SIZE][IM_SIZE][OUT_D]={0};
u8 ro_ofm;

// For measuring execution time
XTime hw_start, hw_end;
XTime sw_start, sw_end;
volatile float  hw_exe_time, sw_exe_time;



int main()
{
  #ifdef DBG_PRINTS
  // For reading register values
  int read_pc = 0;
  int read_ce = 0;
  int read_int = 0;
  #endif

  // For checking at the end
  unsigned int missmatches = 0;
  // For byte=addressing 'main memory'
  volatile u8  * main_memory_bw = (u8 *) main_memory; // byte-wise access to main memory

  // Initialize platform
  init_platform();

  // Initialize interrupt system
  #ifdef USE_INTERRUPT
  enable_intr_system(INTC_DEVICE_ID);
  #endif

  // Disable the cache
  Xil_DCacheDisable();
  Xil_ICacheDisable();
  // Invalidate range of memory which we are using as main
  Xil_DCacheInvalidateRange((int)main_memory,MEMORY_SIZE);
  Xil_ICacheInvalidateRange((int)main_memory,MEMORY_SIZE);

  // Explicitly reset memory to null commands
  for(int i = 0; i < MEMORY_SIZE; i++)
    main_memory[i] = 0;
  // Reset interrupt flag
  riscvv_intr_done = 0;

  #ifdef DBG_PRINTS
  // Read register values to make sure processor isn't running
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\nCE value: %d\nINT value: %d\n",read_pc,read_ce,read_int);
  #endif

  // Processor needs to know base adress of memory,
  // It will start executing from this locatons onward.
  Xil_Out32(USR_MEM_BASE_ADDRESS, (u32)&main_memory[0]);
  #ifdef DBG_PRINTS
  printf("\nThis is first memory address %p\n",&main_memory[0]);
  #endif

  // Find size of assembly program (machine code), then initialize memory
  size_t assembly_num_el = sizeof(assembly)/sizeof(assembly[0]);
  for (int i=0; i<assembly_num_el; i++){
    if(i<assembly_num_el)
      main_memory[i] = assembly[i];
    else
      main_memory[i] = 0x00000013;
  }

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
  for (int y=0; y<IM_SIZE+2*PD_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE+2*PD_SIZE; x++)
    {
      for (int ich=0; ich<IN_D; ich++)
      {
        if(PD_SIZE!=0 && (x==0 || x==(IM_SIZE+2*PD_SIZE-1) || y==0 || y==(IM_SIZE+2*PD_SIZE-1)))
          ifm[y][x][ich]=0;
        else
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
    for (int fy=0; fy<FR_SIZE; fy++)
    {
      for (int fx=0; fx<FR_SIZE; fx++)
      {
        for (int ich=0; ich<IN_D; ich++)
        {
          filter[och][fy][fx][ich]=((och+ich)-(ich%10));
          main_memory_bw[FILTER_START+(och*FR_SIZE*FR_SIZE*IN_D)+(fy*FR_SIZE*IN_D)+(fx*IN_D)+ich]=filter[och][fy][fx][ich];
        }
      }
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

  // Reference model (Expected results)***************************************************
  // Enable caches for reference model
  Xil_DCacheEnable();
  Xil_ICacheEnable();
  XTime_GetTime(&sw_start);
  for (int y=0; y<IM_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE; x++)
    {
      for (int och=0; och<OUT_D; och++)
      {
        for (int fy=0; fy<FR_SIZE; fy++)
        {
          for (int fx=0; fx<FR_SIZE; fx++)
          {
            ofm[y][x][och] = 0;
            for (int ich=0; ich<IN_D; ich++)
            {
              ofm[y][x][och]+=(ifm[y+fy][x+fx][ich]*filter[och][fy][fx][ich]);
            }
          }
        }
      }
    }
  }
  //sw_end = clock();
  XTime_GetTime(&sw_end);
  // Disable the cache after done with reference
  Xil_DCacheDisable();
  Xil_ICacheDisable();

  // Calculate processor execution time
  sw_exe_time = 1.0 * (sw_end - sw_start) / (COUNTS_PER_SECOND/1000000);
  // **************************************************************************************
  #ifdef DBG_PRINTS
  printf("\n\n* Expected result vector (for:y=0,x=0) DDR[RESULT_START:RESULT_START+OUT_D]: *\n");
  for (int och=0; och<OUT_D; och++)
  {
    if(och%8 == 0)
      printf("\n");
    printf("%d:%02x;  ",(och),(unsigned char)ofm[0][0][och]);
  }
  #endif
  
  #ifdef DBG_PRINTS
  // Read register values
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\nCE value: %d\nINT value: %d\n",read_pc,read_ce,read_int);
  #endif

  //**********************************EXECUTION****************************************
  // Start executing program (by setting ce to 1)
  XTime_GetTime(&hw_start);
  Xil_Out32(USR_RISCV_CE, (u32)1);

  #ifdef DBG_PRINTS
  // Read register values
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\nCE value: %d\nINT value: %d\n",read_pc,read_ce,read_int);
  #endif

  // Wait until finished
  while(!riscvv_intr_done);
  // Calculate vector execution time
  hw_exe_time = 1.0 * (hw_end - hw_start) / (COUNTS_PER_SECOND/1000000);

  // We can stop execution now, no need for processor to run
  Xil_Out32(USR_RISCV_CE, (u32)0);
  //**********************************************************************************

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

  // Read register values
  #ifdef DBG_PRINTS
  read_pc  = Xil_In32(USR_RISCV_PC);
  read_ce  = Xil_In32(USR_RISCV_CE);
  read_int = Xil_In32(USR_RISCV_INTERRUPT);
  printf("\nPC value: %d\nCE value: %d\nINT value: %d\n",read_pc,read_ce,read_int);
  #endif

  printf("\n...Checking results...\n");
  for (int y=0; y<IM_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE; x++)
    {
      for (int och=0; och<OUT_D; och++)
      {
        ro_ofm = ofm[y][x][(och/BATCH_SIZE+1)*BATCH_SIZE-(och%BATCH_SIZE)-1];
        if (ro_ofm!=main_memory_bw[RESULT_START+(y*IM_SIZE*OUT_D+x*OUT_D+och)])
        {
          missmatches++;
          printf("Missmatch! %02x:%02x\n",ro_ofm, main_memory_bw[RESULT_START+(y*IM_SIZE*OUT_D+x*OUT_D+och)]);
        }
      }
    }
  }

  if(missmatches)
    printf("\n***** TEST FAILED! Missmatches:%d **********\n",missmatches);
  else
    printf("\n***** TEST PASSED! **********\n");

  // Calculate execution time
  printf("\nRISCV-V execution time [us] : %.2f, ARM execution time [us]: %.2f\n",hw_exe_time,sw_exe_time);
  printf("Acceleration:%.2f\n",sw_exe_time/hw_exe_time);
  print("done.\n");

  #ifdef USE_INTERRUPT
  printf("\nInterrupt status : %d \n", riscvv_intr_done);
  disable_intr_system();
  #endif 
  cleanup_platform();
  return 0;
}






// INTERRUPT RELATED FUNCTIONS ******************************************************************
#ifdef USE_INTERRUPT
u32 enable_intr_system(u32 DeviceId)
{
  // Setup interrupt handlers and general interrupt controller
  XScuGic_Config *IntcConfig;
  int status;
  IntcConfig = XScuGic_LookupConfig(DeviceId);

  status = XScuGic_CfgInitialize(&INTCInst, IntcConfig, IntcConfig->CpuBaseAddress);
  if(status != XST_SUCCESS)
    return XST_FAILURE;
  XScuGic_SetPriorityTriggerType(&INTCInst, RISCVV_INTR_ID, 0xA8, 3);

  status = XScuGic_Connect(&INTCInst, RISCVV_INTR_ID, (Xil_ExceptionHandler)riscvv_interrupt_handler, (void *)&INTCInst);
  if(status != XST_SUCCESS)
    return XST_FAILURE;
  XScuGic_Enable(&INTCInst, RISCVV_INTR_ID);

  Xil_ExceptionInit();
  Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler)XScuGic_InterruptHandler, &INTCInst);
  Xil_ExceptionEnable();

  return XST_SUCCESS;
}

void disable_intr_system()
{
  // Disable interrupt system
	XScuGic_Disconnect(&INTCInst, RISCVV_INTR_ID);
}

void riscvv_interrupt_handler(void *intc_inst_ptr)
{
  // Interrupt done
	riscvv_intr_done = 1;
  // Reset interrupt flag
  Xil_Out32(USR_RISCV_INTERRUPT, (u32)1);
  // Stop processor
  Xil_Out32(USR_RISCV_CE, (u32)0);
  // Program executed, stop time
  XTime_GetTime(&hw_end);
}
#endif
