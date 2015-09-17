#ifndef DSO_TEST_USER_H_
#define DSO_TEST_USER_H_
#include <stdio.h>
#define PAGE_SIZE (4096) //交换区大小
#define PAGE_OFFSET               0x80000000
//O_DIRECT 声明
#define __USE_GNU 1 
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

typedef unsigned long u32;
typedef unsigned char u8;
typedef unsigned short u16;
#define GPIO_DATA_LEN_MAX 4000
//数据帧定义
typedef struct _gpio_data_frame
{
	struct _gpio_data_frame *next;//下一位置指针
	u32 len;	//数据包长度
	u8 frame_type;	//数据类型
	u8 frame_num;	//数据编号
	u8 data[GPIO_DATA_LEN_MAX];	//实际数据
} gpio_data_frame;
#define TYPE_EMPTY 0
#define TYPE_CH1 1
#define TYPE_CH2 2
#define TYPE_FINISH 255
#define Gpio_Data_Frame_Init(p)	{(p)->next = 0;(p)->len = 0;(p)->frame_type = 0;}
#endif
