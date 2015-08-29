# build mthread executable when user executes "make"
mthread: mthread.o Linklist.o
	$(CC) $(LDFLAGS)   mthread.o Linklist.o  -o mthread -lpthread

mthread.o: mthread.c
	$(CC) $(CFLAGS) -O3 -c mthread.c 
Sequeue.o: Linklist.c
	$(CC) $(CFLAGS) -O3 -c Linklist.c 

# remove object files and executable when user executes "make clean"
clean:
	rm *.o mthread
