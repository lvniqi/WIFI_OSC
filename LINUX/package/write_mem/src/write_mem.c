#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
//O_DIRECT 声明
#define __USE_GNU 1 
#include <fcntl.h>
static unsigned long p = 0;//交换区地址
int main(int argc, char *argv[])
{
	unsigned long* v_addr;
	unsigned long data;
	int fd;
	unsigned long base_address;
	if (3 == argc )
	{
		base_address = strtol(argv[1],NULL,NULL);
		data =  strtol(argv[2],NULL,NULL);
		printf("address_real: 0x%08x\n",(unsigned long)base_address);
		fd = open("/dev/mem", O_RDWR|O_SYNC);
		if(fd < 0)//打开出错
		{
			perror("open");
			return -1;
		}
		v_addr = (int)mmap(NULL, 0x01, 
				   PROT_READ|PROT_WRITE|PROT_EXEC, MAP_SHARED|MAP_NONBLOCK|MAP_POPULATE, 
				   fd, base_address&~0x00000fff);
		if (v_addr == MAP_FAILED)
		{
			perror("errno");
			return;
		}
		if(close(fd) < 0)// 关闭/dev/mem文件
		{ 
			perror("couldn't close /dev/mem file descriptor");
			exit(1);
		}	
		printf("address_virt: 0x%08x\n",(unsigned long)v_addr);//显示内存地址
		printf("data: %d\n",*(v_addr+((base_address&0x00000fff)>>2)));
		*(v_addr+((base_address&0x00000fff)>>2)) = data;
		msync(v_addr,0x01,MS_SYNC);
		printf("change data: %d\n",*(v_addr+((base_address&0x00000fff)>>2)));
		int i;
		munmap(v_addr,0x01);//释放交换区
	} 
	return 0;
}
