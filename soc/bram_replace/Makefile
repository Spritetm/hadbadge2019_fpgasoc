TARGET := bram_replace
OBJS := bram_replace.o twister.o
CFLAGS := -ggdb

$(TARGET): $(OBJS)
	$(CC) -o $(TARGET) $(OBJS)


clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: clean