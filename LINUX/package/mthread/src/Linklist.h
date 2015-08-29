/*
* CCD.c
*
*  Created on: 2013-12-2
*      Author: lvniqi
*      Email: lvniqi@gmail.com
*/
/*
	���棡ʹ��ʱ����ǳ�С�ģ�
        ʹ��ǰ�����ʼ����
        ��Ҫ�������� ��֤���ݲ��⵽�޸�!
	ͬʱ ���ֹ��������� ��
	
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
/*************������**************************/
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
    pthread_rwlock_t lock;//��ַ��
}socksfd;
/**************������***************************/
/*�ڵ�ͷ��ʼ��*/
#define Socksfd_Init(sl)    \
{   \
    (sl)->begin = 0;\
    pthread_rwlock_init(&((sl)->lock), NULL);\
}
/*�õ����г���*/
extern int socksfd_GetLen(socksfd* sl);
/*��ӽڵ�*/
extern int Socksfd_Add(socksfd* sl,int ip,int tcp,int udp);
/*ɾ���ڵ�*/
extern bool Socksfd_Delete(socksfd* sl,int ip);
/*��ʾ*/
extern void Socksfd_Print(socksfd *sl);
/*�����ص�*/
extern void Socksfd_RunFuc(socksfd *sl,void(*func)(socks*));
#endif
