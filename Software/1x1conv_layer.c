#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int8_t ifm [56][56][256];
int8_t filter [64][256];
int8_t ofm [56][56][64]= {0};

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
        for (int ich=0; ich<256; ich++)
        {
          ofm[y][x][och] +=(ifm[y][x][ich]*filter[och][ich]);
        }
      }
    }
  }

  printf("Output feature map:\n");
  for (int y=0; y<56; y++)
  {
    for (int x=0; x<56; x++)
    {
      for (int och=0; och<64; och++)
      {
        printf("ofm[%d][%d][%d]=%d\n",y,x,och,ofm[y][x][och]);
      }
    }
  }
  return 0;
}

