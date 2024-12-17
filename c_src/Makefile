CFLAGS = -fPIC -I$(ERTS_INCLUDE_DIR) -I.
LDFLAGS = -dynamiclib -undefined dynamic_lookup
TARGET = ../priv/imessaged_nif.so
SDEF_SOURCE = /System/Applications/Messages.app/Contents/Resources/Messages.sdef

$(TARGET): Messages.h imessaged_nif.m
	mkdir -p ../priv
	$(CC) $(CFLAGS) $(LDFLAGS) \
		-framework Foundation \
		-framework CoreServices \
		-framework ScriptingBridge \
		-framework AppKit \
		-o $(TARGET) imessaged_nif.m

Messages.h: Messages.sdef
	sdp -fh --basename Messages Messages.sdef

Messages.sdef:
	cp $(SDEF_SOURCE) Messages.sdef

clean:
	rm -f $(TARGET) Messages.h Messages.sdef