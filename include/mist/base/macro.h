#pragma once

#ifdef __GNUC__
#define MIST_GNUC 1
#else
#define MIST_GNUC 0
#endif

#ifdef __GNUG__
#define MIST_GNUC 1
#else
#define MIST_GNUC 0
#endif

#if defined(__GUNG__)
#define MIST_GUNG 1
#else
#define MIST_GUNG 0
#endif

#if defined(__clang__)
#define MIST_CLANG 1
#else
#define MIST_CLANG 0
#endif

#if MIST_GNUC || MIST_GUNG || MIST_CLANG
#define MIST_LIKELY(x) __builtin_expect(!!(x), 1)
#define MIST_UNLIKELY(x) __builtin_expect(!!(x), 0)
#else
#define MIST_LIKELY(x) (x)
#define MIST_UNLIKELY(x) (x)
#endif

// Alias for NDEBUG
#ifdef NDEBUG
#ifndef MIST_NO_DEBUG
#define MIST_NO_DEBUG
#endif
#endif

#define MIST_CONCAT(a, b) a##b

// Count number of args inside variadic macro
#define MIST_NUM_VA_ARGS_HELPER_(_1, _2, _3, _4, _5, _6, N, ...) N
#define MIST_NUM_VA_ARGS(...) \
  MIST_NUM_VA_ARGS_HELPER_(__VA_ARGS__ __VA_OPT__(, ) 6, 5, 4, 3, 2, 1, 0)

// Select macro based on number of args in __VA_ARGS__
//
// usage:
//
// #define MIST_TEST_MACRO_1(a) 1
// #define MIST_TEST_MACRO_2(a, b) 2
// #define MIST_TEST_MACRO_3(a, b, c) 3
// #define MIST_TEST_MACRO(...) MIST_VA_SELECT(MIST_TEST_MACRO, __VA_ARGS__)
//
// MIST_TEST_MACRO(x, y) -> MIST_TEST_MACRO_2(x, y)
#define MIST_OVERLOAD_HELPER_(name, n) MIST_CONCAT(name##_, n)
#define MIST_OVERLOAD(name, ...) \
  MIST_OVERLOAD_HELPER_(name, MIST_NUM_VA_ARGS(__VA_ARGS__))(__VA_ARGS__)

#define MIST_NOEXCEPT noexcept
#define MIST_NODISCARD [[__nodiscard__]]
#define MIST_NOEXCEPT_IF(condition) noexcept(condition)

#if __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
#define MIST_LITTLE_ENDIAN 1
#define MIST_BIG_ENDIAN 0
#else
#define MIST_LITTLE_ENDIAN 0
#define MIST_BIG_ENDIAN 1
#endif

// string concat
#define MIST_INTERNAL_CAT_HELPER_(a, b) a##b
#define MIST_INTERNAL_CAT_(a, b) MIST_INTERNAL_CAT_HELPER_(a, b)
#define MIST_CAT(a, b) MIST_INTERNAL_CAT_(a, b)

// This macro should only be used in cc file, and should not be located in
// anonymous namespace. The purpose of the macro is to generate a registry
// variable that is not GCed by linker.
//
// TODO: using __LINE__ is not absolutely safe
#define MIST_COMMAND(...)                           \
  struct MIST_CAT(CommandT, __LINE__) {             \
    MIST_CAT(CommandT, __LINE__)() { __VA_ARGS__; } \
  };                                               \
  MIST_CAT(CommandT, __LINE__) MIST_CAT(MistGlobalRegistry_COMMAND, __LINE__);
