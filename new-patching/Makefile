
all: patch build

### Config knobs
CMAKE_BUILD_TYPE ?= Debug

### Portability defines:
SRC_DIR := ..
PATCHED_DIR := ./patched

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

### Dependency directories
PSYCHEC_DIR := ../psychec
PSYCHEC_BUILD := ./psychec-build

PATCHER_DIR := ./patcher
PATCHER_BUILD := ./patcher-build

clean: psychec-clean patcher-clean
	rm -r ${PATCHED_DIR}

#### Okay, targets that actually do things

patch:
	# copy everything in the source tree to a dedicated working folder...
	mkdir -p ${PATCHED_DIR}
	cp ${SRC_DIR}/*.c ${SRC_DIR}/*.h ${SRC_DIR}/Makefile ${PATCHED_DIR}
	# patch makefile to aggressively enforce ANSI C89;
	patch ${PATCHED_DIR}/Makefile Makefile.patch
	# run patcher using psychec;
	${PSYCHEC_BUILD}/cnip -analysis ${PATCHER_BUILD}/${LIBPFX}c89-patcher.${DLEXT} -I${SRC_DIR} ${SRC_DIR}/cutils.h
	${PSYCHEC_BUILD}/cnip -analysis ${PATCHER_BUILD}/${LIBPFX}c89-patcher.${DLEXT} -I${SRC_DIR} ${SRC_DIR}/cutils.c

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
