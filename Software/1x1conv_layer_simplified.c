#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>
#define IM_D 3
#define IN_D    512
#define OUT_D   16
#define REPEAT_NUM 1
int8_t inter [IM_D][IM_D][OUT_D][IN_D];
int8_t ifm [IM_D][IM_D][IN_D];
int8_t filter [OUT_D][IN_D];
int8_t ofm [IM_D][IM_D][OUT_D]={0};
int8_t lane0;
int8_t lane1;
int8_t lane2;
int8_t lane3;
double time_spent_per_repeat = 0.0;
double total_time=0.0;

int main()
{
  
  // Initialize values
  for (int y=0; y<IM_D; y++)
    for (int x=0; x<IM_D; x++)
      for (int ich=0; ich<IN_D; ich++)
         ifm[y][x][ich]=y*IM_D+x+ich%3;

  for (int och=0; och<OUT_D; och++)
    for (int ich=0; ich<IN_D; ich++)
       filter[och][ich]=((och+ich)-(ich%10));



  for (int repeat=0; repeat < REPEAT_NUM; repeat++)
    {
      clock_t begin = clock();
    // 1x1 convolution
    for (int y=0; y<IM_D; y++)
      {
	for (int x=0; x<IM_D; x++)
	  {
	    for (int och=0; och<OUT_D; och++)
	      {
		/* lane0 = 0; */
		/* lane1 = 0; */
		/* lane2 = 0; */
		/* lane3 = 0; */
		for (int ich=0; ich<IN_D; ich++)
		  {
		    ofm[y][x][och]+=(ifm[y][x][ich]*filter[och][ich]);
		    /* if(ich%4==0) */
		    /*   lane0+=ifm[y][x][ich]*filter[och][ich]; */
		    /* if(ich%4==1) */
		    /*   lane1+=ifm[y][x][ich]*filter[och][ich]; */
		    /* if(ich%4==2) */
		    /*   lane2+=ifm[y][x][ich]*filter[och][ich]; */
		    /* if(ich%4==3) */
		    /*   lane3+=ifm[y][x][ich]*filter[och][ich]; */
	//	     inter[y][x][och][ich]=(ifm[y][x][ich]*filter[och][ich]);
		    printf("inter[%d][%d][%d][%d]=%02x \t\t ifm=%02x \t filter=%02x\n",y,x,och,ich,(unsigned char)inter[y][x][och][ich],(unsigned char)ifm[y][x][ich],(unsigned char)filter[och][ich]);
		    getchar();
		  }
		//printf("subtotals ln0: %02x ln1: %02x ln2: %02x ln3: %02x\n",(unsigned char)lane0,(unsigned char)lane1,(unsigned char)lane2,(unsigned char)lane3);
		//printf("ofm[%d][%d][%d]=%02x ",y,x,och,(unsigned char)ofm[y][x][och]);
		//getchar();
	      }
	  }
      }
    clock_t end = clock();
    time_spent_per_repeat = (double)(end - begin) / CLOCKS_PER_SEC;
    total_time+=time_spent_per_repeat;
    }


  

  printf("\nAverage elapsed time is: The elapsed time is %f seconds\n", total_time/REPEAT_NUM);
  
  printf("Output feature map:\n");
  for (int y=0; y<IM_D; y++)
  {
    for (int x=0; x<IM_D; x++)
    {
      for (int och=15; och>=0; och--)
      {
        printf("ofm[%d][%d][%d]=%02x\n",y,x,och,(unsigned char)ofm[y][x][och]);
        //printf("ofm[%d][%d][%d]=%d\n",y,x,och,ofm[y][x][och]);
      }
      getchar();
    }
  }
  return 0;
}

