#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define DBG_F 1

int8_t inter [56][56][64][256];
int8_t ifm [56][56][256];
int8_t filter [64][256];
int8_t ofm [56][56][64]={0};
int8_t lane0;
int8_t lane1;
int8_t lane2;
int8_t lane3;

int main()
{
  // Initialize values
  for (int y=0; y<56; y++)
    for (int x=0; x<56; x++)
      for (int ich=0; ich<256; ich++)
         ifm[y][x][ich]=y*56+x+ich%3;

  for (int och=0; och<64; och++)
    for (int ich=0; ich<256; ich++)
       filter[och][ich]=((och+ich)-(ich%10));
  
  // 1x1 convolution
  for (int y=0; y<56; y++)
  {
    for (int x=0; x<56; x++)
    {
      for (int och=0; och<64; och++)
      {
        lane0 = 0;
        lane1 = 0;
        lane2 = 0;
        lane3 = 0;
        for (int ich=0; ich<256; ich++)
        {
          ofm[y][x][och]+=(ifm[y][x][ich]*filter[och][ich]);
          if(ich%4==0)
            lane0+=ifm[y][x][ich]*filter[och][ich];
          if(ich%4==1)
            lane1+=ifm[y][x][ich]*filter[och][ich];
          if(ich%4==2)
            lane2+=ifm[y][x][ich]*filter[och][ich];
          if(ich%4==3)
            lane3+=ifm[y][x][ich]*filter[och][ich];
          inter[y][x][och][ich]=(ifm[y][x][ich]*filter[och][ich]);
          printf("inter[%d][%d][%d][%d]=%02x \t\t ifm=%02x \t filter=%02x\n",y,x,och,ich,(unsigned char)inter[y][x][och][ich],(unsigned char)ifm[y][x][ich],(unsigned char)filter[och][ich]);
          //getchar();
        }
        printf("subtotals ln0: %02x ln1: %02x ln2: %02x ln3: %02x\n",(unsigned char)lane0,(unsigned char)lane1,(unsigned char)lane2,(unsigned char)lane3);
        printf("ofm[%d][%d][%d]=%02x ",y,x,och,(unsigned char)ofm[y][x][och]);
        getchar();
      }
    }
  }

  printf("Output feature map:\n");
  for (int y=0; y<56; y++)
  {
    for (int x=0; x<56; x++)
    {
      for (int och=15; och>=0; och--)
      {
        printf("ofm[%d][%d][%d]=%02x ",y,x,och,(unsigned char)ofm[y][x][och]);
        //printf("ofm[%d][%d][%d]=%d\n",y,x,och,ofm[y][x][och]);
        getchar();
      }
    }
  }
  return 0;
}

