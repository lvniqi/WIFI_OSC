# build helloworld executable when user executes "make"

helloworld: read_mem.o
	$(CC) $(LDFLAGS) read_mem.o -o read_mem

helloworld.o: read_mem.c
	$(CC) $(CFLAGS) -c read_mem.c

# remove object files and executable when user executes "make clean"
clean:
	rm *.o read_mem
