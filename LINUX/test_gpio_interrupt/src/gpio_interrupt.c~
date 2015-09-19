/*
 *gpio  中断程序
 *V1.0
 */
#include "gpio_interrupt.h"
#define DRV_VERSION	"0.1.1"
#define DRV_DESC	"TEST GPIO Interrupt"


#define NETLINK_USER 31
u16 DEV_MAJOR =  253; //定义设备号
const char* DEV_NAME = "DSO_driver";
static test_semaphore dso_sem;//DSO信号量
static struct tasklet_struct dso_tasklet; //DSO数据获取任务
gpio_data_stream data_stream;//数据流
static unsigned long* GPIO_ADDR_BASE = 0;
struct class *device_class = NULL;

struct sock *nl_sk = NULL;
int send_pid = 0;
bool hasSend = false;
static DEFINE_SPINLOCK(w_lock);//锁初始化

#define SHARE_MEM_PAGE_COUNT 64
#define SHARE_MEM_SIZE (PAGE_SIZE*SHARE_MEM_PAGE_COUNT)
frame_sequeue *share_memory=NULL;//test mmap

/********************************************************************
* 名称 : netlink_send_msg
* 功能 : netlink发送数据
* 输入 : 消息 pid
* 输出 : 无
***********************************************************************/
static int netlink_send_msg(const char* msg,int send_pid){
    int res;
    struct sk_buff *skb_out;
    int msg_size = strlen(msg);
    struct nlmsghdr *nlh;
    if(send_pid != 0){
        skb_out = nlmsg_new(msg_size, 0);
        if (!skb_out){
            printk(KERN_ERR "Failed to allocate new skb\n");
            return -1;
        }
        nlh = nlmsg_put(skb_out, 0, 0, NLMSG_DONE, msg_size, 0);
        NETLINK_CB(skb_out).dst_group = 0; /* not in mcast group */
        strncpy(nlmsg_data(nlh), msg, msg_size);
        res = nlmsg_unicast(nl_sk, skb_out, send_pid);
        //nlmsg_free(skb_out);
        return res;
    }
    return -1;
}
/********************************************************************
* 名称 : netlink_send_signal
* 功能 : netlink发送信号
* 输入 : 信号 pid
* 输出 : 无
***********************************************************************/
static int netlink_send_signal(const int signal,int send_pid){
    int res;
    struct sk_buff *skb_out;
    int msg_size = sizeof(int);
    struct nlmsghdr *nlh;
    if(send_pid != 0){
        skb_out = nlmsg_new(msg_size, 0);
        if (!skb_out){
            printk(KERN_ERR "Failed to allocate new skb\n");
            return -1;
        }
        nlh = nlmsg_put(skb_out, 0, 0, NLMSG_DONE, msg_size, 0);
        NETLINK_CB(skb_out).dst_group = 0; /* not in mcast group */
        *((int*)nlmsg_data(nlh)) = signal;
        res = nlmsg_unicast(nl_sk, skb_out, send_pid);
        //nlmsg_free(skb_out);
        return res;
    }
    return -1;
}
/********************************************************************
* 名称 : netlink_recv_msg
* 功能 : netlink接收数据
* 输入 : 无
* 输出 : 无
***********************************************************************/
static void netlink_recv_msg(struct sk_buff *skb){
    int res = 0;
    int code = 0;
    struct nlmsghdr *nlh;
    //printk(KERN_INFO "Entering: %s\n", __FUNCTION__);
    nlh = (struct nlmsghdr *)skb->data;
    code = *(int *)nlmsg_data(nlh);
    //printk(KERN_INFO "Netlink received signal payload:%d\n",code);
    send_pid = nlh->nlmsg_pid; /*pid of sending process */
    //res = netlink_send_signal(123,send_pid);
    if(code == 0xffff){
        //start
        printk("code == 0xffff!\n");
        spin_lock_bh(&w_lock);
        hasSend = false;
        data_stream.full = false;
        if(data_stream.irq){
		    data_stream.irq = false;
		    printk("start tasklet!\n");
		    tasklet_schedule(&dso_tasklet);
		}
        spin_unlock_bh(&w_lock);
    }
    else if(code == 0xfffe){
        //end
        send_pid = 0;
    }
    else if(code <Stream_Len){
        //cut length
        int front_dif = ((code+share_memory->len_max)-share_memory->front)
            %(share_memory->len_max);
        spin_lock_bh(&w_lock);
        hasSend = false;
        share_memory->front = code;
        share_memory->len -= front_dif;
        if(data_stream.full){
            data_stream.full = false;
        }
		if(data_stream.irq){
		    data_stream.irq = false;
		    printk("start tasklet!\n");
		    tasklet_schedule(&dso_tasklet);
		}
        spin_unlock_bh(&w_lock);
    }
}
/********************************************************************
* 名称 : netlink_init
* 功能 : netlink初始化
* 输入 : 无
* 输出 : 无
***********************************************************************/
static int __init netlink_init(void){
    struct netlink_kernel_cfg cfg = { .input = netlink_recv_msg,};
    printk("Entering: %s\n", __FUNCTION__);
    nl_sk = netlink_kernel_create(&init_net, NETLINK_USER,&cfg);
    if (!nl_sk){
        printk(KERN_ALERT "Error creating socket.\n");
        return -10;
    }
    return 0;
}
/********************************************************************
* 名称 : netlink_exit
* 功能 : netlink退出
* 输入 : 无
* 输出 : 无
***********************************************************************/
static void __exit netlink_exit(void){
    printk(KERN_INFO "exiting hello module\n");
    netlink_kernel_release(nl_sk);
}
/********************************************************************
* 名称 : mmap_page_init
* 功能 : mmap_page初始化
* 输入 : 无
* 输出 : 无
***********************************************************************/
static int __init mmap_page_init(void){
    share_memory=(void*)__get_free_pages(GFP_KERNEL,6);//得到一个虚拟地址;
    int lp;
    for(lp=0;lp<SHARE_MEM_PAGE_COUNT;lp++){
        SetPageReserved(virt_to_page((char*)share_memory+PAGE_SIZE*lp));//设置标志 告诉系统 内存已占用
    }
    Sequeue_Set_Null(share_memory,Stream_Len);
    /*for(lp=0;lp<SHARE_MEM_PAGE_COUNT;lp++){
        sprintf((char*)share_memory+PAGE_SIZE*lp,"TEST %d",lp);
    }*/
    return 0;
}
/********************************************************************
* 名称 : mmap_page_exit
* 功能 : mmap退出
* 输入 : 无
* 输出 : 无
***********************************************************************/
static void __exit mmap_page_exit(void){
    if(share_memory!=NULL){
        int lp;
        for(lp=0;lp<SHARE_MEM_PAGE_COUNT;lp++){
            ClearPageReserved(virt_to_page((char*)share_memory+PAGE_SIZE*lp));//设置标志 告诉系统 内存已占用
        }
        free_pages((u32)share_memory,6);
        share_memory = NULL;
    }
}
/********************************************************************
* 名称 : mem_mmap
* 功能 : 实现mmap功能
* 输入 : 无
* 输出 : 无
***********************************************************************/
static int mem_mmap(struct file* file_operations,
        struct vm_area_struct *vma){
    //间接的控制设备
    struct mem_dev *dev = file_operations->private_data;
   	u32 start = (u32)vma->vm_start;
    u32 size = (u32)(vma->vm_end - vma->vm_start);
    
    vma->vm_flags |= (VM_DONTEXPAND | VM_DONTDUMP);
	printk("mmaptest_mmap called\n");
	if(size > SHARE_MEM_SIZE)  //用户要映射的区域太大
		return - EINVAL;
	//vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);   //赋nocache标志
    if(remap_pfn_range(vma,//虚拟内存区域
        vma->vm_start, //虚拟地址的起始地址
        virt_to_phys(share_memory)>>PAGE_SHIFT, //物理存储区的物理页号
     	size,
		PAGE_SHARED
        ))
        return -EAGAIN;

    return 0;
}
/********************************************************************
* 名称 : interrupt_open
* 功能 : 打开 gpio 中断
* 输入 : 无
* 输出 : 无
***********************************************************************/
inline void interrupt_open(void){
	P_DEBUG("GPIO INT OPEN\n");
	//gpio 全部置为输入
	*(GPIO_ADDR_BASE+0) = 0x00000000;//General Purpose I/O Output Disable
	//gpio 23   时钟输出
	*(GPIO_ADDR_BASE+0) |= GPIO_ACK;//General Purpose I/O Output Disable

	*(GPIO_ADDR_BASE+5) |= GPIO_CLK;//General Purpose I/O Interrupt Enable
	*(GPIO_ADDR_BASE+6) |= GPIO_CLK;//General Purpose I/O Interrupt Type
	*(GPIO_ADDR_BASE+7) |= GPIO_CLK;//General Purpose I/O Interrupt Polarity
	*(GPIO_ADDR_BASE+9) |= GPIO_CLK;//General Purpose I/O Interrupt Mask
	*(GPIO_ADDR_BASE+10) = 0x48003;//General Purpose I/O Function
	*(GPIO_ADDR_BASE+12) = 0x70300;//Extended GPIO Function Control
}
/********************************************************************
* 名称 : interrupt_close
* 功能 : 关闭 gpio 中断
* 输入 : 无
* 输出 : 无
***********************************************************************/
inline void interrupt_close(void)
{
	P_DEBUG("GPIO INT CLOSE\n");
	*(GPIO_ADDR_BASE+5) = 0x00000000;
	*(GPIO_ADDR_BASE+6) = 0x00000000;
	*(GPIO_ADDR_BASE+7) = 0x00000000;
	*(GPIO_ADDR_BASE+9) = 0x00000000;
}
/********************************************************************
* 名称 : receive_data
* 功能 : 数据采集函数
* 输入 : gpio_data_frame* data_cache
* 输出 : 无
***********************************************************************/
inline void receive_data(gpio_data_frame* data_cache){
	u32 timer;//超时定时
	u32 data_len = 0;//得到数据计数器
	u32 data_temp = *(GPIO_ADDR_BASE+1);// 第一个 数据
	u32 clk_bit = data_temp&GPIO_CLK;//记录上次时钟
	*(GPIO_ADDR_BASE+2) ^= GPIO_ACK;//翻转ACK
    data_cache->frame_type = Gpio2Data(data_temp);//得到数据ID
    //printk("data_id: %d\n",(data_cache->frame_type));//显示数据ID
	while(1){
		timer = 0;
		while(((data_temp&GPIO_CLK) == clk_bit) && timer <200){//CLK如果翻转
			data_temp = *(GPIO_ADDR_BASE+1);
			timer++;
		}
		clk_bit = data_temp&GPIO_CLK;//记录时钟
		if(timer ==200){
		    *(GPIO_ADDR_BASE+2) ^= GPIO_ACK;//翻转ACK
			break; //超时跳出
		}
		*(GPIO_ADDR_BASE+2) ^= GPIO_ACK;//翻转ACK
		(data_cache->data)[data_len++] = Gpio2Data(data_temp);
		if(data_len>=4000){
		    printk("len: %d too long!\n",data_len);
		    break;
		}
	}
	//printk("data_cache->len:%d\n",data_len);
	data_cache->len = data_len;
}
/********************************************************************
* 名称 : irq_handler
* 功能 : 中断处理函数
* 输入 : 无
* 输出 : 无
***********************************************************************/
irqreturn_t irq_handler(int irqno, void *dev_id) //中断处理函数
{
	if(*(GPIO_ADDR_BASE+8))
	{
		*(GPIO_ADDR_BASE+5) = 0;//   关闭中断
		if((data_stream.full) != true)//如果节点未满
		{
			tasklet_schedule(&dso_tasklet);  //  调度tasklet处理程序
		}
		else
		{
			printk("Data full!\n");
			data_stream.irq = true;////流已满却触发了中断
		}
		return IRQ_HANDLED;
	}
	else
	{
		return IRQ_HANDLED;
	}
}
/********************************************************************
* 名称 : tasklet_handler
* 功能 : 任务处理函数
* 输入 : 无
* 输出 : 无
***********************************************************************/
static void tasklet_handler (unsigned long data){
    gpio_data_frame* data_real;
    int pos;
    bool isFull;
    //P_DEBUG("tasklet_handler is running\n");
	spin_lock_bh(&w_lock);
	data_real = &Sequeue_Get_Next(share_memory);//实际数据
    pos = (share_memory)->rear;//得到位置
    isFull = Sequeue_Full(share_memory);
    spin_unlock_bh(&w_lock);
    //如果数据未满
    if(!isFull){
        receive_data(data_real);    
        spin_lock_bh(&w_lock);
        (share_memory)->rear = (pos +1)%((share_memory)->len_max);
        ((share_memory)->len)++;
        spin_unlock_bh(&w_lock);
    }
    else{
        (data_stream.full) = true;        
    }
    spin_lock_bh(&w_lock);
    if(!hasSend){
        hasSend = true;
        netlink_send_signal(pos,send_pid);
    }
    spin_unlock_bh(&w_lock);
    
    *(GPIO_ADDR_BASE+5) |= GPIO_CLK;//    打开中断*/ 
    
}
/*-------------------------------------------------------------------------*/
/********************************************************************
* 名称 : test_open
* 功能 : 打开设备
* 输入 : 无
* 输出 : 无
***********************************************************************/
int test_open(struct inode *node, struct file *filp){
	P_DEBUG("open device\n");
	return 0;
}

