#ifndef TEST_NETLINK_H_
#define TEST_NETLINK_H_
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include <sys/socket.h>
#include <linux/netlink.h>

#define NETLINK_USER 31
#define MAX_PAYLOAD 100 /* maximum payload size*/

#include "Sequeue.h"
#include "dso_test_user.h"

extern void netlink_send(const char* data);
extern void netlink_send_signal(const int signal);
extern char* netlink_recv();
extern int netlink_recv_signal();
extern void netlink_init(void);
extern void netlink_exit(void);
#endif
