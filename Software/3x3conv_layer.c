#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define IM_SIZE 56
#define PD_SIZE 1
#define IN_D    64
#define OUT_D   64
#define FR_SIZE 3
#define PRINT_INTERMEDIATE

int8_t inter [IM_SIZE][IM_SIZE][OUT_D][FR_SIZE][FR_SIZE][IN_D];
int8_t ifm [IM_SIZE+PD_SIZE][IM_SIZE+PD_SIZE][IN_D];
int8_t filter [OUT_D][FR_SIZE][FR_SIZE][IN_D];
int8_t ofm [IM_SIZE][IM_SIZE][OUT_D]={0};

int main()
{
  // Initialize values
  for (int y=0; y<IM_SIZE+2*PD_SIZE; y++)
  {
    for (int x=0; x<IM_SIZE+2*PD_SIZE; x++)
    {
      for (int ich=0; ich<IN_D; ich++)
      {
         if(x==0 || x==(IM_SIZE+2*PD_SIZE-1) || y==0 || y==(IM_SIZE+2*PD_SIZE-1))
           ifm[y][x][ich]=0;
         else
           ifm[y][x][ich]=y*IM_SIZE+x+ich%3;
      }
    }
  }

  for (int och=0; och<OUT_D; och++)
    for (int fy=0; fy<FR_SIZE; fy++)
      for (int fx=0; fx<FR_SIZE; fx++)
        for (int ich=0; ich<IN_D; ich++)
          filter[och][fy][fx][ich]=((och+ich)-(ich%10));
  
  // 1x1 convolution
  for (int och=0; och<OUT_D; och++)
  {
    for (int y=0; y<IM_SIZE; y++)
    {
      for (int x=0; x<IM_SIZE; x++)
      {
        for (int fy=0; fy<FR_SIZE; fy++)
        {
          for (int fx=0; fx<FR_SIZE; fx++)
          {
            for (int ich=0; ich<IN_D; ich++)
            {
              ofm[y][x][och]+=(ifm[y+fy][x+fx][ich]*filter[och][fy][fx][ich]);
              #ifdef PRINT_INTERMEDIATE
              inter[y][x][och][fy][fx][ich]=(ifm[y+fy][x+fx][ich]*filter[och][fy][fx][ich]);
            	printf("inter[%d][%d][%d][%d][%d][%d]=%02x \t\t ifm[memloc:%d]=%02x \t filter=%02x\n",
                y,x,och,fy,fx,ich, 
                (unsigned char)inter[y][x][och][fy][fx][ich],
                (1024+(y+fy)*58*64+(x+fx)*64+ich),
                (unsigned char)ifm[y+fy][x+fx][ich],
                (unsigned char)filter[och][fy][fx][ich]);

              #endif
            }
            #ifdef PRINT_INTERMEDIATE
            printf("ofm[macd]=%02x\n",ofm[y][x][och]);
            getchar();
            #endif
          }
        }
        //printf("subtotals ln0: %02x ln1: %02x ln2: %02x ln3: %02x\n",(unsigned char)lane0,(unsigned char)lane1,(unsigned char)lane2,(unsigned char)lane3);
        printf("ofm[%d][%d][%d]=%02x ",y,x,och,(unsigned char)ofm[y][x][och]);
        getchar();
      }
    }
  }

            //printf("inter[%d][%d][%d][%d]=%02x \t\t ifm=%02x \t filter=%02x\n",y,x,och,ich,(unsigned char)inter[y][x][och][ich],(unsigned char)ifm[y][x][ich],(unsigned char)filter[och][ich]);
            //getchar();
  printf("Output feature map:\n");
  for (int och=0; och<OUT_D; och++)
  {
    for (int y=0; y<IM_SIZE; y++)
    {
      for (int x=0; x<IM_SIZE; x++)
      {
        printf("ofm[%d][%d][%d]=%02x ",y,x,och,(unsigned char)ofm[y][x][och]);
        //printf("ofm[%d][%d][%d]=%d\n",y,x,och,ofm[y][x][och]);
        getchar();
      }
    }
  }
  return 0;
}

