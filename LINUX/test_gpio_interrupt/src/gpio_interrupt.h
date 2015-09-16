#ifndef GPIO_INTERRUPT_H_
#define GPIO_INTERRUPT_H_
#include <linux/types.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/slab.h>   /* kmalloc() */
#include <linux/fs.h>
#include <asm/uaccess.h>//用于支持地址检测
#include <linux/mm.h>
#include <linux/interrupt.h>//中断
#include <linux/irq.h>//中断寄存器
#include <asm/mach-ath79/ar71xx_regs.h>
#include <linux/delay.h>
#include <linux/semaphore.h>  //信号量  
#include <linux/sched.h>   //队列
#include <linux/wait.h>  
#include <asm/io.h>

#include <linux/list.h>

#include "Sequeue.h"
//测试模式
#define DEBUG_SWITCH 1

#if DEBUG_SWITCH
 #define P_DEBUG(fmt, args...) printk("<1>" "<kernel>[%s]"fmt, __FUNCTION__, ##args)
#else
 #define P_DEBUG(fmt, args...) printk("<7>" "<kernel>[%s]"fmt, __FUNCTION__, ##args)
#endif
// GPIO 宏定义
#define GPIO_BASE_IN (AR71XX_GPIO_BASE+AR71XX_GPIO_REG_IN)
#define GPIO_CLK BIT(22)
#define GPIO_ACK BIT(23)
#define Gpio2Data(data_temp) ((data_temp&0x01)<<7) + (u8)((data_temp)>>11)
#define GPIO_DATA_LEN_MAX 4000
//数据帧定义
typedef struct _gpio_data_frame
{
	struct _gpio_data_frame *next;//下一位置指针
	u32 len;	//数据包长度
	u8 frame_type;	//数据类型
	u8 frame_num;	//数据编号
	u8 data[GPIO_DATA_LEN_MAX];	//实际数据
    //void * real_adr;//real address of this data
} gpio_data_frame;
typedef struct _gpio_data_sequeue
{
	float* dataspace;
	u16 front;
	u16 rear;
	u16 len;
	u16 len_max;
}gpio_data_sequeue;
#define TYPE_EMPTY 0
#define TYPE_CH1 1
#define TYPE_CH2 2
#define TYPE_FINISH 255
#define Gpio_Data_Frame_Init(p)	{(p)->next = 0;(p)->len = 0;\
    (p)->frame_type = TYPE_EMPTY;}

//头尾指针定义
typedef struct _gpio_data_stream
{
	gpio_data_frame *start;//开始帧
	gpio_data_frame *now;//发送帧
	gpio_data_frame *end;//结束帧
	u32 len;//长度
	bool full;//满标志
	bool irq;//流已满却触发了中断
}gpio_data_stream;
#define Stream_Len 20
#define Gpio_Data_Stream_Init(p) {(p)->start = NULL;(p)->now = NULL;(p)->end = NULL;(p)->len = 0;(p)->irq = false;(p)->full = false;}


//等待队列
typedef struct _test_semaphore
{
	struct semaphore sem; //定义信号量  
	wait_queue_head_t outq;  //定义一个等待队列头   
	int empty; //数据空标志  
} test_semaphore;

#define Test_Semaphore_Init(p) { sema_init(&((p)->sem),1);init_waitqueue_head(&((p)->outq));(p)->empty = 0;}
#endif
