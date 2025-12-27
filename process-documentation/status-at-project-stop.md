# Status At Project Stop

This file records the current state of the C89/portability work. It is meant
as a single, self-contained reference for resuming the project later.

## Summary

Work completed:

- Strict C89 compatibility fixes across the codebase.
- Configurable endianness (little vs big) with build flags.
- Guest build workflow (generate headers on host, compile on guest).
- Documentation updates (README + C89_PORTING_NOTES).

Work paused:

- Full compatibility with plain (non-GCC/Clang) C89 compilers.
- 32-bit cross builds when a 32-bit toolchain is not available.
- Native support for platforms without a 64-bit integer type.

## Major Changes Applied

### C89 Compatibility

- Converted C++-style `//` comments to `/* ... */`.
- Removed `inline` usage; added `__maybe_unused` where static helpers can be
  unused.
- Removed trailing commas in enums (many files).
- Replaced C99 variadic macros with C89 varargs functions.
- Replaced hex float literals with decimal constants and documented original
  hex values.
- Replaced long-long literal uses in 32-bit builds with safe 32-bit
  composition.
- Eliminated GNU case ranges (expanded to explicit `case` fallthrough).
- Fixed void function returns (`return expr;` -> call + `return;`).
- Fixed declaration-after-statement errors.
- Replaced flexible array members with C89 struct hacks using `[1]` and
  `offsetof` sizing (e.g., `JSString`, `JSByteArray`, `JSValueArray`, etc.).

### Endianness

- Added endianness detection and overrides in `porting.h`.
- `WORDS_BIGENDIAN` is the controlling symbol.
- `get_be32`/`put_be32` are endian-aware.
- stdlib generator (`mquickjs_build.c`) emits 32-bit float64 words in
  big-endian order when `WORDS_BIGENDIAN` is set.

### Guest Build Workflow

- New `Makefile.guest` (generator-free build).
- New target `build-guest-sourcetree` in the main `Makefile`.
- The guest tree includes pre-generated headers:
  - `mqjs_stdlib.h`
  - `mquickjs_atom.h`
  - `example_stdlib.h`
- `make clean` now also removes the guest tree (`$(GUEST_DIR)`), ignoring
  missing directories.

### Build Flags / Tooling

- Default warning flags in `Makefile` and `Makefile.guest` are now:
  - `-Wall -Wstrict-prototypes -std=c89 -pedantic -Werror`
- Earlier experimental flags (`-Wextra`, `-Wconversion`, `-Wshadow`,
  `-Wmissing-prototypes`) were removed to avoid widespread warnings.

## Key Files Added / Updated

- `C89_PORTING_NOTES.md` — comprehensive porting strategies.
- `Makefile.guest` — generator-free guest build.
- `porting.h` — portability macros (endianness and `JS_PTR64` guidance).
- `README.md` — updated with C89/guest workflow notes and a PROJECT STOPPED
  banner.

## Examples of Critical Code Changes

### Endianness in stdlib generation

File: `mquickjs_build.c`

```c
#if defined(WORDS_BIGENDIAN)
    printf("  0x%08x,\n", (uint32_t)(v >> 32));
    printf("  0x%08x,\n", (uint32_t)v);
#else
    printf("  0x%08x,\n", (uint32_t)v);
    printf("  0x%08x,\n", (uint32_t)(v >> 32));
#endif
```

### Endian-aware helpers

File: `cutils.h`

```c
static __maybe_unused uint32_t get_be32(const uint8_t *d)
{
#if defined(WORDS_BIGENDIAN)
    return get_u32(d);
#else
    return bswap32(get_u32(d));
#endif
}
```

### C89 struct hack (flexible arrays)

File: `mquickjs.c`

```c
typedef struct {
    JS_MB_HEADER;
    JSWord size: JS_MB_PAD(JS_MTAG_BITS);
    uint8_t buf[1];
} JSByteArray;

arr = js_malloc(ctx, offsetof(JSByteArray, buf) + size,
                JS_MTAG_BYTE_ARRAY);
```

### Hex-float replacement

File: `mquickjs.c`

```c
if (fabs(d) >= 5.8774717541114375e-39 /* 0x1p-127 */ &&
    fabs(d) <= 3.4028236692093846e38 /* 0x1p+128 */) {
    return js_to_short_float(d);
}
```

### 64-bit literal decomposition (32-bit builds)

File: `libm.c`

```c
#define U64_FROM_U32(hi, lo) ((((uint64_t)(hi)) << 32) | (uint32_t)(lo))

static const uint64_t T[T_LEN] = {
    U64_FROM_U32(0x1580cc11u, 0xbf1edaeau), /* 0x1580cc11bf1edaea */
    /* ... */
};
```

## Build Targets Tested

- `make`
- `make test`
- `make size`
- `make CONFIG_SMALL=y`
- `make CONFIG_BIG_ENDIAN=y`
- `make CONFIG_BIG_ENDIAN=y CONFIG_SMALL=y`

Note: 32-bit builds with `CONFIG_X86_32=y` failed to link in this environment
because the toolchain could not link a 32-bit binary.

## Current Portability Challenges

### 1) Plain C89 / Non-GCC Compatibility

Based on static inspection, the code still relies on:

- GCC/Clang attributes (`__attribute__((...))`).
- GCC/Clang builtins (`__builtin_clz`, `__builtin_expect`, etc.).
- C99 headers `<stdint.h>` and `<inttypes.h>`.
- IEEE-754 and packed/unaligned access assumptions.

To fully support a non-GCC C89 compiler, we likely need:

- A compatibility layer for attributes and builtins.
- A replacement for fixed-width integer types and format macros.
- Additional endianness audits beyond the explicit helpers.

### 2) 64-bit Integer Requirement

The engine relies on native 64-bit integers for:

- Float bit manipulation.
- `libm` and `dtoa` internals.
- Random generator state.
- Various math paths.

A platform without native 64-bit integer support would require a substantial
refactor to implement a software 64-bit integer type.

### 3) 32-bit Cross Builds

`CONFIG_X86_32=y` requires a working 32-bit toolchain. Without it, link fails.
A `CONFIG_32BIT_STDLIB` experiment (generate 32-bit headers only) was attempted
but caused type/initializer mismatches when compiling the 64-bit runtime.

## What Remains To Do

- Decide on a portability layer for non-GCC C89 compilers.
  - Likely changes in `porting.h` and build flags.
- Decide whether to add a true 32-bit build flag that does not depend on
  GCC/Clang `-m32`.
- If targeting big-endian for real: test on actual big-endian hardware.
- Consider whether a software 64-bit integer implementation is worth pursuing.

## Where To Resume

- Re-evaluate the non-GCC portability plan.
- Decide on a strategy for fixed-width integer polyfills.
- Run a targeted audit for endian-sensitive code paths beyond the current
  helpers.

