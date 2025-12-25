#ifndef MQUICKJS_PORTING_H
#define MQUICKJS_PORTING_H

/*
 * Portability helpers for strict C89 builds.
 * Avoid preprocessor expressions that expand to long long literals.
 */
#ifndef WORDS_BIGENDIAN
/* Endianness: define WORDS_BIGENDIAN for big-endian targets. */
#if defined(CONFIG_BIG_ENDIAN)
#define WORDS_BIGENDIAN 1
#elif defined(CONFIG_LITTLE_ENDIAN)
/* leave WORDS_BIGENDIAN undefined */
#elif defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && \
      defined(__ORDER_LITTLE_ENDIAN__)
#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define WORDS_BIGENDIAN 1
#endif
#elif defined(__BIG_ENDIAN__) || defined(__ARMEB__) || defined(__MIPSEB__) || \
      defined(__PPC__) || defined(__sparc__)
#define WORDS_BIGENDIAN 1
#endif
#endif
/* JS_PTR64 indicates that JSValue/JSWord are 64-bit (pointer width).
 * On 32-bit targets, leave this undefined unless the ABI truly uses 64-bit
 * pointers (e.g., unusual or capability-based platforms). */
#if !defined(JS_PTR64)
#if defined(__SIZEOF_POINTER__)
#if __SIZEOF_POINTER__ >= 8
#define JS_PTR64
#endif
#elif defined(EXOTIC_COMPILER_PTR64)
/* Add exotic compiler pointer-size macros here (define JS_PTR64 as needed). */
#elif defined(_WIN64) || defined(__LP64__) || defined(__x86_64__) || \
      defined(__aarch64__) || defined(__ppc64__) || defined(__mips64) || \
      defined(__s390x__) || defined(__riscv_xlen) || defined(__EMSCRIPTEN__)
#define JS_PTR64
#endif
#endif

#ifndef __maybe_unused
/* GCC/Clang -Wunused-function can trip on unused static helpers in headers. */
#if defined(__GNUC__) || defined(__clang__)
#define __maybe_unused __attribute__((unused))
#else
#define __maybe_unused
#endif
#endif

#endif /* MQUICKJS_PORTING_H */
