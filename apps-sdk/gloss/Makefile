TARGET := libgloss.a
OBJS := crt0.o

$(TARGET): $(OBJS)
	$(PREFIX)ar rc $(TARGET) $(OBJS)

clean:
	rm -f $(TARGET) $(OBJS)