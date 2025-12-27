# C89 Porting Notes (Project Conventions)

This document captures the C89-compatibility strategies used in this tree.
It is intended for humans and automation to keep future changes consistent.

## General C89 Rules Used Here

- **No C99/C11 features**: avoid `inline`, variadic macros, flexible array
  members (`T arr[]`), anonymous structs/unions, hex float literals, and GNU
  case ranges.
- **No `long long` literals** in strict C89 builds. Use 32-bit composition.
- **Prefer C89-friendly constants**: use decimal literals or `offsetof`-based
  size calculations; avoid `INT64_MAX`/`0x...LL` in preprocessor logic.

## Strategies Applied in This Tree

### 1) C++-style `//` comments
Convert to C89 block comments.
- Example: `// text` -> `/* text */`
- Avoid nested `/* ... /* ... */` sequences.

### 2) `inline` usage
Remove `inline` and related macros.
- If needed for headers, keep `static` functions and add `__maybe_unused`.

### 3) Trailing commas in enums
Remove trailing commas in enum definitions.
- If a macro expands to a comma (e.g., opcode lists), add a final sentinel
  enumerator to avoid a trailing comma.

### 4) Variadic macros
Replace with C89 varargs **functions**.
- Example: replace `JS_ThrowTypeError(...)` macro with
  `JS_ThrowTypeError(ctx, fmt, ...)` function wrappers calling a shared
  `va_list` helper.

### 5) Hex float literals
Replace `0x1p±N` with decimal constants and **document the original**.
- Example: `5.8774717541114375e-39 /* 0x1p-127 */`
 - When converting numeric literals not supported by C89 (hex floats, large
   64-bit constants), use an external tool to compute the replacement.
   Example (Python):
   ```sh
   python3 - <<'PY'
   from decimal import Decimal, getcontext
   getcontext().prec = 50
   print(Decimal(2) ** Decimal(-127))  # 0x1p-127
   print(Decimal(2) ** Decimal(128))   # 0x1p+128
   PY
   ```

### 6) `long long` literals in 32-bit mode
Replace 64-bit constants with `U64_FROM_U32(hi, lo)` or shifts.
- Example:
  - `0x8000000000000000` -> `((uint64_t)0x80000000u << 32)`
  - `0x2545F4914F6CDD1D` -> `((uint64_t)0x2545F491u << 32) | 0x4F6CDD1Du`
- Always add a comment with the original literal.

### 7) Flexible array members
Use the C89 “struct hack” with `[1]` and size via `offsetof`.
- Struct: `T arr[1];`
- Allocation: `offsetof(S, arr) + n * sizeof(T)`
- Resizing/shrinking: use `offsetof` and round as needed.

### 8) `void *` pointer arithmetic
Cast to a byte pointer before arithmetic.
- Example: `ctx->stack_top = (uint8_t *)mem_start + mem_size;`

### 9) GNU case ranges
Expand `case 'a' ... 'z'` into explicit fallthrough cases.

### 10) Header helpers unused in some TUs
Use `__maybe_unused` to silence `-Wunused-function` where needed.
See `porting.h` for the definition.

### 11) Configurable endianness
Use `WORDS_BIGENDIAN` to select big-endian behavior.
- Build flags: `CONFIG_BIG_ENDIAN=y` or `CONFIG_LITTLE_ENDIAN=y`.
- `get_be32`/`put_be32` are endian-aware helpers.
- The stdlib generator (`mquickjs_build.c`) emits 32-bit words in the correct
  order for the target endianness.
- Strategy:
  - Define endianness in `porting.h`, with optional build flags to override
    auto-detection.
  - Gate data-marshaling helpers in `cutils.h` so they no-op on big-endian
    and swap on little-endian.
  - Emit 32-bit `float64` word order in `mquickjs_build.c` based on
    `WORDS_BIGENDIAN` (so ROM data matches the target ABI).

## Build & Generation Workflow Notes

- Generated headers (`mqjs_stdlib.h`, `mquickjs_atom.h`, `example_stdlib.h`)
  must be built by host tools. A guest build tree can be created with:
  `make build-guest-sourcetree`.
- The guest tree includes only sources, generated headers, and a
  generator-free `Makefile`.

## Checklist for New Changes

- No `inline`, no variadic macros, no flexible arrays.
- No trailing enum commas.
- No `0x...LL` / `INT64_MAX` in preprocessor checks.
- No `0x1p±N` literals.
- Avoid `void *` arithmetic.
- Use `offsetof` for variable-size structs.

## Plain C89 / Non-GCC Compatibility (Tentative Findings)

These notes are based on a static grep of the current tree. They are
**tentative** and **non-exhaustive**; additional blockers may appear when
porting to a specific non-GCC/Clang compiler.

Observed non-C89 / non-portable dependencies:

- **GCC/Clang attributes** in headers and sources:
  - `__attribute__((unused))`, `__attribute__((packed))`,
    `__attribute__((format))`, `__attribute__((noinline))`.
  - Examples: `cutils.h`, `readline.h`, `mquickjs.c`.
- **Compiler builtins**:
  - `__builtin_clz`, `__builtin_ctz`, `__builtin_expect`,
    `__builtin_add_overflow`, `__builtin_sub_overflow`.
  - Examples: `cutils.h`, `mquickjs.c`.
- **C99 headers and fixed-width types**:
  - `<stdint.h>`, `<inttypes.h>`, and `uint64_t`/`int32_t` etc.
  - Format macros like `PRIx64`, `PRIu64`.
  - Examples: `mquickjs.h`, `dtoa.c`, `libm.c`, `mquickjs_build.c`.
- **IEEE-754 and layout assumptions**:
  - Bit-level float reinterpretation and packed structs.
  - Examples: `cutils.h`, `libm.c`.

If a target compiler lacks these facilities, expect to add a compatibility
layer (e.g., in `porting.h`) or provide substitute headers/types.
