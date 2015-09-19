# build mthread executable when user executes "make"
dso_mthread: dso_test_user.o  netlink.o mmap.o mthread.o Linklist.o
	$(CC) $(LDFLAGS)   dso_test_user.o netlink.o mmap.o mthread.o Linklist.o  -o dso_mthread -lpthread

dso_test_user.o: dso_test_user.c
	$(CC) $(CFLAGS) -O3 -c dso_test_user.c 

netlink.o: netlink.c
	$(CC) $(CFLAGS) -O3 -c netlink.c 

mmap.o: mmap.c
	$(CC) $(CFLAGS) -O3 -c mmap.c 

mthread.o: mthread.c
	$(CC) $(CFLAGS) -O3 -c mthread.c 

Linklist.o: Linklist.c
	$(CC) $(CFLAGS) -O3 -c Linklist.c 
# remove object files and executable when user executes "make clean"
clean:
	rm *.o dso_mthread
