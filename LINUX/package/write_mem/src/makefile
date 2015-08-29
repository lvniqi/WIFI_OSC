# build helloworld executable when user executes "make"

helloworld: write_mem.o
	$(CC) $(LDFLAGS) write_mem.o -o write_mem

helloworld.o: write_mem.c
	$(CC) $(CFLAGS) -c write_mem.c

# remove object files and executable when user executes "make clean"
clean:
	rm *.o write_mem
