#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>

#include <linux/fs.h>
#include <linux/types.h>
#include <linux/errno.h>
#include <linux/fcntl.h>

#include <linux/vmalloc.h>
#include <linux/uaccess.h>
#include <linux/io.h>

#include <asm/page.h>
#include <linux/mm.h>

#include <net/sock.h>
#include <linux/netlink.h>
#include <linux/skbuff.h>

#include <linux/device.h>

#define NETLINK_USER 31

#define MMAPNOPAGE_DEV_NAME "mmapnopage"
#define MMAPNOPAGE_DEV_MAJOR 240

#define SHARE_MEM_PAGE_COUNT 32
#define SHARE_MEM_SIZE (PAGE_SIZE*SHARE_MEM_PAGE_COUNT)
char *share_memory=NULL;
struct class *myclass = NULL;


struct sock *nl_sk = NULL;
int send_pid = 0;
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


struct file_operations mmapnopage_fops={
    .owner=THIS_MODULE,
    .mmap=mem_mmap,
};
int mmapnopage_init(void){
    int lp;
    int result;
    printk("Entering: %s\n", __FUNCTION__);
    result=register_chrdev(MMAPNOPAGE_DEV_MAJOR,
                MMAPNOPAGE_DEV_NAME,
                &mmapnopage_fops);
    if(result<0){
        return result;
    }
    myclass = class_create(THIS_MODULE,MMAPNOPAGE_DEV_NAME);
    device_create(myclass, NULL, 
        MKDEV(MMAPNOPAGE_DEV_MAJOR, 0), NULL,MMAPNOPAGE_DEV_NAME);
    
    share_memory=(void*)__get_free_pages(GFP_KERNEL,5);//得到一个虚拟地址;
    for(lp=0;lp<SHARE_MEM_PAGE_COUNT;lp++){
        SetPageReserved(virt_to_page(share_memory+PAGE_SIZE*lp));//设置标志 告诉系统 内存已占用
    }
    for(lp=0;lp<SHARE_MEM_PAGE_COUNT;lp++){
        sprintf(share_memory+PAGE_SIZE*lp,"TEST %d",lp);
    }
    return 0;
}
void mmapnopage_exit(void){
    printk("Exiting: %s\n", __FUNCTION__);
    if(share_memory!=NULL){
        int lp;
        for(lp=0;lp<SHARE_MEM_PAGE_COUNT;lp++){
            ClearPageReserved(virt_to_page(share_memory+PAGE_SIZE*lp));//设置标志 告诉系统 内存已占用
        }
        free_pages((u32)share_memory,5);
        share_memory = NULL;
    }
    device_destroy(myclass,MKDEV(MMAPNOPAGE_DEV_MAJOR, 0));
    class_destroy(myclass);
    unregister_chrdev(MMAPNOPAGE_DEV_MAJOR,
            MMAPNOPAGE_DEV_NAME);
}

static int netlink_send_msg(char* msg){
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
static void netlink_recv_msg(struct sk_buff *skb){
    int res;
    struct nlmsghdr *nlh;
    printk(KERN_INFO "Entering: %s\n", __FUNCTION__);
    nlh = (struct nlmsghdr *)skb->data;
    printk(KERN_INFO "Netlink received msg payload:%s\n", (char *)nlmsg_data(nlh));
    send_pid = nlh->nlmsg_pid; /*pid of sending process */
    res = netlink_send_msg("Hello from kernel");
    if (res < 0){
            printk("Error Code %d\n",res);
            printk(KERN_INFO "Error while sending bak to user\n");
    }
}

static int __init hello_init(void){
    mmapnopage_init();
    struct netlink_kernel_cfg cfg = { .input = netlink_recv_msg,};
    printk("Entering: %s\n", __FUNCTION__);
    nl_sk = netlink_kernel_create(&init_net, NETLINK_USER,&cfg);
    if (!nl_sk){
        printk(KERN_ALERT "Error creating socket.\n");
        return -10;
    }
    return 0;
}

static void __exit hello_exit(void){
    mmapnopage_exit();
    printk(KERN_INFO "exiting hello module\n");
    netlink_kernel_release(nl_sk);
}

module_init(hello_init); 
module_exit(hello_exit);

MODULE_LICENSE("GPL");
