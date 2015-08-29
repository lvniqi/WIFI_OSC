/*
* CCD.c
*
*  Created on: 2013-12-2
*      Author: lvniqi
*      Email: lvniqi@gmail.com
*/
/*
	警告！使用时必须非常小心！
        使用前必须初始化！
        勿要滥用数据 保证数据不遭到修改!
	同时 请防止缓冲区溢出 ！
	
 */
#ifndef LINKLIST_H_
#define LINKLIST_H_
#include <pthread.h>
#include <stdbool.h>
#include <string.h>
#include<stdlib.h>
#include<stdio.h>
#define DEBUG
typedef unsigned int u16;
/*************链表定义**************************/
typedef struct _socks{
    int udp;
    int tcp;
    int address;
}socks;
typedef struct _socksfd_node socksfd_node;
struct _socksfd_node
{
	socks dataspace;
    socksfd_node *next;
};
typedef struct{
    socksfd_node* begin;
    pthread_rwlock_t lock;//地址锁
}socksfd;
/**************链表函数***************************/
/*节点头初始化*/
#define Socksfd_Init(sl)    \
{   \
    (sl)->begin = 0;\
    pthread_rwlock_init(&((sl)->lock), NULL);\
}
/*得到队列长度*/
extern int socksfd_GetLen(socksfd* sl);
/*添加节点*/
extern int Socksfd_Add(socksfd* sl,int ip,int tcp,int udp);
/*删除节点*/
extern bool Socksfd_Delete(socksfd* sl,int ip);
/*显示*/
extern void Socksfd_Print(socksfd *sl);
/*遍历回调*/
extern void Socksfd_RunFuc(socksfd *sl,void(*func)(socks*));
#endif
