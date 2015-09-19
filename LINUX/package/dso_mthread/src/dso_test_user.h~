#ifndef DSO_TEST_USER_H_
#define DSO_TEST_USER_H_
#define PAGE_SIZE (4096) //交换区大小
#define PAGE_OFFSET               0x80000000
//O_DIRECT 声明
#define __USE_GNU 1 
#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include <sys/socket.h>
#include <linux/netlink.h>


#include "Sequeue.h"
#include "netlink.h"
#define DEV_NAME "/dev/DSO_driver"
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

#define Stream_Len 64
typedef struct _frame_sequeue
{
	gpio_data_frame dataspace[Stream_Len];
	u16 front;
	u16 rear;
	u16 len;
	u16 len_max;
}frame_sequeue;

#define SHARE_MEM_PAGE_COUNT 64
#define SHARE_MEM_SIZE (4096*SHARE_MEM_PAGE_COUNT)


extern frame_sequeue* mmap_init();
extern void mmap_exit(frame_sequeue* ptrdata);
#endif
