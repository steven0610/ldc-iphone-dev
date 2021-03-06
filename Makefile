# Make main LDC stuff for iOS and support packages

# The llvm-config program.  Change this if llvm is configured
# differently (e.g. Debug+Asserts)
LLVM_CONFIG = build/llvm/Release/bin/llvm-config


all: support ldc-all

clean: ldc-clean

distclean:
	-rm -Rf build
	$(MAKE) -C iphoneos-apple-support clean

unittest: unittest-debug unittest-release

unittest-debug: all
	$(MAKE) -C build/ldc druntime-ldc-unittest-debug
	$(MAKE) -C build/ldc phobos2-ldc-unittest-debug

unittest-release: all
	$(MAKE) -C build/ldc druntime-ldc-unittest
	$(MAKE) -C build/ldc phobos2-ldc-unittest

.PHONY: all clean distclean unittest unittest-debug unittest-release

# ldc submakes

ldc-%: build/ldc/Makefile 
	$(MAKE) -C build/ldc $(@:ldc-%=%)

build/ldc/Makefile: $(LLVM_CONFIG)
	mkdir -p build/ldc
	tools/prepmake-ldc

# support packages - treat llvm different because it is so big.  Only
# do submake in llvm if it doesn't appear to be built.  I assume llvm
# won't be changing much and you can always do a direct make in the
# subpackage if something changes (e.g. make llvm-all)

.PHONY: support

support: $(LLVM_CONFIG)
	$(MAKE) -C iphoneos-apple-support

iphoneos-apple-support/libiphoneossup.a:
	$(MAKE) -C iphoneos-apple-support

# Use non-existence of llvm-config to decide if llvm needs to be built

$(LLVM_CONFIG):
	$(MAKE) llvm-all

# llvm submakes

llvm-%: build/llvm/Makefile
	$(MAKE) -C build/llvm $(@:llvm-%=%)

build/llvm/Makefile:
	mkdir -p build/llvm
	tools/prepmake-llvm

# emacs stuff

.PHONY: etags dscanner-check

etags: dscanner-check
	etags -o TAGS.llvm `find llvm/{include,lib} -name '*.[hc]' -o -name '*.cpp'`
	if [ -d llvm/tools/clang ]; then \
	    etags --append -o TAGS.llvm \
	    `find llvm/tools/clang/{include,lib} -name '*.[hc]' -o -name '*.cpp'`; \
	  fi
	etags -o TAGS.ldc `find ldc -name '*.[hc]' -o -name '*.cpp'`
	dscanner --etags ldc/runtime/druntime/src >TAGS.druntime
	dscanner --etags ldc/runtime/phobos >TAGS.phobos
	dscanner --etagsAll ldc/runtime/druntime/src >TAGS.private-druntime
	dscanner --etagsAll ldc/runtime/phobos >TAGS.private-phobos
	etags -i TAGS.druntime -i TAGS.phobos -i TAGS.ldc -i TAGS.llvm

dscanner-check:
	@type dscanner >&/dev/null || \
	  (echo 'Need dscanner in PATH to make all etags';false)