/********************************************************************
* 名称 : test_close
* 功能 : 关闭设备
* 输入 : 无
* 输出 : 无
***********************************************************************/
int test_close(struct inode *node, struct file *filp){
	void* p_temp;
	P_DEBUG("close device\n");
	while((data_stream.start) != 0)//操作已完成
    {
		p_temp = data_stream.start;
		printk("%d\n",(int)((data_stream.start)->frame_type));
		(data_stream.start) = (data_stream.start)->next;//指向下一个节点
		ClearPageReserved(virt_to_page((p_temp)));//清除标志 告诉系统 内存已释放
		free_pages((u32)p_temp, 0);//释放内存
		data_stream.end =0;
		(data_stream.len)--;
	}
	return 0;
}
/*定义文件操作的结构体*/
struct file_operations test_fops = {
.open = test_open,
.release = test_close,
.mmap = mem_mmap,
};

/*装载*/
static int __init gpio_interrupt_init(void){
	int ret;
    int i;
	register_chrdev(DEV_MAJOR, DEV_NAME, &test_fops);//注册设备
	device_class = class_create(THIS_MODULE,DEV_NAME);
    device_create(device_class, NULL, 
        MKDEV(DEV_MAJOR, 0), NULL,DEV_NAME);
    
    netlink_init();
    mmap_page_init();
    
    Gpio_Data_Stream_Init(&data_stream);//初始化数据流
	Test_Semaphore_Init(&dso_sem);// 初始化信号量
	GPIO_ADDR_BASE = ioremap(AR71XX_GPIO_BASE,AR71XX_GPIO_SIZE);
	P_DEBUG("GPIO_ADDR_BASE:%x\n",(unsigned int)GPIO_ADDR_BASE);
	P_DEBUG("gpio_interrupt init !\n");
	/*********************************中断部分******************/
	tasklet_init(&dso_tasklet, tasklet_handler, 0);  //装载任务
	ret = request_irq(ATH79_MISC_IRQ_GPIO, irq_handler,
				IRQF_NO_SUSPEND|
				IRQF_FORCE_RESUME| IRQF_NO_THREAD
				,"gpio_int", NULL);
	if(ret){
		P_DEBUG("request irq failed!\n");
		return -1;
	}
	interrupt_open();
	return 0;
}
module_init(gpio_interrupt_init);
/**卸载*/
static void __exit gpio_interrupt_exit(void){
	gpio_data_frame* p_temp;
	device_destroy(device_class,MKDEV(DEV_MAJOR, 0));
    class_destroy(device_class);
    
	unregister_chrdev(DEV_MAJOR, DEV_NAME);	//卸载设备
    
    
    netlink_exit();
    mmap_page_exit();
    
    while((data_stream.start) != 0)//操作已完成
	{
        void* temp;
		p_temp = data_stream.start;
		printk("%d\n",(int)((data_stream.start)->frame_type));
		(data_stream.start) = (data_stream.start)->next;//指向下一个节点
        //temp = p_temp->real_adr;
        temp = p_temp;
		ClearPageReserved(virt_to_page(temp));//清除标志 告诉系统 内存已释放
		free_pages((u32)temp, 0);//释放内存
		data_stream.end =0;
		(data_stream.len)--;
	}
	/*********************************中断部分******************/
	interrupt_close();
	free_irq(ATH79_MISC_IRQ_GPIO, NULL);
	tasklet_kill(&dso_tasklet);  //  销毁tasklet
	P_DEBUG("gpio_interrupt exit !\n");
}
module_exit(gpio_interrupt_exit);

MODULE_DESCRIPTION(DRV_DESC);
MODULE_VERSION(DRV_VERSION);
MODULE_AUTHOR("Lvniqi <lvniqi@gmail.com>");
MODULE_LICENSE("GPL v2");

