#include "netlink.h"
struct sockaddr_nl src_addr, dest_addr;
struct nlmsghdr *nlh_send = NULL;
struct nlmsghdr *nlh_recv = NULL;
struct iovec iov_send;
struct iovec iov_recv;
int sock_fd;
struct msghdr msg_send;
struct msghdr msg_recv;
frame_sequeue* share_memory;

void netlink_send(const char* data){
    struct nlmsghdr *nlh_send = (struct nlmsghdr *)(&msg_send)->msg_iov->iov_base;
    strcpy(NLMSG_DATA(nlh_send),data);
    sendmsg(sock_fd, &msg_send, 0);
}
void netlink_send_signal(const int signal){
    struct nlmsghdr *nlh_send = (struct nlmsghdr *)(&msg_send)->msg_iov->iov_base;
    *(int*)NLMSG_DATA(nlh_send) = signal;
    sendmsg(sock_fd, &msg_send, 0);
}
char* netlink_recv(){
    recvmsg(sock_fd, &msg_recv, 0);
    return (char*)NLMSG_DATA(nlh_recv);
}
int netlink_recv_signal(){
    recvmsg(sock_fd, &msg_recv, 0);
    return *(int*)NLMSG_DATA(nlh_recv);
}
void netlink_init(void){
    sock_fd = socket(PF_NETLINK, SOCK_RAW, NETLINK_USER);
    if (sock_fd < 0){
        return -1;
    }
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
}
void netlink_exit(void){
    close(sock_fd);
}
