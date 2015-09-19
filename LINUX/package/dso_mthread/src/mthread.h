#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <signal.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>

#include <unistd.h>

#include "Linklist.h"

#define MAX 7
#define UDP_IN_PORT 55554
#define UDP_PORT 55555
#define TCP_PORT 55556

extern pthread_mutex_t count_lock;//自旋锁  
extern pthread_cond_t count_nonzero;//条件锁 
extern socksfd socks_temp;//sock
extern void *Udp_recvThread();//udp接收
extern void *Udp_sendThread();//udp发送
