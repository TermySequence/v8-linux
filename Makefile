export ARCH ?= x64
export BUILDDIR ?= out.gn/$(ARCH).release
export JOBS ?= 2

export CC ?= gcc
export CXX ?= g++
export LD ?= $(CXX)
export AR ?= gcc-ar

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

gn := gn/out/gn

.PHONY: all clean
.NOTPARALLEL: all clean

all: $(targets)

$(patterns): $(gn) v8/src/*.cc v8/src/*.h
	./build.sh

$(gn): gn/tools/gn/*.cc gn/tools/gn/*.h
	./bootstrap.sh

clean:
	./clean.sh
