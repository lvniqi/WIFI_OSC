#include "Linklist.h"
/*单个节点初始化*/
#define socksfd_node_Init(sl)  \
{   \
    bzero(sl,sizeof(socksfd_node));\
}
int Socksfd_GetLen(socksfd* sl){
    int len = 0;
    socksfd_node* p = sl->begin;
    pthread_rwlock_rdlock(&(sl->lock));
    while(p!= NULL){
        p = p->next;
        len++;
    }
    pthread_rwlock_unlock(&(sl->lock));
    return len;
}
int Socksfd_Add(socksfd*sl,int ip,int tcp,int udp){
    pthread_rwlock_wrlock(&(sl->lock));
       if(NULL == sl->begin){
        socksfd_node* node = 
            (socksfd_node*)malloc(sizeof(socksfd_node));
        socksfd_node_Init(node);
        socks* sock = &(node->dataspace);
        sock->address = ip;
        sock->udp = udp;
        sock->tcp = tcp;
        sl->begin = node;
    }
    else{
        socksfd_node* pos = sl->begin;
        while(NULL != pos->next){
            pos = pos->next;
            ;
        }
        socksfd_node* node = 
            (socksfd_node*)malloc(sizeof(socksfd_node));
        socksfd_node_Init(node);
        socks* sock = &(node->dataspace);
        sock->address = ip;
        sock->udp = udp;
        sock->tcp = tcp;
        pos->next = node;
    }
    pthread_rwlock_unlock(&(sl->lock));
    return true;
}
bool Socksfd_Delete(socksfd* sl,const int ip){
    bool result = false;
    pthread_rwlock_wrlock(&(sl->lock));
    socksfd_node* pos = sl->begin;
    /*第一个比较特殊*/
    if((pos->dataspace).address == ip){
        sl->begin = pos->next;
        free(pos);
        result = true;
    }
    else{
        socksfd_node* head = pos;
        pos = pos->next;
        while(NULL != pos){
            if((pos->dataspace).address == ip){
                head->next = pos->next;
                free(pos);
                result = true;
                break;
            }
            head = pos;
            pos = pos->next;
        }
    }
    pthread_rwlock_unlock(&(sl->lock));
#ifdef DEBUG
    Socksfd_Print(sl);
#endif
    return result; 
}
void socks_node_Print(socks* p){
    printf("socks address: %d\n",p->address);
    printf("udp: %d\n",p->udp);
    printf("tcp: %d\n",p->tcp);
}
/*显示*/
void Socksfd_Print(socksfd *sl){
    pthread_rwlock_rdlock(&(sl->lock));
    socksfd_node* pos = sl->begin;
    socks* sock_p;
    int count = 0;
    while(NULL != pos){
        printf("----num:\t%d-----\n",count++);
        socks_node_Print(&(pos->dataspace));
        pos = pos->next;
    }
    pthread_rwlock_unlock(&(sl->lock));
}
/*遍历回调*/
void Socksfd_RunFuc(socksfd *sl, void(*func)(socks*)){
    pthread_rwlock_rdlock(&(sl->lock));
    socksfd_node* pos = sl->begin;
    while(NULL != pos){
        socks * p = &(pos->dataspace);
        func(p);
        pos = pos->next;
    }
        pthread_rwlock_unlock(&(sl->lock));
}

