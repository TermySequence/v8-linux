ARCH ?= x64
BUILDDIR ?= .

gndir := v8/buildtools/linux64
gn := $(gndir)/gn
targets = \
    $(BUILDDIR)/obj/libv8_libplatform.a \
    $(BUILDDIR)/obj/libv8_base.a \
    $(BUILDDIR)/obj/libv8_external_snapshot.a \
    $(BUILDDIR)/obj/libv8_init.a \
    $(BUILDDIR)/obj/libv8_initializers.a \
    $(BUILDDIR)/obj/libv8_libbase.a \
    $(BUILDDIR)/obj/libv8_libsampler.a \
    $(BUILDDIR)/snapshot_blob.bin \
    $(BUILDDIR)/natives_blob.bin

.PHONY: all clean

all: $(targets)

$(targets): $(gn) v8/src/*.cc v8/src/*.h
	echo ARCH=$(ARCH)
	echo BUILDDIR=$(BUILDDIR)
	echo CFLAGS=$(CFLAGS)
	echo LDFLAGS=$(LDFLAGS)
	./build.sh $(BUILDDIR) $(ARCH) "$(CFLAGS)" "$(LDFLAGS)" $(ARMFP)

$(gn): v8/gn/*.cc v8/gn/*.h
	mkdir -p $(gndir)
	cp -r v8/gn v8/tools
	(cd v8/tools/gn/ && ./bootstrap/bootstrap.py -s)
	cp -p v8/out/Release/gn $(gn)

clean:
	./clean.sh
