#include <sys/socket.h>
#include <linux/netlink.h>

#define NETLINK_USER 31

#define MAX_PAYLOAD 100 /* maximum payload size*/
struct sockaddr_nl src_addr, dest_addr;
struct nlmsghdr *nlh_send = NULL;
struct nlmsghdr *nlh_recv = NULL;
struct iovec iov_send;
struct iovec iov_recv;
int sock_fd;
struct msghdr msg_send;
struct msghdr msg_recv;


#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#define DEVICE_FILENAME "/dev/mmapnopage"
#define SHARE_MEM_PAGE_COUNT 15
#define SHARE_MEM_SIZE (4096*SHARE_MEM_PAGE_COUNT)

void test_mmap(int count){
    int dev;
    int loop;
    char *ptrdata;
    
    dev=open(DEVICE_FILENAME,O_RDWR|O_NDELAY);
    
    if(dev>=0){
        printf("open file success!\n");
        ptrdata=(char*)mmap(0,
                count*4096,
                PROT_READ|PROT_WRITE,
                MAP_SHARED,
                dev,
                0);
        for(loop=0;loop<count;loop++){
            printf("[%-10s%x]\n",ptrdata+4096*loop,ptrdata+4096*loop);
        }
        munmap(ptrdata,count*4096);
        close(dev);
    }
}

void main(int argc, char *argv[])
{
    test_mmap(strtol(argv[1],NULL,NULL));
    sock_fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_USER);
    if (sock_fd < 0)
        return -1;
    memset(&src_addr, 0, sizeof(src_addr));
    src_addr.nl_family = AF_NETLINK;
    src_addr.nl_pid = getpid(); /* self pid */

    bind(sock_fd, (struct sockaddr *)&src_addr, sizeof(src_addr));
    memset(&dest_addr, 0, sizeof(dest_addr));
    memset(&dest_addr, 0, sizeof(dest_addr));
    dest_addr.nl_family = AF_NETLINK;
    dest_addr.nl_pid = 0; /* For Linux Kernel */
    dest_addr.nl_groups = 0; /* unicast */
    
    //send
    nlh_send = (struct nlmsghdr *)malloc(NLMSG_SPACE(MAX_PAYLOAD));
    memset(nlh_send, 0, NLMSG_SPACE(MAX_PAYLOAD));
    nlh_send->nlmsg_len = NLMSG_SPACE(MAX_PAYLOAD);
    nlh_send->nlmsg_pid = getpid();
    nlh_send->nlmsg_flags = 0;
    strcpy(NLMSG_DATA(nlh_send), "Hello");
    
    iov_send.iov_base = (void *)nlh_send;
    iov_send.iov_len = nlh_send->nlmsg_len;
    msg_send.msg_name = (void *)&dest_addr;
    msg_send.msg_namelen = sizeof(dest_addr);
    msg_send.msg_iov = &iov_send;
    msg_send.msg_iovlen = 1;
    
    //recv
    nlh_recv = (struct nlmsghdr *)malloc(NLMSG_SPACE(MAX_PAYLOAD));
    memset(nlh_recv, 0, NLMSG_SPACE(MAX_PAYLOAD));
    nlh_recv->nlmsg_len = NLMSG_SPACE(MAX_PAYLOAD);
    nlh_recv->nlmsg_pid = getpid();
    nlh_recv->nlmsg_flags = 0;
    
    iov_recv.iov_base = (void *)nlh_recv;
    iov_recv.iov_len = nlh_recv->nlmsg_len;
    msg_recv.msg_name = (void *)&dest_addr;
    msg_recv.msg_namelen = sizeof(dest_addr);
    msg_recv.msg_iov = &iov_recv;
    msg_recv.msg_iovlen = 1;
    
    int i;
    for(i=0;i<10;i++){
        printf("Sending message%d to kernel\n",i);
        sendmsg(sock_fd, &msg_send, 0);
        printf("Waiting for message%d from kernel\n",i);
        
        /* Read message from kernel */
        recvmsg(sock_fd, &msg_recv, 0);
        printf("Received message%d payload: %s\n", i,NLMSG_DATA(nlh_recv));
    }
    close(sock_fd);
}
