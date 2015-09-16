/*
 *gpio  中断程序
 *V1.0
 */
#include "gpio_interrupt.h"
#define DRV_VERSION	"0.1.1"
#define DRV_DESC	"TEST GPIO Interrupt"


u16 major =  253; //定义设备号
static test_semaphore dso_sem;//DSO信号量
static struct tasklet_struct dso_tasklet; //DSO数据获取任务
gpio_data_stream data_stream;//数据流
static unsigned long* GPIO_ADDR_BASE = 0;
char* temp_p_0 = 0;//test mmap and ioremap
char* temp_p_1 = 0;//test mmap and ioremap
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
    printk("data_id: %d\n",(data_cache->frame_type));//显示数据ID
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
		if(data_len>3200){
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
    P_DEBUG("tasklet_handler is running\n");
	gpio_data_frame* data_real;//实际数据
    void* temp;
    temp = (void*)__get_free_pages(GFP_KERNEL,0);//得到一个虚拟地址
  	SetPageReserved(virt_to_page(temp));//设置标志 告诉系统 内存已占用	
    data_real = temp;
	Gpio_Data_Frame_Init(data_real);
	receive_data(data_real);
	P_DEBUG("data len: %d\n",data_real->len);
	if(!(data_stream.end))// 尾节点为空 添加至尾部
	{
		data_stream.end = data_real;
		(data_stream.len) = 1;
	}
	else if(data_stream.len <Stream_Len)//节点未满 继续添加
	{
		(data_stream.end)->next = data_real;
		data_stream.end = data_real;
		(data_stream.len)++;
		//printk("data_stream.len:%d\n",data_stream.len);
	}
	else//节点满 停止添加 标记符号
	{
		(data_stream.full) = true;
	}
	
	if(!(data_stream.start))//头节点为空 令头节点等于尾节点
	{
		data_stream.start = data_stream.end;
		data_stream.now = data_stream.start;
	}
	else
	{
		void* p_temp;
		while(
				(TYPE_FINISH == (data_stream.start)->frame_type)
				||(
						((data_stream.start)->next)!= 0 
						&&
						(TYPE_FINISH ==((data_stream.start)->next)->frame_type)
					)
				 ||(
						((data_stream.start)->next)!= 0 
						&&
						((data_stream.start)->next->next)!= 0 
						&&
						(TYPE_FINISH ==((data_stream.start)->next->next)->frame_type)
					)
				)//操作已完成
		{
			//p_temp = (data_stream.start)->real_adr;
			p_temp = (data_stream.start);
			(data_stream.start) = (data_stream.start)->next;//指向下一个节点
			ClearPageReserved(virt_to_page((p_temp)));//清除标志 告诉系统 内存已释放
			free_pages((u32)p_temp, 0);//释放内存
			if((data_stream.start) == 0)//释放完 结束
			{
				data_stream.end =0;
				break;
			}
		}
	}
	if(!(data_stream.now))//现有节点为空 令现有节点等于尾节点
	{
		data_stream.now = data_stream.end;
	}
	if(dso_sem.empty == 1)//如果读空
	{
		dso_sem.empty = 0;//设置为未读空
		wake_up_interruptible(&(dso_sem.outq));//唤醒队列
	}
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
* 名称 : test_read
* 功能 : 读取设备
* 输入 : 无
* 输出 : 返回实际读取的字节数或错误号
***********************************************************************/
ssize_t test_read(struct file *filp, char __user *buf, size_t count, loff_t *offset)
{
	int ret;//返回值
	int i;
	char temp_addr[20] = {0};//暂存地址
	if (wait_event_interruptible(dso_sem.outq, dso_sem.empty == 0))//如果没空 不阻塞
	{
		return - ERESTARTSYS;  //获取失败 等着
	}
	//down_interruptible 函数返回非零值，表示操作被中断，调用者拥有信号量失败  
	if (down_interruptible(&(dso_sem.sem)))//获取信号量
	{
		return - ERESTARTSYS; //获取失败 等着
	}
	for(i=0;i<5 && (data_stream.now) != 0;i++)
	{
		((gpio_data_frame **)(temp_addr))[i] = (data_stream.now);
		data_stream.now=(data_stream.now)->next;
		(data_stream.len)--;
	}
	if( i == 0)//没读到
	{
		dso_sem.empty = 1;//读空
	}
	if(data_stream.irq)
	{
		tasklet_schedule(&dso_tasklet);//开启任务
		data_stream.full = false;
		data_stream.irq = false;
	}
	if (copy_to_user(buf, temp_addr, 20))//从内核复制内存地址 到用户态
	{
		ret = - EFAULT;
	}
	else
	{
		ret = count;
	}
	up(&(dso_sem.sem));//释放信号量
	return ret; //返回实际读取的字节数或错误号
}
/********************************************************************
* 名称 : test_write
* 功能 : 写入设备
* 输入 : 无
* 输出 : 返回实际读取的字节数或错误号
***********************************************************************/
ssize_t test_write(struct file *filp, const char __user *buf, size_t count, loff_t *offset)
{
	char kbuf[20];
	int ret;
	u32 x;
	/*if(copy_from_user(kbuf, buf, count))
	{
		ret = - EFAULT;
	}
	else
	{
		ret = count;
		P_DEBUG("kbuf is [%s]\n", kbuf);
	}

	x = *(GPIO_ADDR_BASE+1);
	P_DEBUG("GPIO is %d \n", x);*/
	return ret; //返回实际写入的字节数或错误号
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
	P_DEBUG("mmaptest_mmap called\n");
	if(size > 4096)  //用户要映射的区域太大
		return - EINVAL;

	//vma->vm_page_prot = pgprot_noncached(vma->vm_page_prot);   //赋nocache标志
    if(remap_pfn_range(vma,//虚拟内存区域
        vma->vm_start, //虚拟地址的起始地址
        virt_to_phys(temp_p_1)>>PAGE_SHIFT, //物理存储区的物理页号
     	PAGE_SIZE,
		PAGE_SHARED
        ))
        return -EAGAIN;

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
.write = test_write,
.read = test_read,
.mmap = mem_mmap,
};

/*装载*/
static int __init gpio_interrupt_init(void){
	int ret;
    int i;
	register_chrdev(major, "DSO_driver", &test_fops);//注册设备
	temp_p_0 = (char*)__get_free_pages(GFP_KERNEL, 0); //test mmap
    P_DEBUG("virtual address: %x\n",(unsigned int)temp_p_0);
  	SetPageReserved(virt_to_page((void *)temp_p_0));//设置标志 告诉系统 内存已占用
	P_DEBUG("real address: %x\n",(unsigned int)virt_to_phys(temp_p_0));
    temp_p_1 = (char*)ioremap(virt_to_phys(temp_p_0),4096);
    for(i=0;i<4096;i++){
        temp_p_1[i] = i;
    }
    P_DEBUG("real virtual address: %x\n",(unsigned int)temp_p_1);
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
	unregister_chrdev(major, "DSO_driver");	//卸载设备
	ClearPageReserved(virt_to_page(temp_p_0));
    free_pages((u32)temp_p_0,0);
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