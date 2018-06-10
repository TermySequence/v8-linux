V8ARCH ?= x64

CFLAGS ?= -g -O2
LDFLAGS ?= -g -O2

PREFIX ?= /usr/local
MULTILIB ?= lib
LIBDIR ?= $(DESTDIR)$(PREFIX)/$(MULTILIB)
INCDIR ?= $(DESTDIR)$(PREFIX)/include

.PHONY: all install

all:
	./build.sh $(V8ARCH) "$(CFLAGS)" "$(LDFLAGS)" $(ARMFP)

install:
	./install.sh $(V8ARCH) $(LIBDIR) $(INCDIR)
