CFLAGS := -ggdb -Wall -O3

test: tjftl.o main.o hexdump.o
	$(CC) $(LDFLAGS) -o test $^

tjftl.o: ../tjftl.c
	$(CC) $(CFLAGS) -c -o $@ $^

clean:
	rm *.o test
