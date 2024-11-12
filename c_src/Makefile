CFLAGS = -fPIC -I$(ERTS_INCLUDE_DIR)
LDFLAGS = -dynamiclib -undefined dynamic_lookup
TARGET = ../priv/imessaged_nif.so

$(TARGET): imessaged_nif.m
	mkdir -p ../priv
	$(CC) $(CFLAGS) $(LDFLAGS) -framework Foundation -o $(TARGET) imessaged_nif.m

clean:
	rm -f $(TARGET) 