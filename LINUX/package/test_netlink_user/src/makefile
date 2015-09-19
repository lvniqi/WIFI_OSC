# build helloworld executable when user executes "make"

test_netlink: test_netlink.o
	$(CC) $(LDFLAGS) test_netlink.o  -o test_netlink

test_netlink.o: test_netlink.c
	$(CC) $(CFLAGS) -O3 -c  test_netlink.c

# remove object files and executable when user executes "make clean"
clean:
	rm *.o test_netlink
