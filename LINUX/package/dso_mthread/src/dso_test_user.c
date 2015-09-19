#include <stdio.h>
#include "dso_test_user.h"
#include "mthread.h"

//unsigned count = 0;
//pthread_mutex_t mut;
//int number=0, i;

void test_netlink(frame_sequeue* share_memory){
    netlink_init();
    
    printf("rear:%d\n",share_memory->rear);
    printf("front:%d\n",share_memory->front);
    printf("len:%d\n",share_memory->len);
    printf("len_max:%d\n",share_memory->len_max);
    //start
    int last_front = share_memory->front;
    int count = 0;
    netlink_send_signal(0xffff);
    //running
    while(1){
        int rear = netlink_recv_signal();
        int len = (rear+Stream_Len-last_front)%(Stream_Len);
        printf("\n---%d---\n",count++);
        while(len--){
            gpio_data_frame* p = &((share_memory->dataspace)[last_front]);
            last_front = (last_front+1)%(Stream_Len);
            printf("front:%d\n",last_front);
            printf("CODE:%d\n",p->frame_type);
            printf("LEN:%d\n",p->len);
        }
        netlink_send_signal(last_front);
    }
    netlink_exit();
}
gpio_data_frame* data_frame_t = NULL;
frame_sequeue* share_memory = NULL;
void sendUdp_t(socks* p){
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port =htons(UDP_PORT);
    addr.sin_addr.s_addr = p->address;
    data_frame_t->data[0] = 0x00;
    //printf("DATA_LEN:%d\n",data_frame_t->len);
    sendto(p->udp, data_frame_t->data, 
            data_frame_t->len, 0, 
            (struct sockaddr *)&addr, sizeof(addr));
}
/*
 * 数据发送
 * */
void *Udp_sendThread_t() {
  //start
  int last_front = share_memory->front;
  int count = 0;
  netlink_send_signal(0xffff);
  while(true){
    int rear = netlink_recv_signal();
    int len = (rear+Stream_Len-last_front)%(Stream_Len);
    while(len--){
      data_frame_t = &((share_memory->dataspace)[last_front]);
      last_front = (last_front+1)%(Stream_Len);
      Socksfd_RunFuc(&socks_temp,sendUdp_t);
    }
    netlink_send_signal(last_front);
  }
}
int main(void){
  share_memory = mmap_init();
  //test_netlink(share_memory);
  Socksfd_Init(&socks_temp);  
  pthread_t tid1, tid2;
  //各种锁
  pthread_mutex_init(&count_lock, NULL);
  pthread_cond_init(&count_nonzero, NULL);
  
  //netlink初始化
  netlink_init();
  
  pthread_create(&tid1, NULL, Udp_sendThread_t, NULL);
  pthread_create(&tid2, NULL, Udp_recvThread, NULL);
  printf("waitting to exit!\n");
  pthread_exit(0);
  //netlink退出
  netlink_exit();
  
  mmap_exit(share_memory);
}
