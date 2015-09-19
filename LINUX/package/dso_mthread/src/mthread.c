/*thread_example.c :  c multiple thread programming in linux
  *author : lvniqi
  *E-mail : lvniqi@gmail.com
  */
#include "mthread.h"
pthread_mutex_t count_lock;//自旋锁  
pthread_cond_t count_nonzero;//条件锁 
unsigned count = 0;
pthread_mutex_t mut;
int number=0, i;
socksfd socks_temp;
int createUdp(int addr_in,int port){ 
    int sock;
    if ( (sock=socket(AF_INET, SOCK_DGRAM, 0)) <0){
        perror("socket");
        exit(1);
    }

    return sock;
}
void sendUdp(socks* p){
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port =htons(UDP_PORT);
    addr.sin_addr.s_addr = p->address;
#define LEN  500
    char buff[LEN];
    int i;
    for(i=0;i<LEN;i++){
        buff[i] = i;
    }
    int len = sizeof(addr);
    sendto(p->udp, buff, LEN, 0, 
            (struct sockaddr *)&addr, sizeof(addr));
}
void connectTcp(int addr,int port){
    struct sockaddr_in sock_tcp;
    int sock_fd;
    #define MAXLINE 4096
    char buf[MAXLINE];
    char str[MAXLINE];
    #undef MAXLINE
    int result;
    /*防止写入失败*/
    signal(SIGPIPE,SIG_IGN);
    bzero(&sock_tcp, sizeof(sock_tcp));
    
    sock_tcp.sin_family = AF_INET;
    sock_tcp.sin_addr.s_addr = addr;
    sock_tcp.sin_port = htons(port);
    /*得到socket标示符*/
    sock_fd = socket(AF_INET, SOCK_STREAM, 0);
    result=connect(sock_fd, (void *)&sock_tcp, sizeof(sock_tcp));
    if(result <0){
        perror(" call connect");
        exit(1);
    }
    int len;
    /*创建UDPsock*/
    int udp_sock = createUdp(addr,port);
    /* 添加sockfd*/
    Socksfd_Add(&socks_temp,addr,sock_fd,udp_sock);

    while(1) {
        len = recv(sock_fd,buf,200,0);
        if(len<0){
             printf("error comming!\n");
            break;
        }
        if(0 == len){
            printf("the othere side has been closed.\n");
            break;
        }
        else{
            printf("receive from server:%s\n",buf);
        }
    }
    /*删除sock标示符*/
    Socksfd_Delete(&socks_temp,sock_tcp.sin_addr.s_addr);
    close(sock_fd); 
}
void *Tcp_sendThread(void* addr){
    connectTcp(*(int*)addr,TCP_PORT);
}
/*
 * 数据发送
 * */
void *Udp_sendThread() {
   while(true){ 
     Socksfd_RunFuc(&socks_temp,sendUdp);
     usleep(100000); 
   }
    //pthread_mutex_lock(&addr_lock);
    //pthread_mutex_unlock(&addr_lock);
    //等待线程:1使用pthread_cond_wait前要先加锁
    //2pthread_cond_wait内部会解锁，然后等待条件变量被其它线程激活  
    //pthread_cond_wait(&count_nonzero, &count_lock); 
    //printf("get ip address:\t%s\n","0.0.0.0");  
    //pthread_cond_signal(&count_nonzero); 
    //pthread_mutex_unlock(&count_lock);
}  
 /*
  * 条件锁测试
  */
void *Udp_recvThread()  {  
    struct sockaddr_in addr;
    //IPV4
    addr.sin_family = AF_INET;
    //prot
    addr.sin_port = htons(UDP_IN_PORT);
    //任意地址
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    int sock;
    if ( (sock = socket(AF_INET, SOCK_DGRAM,IPPROTO_UDP)) < 0){
        perror("socket");
        exit(1);
    }
    if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0){
        perror("bind");
        exit(1);
    }
    #define BUFFER_LEN 20
    char buff[BUFFER_LEN];
    struct sockaddr_in clientAddr;
    int message_len;
    int len = sizeof(clientAddr);
    while (1){
        message_len = recvfrom(sock, buff,BUFFER_LEN-1, 0
                , (struct sockaddr*)&clientAddr, &len);
        if(message_len >0){
            buff[message_len] = 0;
		    printf("len:%d\n",message_len);
            if(0 == strcmp(inet_ntoa(clientAddr.sin_addr),buff)){
                printf("Ip: %s\n",buff);
                int temp =inet_addr(buff); 
                pthread_create(malloc(sizeof(pthread_t)),NULL,
                       Tcp_sendThread,&temp);
                //Socksfd_Add(&socks_temp,inet_addr(buff),0,0);
                //Socksfd_Print(&socks_temp);
                //Socksfd_Delete(&socks_temp,-1543395136);
                //connectTcp(inet_addr(buff),TCP_PORT);
            }
        }
        else{
            perror("recv");
            break;
        }
    }

    pthread_mutex_lock(&count_lock);         
    //激活线程：1加锁（和等待线程用同一个锁）  
    pthread_cond_signal(&count_nonzero);
    pthread_mutex_unlock(&count_lock); 
}  
/*int main()
{
        //测试 条件锁
        Socksfd_Init(&socks_temp);
        printf("测试条件锁！\n----\n");
        pthread_t tid1, tid2;
        pthread_mutex_init(&count_lock, NULL);
        pthread_cond_init(&count_nonzero, NULL);
        pthread_create(&tid1, NULL, Udp_sendThread, NULL);
        pthread_create(&tid2, NULL, Udp_recvThread, NULL);
        printf("after sleep 1 second begin exit!\n");
        pthread_exit(0);
        return 0;
}*/
