V8ARCH ?= x64

CFLAGS ?= -g -O2
LDFLAGS ?= -g -O2

PREFIX ?= /usr/local
LIBDIR ?= $(DESTDIR)$(PREFIX)/lib64
INCDIR ?= $(DESTDIR)$(PREFIX)/include
BINDIR ?= $(DESTDIR)$(PREFIX)/bin

.PHONY: all install

all:
	./build.sh $(V8ARCH) "$(CFLAGS)" "$(LDFLAGS)"

install:
	./install.sh $(V8ARCH) $(LIBDIR) $(INCDIR) $(BINDIR)
