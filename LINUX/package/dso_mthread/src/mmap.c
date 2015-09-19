#include "dso_test_user.h"
int dev;
frame_sequeue* mmap_init(){
    dev=open(DEV_NAME,O_RDWR|O_NDELAY);
    if(dev>=0){
        return mmap(0,
                    SHARE_MEM_SIZE,
                    PROT_READ|PROT_WRITE,
                    MAP_SHARED,
                    dev,
                    0);
    }
    else{
        return -1;
    }
}
void mmap_exit(frame_sequeue* ptrdata){
    munmap(ptrdata,SHARE_MEM_SIZE);
    close(dev);
}
