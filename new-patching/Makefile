
all: patch build
patch: patcher headers-32 prepare-patching-tree run-patcher
clean: psychec-clean patcher-clean headers-clean prepare-patching-tree-clean

### Config knobs
CMAKE_BUILD_TYPE ?= Debug

### Utility define
OS := $(shell uname -s 2>/dev/null || echo Unknown)
ifeq ($(OS),Darwin)
	DLEXT := dylib
	LIBPFX := lib
else ifeq ($(OS),Linux)
	DLEXT := so
	LIBPFX := lib
else ifneq (,$(findstring MINGW,$(OS)))
	DLEXT := dll
	LIBPFX :=
else ifneq (,$(findstring CYGWIN,$(OS)))
	DLEXT := dll
	LIBPFX :=
else ifeq ($(OS),Unknown)  # Windows with native make
	DLEXT := dll
	LIBPFX :=
else
	DLEXT := so
	LIBPFX := lib
endif

### Internal: dependency directories
SRC_DIR := ..
GENERATE_HEADERS_PHASE_DIR := ./scratch-header-generation
TO_PATCH_DIR := ./scratch-to-patch
PATCHED_DIR := ./build-patched

PATCHER_DIR := ./patcher
PATCHER_BUILD := ./build-patcher

PSYCHEC_DIR := ../psychec-25-12-24
PSYCHEC_BUILD := ./build-psychec-local


#### STEP 1: non-C89 step - generate headers for a 32-bit platform.

.PHONY: headers-32 headers-64 

TARGET_SRCS := mquickjs.c mqjs.c dtoa.c libm.c cutils.c readline.c readline_tty.c example.c
TARGET_HDRS := mquickjs.h mquickjs_priv.h mquickjs_opcode.h dtoa.h libm.h cutils.h readline.h readline_tty.h list.h softfp_template.h softfp_template_icvt.h
GENERATED_HDRS := mquickjs_atom.h mqjs_stdlib.h example_stdlib.h

.PHONY:prepare-patching-tree
prepare-patching-tree: headers-32
	# ensure destination is clean
	rm -rf $(TO_PATCH_DIR)
	mkdir -p $(TO_PATCH_DIR)
	# copy target-facing sources and headers from the source tree
	cp $(addprefix $(SRC_DIR)/,$(TARGET_SRCS)) $(TO_PATCH_DIR)
	cp $(addprefix $(SRC_DIR)/,$(TARGET_HDRS)) $(TO_PATCH_DIR)
	# copy the generated headers from the header-generation phase
	cp $(addprefix $(GENERATE_HEADERS_PHASE_DIR)/,$(GENERATED_HDRS)) $(TO_PATCH_DIR)
	# copy makefile, and patch to aggressive C89 mode
	cp $(SRC_DIR)/Makefile $(TO_PATCH_DIR)/Makefile
	patch -s $(TO_PATCH_DIR)/Makefile < Makefile.patch

prepare-patching-tree-clean: headers-clean
	rm -rf $(PATCHED_DIR)

# Build all header artifacts only (runs host tools first, then emits headers)
headers-32:
	mkdir -p $(GENERATE_HEADERS_PHASE_DIR)
	cp $(SRC_DIR)/*.c $(SRC_DIR)/*.h $(SRC_DIR)/Makefile $(GENERATE_HEADERS_PHASE_DIR)
	# note that, although CONFIG_X86_32 is used here, for our purposes it just means "32-bit"
	$(MAKE) -C $(GENERATE_HEADERS_PHASE_DIR) CONFIG_X86_32=y mquickjs_atom.h mqjs_stdlib.h example_stdlib.h
headers-64:
	mkdir -p $(GENERATE_HEADERS_PHASE_DIR)
	cp $(SRC_DIR)/*.c $(SRC_DIR)/*.h $(SRC_DIR)/Makefile  $(GENERATE_HEADERS_PHASE_DIR)
	$(MAKE) -C $(GENERATE_HEADERS_PHASE_DIR) mquickjs_atom.h mqjs_stdlib.h example_stdlib.h

headers-clean:
	rm -rf $(GENERATE_HEADERS_PHASE_DIR)

#### STEP @: actual patching step - run the C89 patcher

run-patcher: patcher prepare-patching-tree
	@set -e; \
	mkdir -p "$(PATCHED_DIR)"; \
	for f in $(TO_PATCH_DIR)/*.[ch]; do \
	  b=$$(basename "$$f"); \
	  echo "[patcher] $$b"; \
	  "$(PSYCHEC_BUILD)/cnip" -analysis "$(PATCHER_BUILD)/$(LIBPFX)c89-patcher.$(DLEXT)" -I"$(TO_PATCH_DIR)" "$$f" > "$(PATCHED_DIR)/$$b"; \
	done

#### STEP 3 (not strictly required): test-build patched C89 sources on the
#### host with C89 flags and Werror cranked up to the max. Not
#### necessarily required if we're just after the patched sources.
build:
	cd ${PATCHED_DIR} && $(MAKE)

#### Patcher (via CMake)

.PHONY: patcher patcher-clean
# Build patcher after psychec to ensure the library exists
patcher: psychec
	mkdir -p $(PATCHER_BUILD)
	cmake -S $(PATCHER_DIR) -B $(PATCHER_BUILD) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DPSYCHEC_SOURCE_DIR=$(abspath ../psychec) \
		-DPSYCHEC_BUILD_DIR=$(abspath $(PSYCHEC_BUILD))
	$(MAKE) -C $(PATCHER_BUILD) $(PSYCHEC_MAKE_FLAGS)

patcher-clean:
	rm -rf $(PATCHER_BUILD)

#### Psyche-C

PSYCHEC_MAKE_FLAGS := -j 4

.PHONY: psychec psychec-clean
psychec:
	mkdir -p $(PSYCHEC_BUILD)
	cmake -S $(PSYCHEC_DIR) -B $(PSYCHEC_BUILD) -DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) -DPSYCHEC_BUILD_TESTS=OFF
	$(MAKE) -C $(PSYCHEC_BUILD) $(PSYCHEC_MAKE_FLAGS)

psychec-clean:
	rm -rf $(PSYCHEC_BUILD)
	rm -rf CMakeFiles
