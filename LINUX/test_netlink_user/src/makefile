# build helloworld executable when user executes "make"

helloworld: test_netlink.o
	$(CC) $(LDFLAGS) test_netlink.o -o3 -o test_netlink

helloworld.o: test_netlink.c
	$(CC) $(CFLAGS) -c -o3 test_netlink.c

# remove object files and executable when user executes "make clean"
clean:
	rm *.o test_netlink
