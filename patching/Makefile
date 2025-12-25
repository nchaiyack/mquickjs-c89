
all: patch build

# Portability defines:
SRC_DIR := ..
PATCHED_DIR := ./patched

patch:
	# copy everything in the source tree to a dedicated working folder...
	mkdir -p ${PATCHED_DIR}
	cp ${SRC_DIR}/*.c ${SRC_DIR}/*.h ${SRC_DIR}/Makefile ${PATCHED_DIR}
	# apply patches. let's try to make these as codebase-agnostic as possible.
	patch ${PATCHED_DIR}/Makefile Makefile.patch
	@set -e; \
    for f in $(PATCHED_DIR)/*.[ch]; do \
        [ -e "$$f" ] || continue; \
		# ...convert C99 comments to C89 comments... \
        awk -f patch_comments.awk "$$f" > "$$f.tmp" && mv "$$f.tmp" "$$f"; \
		# ...remove "inline" keyword... \
		awk -f patch_inline.awk "$$f" > "$$f.tmp" && mv "$$f.tmp" "$$f"; \
		# ...convert fancy new float literals to calls to ldexp()... \
		sed 's/0x1p\([+-][0-9][0-9]*\)/ldexp(1.0,\1)/g' "$$f" > "$$f.tmp" && mv "$$f.tmp" "$$f"; \
		# ...remove trailing commas at the end of compound initialisers... \
		awk -f patch_enum_trailing_comma.awk "$$f" > "$$f.tmp" && mv "$$f.tmp" "$$f"; \
    done
	# unavoidably file-specific patches...
	# ...mquickjs.c
	#.       we need to specify the size of arrays in declarations;
	sed 's/parse_func_table\[[[:space:]]*\]/parse_func_table[12]/g' ${PATCHED_DIR}/mquickjs.c > ${PATCHED_DIR}/mquickjs.c.tmp && mv ${PATCHED_DIR}/mquickjs.c.tmp ${PATCHED_DIR}/mquickjs.c
	# ...mquickjs_build.c and .h
	#        convert some unions to structs, to avoid issues with
	#        designated initializers (i.e. ".field = value" syntax);
	awk -f patch_mquickjs_build_h_part1.awk ${PATCHED_DIR}/mquickjs_build.h > ${PATCHED_DIR}/mquickjs_build.h.tmp && mv ${PATCHED_DIR}/mquickjs_build.h.tmp ${PATCHED_DIR}/mquickjs_build.h
	sed -f patch_mquickjs_build_c_part1.sed ${PATCHED_DIR}/mquickjs_build.c > ${PATCHED_DIR}/mquickjs_build.c.tmp && mv ${PATCHED_DIR}/mquickjs_build.c.tmp ${PATCHED_DIR}/mquickjs_build.c
	#        quickjs_build.c - since it also generates C code, update the
	#        generated C code similarly to prev.
	sed -f patch_mquickjs_build_c_part2.sed ${PATCHED_DIR}/mquickjs_build.c > ${PATCHED_DIR}/mquickjs_build.c.tmp && mv ${PATCHED_DIR}/mquickjs_build.c.tmp ${PATCHED_DIR}/mquickjs_build.c

build:
	cd ${PATCHED_DIR} && $(MAKE)

clean:
	rm -r ${PATCHED_DIR}