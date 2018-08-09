ARCH ?= x64
BUILDDIR ?= .

targets = \
    $(BUILDDIR)/obj/libv8_libplatform.a \
    $(BUILDDIR)/obj/libv8_base.a \
    $(BUILDDIR)/obj/libv8_external_snapshot.a \
    $(BUILDDIR)/obj/libv8_init.a \
    $(BUILDDIR)/obj/libv8_initializers.a \
    $(BUILDDIR)/obj/libv8_libbase.a \
    $(BUILDDIR)/obj/libv8_libsampler.a
patterns = \
    $(BUILDDIR)/obj/%_libplatform.a \
    $(BUILDDIR)/obj/%_base.a \
    $(BUILDDIR)/obj/%_external_snapshot.a \
    $(BUILDDIR)/obj/%_init.a \
    $(BUILDDIR)/obj/%_initializers.a \
    $(BUILDDIR)/obj/%_libbase.a \
    $(BUILDDIR)/obj/%_libsampler.a

gndir := v8/buildtools/linux64
gn := $(gndir)/gn

.PHONY: all clean
.NOTPARALLEL: all clean

all: $(targets)

$(patterns): $(gn) v8/src/*.cc v8/src/*.h
	echo ARCH=$(ARCH)
	echo BUILDDIR=$(BUILDDIR)
	echo CFLAGS=$(CFLAGS)
	echo LDFLAGS=$(LDFLAGS)
	./build.sh $(BUILDDIR) $(ARCH) "$(CFLAGS)" "$(LDFLAGS)" $(ARMFP)

$(gn): v8/gn/*.cc v8/gn/*.h
	mkdir -p $(gndir)
	cp -r v8/gn v8/tools
	(cd v8/tools/gn/ && CFLAGS= CXXFLAGS= LDFLAGS= ./bootstrap/bootstrap.py -s -v)
	cp -p v8/out/Release/gn $(gn)

clean:
	./clean.sh $(BUILDDIR)
