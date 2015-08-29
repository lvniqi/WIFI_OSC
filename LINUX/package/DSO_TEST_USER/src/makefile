# build helloworld executable when user executes "make"

helloworld: dso_test_user.o
	$(CC) $(LDFLAGS) dso_test_user.o -o3 -o dso_test_user

helloworld.o: dso_test_user.c
	$(CC) $(CFLAGS) -c -o3 dso_test_user.c

# remove object files and executable when user executes "make clean"
clean:
	rm *.o dso_test_user
